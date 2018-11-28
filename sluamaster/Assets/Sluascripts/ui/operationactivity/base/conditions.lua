local ItemManager  = require("item.itemmanager")
local BagManager   = require("character.bagmanager")
local LimitManager = require("limittimemanager")
local CheckCmd     = require("common.checkcmd")

--==========================================================================
local Condition_Base = Class:new()
function Condition_Base:__new(activityItem, type, config)
    self.m_Type = type
    self.m_Config = config
    self.m_ActivityItem = activityItem
end
function Condition_Base:GetShowGroup()
    return self.m_Type
end
function Condition_Base:GetConditionText()
    return self.m_Config.description1
end
function Condition_Base:GetConditionText2()
    return self.m_Config.description2
end

function Condition_Base:IsNeedSort()
    return false
end

--==========================================================================
local Condition_Collection = Class:new(Condition_Base)
function Condition_Collection:__new(activityItem, config)
    Condition_Base.__new(self, activityItem, "collection", config)
    self.m_CollectionItems = {}
    for i, item in pairs(self.m_Config.items.items) do
        table.insert( self.m_CollectionItems, ItemManager.CreateItemBaseById(item.itemid,nil,item.amount) )
    end
end
function Condition_Collection:GetCollectionItems()
    return self.m_CollectionItems
end
function Condition_Collection:GetDayTimes()
    local limitTimes = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
    return self.m_Config.daylimit.num - limitTimes
end
function Condition_Collection:GetAllTimes()
    local limitTimes = LimitManager.GetLifelongLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
    return self.m_Config.totallimit.num - limitTimes
end

function Condition_Collection:GetItemNumber(item)
    local configId = item:GetConfigId()
    local items = BagManager.GetItemById(configId)
    if items and #items > 0 then
        local bagItemNum = 0
        for i, bagItem in pairs(items) do
            bagItemNum = bagItemNum + bagItem:GetNumber()
        end
        return bagItemNum, item:GetNumber()
    end
    return 0, item:GetNumber()
end

function Condition_Collection:ExistItem(item)
    local bagNum, NeedNum = self:GetItemNumber(item)
    if bagNum >= NeedNum then
        return true
    end
    return false
end

function Condition_Collection:ExistAllItem()
    for i, item in pairs(self.m_CollectionItems) do
        if self:ExistItem(item) == false then
            return false
        end
    end
    return true
end




function Condition_Collection:IsMatchCondition()
    return self:ExistAllItem() and (self:GetDayTimes() > 0) and (self:GetAllTimes() > 0)
end

function Condition_Collection:UnRead()
    local isMatchCodition = self:IsMatchCondition()
    return isMatchCodition
end

function Condition_Collection:IsNeedSort()
    return false
end

--==========================================================================
local Condition_Charge = Class:new(Condition_Base)
function Condition_Charge:__new(activityItem, config)
    Condition_Base.__new(self, activityItem, "chargereward", config)
end
function Condition_Charge:GetSpriteName()
    return ""
end
function Condition_Charge:GetCurrencyCount()
    if self.m_Config.class == "cfg.operationalactivity.DailyRecharge" then
        return self.m_Config.num
    elseif self.m_Config.class == "cfg.operationalactivity.RechargeShop" then
        return self.m_Config.cost.amount
    else
        return 0
    end
end
function Condition_Charge:GetDayTimes()
    if self.m_Config.class == "cfg.operationalactivity.DailyRecharge" then
        local limitTimes1 = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
        if limitTimes1 then
            return self.m_Config.daylimit.num - limitTimes1
        else
            return 0
        end
    elseif self.m_Config.class == "cfg.operationalactivity.RechargeShop" then
        local limitTimes2 = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
        if limitTimes2 then
            return self.m_Config.limit.num - limitTimes2
        else
            return 0
        end
    else
        return 0
    end
end
function Condition_Charge:GetAllTimes()
    return 0
end
function Condition_Charge:IsMatchCondition()
    local costCurrency = self:GetCurrencyCount()
    local allCurrency = PlayerRole:Instance():GetCurrency(self.m_ActivityItem:GetCurrencyType())
    if costCurrency <= allCurrency then
        return true
    end
    return false

end
function Condition_Charge:UnRead()
    --return false
    return self:IsMatchCondition()
end

function Condition_Charge:IsNeedSort()
    return false
end

--==========================================================================
local Condition_GiftBag = Class:new(Condition_Base)
function Condition_GiftBag:__new(activityItem, config)
    Condition_Base.__new(self, activityItem, "giftbag", config)
