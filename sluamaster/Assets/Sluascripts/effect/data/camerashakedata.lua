
local CameraShakeData = Class:new()

local Version = 0
CameraShakeData.Type = nil	--振动类型(0:NoShake,1:Normal,2:Horizontal,3:Vertical)
CameraShakeData.Life = nil	--生存时间
CameraShakeData.StartDelay = nil	--延迟播放时间
CameraShakeData.MaxRange = nil	--最大影响范围
CameraShakeData.MinRange = nil	--最小完整影响范围，在min和max范围之间受到影响递减
CameraShakeData.MaxAmplitude = nil	--最大振幅
CameraShakeData.MinAmplitude = nil	--最小振幅 真实振幅在min和max之间随机
CameraShakeData.AmplitudeAttenuation = nil	--振幅衰减 0无衰减 值越大衰减越快
CameraShakeData.Frequency = nil	--初始频率 次/秒
CameraShakeData.FrequencyKeepDuration = nil	--初始频率维持时间
CameraShakeData.FrequencyAttenuation = nil	--频率衰减 0无衰减


function CameraShakeData:__new()
end


return CameraShakeData
