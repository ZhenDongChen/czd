local breakSocketHandle,debugXpCall = require("LuaDebugjit")("localhost",7003)
LuaTimer.Add(0,1000,function(id)
    breakSocketHandle()
end)

local require = require

require "global"

local gameevent = require "gameevent"
local message = require "common.message"
local modules = require "modules"

local ipairs = ipairs
local logError = logError

local function init_modules()
    printyellowmodule(Local.LogModuals.Moduals,"init modules")

	for _, module_name in ipairs(modules) do
		local mod = require(module_name)
		if mod then
            printyellowmodule(Local.LogModuals.Moduals,string.format("init module:%s", module_name))
			mod.init()
		else
			logError("module:%s load fail!", module_name)
		end
	end
end


local function refresh_app_version()
	local ver_file_name
	if IsAndroid then
		ver_file_name = "apk_version.txt"
	elseif IsIos then
		ver_file_name = "app_version.txt"
	else
		print("not ios or android.")
		return
	end
	local ins = Game.Platform.Interface.Instance
	local cur_version = ins:GetVersion()
	local ver_path_name = ins:GetPath(ver_file_name)
	print("== version path:" .. ver_path_name)
	local ver_file = io.open(ver_path_name, "r")
	local old_version
	if ver_file then
		old_version = ver_file:read("*all")
		ver_file:close()
	else
		old_version = "0.0.0"
		print("== open old appversion fail.")
	end
	print("== old_version:" .. old_version .. ", new_version:" .. cur_version)
	if old_version ~= cur_version then
		print("== need refresh appversion")
		local new_ver_file, err = io.open(ver_path_name, "w")
		if new_ver_file then
			new_ver_file:write(cur_version)
			new_ver_file:close()
			print("== refresh appversion succ")
		else
			print("== refresh appversion fail. reason:" .. err)
		end
	end
end

local function init()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)

	printyellowmodule(Local.LogModuals.Moduals,"script start.")
	math.randomseed(os.time())
	init_modules()
    Time:Init()
	refresh_app_version()
    utils.nowTime = os.date("*t", os.time())
end

local evt_update = gameevent.evt_update
local function update()
    utils.nowTime = os.date("*t", os.time())
    Time:SetDeltaTime(UnityEngine.Time.deltaTime, UnityEngine.Time.unscaledDeltaTime)
	evt_update:trigger()
end


local evt_late_update = gameevent.evt_late_update
local evt_late_update2 = gameevent.evt_late_update2
local function late_update()
	evt_late_update:trigger()
	evt_late_update2:trigger()
end

local evt_second_update = gameevent.evt_second_update
local function second_update(now)
	evt_second_update:trigger(now)
end

local evt_fixed_update = gameevent.evt_fixed_update
local function fixed_update()
    evt_fixed_update:trigger()
end

local evt_system_message = gameevent.evt_system_message
local function on_message(str)
	printyellowmodule(Local.LogModuals.Moduals,string.format("on_message:%s", str))
	local target,data = string.match(str,"^(%w*):(.*)$")
    if nil == target then
        target = str
    end
	evt_system_message:trigger(target,data)
end


return {
	init = init,
	update = update,
	late_update = late_update,
	second_update = second_update,
    fixed_update = fixed_update,
    recv_msg = message.receive,

	on_message = on_message,
}
