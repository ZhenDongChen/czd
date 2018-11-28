local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"


local TracePosEffectInstance = Class:new(EffectInstance)

function TracePosEffectInstance:CheckCanShow()
    if self.ParentEffect:Caster() ==nil or 
        IsNull(self.ParentEffect:Caster().m_Object) or 
        self.ParentEffect.TracePosObj == nil or
        IsNullOrEmpty(self.EffectInstanceData.Path) then 
        return false
    end 
    return true
end

function TracePosEffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect and self.ParentEffect:Caster() and self.ParentEffect.TracePosObj then
        vecPos =self:GetBindPos(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType)
    end
    return vecPos;
end

function TracePosEffectInstance:GetOffset()
    local vecOffset = Vector3.zero
    vecOffset = self.Object.transform.rotation * self.EffectInstanceData.OffSet
    return vecOffset
end

function TracePosEffectInstance:OnInitObjDone()
    if  self.Visible and self.ParentEffect and self.ParentEffect:Caster() then
        if self.ParentEffect.TracePosObj and self.ParentEffect.TracePosObj:IsAttacking() and not self.ParentEffect.TracePosObj:IsFixed() then
            self.ParentEffect.TracePosObj:StartFly(self.Object)
        end
    end
end


function TracePosEffectInstance:UpdateTransform()
    ---[[
    if self.ParentEffect and self.ParentEffect.TracePosObj then
      if  self.ParentEffect.TracePosObj:IsDead() then
        self.Dead = true
        self:Destroy()
        return
      end
      self:SetPosition(self.ParentEffect.TracePosObj.m_Pos)
    end
    --]]
end

return TracePosEffectInstance
