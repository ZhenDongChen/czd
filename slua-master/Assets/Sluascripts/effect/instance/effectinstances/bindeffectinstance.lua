local require                       = require
local EffectInstance                = require "effect.instance.effectinstance"
local defineenum                    = require "defineenum"
local mathutils                     = require "common.mathutils"
local cameramanager                 = require "cameramanager"
local define                        = require "define"
local EffectInstanceBindType        = defineenum.EffectInstanceBindType


local BindEffectInstance = Class:new(EffectInstance)


function BindEffectInstance:CheckCanShow()
    if self.ParentEffect.BindCharacter ==nil or IsNull(self.ParentEffect.BindCharacter.m_Object) then 
        return false
    end 
    return true
end


function BindEffectInstance:InitPosition()
    local offset = self.EffectInstanceData.OffSet
    local  bindtype = self.EffectInstanceData.CasterBindType
    local bonetrans = self:GetBindTransform(self.ParentEffect.BindCharacter,self.EffectInstanceData.CasterBindType)
	local vecOffset = Vector3.zero
    if bonetrans == nil then 
        if bindtype == EffectInstanceBindType.Body then
            vecOffset = Vector3(offset.x,offset.y,offset.z) + Vector3.forward* self.ParentEffect.BindCharacter.m_Height * cfg.skill.TraceObject.BODY_CORRECT
        elseif  bindtype == EffectInstanceBindType.Head then
			vecOffset = Vector3(offset.x,offset.y,offset.z) +  Vector3.forward* self.ParentEffect.BindCharacter.m_Height * cfg.skill.TraceObject.HEAD_CORRECT
		else
			vecOffset = Vector3(offset.x,offset.y,offset.z)  
        end 
    end
    
    self.Object.transform.localPosition = vecOffset
end

function BindEffectInstance:InitScale()
    self.Object.transform.localScale = Vector3.one 
    EffectInstance.InitScale(self)
end

function BindEffectInstance:InitRotation()
    self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
end

function BindEffectInstance:InitObj()
    if not self:CheckCanShow() then
        self.Dead = true
        return
    end
    if self.Object then
        local bonetrans = self:GetBindTransform(self.ParentEffect.BindCharacter,self.EffectInstanceData.CasterBindType)
        --printyellow("self.ParentEffect.CasterId",self.ParentEffect.BindCharacter.m_Id)
        if bonetrans == nil then 
            bonetrans = self.ParentEffect.BindCharacter.m_Object.transform 
        end
        self.Object.transform:SetParent(bonetrans.transform)
        EffectInstance.InitObj(self)
        ExtendedGameObject.SetLayerRecursively(self.Object, self.ParentEffect.BindCharacter.m_Object.layer)
    end
    
end

function BindEffectInstance:Update()
    if not self.Loaded and not self.Dead then 
        if not self:CheckCanShow() then
            self.Dead = true
            return
        end
        self.Loaded = true
        Util.Load(self.EffectInstanceData.Path, define.ResourceLoadType.LoadBundleFromFile,function(asset_obj)
            if not IsNull(asset_obj) then 
                if not self.Dead then
                    self.Object = Util.Instantiate(asset_obj,self.EffectInstanceData.Path)
                    self:InitObj()
                else 
                    printyellow("===================== InitObj self.Dead ")
                end
                
            else 
                self.Dead = true
            end
        end)
    end
end 


function BindEffectInstance:Destroy()
    self.Dead = true
    self.StartTime = 0
    self.Loaded = false
    if self.Object then
        GameObject.Destroy(self.Object)
    end
    self.Object = nil
end



return BindEffectInstance
