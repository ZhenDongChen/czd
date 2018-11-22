
local SoundInstanceData = Class:new()

local Version = 1
SoundInstanceData.Type = nil	--音效类型(0:common,1:cry,2:weapon)
SoundInstanceData.Id = nil	--类型ID(ref Type:common时无效，cry时为monster表或proffesion表的配置，weapon时为武器的id)
SoundInstanceData.StartDelay = nil	--延迟播放时间
SoundInstanceData.Sound = nil	--音效资源路径
SoundInstanceData.MinVlm = nil	--最小音量
SoundInstanceData.MaxVlm = nil	--最大音量
SoundInstanceData.MinPitch = nil	--最低音高
SoundInstanceData.MaxPitch = nil	--最高音高
SoundInstanceData.IsRandom = nil	--是否随机
SoundInstanceData.CanRepeat = nil	--是否可重复
SoundInstanceData.PlayProbability = nil	--播放几率
SoundInstanceData.IsLoop = nil	--是否循环
SoundInstanceData.LogicalPriority = nil	--音量总数控制(0-8)
SoundInstanceData.LogicalType = nil	--逻辑类型(1-9)


function SoundInstanceData:__new()
	self.Sound = {}
end

return SoundInstanceData
