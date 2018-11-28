local require                 = require
local EffectPool              = EffectPool
local ExtendedGameObject      = ExtendedGameObject
local Instance                = require "effect.instance.instance"
local defineenum              = require "defineenum"
local mathutils               = require "common.mathutils"
local cameramanager           = require "cameramanager"
local charactermanager        = require "character.charactermanager"
local define                  = require "define"
local EffectInstanceType      = defineenum.EffectInstanceType
local EffectInstanceBindType  = defineenum.EffectInstanceBindType
local EffectInstanceAlignType = defineenum.EffectInstanceAlignType
local TraceType               = defineenum.TraceType
local ESpecialType            = defineenum.ESpecialType
local BoneNames               = defineenum.BoneNames

local ResourceLoadType = define.ResourceLoadType
local Layer  = define.Layer


local EffectInstance = Class:new(Instance)

EffectInstance.MainColorName = "_Color"
EffectInstance.TintColorName = "_TintColor"



function EffectInstance:__new()
    Instance.__new(self)
    --self:reset()
end

function EffectInstance:reset()
    Instance.reset(self)
    self.EffectInstanceData = nil
    self.m_EffectLoadTaskId =0
    self.BornPos            = Vector3.zero
    self.BornTime           =0
    self.Visible            = false
    self.Trails             = nil
    self.Renderers          = nil
	self.TrailsStartWidth = {};
	self.TrailsEndWidth = {};
	self.TrailsTime = {};
	self.TrailsInit = 0;
end


function EffectInstance:CheckCanShow()
    if self.ParentEffect:Caster() ==nil or 
       IsNull(self.ParentEffect:Caster().m_Object) or 
       IsNullOrEmpty(self.EffectInstanceData.Path) then 
        return false
    end 
    return true
end





function EffectInstance:SetScale(scale)
    if scale~=nil and scale>0 and self.Object ~=nil and self.Object.transform ~=nil then
        --printyellow("SetScale(scale)",self.Object.transform.localScale.x,scale)
		
	--	print("EffectInstance SetScale :"..tostring(self.EffectInstanceData.Path))
		
        self.Object.transform.localScale = self.Object.transform.localScale * scale
        if self.Trails then
            for i=1, self.Trails.Length do
                if self.Trails[i] then
					if self.Trails[i].startWidth==nil then
						logError("EffectInstance:SetScale error. Trails startWidth nil.i="..tostring(i)..",effectpath:"..self.EffectInstanceData.Path)
					else
						self.Trails[i].startWidth = self.Trails[i].startWidth * scale
						self.Trails[i].endWidth = self.Trails[i].endWidth * scale
					end
                end
            end
        end
        ExtendedGameObject.SetParticleSystemScale(self.Object,scale)
    end
end

function EffectInstance:SetPosition(vecPos)
    if self.Object and self.Object.transform  then
		if self.EffectInstanceData.TerrainEffect == true then
			self.Object.transform.position = Vector3(vecPos.x, vecPos.y, -1)
		else
			self.Object.transform.position = Vector3(vecPos.x, vecPos.y, vecPos.z)
		end
    end
end

function EffectInstance:SetRotate(angle)
    if self.Object then
        local vecAngle = self.BornAngle + angle
        vecAngle = mathutils.ClampAngles(vecAngle)
        self.Object.transform.localEulerAngles = vecAngle
    end
end

function EffectInstance:SetTransparent(transparent)
    if self.Object and self.Renderers and transparent >=0 and transparent <=1 then
        for i = 1 ,self.Renderers.Length do
            local r = self.Renderers[i]
            if r then
                for j = 1,r.materials.Length do
                    local m = r.materials[j]
                    if m:HasProperty(EffectInstance.MainColorName) then
                        local c = m:GetVector(EffectInstance.MainColorName)
                        c.w = c.w * transparent
                        m:SetVector(EffectInstance.MainColorName,c)
                    end

                    if m:HasProperty(EffectInstance.TintColorName) then
                        local c = m:GetVector(EffectInstance.TintColorName)
                        c.w = c.w * transparent
                        m:SetVector(EffectInstance.TintColorName,c)
                    end

                end
            end
        end
    end


