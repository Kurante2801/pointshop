local Player = FindMetaTable('Player')

-- Because of the huge variaty of admin mods and their various ways of handling usergroups.
-- This had to be done..
function Player:PS_GetUsergroup()
    if (self.EV_GetRank) then return self:EV_GetRank() end
    if (serverguard) then return serverguard.player:GetRank(self) end
    -- add for each conflicting admin mod.

    return self:GetNWString('UserGroup')
end

function Player:PS_IsSpectator()
    if TEAM_SPECTATOR ~= nil and self:Team() == TEAM_SPECTATOR then return true end
    if TEAM_SPEC ~= nil and self:Team() == TEAM_SPEC then return true end
    if self.Spectating then return true end
end

function Player:PS_Think()
    for item_id, item in pairs(self.PS_Items) do
        local ITEM = PS.Items[item_id]

        if item.Equipped then
            ITEM:OnThink(self, item.Modifiers)
        end
    end
end

function Player:PS_Move(data)
    for item_id, item in pairs(self.PS_Items or {}) do
        local ITEM = PS.Items[item_id]

        if item.Equipped then
            ITEM:OnMove(self, item.Modifiers, data)
        end
    end
end

function Player:PS_GetModifiers(id)
    return (self.PS_Items and self.PS_Items[id]) and self.PS_Items[id].Modifiers or {}
end