local NetWork = require("network")
local UIManager = require("uimanager")
local GameEvent = require("gameevent")

local FamilyDeclareWarInfo = Class:new()

function FamilyDeclareWarInfo:__new(serverInfo)
    self.m_Id           = serverInfo.id
    self.m_FamilyName   = serverInfo.familyname
end


local FamilyDeclareWarData = {
    m_IsOpen = false,
    m_WarFamilys = {},
    m_FamilyDeclareMine = {},
}

local function RefreshUI()
    if UIManager.isshow("family.tabsearch") then
        UIManager.refresh("family.tabsearch")
    end
end

local function OnMsgFamilyDeclareWarInfo(msg)
    --printyellow(msg)
    if msg.isopen == 1 then
        FamilyDeclareWarData.m_IsOpen = true
    else
        FamilyDeclareWarData.m_IsOpen = false
    end
    local allFamilyName = ""
    FamilyDeclareWarData.m_WarFamilys = {}
    for i, family in pairs(msg.mydeclares) do
        FamilyDeclareWarData.m_WarFamilys[family.id] = FamilyDeclareWarInfo:new(family)
        if #allFamilyName > 0 then
            allFamilyName = allFamilyName .. LocalString.StopSeparator
        end
        allFamilyName = allFamilyName .. family.familyname
    end

    for i, family in pairs(msg.declaremes) do
        FamilyDeclareWarData.m_FamilyDeclareMine[family.id] = FamilyDeclareWarInfo:new(family)
    end

    if msg.isopen == 1 and #allFamilyName > 0 then
        UIManager.ShowSingleAlertDlg({
            content = string.format( LocalString.Family.FamilyDeclareWarTip, tostring(allFamilyName) )
        })
    end
    RefreshUI()
    GameEvent.evt_notify:trigger(defineenum.NotifyType.FamilyWarStateChange, {})
end

local function DeclareWar(familyId)
    --printyellow("===============================:DeclareWar",familyId)
    local re = lx.gs.family.msg.CDeclareWar({targetfamilyid = familyId, declare = 1 })
    NetWork.send(re)
end
local function CancelWar(familyId)
    local re = lx.gs.family.msg.CDeclareWar({targetfamilyid = familyId, declare = 0 })
    NetWork.send(re)
end

local function OnMsgDeclareWar(msg)
    --printyellow(msg)
    if msg.declare == 1 then
        local info = { id = msg.targetfamilyid, familyname = msg.targetfamilyname }
        FamilyDeclareWarData.m_WarFamilys[msg.targetfamilyid] = FamilyDeclareWarInfo:new(info)
        UIManager.ShowSingleAlertDlg({
            content = string.format( LocalString.Family.FamilyDeclareWarTip, tostring(msg.targetfamilyname) )
        })
    else
        FamilyDeclareWarData.m_WarFamilys[msg.targetfamilyid] = nil
    end
    RefreshUI()
   -- local familyName = PlayerRole:Instance().m_FamilyName

   GameEvent.evt_notify:trigger(defineenum.NotifyType.FamilyWarStateChange, {})
end

local function IsDeclaredWar(familyId)
    return FamilyDeclareWarData.m_WarFamilys[familyId] ~= nil
end

local function IsInWarState(familyId)
    return FamilyDeclareWarData.m_WarFamilys[familyId] ~= nil
end

local function GetWarFamilys()
    return FamilyDeclareWarData.m_WarFamilys
end

local function GetFamilyDeclareMine()
    return FamilyDeclareWarData.m_FamilyDeclareMine
end

local function GetIsOpen()
    return FamilyDeclareWarData.m_IsOpen
end

local function init()
    NetWork.add_listeners({
        { "lx.gs.family.msg.SFamilyDeclareWarInfo",     OnMsgFamilyDeclareWarInfo },
        { "lx.gs.family.msg.SGetFamilyDeclareWarList",  OnMsgGetFamilyDeclareWarList },
        { "lx.gs.family.msg.SDeclareWar",               OnMsgDeclareWar },
    },"declarewarmanager")
end

return {
    init = init,
    IsInWarState = IsInWarState,
    CanChangeWarState = CanChangeWarState,
    DeclareWar = DeclareWar,
    CancelWar = CancelWar,
    IsDeclaredWar = IsDeclaredWar,
    GetWarFamilys = GetWarFamilys,
    GetFamilyDeclareMine = GetFamilyDeclareMine,
    GetIsOpen = GetIsOpen,
}
