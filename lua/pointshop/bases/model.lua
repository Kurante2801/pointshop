local BASE = {}
BASE.ID = "model"

BASE.Modify = true

BASE.PositionMinMax = { -10, 10 }
BASE.ScaleMinMax = { 0.1, 1.75 }

BASE.Props = {
    ["bomb"] = {
        model = "models/Combine_Helicopter/helicopter_bomb01.mdl",
        bone = "ValveBiped.Bip01_Head1",
        pos = Vector(3, -2.427, 0),
        ang = Angle(0, -160, 180),
        scale = Vector(0.425, 0.425, 0.425),
        color = Color(255, 255, 255),
        alpha = 1,
        colorabletype = nil,
        material = nil
    }
}

function BASE:SanitizeTable(mods)
    if not isvector(mods.pos) then
        mods.pos = Vector(0, 0, 0)
    end

    if not isangle(mods.ang) then
        mods.ang = Angle(0, 0, 0)
    end

    if not isnumber(mods.scale) then
        mods.scale = 1
    end

    return {
        pos = Vector(math.Clamp(mods.pos.x, self.PositionMinMax[1], self.PositionMinMax[2]), math.Clamp(mods.pos.y, self.PositionMinMax[1], self.PositionMinMax[2]), math.Clamp(mods.pos.z, self.PositionMinMax[1], self.PositionMinMax[2])),
        ang = Angle(math.Clamp(mods.ang.p, -180, 180), math.Clamp(mods.ang.y, -180, 180), math.Clamp(mods.ang.r, -180, 180)),
        scale = math.Clamp(mods.scale, self.ScaleMinMax[1], self.ScaleMinMax[2])
    }
end

function BASE:ToString()
    return "[model] " .. self.ID
end

if not CLIENT then
    return PS:RegisterBase(BASE)
end

PS.CSModels = PS.CSModels or {}
local csmodels = PS.CSModels

local empty = {}
local COLOR_WHITE = Color(255, 255, 255)
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect

function BASE:OnPlayerDraw(ply, flags, ent, mods)
    if PS.GamemodeCheck(self) or not self.Props or not PS:CanSeeAccessory(ply) then return end

    self:SetupModels()
    self:DrawModels(ply, ent, csmodels[self.ID], mods)
end

function BASE:OnPreviewDraw(w, h, panel)
    self:SetupModels()
    self:DrawModels(nil, panel.Entity, csmodels[self.ID], nil)
end

function BASE:ModifyClientsideModel(ply, model, pos, ang)
    local mods = ply:PS_GetModifiers(self.ID)
    mods.pos = mods.pos or Vector()
    mods.ang = mods.ang or Angle()
    mods.scale = mods.scale or 1

    -- Offset
    pos = pos + ang:Forward() * mods.pos.x - ang:Right() * mods.pos.y + ang:Up() * mods.pos.z
    ang:RotateAroundAxis(ang:Forward(), mods.ang.p)
    ang:RotateAroundAxis(ang:Right(), -mods.ang.y)
    ang:RotateAroundAxis(ang:Up(), -mods.ang.r)
    model:SetModelScale(mods.scale)

    return model, pos, ang
end

function BASE:SetupModels()
    local models = csmodels[self.ID]

    -- Check if models changed path (were edited by admin)

    -- Create
    if not models then
        csmodels[self.ID] = self:CreateModels(false)
        models = csmodels[self.ID]
    end
end

function BASE:DrawModels(ply, ent, models, mods)
    mods = mods or empty
    ent = ent or ply

    -- Transform entities
    for _, model in ipairs(models) do
        local data = self.Props[model.ID]
        -- Get Bone pos, angles
        local pos, ang = self:GetBonePosAng(ent, data.bone)
        if not pos or not ang then continue end

        model.LastPaint = CurTime()
        -- Apply modifications from mods and prop
        pos = pos + ang:Forward() * data.pos.x - ang:Right() * data.pos.y + ang:Up() * data.pos.z
        if ply then
            model, pos, ang = self:ModifyClientsideModel(ply, model, pos, ang)
        end

        ang:RotateAroundAxis(ang:Forward(), data.ang.p)
        ang:RotateAroundAxis(ang:Right(), -data.ang.y)
        ang:RotateAroundAxis(ang:Up(), -data.ang.r)
        local matrix = Matrix()
        matrix:SetScale(data.scale or Vector(1, 1, 1))

        model:SetPos(pos)
        model:SetAngles(ang)
        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
        model:SetMaterial(data.material or "")
        model:SetupBones()
        model:EnableMatrix("RenderMultiply", matrix)

        -- Apply color
        if data.colorabletype == "playercolor" then
            local color = ply:GetPlayerColor()
            render.SetBlend(1)
            render.SetColorModulation(color.x, color.y, color.z)
        elseif data.colorabletype == "rainbow" then
            local color = HSVToColor(RealTime() * (data.speed or 70) % 360, 1, 1)
            render.SetBlend(1)
            render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        else
            render.SetBlend(data.alpha or 1)
            local color = data.color or COLOR_WHITE
            render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        end

        if data.animated then
            model:FrameAdvance((RealTime() - model.LastPaint) * (data.animspeed or 1))
        end

        model:DrawModel()

        model:SetRenderOrigin()
        model:SetRenderAngles()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
    end
end

