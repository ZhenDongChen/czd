local require                    = require
local charactermanager           = require "character.charactermanager"
local PlayerRole                 = require "character.playerrole"
local defineenum                 = require "defineenum"
local StandEffectInstance        = require "effect.instance.effectinstances.standeffectinstance"
local StandTargetEffectInstance  = require "effect.instance.effectinstances.standtargeteffectinstance"
local FollowEffectInstance       = require "effect.instance.effectinstances.followeffectinstance"
local FollowTargetEffectInstance       = require "effect.instance.effectinstances.followtargeteffectinstance"
local CreateRoleEffectInstance       = require "effect.instance.effectinstances.createroleeffectinstance"
local CreateTalismanEffectInstance = require "effect.instance.effectinstances.createtalismaneffectinstance"

local BindEffectInstance        = require "effect.instance.effectinstances.bindeffectinstance"

local BindToCameraEffectInstance = require "effect.instance.effectinstances.bindtocameraeffectinstance"
local TraceEffectInstance        = require "effect.instance.effectinstances.traceeffectinstance"
local TracePosEffectInstance     = require "effect.instance.effectinstances.traceposeffectinstance"
local UIStandEffectInstance      = require "effect.instance.effectinstances.uistandeffectinstance"
local CameraShakeInstance        = require "effect.instance.camerashakeinstance"
local SoundInstance              = require "effect.instance.soundinstance"
local ESpecialType               = defineenum.ESpecialType
local EffectInstanceType         = defineenum.EffectInstanceType



local Effect = Class:new()

function Effect:__new()
    self:reset()
end

function Effect:reset()
    self.EffectInstances      = {}
    self.SoundInstances       = {}
    self.CameraShakeInstances = {}
    self.EffectData           = nil
    self.Loaded               = false
    self.Dead                 = false
    self.StartTime            = 0
    self.bPause               = false
    self.PauseTime            = 0
    self.TracePosObj          = nil
    self.TargetTransform      = nil
    self.ScaleVec             = Vector3.zero
    self.AngleModify          = Vector3.zero
    self.SpecialType          = ESpecialType.None
    self.ScaleModify          = 1
    self.CasterId             = 0
    self.TargetId             = 0
    self.TargetPos            = Vector3.zero
    self.BindCharacter        = nil
    self.FadeOut              = false
    self.FadeOutTime          = 0
    --self.UseTargetPos = false
end

function Effect: Caster()
    local cha =charactermanager.GetCharacter(self.CasterId)
    return cha
end

function Effect: Target()
    return charactermanager.GetCharacter(self.TargetId)
end

function Effect:GetTargetDir() 
    local dir= nil
    local casterChar = self:Caster()
    local targetChar = self:Target()
    if casterChar and targetChar then
         dir=  Vector3(targetChar:GetRefPos().x - casterChar:GetRefPos().x,
                                   0,
                                   targetChar:GetRefPos().z - casterChar:GetRefPos().z):Normalize()
    
    end
    if dir and dir:Magnitude()> 1e-6 then return Quaternion.LookRotation(dir) else return nil end
end

function Effect:IsRole()
    return self.CasterId ~=0 and self.CasterId == PlayerRole:Instance().m_Id
end

function Effect:Load(data)
    printyellow("Effect:Load(data)")
    if data ==nil then
        return false
    end
    self.EffectData = data
    self.EffectInstances = {}
    self.SoundInstances = {}
    self.CameraShakeInstances = {}

    if data.InstanceDatas then
        for i = 1,#data.InstanceDatas do
            local instanceData = data.InstanceDatas[i]
            if instanceData then
                local instance = nil
                if Local.LogModuals.EffectManager then
                    printyellow("EffectInstanceType:",utils.getenumname(EffectInstanceType,instanceData.Type))
                end
                if self.BindCharacter or instanceData.Type == EffectInstanceType.BindToBip or instanceData.Type == EffectInstanceType.BindToBipTarget then
                    instance = BindEffectInstance:new() 
                elseif instanceData.Type == EffectInstanceType.Stand then
                    instance = StandEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.Follow then
                    instance = FollowEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.Trace then
                    instance = TraceEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.TracePos then
                    instance = TracePosEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.BindToCamera then
                    instance = BindToCameraEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.UIStand then
                    instance = UIStandEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.StandTarget then
                    instance = StandTargetEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.FollowTarget then
                    instance = FollowTargetEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.CreateRole then
                    instance = CreateRoleEffectInstance:new()
                elseif instanceData.Type == EffectInstanceType.CreateTalisman then
                    instance = CreateTalismanEffectInstance:new()
                end
                if instance then
                    instance.ParentEffect = self
                    if instance:Load(instanceData) then
                        table.insert(self.EffectInstances,instance)
                    end
                end
            end
        end
    end

    if data.SoundDatas then
        for i = 1,#data.SoundDatas do
            local soundinstanceData = data.SoundDatas[i]
            if soundinstanceData then
                local soundinstance = SoundInstance:new()
                soundinstance.ParentEffect = self
                if soundinstance:Load(soundinstanceData) then
                  table.insert(self.SoundInstances,soundinstance)
                end
            end
        end
    end

    if data.CameraShakes then
        for i = 1,#data.CameraShakes do
            local camerashakeData = data.CameraShakes[i]
            if camerashakeData then
                local camerashakeinstance = CameraShakeInstance:new()
                camerashakeinstance.ParentEffect = self
                if camerashakeinstance:Load(camerashakeData) then
                    table.insert(self.CameraShakeInstances,camerashakeinstance)
                end
            end
        end
    end

    self.Loaded = true
    self.StartTime = Time.time
    self.bPause = false
    self.PauseTime = 0
    return true

