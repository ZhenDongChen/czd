local network = require("network")
local uimanager = require("uimanager")
local LimitManager=require("limittimemanager")

local modset = {"family.praymanager",
               "family.partymanager",
                "ui.family.boss.familybossmanager",
                "family.warmanager",
}

local m_IsReady = false

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
    m_Callback = callback
    network.send(lx.gs.family.msg.CGetFamilyActivityInfo())
end

local function Release()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.Release then
            mod.Release()
        end
    end
    m_IsReady = false
end

local function OpenFamilyTeamEctype(callback)
    network.send(lx.gs.map.msg.COpenFamilyTeamEctype())
end

local function HasFamilyEctypeTimes()
    local useTime = 0
    local limit = nil
    limit = LimitManager.GetLimitTime(cfg.cmd.ConfigId.FAMILY_TEAM_ECTYPE,0)
    if limit then
        useTime=limit[cfg.cmd.condition.LimitType.DAY]
    end
    local familyteamConfig = ConfigManager.getConfig("familyteam")
    local enterTime = familyteamConfig.rewardfinishnum.num
    local remainTime=enterTime-useTime
    if remainTime > 0 then
        return true
    else
        return false
    end  
end

local function UnRead()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.UnRead and mod.UnRead() then
            return true
        end
    end

    if HasFamilyEctypeTimes() then
        return true
    end

    --[[local familymgr = require("family.familymanager")
    if familymgr.IsInBlackMarketTime() then
        return true
    end]]
    return false
end

local function init()
    for _,mod in ipairs(modset) do
        local mod = require(mod)
        if mod and mod.init then
            mod.init()
        end
    end

    network.add_listeners({
        {"lx.gs.family.msg.SGetFamilyActivityInfo", function(msg)
             m_IsReady = true
             if m_Callback then
                 m_Callback()
                 m_Callback = nil
             end
        end},
    },"activitymanager")
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    UnRead              = UnRead,
    OpenFamilyTeamEctype= OpenFamilyTeamEctype,
    HasFamilyEctypeTimes= HasFamilyEctypeTimes,
}
