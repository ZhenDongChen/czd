local NetWork=require("network")
local UIManager=require("uimanager")
local EctypeManager = require "ectype.ectypemanager"
local ConfigManager 	  = require "cfg.configmanager"
local gameevent         = require "gameevent"
local DlgActivityTip

local m_ActivityTipCfg

local m_ActivityTipList = {}
local m_ActivityTipIndex = -1
local m_ActivityTipTablee = {}

------------------------------------------------------------------------
--utils
------------------------------------------------------------------------
local function Clear()
    m_ActivityTipList = {}
    m_ActivityTipIndex = -1
    m_ActivityTipTable = {}
end

local function GetTipCount()
    if m_ActivityTipList then
        return table.getn(m_ActivityTipList)
    else
        return 0
    end
end

local function NeedShowActivityTip(isshowbyuimain)
    if (true==isshowbyuimain or UIManager.isshow("dlguimain")) and GetTipCount()>0 and false==EctypeManager.IsInEctype() then
        return true
    else
        --printyellow(string.format("[activitytipmanager:NeedShowActivityTip] return false! UIManager.isshow(dlguimain)=[%s], GetTipCount()=[%s], EctypeManager.IsInEctype()=[%s], isshowbyuimain=", UIManager.isshow("dlguimain"), GetTipCount(), EctypeManager.IsInEctype() ), isshowbyuimain)
        return false
    end
end

local function GetTipShowDuration()
    --test
    --return 10

    ---[[
    local showduration = 30
    if m_ActivityTipCfg then
        showduration = m_ActivityTipCfg.tipshowduration
    end
    return showduration
    --]]
end

local function IsActivityRegistered(type)
    local result = false
    if type and m_ActivityTipTable and m_ActivityTipTable[type]~=nil then
        result = true
    end
    return result
end

local function IsCountdownType(type)
    local result = false
    if type==cfg.dailyactivity.ActivityTipEnum.HongMengZhengBa_Countdown or type==cfg.dailyactivity.ActivityTipEnum.CITYWAR_PREPARE then
        result = true
    end
    return result
end

------------------------------------------------------------------------
--next
------------------------------------------------------------------------
local function GetNextIndex(currentindex)
    local newindex = -1
    if GetTipCount()>0 then
        newindex = currentindex+1
        newindex = math.max(1, newindex)
        if newindex>GetTipCount() then
            newindex = 1
        end
    end
    return newindex
end

local function GetTipByType(activitytype)
    local tipinfo
    if activitytype then
        tipinfo = m_ActivityTipTable[activitytype]
    end
    return tipinfo
end

local function GetTipByIndex(index)
    local tipinfo
    if GetTipCount()>0 then  
        if index<=0 then
            index= GetTipCount()
        end
        if index>GetTipCount() then
            index= 1
        end
        tipinfo = GetTipByType(m_ActivityTipList[index])
    end
    return tipinfo
end

local function GetNextTip()
    local nexttip
    if GetTipCount()>0 then    
        if 1==GetTipCount() then
            m_ActivityTipIndex = 1
            nexttip = GetTipByIndex(m_ActivityTipIndex)
        else
            local tmpindex = math.max(1, m_ActivityTipIndex)
            m_ActivityTipIndex = GetNextIndex(m_ActivityTipIndex)
            nexttip = GetTipByIndex(m_ActivityTipIndex)

            if nil==nexttip then        
                repeat
                    m_ActivityTipIndex = GetNextIndex(m_ActivityTipIndex)                    
                    nexttip = GetTipByIndex(m_ActivityTipIndex)
                until nexttip or m_ActivityTipIndex==tmpindex 
            end 
        end
    end

    --[[
    if nexttip then
        printyellow(string.format("[activitytipmanager:GetNextTip] get next tip [%s] by index [%s]!", nexttip.type, m_ActivityTipIndex))
    else
        printyellow("[activitytipmanager:GetNextTip] GetNextTip nil!")
    end
    --]]
    return nexttip
end

local function GetActivityCountdownString(activityname, time)
    if activityname then
        time = time and time or 0
        time = math.floor(time)
        --timeutils.TimeStr(msg.remaintime/1000)
        if LocalString.Activity_Tip_Countdown_Color then
			--printyellow("[activitytipmanager:GetActivityCountdownString] return:", activityname..LocalString.Activity_Tip_Countdown_Color..timeutils.getDateTimeString(time, "mm:ss"))
            return activityname..LocalString.Activity_Tip_Countdown_Color..timeutils.getDateTimeString(time, "mm:ss")
        else
            return activityname..timeutils.getDateTimeString(time, "mm:ss")   
        end
    end
end

