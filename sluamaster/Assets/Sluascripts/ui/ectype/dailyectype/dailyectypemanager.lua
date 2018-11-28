local NetWork = require("network")
local TaskManager=require("taskmanager")
local LimitManager=require("limittimemanager")
local ConfigManager = require("cfg.configmanager")
local UIManager = require("uimanager")
local BagManager = require("character.bagmanager")
local PlayerRole = require("character.playerrole"):Instance()
local DefineEnum = require("defineenum")
local TaskStatusType = DefineEnum.TaskStatusType

local DAILYECTYPE_Index = 2  --日常副本标签索引

local m_DailyEctypeType =
{
cfg.ectype.EctypeType.CURRENCY,
cfg.ectype.EctypeType.EXP,
cfg.ectype.EctypeType.YUPEI,
cfg.ectype.EctypeType.HUFU,
}

local function GetFreeTimes(ectypeType)
	local ectypeSingleData = ConfigManager.getConfig("ectypesingle")
	local vipLimit = ectypeSingleData.ectypes[ectypeType].viptimes
	local vipLevel = PlayerRole.m_VipLevel
	local canEnterTime = 0
	local i = 0
	if vipLimit then
		for _,time in pairs(vipLimit.entertimes) do
			if i == vipLevel then
				canEnterTime = time
				break
			end
			i = i + 1
		end
	end
	return canEnterTime
end

local function GetTaskName(taskId)
	local name = ""
	local task = TaskManager.GetTask(taskId)
	if task then
	    name = task.basic.name
	end
	return name
end

local function FinishTask(taskId)
	local finish = false
	finish = (TaskManager.GetTaskStatus(taskId) == TaskStatusType.Completed)
	return finish
end

local function GetEctypeInfo(ectypeType)
	local ectypeSingleData = ConfigManager.getConfig("ectypesingle")
	local ectypeInfo = ectypeSingleData.ectypes[ectypeType]
	return ectypeInfo
end

local function GetEctypeByType(ectypeType)
	local ectypeData = ConfigManager.getConfig("ectypebasic")
	local ectypes = {}
	if ectypeType == cfg.ectype.EctypeType.CURRENCY then
		local currencyEctypes = ConfigManager.getConfig("currencyectype")
		if currencyEctypes then
			ectypes = currencyEctypes
		end
	elseif ectypeType == cfg.ectype.EctypeType.EXP then
		local expEctypes = ConfigManager.getConfig("expectype")
		if expEctypes then
			ectypes = expEctypes
		end
	else
		local dailyEctype = ConfigManager.getConfig("dailyectype")
		for id,ectypeItem in pairs(dailyEctype) do
			if ectypeData[id] and ectypeData[id].type == ectypeType then
				ectypes[id] = ectypeItem
			end
		end
	end
	table.sort(ectypes, function (a,b)
		if (a.openlevel.level >= b.openlevel.level) then
			return true
		else
			return false
		end
	end)
	return ectypes
end

local function GetDefaultEctype(ectypeType)
	local ectypeData = GetEctypeByType(ectypeType)
	local ectype = nil
	local level
	if ectypeData then
		for _,ectypeItem in pairs(ectypeData) do
			if level == nil then
				level = ectypeItem.openlevel.level
				ectype = ectypeItem
			elseif ectypeItem.openlevel.level < level then
				level = ectypeItem.openlevel.level
				ectype = ectypeItem
			end
		end
	end
	return ectype
end

local function GetEctypeByLevel(ectypeType)
	local ectypes = GetEctypeByType(ectypeType)
	local ectype = nil
	local eId = 0
	if ectypes then
		for id,ectypeItem in pairs(ectypes) do
			if (PlayerRole:GetLevel() >= ectypeItem.openlevel.level) then
				if (ectype) then
					if (ectype.openlevel.level < ectypeItem.openlevel.level) then
						ectype = ectypeItem
						eId = id
					end
				else
					ectype = ectypeItem
					eId = id
				end
			end
		end
	end
	return ectype,eId
end

local function GetBasicEctypeById(id)
	local ectype = nil
	local ectypeData = ConfigManager.getConfig("ectypebasic")
	if ectypeData[id] then
		ectype = ectypeData[id]
	end
	return ectype
end

local function HasRemainChallengeTimeByType(ectypeType)
	local result = false
	local ectype,eId = GetEctypeByLevel(ectypeType)
	if ectype then
		local enterTime = GetFreeTimes(ectypeType)
		local useTime = 0
		local limit = nil
		limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.DAILY_ECTYPE,ectypeType)
		if limit then
			useTime = limit[cfg.cmd.condition.LimitType.DAY]
		end
		if enterTime > useTime then
			result = true
		end
	end
	return result
end

local function HasRemainChallengeTime()
	local result = false
	for _,ectypeType in pairs(m_DailyEctypeType) do
		if HasRemainChallengeTimeByType(ectypeType) == true then
			result = true
			break
		end
	end
	if result == false then
		--个人boss
		local personalBoss = require("ui.activity.personalboss.personalboss")
		result = personalBoss.UnRead()
	end
	if result == false then
		--天玄英雄录
		local herobookmanager = require("ui.activity.herobook.herobookmanager")
		result = herobookmanager.UnRead()
	end
	return result
end

local function SendGetBestRecord(ectypeType)
	local msg = lx.gs.map.msg.CGetDailyBestRecord({ectypetype = ectypeType})
	NetWork.send(msg)
end

local function SendResetOpenCount(type)
	local msg = lx.gs.map.msg.CResetDailyEctypeOpenCount({ectypetype = type})
	NetWork.send(msg)
end

