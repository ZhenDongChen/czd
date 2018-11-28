local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local uimanager         = require("uimanager")
local network           = require("network")
local ActivityTipMgr           = require("ui.activity.activitytipmanager")
local timeutils          = require "common.timeutils"
local EventHelper = UIEventListenerHelper

local gameObject
local name
local fields

local ButtonState = enum{
    IDEL,
    TWEEN_SHOW,
    TWEEN_HIDE,
    SHOWING,
}

local m_IsVisible = false
local m_CurActivityTip = nil
local m_CurTipDuration = 0
local m_CurTipCountdown = nil
local m_NextActivityTip = nil
local m_ShowTweens
local m_HideTweens
local m_ButtonState = ButtonState.IDEL

local function SetTipLabel(tip)
    if fields and tip then
        --printyellow("[SetTipLabel:SetTipLabel] SetTipLabel:", tip)
        fields.UILabel_SystemMessage2.text = tip
    end
end

local function reset()
    m_CurActivityTip = nil
    m_CurTipDuration = 0
    m_CurTipCountdown = nil
    m_NextActivityTip = nil
    SetTipLabel("")
end

local function clear()
    m_ButtonState = ButtonState.IDEL
    reset()
end

local function IsVisible()
    return m_IsVisible
end

local function SetVisible(value)
    m_IsVisible = value
    if fields then
        fields.UIButton_NewActive.gameObject:SetActive(value)   
    end
end

local function GetIntCountdown(tipinfo)
    if tipinfo and tipinfo.countdown then
        return math.floor(tipinfo.countdown)
    else
        return 0
    end    
end

local function PlayShowTween()
    if m_ShowTweens then
        --printyellow(string.format("[dlguimain_activitytip:PlayShowTween] play ShowTween for tip[%d]!", m_CurActivityTip.type))
        m_ButtonState = ButtonState.TWEEN_SHOW
        m_ShowTweens:Play(true)
    end
end

local function PlayHideTween()
    if m_HideTweens then
        --printyellow(string.format("[dlguimain_activitytip:PlayHideTween] play HideTween for tip[%d]!", m_CurActivityTip.type))
        m_ButtonState = ButtonState.TWEEN_HIDE
        m_HideTweens:Play(true)
    end
end

local function hide()
    --printyellow("[dlguimain_activitytip:hide] hide dlguimain_activitytip!")
    clear()   
    SetVisible(false)
end

local function GetActivityCountdownString(activityname, time)
    if activityname then
        time = time and time or 0
        --timeutils.TimeStr(msg.remaintime/1000)
        return activityname..timeutils.getDateTimeString(time, "mm:ss")
    end
end

local function ShowActivityTip(activityTip)
    if nil == activityTip or activityTip==m_CurActivityTip then    
        if nil == activityTip then
            --printyellow("[dlguimain_activitytip:ShowActivityTip] show failed: nil == activityTip!")
        elseif activityTip==m_CurActivityTip then
            --printyellow("[dlguimain_activitytip:ShowActivityTip] skip show: activityTip==m_CurActivityTip!")
        end
    else    
        print(string.format("[dlguimain_activitytip:ShowActivityTip] Show Activity Tip [%d]!", activityTip.type))
        reset()
        m_CurActivityTip = activityTip
        if ActivityTipMgr.IsCountdownType(m_CurActivityTip.type) then
            if m_CurActivityTip.countdown then
                m_CurTipCountdown = GetIntCountdown(m_CurActivityTip)
            end
            --����ʱ
            SetTipLabel(GetActivityCountdownString(m_CurActivityTip.tip, m_CurTipCountdown) )  
        else
            --��ʾTIP
            SetTipLabel(m_CurActivityTip.tip)      
        end
        
        --tween
        PlayShowTween()
    end
end

local function ShowNextActivityTip()
    if nil==m_NextActivityTip then
        m_NextActivityTip = ActivityTipMgr.GetNextTip()
    end

    if m_NextActivityTip then
        --printyellow("[dlguimain_activitytip:ShowNextActivityTip] ShowNextActivityTip")
        ShowActivityTip(m_NextActivityTip)
    else
        hide()    
    end
end

local function PrepareShowNextActivityTip()
    --���Ŷ����ж�    
    m_NextActivityTip = ActivityTipMgr.GetNextTip()
    if m_CurActivityTip then
        --local tipinfo = ActivityTipMgr.GetNextTip()
        if m_NextActivityTip then
            if m_CurActivityTip~=m_NextActivityTip then
                --printyellow(string.format("[dlguimain_activitytip:PrepareShowNextActivityTip] prepare show Nexttip[%d], curtip=[%d]!", m_NextActivityTip.type, m_CurActivityTip.type))
                PlayHideTween()  
            else
                --printyellow(string.format("[dlguimain_activitytip:PrepareShowNextActivityTip] Nexttip[%d] == curtip[%d], keep showing!", m_NextActivityTip.type, m_CurActivityTip.type))
            end
        else   
            hide()    
        end
    else
        ShowNextActivityTip()
    end
end

local function show(params, isshowbyuimain)
    if false==ActivityTipMgr.NeedShowActivityTip(isshowbyuimain) then
        hide()
        return
    end
    
    --printyellow("[dlguimain_activitytip:show] show dlguimain_activitytip!")
    clear()
    SetVisible(true)

    PrepareShowNextActivityTip()
