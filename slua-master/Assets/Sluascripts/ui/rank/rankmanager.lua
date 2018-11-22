local format           = string.format
local network          = require "network"
local UIManager        = require("uimanager")
local ConfigManager    = require("cfg.configmanager")
local LimitTimeManager = require("limittimemanager")
local BonusManager     = require("item.bonusmanager")
local gameevent        = require("gameevent")

local g_RanksData = { }

-- rank 的数据结构
local RankData = Class:new()
function RankData:__new(id, name, value1, value2)
	self.m_RoleId = id
	self.m_RoleName = name
	self.m_RankValue1 = value1
	self.m_RankValue2 = value2
end

local function pairsByRank(list)
	local key = { }
	local map = { }
	for _, rank in pairs(list) do
		key[#key + 1] = rank.requirerank
		map[rank.requirerank] = rank.bonuslist
	end
	-- 默认升序
	table.sort(key)
	local i = 0
	return function()
		i = i + 1
		return key[i], map[key[i]]
	end
end
-- 按照最好排名和上次取奖励的排名来获得奖励物品
local function GetArenaRankBonus(beginRank, endRank)
	local rankBonusList = ConfigManager.getConfig("arenaconfig").rankbonus

	local preRank = 0
	local BRank = beginRank
	local items = { }
	if endRank > 0 then
		-- 曾领取过奖励
		for requireRank, itemList in pairsByRank(rankBonusList) do

			if requireRank >= endRank then
				break
			end

			if BRank > preRank and BRank <= requireRank
				and requireRank < endRank then
				for _, item in pairs(BonusManager.GetItemsOfSingleBonus(itemList)) do
					items[#items + 1] = item
				end

				BRank = requireRank + 1
			end
			preRank = requireRank

		end
	else
		-- 未领取过奖励
		for requireRank, itemList in pairsByRank(rankBonusList) do

			if BRank > preRank and BRank <= requireRank then
				for _, item in pairs(BonusManager.GetItemsOfSingleBonus(itemList)) do
					items[#items + 1] = item
				end
				-- 将剩余的奖励也领取
				BRank = requireRank + 1
			end
			preRank = requireRank

		end
	end
	return items
end
-- 其他排行榜奖励取curRank所在奖励名次区间段的所有奖励物品
-- 例如 curRank = 4500，在配置里5000和4001区间段，奖励物品为此区间段的所有物品
-- 只要上过榜，每天都可以取到奖励，即便以后从未上过榜
local function GetGeneralRankBonus(rankType, curRank)
	local items = { }
	local preRank = 0

	local rankBonusData = ConfigManager.getConfigData("rankbonus", rankType)
	if not rankBonusData then
		return items
	end
	for requireRank, itemList in pairsByRank(rankBonusData.bonuslist) do
		if curRank > preRank and curRank <= requireRank then
			for _, item in pairs(BonusManager.GetItemsOfSingleBonus(itemList)) do
				items[#items + 1] = item
			end
			break
		end
		preRank = requireRank

	end
	return items
end

-- key 为ranktype，value是RankData数据
local function GetRankData()
	return g_RanksData
end

-- region msg
local function OnMsg_SLatestLeaderBoard(msg)
	for rankType, rank in pairs(msg.latestbord) do
		g_RanksData[rankType].m_Ranks = { }
		for rankIdx, rankData in ipairs(rank.info) do
			g_RanksData[rankType].m_Ranks[rankIdx] = RankData:new(rankData.id, rankData.name, rankData.val1, rankData.val2)
		end
	end
	if UIManager.isshow("rank.dlgranklist") then
		UIManager.call("rank.dlgranklist","RefreshRanklist")
	end
	-- 红点刷新
	if UIManager.hasloaded("dlguimain") then 
		UIManager.call("dlguimain", "RefreshRedDotType", cfg.ui.FunctionList.RANKLIST)
	end
end

local function OnMsg_SRoleRanking(msg)
	for rankType, curRank in pairs(msg.info) do
		g_RanksData[rankType].m_CurRank = curRank
	end
	if UIManager.isshow("rank.dlgranklist") then
		UIManager.call("rank.dlgranklist","RefreshCurRank")
	end
end
-- 昨天0点前最新排名，以此排名来领取奖励
local function OnMsg_SYesterdayRanking(msg)
	for rankType, preRank in pairs(msg.info) do
		g_RanksData[rankType].m_PreRank = preRank
	end
	if UIManager.isshow("rank.dlgranklist") then
		UIManager.call("rank.dlgranklist","RefreshRewardInfo")
	end
end
-- endregion msg

local function UnReadType(rankType)
	local rankConfigData = ConfigManager.getConfigData("rank", rankType)
	-- 0s时前是否上榜
	if g_RanksData[rankType].m_PreRank > 0 and g_RanksData[rankType].m_PreRank <= rankConfigData.ranksize then

		local getRewardTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.RANK, rankType)
		-- 即使上过榜，每天限制领取一次,有的榜单没有奖励，具体查看配置
		if getRewardTime == 0 then
			-- 未领取过奖励
			local bonusItems = GetGeneralRankBonus(rankType, g_RanksData[rankType].m_PreRank)
			return (#bonusItems ~= 0)
		else
			-- 已经领取过奖励
			return false
		end
	else
		-- 未上榜
		return false
	end

end
-- 红点提示
local function UnRead()
	-- 不包括竞技场榜
	for _, rankType in pairs(cfg.bonus.RankType) do
		if rankType ~= cfg.bonus.RankType.ARENA then 
			local bUnRead = UnReadType(rankType)
			if bUnRead then
				return true
			end	 
		end
	end
	return false
end

local function Release()
	-- 初始化数据(不包括竞技场榜)
	g_RanksData = { }
	for _, rankType in pairs(cfg.bonus.RankType) do
		g_RanksData[rankType] = { }
		g_RanksData[rankType].m_Ranks = { }
		g_RanksData[rankType].m_CurRank = -1
		g_RanksData[rankType].m_PreRank = -1
	end
end

local function OnLogout()
	Release()
end

local function init()
	-- 初始化数据(不包括竞技场榜)
	for _, rankType in pairs(cfg.bonus.RankType) do
		g_RanksData[rankType] = { }
		g_RanksData[rankType].m_Ranks = { }
		g_RanksData[rankType].m_CurRank = -1
		g_RanksData[rankType].m_PreRank = -1
	end
	network.add_listeners( {
		{ "lx.gs.leaderboard.msg.SRoleRanking", OnMsg_SRoleRanking },
		{ "lx.gs.leaderboard.msg.SLatestLeaderBoard", OnMsg_SLatestLeaderBoard },
		{ "lx.gs.leaderboard.msg.SYesterdayRanking", OnMsg_SYesterdayRanking },
	} )

	gameevent.evt_system_message:add("logout", OnLogout)
end

return {
	init                = init,
	UnRead              = UnRead,
	UnReadType          = UnReadType,
	GetRankData         = GetRankData,
	GetGeneralRankBonus = GetGeneralRankBonus,

}