end


function EffectInstance:SetVisible(bVisible)
    if self.Object == nil then
        return
    end

    if self.Object.audio then
        if bVisible then self.Object.audio.Play() else self.Object.audio.Stop() end
    end

    if self.Object.renderer then
        self.Object.rederer.enabled = bVisible
    end

    ExtendedGameObject.SetParticleSystemVisible(self.Object,bVisible)

end



function EffectInstance:GenBornPosition()
    --子类实现
    return Vector3.zero
end

function EffectInstance:GetOffset()
    --子类实现
    return Vector3.zero
end


function EffectInstance:InitPosition()
    local bornpos = self:GenBornPosition() or Vector3.zero
    local offset = self:GetOffset() or Vector3.zero
    self.BornPos = bornpos + offset
    self:SetPosition(self.BornPos)
end

function EffectInstance:InitScale()
    local scale =self.EffectInstanceData.Scale
    if scale~=nil then 
        if self.ParentEffect then
            scale = scale * self.ParentEffect.ScaleModify
        end
        if scale > 0 then
            self:SetScale(scale)
        end
    end
end


function EffectInstance:InitRotation()
    self:UpdateRotation()
end





function EffectInstance:InitObj()
    if self.Object then
        if not self:CheckCanShow() then
            self.Dead = true
            return
        end
        
		self.TrailsInit = 0;
		
        self.Trails = self.Object:GetComponentsInChildren(UnityEngine.TrailRenderer,true)
		
		self.TrailsStartWidth = {};
		self.TrailsEndWidth = {};
		self.TrailsTime = {};
		if self.Trails then
            for i=1, self.Trails.Length do
                if self.Trails[i] then
                    self.TrailsStartWidth[i] = self.Trails[i].startWidth
					self.TrailsEndWidth[i] = self.Trails[i].endWidth
					self.TrailsTime[i] = self.Trails[i].time;
					self.Trails[i].time = 0;
                end
            end
        end
		
        self:InitScale()
        self:InitRotation()
        self:InitPosition()

        self.Object:SetActive(false)
        printyellow("EffectInstance:InitObj()")
        --[[
        if self.ParentEffect:Caster() and charactermanager.FindLocalCharacter(self.ParentEffect:Caster().id) then -- wait for add
            ExtendedGameObject.SetToLayer(self.Object,Layer.LayerUICharacter)
        end
        --]]
        self.Visible  = true
        self.BornTime = Time.time
		
        self.Renderers = self.Object:GetComponentsInChildren(UnityEngine.Renderer,true)
        ExtendedGameObject.SetLayerRecursively(self.Object, define.Layer.LayerEffect)
        ExtendedGameObject.SetActiveRecursely(self.Object,true)
        self:OnInitObjDone()
    end
end

function EffectInstance:OnInitObjDone()
    --子类实现
end

function EffectInstance:GetBindTransform(character,bindtype) 
    
    if character == nil or IsNull(character.m_Object) or self.ParentEffect == nil then
        return nil
    end
    
    if self.EffectInstanceData.BoneName and  self.EffectInstanceData.BoneName~="" then
        local attachBone = character:GetAttachBone(self.EffectInstanceData.BoneName,false)  --wait for add
        --printyellow("attachBone",attachBone)
        if attachBone then return attachBone end

    elseif BoneNames[bindtype] then
        local bodyTrans = character:GetAttachBone(BoneNames[bindtype],false)
        if bodyTrans then return bodyTrans end
    end  
    
    return nil
end


