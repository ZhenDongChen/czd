--Generated at 2015/8/18 16:45:56
--This file is auto-generated,please do not modify it!


local HitPointData = Class:new()

local Version = 4
HitPointData.HitTime = nil	--击中时间
HitPointData.CurveId = nil	--击飞曲线ID
HitPointData.TargetAction = nil	--目标被击动作
HitPointData.TargetActionFreezeTime = nil	--目标硬直时间/ms
HitPointData.AOEDistance = nil	--AOE判定区域位移
HitPointData.AOERangeX = nil	--AOE判定区域范围X
HitPointData.AOERangeZ = nil	--AOE判定区域范围Z
HitPointData.AOERangeYmin = nil	--攻击高度底部
HitPointData.AOERangeYmax = nil	--攻击高度顶部
HitPointData.EffectId = nil	--击中特效ID(Ref effectnew.xml)
HitPointData.ActionFreezeTime = nil	--技能动作顿帧时间/ms
HitPointData.HurtRatio = nil	--伤害比例


function HitPointData:__new()
	self.TargetAction = ""
end


function HitPointData:LoadConfig(file)
	local strLine = file:read()
	Version = tonumber(strLine)
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.HitTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.CurveId = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.TargetAction = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.TargetActionFreezeTime = tonumber(strLine)
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		self.AOEDistance = tonumber(strLine)
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		self.AOERangeX = tonumber(strLine)
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		self.AOERangeZ = tonumber(strLine)
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		self.AOERangeYmin = tonumber(strLine)
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		self.AOERangeYmax = tonumber(strLine)
	end
	if Version >= 2 and Version <= 99999 then
		strLine = file:read()
		self.EffectId = tonumber(strLine)
	end
	if Version >= 3 and Version <= 99999 then
		strLine = file:read()
		self.ActionFreezeTime = tonumber(strLine)
	end
	if Version >= 4 and Version <= 99999 then
		strLine = file:read()
		self.HurtRatio = tonumber(strLine)
	end
end
return HitPointData
