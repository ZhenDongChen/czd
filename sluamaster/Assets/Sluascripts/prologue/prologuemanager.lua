local NetWork=require("network")
local UIManager=require("uimanager")
local ectypetools = require("ectype.ectypetools")
local PlayerRole = require("character.playerrole")
local EctypeManager = require"ectype.ectypemanager"
local ConfigManager = require("cfg.configmanager")
local AudioMgr = require"audiomanager"
local gameevent         = require "gameevent"
local CGManager = require("ui.cg.cgmanager")

local m_PrologueCfg

local m_CreateRoleID
local m_NeedPlaySurfixPrologue

--�õ���һ�����µ�ս��ֵ
local function GetFightPower(profession)
    if m_PrologueCfg then
        return m_PrologueCfg.professionequips[profession].battlepower
    else
        return 0
    end
end

local function onmsg_SCreateRole(msg)
    m_CreateRoleID = (msg and msg.newinfo) and msg.newinfo.roleid or nil
end

local function onmsg_SRoleLogin(msg)
    if msg and msg.err == lx.gs.login.SRoleLogin.OK then
        if m_CreateRoleID then
            m_NeedPlaySurfixPrologue = m_CreateRoleID==msg.roledetail.roleid
        else
            m_NeedPlaySurfixPrologue = false
        end          
    end
end


local function IsInPrologue()
    if EctypeManager.IsInEctype() and EctypeManager.GetEctype().m_EctypeType == cfg.ectype.EctypeType.PROLOGUE then
        return true
    else
        return false
    end
end

local function GetSkillOrder(profession)
    if m_PrologueCfg then
        return m_PrologueCfg.professionequips[profession].skillorder
    else
        return nil
    end
end

local function reset()
    m_CreateRoleID = nil
    m_NeedPlaySurfixPrologue = false
end

local function OnLogout()
    reset()
end


local function PlaySurfixVideo(callback)
    if m_PrologueCfg then
        m_NeedPlaySurfixPrologue = false
        m_CreateRoleID = nil
        CGManager.PlayCG(m_PrologueCfg.cg_ectype_end, callback, m_PrologueCfg.cg_ectype_end_mode)
    else
		
    end
end


local function onmsg_SEndPrologue(msg)
    if msg.errcode == 0 then
        --local PlotManager = require("plot.plotmanager")
        --PlotManager.CutscenePlay("caomiao_1")
    else
        local login = require"login"
	    login.Game_logout(login.LogoutType.to_login)
		--login.logout(login.LogoutType.to_login)
    end
	
				
	if UIManager.isshow("ectype.dlguiectype") then
		UIManager.hide("ectype.dlguiectype")
	end
	

end

local function init()
    m_PrologueCfg= ConfigManager.getConfig("prologue")

    reset()

	gameevent.evt_system_message:add("logout", OnLogout)
    NetWork.add_listeners({
        { "lx.gs.login.SCreateRole", onmsg_SCreateRole },
        { "lx.gs.login.SRoleLogin", onmsg_SRoleLogin },
    })
end

return
{
    init     = init,
    GetSkillOrder = GetSkillOrder,
	IsInPrologue = IsInPrologue,
	GetSkillOrder = GetSkillOrder,
	GetFightPower = GetFightPower,
	PlaySurfixVideo = PlaySurfixVideo,
	onmsg_SEndPrologue = onmsg_SEndPrologue,
}