end

function Effect:Destroy()
    if self.EffectInstances then
        for i = 1 ,#self.EffectInstances do
            if self.EffectInstances[i] then
                self.EffectInstances[i]:Destroy()
            end
        end
        self.EffectInstances = {}
    end

    if self.SoundInstances then
        for i = 1 ,#self.SoundInstances do
            if self.SoundInstances[i] then
                self.SoundInstances[i]:Destroy()
            end
        end
        self.SoundInstances = {}
    end

    if self.CameraShakeInstances then
        for i = 1 ,#self.CameraShakeInstances do
            if self.CameraShakeInstances[i] then
                self.CameraShakeInstances[i]:Destroy()
            end
        end
        self.CameraShakeInstances = {}
    end

end

function Effect:Pause(bPause)
    self.bPause = bPause
end

function Effect:PrintDeadTime()
    local dead = false
  --  print( "self.EffectData.Life " .. self.EffectData.Life )
 --   print( "self.StartTime " .. self.StartTime )
  --  print( "self.PauseTime " .. self.PauseTime )
 --   print( "Time.time " .. Time.time )
    dead = Time.time - self.StartTime > self.EffectData.Life + self.PauseTime
  --  print( " dead " )
 --   print(dead)
end

function Effect:Update()
    if not self.Loaded then
        return
    end
    if self.EffectData == nil then
        self.Dead = true
        return
    end
    if self.bPause then
        self.PauseTime = self.PauseTime+ Time.deltaTime
        return
    end
    if self.BindCharacter then 
        self.Dead = false
    elseif self.EffectData.Life >0 and 
           Time.time - self.StartTime > self.EffectData.Life + self.PauseTime then
        self.Dead = true
    else
        self.Dead = true
        if self.Dead and self.EffectInstances then
            for i = 1 ,#self.EffectInstances do
                if self.EffectInstances[i] and not self.EffectInstances[i].Dead  then
                    self.Dead = false
                    break
                end
            end
        end
        if self.Dead and self.SoundInstances then
            for i = 1 ,#self.SoundInstances do
                if self.SoundInstances[i] and not self.SoundInstances[i].Dead  then
                    self.Dead = false
                    break
                end
            end
        end
        if self.Dead and self.CameraShakeInstances then
            for i = 1 ,#self.CameraShakeInstances do
                if self.CameraShakeInstances[i] and not self.CameraShakeInstances[i].Dead  then
                    self.Dead = false
                    break
                end
            end
        end

    end
    if self.Dead then
        return
    end

    if self.EffectInstances then
        for i = 1 ,#self.EffectInstances do
            if self.EffectInstances[i] and not self.EffectInstances[i].Dead  then
                self.EffectInstances[i]:Update()
            end
        end
    end
    if self.SoundInstances then
        for i = 1 ,#self.SoundInstances do
            if self.SoundInstances[i] and not self.SoundInstances[i].Dead  then
                self.SoundInstances[i]:Update()
            end
        end
    end

    if self.CameraShakeInstances then
        for i = 1 ,#self.CameraShakeInstances do
            if self.CameraShakeInstances[i] and not self.CameraShakeInstances[i].Dead  then
                self.CameraShakeInstances[i]:Update()
            end
        end
    end



end



function Effect:SetVisible(bVisible)
    if self.EffectInstances then
        for i = 1 ,#self.EffectInstances do
            if self.EffectInstances[i] then
                self.EffectInstances[i]:SetVisible(bVisible)
            end
        end
    end
end








return Effect
