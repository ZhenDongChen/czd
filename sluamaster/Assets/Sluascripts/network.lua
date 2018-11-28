local print = print
local require = require
local error = error
local defineenum = require "defineenum"
local os = require "common.octets"
local message = require "common.message"
local allmsg = require "msg.allmsg"
local gameevent = require "gameevent"
local serverInfos = nil
local uimanager = require("uimanager")
local create_by_id = message.create_by_id
local dispatch = message.dispatch
local selectedServer
local session
local reconnectCount
local addressIndex
local serverIndex
local serverlist



local MapContexProtocolIndexSet


local function send(msg)
    message.send(msg, false)
end

local function create_and_send(msg_type_name, msg)
	
    message.create_and_send(msg_type_name, msg, false)
end

local function add_listener(msg_type_name, func)
	return message.add_listener(msg_type_name, func)
end

local function remove_listener(id)
	message.remove_listener(id)
end

local function add_listeners(listeners,nm)
	return message.add_listeners(listeners,nm)
end

local function remove_listeners(ids)
	message.remove_listeners(ids)
end

local function on_abort()
	printyellow("connect abort")
	if session.AutoReconnect then
		reconnectCount = reconnectCount + 1
        local fakeReconnectCount = reconnectCount - 4
        if fakeReconnectCount > 0 then
            if fakeReconnectCount > LocalString.MaxReconnectCount then
                session.AutoReconnect = false,
                uimanager.hide("common.dlgdialogbox_disconnetion")
                uimanager.ShowSingleAlertDlg{
                    content=LocalString.MaxReconnectInfo,
                    callBackFunc=
                    function()
                        local login = require"login"
                        login.role_logout(login.LogoutType.to_login)
                    end
                }
            else
                uimanager.showorrefresh("common.dlgdialogbox_disconnetion",{tip = string.format(LocalString.Network_ReconnectTime,fakeReconnectCount)})
            end
        end
    end
    gameevent.evt_system_message:trigger("network_abort")
end

local function on_connect()
	printyellow("connect succ")
    gameevent.evt_system_message:trigger("network_connected")
end

local function on_disconnect()
	on_abort()
end

local function reset_reconnect_count()
	print("reset_reconnect_count")
    reconnectCount = 0
end

