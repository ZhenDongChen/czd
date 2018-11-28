local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"


local TraceEffectInstance = Class:new(EffectInstance)

function TraceEffectInstance:CheckCanShow()
    if self.ParentEffect:Caster() ==nil or IsNull(self.ParentEffect:Caster().m_Object) or
       self.ParentEffect:Target() ==nil or IsNull(self.ParentEffect:Target().m_Object) or
       IsNullOrEmpty(self.EffectInstanceData.Path) then 
        return false
    end 
    return true
end

function TraceEffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect.UseTargetPos then
        vecPos = self.ParentEffect.TargetPos
    else 
        vecPos =self:GetBindPos(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType)
    end
    return vecPos;
end

function TraceEffectInstance:GetOffset()
    local vecOffset = Vector3.zero
    vecOffset = self.Object.transform.rotation * self.EffectInstanceData.OffSet
    return vecOffset
end

function TraceEffectInstance:UpdateTransform()
    if self.ParentEffect and self.ParentEffect:Target() then
        if self.EffectInstanceData.InstanceTraceType == TraceType.Line then
            vecPos = self:GetBindPos(self.ParentEffect:Target(),self.EffectInstanceData.TargetBindType) + self:GetOffset()
            if self.EffectInstanceData.TraceTime >0 then
                local dir = vecPos - self.BornPos
                local elapse = Time.time - self.BornTime
                self:SetPosition(self.BornPos + dir * mathutils.TernaryOperation(elapse >= self.EffectInstanceData.TraceTime,1,elapse / self.EffectInstanceData.TraceTime) )
            else
                self:Posotion(vecPos)
            end
        elseif self.EffectInstanceData.InstanceTraceType == TraceType.Bezier then
        --Bezier
        end
    end
end

return TraceEffectInstance
