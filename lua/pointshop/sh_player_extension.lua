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