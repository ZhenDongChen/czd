local GameEvent = require("gameevent")
local ConfigManager = require("cfg.configmanager")

local SlowTime = nil


local function update()
    if SlowTime then
        UnityEngine.Time.timeScale = SlowTime.timeScale
        SlowTime.duration = SlowTime.duration - UnityEngine.Time.unscaledDeltaTime
        if SlowTime.duration < 0 then
            UnityEngine.Time.timeScale = 1
            SlowTime = nil
        end
    end
end

local function StartSlowTime(timeScaleIn,timeIn)
    --printyellow("===========",timeScaleIn,timeIn)
    SlowTime = {
        timeScale = timeScaleIn,
        duration = timeIn,
    }
end
local function StartSlowTimeById(id)
    local setting = ConfigManager.getConfigData("slowtime",id)
    if setting ~= nil then
    --printyellow("===========",timeScaleIn,timeIn)
        SlowTime = {
            timeScale = setting.rate,
            duration = setting.duration,
        }
    end
end

local function init()
    GameEvent.evt_update:add(update)
end


return {
    init = init,
    StartSlowTime = StartSlowTime,
    StartSlowTimeById = StartSlowTimeById,
}