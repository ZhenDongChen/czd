local ConfigManager 	  = require "cfg.configmanager"
local UIManager 		= require("uimanager")
local gameevent         = require "gameevent"
local WelfareManager = require("ui.welfare.welfaremanager")

local m_SpringFestivalCfgs
local m_CurrentActivityCfg
local m_CurrentDayBonusInfo
local m_CurrentDailyBonus

local m_CurrentActivityID = 0
local m_CurrentLoginDay = 0
local m_NextBonusIndex = 0

local Update_Interval = 5
local m_LastUpdateTime = 0

local function GetCurrentActivityCfg()
    return m_CurrentActivityCfg
end

local function SetCurrentActivityID(activityid)
    printyellow("[springfestivalinfo:SetCurrentActivityID] activityid = ", activityid)
    m_CurrentActivityID = activityid

    for _, activitycfg in pairs(m_SpringFestivalCfgs) do
        printyellow("[springfestivalinfo:SetCurrentActivityID] activitycfg.id = ", activitycfg.id)
        if activitycfg.id==activityid then
            m_CurrentActivityCfg = activitycfg
            break
        end
    end
    m_CurrentDayBonusInfo = nil
    m_CurrentDailyBonus = nil
    printyellow("[springfestivalinfo:SetCurrentActivityID] m_CurrentActivityCfg = ")
    printt(m_CurrentActivityCfg)
end

local function GetCurrentActivityID()
    return m_CurrentActivityID
end

local function GetCurrentDayBonusInfo()
    --printyellow("[springfestivalinfo:GetCurrentDayBonusInfo] m_CurrentDayBonusInfo = ", m_CurrentLoginDay)
    return m_CurrentDayBonusInfo
end

local function SetLoginDay(day)
    printyellow("[springfestivalinfo:SetLoginDay] day = ", day)
    m_CurrentLoginDay = day
    if m_CurrentActivityCfg then
        m_CurrentDayBonusInfo = m_CurrentActivityCfg.daybonus[m_CurrentLoginDay]
    end
    m_CurrentDailyBonus = nil
end

local function GetLoginDay()
    return m_CurrentLoginDay
end

local function GetCurrentDailyBonus()
    --printyellow("[springfestivalinfo:GetCurrentDailyBonus] m_CurrentDailyBonus = ", m_CurrentLoginDay)
    return m_CurrentDailyBonus
end

local function SetNextBonusIndex(bonusindex)
    printyellow("[springfestivalinfo:SetNextBonusIndex] bonusindex = ", bonusindex)
    m_NextBonusIndex = bonusindex+1

    if m_CurrentDayBonusInfo then
        local count = #m_CurrentDayBonusInfo.dailybonus
        m_CurrentDailyBonus = (m_NextBonusIndex>count) and m_CurrentDayBonusInfo.dailybonus[count] or m_CurrentDayBonusInfo.dailybonus[m_NextBonusIndex]
    end
end

local function GetNextBonusIndex()
    return m_NextBonusIndex
end

local function GetLoginTime()
    return WelfareManager.GetDailyOnlineData() and WelfareManager.GetDailyOnlineData().DailyOnlineSeconds or 0
end

local function IsActivityOpen()
    return nil~=m_CurrentActivityCfg
    
    --test
    --return true
end

local function GetBG()
    printyellow("[springfestivalinfo:GetBG] ", m_CurrentActivityCfg and m_CurrentActivityCfg.background or nil)   
    return m_CurrentActivityCfg and m_CurrentActivityCfg.background or nil
end

local function GetTitle()
    --printyellow("[springfestivalinfo:GetDesc] ", m_CurrentActivityCfg and m_CurrentActivityCfg.background or nil)   
    return m_CurrentActivityCfg and m_CurrentActivityCfg.name or ""
end

local function GetDesc()
    --printyellow("[springfestivalinfo:GetDesc] ", m_CurrentActivityCfg and m_CurrentActivityCfg.background or nil)   
    return m_CurrentActivityCfg and m_CurrentActivityCfg.desc or ""
end

local function GetDetail()
    --printyellow("[springfestivalinfo:GetDetail] ", m_CurrentActivityCfg and m_CurrentActivityCfg.background or nil)   
    return m_CurrentActivityCfg and m_CurrentActivityCfg.logindaydecs or ""
end

