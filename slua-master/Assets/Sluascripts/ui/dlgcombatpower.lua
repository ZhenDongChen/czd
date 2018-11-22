--local DlgCombatPower  = require "ui.dlgcombatpower"
local unpack         = unpack
local print          = print
local EventHelper    = UIEventListenerHelper
local uimanager      = require("uimanager")
local network        = require("network")
local gameObject
local name
local fields
local UIFadeIn_CombatPower = nil
local UIFadeOut_CombatPower = nil
local DlgName = "dlgcombatpower"

local combatpower_begin,combatpower_end,changepower = 0,0 ,0
local duration = 1.2
local m_elapsetime = 0
local m_currentcombatpower = 0

local ShowState = enum{
    "None",
    "FadeIn",
    "Changing",
    "FadeOut",
}

local CurrentState = ShowState.None

local function SetState(state)
    --printyellow("combatpower SetState " ,utils.getenumname(ShowState,state))
    CurrentState = state
end


local function reset() 
    m_elapsetime = 0
    m_currentcombatpower = 0
    UIFadeIn_CombatPower:Stop()
    UIFadeOut_CombatPower:Stop()
end 



local function startshow()
    reset()
    
    if changepower > 0 then
        fields.UILabel_AddPower.text = string.format("+%d",changepower)
    else
        fields.UILabel_ReducePower.text = changepower
    end
    m_currentcombatpower = combatpower_begin
    fields.UILabel_Power.text = m_currentcombatpower
    
    fields.UILabel_AddPower.gameObject:SetActive(changepower>0)
    fields.UILabel_ReducePower.gameObject:SetActive(changepower<0)

    UIEventListenerHelper.SetPlayTweenFinish(UIFadeIn_CombatPower, function(uifadein)
        --printyellow("PlayTweenFinish")
        SetState(ShowState.Changing)
    end)

    UIEventListenerHelper.SetPlayTweenFinish(UIFadeOut_CombatPower, function(uifadein)
        uimanager.hide(DlgName)
    end)

    SetState(ShowState.FadeIn)
    UIFadeIn_CombatPower:Play(true)
end 


local function showchange(icombatpowerbegin,icombatpowerend)
    --printyellow(DlgName,icombatpowerbegin,icombatpowerend)
    combatpower_begin,combatpower_end,changepower =icombatpowerbegin,icombatpowerend,icombatpowerend - icombatpowerbegin
    
    local isLock = uimanager.GetIsLock()
    if isLock == false then
        if uimanager.isshow(DlgName) then 
            startshow()
        else 
            uimanager.show(DlgName)
        end 
        
    end
end


local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    startshow()
end

local function hide()
    -- print(name, "hide")
end

local function refresh(params)
    -- print(name, "refresh")
end

local function update()
    -- print(name, "update")
    if CurrentState == ShowState.Changing then 
        local combatpower = math.ceil(combatpower_begin * (1 - m_elapsetime / duration) + combatpower_end * (m_elapsetime / duration))
        m_elapsetime = m_elapsetime +Time.deltaTime
        if m_elapsetime>duration then
            combatpower = combatpower_end
            SetState(ShowState.FadeOut)
            UIFadeOut_CombatPower:Play(true)
        end 
        if m_currentcombatpower ~= combatpower then 
            m_currentcombatpower = combatpower
            fields.UILabel_Power.text = m_currentcombatpower 
        end 
    end 
    
end



local function init(params)
    name, gameObject, fields = unpack(params)
      --print(name, "init")
    UIFadeIn_CombatPower = LuaHelper.GetComponent(fields.UIGroup_Power.gameObject,"UIFadeIn")
    UIFadeOut_CombatPower = LuaHelper.GetComponent(fields.UIGroup_Power.gameObject,"UIFadeOut")
end








return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    destroy         = destroy,
    refresh         = refresh,
    showchange      = showchange,
}
