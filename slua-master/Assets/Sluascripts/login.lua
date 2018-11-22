local require = require
local print = print
local printt = printt

local network = require "network"
local message = require "common.message"
local uimanager = require("uimanager")
local scenemanager = require("scenemanager")
local TimeUtils = require("common.timeutils")
local CharacterManager = require "character.charactermanager"
local message = require "common.message"
local ConfigManager = require("cfg.configmanager")
local gameevent = require "gameevent"
local AudioMgr = require "audiomanager"
local ObjPoolsManager = require("objectpoolsmanager")
local CameraManager = require "cameramanager"
local errMgr = require "assistant.errormanager"
local Assistant = require("assistant.assistant")
local EctypeManager = require "ectype.ectypemanager"
local PetManager = require"character.pet.petmanager"
local httpLog = require("httplog")
local defineenum = require "defineenum"
local ItemManager        = require("item.itemmanager")

local SceneMgr = Game.SceneMgr

local ToString = Slua.ToString
local ToBytes = Slua.ToBytes

local resverurl
local selectedroleid = 0
local loginroleid = 0
local LoggedInPlatform
local serverid = 0
local userid

local username=""
local token

local isOnline = false
local textTime

-- 新增变量
local roles = { }
local firstlogin = true

local nextSendCPingTime
local SEND_CPING_INTERVAL = 10

local nextCheckResVerTime
local CHECK_RESVER_INTERVAL = 600


local KEEPALIVE_SEND_INTERVAL = 10
local nextSendKeepaliveTime = 0
local recvKeepaliveExpireTime
local KEEPALIVE_EXPIRE_TIME = 30

local LogoutType = enum {
    "to_login",
    "to_choose_player",
}

----------------------提供外部访问的 函数开始 --------------------

local function remove_role(idx)
    table.remove(roles, idx)
end

local function remove_role(role_index)
    local srole = roles[role_index]
    local delete_role_id = roles[role_index].roleid
    local re = lx.gs.login.CDeleteRole( { roleid = delete_role_id })
    network.send(re)
end


local function get_roles()
    return roles
end

local function get_loginrole()
    return loginroleid
end


local function create_role(rolename, roleprofession, rolegender)
    local platformtype = 0
    if Application.platform == UnityEngine.RuntimePlatform.Android then
        platformtype = 0
    elseif Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
        platformtype = 1
    elseif Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
        if Game.Platform.Interface.Instance:GetPlatform() == "Android" then
            platformtype = 0
        else
            platformtype = 1
        end
    end
    local re = lx.gs.login.CCreateRole( { name = rolename, profession = roleprofession, gender = rolegender, plattype = platformtype })
    network.send(re)

end




----------------------提供外部访问的  函数结束 -------------------
local errcode2msg = {
    LocalString.ERR_FORMATE_INVALID,
    LocalString.ERR_INVALID,
    LocalString.ERR_TYPE_NOT_MATCH,
    LocalString.ERR_CODE_IS_USED,
    LocalString.ERR_CODE_IS_EXPIRATED,
    LocalString.ERR_CODE_IS_NOT_OPEN,
    LocalString.ERR_FUNCTION_IS_CLOSED,
    LocalString.ERR_PLATFORM_NOT_MATCH,
    LocalString.ERR_HAS_ALEADY_ACTIVATED,
    LocalString.ERR_NETWORK,
    LocalString.ERR_EXCEED_DAY_USENUM,
    LocalString.ERR_EXCEED_ALL_USENUM,
    LocalString.ERR_INTERNAL,
	LocalString.ERR_INVALID,
    LocalString.ERR_LEVEL_TOO_LOWE,
    LocalString.ERR_LEVEL_TOO_HIGH,
}

local function  getErrMsg(errcode)
    return errcode2msg[errcode] or LocalString.LOGIN_InvalidActivationCode
end

