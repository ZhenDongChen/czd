
local Network 				= require("network")
local UIManager				= require("uimanager")
local ConfigManager			= require("cfg.configmanager")
local LimitManager			= require("limittimemanager")
-------------------------------------------------------------------------------------
local FightReportInfo 	= require("ui.arena.single.arenainfo.arenafightreport")
local RewardsInfo 		= require("ui.arena.single.arenainfo.arenarewards")
local PlayerInfo 		= require("ui.arena.single.arenainfo.arenaroleinfo")
-------------------------------------------------------------------------------------

local listenerId
--竞技场数据
local ArenaData 			= {}
--竞技场状态
ArenaData.PlayerState 		= {
	m_Rank 					= -1,
	m_Reputation 			= 0,
	m_ReputationIncrease 	= 0,
	m_SuccessCount 			= 0,
	

    m_BestRank              = 0,
    m_LastRewardRank        = 0,
}

ArenaData.OpponentList 		= {} 					--对手列表
ArenaData.CurrentOpponent 	= nil 					--当前对手
ArenaData.FightReportList 	= {} 					--战斗报告
ArenaData.RewardsList 		= {} 					--奖励

------------------------------------------------------------------------------------------------------
local function SetPlayerState(params)
	ArenaData.PlayerState.m_Rank            = params.rank or ArenaData.PlayerState.m_Rank
	ArenaData.PlayerState.m_SuccessCount    = params.successcount or ArenaData.PlayerState.m_SuccessCount
    ArenaData.PlayerState.m_BestRank        = params.bestrank
    ArenaData.PlayerState.m_LastRewardRank  = params.lastrewardrank
	--ArenaData.PlayerState.m_Reputation    = params.reputation or ArenaData.PlayerState.m_Reputation
	--ArenaData.PlayerState.m_ReputationIncrease = params.reputationincrease or ArenaData.PlayerState.m_ReputationIncrease
end

