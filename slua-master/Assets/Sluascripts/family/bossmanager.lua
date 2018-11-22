local network = require("network")
local uimanager = require("uimanager")
local mgr = require("family.familymanager")

local m_IsReady = false
local m_Bosses = {}

local function IsReady()
    return mgr.IsReady()
end

local function GetReady(callback)
end

local function Release()
    m_IsReady = false
end

local m_PrayCallback
local function Pray(praytype, callback)
    m_PrayCallback = callback
    network.send(lx.gs.family.msg.CFamilyPray(){burntype=praytype})
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyActivityInfo", function(msg)
             m_Bosses = msg.activity.godanimalinfo
             if m_Callback then
                 m_Callback()
             end
        end},

        --notify
        {"lx.gs.limit.msg.SLimitChange", function(msg)
             for _,limit in pairs(msg.changelimits) do
                 local cmdid = limit.id % 2^32
                 local configid = (limit.id - cmdid)/2^32
                 if configid == cfg.cmd.ConfigId.FAMILY_PRAY then
                     uimanager.refresh("family.tabpray", {refreshlimit=true, id=cmdid, count=limit.typenums[cfg.cmd.condition.LimitType.DAY] or 0})
                 end
             end
             for _,id in pairs(msg.removelimits) do
                 local cmdid = limit.id % 2^32
                 local configid = (limit.id - cmdid)/2^32
                 if configid == cfg.cmd.ConfigId.FAMILY_PRAY then
                     uimanager.refresh("family.tabpray", {refreshlimit=true, id=cmdid, count=0})
                 end
             end
        end},
    },"bossmanager")
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Pray                = Pray,
}