local function OnMsg_SResetDailyEctypeOpenCount(msg)
	if UIManager.isshow("activity.tabdailyectypeone") then
		UIManager.call("activity.tabdailyectypeone","DisplayDetailDailyEctype",msg.ectypetype)
	end
	if UIManager.isshow("activity.tabdailyectypetwo") then
		UIManager.call("activity.tabdailyectypetwo","DisplayDetailDailyEctype",msg.ectypetype)
	end
	if UIManager.isshow("activity.tabdailyectypethree") then
		UIManager.call("activity.tabdailyectypethree","DisplayDetailDailyEctype",msg.ectypetype)
	end
	if UIManager.isshow("activity.tabdailyectypefour") then
		UIManager.call("activity.tabdailyectypefour","DisplayDetailDailyEctype",msg.ectypetype)
	end
	-- if UIManager.isshow("ectype.dailyectype.tabdailyectype") then
	-- 	UIManager.call("ectype.dailyectype.tabdailyectype","DisplayDetailDailyEctype",msg.ectypetype)
	-- end
	UIManager.RefreshRedDot()
end

local function OnMsg_SGetDailyBestRecord(msg)
	if UIManager.isshow("activity.tabdailyectypeone") then
		UIManager.call("activity.tabdailyectypeone","OnMsg_SGetDailyBestRecord",msg)
	end
	if UIManager.isshow("activity.tabdailyectypetwo") then
		UIManager.call("activity.tabdailyectypetwo","OnMsg_SGetDailyBestRecord",msg)
	end
	if UIManager.isshow("activity.tabdailyectypethree") then
		UIManager.call("activity.tabdailyectypethree","OnMsg_SGetDailyBestRecord",msg)
	end
	if UIManager.isshow("activity.tabdailyectypefour") then
		UIManager.call("activity.tabdailyectypefour","OnMsg_SGetDailyBestRecord",msg)
	end

	-- if UIManager.isshow("ectype.dailyectype.tabdailyectype") then
	-- 	UIManager.call("ectype.dailyectype.tabdailyectype","OnMsg_SGetDailyBestRecord",msg)
	-- end
end

local function SendSweep(ectypeType,profession)
	local msg = lx.gs.map.msg.CSweepDailyEctype({ectypetype = ectypeType})
	NetWork.send(msg)
end

local function OnMsg_SSweepDailyEctype(msg)
	-- if UIManager.isshow("ectype.dailyectype.tabdailyectype") then
	-- 	UIManager.call("ectype.dailyectype.tabdailyectype","DisplayDetailDailyEctype",msg.ectypetype)
	-- 	UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
	-- end


	if UIManager.isshow("activity.tabdailyectypeone") then
		UIManager.call("activity.tabdailyectypeone","DisplayDetailDailyEctype",msg.ectypetype)
		UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
	end
	if UIManager.isshow("activity.tabdailyectypetwo") then
		UIManager.call("activity.tabdailyectypetwo","DisplayDetailDailyEctype",msg.ectypetype)
		UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
	end
	if UIManager.isshow("activity.tabdailyectypethree") then
		UIManager.call("activity.tabdailyectypethree","DisplayDetailDailyEctype",msg.ectypetype)
		UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
	end
	if UIManager.isshow("activity.tabdailyectypefour") then
		UIManager.call("activity.tabdailyectypefour","DisplayDetailDailyEctype",msg.ectypetype)
		UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
	end
	if UIManager.isshow("activity.tabactivitylist") then
		UIManager.call("activity.tabactivitylist","DisplayDetailDailyEctype",msg.ectypetype)
	end
end

local function HasEnoughSweepTicket(sweepInfo)
	local result = false
	local itemNum = BagManager.GetItemNumById(sweepInfo.cost.itemid)
	if itemNum >= sweepInfo.cost.amount then
		result = true
	end
	return result
end

local function GetSweepNumAndName(sweepInfo)
	local name = ""
	local ItemManager = require("item.itemmanager")
	local itemNum = BagManager.GetItemNumById(sweepInfo.cost.itemid)
	local item = ItemManager.CreateItemBaseById(sweepInfo.cost.itemid)
	if item then
		name = item:GetName()
	end
	return itemNum,name
end
local function init()
	NetWork.add_listeners({
	{"lx.gs.map.msg.SResetDailyEctypeOpenCount",OnMsg_SResetDailyEctypeOpenCount},
	{"lx.gs.map.msg.SGetDailyBestRecord",OnMsg_SGetDailyBestRecord},
	{"lx.gs.map.msg.SSweepDailyEctype",OnMsg_SSweepDailyEctype},
	})
end

local function UnRead()
	local result = false
	local ModuleLockManager = require("ui.modulelock.modulelockmanager")
	if ModuleLockManager.GetModuleStatusByIndex("ectype.dlgentrance_copy",DAILYECTYPE_Index) == DefineEnum.ModuleStatus.UNLOCK then
		result = HasRemainChallengeTime()
	end
	return result
end

return{
	init = init,
	GetFreeTimes = GetFreeTimes,
	GetEctypeByLevel = GetEctypeByLevel,
	GetDefaultEctype = GetDefaultEctype,
	GetEctypeInfo = GetEctypeInfo,
	GetBasicEctypeById = GetBasicEctypeById,
	HasRemainChallengeTime = HasRemainChallengeTime,
	HasRemainChallengeTimeByType = HasRemainChallengeTimeByType,
	SendResetOpenCount = SendResetOpenCount,
	SendGetBestRecord = SendGetBestRecord,
	SendSweep = SendSweep,
	HasEnoughSweepTicket = HasEnoughSweepTicket,
	GetSweepNumAndName = GetSweepNumAndName,
	UnRead = UnRead,
}