local network            = require "network"
local timeutils          = require "common.timeutils"
local UIManager          = require "uimanager"
local ConfigManager      = require "cfg.configmanager"
local ChatManager	     = require "ui.chat.chatmanager"
local ActivityTipManager = require("ui.activity.activitytipmanager")
local ModuleLockManager  = require("ui.modulelock.modulelockmanager")
local CheckCmd           = require("common.checkcmd")


local g_ActData
local g_ActOpenTime
local g_ActEndTime
local g_RegBeginTime
local g_RegEndTime
local g_bHasRegistered = false
local g_ActStatus = cfg.ectype.AttackCityStage.CLOSED

-- Time的格式均为{days,hours,minutes,seconds}
-- 注册开始时间
local function GetRegBeginTime()	
	return g_RegBeginTime
end
-- 注册结束时间
local function GetRegEndTime()
	return g_RegEndTime
end
-- 活动开始时间
local function GetActOpenTime()
	return g_ActOpenTime
end
-- 活动结束时间
local function GetActEndTime()
	return g_ActEndTime
end
-- 获取活动状态
local function GetActStatus()
	return g_ActStatus
end
-- 是否可以报名
local function CanRegister()
	local data = ConfigManager.getConfig("attackcity")
	local validate, info = CheckCmd.CheckData( { data = data.requirelevel, num = 1, showsysteminfo = false })
	if not validate then
		return false
	else
		if not g_bHasRegistered and g_ActStatus == cfg.ectype.AttackCityStage.SIGNUP then
			return true
		else
			return false
		end
	end
end
-- 是否已经报名
local function HasRegistered()
	return g_bHasRegistered
end
-- 返回兽妖攻城界面的第一层和第二层tab索引
local function GetAttackCityTabIndexs()
	local dialogData = ConfigManager.getConfigData("dialog","activity.dlgactivity")
	for tabIdx1,tabGroup in ipairs(dialogData.tabgroups) do
		for tabIdx2,tab in ipairs(tabGroup.tabs) do
			if tab.tabname == "activity.attackcity.tabattackcity" then 
				return tabIdx1,(tabIdx2-1)
			end
		end
	end
end

-- region msg
-- 获取基本信息
local function OnMsg_SGetAttackCityInfo(msg)
	g_bHasRegistered = (msg.signup == 1) and true or false
	printyellow(">>>>>>>>>msg.stage:",msg.stage)
	g_ActStatus = msg.stage
	-- 主界面活动提示
	local tabIndex1,tabIndex2 = GetAttackCityTabIndexs()
	local bActivityTipRegistered = ActivityTipManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng)
	-- 对应活动是否开启(活动是否达到开启条件(等级))
	local attackCityData = ConfigManager.getConfig("attackcity")
	local levelValidated = CheckCmd.CheckData( { data = attackCityData.requirelevel, num = 1, showsysteminfo = false })

	if levelValidated and CanRegister() and (not bActivityTipRegistered) then
		ActivityTipManager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng,nil,function()
			-- 转到兽妖攻城界面
			if tabIndex1 and tabIndex2 then 
				UIManager.showdialog("activity.dlgactivity",{tabindex2 = tabIndex2},tabIndex1)
			end
		end)
	end
end
-- 报名兽妖攻城
local function OnMsg_SEnrollAttackCity(msg)
	g_bHasRegistered = true
	UIManager.refresh("activity.attackcity.tabattackcity")
	if ActivityTipManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng) then
		ActivityTipManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng)
	end
end

-- 活动状态变化通知(三个状态会发：报名开始时，活动开始时，活动结束时)
local function OnMsg_SChangeAttackCityStage(msg)
	g_ActStatus = msg.stage
	UIManager.refresh("activity.attackcity.tabattackcity")

	-- 主界面活动提示
	local tabIndex1,tabIndex2 = GetAttackCityTabIndexs()
	local bActivityTipRegistered = ActivityTipManager.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng)
	-- 对应活动是否开启(活动是否达到开启条件(等级))
	local attackCityData = ConfigManager.getConfig("attackcity")
	local levelValidated = CheckCmd.CheckData( { data = attackCityData.requirelevel, num = 1, showsysteminfo = false })

	-- 报名期间注册
	if levelValidated and CanRegister() and (not bActivityTipRegistered) then 

		ActivityTipManager.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng,nil,function()
			-- 转到兽妖攻城界面
			if tabIndex1 and tabIndex2 then 
				UIManager.showdialog("activity.dlgactivity",{tabindex2 = tabIndex2},tabIndex1)
			end
		end)
	end
	-- 非报名期间取消注册
	if g_ActStatus ~= cfg.ectype.AttackCityStage.SIGNUP and bActivityTipRegistered then
		ActivityTipManager.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.YaoShouGongCheng)
	end

	if g_ActStatus == cfg.ectype.AttackCityStage.OPEN and g_bHasRegistered then
		local params = { }
		params.title = LocalString.TipText
		params.content = LocalString.Activity_AttackCity_ActBeginTip
		params.callBackFunc = function() network.create_and_send("lx.gs.map.msg.CEnterAttackCity") end
		UIManager.ShowAlertDlg(params)
	elseif g_ActStatus == cfg.ectype.AttackCityStage.CLOSED then
		g_bHasRegistered = false
	end