local function IsDailyBonusFetched(DailyBonus)
    local result = false
    if DailyBonus and m_CurrentDayBonusInfo then
        for index,dailybonus in ipairs(m_CurrentDayBonusInfo.dailybonus) do
            if DailyBonus==dailybonus then
                result = (index<m_NextBonusIndex)
                break
            end
        end
    end
    return result
end

local function CanFetchDailyBonus()
    local result = false
    if m_CurrentDailyBonus then
        result = false==IsDailyBonusFetched(m_CurrentDailyBonus) and GetLoginTime()>=m_CurrentDailyBonus.time
    end
    return result
end

local function GetFetchCountdown()
    local countdown = 0
    if m_CurrentDailyBonus and false==IsDailyBonusFetched(m_CurrentDailyBonus) then
        countdown =  math.max(m_CurrentDailyBonus.time-GetLoginTime(), 0)
    end
    --printyellow("[springfestivalinfo:GetFetchCountdown] countdown=", countdown)
    return countdown
end

local function update()
    --printyellow("[springfestivalinfo:update] update!")
    --[[
    if nil==m_LastUpdateTime or (Time.time-m_LastUpdateTime)>Update_Interval then    
        m_LastUpdateTime = Time.time
    end
    --]]
end

local function reset()
    m_CurrentActivityCfg = nil
    m_CurrentDayBonusInfo = nil
    m_CurrentDailyBonus = nil

    m_CurrentActivityID = 0
    m_CurrentLoginDay = 0
    m_NextBonusIndex = 0

    m_LastUpdateTime = 0
end

local function OnLogout()
    reset()
end

--[[
<protocol name="SActivity">
	<variable name="id" type="int"/>
	<variable name="nextbonusid" type="int"/>��0��ʼ
	<variable name="dayindex" type="int"/>��1��ʼ
</protocol>
--]]
local function on_SActivity(msg)
    printyellow("[springfestivalinfo:on_SActivity] receive:", msg)
    SetCurrentActivityID(msg.id)
    SetLoginDay(msg.dayindex)
    SetNextBonusIndex(msg.nextbonusid)
end

--[[
<protocol name="SGetBonus">
	<variable name="activityid" type="int"/>
	<variable name="nextbonusid" type="int"/>
	<variable name="bonus" type="map.msg.Bonus"/>
</protocol>
--]]
local function on_SGetBonus(msg)
    --printyellow("[springfestivalinfo:on_SGetBonus] receive:", msg)
    SetNextBonusIndex(msg.nextbonusid)
end

--[[
<protocol name="SCloseActivity">
	<variable name="id" type="int"/>
</protocol>
--]]
local function on_SCloseActivity(msg)
   -- printyellow("[springfestivalinfo:on_SCloseActivity] receive:", msg)
    if msg.id==m_CurrentActivityID then
        reset()
    end
end

local function init()
    printyellow("[springfestivalinfo:init] init!")    
    reset()
    
    --get cfg
    m_SpringFestivalCfgs = ConfigManager.getConfig("onlinetimebonus2")
    if m_SpringFestivalCfgs == nil then
        printyellow("[ERROR][springfestivalinfo:init] m_SpringFestivalCfgs null!")
    else
        --printyellow("[springfestivalinfo:init] m_SpringFestivalCfgs:")
        --printt(m_SpringFestivalCfgs)
    end

    --others
	gameevent.evt_system_message:add("logout", OnLogout)
	gameevent.evt_update:add(update)
end

return
{
    init = init,
    GetCurrentActivityCfg = GetCurrentActivityCfg,
    GetCurrentActivityID = GetCurrentActivityID,
    GetCurrentDayBonusInfo = GetCurrentDayBonusInfo,
    GetLoginDay = GetLoginDay,
    GetNextBonusIndex = GetNextBonusIndex,
    GetCurrentDailyBonus = GetCurrentDailyBonus,
    IsActivityOpen = IsActivityOpen,
    GetBG = GetBG,
    GetDetail = GetDetail,
    GetDesc = GetDesc,
    GetTitle = GetTitle,
    GetLoginTime = GetLoginTime,
    IsDailyBonusFetched = IsDailyBonusFetched,
    CanFetchDailyBonus = CanFetchDailyBonus,
    GetFetchCountdown = GetFetchCountdown,

    on_SActivity = on_SActivity,
    on_SGetBonus = on_SGetBonus,
    on_SCloseActivity = on_SCloseActivity,
}

