local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"
local EffectInstanceAlignType       = defineenum.EffectInstanceAlignType
local ESpecialType                  = defineenum.ESpecialType


local BindToCameraEffectInstance = Class:new(EffectInstance)

function BindToCameraEffectInstance:GenBornPosition()
    return cameraTransform.position;
end

function BindToCameraEffectInstance:GetOffset()
    return self.EffectInstanceData.OffSet
end

function BindToCameraEffectInstance:UpdateTransform()
    self:SetPosition(cameraTransform.position + self:GetOffset())
end

return BindToCameraEffectInstance
