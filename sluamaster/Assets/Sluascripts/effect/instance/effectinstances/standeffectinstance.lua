local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"
local EffectInstanceAlignType       = defineenum.EffectInstanceAlignType
local ESpecialType                  = defineenum.ESpecialType


local StandEffectInstance = Class:new(EffectInstance)

function StandEffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect.UseTargetPos then
        vecPos = self.ParentEffect.TargetPos
    else
        vecPos =self:GetBindPos(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType)
    end

    if self.EffectInstanceData.AlignType ~= EffectInstanceAlignType.None then
        vecPos = self:ModifyBornPosByAlignType()
    end
    return vecPos;
end

function StandEffectInstance:GetOffset()
    local vecOffset = Vector3.zero
	vecOffset = self.Object.transform.rotation * self.EffectInstanceData.OffSet
    return vecOffset
end

function StandEffectInstance:ModifyBornPosByAlignType()
    
    local rectArea = cameramanager.GetCurWorldArea() --wait for add
    local fPosZ = 0
    if self.ParentEffect and self.ParentEffect:Caster() then
        fPosZ = self.ParentEffect:Caster().Pos.z
    end
    local vecPos = Vector3(0,0,fPosZ)
    if self.EffectInstanceData.AlignType == EffectInstanceAlignType.LeftTop then
        vecPos = Vector3(rectArea.xMin,rectArea.yMax,fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.Left then
        vecPos = Vector3(rectArea.xMin,(rectArea.yMax + rectArea.yMin)*0.5,fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.LeftBottom then
        vecPos = Vector3(rectArea.xMin,  rectArea.yMin, fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.Top then
        vecPos = Vector3((rectArea.xMin + rectArea.xMax) * 0.5,rectArea.yMax,fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.Center then
        vecPos = Vector3((rectArea.xMin + rectArea.xMax) * 0.5,(rectArea.yMax + rectArea.yMin) * 0.5,fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.Bottom then
        vecPos = Vector3((rectArea.xMin + rectArea.xMax) * 0.5, rectArea.yMin, fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.RightTop then
        vecPos = Vector3(rectArea.xMax, rectArea.yMax, fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.Right then
        vecPos = Vector3(rectArea.xMax, (rectArea.yMax + rectArea.yMin) * 0.5, fPosZ)

    elseif self.EffectInstanceData.AlignType == EffectInstanceAlignType.RightBottom then
        vecPos = Vector3(rectArea.xMax, rectArea.yMin, fPosZ)

    end

    return vecPos
end

function StandEffectInstance:UpdateTransform()
    local vecPos = Vector3.zero

    if self.ParentEffect.SpecialType == ESpecialType.Ray then
        self:SetRotate(self.ParentEffect.AngleModify)
    end
end

return StandEffectInstance