function EffectInstance:GetBindPos(character,bindtype) 
    --Character,EffectInstanceBindType
    --printyellow("EffectInstance:GetBindPos(character,bindtype) " .. tostring(bindtype))
    local pos = Vector3.zero
    local found = false
    if character == nil or IsNull(character.m_Object) or self.ParentEffect == nil then
        return pos
    end
    
    
    pos = character.m_Object.transform.position

    local bonetrans = self:GetBindTransform(character,bindtype) 
    if bonetrans then
        pos = bonetrans.position
        found = true

    elseif bindtype == EffectInstanceBindType.Body then
        --[[
        local bodyTrans = character:GetAttachBone(BoneNames[EffectInstanceBindType.Body],false)
        if bodyTrans then
            pos= bodyTrans.position
            found = true
        end
        --]]
        pos = character.m_Object.transform.position
        found = true
    elseif  bindtype == EffectInstanceBindType.Foot then
        pos = character.m_Object.transform.position
        found = true
    elseif  bindtype == EffectInstanceBindType.Head then
        pos = character.m_Object.transform.position
		pos.y = pos.y + character.m_Height
        found = true
    end  
    if not found then
        pos =  character.m_Object.transform.position
    end
    --printyellow("============",bindtype,pos,character.Object.transform.position)
    --printyellow(found)
    --printt(pos)
    return pos
end


function EffectInstance:Load(data)
    if data == nil then
        return false
    end
    --self:reset()
    self.EffectInstanceData = data
    self.StartTime = Time.time
    return true
end

function EffectInstance:Destroy()
    self.Dead = true
    self.StartTime = 0
    self.Loaded = false
    if self.Object then
        local scale = self.EffectInstanceData.Scale
        if scale ~=nil then 
            if self.ParentEffect then
                scale =  self.ParentEffect.ScaleModify *scale
            end
            if scale > 0 then
                self:SetScale(1/scale)
            end
        end
		
		if self.Trails then
            for i=1, self.Trails.Length do
                if self.Trails[i] then
                    self.Trails[i].startWidth = self.TrailsStartWidth[i]
					self.Trails[i].endWidth = self.TrailsEndWidth[i]
                end
            end
        end
		
        self.Object:SetActive(false)
        self.Object.transform:SetParent(nil)
        EffectPool.PutEffect(self.EffectInstanceData.Path,self.Object)
    end
    self.Object = nil
end

function EffectInstance:UpdateRotation()
    if Local.LogModuals.EffectManager then 
        printyellow("EffectInstance:UpdateRotation()",Time.time,self.EffectInstanceData.FollowBoneDirection,self.EffectInstanceData.FollowDirection,self.ParentEffect:Caster())
    end
    --[[local bonetrans = self:GetBindTransform(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType) 
    if self.EffectInstanceData.FollowBoneDirection then 
		if bonetrans~=nil then
			local rotation = Quaternion.Euler(0, 180, bonetrans.localEulerAngles.z);
			self.Object.transform.rotation = rotation * self.EffectInstanceData.Rot
		else
			local rotation = Quaternion.Euler(0, 180, 0);
			self.Object.transform.rotation = rotation * self.EffectInstanceData.Rot
		end
        if Local.LogModuals.EffectManager then 
            printyellow("FollowBoneDirection")
            printt(bonetrans.rotation.eulerAngles)
            printt(self.EffectInstanceData.Rot.eulerAngles)
            printt(self.Object.transform.rotation.eulerAngles)
        end
    elseif self.EffectInstanceData.FollowDirection then
        if self.ParentEffect:Caster() and self.ParentEffect:Caster().m_Object then
			local rotation = Quaternion.Euler(0,180,self.ParentEffect:Caster().m_Object.transform.localEulerAngles.z);
            self.Object.transform.rotation = rotation * self.EffectInstanceData.Rot
            if Local.LogModuals.EffectManager then 
                printyellow("FollowDirection")
                printt(self.ParentEffect:Caster().m_Object.transform.rotation.eulerAngles)
                printt(self.EffectInstanceData.Rot.eulerAngles)
                printt(self.Object.transform.rotation.eulerAngles)
            end
        end
    else 
        if Local.LogModuals.EffectManager then
            printyellow("DefaultDirection")
        end
        self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
    end]]
	
	local bonetrans = self:GetBindTransform(self.ParentEffect:Caster(),self.EffectInstanceData.CasterBindType) 
    if self.EffectInstanceData.FollowBoneDirection and self.EffectInstanceData.CasterBindType == 0 then 
         self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
	elseif self.EffectInstanceData.FollowBoneDirection and bonetrans~=nil then 
        self.Object.transform.rotation = bonetrans.rotation * self.EffectInstanceData.Rot
        if Local.LogModuals.EffectManager then 
            printyellow("FollowBoneDirection")
            printt(bonetrans.rotation.eulerAngles)
            printt(self.EffectInstanceData.Rot.eulerAngles)
            printt(self.Object.transform.rotation.eulerAngles)
        end
    elseif self.EffectInstanceData.FollowDirection then
        if self.ParentEffect:Caster() and self.ParentEffect:Caster().m_Object then
            self.Object.transform.rotation = self.ParentEffect:Caster().m_Object.transform.rotation * self.EffectInstanceData.Rot
            if Local.LogModuals.EffectManager then 
                printyellow("FollowDirection")
                printt(self.ParentEffect:Caster().m_Object.transform.rotation.eulerAngles)
                printt(self.EffectInstanceData.Rot.eulerAngles)
                printt(self.Object.transform.rotation.eulerAngles)
            end
        end
    else 
        if Local.LogModuals.EffectManager then
            printyellow("DefaultDirection")
        end
        self.Object.transform.localEulerAngles = self.EffectInstanceData.EulerAngles
    end