------------------------------------------------------------------------
--register
------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--[[
--功能：注册活动tip
--入参：type           type:cfg.dailyactivity.ActivityTipEnum              活动类型，参看csv\dailyactivity\dailyactivity.xml
--      countdown          type:float           活动开启倒计时，单位是秒，如果不需要传nil
--      clickcallback  type:function        点击tip回调，各活动回调内容参看 Design\04_系统功能文档\02_主界面与操作\主界面优化-活动按钮.docx
--返回值：无
--]]
------------------------------------------------------------------------------------------------------------
local function RegisterActivity(type, countdown, clickcallback)
    if nil==type then
        print("[activitytipmanager:RegisterActivity] register failed! type nil!")
        return 
    end

    --test
    --[[
    if cfg.dailyactivity.ActivityTipEnum.CITYWAR~=type then
        return 
    end
    --]]
    
    local tip = m_ActivityTipCfg.activitytipmap[type]
    if nil==tip then
        --printyellow(string.format("[activitytipmanager:RegisterActivity] Register failed! tip nil for Activity type [%d]!", type))
        return 
    end

    --save data
    if nil==m_ActivityTipTable[type] then
        table.insert(m_ActivityTipList, type)    
    end
    local oldtipinfo = m_ActivityTipTable[type]
    if nil==oldtipinfo or oldtipinfo.type~=type or oldtipinfo.countdown~=countdown or oldtipinfo.clickcallback~=clickcallback or oldtipinfo.tip~=tip then 
        printyellow("[activitytipmanager:RegisterActivity] Register Activity tip:", type, countdown)
        local fulltip
        if IsCountdownType(type) then
            fulltip = GetActivityCountdownString(tip, countdown)
        end
        m_ActivityTipTable[type] = {type=type, countdown=countdown, clickcallback=clickcallback, tip=tip, fulltip=fulltip}

        --update ui
        if NeedShowActivityTip() then
            DlgActivityTip.OnActivityTipChange()
        end
    else
        printyellow(string.format("[activitytipmanager:RegisterActivity] same Activity tip [%d] already registered!", type)) 
    end
end

------------------------------------------------------------------------------------------------------------
--[[
--功能：取消注册活动tip
--入参：type           type:cfg.dailyactivity.ActivityTipEnum              活动类型，参看csv\dailyactivity\dailyactivity.xml
--返回值：无
--]]
------------------------------------------------------------------------------------------------------------
local function UnregisterActivity(type)
    if nil==type then
        return 
    end
    
    printyellow(string.format("[activitytipmanager:UnregisterActivity] Unregister Activity tip [%d]!", type))
    --remove data
    if GetTipCount()>0 then
        for i=1, GetTipCount() do
            if m_ActivityTipList[i]==type then
                table.remove(m_ActivityTipList, i)
                if i<=m_ActivityTipIndex then
                    m_ActivityTipIndex = m_ActivityTipIndex-1
                end               
                break
            end            
        end        
    end
    m_ActivityTipTable[type] = nil

    --update ui
    if 0==GetTipCount() and DlgActivityTip.IsVisible() then
        DlgActivityTip.hide()
    elseif NeedShowActivityTip() then
        DlgActivityTip.OnActivityTipChange()
    end
end

------------------------------------------------------------------------
--others
------------------------------------------------------------------------
local function update()
    for type, tipinfo in pairs(m_ActivityTipTable) do
        if type and tipinfo and IsCountdownType(type) and tipinfo.countdown and tipinfo.countdown>0 then
            tipinfo.countdown = tipinfo.countdown - Time.deltaTime
            if tipinfo.countdown<0 then
                UnregisterActivity(type)
            else
                tipinfo.fulltip = GetActivityCountdownString(tipinfo.tip, tipinfo.countdown)
            end
        end
    end
end

local function OnLogout()
    Clear()
end

local function init()
    --printyellow("[activitytipmanager:init] init activitytipmanager!")
    DlgActivityTip = require "ui.activity.dlguimain_activitytip"
    Clear()

    m_ActivityTipCfg  = ConfigManager.getConfig("activitytip")    
    --printt(m_ActivityTipCfg)

	gameevent.evt_system_message:add("logout", OnLogout)
	gameevent.evt_update:add(update)

    NetWork.add_listeners({
    })
end

return{
    init=init,

    NeedShowActivityTip = NeedShowActivityTip,
    GetNextTip = GetNextTip,
    GetTipByType = GetTipByType,
    GetTipShowDuration = GetTipShowDuration,
	IsCountdownType = IsCountdownType,

    RegisterActivity = RegisterActivity,
    UnregisterActivity = UnregisterActivity,
    IsActivityRegistered = IsActivityRegistered,
}
