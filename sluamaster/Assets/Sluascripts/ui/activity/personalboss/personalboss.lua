local PlayerRole 			= require "character.playerrole"
local network 				= require "network"
local ConfigMgr 			= require "cfg.configmanager"

local UIManager 			= require("uimanager")
local ItemManager			= require("item.itemmanager")
local ItemIntroduction		= require("item.itemintroduction")
local CheckCmd				= require("common.checkcmd")

local BossInfo = require("ui.activity.personalboss.bossinfo")

local Inited = false
--个人Boss系统的Boss信息


local PersonalBoss 			= {}		--个人Boss系统信息表
PersonalBoss.BossList		= {}		--个人Boss列表

--选择信息
PersonalBoss.ChooseState	= {
	CurrentChooseIndex 		= 1,
	StartChallengeId 		= nil,
	CurrentChallengeBossId	= nil,
}

--获取的个人信息
PersonalBoss.PersonalInfo	= {
	m_Power 				= 0,		--个人战斗力
	m_Level 				= 0,		--个人等级
	m_VipLevel 				= 0,		--个人VIP等级
}

--通过ID查找Boss
local function GetBossInfoById(bossId)
	for i,k in ipairs(PersonalBoss.BossList) do
		if k.m_Id == bossId then
			return PersonalBoss.BossList[i]
		end
	end
	return nil
end

--获取Boss数量
local function GetBossCount()
	return #PersonalBoss.BossList
end
--人物战力
local function GetPlayerPower()
	--GetPersonalInfo()
	return PlayerRole:Instance():GetPower()
end

--增加Boss信息
local function AddBossInfo(bossInfo)
	local insertPos = 1
	for i,k in ipairs(PersonalBoss.BossList) do
		if bossInfo.m_ReCommendPower > k.m_ReCommendPower then
			insertPos = insertPos + 1
		end
	end
	table.insert( PersonalBoss.BossList, insertPos, bossInfo )
end
--获取玩家信息
local function GetPersonalInfo()
	PersonalBoss.PersonalInfo.m_Level = PlayerRole:Instance():GetLevel()
	PersonalBoss.PersonalInfo.m_VipLevel = PlayerRole:Instance().m_VipLevel
	PersonalBoss.PersonalInfo.m_Power = PlayerRole:Instance():GetPower()
end
--获取Boss信息
local function GetPersonBossInfo()
	local personalBosses = ConfigMgr.getConfig("personalboss")
	PersonalBoss.BossList = {}
	for id, config in pairs(personalBosses) do
		local info = BossInfo:new(id,config)
		AddBossInfo(info)
	end
end

local function OpenPersonalBossEctype(bossinfo)
	--printyellow("Start Challenge: ",bossinfo.m_SceneId)
	local re = lx.gs.map.msg.COpenPersonalBossEctype({ectypeid = bossinfo.m_SceneId})
	network.send(re)
end

--是否挑战成功
local function IsChanllengeSuccece()
	
end

--向服务器询问是否可以开始挑战
local function BeginChallengeBoss(bossinfo)
	--printyellow("begin Challenge Boss", bossinfo.m_Name)
	if bossinfo:GetRemainTimes()>0 then
		OpenPersonalBossEctype(bossinfo)
	else
		UIManager.ShowAlertDlg({immediate = true,title = LocalString.PersonalBoss_AlertTitle, content = LocalString.PersonalBoss_ErrorIndo[3], callBackFunc= nil })
	end
end

--是否满足条件
local function IsMatchBossCondition(bossInfo)
	GetPersonalInfo()
	local personalInfo = PersonalBoss.PersonalInfo
	if personalInfo.m_Level >= bossInfo.m_LimitCondition.Level and personalInfo.m_VipLevel >= bossInfo.m_LimitCondition.VipLevel then
		if bossInfo.m_TaskId ~= nil and bossInfo.m_TaskId > 0 then
			return CheckCmd.CheckCompleteTask({taskid = bossInfo.m_TaskId},{})
		else
			return true
		end
	end
	return false
end

local function IsCurrenctLevelRegion(bossInfo)
	local roleLevel = math.floor(PlayerRole:Instance().m_Level/15) * 15
	return (bossInfo.m_LimitCondition.Level <= roleLevel) and (bossInfo.m_LimitCondition.Level > roleLevel - 15)
end


local function OnMsgSEnterPersonalBossEctype(msg)
	--printyellow(msg)
	if msg == nil then
		return
	end
end

local function OnMsgSEndPersonalBossEctype(msg)
	--printyellow(msg)
	if msg == nil then
		return
	end
end

local function GetOpenLevel()
	local openLevel = 99999
	for i, bossInfo in pairs(PersonalBoss.BossList) do
		if bossInfo.m_LimitCondition.Level < openLevel then
			openLevel = bossInfo.m_LimitCondition.Level
		end
	end
	return openLevel
end


local function init()
	if Inited == false then
	    network.add_listeners( {
	        { "map.msg.SEnterPersonalBossEctype",     OnMsgSEnterPersonalBossEctype   },
	        { "map.msg.SEndPersonalBossEctype",       OnMsgSEndPersonalBossEctype     },
	    } )
		GetPersonBossInfo()
	end
	
end


local function UnRead()
	local result = false
	--printyellow("PersonalBoss.BossList UnRead", #PersonalBoss.BossList)
	for i, bossInfo in pairs(PersonalBoss.BossList) do
		--printyellow(bossInfo.m_Name, IsMatchBossCondition(bossInfo), bossInfo:CanChanllenge())
		if IsMatchBossCondition(bossInfo) == true and IsCurrenctLevelRegion(bossInfo) then
			if bossInfo:CanChanllenge() == true then
				result = true
				break
			end
		end
	end
	--printyellow("PersonalBoss UnRead", result)
	return result
end





return {
	init = init,
	PersonalBoss = PersonalBoss,
	GetPlayerPower=GetPlayerPower,
	BeginChallengeBoss=BeginChallengeBoss,
	GetBossCount=GetBossCount,
	IsMatchBossCondition=IsMatchBossCondition,
	IsCurrenctLevelRegion = IsCurrenctLevelRegion,
	GetOpenLevel = GetOpenLevel,
	UnRead = UnRead,
	IsChanllengeSuccece = IsChanllengeSuccece,
	--GetBossCount=GetBossCount,
	--GetBossRewardsCount=GetBossRewardsCount,
	--GetBossRewardsList=GetBossRewardsList,

	--ChallengePersonBoss=ChallengePersonBoss,
	--ShowDetailInfoOfItem=ShowDetailInfoOfItem,

}
