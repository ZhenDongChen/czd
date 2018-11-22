local network = require("network")
local player = require("character.playerrole"):Instance()
local uimanager = require("uimanager")

local m_IsReady = false
local m_Callback

local m_EventMap

local FindType = enum
{
    "JinBi = 0",
    "YuanBao",
    "JinBiAll",
    "YuanBaoAll",
}

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
	print("GetReady")
    if not m_IsReady then
        m_Callback = callback
        network.send(lx.gs.dailyactivity.msg.CGetUndoActive())
    else
        callback()
    end
end

local function Release()
    m_IsReady = false
end

local function IsFristDay()
    local welfaremanager = require "ui.welfare.welfaremanager"
    if welfaremanager.GetLoginDays() == 1 then
        return true
    end
    return false
end

local function UnRead()
    if m_IsReady and not IsFristDay() then
        for _,data in pairs(m_EventMap) do
            if data.undotimes > 0 then
                return true
            end
        end
    end  
    return false
end

local function UndoEventIDs()
    local ids = {}
    for id,_ in pairs(m_EventMap) do
        if id ~= 0 then
            ids[#ids+1] = id
        end
    end
    return ids
end

local function UndoEvent(id)
    return m_EventMap[id] or {}
end

local m_ReclaimCallback
local function Reclaim(id, reclaimtype, callback)
    m_ReclaimCallback = callback
    network.send(lx.gs.dailyactivity.msg.CFindBack(){findtype=reclaimtype, eventtype=id})
end

local function init()
    network.add_listeners({
        {"lx.gs.dailyactivity.msg.SGetUndoActive", function(msg)
			printyellow("SGetUndoActive")
             m_EventMap = msg.undoactive.undoactive
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
        {"lx.gs.role.msg.SDayOver", function(msg)
			printyellow("SDayOver")
             Release()
        end},
        {"lx.gs.dailyactivity.msg.SFindBack", function(msg)
             if msg.findtype == lx.gs.dailyactivity.msg.Findbacktype.JINBI_FINDALL
             or msg.findtype == lx.gs.dailyactivity.msg.Findbacktype.YUANBAO_FINDALL then
                 m_EventMap = {}
             else
                 m_EventMap[msg.eventtype] = nil
             end
             if m_ReclaimCallback then
                 m_ReclaimCallback()
             end
        end},

        -- notify
    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    UndoEventIDs        = UndoEventIDs,
    UndoEvent           = UndoEvent,
    Reclaim             = Reclaim,
    UnRead              = UnRead,
    FindType            = FindType,
    IsFristDay          = IsFristDay,
}
