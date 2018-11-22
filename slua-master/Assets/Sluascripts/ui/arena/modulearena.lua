local ArenaManager 		= require("ui.arena.single.arenamanager")
local PVPManager        = require("ui.arena.multi.pvp.pvpmanager")
local UIManager         = require("uimanager")
local citywarmanager 	  = require "ui.citywar.citywarmanager"

local function init()
    PVPManager.init()

end

local function Start()
    ArenaManager.Start()
end

local function GetOpenLevel()
    local level = ArenaManager.GetOpenLevel()
    return level
end
local function ShowLevelAlert()
    local infoCfg = ConfigManager.getConfig("arenainfo")
    local alertContent = string.format(infoCfg["levelalert"].content, tostring(GetOpenLevel()))
    UIManager.ShowSingleAlertDlg({content = alertContent})
end

local function UnRead()
    local arenaUnRead = ArenaManager.UnRead()
    local teamfightUnRead = PVPManager.UnRead()
    local citywarUnRead = citywarmanager.UnRead()
    return arenaUnRead or teamfightUnRead or citywarUnRead
end

return {
    init = init,
    Start = Start,
    GetOpenLevel = GetOpenLevel,
    ShowLevelAlert = ShowLevelAlert,
    UnRead = UnRead,
}