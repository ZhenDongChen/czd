
local StateType = { Idle = 0, Follow = 1, Fight =2 , FightMove = 3}
local DefaultPos = Vector3(1.2,0.5,0)
local MaxMoveSpeedCoefficient = 1.5
local MinMoveSpeed = 1
local MaxMoveSpeed = 5
local LuaMode = false
local LuaUpdate = true

local FollowSetting = {
    EffectDistance = 8,
    BlinkDistance = 10,
    BlinkTargetDistance = 2.5,
    MaxSpeedDistance = 2,
    StopDistance = 0.1,
    DefaultAcceleration = 5,
    Mode = 0,
}

return {
    StateType = StateType,
    LuaMode = LuaMode,
    LuaUpdate = LuaUpdate,
    DefaultPos= DefaultPos,
    FollowSetting = FollowSetting,
    MaxMoveSpeedCoefficient = MaxMoveSpeedCoefficient,
    MinMoveSpeed = MinMoveSpeed,
    MaxMoveSpeed = MaxMoveSpeed,
}
