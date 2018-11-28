local defineenum = require "defineenum"
local AniStatus = defineenum.AniStatus
local CharacterType = defineenum.CharacterType

local AnimationManager = Class:new()
function AnimationManager:__new()
    self:reset()
end

 

function AnimationManager:reset()

    self.Character = nil
    self.animator = nil
    self.m_MecanimControl = nil
end

function AnimationManager:Init(character)

    self.Character = character
	
	self.animator = LuaHelper.GetComponent(self.Character.m_Object.transform:GetChild(0).gameObject,"Animator")
    self.animator.speed =1
    if self.Character.m_Type == CharacterType.PlayerRole then
     self.animator.cullingMode = LuaHelper.GetAnimatorAwaysMode()
    end
     self.m_MecanimControl = LuaHelper.GetComponent(self.Character.m_Object.transform:GetChild(0).gameObject,"MecanimControl")
end

function AnimationManager:CanPlay() 
	
    return self.Character:IsActive()
end 
--已经作废（由Character:IsPlaying代替）
function AnimationManager:IsPlaying(aniName)

    if not self:CanPlay() then 
		return false 
	end
    local playing = self.m_MecanimControl:IsPlaying(StringToHash(aniName))
    return playing
end
--已经作废（由Character:IsPlayingSkill代替）
function AnimationManager:IsPlayingSkill(aniName,loopplay)
    if not self:CanPlay() then return false end
    local playing =  self.m_MecanimControl:IsPlayingSkill(StringToHash(aniName),loopplay)
    return playing
end
--已经作废（由Character:Play代替）
function AnimationManager:Play(aniName,speed)
    if Local.LogModuals.AnimationManager then
        printyellow("AnimationManager:Play(aniName)",aniName,Time.time)
    end
    if not self:CanPlay() then return end
    if not IsNullOrEmpty(aniName) and self.m_MecanimControl then
        self.m_MecanimControl.speed = speed~=nil and speed or 1
        self.m_MecanimControl:Play(StringToHash(aniName))
    end
end
--此函数会造成GC 禁止在Update里调用
function AnimationManager:GetCurrentAnimatorStateInfo()
    local layerIndex = self.animator:GetLayerIndex("Base Layer")
    local animatorstateinfo = self.animator:GetCurrentAnimatorStateInfo(layerIndex)
    return animatorstateinfo
end

function AnimationManager:GetNormalizedTime()
    if self.m_MecanimControl then 
        return self.m_MecanimControl:GetNormalizedTime()
    else 
        logError("m_MecanimControl is nil m_Id:"..self.Character.m_Id)
        return 0
    end 
end

function AnimationManager:CrossFade(aniName,transitionDuration)
    if Local.LogModuals.AnimationManager then 
        printyellow("AnimationManager:CrossFade(aniName)",aniName,Time.time)
    end
    if not self:CanPlay() then return end
    if self.m_MecanimControl~=nil then  
        self.m_MecanimControl:CrossFade(StringToHash(aniName),transitionDuration or 0.2) 
    else 
        logError("m_MecanimControl is nil m_Id:"..self.Character.m_Id)
    end 
end

return AnimationManager