local function SubmitUserInfo(subtype)
    local selectedServer = network.getSelectedServer()
    local roleid = tostring(PlayerRole:Instance().m_Id)
    local rolelevel = tostring(PlayerRole:Instance().m_Level)
    printyellow("submituserinfo rolelevel " .. rolelevel)
    printyellow("submituserinfo roleid " .. roleid)
    printyellow("login time serverid", serverid)
    local name = PlayerRole:Instance().m_Name
    local createTime = PlayerRole:Instance().m_CreateTime
    printyellow("login time=",createTime)
    Game.Platform.Interface.Instance:SubmitUserInfo(subtype, roleid, name, rolelevel, serverid, selectedServer.name, tostring(createTime));
end

local function refreshPing(ping)
    if uimanager.isshow("dlguimain") then

        local DlgUIMain = require("ui.dlguimain")
        DlgUIMain.refreshTime(ping)
    end

end

local function role_login(role_index)
    selectedroleid = role_index
    local roleid = roles[selectedroleid].roleid
    -- TODO 发送协议
    local re = lx.gs.login.CRoleLogin( { roleid = roleid })
    network.send(re)
end


local function login_sucess(roleinfo, roledetail)

    if not ObjPoolsManager.IsInited() then
        ObjPoolsManager.init()
    end
    local PlayerRole = require "character.playerrole"
    PlayerRole:Instance():init(roleinfo, roledetail)
    CharacterManager.AddCharacter(roleinfo.roleid, PlayerRole:Instance())
    Assistant.init()
    loginroleid = roleinfo.roleid
	
	if Application.platform == UnityEngine.RuntimePlatform.Android then
		Game.Platform.Interface.Instance:InitVoiceSDK(loginroleid)
    elseif Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then    
		Game.Platform.Interface.Instance:InitVoiceSDK(loginroleid)
    else
    end
end


local function set_username(value)
    if Application.platform ~= UnityEngine.RuntimePlatform.IPhonePlayer 
		and Application.platform ~= UnityEngine.RuntimePlatform.Android then
        UnityEngine.PlayerPrefs.SetString("username", value);
        username = value
    end
end

local function LoginSuccess()
    if not LoggedInPlatform then
        LoggedInPlatform = true
		if Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer
			or Application.platform == UnityEngine.RuntimePlatform.Android then
			username = Game.Platform.Interface.Instance:GetUserName();
		else
			--username = '1_ztl'
			username = 'ztl'
			local name = UnityEngine.PlayerPrefs.GetString("username");
			if name ~= nil then
				username = name
			end
		end
        token = Game.Platform.Interface.Instance:GetToken();
		if token==nil then
			token = "0"
		end
		print("LoginSuccess token:"..token)
    end

    network.SetServer()
    -- ToDo 登录成功

    if uimanager.hasloaded "dlglogin" then

        uimanager.call("dlglogin", "OnLoginSuccess")
        uimanager.refresh "dlglogin"
    end

end
local function LoginFailed()
	uimanager.ShowSystemFlyText(LocalString.Login_LoginPlatformFailed)
end
local function SwitchSuccess()
    if LoggedInPlatform then
        LoggedInPlatform = false
		role_logout(LogoutType.to_login, true)
	end
end
---------------------------协议部分 开始-------------------------------------


local function onmsg_Challenge(d)
    print("onmsg_Challenge serverid = " .. d.serverid..",platform="..tostring(Application.platform)..",username="..username)
    local plattype = gnet.PlatType.TEST;
    serverid = d.serverid;
    local oss = "0";
    if Application.platform == UnityEngine.RuntimePlatform.Android then
        oss = "2"
    elseif Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
        if Local.JailBreak then
            oss = "0"
        else
            oss = "3"
        end
		plattype = gnet.PlatType.LYSDK;
    elseif Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer
           or Application.platform == UnityEngine.RuntimePlatform.WindowsEditor then
        oss = "4"
    end

    --if oss == "4" then
        --print("check userName:"..username);
        --local i, j = string.find(username,"1_")
        --if (i==nil or j==nil) or (not (i==1 and j==2)) then
            -- 没有加1_要加一下
            --username = "1_"..username
        --end
    --end
    platform = Game.Platform.Interface.Instance:GetSDKPlatformName();
    local re = gnet.Response( {
        user_identity = username,
        token = token,
        plattype = { plat = plattype },
        deviceid = deviceid,
        os = oss,
        platform = platform
    } )
    message.send(re, false)