end

function EffectInstance:UpdateTransform()
   --子类实现
end

function EffectInstance:GetEffectFromPool()
    if EffectPool.HasEffect(self.EffectInstanceData.Path) then 
        if not self.Dead then
            self.Object = EffectPool.GetEffect(self.EffectInstanceData.Path)
            self:InitObj()
        else 
            printyellow("===================== GetEffectFromPool self.Dead is true ")
        end 
        
    else 
        self.Dead = true
    end
end 


function EffectInstance:UpdateLoad()
    if   self.EffectInstanceData  and not self.Dead then
        --print("self.EffectInstanceData.StartDelay" .. self.EffectInstanceData.StartDelay)
        --print("self.StartTime" .. self.StartTime)
        --print("self.EffectInstanceData.StartDelay" .. self.EffectInstanceData.StartDelay)
        --print("self.ParentEffect.PauseTime" .. self.ParentEffect.PauseTime)
        
        if self.EffectInstanceData.StartDelay<=0 or Time.time - self.StartTime >= self.EffectInstanceData.StartDelay + self.ParentEffect.PauseTime then
            if not self:CheckCanShow() then
                self.Dead = true
                return
            end
            self.Loaded = true
            
            if EffectPool.HasEffectPoolItem(self.EffectInstanceData.Path) then 
                self:GetEffectFromPool()
            else 
                Util.Load(self.EffectInstanceData.Path, ResourceLoadType.LoadBundleFromFile,function (asset_obj)
                    if not IsNull(asset_obj) then 
						if not IsAndroid and not IsIos then print("load effect ! effectpath:"..self.EffectInstanceData.Path) end
						
                        EffectPool.AddEffectPoolItem(self.EffectInstanceData.Path,asset_obj)
                        self:GetEffectFromPool()
                    else 
                        logError("load effect failed! effectpath:",self.EffectInstanceData.Path)
                    end 
                end)
            end 


        end
    end
end 



function EffectInstance:Update()
    Instance.Update(self)
    if not self.Loaded then 
        self:UpdateLoad()
    end

    if self.Object == nil or
        self.ParentEffect ==nil or
        not self.Visible or
        self.Dead then
        return
    end

    if self.EffectInstanceData.Life > 0 and Time.time - self.BornTime >= self.EffectInstanceData.Life + self.ParentEffect.PauseTime or
        self.ParentEffect.FadeOut and Time.time - self.ParentEffect.FadeOutTime >= self.EffectInstanceDate.FadeOutTime then
        self:Destroy()
        return
    end

    if self.Object then
		
		if self.TrailsInit < 30 then
			self.TrailsInit = self.TrailsInit + 1;
		elseif self.TrailsInit == 30 then
			if self.Trails then
				for i=1, self.Trails.Length do
					if self.Trails[i] then
						self.Trails[i].time = self.TrailsTime[i];
					end
				end
			end
			self.TrailsInit = self.TrailsInit + 1;
		end
		
        self:UpdateTransform()
        --printyellow("self.Object")
        --printt(self.Object.transform.position)
    end

end




return EffectInstance
