local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"


local FollowEffectInstance = Class:new(EffectInstance)

function FollowEffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect then
        if self.ParentEffect:Caster() then
            vecPos =self:GetBindPos(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType)
        end
    end
    return vecPos;
end

function FollowEffectInstance:GetOffset()
    local vecOffset = Vector3.zero
    vecOffset = self.Object.transform.rotation * self.EffectInstanceData.OffSet
    return vecOffset
end

function FollowEffectInstance:UpdateTransform()
    if self.ParentEffect and self.ParentEffect:Caster() then
        self:UpdateRotation() 
        self:SetPosition(self:GetBindPos(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType) + self:GetOffset())
        --printt(vecPos)
    end
end

return FollowEffectInstance