end

local function onmsg_ChallengeNew(d)
    onmsg_Challenge(d)
end


local function onmsg_ErrorInfo(d)
    print("onmsg_ErrorInfo " .. d.errcode.code)
    if (d.errcode.code == gnet.ErrCode.ERR_KICK_BY_ANOTHER_USER) then
        Aio.Session.Instance.AutoReconnect = false
        uimanager.ShowSingleAlertDlg {
            content = LocalString.Err_KickByAnotherPlayer,
            callBackFunc = function()
                LoggedInPlatform = false
                Game.Platform.Interface.Instance:Logout()
            end
        }
    else
        isOnline = false
        network.close(Aio.Session.Instance.AutoReconnect)
    end
end

local function NotifySceneLoginLoaded()
    selectedroleid = 0
    loginroleid = 0
    isOnline = false
    useridj = 0;
end


local function onmsg_KeepAlive(d)
    recvKeepaliveExpireTime = TimeUtils.GetLocalTime() + KEEPALIVE_EXPIRE_TIME
end
local function onmsg_SKeepAlive(d)
    onmsg_KeepAlive(d)
end

local function second_update()
    local now = TimeUtils.GetLocalTime()
    if isOnline and recvKeepaliveExpireTime then
        if nextSendKeepaliveTime <= now then
            nextSendKeepaliveTime = now + KEEPALIVE_SEND_INTERVAL
            message.create_and_send("gnet.KeepAlive", { code = now * 1000 }, false)
        end
        if recvKeepaliveExpireTime <= now then
            network.reconnect()
			isOnline = false
        end
    end

    if isOnline and nextSendCPingTime and nextSendCPingTime < now and loginroleid > 0 then
        nextSendCPingTime = now + SEND_CPING_INTERVAL
        local recvCount = message.getProtocolCount()
        LuaHelper.Ping(recvCount)
    end
end



local function OnLoginSceneLoaded(logouttype, bNeedLogin)
    CharacterManager.NotifySceneLoginLoaded()
    uimanager.NotifySceneLoginLoaded()
    CameraManager.NotifySceneLoginLoaded()
    EctypeManager.NotifySceneLoginLoaded()
    NotifySceneLoginLoaded()
    local sceneInfo = ConfigManager.getConfigData("scene", "login")
    AudioMgr.PlayBackgroundMusic(sceneInfo.backgroundmusicid)

    uimanager.hide("dlgloading")
    if logouttype == LogoutType.to_login then
        uimanager.show("dlglogin", { bNeedLogin = bNeedLogin })
    elseif logouttype == LogoutType.to_choose_player then
        -- network.reconnect()
        network.connect()
        Aio.Session.Instance.AutoReconnect = true
    else
        uimanager.show("dlglogin", { bNeedLogin = bNeedLogin })
    end
end


local function RegisterLoginSceneLoadedCallback(logouttype, bNeedLogin)
    SceneMgr.Instance:RegisteOnSceneLoadFinish( function(result)
        if result == true then
            OnLoginSceneLoaded(logouttype, bNeedLogin)
        else
            SceneMgr.Instance:ChangeScene("login")
        end

    end )
end


local function role_logout(logouttype, haslogout)
    -- logout
    print("[login:role_logout] role logout!")

    if scenemanager.GetMapName() == "login" then
        print("[login:role_logout] scenemanager.GetMapName() == login!")
        uimanager.DestroyAllDlgs()
        CameraManager.NotifySceneLoginLoaded()

        uimanager.show("dlglogin")
        network.close(false)
    else
        -- msg

        network.send(lx.gs.login.CRoleLogout( { }))

        network.close(false)
        network.reset_last_reconnect_time()

        gameevent.evt_system_message:trigger("logout", logouttype)
        uimanager.show("dlgloading")

        -- load scene
        print("[login:role_logout] load login scene!")
        RegisterLoginSceneLoadedCallback(logouttype, true)
        SceneMgr.Instance:ChangeScene("login")
        loginroleid = 0
    end
	
	Game.Platform.Interface.Instance:UnInitVoiceSDK()
