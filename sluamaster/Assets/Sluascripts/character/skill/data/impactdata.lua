--Generated at 2015/8/18 16:45:56
--This file is auto-generated,please do not modify it!


local ImpactData = Class:new()

local Version = 0
ImpactData.Time = nil	--生效时间
ImpactData.ImpactId = nil	--ImpactId(ref Impact表)


function ImpactData:__new()
end


function ImpactData:LoadConfig(file)
	local strLine = file:read()
	Version = tonumber(strLine)
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Time = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.ImpactId = tonumber(strLine)
	end
end
return ImpactData
