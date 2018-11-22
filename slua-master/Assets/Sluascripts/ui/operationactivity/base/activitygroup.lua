local AcitityItem = require("ui.operationactivity.base.activityitem")
local ItemManager = require("item.itemmanager")

local ActivityGroup = Class:new()

function ActivityGroup:__new(config)
    self.m_Id = config.type
    self.m_Config = config

    self.m_IsOpen = false
    self.m_StartTime = self.m_Config.timerange.begintime
    self.m_EndTime = self.m_Config.timerange.endtime

    self.m_ActivityItems = {}
    for i, value in pairs(self.m_Config.activityinfo) do
        table.insert( self.m_ActivityItems, AcitityItem:new(self, value) )
    end
    
    self.m_UnRead = false
end

function ActivityGroup:GetId()
    return self.m_Id
end



function ActivityGroup:IsNeedSort()
    if #self.m_ActivityItems >= 1 then
        local activityItem = self.m_ActivityItems[1]
        return activityItem:IsNeedSort()
    end
    return false
end

function ActivityGroup:Sort(list)
    table.sort( list, function(itemA, itemB) 
        if itemA:CanReceive() == true and itemB:CanReceive() == false then
            return true
        end
        if itemA:CanReceive() == false and itemB:CanReceive() == true then
            return false
        end
        if itemA:IsComplete() == false and itemB:IsComplete() == true then
            return true
        end
        if itemA:IsComplete() == true and itemB:IsComplete() == false then
            return false
        end
        return false
    end)
end



function ActivityGroup:UnRead()
    if self.m_Config.showreddot == true then
        local result = false
        for i, activityItem in pairs(self.m_ActivityItems) do
            if activityItem:IsShow() == true and activityItem:UnRead() == true then
                result = true
            end
        end
        return result
    else
        return false
    end
end

function ActivityGroup:IsShow()
    if #self.m_ActivityItems >= 1 then
        local activityItem = self.m_ActivityItems[1]
        return activityItem:IsShow()
    end
    return false
end


function ActivityGroup:AllComplete()
    return false
end

function ActivityGroup:GetCurrencyType()
    return self.m_Config.currencytype
end

function ActivityGroup:GetActivityItems()
    return self.m_ActivityItems
end
function ActivityGroup:GetActivityItem(cmdid)
    for i, activityItem in pairs(self.m_ActivityItems) do
        if activityItem:GetId() == cmdid then
            return activityItem
        end
    end
    return nil
end

function ActivityGroup:GetTitle()
    return self.m_Config.title
end

function ActivityGroup:GetFinishedLabel()
    return self.m_Config.finishedlabel
end

function ActivityGroup:GetUnFinishLabel()
    return self.m_Config.unfinishlabel
end

function ActivityGroup:GetCurrencyName()
    return self.m_Config.currencyname
end

function ActivityGroup:GetCurrencyCount()
    return PlayerRole:Instance():GetCurrency(self.m_Config.currencytype)
end

function ActivityGroup:GetTexture()
    return self.m_Config.texture
end

function ActivityGroup:GetContent()
    return self.m_Config.content
end

function ActivityGroup:GetTimeRange()
  --  self.m_Config.timerange.begintime
  --  self.m_Config.timerange.endtime
    --[[
        	<field name="hour" type="int"/>
		<field name="minute" type="int"/>
		<field name="second" type="int"/>
    ]]
    
end

function ActivityGroup:GetStartTimeStr()
    if self.m_ActivityItems[1] and self.m_ActivityItems[1]:GetStartTime() > 0 then
        local startTime = self.m_ActivityItems[1]:GetStartTime()
        local startData = os.date("*t", startTime)

        return string.format(   "%04d-%02d-%02d %02d:%02d:%02d", 
                                startData.year,
                                startData.month,
                                startData.day,
                                startData.hour,
                                startData.min,
                                startData.sec)
    end
    return string.format(   "%04d-%02d-%02d %02d:%02d:%02d", 
                            self.m_StartTime.year, 
                            self.m_StartTime.month, 
                            self.m_StartTime.day, 
                            self.m_StartTime.hour, 
                            self.m_StartTime.minute, 
                            self.m_StartTime.second)
end

function ActivityGroup:GetEndTimeStr()
    if self.m_ActivityItems[1] and self.m_ActivityItems[1]:GetEndTime() > 0 then
        local endTime = self.m_ActivityItems[1]:GetEndTime()
        local endData = os.date("*t", endTime)

        return string.format(   "%04d-%02d-%02d %02d:%02d:%02d", 
                                endData.year,
                                endData.month,
                                endData.day,
                                endData.hour,
                                endData.min,
                                endData.sec)
    end
    return string.format(   "%04d-%02d-%02d %02d:%02d:%02d", 
                            self.m_EndTime.year, 
                            self.m_EndTime.month, 
                            self.m_EndTime.day, 
                            self.m_EndTime.hour, 
                            self.m_EndTime.minute, 
                            self.m_EndTime.second)
end

function ActivityGroup:IsShowTime()
    if self.m_ActivityItems[1] and self.m_ActivityItems[1]:GetEndTime() > 0 then
        local endTime = self.m_ActivityItems[1]:GetEndTime()
        local endData = os.date("*t", endTime)
        if endData and endData.year then
            if tonumber(endData.year) >= 2100 then
                return false
            end
        end
    end
    return true
end

function ActivityGroup:GetDisplayOrder()
    return self.m_Config.displayorder or 0
    
end

function ActivityGroup:NeedMsgParams()
    if self.m_ActivityItems[1] and self.m_ActivityItems[1]:NeedMsgParams() then
        return true
    end
    return false
end

function ActivityGroup:SetMsgParams(msgParams)
    for k, value in pairs(msgParams) do
        local activityItem = self:GetActivityItem(k)
        if activityItem then
            activityItem:SetMsgParams(value)
        end
    end
end


return ActivityGroup