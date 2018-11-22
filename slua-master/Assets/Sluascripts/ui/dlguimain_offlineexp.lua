local unpack            = unpack
local print             = print
local format            = string.format
local math              = math
local EventHelper       = UIEventListenerHelper
local gameevent         = require"gameevent"
local network           = require"network"
local defineenum        = require"defineenum"
local format            = string.format
local math              = math

local uimanager         = require"uimanager"
local charactermanager  = require"character.charactermanager"
local PrologueManager   = require"prologue.prologuemanager"


local name
local gameObject
local fields


local isGetOfflineExp = false

local function ShowGetOfflineExpUI()
    local PlayerRole = require "character.playerrole"
    local configmanager = require "cfg.configmanager"
    local roleconfig = configmanager.getConfig("roleconfig")
    local maxHour = roleconfig.offlinemaxtime/60
    local offlineTime = PlayerRole:Instance().m_OfflineTime
    local offlineExp = PlayerRole:Instance().m_OfflineExp
    if not isGetOfflineExp and not PrologueManager.IsInPrologue() and offlineTime > 0 and offlineExp > 0 then
        isGetOfflineExp = true

        local timeDesc = string.format(LocalString.OFFLINE_TIME_EXCEED_ONEDAY,maxHour)
        if offlineTime < roleconfig.offlinemaxtime then
            local hour = offlineTime/60
            local minute = offlineTime%60
            timeDesc = string.format("%02d时%02d分", hour, minute)
        end
        
        local info = string.format(LocalString.OFFLINE_EXP_DESC,maxHour,timeDesc, offlineExp)
        uimanager.ShowSingleAlertDlg( {
            title = LocalString.OFFLINE_EXP_REWARD,
            content = info,
            buttonText = LocalString.Common_Receiving,
            fontSize = 20,
            callBackFunc = function()
                local re = lx.gs.role.msg.CGetOffLineExp()
                network.send(re)
            end,
            callBackHideFunc = function()
                local re = lx.gs.role.msg.CGetOffLineExp()
                network.send(re)
            end,
        } )

    end
end


local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    ShowGetOfflineExpUI()
end

local function hide()
    -- print(name, "hide")
end


local function update()
    -- print(name, "update")
end


local function refresh()
    -- print(name, "refresh")

end

local function OnLogout()
    isGetOfflineExp = false

    local PlayerRole = require "character.playerrole"
    PlayerRole:Instance().m_OfflineTime = 0
    PlayerRole:Instance().m_OfflineExp = 0
end

local function init(iName,iGameObject,iFields)
    name            = iName
    gameObject      = iGameObject
    fields          = iFields
  
    gameevent.evt_system_message:add("logout", OnLogout)
end



return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    ShowGetOfflineExpUI = ShowGetOfflineExpUI,
}
