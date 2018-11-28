local PlayerRole 			= require "character.playerrole"
local network 				= require "network"
local ConfigMgr 			= require "cfg.configmanager"

local UIManager 			= require("uimanager")
local ItemManager			= require("item.itemmanager")
local ItemIntroduction		= require("item.itemintroduction")
local ActivityTipMgr           = require("ui.activity.activitytipmanager")

local CheckCmd
local monsterData = nil

local ExpMonster 			= {}		--精英怪系统信息表
ExpMonster.MonsterList		= {}		--精英怪列表


--获取的个人信息
ExpMonster.PersonalInfo	= {
	m_Power 				= 0,		--个人战斗力
	m_Level 				= 0,		--个人等级
	m_VipLevel 				= 0,		--个人VIP等级
}
ExpMonster.config = {} --配置信息
ExpMonster.KillNum = 0
ExpMonster.Receivedbonus = 0 --已领取数
ExpMonster.isOpen = 0 --0 未开启 1 开启 2结束
ExpMonster.refreshTimes={}

--获取玩家信息
local function GetPersonalInfo()
	ExpMonster.PersonalInfo.m_Level = PlayerRole:Instance():GetLevel()
	ExpMonster.PersonalInfo.m_VipLevel = PlayerRole:Instance().m_VipLevel
	ExpMonster.PersonalInfo.m_Power = PlayerRole:Instance():GetPower()
end

--人物战力
local function GetPlayerPower()
	--GetPersonalInfo()
	return PlayerRole:Instance():GetPower()
end


local function CanChallengeMonster()
	GetPersonalInfo()
	local PersonLevel = PlayerRole:Instance():GetLevel()
	for i,monsterInfo in ipairs(ExpMonster.MonsterList) do
		if (ExpMonster.PersonalInfo.m_Level >= monsterInfo.minlevel and ExpMonster.PersonalInfo.m_Level<= monsterInfo.maxlevel) then
			monsterData = monsterInfo
		end 
	end
end

local function GetRefreshTimeList()
    return ExpMonster.refreshTimes
end

local function GetAllExpMonsterInfo()
	ExpMonster.refreshTimes = {}
	local expMonsterData=ConfigManager.getConfig("expmonster")
	ExpMonster.config = expMonsterData
	ExpMonster.MonsterList = {}
    for _, config in ipairs(expMonsterData.monstermsg) do
        table.insert( ExpMonster.MonsterList, config )
    end
    CanChallengeMonster()	
    for _,controller in pairs(expMonsterData.opentimes) do
        local time={}
        time.hour=controller.hour
        time.min=controller.minute
        time.sec=controller.second
        time.allSec = controller.hour*3600 + controller.minute *60 + controller.second
        table.insert(ExpMonster.refreshTimes,time)
    end
    if #ExpMonster.refreshTimes == 1 then
    	local endTimeSec = ExpMonster.refreshTimes[1].allSec + ExpMonster.config.lasttime
    	local endTime = {}
    	endTime.hour = math.floor(endTimeSec/3600)
    	endTime.min = math.floor((endTimeSec - endTime.hour*3600)/60)
    	endTime.sec = endTimeSec - endTime.hour*3600 - endTime.min*60
    	table.insert(ExpMonster.refreshTimes,endTime)
    end

end

local function GetOpenStatus(msg)
	local PersonLevel = PlayerRole:Instance():GetLevel()
	ExpMonster.isOpen = 0
	if ExpMonster.MonsterList[1] and PersonLevel >= ExpMonster.MonsterList[1].minlevel then
		local nowTime = timeutils.TimeNow()
	    local nowTimeSecs = nowTime.hour *3600 + nowTime.min *60 + nowTime.sec
		--printyellow("nowTimeSecs,ExpMonster.refreshTimes[1].allSec",nowTime.hour,nowTime.min,nowTime.sec,ExpMonster.refreshTimes[1].allSec,(ExpMonster.refreshTimes[1].allSec + ExpMonster.config.lasttime))
	    if (nowTimeSecs >= ExpMonster.refreshTimes[1].allSec and nowTimeSecs <= (ExpMonster.refreshTimes[1].allSec + ExpMonster.config.lasttime) )then
	    	ExpMonster.isOpen = 1 --开启
	    elseif nowTimeSecs > (ExpMonster.refreshTimes[1].allSec + ExpMonster.config.lasttime) then
	    	ExpMonster.isOpen = 2 --结束
	    end
	end
    return ExpMonster.isOpen
end

local function GetExpMonsterInfo()
	if monsterData then
		return monsterData
	end
end

local function GetKillMonsterNum()
	return ExpMonster.KillNum
end

local function GetReceivedbonus()
	return ExpMonster.Receivedbonus
end


