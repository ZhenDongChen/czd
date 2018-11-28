--Generated at 2015/8/18 16:45:56
--This file is auto-generated,please do not modify it!

local CameraShakeData = require "effect.data.camerashakedata"
local EffectInstanceData = require "effect.data.effectinstancedata"
local SoundInstanceData = require "effect.data.soundinstancedata"
local DisplacementData = require "character.skill.data.displacementdata"
local HitPointData = require "character.skill.data.hitpointdata"
local ImpactData = require "character.skill.data.impactdata"
local DataSkill = Class:new()

local Version = 9
DataSkill.SkillID = nil	--技能ID
DataSkill.SkillName = nil	--技能名称
DataSkill.Level = nil	--技能等级
DataSkill.PrevPriority = nil	--起手优先级
DataSkill.MidPriority = nil	--攻击优先级
DataSkill.BackPriority = nil	--收手优先级
DataSkill.CDTime = nil	--冷却时间ms
DataSkill.PubCDID = nil	--技能公CDID
DataSkill.OnAirLimit = nil	--使用状态限制(滞空，0无限制，1滞空状态使用，2非滞空状态使用)
DataSkill.SkillType = nil	--技能类型（0立即，1飞行道具，2吟唱（预留）, 0持续引导，4 召唤炸弹类技能，5 射线类技能，6 Qte类技能）
DataSkill.CanNotMoveTime = nil	--技能释放过程中不能移动时间ms（Player放技能时不能移动的时间）
DataSkill.CanNotActionTime = nil	--禁止行动时间ms（技能完成后不能动作时间）
DataSkill.Action = nil	--技能动作
DataSkill.LoopAction = nil	--循环技能动作(qte、射线技能使用)
DataSkill.TargetEffect = nil	--被击者特效
DataSkill.IsNormal = nil	--是否普攻
DataSkill.NextSkillID = nil	--手动释放的下一个连续技
DataSkill.CallBackSkillID = nil	--自动释放的下一个连续技
DataSkill.ActionID = nil	--ActionID(ref bombaction或flyweaponaction表)
DataSkill.HideScene = nil	--隐藏场景
DataSkill.Impacts = nil	--技能受击效果列表
DataSkill.StartHitTime = nil	--攻击开始时间
DataSkill.EndHitTime = nil	--攻击结束时间
DataSkill.HitPoints = nil	--hitpoit列表
DataSkill.SkillEffects = nil	--技能特效列表
DataSkill.SkillCameraShakes = nil	--技能屏震列表
DataSkill.SkillSounds = nil	--技能音效列表
DataSkill.Displacements = nil	--水平位移列表
DataSkill.VDisplacements = nil	--竖直位移列表
DataSkill.HideMonster = nil	--隐藏怪物
DataSkill.ToTargetActionId = nil	--移动到目标对象位置ActionId(ref totargetaction表)
DataSkill.AttackImpacts = nil	--技能攻击效果列表
DataSkill.AttackAllOthers = nil	--攻击所有其他人


function DataSkill:__new()
	self.SkillName = ""
	self.Action = ""
	self.LoopAction = ""
	self.ActionID = ""
	self.Impacts = {}
	self.HitPoints = {}
	self.SkillEffects = {}
	self.SkillCameraShakes = {}
	self.SkillSounds = {}
	self.Displacements = {}
	self.VDisplacements = {}
	self.AttackImpacts = {}
end


function DataSkill:LoadConfig(file)
	local strLine = file:read()
	Version = tonumber(strLine)
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.SkillID = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.SkillName = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Level = tonumber(strLine)
	end
	if Version >= 2 and Version <= 99999 then
		strLine = file:read()
		self.PrevPriority = tonumber(strLine)
	end
	if Version >= 2 and Version <= 99999 then
		strLine = file:read()
		self.MidPriority = tonumber(strLine)
	end
	if Version >= 2 and Version <= 99999 then
		strLine = file:read()
		self.BackPriority = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.CDTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.PubCDID = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.OnAirLimit = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.SkillType = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.CanNotMoveTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.CanNotActionTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.Action = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.LoopAction = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.TargetEffect = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.IsNormal = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.NextSkillID = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.CallBackSkillID = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.ActionID = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.HideScene = strLine
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.Impacts = {}
		for i = 1,count do
			strLine =  file:read()
			self.Impacts[i] =tonumber{strLine}
		end
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.StartHitTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		self.EndHitTime = tonumber(strLine)
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.HitPoints = {}
		for i = 1,count do
			local newObj = HitPointData:new()
			newObj:LoadConfig(file)
			self.HitPoints[i] =newObj
		end
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.SkillEffects = {}
		for i = 1,count do
			local newObj = EffectInstanceData:new()
			newObj:LoadConfig(file)
			self.SkillEffects[i] =newObj
		end
	end
	if Version >= 0 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.SkillCameraShakes = {}
		for i = 1,count do
			local newObj = CameraShakeData:new()
			newObj:LoadConfig(file)
			self.SkillCameraShakes[i] =newObj
		end
	end
	if Version >= 1 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.SkillSounds = {}
		for i = 1,count do
			local newObj = SoundInstanceData:new()
			newObj:LoadConfig(file)
			self.SkillSounds[i] =newObj
		end
	end
	if Version >= 3 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.Displacements = {}
		for i = 1,count do
			local newObj = DisplacementData:new()
			newObj:LoadConfig(file)
			self.Displacements[i] =newObj
		end
	end
	if Version >= 8 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.VDisplacements = {}
		for i = 1,count do
			local newObj = DisplacementData:new()
			newObj:LoadConfig(file)
			self.VDisplacements[i] =newObj
		end
	end
	if Version >= 4 and Version <= 99999 then
		strLine = file:read()
		self.HideMonster = strLine
	end
	if Version >= 6 and Version <= 99999 then
		strLine = file:read()
		self.ToTargetActionId = tonumber(strLine)
	end
	if Version >= 7 and Version <= 99999 then
		strLine = file:read()
		local count = tonumber(strLine)
		self.AttackImpacts = {}
		for i = 1,count do
			local newObj = ImpactData:new()
			newObj:LoadConfig(file)
			self.AttackImpacts[i] =newObj
		end
	end
	if Version >= 9 and Version <= 99999 then
		strLine = file:read()
		self.AttackAllOthers = strLine
	end
end
return DataSkill
