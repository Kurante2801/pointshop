PS = PS or {}
PS.__index = PS

include("pointshop/sh_config.lua")
include("pointshop/sh_player_extension.lua")
include("pointshop/sh_init.lua")

if SERVER then
    include("pointshop/sv_init.lua")
    include("pointshop/sv_player_extension.lua")

    AddCSLuaFile("pointshop/sh_config.lua")
    AddCSLuaFile("pointshop/sh_init.lua")
    AddCSLuaFile("pointshop/sh_player_extension.lua")

    AddCSLuaFile("pointshop/cl_init.lua")
    AddCSLuaFile("pointshop/cl_player_extension.lua")
    AddCSLuaFile("pointshop/vgui/tdlib.lua")
    AddCSLuaFile("pointshop/vgui/dpointshop_menu.lua")
    AddCSLuaFile("pointshop/vgui/dpointshop_elements.lua")
else
    include("pointshop/cl_init.lua")
    include("pointshop/cl_player_extension.lua")
    include("pointshop/vgui/tdlib.lua")
    include("pointshop/vgui/dpointshop_menu.lua")
    include("pointshop/vgui/dpointshop_elements.lua")
end