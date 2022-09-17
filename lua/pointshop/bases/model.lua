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

function BASE:OnEquip(ply, mods)
    if self:GamemodeCheck() or ply:PS_IsSpectator() or not ply:PS_CanPerformAction(self.ID) then return end
    ply:PS_AddClientsideModel(self.ID)
end

function BASE:OnHolster(ply)
    if self:GamemodeCheck() then return end
    ply:PS_RemoveClientsideModel(self.ID)
end

function BASE:OnSpawn(ply, mods)
    self:OnEquip(ply, mods)
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
        for _, model in ipairs(this.Props) do
            render.SetBlend(model.alpha)
            render.SetColorModulation(model.Color.x, model.Color.y, model.Color.z)
            model:DrawModel()
        end
    end

    mdl.OnRemove = function(this)
        SafeRemoveEntity(this.Entity)
        for _, model in ipairs(this.Props) do
            SafeRemoveEntity(model)
        end
    end

    -- Focus playermodel in different parts
    if data then
        mdl:SetCamPos(data.pos)
        mdl:SetLookAt(data.target)
        mdl:SetFOV(data.fov)
    end

    -- Add models
    mdl.Props = {}

    for id, prop in pairs(self.Props) do
        if not file.Exists(prop.model, "GAME") then continue end
        local model = prop.model
        model = ClientsideModel(model)
        if not model then continue end
        model:SetNoDraw(true)
        model:DrawShadow(false)
        model:DestroyShadow()
        table.insert(mdl.Props, model)

        local pos, ang = self:GetBonePosAng(mdl.Entity, prop.bone)
        if not pos or not ang then continue end
        -- Offset
        pos = pos + ang:Forward() * prop.pos.x - ang:Right() * prop.pos.y + ang:Up() * prop.pos.z
        ang:RotateAroundAxis(ang:Forward(), prop.ang.p)
        ang:RotateAroundAxis(ang:Right(), -prop.ang.y)
        ang:RotateAroundAxis(ang:Up(), -prop.ang.r)
        model:SetPos(pos)
        model:SetAngles(ang)
        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
        model:SetupBones()
        local matrix = Matrix()
        matrix:SetScale(prop.scale or Vector(1, 1, 1))
        model:EnableMatrix("RenderMultiply", matrix)
        model:SetMaterial(prop.material or "")
        model.alpha = prop.alpha or 1
        local color = prop.color or Color(255, 255,255)
        model.Color = Vector(color.r / 255, color.g / 255, color.b / 255)
    end
end

local surface_SetDrawColor, surface_SetMaterial, surface_DrawTexturedRect
if CLIENT then
    surface_SetDrawColor = surface.SetDrawColor
    surface_SetMaterial = surface.SetMaterial
    surface_DrawTexturedRect = surface.DrawTexturedRect
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

function BASE:OnPanelPaint(panel)
    if panel.PanelMaterial then
        surface_SetDrawColor(255, 255, 255, 255)
        surface_SetMaterial(panel.PanelMaterial)
        surface_DrawTexturedRect(0, 0, w, h)
    end
end

function BASE:OnPlayerDraw(ply, flags, ent, mods)
    if self:GamemodeCheck() or not self.Props or not PS.ClientsideModels[ply] or not PS:CanSeeAccessory(ply) then return end
    local models = PS.ClientsideModels[ply]
    if not models or not models[self.ID] then return end

    for _, model in ipairs(models[self.ID]) do
        local data = self.Props[model.data]
        local pos, ang = self:GetBonePosAng(ent or ply, data.bone)
        if not pos or not ang then continue end
        model.LastPaint = RealTime()
        -- Offset
        pos = pos + ang:Forward() * data.pos.x - ang:Right() * data.pos.y + ang:Up() * data.pos.z
        model, pos, ang = self:ModifyClientsideModel(ply, model, pos, ang)
        ang:RotateAroundAxis(ang:Forward(), data.ang.p)
        ang:RotateAroundAxis(ang:Right(), -data.ang.y)
        ang:RotateAroundAxis(ang:Up(), -data.ang.r)
        model:SetPos(pos)
        model:SetAngles(ang)
        model:SetRenderOrigin(pos)
        model:SetRenderAngles(ang)
        model:SetupBones()
        local matrix = Matrix()
        matrix:SetScale(data.scale or Vector(1, 1, 1))
        model:EnableMatrix("RenderMultiply", matrix)
        model:SetMaterial(data.material or "")
        -- Color
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
            render.SetColorModulation(model.Color.r, model.Color.b, model.Color.b)
        end

        model:DrawModel()

        if data.animated then
            model:FrameAdvance((RealTime() - model.LastPaint) * (data.animspeed or 1))
        end

        model:SetRenderOrigin()
        model:SetRenderAngles()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
    end
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

function BASE:ToString()
    return "[model] " .. self.ID
end

function BASE:GetBonePosAng(ent, bone)
    bone = ent:LookupBone(bone)
    if not bone then return Vector(), Angle() end
    local matrix = ent:GetBoneMatrix(bone)
    if matrix then return matrix:GetTranslation(), matrix:GetAngles() end
    return Vector(), Angle()
end

return PS:RegisterBase(BASE)