--获取声望增长速度
local function GetReputationIncrease(rank)
	if rank == nil or rank < 0 then
		return 0
	end
	local reputationincrease = 0
	local arenaConfig = ConfigManager.getConfig("arenaconfig")
	local reputationList = arenaConfig.shengwangsteplist
	if reputationList and rank > 0 then
		for i = 1,#reputationList do
			local k = reputationList[#reputationList- i + 1]
			if rank <= k.minrank then
				reputationincrease = k.addshengwang
			end
		end
	end
	return reputationincrease
end
--获取玩家信息
local function GetPlayerInfo()
	local state = {}
	state.m_Rank = ArenaData.PlayerState.m_Rank
	state.m_SuccessCount = ArenaData.PlayerState.m_SuccessCount
	state.m_Reputation = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ShengWang)
	state.m_ReputationIncrease = GetReputationIncrease(state.m_Rank)

	local vipLevel = PlayerRole:Instance().m_VipLevel
	--refreshopponentlimit
	local serverlimit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.ARENA_CHALLENGE,0) or {[1]=0}
	local serverLimit2 = LimitManager.GetLimitTime(cfg.cmd.ConfigId.ARENA_REFRESH_OPPONENT,0) or {[1]=0}
	--printyellow("LLimit")
	--printt(serverlimit)
	--printt(serverLimit2)
	
	local arenaConfig = ConfigManager.getConfig("arenaconfig")

	state.m_RefreshCurrency = 0
	state.m_ChallengeCurrency = 0
	state.m_ChallengeNum = 0
	--state.m_SuccessCount = serverlimit[1]--ArenaData.PlayerState.m_SuccessCount
	state.m_ChallengeCount = serverlimit[1]
	state.m_RefreshNum = serverLimit2[1]
	local maxLv = #arenaConfig.challengelimit.entertimes
	state.m_MaxChallengeNum = arenaConfig.challengelimit.entertimes[maxLv]
	if vipLevel+1 <= maxLv then
		state.m_ChallengeNum = arenaConfig.challengelimit.entertimes[vipLevel+1]
	else
		state.m_ChallengeNum = arenaConfig.challengelimit.entertimes[#arenaConfig.challengelimit.entertimes]
	end

	if state.m_ChallengeCount +1 <= #arenaConfig.challengelimit.amout then
		state.m_ChallengeCurrency = arenaConfig.challengelimit.amout[state.m_ChallengeCount+1]
	else
		state.m_ChallengeCurrency = arenaConfig.challengelimit.amout[#arenaConfig.challengelimit.amout]
	end

	if state.m_RefreshNum+1 <= #arenaConfig.refreshopponentlimit.amout then
		state.m_RefreshCurrency = arenaConfig.refreshopponentlimit.amout[state.m_RefreshNum+1]
	else
		state.m_RefreshCurrency = arenaConfig.refreshopponentlimit.amout[#arenaConfig.refreshopponentlimit.amout]
	end

	return state
end

local function HasFightReport(report)
	if ArenaData.FightReportList==nil then
		ArenaData.FightReportList = {}
	end
	for k, it in pairs(ArenaData.FightReportList) do
		if it.m_Time == report.fighttime
		  and it.m_OpponentName==report.opponentname then
			return true
		end
	end
	return false
end
--战报信息
local function OnMsgSNewFightReport(msg)
	printyellowmodule( Local.LogModuals.Arena, msg)
	if msg == nil then
		return
	end
	local arenaConfig = ConfigManager.getConfig("arenaconfig")
	local reportMaxCount = arenaConfig.maxreportnum
	if not HasFightReport(msg.report) then
		local newReport = FightReportInfo:new(msg.report)
		table.insert(ArenaData.FightReportList, 1, newReport)
		if #ArenaData.FightReportList > reportMaxCount then
			table.remove(ArenaData.FightReportList, #ArenaData.FightReportList)
		end
		ArenaData.m_Rank = newReport.m_ResultRank
	end
	--print("OnMsgSNewFightReport Reports:"..newReport:ToString())
	UIManager.refresh("arena.single.dlgarenafightreport")
end

------------------------------------------------------------------------------------------------------
--竞技场信息（进入游戏时发送）
local function OnMsgSInfo(msg)
	printyellowmodule( Local.LogModuals.Arena, msg)
	if msg == nil then
		return
	end

	SetPlayerState({ 
        successcount        = msg.challengesuccnum,
        rank                = msg.rank,
        bestrank            = msg.bestrank,
        lastrewardrank      = msg.lastrewardrank,
        reputation          = nil,
        reputationincrease  = nil })

	local arenaConfig = ConfigManager.getConfig("arenaconfig")
	ArenaData.RewardsList = {}
	for i, rewardConfig in ipairs(arenaConfig.specialawardlist) do
		local rewards = RewardsInfo:new(rewardConfig)
		for i,obtainTimes in pairs(msg.obtainrewards) do
			if rewardConfig.times == obtainTimes then
				rewards:SetReceived(true)
			end
		end
		table.insert(ArenaData.RewardsList, rewards)
	end
	--printyellow("=========================================")
	--printyellow(msg.challengesuccnum,ArenaData.PlayerState.m_SuccessCount)
	--printt(ArenaData.RewardsList)
	
	local strTmp = "OnMsgSInfo Reports:"
	ArenaData.FightReportList = {}
	for i, report in ipairs(msg.reports) do
		local newReport = FightReportInfo:new(report)
		strTmp = strTmp.." "..i..":"..newReport:ToString().."\n"
		table.insert(ArenaData.FightReportList, 1, newReport)
	end
	--print(strTmp)
end
------------------------------------------------------------------------------------------------------
--获取挑战对手信息
local function GetChallenge()
	local re = lx.gs.arena.msg.CGetChallenge({})
	Network.send(re)
end

local function RefreshChallenge()
	local re = lx.gs.arena.msg.CRefreshChallenge({})
	Network.send(re)

end

local function OnMsgSGetChallenge(msg)
	printyellowmodule( Local.LogModuals.Arena, msg)
	if msg == nil then
		return
	end
	if msg.rank~=nil then
		ArenaData.PlayerState.m_Rank = msg.rank;
	end
	ArenaData.OpponentList = {}

	for i, oppInfo in ipairs(msg.challengeranks) do
		local opponent = PlayerInfo:new(oppInfo)
		table.insert(ArenaData.OpponentList,opponent)
	end
	UIManager.refresh("arena.single.tabarenachallenge")
end
------------------------------------------------------------------------------------------------------
--开始挑战
local function Challenge(rank)
	printyellowmodule(Local.LogModuals.Arena, "Challenge: " .. rank )
	local re = lx.gs.arena.msg.CChallenge({rank = rank})
	Network.send(re)
end
--竞技场挑战结束
local function OnMsgSChallenge(msg)
	printyellowmodule( Local.LogModuals.Arena, msg)
	if msg == nil then
		return
	end

	SetPlayerState({ successcount = msg.challengesuccnum, rank = msg.newrank ,reputation = nil ,reputationincrease = nil })
	OnMsgSGetChallenge({challengeranks = msg.challengeranks})

	UIManager.refresh("arena.single.tabarenachallenge")
end

------------------------------------------------------------------------------------------------------
--领取奖励
local function CanObtainDailyReward()
	local receiveMum = 0
	local playerInfo = GetPlayerInfo()
	for i = 1, #ArenaData.RewardsList do
		local rewardsInfo = ArenaData.RewardsList[i]
		if rewardsInfo.m_IsReceived == false and playerInfo.m_SuccessCount >= rewardsInfo.m_Times then
			receiveMum = receiveMum + 1
		end
	end
	if receiveMum > 0 then
		return true
	else
		return false
	end
end

local function ObtainDailySuccReward(rewardid)
	printyellowmodule(Local.LogModuals.Arena, "ObtainDailySuccReward: " .. rewardid )
	local re = lx.gs.arena.msg.CObtainDailySuccReward({rewardid=rewardid})
	Network.send(re)
end

local function OnMsgSObtainDailySuccReward(msg)
	printyellowmodule( Local.LogModuals.Arena, msg)
	if msg == nil then
		return
	end
	for i, k in pairs(ArenaData.RewardsList) do
		if k.m_Times == msg.rewardid then
			k.m_IsReceived = true
			local items = k.m_Items
			if items and #items>0 then
				UIManager.show("common.dlgdialogbox_itemshow", {itemList = items})
			end
		end
	end
	
	--

	UIManager.refresh("arena.single.dlgarenarewards")
	UIManager.call("arena.single.tabarenachallenge","ResetRedDot")
	--[[
	<variable name="rewardid" type="int"/>
	<variable name="bonus" type="lx.gs.bonus.msg.Bonus"/>
	]]
end

local function OnMsgSDayOver()
	ArenaData.PlayerState.m_SuccessCount = 0
	if ArenaData.RewardsList then
		for i, rewards in pairs(ArenaData.RewardsList) do
			rewards:SetReceived(false)
		end
	end

	if UIManager.isshow("arena.single.dlgarenarewards") then
		UIManager.refresh("arena.single.dlgarenarewards")
	end
	if UIManager.isshow("arena.single.tabarenachallenge") then
		UIManager.refresh("arena.single.tabarenachallenge")
	end
end

local function AddSuccessCount()
	ArenaData.PlayerState.m_SuccessCount = ArenaData.PlayerState.m_SuccessCount + 1
end

--初始化
local function Start()
	
	if listenerId then
        Network.remove_listeners(listenerId)
        listenerId = nil
    end	
	
   listenerId = Network.add_listeners( {
		--竞技场信息（进入游戏时发送）
		{ "lx.gs.arena.msg.SInfo", 					OnMsgSInfo				},
		--竞技场挑战结束
		{ "lx.gs.arena.msg.SChallenge", 			OnMsgSChallenge			},
		--获取对手信息
		{ "lx.gs.arena.msg.SGetChallenge", 			OnMsgSGetChallenge		},
		--战报
		{ "lx.gs.arena.msg.SNewFightReport", 		OnMsgSNewFightReport 	},
		--领取奖励
		{ "lx.gs.arena.msg.SObtainDailySuccReward", OnMsgSObtainDailySuccReward		},

		{ "lx.gs.role.msg.SDayOver",				OnMsgSDayOver			},
	} )

end

local function UnRead()
	local canGetRewards = CanObtainDailyReward()
	local status = GetPlayerInfo()
    return canGetRewards or (status.m_ChallengeCurrency <= 0)
end

local function GetOpenLevel()
	local arenaCfg = ConfigManager.getConfig("arenaconfig")
	return arenaCfg.openlevel
end


return {
	Start 					= Start,
	ArenaData 				= ArenaData,
	GetReputationIncrease	= GetReputationIncrease,
	GetPlayerInfo			= GetPlayerInfo,
	GetChallenge			= GetChallenge,
	RefreshChallenge		= RefreshChallenge,
	Challenge				= Challenge,
	ObtainDailySuccReward	= ObtainDailySuccReward,
	CanObtainDailyReward	= CanObtainDailyReward,
    UnRead                  = UnRead,
	AddSuccessCount			= AddSuccessCount,
	GetOpenLevel			= GetOpenLevel,
}