local osnew = os.new
local ospopint = os.pop_int
local function onmsg_RoleProtocols(proto)
    local roleid = proto.roleid
    local octs = proto.data
    local stream = osnew(octs)
    local typeid = proto.ptype
    local msg = create_by_id(typeid)
    if not msg then
        print("unknown RoleProtocol message. id" .. typeid .. ", size" .. #octs)
    end
    
    msg:_decode(stream)
    if Local and Local.LogProtocol then
        if msg.roleid then
            print("RoleProtocol.roleid override type:" .. msg._name .. "'s field roleid")
        end
        msg.roleid = roleid
        print("=== recv RoleProtocol.", msg)
    else
        msg.roleid = roleid
    end
    dispatch(msg)
end

local function onmsg_MapContexProtocol(proto)
	if MapContexProtocolIndexSet:find(proto.index) then
		return
	end
	MapContexProtocolIndexSet:insert(proto.index)
	local octs = proto.data
	local stream = osnew(octs)
	local typeid = ospopint(stream)
	local msg = create_by_id(typeid)
	if not msg then
		error("unknown MapContexProtocol message. id" .. typeid .. ", size" .. #octs)
	end
	msg:_decode(stream)
	if Local and Local.LogProtocol then
		print("=== recv MapContexProtocol.", msg)
	end
	dispatch(msg)
end

local function onmsg_MapContexProtocols(proto)
	local octs = proto.data
	local stream = osnew(octs)
	for i = 0, proto.count-1 do
		local typeid = ospopint(stream)
		local msg = create_by_id(typeid)
		msg:_decode(stream)
		if not MapContexProtocolIndexSet:find(i) then
			if not msg then
				error("unknown MapContexProtocols message. id" .. typeid .. ", size" .. #octs)
			end
			if Local and Local.LogProtocol then
				print("=== recv MapContexProtocols.", msg)
			end
			dispatch(msg)
			MapContexProtocolIndexSet:insert(i)
		else
			print("=== ignore MapContexProtocols.", msg)
		end
	end
end

local function onmsg_SLeaveMap(msg)
	MapContexProtocolIndexSet:clear()
end

local function reset_last_reconnect_time()
    session:ResetLastReconnectTime()
end


local function connect()
    print("connect()")
    session.AutoReconnect = false
	local callback = LuaLinkcallback(on_connect, on_abort, on_disconnect)
	session:Connect(
		selectedServer.addresses[addressIndex].host, selectedServer.addresses[addressIndex].port,
		8192, 8192, 16384, 16384,
		callback)
end

local function reconnect()
	printyellow("reconnect()",selectedServer.addresses[addressIndex].host,selectedServer.addresses[addressIndex].port)
    session.AutoReconnect = true
    session:Close()
end

local function close(autoReconnect)
    printyellow("close!!!!!!!!!!!")
    session.AutoReconnect = autoReconnect == true
    if session.Connected then
        session:Close()
    end
end

local function GetNewDefaultServer(slist)
    local newServers = {}
    for idx,v in ipairs(slist) do
        if v.isNew then
            table.insert(newServers,idx)
        end
    end

    local loginServer
    if #newServers>0 then
        local ss = math.random(#newServers)
        loginServer = newServers[ss]
    else
        loginServer = #slist
    end
    return loginServer
end

local function GetDefaultLogin()
        if UserConfig.DefaultServer and UserConfig.DefaultServer <= #serverlist then
            return UserConfig.DefaultServer
        end
        if UserConfig.DefaultLogin and UserConfig.DefaultLogin ~= 8 and UserConfig.DefaultLogin <= #serverlist then
            return UserConfig.DefaultLogin
        end
        local loginServer = GetNewDefaultServer(serverlist)
        UserConfig.DefaultLogin = loginServer
        UserConfig.DefaultServer = loginServer
        SaveUserConfig()
        return UserConfig.DefaultServer
end

local function GetAddressIndex(addresses)
    local TimeUtils = require"common.timeutils"
    local tm = TimeUtils.GetLocalTime()
    local strTime = tostring(tm)
    local revTime = strTime:reverse()
    local subTime = revTime:sub(1,6)
    local numTime = tonumber(subTime)
    math.randomseed(numTime)
    local ret
    for i=1,7 do
        ret = math.random(#addresses)
    end
    return ret
end

local function updateServerGlobalVars()
    g_tbFunctionSet=selectedServer;
end

local function SetServer()
    serverlist = GetServerList()
    serverIndex = GetDefaultLogin()
    selectedServer = serverlist[serverIndex]
    addressIndex = GetAddressIndex(selectedServer.addresses)
	
	updateServerGlobalVars()
end

local function init()
	add_listener("lx.gs.map.msg.SLeaveMap", onmsg_SLeaveMap)
	add_listener("map.msg.RoleProtocols", onmsg_RoleProtocols)
	add_listener("map.msg.MapContexProtocol", onmsg_MapContexProtocol)
	add_listener("map.msg.MapContexProtocols", onmsg_MapContexProtocols)
	session = Aio.Session.Instance
    SetServer()
	reconnectCount = 0
	MapContexProtocolIndexSet = newset()
	
end

local function setSelectedServer(ss)
	if serverIndex ~= ss then
	    selectedServer = serverlist[ss]
		addressIndex = GetAddressIndex(selectedServer.addresses)
		serverIndex = ss
	end
	
	
	updateServerGlobalVars()
end

local function getSelectedServer()
--	print("getSelectedServer")
    return selectedServer,addressIndex
end



return {
	init = init,
	send = send,
	create_and_send = create_and_send,
	add_listener = add_listener,
    remove_listener = remove_listener,
    add_listeners = add_listeners,
    remove_listeners = remove_listeners,
	connect = connect,
	close = close,
    setSelectedServer = setSelectedServer,
    reconnect = reconnect,
	getSelectedServer = getSelectedServer,
    reset_reconnect_count = reset_reconnect_count,
    reset_last_reconnect_time   = reset_last_reconnect_time,
    GetDefaultLogin = GetDefaultLogin,
    GetAddressIndex = GetAddressIndex,
    SetServer = SetServer,
}
