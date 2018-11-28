local ConfigManager = require("cfg.configmanager")
local BonusManager  = require("item.bonusmanager")
local Network       = require("network")
local UIManager     = require("uimanager")

local DayChargeBonusData = {
    m_ActivityItems = {}
}

local DayChargeActivity = Class:new()

function DayChargeActivity:__new(config)
    self.m_Id           = config.activityinfo.id
    self.m_GroupId      = config.groupid
    self.m_Description  = config.activityinfo.condition.description1
    self.m_Number       = config.activityinfo.condition.num
    self.m_Rewards      = BonusManager.GetItemsByBonusConfig(config.activityinfo.reward)
    self.m_Status       = cfg.operationalactivity.OperationStatus.NOT_COMPLETE
    self.m_Config       = config.config
    self.m_IsOpen       = true
    self.m_StartTime    = -1
    self.m_EndTime      = -1
end

function DayChargeActivity:SetServerMsg(msg)
    self.m_Status = msg.status
    self.m_StartTime = msg.opentime/1000
    self.m_EndTime = msg.closetime/1000
    if msg.isopen == 1 then
        self.m_IsOpen = true
    else
        self.m_IsOpen = false
    end
end

function DayChargeActivity:GetGroupId()
    return self.m_GroupId
end

function DayChargeActivity:GetItemId()
    return self.m_Id
end

function DayChargeActivity:IsMatchCondition()
    if self.m_Status == cfg.operationalactivity.OperationStatus.COMPLETE then
        return true
    else
        return false
    end

end

function DayChargeActivity:IsFinish()
    return (self.m_Status == cfg.operationalactivity.OperationStatus.GETREWARD)
end

function DayChargeActivity:IsComplete()
    return (self.m_Status == cfg.operationalactivity.OperationStatus.COMPLETE)
end

function DayChargeActivity:SetDayOver()
    self.m_Status = cfg.operationalactivity.OperationStatus.NOT_COMPLETE
end

function DayChargeActivity:GetFinishedLabel()
    return self.m_Config.finishedlabel
end

function DayChargeActivity:GetUnFinishLabel()
    return self.m_Config.unfinishlabel
end

function DayChargeActivity:Receive()
    self.m_Status = cfg.operationalactivity.OperationStatus.GETREWARD
end

function DayChargeActivity:GetRewards()
    return self.m_Rewards
end

function DayChargeActivity:Change(msg)
    self.m_Status = msg.status
end

--==================================================================================
local function GetActivityItemById(id)
    for i, activityItem in pairs(DayChargeBonusData.m_ActivityItems) do
        if activityItem:GetItemId() == id then
            return activityItem
        end
    end
    return nil
end
local function RefreshUI()
	if UIManager.isshow("vipcharge.tabdaycharge") then
		UIManager.refresh("vipcharge.tabdaycharge")
	end

   UIManager.RefreshRedDot()

end
--=================================================================================
local function OnMsgSActivity(msg)
	for key, value in pairs(msg.activityinfos) do
        local activityItem = GetActivityItemById(value.id)
        if activityItem then
            activityItem:SetServerMsg(value)
        end
	end
end

local function OnMsgSReceiveActivityBonus(msg)
	local activityItem = GetActivityItemById(msg.cmdid)
    if activityItem then
        activityItem:Receive()
        local items = activityItem:GetRewards()
        UIManager.show("common.dlgdialogbox_itemshow", {itemList = items})

        RefreshUI()
    end
end

local function OnMsgSActivityChangeNotify(msg)
    local activityItem = GetActivityItemById(msg.cmdid)
    if activityItem then
        activityItem:Change(msg)
        RefreshUI()
    end
end

local function OnMsgSDayOver()
    for i, activityItem in pairs(DayChargeBonusData.m_ActivityItems) do
        activityItem:SetDayOver()
    end
    RefreshUI()
end

local function ReceiveActivityBonus(groupId, itemId)
	local re = lx.gs.activity.msg.CReceiveActivityBonus({ id = groupId, cmdid = itemId})
	Network.send(re)
end

local function LoadConfig()
    DayChargeBonusData.m_ActivityItems = {}

    local CfgIndex = ConfigManager.getConfig("daychargebonusindex")

    for i, index in pairs(CfgIndex.index) do
        local Cfgs = ConfigManager.getConfigData("operationalactivity", index)
        if Cfgs then
            for j, chargeCfg in pairs(Cfgs.activityinfo) do
                local activity = DayChargeActivity:new({config = Cfgs, activityinfo = chargeCfg, groupid = index })
                table.insert( DayChargeBonusData.m_ActivityItems, activity )
            end
        end
    end

end

local function GetActivityItems()
    return DayChargeBonusData.m_ActivityItems
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
	} )

end

return {
    init = init,
    GetActivityItems = GetActivityItems,
    ReceiveActivityBonus = ReceiveActivityBonus,
}

