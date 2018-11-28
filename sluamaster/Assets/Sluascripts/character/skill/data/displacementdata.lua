--Generated at 2015/8/18 16:45:56
--This file is auto-generated,please do not modify it!


local DisplacementData = Class:new()

local Version = 0
DisplacementData.Time = nil	--开始移动时间
DisplacementData.Speed = nil	--移动速度m/s
DisplacementData.Duration = nil	--移动持续时间/ms


function DisplacementData:__new()
end


function DisplacementData:LoadConfig(file)
	local strLine = file:read()
	Version = tonumber(strLine)
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Time = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Speed = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Duration = tonumber(strLine)
	end
end
return DisplacementData
