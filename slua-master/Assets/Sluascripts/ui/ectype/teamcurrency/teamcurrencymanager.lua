local NetWork = require("network")
local PlayerRole = require("character.playerrole"):Instance()
local ConfigManager = require("cfg.configmanager")
local LimitManager = require("manager.limittimemanager")

local function GetEctypeByLevel()
    local ectypes = ConfigManager.getConfig("currencyactivityectype")
    local ectype = nil
    if ectypes then
        for _,ectypeItem in pairs(ectypes) do
            if (PlayerRole:GetLevel() >= ectypeItem.minlevel) and (PlayerRole:GetLevel() <= ectypeItem.maxlevel) then
                ectype = ectypeItem
                break
            end
        end
    end
    return ectype
end

local function UnRead()
    local result = false
    local ectype = GetEctypeByLevel()
    local freeTimes = ectype.dailytime.num
    local remainTimes = freeTimes - LimitManager.GetDayLimitTime(cfg.cmd.ConfigId.DAILY_ECTYPE,cfg.ectype.EctypeType.CURRENCY_ACTIVITY)
    if remainTimes > 0 then
        result = true
    end
    return result  
end

local function init()  
end

return
{
    init = init,
    GetEctypeByLevel = GetEctypeByLevel,
    UnRead = UnRead,
}