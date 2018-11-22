local network = require("network")
local uimanager = require("uimanager")

local m_IsReady = false

local function IsReady()
    return m_IsReady
end

local function GetReady(callback)
end

local function Release()
    m_IsReady = true
end

local function UnRead()
    for id,_ in pairs(ConfigManager.getConfig("familybonus")) do
        if checkcmd.Check({moduleid=cfg.cmd.ConfigId.FAMILY_LEVEL_BONUS, cmdid=id}) then
            return true
        end
    end
    return false
end

local m_GetLevelWelfareCallback
local function GetLevelWelfare(level, callback)
    m_GetLevelWelfareCallback = callback
    network.send(lx.gs.family.msg.CClaimFamilyBonus(){claimlevel=level})
end

local function init()
    network.add_listeners({
        -- {"lx.gs.family.msg.SGetFamilyWelfareInfo", function(msg)

        --      m_IsReady = true
        --      if m_Callback then
        --          m_Callback()
        --          m_Callback = nil
        --      end
        -- end},
        {"lx.gs.family.msg.SClaimFamilyBonus", function(msg)
             if m_GetLevelWelfareCallback then
                 m_GetLevelWelfareCallback(msg.claimlevel)
             end
        end},
    },"levelwelfaremanager")
end

return{
    init                = init,
    IsReady             = IsReady,
    GetReady            = GetReady,
    Release             = Release,
    GetLevelWelfare     = GetLevelWelfare,
    IsWelfareGot        = IsWelfareGot,
    UnRead              = UnRead,
}
