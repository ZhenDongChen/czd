local network = require("network")
local uimanager = require("uimanager")
local mgr = require("family.familymanager")
local limitmgr = require("limittimemanager")

local m_IsReady = false

local function IsReady()
    return m_IsReady
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

local function CanJinbiPray()
    local limitmgr = require("limittimemanager")
    local time = limitmgr.GetDayLimitTime(cfg.cmd.ConfigId.FAMILY_PRAY, 1)
    local listpray = ConfigManager.getConfig("pray")
    for id,data in pairs(listpray) do
        local limit = data.daylimit.entertimes[1]
        return limit > time
    end
    return false
end

local function UnRead()
    return CanJinbiPray()
end

local function init()
    network.add_listeners({
        {"lx.gs.family.msg.SFamilyPray", function(msg)
             local prayInfo = ConfigManager.getConfigData("pray", msg.burntype)
             if prayInfo then
                uimanager.ShowItemFlyText(string.format(LocalString.Family.FamilyPrayReward, 
                    prayInfo.familycapital.buildv, prayInfo.familycapital.money))
             end
             if m_PrayCallback then
                 m_PrayCallback()
             end
        end},

        --notify
        -- {"lx.gs.limit.msg.SLimitChange", function(msg)
        --      --printyellow("on msg slimitchange")
        --      for _,limit in pairs(msg.changelimits) do
        --          local cmdid = limit.id % 2^32
        --          local configid = (limit.id - cmdid)/2^32
        --          --printyellow("id=",limit.id, ",hex=", bit.tohex(limit.id, 64), ",configid =", configid, ",cmdid =", cmdid)
        --          if configid == cfg.cmd.ConfigId.FAMILY_PRAY then
        --              uimanager.refresh("family.tabpray", {refreshlimit=true, id=cmdid, count=limit.typenums[cfg.cmd.condition.LimitType.DAY] or 0})
        --          end
        --      end
        --      for _,id in pairs(msg.removelimits) do
        --          local cmdid = id % 2^32
        --          local configid = (id - cmdid)/2^32
        --          --printyellow("id=",id, ",hex=", bit.tohex(id, 64), ",configid =", configid, ",cmdid =", cmdid)
        --          if configid == cfg.cmd.ConfigId.FAMILY_PRAY then
        --              uimanager.refresh("family.tabpray", {refreshlimit=true, id=cmdid, count=0})
        --          end
        --      end
        -- end},
    })
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    Pray                = Pray,
    UnRead              = UnRead,
    CanJinbiPray        = CanJinbiPray,
}