local function OnMsg_SKillExpMonsterNums(msg)
	ExpMonster.KillNum = msg.nums
	ExpMonster.Receivedbonus = msg.receivedbonus
    if UIManager.isshow("activity.activityexp.tabactivityexp") then
		UIManager.call("activity.activityexp.tabactivityexp","RefreshKillNum")
		--UIManager.call("activity.activityexp.tabactivityexp","refresh")
    end
end

local function OnMsg_ExpMonsterNotify(msg)
	printyellow(">>>>>>>>>>>>>OnMsg_ExpMonsterNotify",msg.START)
	UIManager.ShowSystemFlyText(msg.msg)
    local ChatManager=require"ui.chat.chatmanager"
    ChatManager.AddMessageInfo({channel = cfg.chat.ChannelType.SYSTEM,text = msg.msg})
	
    if GetOpenStatus() ~= 0 then
	    if msg.eventtype == 1 and not ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.ManHuangShouChao) then
	    	ActivityTipMgr.RegisterActivity(cfg.dailyactivity.ActivityTipEnum.ManHuangShouChao,nil,function ()
	    		local params = {}
	    		params.tabindex2 = cfg.dailyactivity.ActivityTipEnum.ManHuangShouChao
	    		UIManager.showdialog("activity.dlgactivity",params)
	    	end)
	    end
	    if msg.eventtype == 2 then
	    	if  ActivityTipMgr.IsActivityRegistered(cfg.dailyactivity.ActivityTipEnum.ManHuangShouChao) then
		    	ActivityTipMgr.UnregisterActivity(cfg.dailyactivity.ActivityTipEnum.ManHuangShouChao)
	    	end
	    end
	end
end


local function refresh()
	--printyellow(">>>>>>Vector3(msg.xposition,msg.zposition,0):    refresh")
	GetAllExpMonsterInfo()
end

local function OnMsg_SGetExpMonsterPosition(msg)
	--printyellow(">>>>>>Vector3(msg.xposition,msg.zposition,0):",Vector3(msg.xposition,msg.zposition,0))
	PlayerRole:Instance():navigateTo({
		targetPos=Vector3(msg.xposition,msg.yposition,0),
		mapId= msg.mapid,
		callback =function ()
			UIManager.call("dlguimain","SwitchAutoFight",true)
		end 
	})
	UIManager.hidecurrentdialog()
end

local function OnMsg_SGetKillExpMonBonus(msg)
	table.insert(ExpMonster.Receivedbonus,msg.num)
	if UIManager.isshow("activity.activityexp.tabactivityexp") then
        UIManager.call("activity.activityexp.tabactivityexp","refresh")
    end
end



local function sendGetReward(killNum)
	local msg=lx.gs.activity.worldmonster.msg.CGetKillExpMonBonus({num = killNum})
    network.send(msg)
end

local function sendFightMsg()
	local msg=lx.gs.activity.worldmonster.msg.CGetExpMonsterPosition({})
    network.send(msg)
end

local function init()
	GetAllExpMonsterInfo()
	network.add_listeners({
        {"lx.gs.activity.worldmonster.msg.SKillExpMonsterNums",OnMsg_SKillExpMonsterNums},
        {"lx.gs.activity.worldmonster.msg.SGetExpMonsterPosition",OnMsg_SGetExpMonsterPosition},
        {"lx.gs.activity.worldmonster.msg.SGetKillExpMonBonus",OnMsg_SGetKillExpMonBonus},
        {"lx.gs.activity.worldmonster.msg.ExpMonsterNotify",OnMsg_ExpMonsterNotify},
    })
end

local function isReceived(killnum)
    local Receivedbonus = ExpMonster.Receivedbonus
    for i=1,#Receivedbonus do
        if Receivedbonus[i] == killnum then
            return false
        end
    end
    return true
end

local function UnRead()
	local result = false
	GetAllExpMonsterInfo()
	if monsterData then
		if GetOpenStatus() == 1 then
			local Receivedbonus = ExpMonster.Receivedbonus
			if #(monsterData.monsterbonus) > #Receivedbonus  then
				result = true
			end
		else
			for i=1,#(monsterData.monsterbonus) do
				local killNum = ExpMonster.KillNum  
		        if (killNum >= monsterData.monsterbonus[i].killnum and isReceived(monsterData.monsterbonus[i].killnum)) then
		        	result = true
		        	break
		        end
			end
		end
	end
	return result
end

return {
	init = init,
	refresh = refresh,
	GetExpMonsterInfo = GetExpMonsterInfo,
	GetPlayerPower    = GetPlayerPower,
	GetKillMonsterNum = GetKillMonsterNum,
	GetRefreshTimeList = GetRefreshTimeList,
	GetOpenStatus = GetOpenStatus,
	sendFightMsg = sendFightMsg,
	sendGetReward = sendGetReward,
	GetReceivedbonus = GetReceivedbonus,
	UnRead = UnRead,
	isReceived = isReceived,
}	