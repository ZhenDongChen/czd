local server
local gameevent         = require "gameevent"


local logger
local function _FormatMessage(prefix, message)
	return " ["..prefix.."] "..message
end

local function LogDebug(message)
    if not Local.LogManager then return end
	local login = require("login")
	logger:Log(login.get_loginrole(), _FormatMessage("Debug", message))
end

local function LogInfo(message)
    if not Local.LogManager then return end
	local login = require("login")
	logger:Log(login.get_loginrole(), _FormatMessage("Info", message))
end

local function LogError(message)
    if not Local.LogManager then return end
	local login = require("login")
	logger:Log(login.get_loginrole(), _FormatMessage("Error", message))
end

local function ProcessMsg()
	logger:process(20);
end

local function OnMsgLog(log)
    print(log)
end

local MsgLog = "log"
local function init()
	gameevent.evt_system_message:add(MsgLog, OnMsgLog)
	server = GetServerInfos()
	gameevent.evt_update:add(ProcessMsg)
	logger = Aio.Logger(server.logserver.host, server.logserver.port);
end


return {
	init = init,
	LogDebug = LogDebug,
	LogInfo = LogInfo,
	LogError = LogError,
}