end

local function Logout()
    if LoggedInPlatform then
        LoggedInPlatform = false
        uimanager.ShowSystemFlyText(LocalString.Login_LogoutPlatform)
        role_logout(LogoutType.to_login, true)
    end
end


-- 角色登出

local function Game_logout(logouttype, haslogout)
    if logouttype == LogoutType.to_login then
        LoggedInPlatform = false
        if Application.platform == UnityEngine.RuntimePlatform.Android or
            Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
            Game.Platform.Interface.Instance:Logout()
            -- Game.Platform.Interface.Instance:Login()
            role_logout(logouttype, haslogout)
        else
            role_logout(logouttype, haslogout)
        end
    elseif logouttype == LogoutType.to_choose_player then
        role_logout(logouttype, haslogout)
    end
end


local function onmsg_KeyExchange(d)
	if token==nil then
		token = "0"
	end
    print("onmsg_KeyExchange username:"..username.." token:"..token)
    local nonce = ToString(LuaHelper.GenKeyExchangeNonceAndSetInOutSecurity(ToBytes(username), ToBytes(token), ToBytes(d.nonce)))
    local kick = 1
    message.create_and_send("gnet.KeyExchange", { nonce = nonce, kick_olduser = kick }, false)
end



local function onmsg_OnlineAnnounce(d)
    print("auth onlineannounce ... userid="..d.userid)
    isOnline = true
    recvKeepaliveExpireTime = TimeUtils.GetLocalTime() + KEEPALIVE_EXPIRE_TIME
    userid = d.userid
    if loginroleid == 0 then
        local PlatformType = 0
        if Application.platform == UnityEngine.RuntimePlatform.Android then
            PlatformType = 0
        elseif Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
            PlatformType = 1
        elseif Application.platform == UnityEngine.RuntimePlatform.WindowsPlayer then
            if Game.Platform.Interface.Instance:GetPlatform() == "Android" then
                PlatformType = 0
            else
                PlatformType = 1
            end
        end

        network.create_and_send("lx.gs.login.CGetRoleList", { plattype = PlatformType })
    else
        local count = message.getProtocolCount()
        local re = lx.gs.login.CRoleRelogin(
        {
            roleid = loginroleid,
            receivedmessagecount = count,
        } )
        network.send(re)
    end
end


local function on_network_abort()
    nextSendCPingTime = nil
    --isOnline = false
end



-- 判断进入界面
local function onmsg_SGetRoleList(d)

    roles = d.roles
    if loginroleid == 0 then
        uimanager.hide("common.dlgdialogbox_disconnetion")
        network.reset_reconnect_count()
    end



    if #roles > 0 then
        for roleid, deltime in pairs(d.deleteinfo or { }) do
            for _, roleinfo in ipairs(roles) do
                if roleinfo.roleid == roleid then
                    roleinfo.deltime = deltime / 1000
                end
            end
        end
        uimanager.show("dlgchooseplayer")
        CameraManager.LoginPull("dlgchooseplayer")
        uimanager.hide("dlglogin")
    else
        uimanager.show("dlgcreatplayer")
        CameraManager.LoginPull("dlgcreatplayer")
        uimanager.hideimmediate("dlglogin")
    end
end

