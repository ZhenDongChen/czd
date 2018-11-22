local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"
local EffectInstanceAlignType       = defineenum.EffectInstanceAlignType
local ESpecialType                  = defineenum.ESpecialType



local UIStandEffectInstance = Class:new(EffectInstance)

function UIStandEffectInstance:CheckCanShow()
    return self.ParentEffect.TargetTransform~=nil and not IsNullOrEmpty(self.EffectInstanceData.Path) 
end

function UIStandEffectInstance:GenBornPosition()
    local vecPos = Vector3.zero
    if self.ParentEffect and self.ParentEffect.TargetTransform then
        vecPos = self.ParentEffect.TargetTransform.position
    end
    return vecPos;
end

function UIStandEffectInstance:GetOffset()
    return self.EffectInstanceData.OffSet
end

function UIStandEffectInstance:OnInitObjDone()
    ExtendedGameObject.SetLayerRecursively(self.Object,Layer.LayerUI)
end

function UIStandEffectInstance:UpdateTransform()
    if self.ParentEffect.TargetTransform then
        self:SetPosition(self.ParentEffect.TargetTransform.position + self:GetOffset())
    end
end

return UIStandEffectInstance
