local defineenum  = require "defineenum"
local PlayerRole
local CameraShakeType = defineenum.CameraShakeType
local CameraShakeData
local StartTime
local StartPos
local CenterPos
local CGControl = false
local StrenuousByTime = false



local function reset()
    CameraShakeData = nil
end

local function init()
    reset()
    PlayerRole = require "character.playerrole"
end

local function StartNewShake(data,pos)
    if data then
        StartTime = Time.time
        CameraShakeData = data
        StartPos = pos
        if math.ceil(CameraShakeData.Frequency) % 15 == 0 then
            CameraShakeData.Frequency = CameraShakeData.Frequency+3.0
        end
    end

    math.randomseed(os.time())

end

local function ShakeOver()
    return CameraShakeData == nil or Time.time - StartTime > CameraShakeData.Life
end

local function GetOffset()
    if CameraShakeData == nil or CameraShakeData.Type == CameraShakeType.NoShake then
        return Vector3.zero
    end



    local elapsedTime = Time.time - StartTime
    if elapsedTime > CameraShakeData.Life then
        reset()
        return Vector3.zero
    end

    if CameraShakeData.MaxRange < CameraShakeData.MinRange then
        CameraShakeData.MaxRange,CameraShakeData.MinRange = CameraShakeData.MinRange,CameraShakeData.MaxRange
    end

    if CameraShakeData.MaxRange <=0 then
        reset()
        return Vector3.zero
    end

    local roleToShakePosDistance = Vector3.Distance(PlayerRole:Instance().m_Pos,StartPos) * SCALE_XY_FRACTION
	
    if roleToShakePosDistance > CameraShakeData.MaxRange then
        return Vector3.zero
    end

    local correct =1
    if roleToShakePosDistance > CameraShakeData.MinRange and CameraShakeData.MaxRange > CameraShakeData.MinRange then
        correct = (CameraShakeData.MaxRange - roleToShakePosDistance) / (CameraShakeData.MaxRange - CameraShakeData.MinRange)
    end

    if CameraShakeData.MaxAmplitude < CameraShakeData.MinAmplitude then
        CameraShakeData.MaxAmplitude,CameraShakeData.MinAmplitude = CameraShakeData.MinAmplitude ,CameraShakeData.MaxAmplitude
    end

    local maxAmp = CameraShakeData.MaxAmplitude
    local minAmp = CameraShakeData.MinAmplitude

    if CameraShakeData.AmplitudeAttenuation > 0 then
        -- y = (1 / a) / (t + 1 / a) 即 y = 1 / x 简单变种
        local attenuationParam =1 / CameraShakeData.AmplitudeAttenuation
        local attenuation = attenuationParam /( elapsedTime + attenuationParam)

        if CGControl and StrenuousByTime then
            attenuation = attenuationParam / ( 1.0 / elapsedTime + attenuationParam)
        end

        maxAmp = CameraShakeData.MaxAmplitude * attenuation
        minAmp = CameraShakeData.MinAmplitude * attenuation
    end

    local amp = math.random(minAmp,maxAmp)
    local frequency = CameraShakeData.Frequency
    if CameraShakeData.FrequencyKeepDuration > 0 and elapsedTime > CameraShakeData.FrequencyKeepDuration then
        if CameraShakeData.FrequencyAttenuation > 0 then
            local frequencyParam = 1 / CameraShakeData.FrequencyAttenuation
            frequency = CameraShakeData.Frequency * (frequencyParam / (elapsedTime + frequencyParam))
        end
    end

    local realAmp = amp * math.sin(2.0 * math.pi * frequency * elapsedTime) * correct
    local offset = Vector3.zero

    if CameraShakeData.Type == CameraShakeType.Horizontal then
        offset.x = (offset.x + realAmp) * SCALE_XY_FRACTION
    elseif CameraShakeData.Type == CameraShakeType.Vertical then
        offset.y = (offset.y + realAmp) * SCALE_XY_FRACTION
    elseif CameraShakeData.Type == CameraShakeType.Normal then
        offset.x = (offset.x + realAmp) * SCALE_XY_FRACTION
        offset.y = (offset.y + realAmp) * SCALE_XY_FRACTION
    end

    return offset

end

return
    {
        init = init,
        StartNewShake = StartNewShake,
        ShakeOver = ShakeOver,
        GetOffset = GetOffset,
    }




