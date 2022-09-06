local Player = FindMetaTable('Player')

-- items
function Player:PS_GetItems()
    return self.PS_Items or {}
end

function Player:PS_HasItem(item_id)
    if not self.PS_Items then return false end

    return self.PS_Items[item_id] and true or false
end

function Player:PS_HasItemEquipped(item_id)
    if not self:PS_HasItem(item_id) then return false end

    return self.PS_Items[item_id].Equipped or false
end

function Player:PS_BuyItem(item_id)
    if self:PS_HasItem(item_id) then return false end
    if not self:PS_HasPoints(PS.Config.CalculateBuyPrice(self, PS.Items[item_id])) then return false end
    net.Start('PS_BuyItem')
    net.WriteString(item_id)
    net.SendToServer()
end

function Player:PS_SellItem(item_id)
    if not self:PS_HasItem(item_id) then return false end
    net.Start('PS_SellItem')
    net.WriteString(item_id)
    net.SendToServer()
end

function Player:PS_EquipItem(item_id)
    if not self:PS_HasItem(item_id) then return false end
    net.Start('PS_EquipItem')
    net.WriteString(item_id)
    net.SendToServer()
end

function Player:PS_HolsterItem(item_id)
    if not self:PS_HasItem(item_id) then return false end
    net.Start('PS_HolsterItem')
    net.WriteString(item_id)
    net.SendToServer()
end

-- points
function Player:PS_GetPoints()
    return self.PS_Points or 0
end

function Player:PS_HasPoints(points)
    return self:PS_GetPoints() >= points
end

-- clientside models
function Player:PS_AddClientsideModel(id)
    local item = PS.Items[id]
    if not item then return false end
    PS.ClientsideModels[self] = PS.ClientsideModels[self] or {}
    local models = PS.ClientsideModels[self]
    -- Remove existing
    if models[id] then
        for _, mdl in ipairs(models[id]) do
            SafeRemoveEntity(mdl)
        end
    end

    models[id] = {}
    if not item.Props then return end

    -- Adds models
    for prop_id, prop in pairs(item.Props) do
        if not file.Exists(prop.model, "GAME") then
            print(string.format("[LBG PointShop] Model %s from %s does not exist, skipping...", prop_id, item.ID))
            continue
        end

        local mdl = ClientsideModel(prop.model)
        if not mdl then
            print(string.format("[LBG PointShop] Could not create model %s from %s, skipping...", prop_id, item.ID))
        return
        end

        mdl:SetNoDraw(true)
        mdl:DrawShadow(false)
        mdl:DestroyShadow()

        local matrix = Matrix()
        matrix:SetScale(prop.scale or Vector(1, 1, 1))
        mdl:EnableMatrix("RenderMultiply", matrix)
        mdl:SetMaterial(prop.material or "")
        mdl.data = prop_id

        local color = prop.color or Color(255, 255, 255)
        mdl.Color = Vector(color.r / 255, color.g / 255, color.b / 255)

        table.insert(models[id], mdl)
    end
end

function Player:PS_RemoveClientsideModel(id)
    local item = PS.Items[id]
    if not item then return false end
    PS.ClientsideModels[self] = PS.ClientsideModels[self] or {}
    local models = PS.ClientsideModels[self]

    if models[id] then
        for _, mdl in ipairs(models[id]) do
            SafeRemoveEntity(mdl)
        end
    end

    models[id] = nil
end