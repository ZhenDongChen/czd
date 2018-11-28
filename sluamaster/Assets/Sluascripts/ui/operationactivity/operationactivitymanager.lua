local Network = require("network")
local ConfigManager = require("cfg.configmanager")
local ActivityGroup = require("ui.operationactivity.base.activitygroup")
local UIManager = require("uimanager")
local PlayerRole = require "character.playerrole"
local TimeUtils = require("common.timeutils")

local bNeedShowRecommend = true

local OperationActivityData = {
	m_ActivityGroups = {}
}

local function GetActivityGroup(groupId)
	return OperationActivityData.m_ActivityGroups[groupId]
end

local function GroupSortFunc(groupA, groupB)
	if groupA:GetId() <= groupB:GetId() then
		return true
	else
		return false
	end
end

local function RefreshUI()
	UIManager.refresh("operationactivity.taboperationactivity")
end

local function GetActivityGroupList()
	local list = {}
	for key, value in pairs(OperationActivityData.m_ActivityGroups) do
		table.insert( list, value )
	end
	table.sort( list, GroupSortFunc )
	return list
end

local function OnMsgSActivity(msg)
	--printyellowmodule(Local.LogModuals.OperationActivity,msg)
	for key, value in pairs(msg.activityinfos) do
		for i, activityGroup in pairs(OperationActivityData.m_ActivityGroups) do
			local activityItem = activityGroup:GetActivityItem(key)
			if activityItem then
				activityItem:SetServerMsg(value)
			end
		end
	end
end

local function ReceiveActivityBonus(groupId, itemId)
	--printyellowmodule(Local.LogModuals.OperationActivity, groupId, itemId)
	local re = lx.gs.activity.msg.CReceiveActivityBonus({ id = groupId, cmdid = itemId})
	Network.send(re)
end

local function OnMsgSReceiveActivityBonus(msg)
	--printyellowmodule(Local.LogModuals.OperationActivity,msg)
	local activityGroup = GetActivityGroup(msg.id)
	if activityGroup then
		local acitityItem = activityGroup:GetActivityItem(msg.cmdid)
		if acitityItem then
			acitityItem:Receive()
			local items = acitityItem:GetRewards()
			--printyellow("itemNum",#items)
			UIManager.show("common.dlgdialogbox_itemshow", {itemList = items})

		end
	end
	--UIManager.ShowSingleAlertDlg({content = LocalString.Common_ReceiveSuccess, immediate = true})
	UIManager.ShowSystemFlyText(LocalString.Common_ReceiveSuccess)
	RefreshUI()
end

local function OnMsgSActivityChangeNotify(msg)
	--printyellowmodule(Local.LogModuals.OperationActivity,msg)
	local activityGroup = GetActivityGroup(msg.id)
	if activityGroup then
		local acitityItem = activityGroup:GetActivityItem(msg.cmdid)
		if acitityItem then
			acitityItem:Change(msg)
		end
	end
	RefreshUI()
end

local function LoadConfig()
	local operaionActivityCfgIndex = ConfigManager.getConfig("operationalactivityindex")

	for i, index in pairs(operaionActivityCfgIndex.index) do
		local groupCfg = ConfigManager.getConfigData("operationalactivity",index)
		if groupCfg then
			OperationActivityData.m_ActivityGroups[index] = ActivityGroup:new(groupCfg)
		end
	end

    -- local operaionActivityCfg = ConfigManager.getConfig("operationalactivity")

    -- for i, groupCfg in pairs(operaionActivityCfg) do
	-- 	OperationActivityData.m_ActivityGroups[i] = ActivityGroup:new(groupCfg)
	-- end
end

local function UnRead()
	local result = false
	for groupId, group in pairs(OperationActivityData.m_ActivityGroups) do
		if group:UnRead() == true then
			result = true
		end
	end
	return result
end

local function OnMsgSDayOver()
	if UIManager.isshow("operationactivity.taboperationactivity") then
		UIManager.refresh("operationactivity.taboperationactivity")
	end
end

local function GetActivityParams(groupId)
	local re = lx.gs.activity.msg.CActivityParams({id = groupId})
	Network.send(re)
end

local function OnMsgSActivityParams(msg)
	local activityGroup = GetActivityGroup(msg.id)
	if activityGroup then
		activityGroup:SetMsgParams(msg.params)
	end
	if UIManager.isshow("operationactivity.taboperationactivity") then
		UIManager.refresh("operationactivity.taboperationactivity")
	end
end

local function GetAllActivityParams()
	for key, group in pairs(OperationActivityData.m_ActivityGroups) do
		if group:NeedMsgParams() then
			GetActivityParams(group:GetId())
		end
	end
end


local function init()
    LoadConfig()
    Network.add_listeners( {
		--活动信息
		{ "lx.gs.activity.msg.SActivity", 				OnMsgSActivity				},
		--领取活动奖励
		{ "lx.gs.activity.msg.SReceiveActivityBonus", 	OnMsgSReceiveActivityBonus	},
		--活动状态改变协议
		{ "lx.gs.activity.msg.SActivityChangeNotify", 	OnMsgSActivityChangeNotify	},

		{ "lx.gs.role.msg.SDayOver",					OnMsgSDayOver				},

		{ "lx.gs.activity.msg.SActivityParams",				OnMsgSActivityParams		},
	} )
end

local function CheckOperationActivity(groupid)
	local group = GetActivityGroup(groupid)
	local items = group:GetActivityItems()
	for _, item in pairs(items) do
		if item:IsComplete() and not item:IsFinish() then
			UIManager.showdialog("operationactivity.dlgnewserverlevelbonus",{groupid  = groupid,itemid = item:GetId()})
			return
		end
	end
end

local function NeedShowRecommend()
	--local key = "act_recommend_"..PlayerRole:Instance().m_Id
	--local timeNow = TimeUtils.TimeNow()
	--local timeNow1 = timeNow.year*10000 + timeNow.month + timeNow.day
	if bNeedShowRecommend then
		bNeedShowRecommend = false
		return true
	end
	return false
end

return {
    init = init,
	GetActivityGroupList = GetActivityGroupList,
	GetActivityGroup = GetActivityGroup,
	ReceiveActivityBonus = ReceiveActivityBonus,
	UnRead = UnRead,
	GetActivityParams = GetActivityParams,
	GetAllActivityParams = GetAllActivityParams,
	CheckOperationActivity = CheckOperationActivity,
	NeedShowRecommend = NeedShowRecommend,
}