-- 创建游戏角色
local function onmsg_SCreateRole(d)
    if d.err == 0 then
        if roles then
            table.insert(roles, d.newinfo)
        end

        local selectedServer, addfress = network.getSelectedServer()

        local createTime = d.servertime and math.floor(d.servertime / 1000) or 0

        Game.Platform.Interface.Instance:SubmitUserInfo(
        "create",
        tostring(d.newinfo.roleid),
        d.newinfo.rolename,
        tostring(d.newinfo.level),
        serverid,
        selectedServer.name,
        tostring(createTime));

        uimanager.hide("dlgcreatplayer")
        role_login(#roles)
    else
        -- 弹出错误提示框
        uimanager.ShowSingleAlertDlg( { content = errMgr.GetErrorText(d.err) })
    end
end

-- 删除已创建的角色
local function onmsg_SDeleteRole(d)
    if roles then
        for i = 1, 4 do
            if roles[i].roleid == d.roleid then
                roles[i].deltime = TimeUtils.GetServerTime()
                break
            end
        end
        if uimanager.hasloaded("dlgchooseplayer") then
            uimanager.call("dlgchooseplayer", "refresh")
        end
    end
    if #roles > 0 then
        uimanager.refresh("dlgchooseplayer")
    else
        uimanager.hide("dlgchooseplayer")
        uimanager.show("dlgcreatplayer", true)
    end
end

-- 取消删除操作
local function onmsg_SCancelDelteRole(msg)

    if roles then
        for i = 1, table.maxn(roles) do
            if roles[i].roleid == msg.roleid then

                roles[i].deltime = nil
                break
            end
        end

        if uimanager.hasloaded("dlgchooseplayer") then
            print("dlgchooseplayer refresh")
            uimanager.call("dlgchooseplayer", "refresh")
        end
    end
end

-- 创建时候玩家登录游戏主界面
local function onmsg_SRoleLogin(d)
    if d.err == lx.gs.login.SRoleLogin.OK then
        firstlogin = false

        CameraManager.DestroyLoginAssist()

        local MapManager = require "map.mapmanager"
        if MapManager.IsFirstLogin() == true then
            uimanager.show("dlgloading")
        end

        login_sucess(roles[selectedroleid], d.roledetail)

        uimanager.hide("dlgchooseplayer")
        SubmitUserInfo("login")
        nextSendCPingTime = TimeUtils.GetLocalTime() + SEND_CPING_INTERVAL
        nextCheckResVerTime = TimeUtils.GetLocalTime() + CHECK_RESVER_INTERVAL
        refreshPing(1)
        uimanager.hide("comom.dlgdialogbox_disconnetion")
        network.reset_reconnect_count()
        -- TODO 接受协议
    elseif d.err == lx.gs.login.SRoleLogin.TOOMANY_ONLINES_ROLE then
        uimanager.ShowSingleAlertDlg { content = LocalString.Login_Toomany_Onlines_Role }
    elseif d.err == lx.gs.login.SRoleLogin.SERVER_LOADAVG_BUSY then
        uimanager.ShowSingleAlertDlg { content = LocalString.Login_Server_Loadavg_Busy }
    else
        loginroleid = 0
        firstlogin = true

    end
end

local function onmsg_SRoleReLogin(d)
    if d.err == lx.gs.login.SRoleLogin.OK then
        nextSendCPingTime = TimeUtils.GetLocalTime() + SEND_CPING_INTERVAL
        nextCheckResVerTime = TimeUtils.GetLocalTime() + CHECK_RESVER_INTERVAL
        SubmitUserInfo("login");
        uimanager.hide("common.dlgdialogbox_disconnetion")
        network.reset_reconnect_count()
    else
        local re = lx.gs.login.CRoleLogin( { roleid = loginroleid })
        network.send(re)
    end
end

local function onmsg_Scanfirstrecharge(d)
    local PlayerRole = require "character.playerrole"
    PlayerRole:Instance():SetFirstCharge(d.canfirstrecharge)
end



local function onmsg_SKickRole(msg)
	uimanager.ShowSystemFlyText(msg.desc)
	role_logout(LogoutType.to_login, true)
end


local function onmsg_SPing(msg)
    refreshPing(msg.recvclienttime - msg.sendclienttime)
    message.setProtocolCount(msg.sendmessagecount)
end

local function onmsg_SLevelChange(msg)
    -- printyellow("onmsg_SLevelChange")

    local oldLevel = PlayerRole:Instance().m_Level
    PlayerRole:Instance().m_Level = msg.level
    PlayerRole:Instance().m_RealLevel = msg.level
    if oldLevel ~= msg.level and uimanager.hasloaded("dlguimain") then
        uimanager.call("dlguimain", "RefreshTaskList")
    end
    SubmitUserInfo("level");
    local ModuleLockManager = require "ui.modulelock.modulelockmanager"
    ModuleLockManager.OnPlayerLevelUp()
    -- local MultiEctypeManager=require"ui.ectype.multiectype.multiectypemanager"
    -- MultiEctypeManager.SetMaxLevelCanChallege(msg.level)
end

local function onmsg_ChangeCurrency(msg)

    local PlayerRole = require "character.playerrole"
    for k, v in pairs(msg.currencys) do
        PlayerRole:Instance().m_Currencys[k] = v
    end

    local DlgDialog = require "ui.dlgdialog"
    DlgDialog.RefreshCurrency()

    if uimanager.hasloaded("dlguimain") then
        uimanager.call("dlguimain", "RefreshRoleInfo")
    end
    -- if uimanager.hasloaded("partner.dlgpartner") then
    --     uimanager.call("partner.dlgpartner","refresh")
    -- end

end


local function onmsg_CurrencyAlert(msg)
    local PlayerRole = require "character.playerrole"
    for k, v in pairs(msg.currencys) do
        if LocalString.CurrencyFlyText[v.ctype] then
			local temptarget = ItemManager.GetCurrencyCommon(v.ctype,v.add)
			printyellow("v.ctype,v.add",v.ctype,v.add)
           -- local flyText = string.format(LocalString.CurrencyFlyText[v.ctype], v.add)
            uimanager.ShowSyncItem(temptarget,v.add)
		--printyellow("temptarget")
        end
    end
end


local function get_serverid()
    return serverid
end

local function get_token()
    return token
end

local function onmsg_KillMonster(msg)
    local PlayerRole = require "character.playerrole"
    --乾坤鼎红点
    if PlayerRole:Instance().m_TodayKillMonsterExtraExp ~= msg.todaytotaladdmonsterexp then
        if uimanager.hasloaded("dlguimain") then
            uimanager.call("dlguimain", "RefreshRedDotType", cfg.ui.FunctionList.DAILYEXTRAEXP)
        end
    end
    PlayerRole:Instance().m_TodayKillMonsterExtraExp = msg.todaytotaladdmonsterexp
    if uimanager.isshow("dlgdailyexp") then
        uimanager.call("dlgdailyexp","refreshExp")
    end

    for _,petexp in pairs(msg.petexps) do
        PetManager.PetExpChange(petexp.modelid,petexp.level,petexp.exp)
    end
end


local function onmsg_SDayOver(msg)
    local PlayerRole = require "character.playerrole"
    PlayerRole:Instance().m_TodayKillMonsterExtraExp = 0
    if uimanager.isshow("dlgdailyexp") then
        uimanager.call("dlgdailyexp","refreshExp")
    end
end

local function OnMsgSOfflineExp(msg)
    --printyellow("OnMsgSOfflineExp", tostring(msg.offlinetime), tostring(msg.offlineexp))
    if msg.offlinetime > 0 and msg.offlineexp > 0 then
        local PlayerRole = require "character.playerrole"
        PlayerRole:Instance().m_OfflineTime = msg.offlinetime
        PlayerRole:Instance().m_OfflineExp = msg.offlineexp

        if uimanager.isshow("dlguimain") then
            uimanager.call("dlguimain", "ShowGetOfflineExpUI")
        end
    end
end

local function onmsg_SCombatPowerChange(msg)
--    local DlgCombatPower = require "ui.dlgcombatpower"
--    DlgCombatPower.showchange(PlayerRole:Instance().m_Power,msg.combatpower)
--    PlayerRole:Instance().m_Power = msg.combatpower
end

local function onmsg_SReSetWorldLevel(d)
    if d ~= nil and d.newlevel ~= nil then
        PlayerRole:Instance().m_worldlevel = d.newlevel
        if uimanager.isshow("dlgdailyexp") then
            uimanager.call("dlgdailyexp","refreshWorldLevelRate")
        end
    end
end

local function onmsg_SReSetWorldLevelRate(d)
    if d ~= nil and d.newrate ~= nil then
        PlayerRole:Instance().m_worldlevelrate = d.newrate
        if uimanager.isshow("dlgdailyexp") then
            uimanager.call("dlgdailyexp","refreshWorldLevelRate")
        end
    end
end


--TODO 未知功能
local function  onmsg_RequireLoginActivationCode(msg)
    userid = msg.userid
    localsid = msg.localsid;
    if msg.err.code == 0 then
        uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
							fields.UIGroup_Button_Mid.gameObject:SetActive(true)
							fields.UIGroup_Button_Norm.gameObject:SetActive(false)
							fields.UIGroup_Resource.gameObject:SetActive(false)
							fields.UIGroup_Select.gameObject:SetActive(false)
							fields.UIGroup_Clan.gameObject:SetActive(false)
							fields.UIGroup_Rename.gameObject:SetActive(false)
							fields.UIGroup_Slider.gameObject:SetActive(false)
							fields.UIGroup_Delete.gameObject:SetActive(false)
							fields.UIInput_Input.gameObject:SetActive(true)
							fields.UIInput_Input_Large.gameObject:SetActive(false)
                            fields.UIGroup_Describe.gameObject:SetActive(false)

                            EventHelper.SetClick(fields.UIButton_Mid, function()
                                    uimanager.hideimmediate("common.dlgdialogbox_input")
                                    code = fields.UIInput_Input.value
									local re = gnet.InputLoginActivationCode( { code = code, localsid=localsid, userid = userid })
                                    message.send(re)
							end)

							EventHelper.SetClick(fields.UIButton_Close, function()
									uimanager.hide("common.dlgdialogbox_input")
							end)


                            fields.UILabel_Button_Mid.text = LocalString.SureText
							fields.UILabel_Title.text = LocalString.LOGIN_Activation
							fields.UIInput_Input.defaultText = ""
							fields.UIInput_Input.selectAllTextOnFocus = true
							fields.UIInput_Input.characterLimit = 15
							fields.UIInput_Input.value = LocalString.LOGIN_ActivationCode
							fields.UIInput_Input.isSelected = false
							fields.UILabel_Input.text = LocalString.LOGIN_ActivationCode
						end})

    else

        local  errmsg = getErrMsg(msg.err.code)
        uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
							fields.UIGroup_Button_Mid.gameObject:SetActive(true)
							fields.UIGroup_Button_Norm.gameObject:SetActive(false)
							fields.UIGroup_Resource.gameObject:SetActive(false)
							fields.UIGroup_Select.gameObject:SetActive(false)
							fields.UIGroup_Clan.gameObject:SetActive(false)
							fields.UIGroup_Rename.gameObject:SetActive(false)
							fields.UIGroup_Slider.gameObject:SetActive(false)
							fields.UIGroup_Delete.gameObject:SetActive(false)
							fields.UIInput_Input.gameObject:SetActive(true)
							fields.UIInput_Input_Large.gameObject:SetActive(false)
                            fields.UIGroup_Describe.gameObject:SetActive(true)

                            EventHelper.SetClick(fields.UIButton_Mid, function()
                                    uimanager.hideimmediate("common.dlgdialogbox_input")
                                    code = fields.UIInput_Input.value
                                    local re = gnet.InputLoginActivationCode( { code = code, localsid=localsid, userid = userid })
                                    network.send(re)
							end)

							EventHelper.SetClick(fields.UIButton_Close, function()
									uimanager.hide("common.dlgdialogbox_input")
							end)

                            fields.UILabel_Button_Mid.text = LocalString.SureText
							fields.UILabel_Title.text = LocalString.LOGIN_Activation
							fields.UIInput_Input.defaultText = ""
							fields.UIInput_Input.selectAllTextOnFocus = true
							fields.UIInput_Input.characterLimit = 15
							fields.UIInput_Input.value = code
							fields.UIInput_Input.isSelected = false
							fields.UILabel_Describe.text = errmsg
							fields.UILabel_Input.text = code
						end})
    end

