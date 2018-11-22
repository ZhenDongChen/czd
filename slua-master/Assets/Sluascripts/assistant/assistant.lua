local FriendManager 	= require("ui.friend.friendmanager")
local TitleManager 		= require("ui.title.titlemanager")
local TalismanManager 	= require("ui.playerrole.talisman.talismanmanager")
local RideManager 		= require("ui.ride.ridemanager")
local ModuleArena 		= require("ui.arena.modulearena")
local ActivityManager	= require("ui.activity.dlgactivitymanager")
local CharacterManager  = require("character.charactermanager")
local WorldBossManager =require("ui.activity.worldboss.worldbossmanager")

local function init()
	 FriendManager.Start()
     TitleManager.Start()
	 TalismanManager.Start()
	 RideManager.Start()
	 ActivityManager.Start()
	 ModuleArena.Start()
	 CharacterManager.Start()
	 WorldBossManager.Start()
end

---只在login.lua中被login_sucess调用:Assistant.init()

return {
	init = init,
}
