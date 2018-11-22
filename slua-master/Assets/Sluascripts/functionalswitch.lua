local switchState = false

local function GetSwitchState()
	return switchState
end

local function SetSwitchState(state)
	switchState = state
end


return {
	GetSwitchState   = GetSwitchState,
    SetSwitchState   = SetSwitchState,
}