end
function Condition_GiftBag:GetSpriteName()
    return ""
end
function Condition_GiftBag:GetOriginalPrice()
    return self.m_Config.original.amount
end
function Condition_GiftBag:GetCurrentPrice()
    return self.m_Config.off.amount
end


function Condition_GiftBag:GetDayTimes()
    local limitTimes = LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
    return self.m_Config.daylimit.num - limitTimes
end
function Condition_GiftBag:GetTotalTimes()
    local limitTimes = LimitManager.GetLifelongLimitTime(cfg.cmd.ConfigId.OPERATION_ACTIVITY, self.m_ActivityItem.m_Id)
    return self.m_Config.totallimit.num - limitTimes
end
function Condition_GiftBag:ShowTotalLimit()
    if self.m_Config.totallimit.num < 0 then
        return false
    end
    return true
end
function Condition_GiftBag:ShowDayLimit()
    if self.m_Config.daylimit.num < 0 then
        return false
    end
    return true
end

function Condition_GiftBag:GetVipLimit()
    return self.m_Config.viplimit.level
end

function Condition_GiftBag:IsMatchConditionLimit()
--[[
    			<field name="viplimit" type="cfg.cmd.condition.MinVipLevel"/>
			<field name="limit" type="cfg.cmd.condition.DayLimit"/> 每日限购次数
			<field name="original" type="cfg.cmd.condition.YuanBao"/>原价
			<field name="off" type="cfg.cmd.condition.YuanBao"/>打折后
]]
    --======================================================
    --Vip限制
    local re1, info1 = CheckCmd.CheckData({ 
                        data = self.m_Config.viplimit,
                        showsysteminfo = false,
                        num = 1,})
    --=====================================================
    --每日限制
    local re3 = true

    if self:ShowDayLimit() then
        local leastTime = self:GetDayTimes()
        if leastTime<=0 then
            re3 = false
        end
    end
    --=====================================================
    --总共限制
    local re4 = true

    if self:ShowTotalLimit() then
        local totalTime = self:GetTotalTimes()
        if totalTime<=0 then
            re4 = false
        end
    end

    return re1 and re3 and re4
end


function Condition_GiftBag:IsMatchCondition()
    local re1 = self:IsMatchConditionLimit()

    local playerYuanbao = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.YuanBao)
    
    local re2 = true
    if self.m_Config.off.amount > playerYuanbao then
        re2 = false
    end

    return re1 and re2
end
function Condition_GiftBag:UnRead()
   -- return false
    return self:IsMatchConditionLimit()
end

function Condition_GiftBag:IsNeedSort()
    return false
end

--==========================================================================
local Condition_Upgrade = Class:new(Condition_Base)
function Condition_Upgrade:__new(activityItem, config)
    Condition_Base.__new(self, activityItem, "upgrade", config)
end

function Condition_Upgrade:IsNeedSort()
    return true
end
--==========================================================================
local Condition_UpgradeParams = Class:new(Condition_Base)
function Condition_UpgradeParams:__new(activityItem, config)
    Condition_Base.__new(self, activityItem, "upgradeparams", config)
    self.m_Params = {}
end
function Condition_UpgradeParams:IsNeedSort()
    return true
end
function Condition_UpgradeParams:SetMsgParams(params)
    for i, text in pairs(params.data) do
        self.m_Params[i] = text
    end
end
-- function Condition_UpgradeParams:GetConditionText()
--     return self.m_Config.description1
-- end
function Condition_UpgradeParams:GetConditionText2()
    local msgContent = self.m_Params[1]
    if msgContent == nil or msgContent == "" then
        msgContent = LocalString.Activity_Rank_Empty
    end
    return msgContent 
end

function Condition_UpgradeParams:NeedMsgParams()
    return true
end



--==========================================================================
local ConditionClasses = {
    [cfg.operationalactivity.ConditionType.Upgrade]         = Condition_Upgrade,
    [cfg.operationalactivity.ConditionType.Collection]      = Condition_Collection,
    [cfg.operationalactivity.ConditionType.Charge]          = Condition_Charge,
    [cfg.operationalactivity.ConditionType.GiftBag]         = Condition_GiftBag,
    [cfg.operationalactivity.ConditionType.UpgradeParams]   = Condition_UpgradeParams,
}





local function CreateCondition(activityItem, config)
    local conditionClass = ConditionClasses[config.conditiontype]
    return conditionClass:new(activityItem,config)
end


return {
    CreateCondition = CreateCondition,
}