end

-- 定时刷怪提示
local function OnMsg_SNewAttackCityMonster(msg)
	local monstersinfo = (g_ActData.sections[msg.sectionindex + 1]).monsterinfos[msg.monsterbatchindex + 1]
	--UIManager.ShowSystemFlyText(monstersinfo.refreshmsg)
	ChatManager.AddMessageInfo({channel = cfg.chat.ChannelType.SYSTEM,text = monstersinfo.refreshmsg})
end

-- endregion msg

local function Release()
	g_ActData		= ConfigManager.getConfig("attackcity")
	g_ActOpenTime	= { days = g_ActData.opentime.begintime.weekday, hours = g_ActData.opentime.begintime.hour, minutes = g_ActData.opentime.begintime.minute,seconds = g_ActData.opentime.begintime.second}
	g_ActEndTime	= { days = g_ActData.opentime.endtime.weekday, hours = g_ActData.opentime.endtime.hour, minutes = g_ActData.opentime.endtime.minute,seconds = g_ActData.opentime.endtime.second }
	g_RegBeginTime	= { days = g_ActData.signuptime.begintime.weekday, hours = g_ActData.signuptime.begintime.hour, minutes = g_ActData.signuptime.begintime.minute,seconds = g_ActData.signuptime.begintime.second }
	g_RegEndTime	= { days = g_ActData.signuptime.endtime.weekday, hours = g_ActData.signuptime.endtime.hour, minutes = g_ActData.signuptime.endtime.minute,seconds = g_ActData.signuptime.endtime.second }
end

local function OnLogout()
	Release()
end

local function init()
	
	g_ActData		= ConfigManager.getConfig("attackcity")
	g_ActOpenTime	= { days = g_ActData.opentime.begintime.weekday, hours = g_ActData.opentime.begintime.hour, minutes = g_ActData.opentime.begintime.minute,seconds = g_ActData.opentime.begintime.second}
	g_ActEndTime	= { days = g_ActData.opentime.endtime.weekday, hours = g_ActData.opentime.endtime.hour, minutes = g_ActData.opentime.endtime.minute,seconds = g_ActData.opentime.endtime.second }
	g_RegBeginTime	= { days = g_ActData.signuptime.begintime.weekday, hours = g_ActData.signuptime.begintime.hour, minutes = g_ActData.signuptime.begintime.minute,seconds = g_ActData.signuptime.begintime.second }
	g_RegEndTime	= { days = g_ActData.signuptime.endtime.weekday, hours = g_ActData.signuptime.endtime.hour, minutes = g_ActData.signuptime.endtime.minute,seconds = g_ActData.signuptime.endtime.second }

    network.add_listeners({
        {"lx.gs.map.msg.SGetAttackCityInfo",OnMsg_SGetAttackCityInfo},
		{"lx.gs.map.msg.SEnrollAttackCity",OnMsg_SEnrollAttackCity},
		{"lx.gs.map.msg.SChangeAttackCityStage",OnMsg_SChangeAttackCityStage},
		{"map.msg.SNewAttackCityMonster",OnMsg_SNewAttackCityMonster},

    })
	gameevent.evt_system_message:add("logout", OnLogout)
end

local function UnRead()
    return CanRegister()
end

return {
	init				= init,
	UnRead				= UnRead,
	GetRegBeginTime		= GetRegBeginTime,
	GetRegEndTime		= GetRegEndTime,
	GetActOpenTime		= GetActOpenTime,
	GetActEndTime		= GetActEndTime,
	GetActStatus		= GetActStatus,
	HasRegistered		= HasRegistered,
	CanRegister			= CanRegister,
}