function BASE:CreateModels()
    local models = {}

    if not self.Props then return end
    for id, prop in pairs(self.Props) do
        -- We show ERRORs so admins know when model is missing
        --[[if not file.Exists(prop.model, "GAME") and not show_error_mdl then
            print(string.format("[LBG PointShop] Model %s from %s does not exist, skipping...", prop_id, item.ID))
            continue
        end]]

        local mdl = ClientsideModel(prop.model)
        if not mdl then
            print(string.format("[LBG PointShop] Could not create model %s from %s, skipping...", prop_id, item.ID))
            return empty
        end

        mdl.IsError = not file.Exists(prop.model, "GAME")
        mdl.ID = id
        mdl:SetNoDraw(true)
        mdl:DrawShadow(false)
        mdl:DestroyShadow()

        local matrix = Matrix()
        matrix:SetScale(prop.scale or Vector(1, 1, 1))
        mdl:EnableMatrix("RenderMultiply", matrix)
        mdl:SetMaterial(prop.material or "")

        table.insert(models, mdl)
    end

    return models
end

function BASE:GetBonePosAng(ent, bone)
    bone = ent:LookupBone(bone)
    if not bone then return Vector(), Angle() end
    local matrix = ent:GetBoneMatrix(bone)
    if matrix then return matrix:GetTranslation(), matrix:GetAngles() end
    return Vector(), Angle()
end

function BASE:OnCustomizeSetup(panel, mods)
    mods.pos = mods.pos or Vector()
    mods.ang = mods.ang or Angle()
    mods.scale = mods.scale or 1

    self:SetupThinker(panel, mods, {
        pos = Vector(mods.pos), ang = Angle(mods.ang), scale = mods.scale
    }, function(a, b)
        return not PS.TablesEqual(a, b)
    end, function(reference, copy)
        return {
            pos = Vector(reference.pos),
            ang = Angle(reference.ang),
            scale = reference.scale
        }
    end)

    PS.AddSlider(panel, "Position X", mods.pos.x, self.PositionMinMax[1], self.PositionMinMax[2], 0.5, function(value)
        mods.pos.x = value
    end)
    PS.AddSlider(panel, "Position Y", mods.pos.y, self.PositionMinMax[1], self.PositionMinMax[2], 0.5, function(value)
        mods.pos.y = value
    end)
    PS.AddSlider(panel, "Position Z", mods.pos.z, self.PositionMinMax[1], self.PositionMinMax[2], 0.5, function(value)
        mods.pos.z = value
    end):DockMargin(0, 0, 0, 32)
    PS.AddSlider(panel, "Angle P", mods.ang.p, -180, 180, 0.5, function(value)
        mods.ang.x = value
    end)
    PS.AddSlider(panel, "Angle Y", mods.ang.y, -180, 180, 0.5, function(value)
        mods.ang.y = value
    end)
    PS.AddSlider(panel, "Angle R", mods.ang.r, -180, 180, 0.5, function(value)
        mods.ang.z = value
    end):DockMargin(0, 0, 0, 32)

    PS.AddSlider(panel, "Scale", mods.scale, self.ScaleMinMax[1], self.ScaleMinMax[2], 0.05, function(value)
        mods.scale = value
    end):SetDefaultValue(1)
end

function BASE:OnPanelPaint(panel)
    if panel.PanelMaterial then
        surface_SetDrawColor(255, 255, 255, 255)
        surface_SetMaterial(panel.PanelMaterial)
        surface_DrawTexturedRect(0, 0, w, h)
    end
end

function BASE:OnPanelSetup(panel)
    -- Instead of rendering the model, render a premade image
    if self.PanelImage then
        panel.PanelMaterial = Material(self.PanelImage)
        return
    end

    local mdl = panel:Add("DModelPanel")
    mdl:SetMouseInputEnabled(false)
    mdl:Dock(FILL)
    mdl:SetModel(PS.Config.GetDefaultPlayermodel())
    mdl.FarZ = 32768

    local ent = mdl.Entity
    ent.GetPlayerColor = function() return Vector(1, 1, 1) end

    -- Rotates entity (needs to be done before freezing model)
    local data = self.CameraData
    if data.angle then
        mdl.Entity:SetAngles(data.angle)
    end

    -- There is no way to stop a DModelPanel from breathing
    -- so instead we manually set each bone's position manually
    -- (found by searching gmod discord)
    ent:SetupBones()
    local bones = {}
    for i = 0, ent:GetBoneCount() - 1 do
        if ent:GetBoneName(i) == "__INVALIDBONE_" then continue end

        local matrix = ent:GetBoneMatrix(i)
        if not matrix then continue end

        local mat = Matrix()

        mat:SetTranslation(matrix:GetTranslation())
        mat:SetAngles(matrix:GetAngles())

        bones[i] = mat
    end

    -- Stops model from breathing
    ent:AddCallback("BuildBonePositions", function(this)
        for id, matrix in pairs(bones) do
            ent:SetBoneMatrix(id, matrix)
        end
    end)

    -- Stops model from rotating
    mdl.LayoutEntity = function(this, _ent)
    end

    mdl.PostDrawModel = function(this, _ent)
        self:DrawModels(nil, _ent, this.Props, nil)
    end

    mdl.OnRemove = function(this)
        SafeRemoveEntity(this.Entity)
        for _, model in pairs(this.Props) do
            SafeRemoveEntity(model)
        end
    end

    -- Focus playermodel in different positions
    if data then
        mdl:SetCamPos(data.pos)
        mdl:SetLookAt(data.target)
        mdl:SetFOV(data.fov)
    end

    -- Add models
    mdl.Props = self:CreateModels()
end

return PS:RegisterBase(BASE)