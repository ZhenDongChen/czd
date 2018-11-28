local print             = print
local require           = require
local Pet               = require"character.pet.pet"
local defineenum        = require"defineenum"
local define            = require"define"
local network           = require"network"
local CharacterType     = defineenum.CharacterType
local PetAI             = require"character.pet.petai"
local Navigation        = require "character.navigation.navigationcontroller"
local PetManager        = require"character.pet.petmanager"
local RolePet = Class:new(Pet)
local PlayerSkill


function RolePet:__new(id,csvId,master,ismodel)
    Pet.__new(self,id,csvId,master,ismodel)
    self.m_Type                 = defineenum.CharacterType.Pet
    -- self.m_PetAI                = PetAI:new(self)
    self.m_Navigation           = Navigation:new(self)
    self.m_MapInfo              = self.m_Master.m_MapInfo
    if PlaySkill == nil then
        PlayerSkill = require"character.skill.playerskill"
    end
    self.PlayerSkill            = PlayerSkill:new(self)
    -- fsm
end

function RolePet:init(skinid)
    Pet.init(self,skinid)
    self.m_PetAI = PetAI:new(self)
end

function RolePet:navigateTo(params)
    if params.targetPos == nil or params.targetPos == Vector3(0,0,0) then
        return
    end
    self.m_Navigation:StartNavigate(params)
end

function RolePet:update()
    Pet.update(self)
    if self.m_PetAI then
        self.m_PetAI:Update()
    end
    self.m_Navigation:Update()
    self.PlayerSkill:Update()
    --fsm update
end

function RolePet:GetMapId()
    return self.m_Master:GetMapId()
end

function RolePet:IsPlayerRolesPet()
    return true
end

function RolePet:IsNavigating()
    return self.m_Navigation:IsNavigating()
end


function RolePet:CanReach(dst)
    if not EctypeManager.CheckPosition(position) then
        return false
    end
    return true
end

function RolePet:SendMove(dst)
    self.m_TransformSync:SyncMoveTo({position = self:GetPos(),target=dst,isplayercontrol=0})
    local re = map.msg.CPetMove({position=self:GetPos(),target=dst,petid=self.m_Id})
    network.send(re)
end

function RolePet:SendStop(pos)
    local target = pos or self:GetPos()
    self.m_TransformSync:SyncStop({position = target,orient = self.m_Object.transform.forward,isplayercontrol = 0})
    local re = map.msg.CPetStop({petid=self.m_Id,position=target,orient = self.m_Object.transform.forward})
    network.send(re)
end

function RolePet:SendAttack(skillid)
    local re = map.msg.CPetSkillPerform({targetid=self:GetTargetId(),skillid=skillid,direction=self.m_Object.transform.forward,petid=self.m_Id})
    network.send(skillid)
    self:PlaySkill(skillid)
end

function RolePet:ChangeAttr(attrs)
    Pet.ChangeAttr(self,attrs)
    if self:IsPlayerRolesPet() then
        PetManager.ChangeFieldAttr(self)
    end
end

function RolePet:moveTo(dst)
    if not self:CanMove() then return false end
    if self.m_Navigation:IsNavigating() then  self.m_Navigation:StopNavigate() end
    if self:CanReach(dst) and self.m_Effect:CanMove() then
        self:SendMove(dst)
        return true
    end
    return false
end

function RolePet:IsRiding()
    return false
end

function RolePet:stop(delta)
    if self.m_Object then
        self.WorkMgr:StopWork(defineenum.WorkType.Move)
        if self.m_Navigation:IsNavigating() then
            self.m_Navigation:StopNavigate()
        end
    end
end

function RolePet:GetNavigateTarget()
    return self.m_Navigation:GetTargetInfo()
end

function RolePet:NotifyAttackComplete(skillid,bCastCallBackSkill)
    Player.NotifyAttackComplete(self,skillid,bCastCallBackSkill)
    self.m_PetAI:NotifyAttackComplete(bCastCallBackSkill)
end

function RolePet:GetNavigateTarget()
    return self.m_Navigation:GetTargetInfo()
end

return RolePet
