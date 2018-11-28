local UIManager = require("uimanager")
local NetWork = require("network")
local DlgDialogBox_Revive = require("ui.common.dlgdialogbox_revive")

local m_AutoReviveTime   --自动复活倒计时
local m_OldReviveTime
local m_ReviveCostYuanBaoCount = 0  --当日使用元宝复活次数
local m_ReviveCostHuaShenCount = 0  --当日已使用化身符复活次数

local function RefreshUITime()
    if UIManager.isshow("common.dlgdialogbox_revive") then
        local DlgResurrection = require"ui.revive.dlgresurrection"
        DlgResurrection.RefreshReviveTime(m_AutoReviveTime)
    elseif UIManager.isshow("dlguimain") then
        UIManager.show("common.dlgdialogbox_revive",{type = DlgDialogBox_Revive.AllDlgType.Resurrection})
    end
end

local function SendCRevive(reviveType)
    local msg = map.msg.CRevive({revivetype = reviveType})
    NetWork.send(msg)
end

local function update()
    if m_AutoReviveTime then
        m_AutoReviveTime = m_AutoReviveTime - Time.deltaTime
        if m_AutoReviveTime <= 0 then
            m_AutoReviveTime = nil
            UIManager.hide("common.dlgdialogbox_revive")
            SendCRevive(cfg.map.ReviveType.REVIVE_POSITION)
            return
        else
            if m_OldReviveTime then
                if math.ceil(m_AutoReviveTime) ~= math.ceil(m_OldReviveTime) then
                    m_OldReviveTime = m_AutoReviveTime
                    RefreshUITime()
                end
            else
                m_OldReviveTime = m_AutoReviveTime
                RefreshUITime()
            end
        end
    end   
end

local function SetReviveState(state)
    if state==true then
        m_AutoReviveTime=cfg.role.Revive.AUTOREVIVETIME
        UIManager.show("common.dlgdialogbox_revive",{type = DlgDialogBox_Revive.AllDlgType.Resurrection})
    else
        m_AutoReviveTime = nil
        m_OldReviveTime = nil
    end
end

local function OnMsg_SReviveCostCount(msg)
    m_ReviveCostYuanBaoCount = msg.yuanbaocount    
    m_ReviveCostHuaShenCount = msg.huashencount
end

local function GetCostYuanBaoReviveCount()
    return m_ReviveCostYuanBaoCount
end

local function GetCostHuaShenReviveCount()
    return m_ReviveCostHuaShenCount
end

local function OnLogout()
    m_AutoReviveTime = nil
	m_OldReviveTime = nil
end

local function init()
    gameevent.evt_update:add(update)
    NetWork.add_listeners({
        {"lx.gs.map.msg.SReviveCostCount",OnMsg_SReviveCostCount}
    },"revivemanager")
	gameevent.evt_system_message:add("logout", OnLogout)
end

return{
    init = init,
    update = update,
    SetReviveState = SetReviveState,
    GetCostYuanBaoReviveCount = GetCostYuanBaoReviveCount,
    GetCostHuaShenReviveCount = GetCostHuaShenReviveCount,
    SendCRevive = SendCRevive,
}