end

local function update()
    if true~=m_IsVisible then
        return
    end

    --update tip duration
    m_CurTipDuration = m_CurTipDuration+Time.deltaTime
    if m_CurTipDuration>=ActivityTipMgr.GetTipShowDuration() then
        --printyellow(string.format("[dlguimain_activitytip:update] m_CurTipDuration[%s]>=ActivityTipMgr.GetTipShowDuration()[%s], show next!", m_CurTipDuration, ActivityTipMgr.GetTipShowDuration() ))
        --printyellow(string.format("[dlguimain_activitytip:update] tip [%s] time up, show next!", m_CurActivityTip.type))
        m_CurTipDuration = 0
        PrepareShowNextActivityTip()
        return
    end    

    --update countdown
    if m_CurActivityTip then
        if ActivityTipMgr.IsCountdownType(m_CurActivityTip.type) then
            if m_CurActivityTip.fulltip~=fields.UILabel_SystemMessage2.text then
                SetTipLabel(m_CurActivityTip.fulltip)
            end
            --[[
             local countdown= GetIntCountdown(m_CurActivityTip)
             if countdown~=m_CurTipCountdown then
                m_CurTipCountdown = countdown
                --���µ���ʱ��ʾ
                SetTipLabel(GetActivityCountdownString(m_CurActivityTip.tip, m_CurTipCountdown) )
             end     
             --]]    
        end
    else
        PrepareShowNextActivityTip()
    end
end

local function refresh(params)
end

local function OnActivityTipChange()
    if false==ActivityTipMgr.NeedShowActivityTip() then
        --printyellow("[dlguimain_activitytip:OnActivityTipChange] no Need to Show ActivityTip!")
        if true== m_IsVisible then
            hide()
        end
    else
        if true~= m_IsVisible then
            show()
        else
            if nil==m_CurActivityTip then            
                PrepareShowNextActivityTip()
            else
                local tipinfo = ActivityTipMgr.GetTipByType(m_CurActivityTip.type)
                if tipinfo then
                    if m_CurActivityTip~=tipinfo then
                        --printyellow(string.format("[dlguimain_activitytip:OnActivityTipChange] tip [%s] changed!", m_CurActivityTip.type))
                        ShowActivityTip(tipinfo)
                    end
                else
                    --printyellow(string.format("[dlguimain_activitytip:OnActivityTipChange] tip [%s] deleted!", m_CurActivityTip.type))
                    PrepareShowNextActivityTip()
                end
            end
        end
    end
end

local function OnShowTweenFinished()
    --printyellow(string.format("[dlguimain_activitytip:OnShowTweenFinished] ShowTween finished for tip[%d]!", m_CurActivityTip.type))
    if true== m_IsVisible and m_ButtonState==ButtonState.TWEEN_SHOW then
        m_ButtonState = ButtonState.SHOWING
    end
end

local function OnHideTweenFinished()
    --printyellow(string.format("[dlguimain_activitytip:OnHideTweenFinished] HideTween finished for tip[%d]!", m_CurActivityTip.type))
    if true== m_IsVisible and m_ButtonState==ButtonState.TWEEN_HIDE then
        m_ButtonState = ButtonState.IDEL
        ShowNextActivityTip()
    end
end

local function OnActivityTipClicked()
    if m_CurActivityTip then
        if m_ButtonState==ButtonState.SHOWING then
            if m_CurActivityTip.clickcallback then
                --printyellow(string.format("[dlguimain_activitytip:OnActivityTipClicked] on tip [%d] clicked!", m_CurActivityTip.type))
                m_CurActivityTip.clickcallback()
            else
                print(string.format("[dlguimain_activitytip:OnActivityTipClicked] tip [%d] clickcallback nil!", m_CurActivityTip.type))
            end     
        else  
            print(string.format("[dlguimain_activitytip:OnActivityTipClicked] m_ButtonState[%d]~=ButtonState.SHOWING, skip callback!", m_ButtonState)) 
        end
    else
        print("[dlguimain_activitytip:OnActivityTipClicked] m_CurActivityTip nil!")
        PrepareShowNextActivityTip()
    end
end

local function destroy()
    --clear()
end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields

    clear()

    --tween init
	local uiplaytweens = fields.UIButton_NewActive.gameObject:GetComponents(UIPlayTweens)
    if uiplaytweens and uiplaytweens.Length>0 then
        m_ShowTweens = uiplaytweens[1]
        m_HideTweens = uiplaytweens[2]
    end
    if m_ShowTweens then
        --printyellow("[dlguimain_activitytip:init] set m_ShowTweens finish callback!")
        EventHelper.AddPlayTweensFinish(m_ShowTweens, OnShowTweenFinished)
    else
        --printyellow("[dlguimain_activitytip:init] m_ShowTweens nil!")
    end
    if m_HideTweens then
        --printyellow("[dlguimain_activitytip:init] set m_HideTweens finish callback!")
        EventHelper.AddPlayTweensFinish(m_HideTweens, OnHideTweenFinished)
    else
        --printyellow("[dlguimain_activitytip:init] m_HideTweens nil!")
    end

    --button
    EventHelper.SetClick(fields.UIButton_NewActive, OnActivityTipClicked)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    OnActivityTipChange = OnActivityTipChange, 
    IsVisible = IsVisible,
}
