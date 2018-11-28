local ActivityConditions = require("ui.operationactivity.base.conditions")
local BonusManager       = require("item.bonusmanager")
--==========================================================================
local ActivityItem = Class:new()

function ActivityItem:__new(group, config)
    self.m_Id = config.id
    self.m_Config = config
    self.m_ActivityGroup = group
    self.m_Condition = ActivityConditions.CreateCondition(self, self.m_Config.condition)
    self.m_Rewards = BonusManager.GetItemsByBonusConfig(self.m_Config.reward)
    -- self.m_Config.reward
    self.m_Status = cfg.operationalactivity.OperationStatus.NOT_COMPLETE
    self.m_IsOpen = false

    self.m_StartTime = -1
    self.m_EndTime = -1
end

function ActivityItem:GetId()
    return self.m_Id
end

function ActivityItem:GetStartTime()
    return self.m_StartTime
end

function ActivityItem:GetEndTime()
    return self.m_EndTime
end

function ActivityItem:SetServerMsg(msg)
    self.m_Status = msg.status
    self.m_StartTime = msg.opentime/1000
    self.m_EndTime = msg.closetime/1000
    if msg.isopen == 1 then
        self.m_IsOpen = true
    else
        self.m_IsOpen = false
    end
end

function ActivityItem:GetRewards()
    return self.m_Rewards
end

function ActivityItem:Change(msg)
    self.m_Status = msg.status
end

function ActivityItem:Receive()
    self.m_Status = cfg.operationalactivity.OperationStatus.GETREWARD
end


function ActivityItem:GetStatus()
    return self.m_Status
end

function ActivityItem:IsComplete()
    return (self.m_Status == cfg.operationalactivity.OperationStatus.COMPLETE)
end

function ActivityItem:IsFinish()
    return (self.m_Status == cfg.operationalactivity.OperationStatus.GETREWARD)
end

function ActivityItem:IsMatchCondition()
    if self.m_Condition.IsMatchCondition == nil then
        if self.m_Status == cfg.operationalactivity.OperationStatus.COMPLETE then
            return true
        else
            return false
        end
    else
        return self.m_Condition:IsMatchCondition()
    end
end

function ActivityItem:CanReceive()
    if self:IsFinish() and self:IsMatchCondition() then
        return true
    end
    return false
end

function ActivityItem:GetCondition()
    return self.m_Condition
end

function ActivityItem:GetShowGroup()
    return self.m_Condition:GetShowGroup()
end

function ActivityItem:GetItemName(num)
    local number = num or 1
    local item = self.m_Rewards[number]
    if item then
        return item:GetName()
    end
    return ""
end

function ActivityItem:GetItemDiscription(num)
    local number = num or 1
    local item = self.m_Rewards[number]
    if item then
        return item:GetIntroduction()
    end
    return ""
end

function ActivityItem:GetCurrencyType()
    return self.m_ActivityGroup:GetCurrencyType()
end

function ActivityItem:GetButtonName()
    
end

function ActivityItem:IsNeedSort()
    if self.m_Condition then
        return self.m_Condition:IsNeedSort()
    end
    return false
end

function ActivityItem:UnRead()
    if self.m_Condition.UnRead == nil then 
        if self:IsComplete() and (not self:IsFinish()) then
            return true
        end
        return  false
    end
    return self.m_Condition:UnRead()
end

function ActivityItem:IsShow()
    return self.m_IsOpen
end

function ActivityItem:SetMsgParams(value)
    self.m_Condition:SetMsgParams(value)
end

function ActivityItem:NeedMsgParams()
    if self.m_Condition and self.m_Condition.NeedMsgParams and self.m_Condition:NeedMsgParams() then
        return true
    end
    return false
end

return ActivityItem