end;


---------------------------------协议部分 结束--------------------------------------------------

local function ClearRoles()
    roles = {}
end

local function init()
    if Application.platform == UnityEngine.RuntimePlatform.Android then
        resverurl = ResVersionUrlConfig.android
    elseif Application.platform == UnityEngine.RuntimePlatform.IPhonePlayer then
        resverurl = ResVersionUrlConfig.ios
    else
        resverurl = ResVersionUrlConfig.android
    end
    LoggedInPlatform = false


    -- 注册登录操作回调函数
    gameevent.evt_system_message:add("loginSuccess", LoginSuccess)
    gameevent.evt_system_message:add("loginFailed", LoginFailed)
    gameevent.evt_system_message:add("logoutSuccess", Logout)
    gameevent.evt_system_message:add("switchSuccess", SwitchSuccess)
	
    gameevent.evt_system_message:add("network_abort", on_network_abort)
    gameevent.evt_system_message:add("logout",ClearRoles)
	
    gameevent.evt_second_update:add(second_update)


    network.add_listeners( {
        { "gnet.Challenge", onmsg_Challenge },
        { "gnet.ChallengeNew", onmsg_ChallengeNew },
        { "gnet.KeepAlive", onmsg_KeepAlive },
        { "lx.gs.SKeepAlive", onmsg_SKeepAlive },
        { "gnet.ErrorInfo", onmsg_ErrorInfo },
        { "gnet.KeyExchange", onmsg_KeyExchange },
        { "gnet.OnlineAnnounce", onmsg_OnlineAnnounce },

        -- 注册协议
        { "lx.gs.login.SGetRoleList", onmsg_SGetRoleList },-- 发送给服务器之后获取到的数据
        { "lx.gs.login.SCreateRole", onmsg_SCreateRole },-- 发送给服务器创建角色之后创建角色
        { "lx.gs.login.SDeleteRole", onmsg_SDeleteRole },
        { "lx.gs.login.SCancelDelteRole", onmsg_SCancelDelteRole },
        { "lx.gs.login.SRoleLogin", onmsg_SRoleLogin },
        { "lx.gs.login.SRoleRelogin", onmsg_SRoleReLogin },
        { "lx.gs.login.Scanfirstrecharge", onmsg_Scanfirstrecharge },
		
	    { "lx.gs.role.msg.SKillMonster", onmsg_KillMonster },
	    { "lx.gs.role.msg.SDayOver", onmsg_SDayOver },
        { "lx.gs.role.msg.SOffLineExp", OnMsgSOfflineExp },
		{ "lx.gs.role.msg.SCombatPowerChange", onmsg_SCombatPowerChange },
        { "lx.gs.role.msg.SReSetWorldLevel", onmsg_SReSetWorldLevel },
        { "lx.gs.role.msg.SReSetWorldLevelRate", onmsg_SReSetWorldLevelRate },
        { "gnet.RequireLoginActivationCode", onmsg_RequireLoginActivationCode },
        { "lx.gs.SPing", onmsg_SPing },
        { "lx.gs.role.msg.SLevelChange", onmsg_SLevelChange },
        { "lx.gs.role.msg.SCurrencyChange", onmsg_ChangeCurrency },
        { "lx.gs.role.msg.SCurrencyAlert", onmsg_CurrencyAlert },
    }
    )
    --登入日志记录
    httpLog.AddUrlTable(httpLog.LogType.Behavior,httpLog.EventType.Sign,httpLog.IsException.No)
end



return {
    init = init,
    get_roles = get_roles,
    role_login = role_login,
    Logout = Logout,
    create_role = create_role,
    remove_role = remove_role,
    get_loginrole = get_loginrole,
    NotifySceneLoginLoaded = NotifySceneLoginLoaded,
    Game_logout = Game_logout,
    set_username = set_username,
    LogoutType = LogoutType,
    get_serverid = get_serverid,
    get_token = get_token,
    getErrMsg = getErrMsg,
}
