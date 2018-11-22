local print=print
local require=require
local Character=require "character.character"
local defineenum = require"defineenum"
local CharacterType=defineenum.CharacterType
local gameevent=require "gameevent"
local Partner=Class:new(Character)
local playerPos
local scenemanager = require "scenemanager"
local PetFSM = require "character.ai.partnerfsm"
local network = require "network"
local mathutils = require"common.mathutils"
local ConfigManager = require"cfg.configmanager"
local Navigation = require"character.navigation.navigationcontroller"
local uimanager
local CharacterManager
local PetManager


function Partner:__new(id,csvId,masterid,ismodel)
    Character.__new(self)
    self.m_Type = CharacterType.Pet
    self.m_Id = id
    self.m_CsvId = csvId
    self.m_MasterId = masterid
    self.m_SkillEnd = false
    self.m_IsModel = ismodel
    self.m_bIsRolePet = false
    self.m_Data = ConfigManager.getConfigData("petbasicstatus",self.m_CsvId)
    self.m_Name = self.m_Data.name or ""
    self.m_NameColor = "ffffff"
    CharacterManager = require"character.charactermanager"
    PetManager  = require"character.pet.petmanager"
    uimanager   = require"uimanager"
    local master  = CharacterManager.GetCharacter(masterid)
    self.m_Master = master
   -- self.PetFsm = PetFSM:new(self.m_ID,self,self.m_Master)
end

function Partner:LoadSkin()
    local ModelData = nil
    local modelname = nil
    if self.m_SkinId~=0 then
        local skinInfo = ConfigManager.getConfigData("petskin",self.m_SkinId)
        modelname = skinInfo.modelname
    else
        modelname = self.m_Data.modelname
    end
    local ModelData = ConfigManager.getConfigData("model",modelname)
    self:CriticalLoadModel({ModelData,ModelData,not self.m_IsModel}) --继承于Character加载模型的流程
end

function Partner:OnCharacterLoaded(modelpath,asset_obj,isShowHeadInfo,playbornaction)

    if self.m_Object then
        self.m_Object:SetActive(true)
    end
    Character.OnCharacterLoaded(self,modelpath,asset_obj,isShowHeadInfo,playbornaction)
    -- if self.m_IsModel then
    --     printyellow("self.m_ModelData.uimodelscalemodify",self.m_ModelData.uimodelscalemodify)
    --     self:SetUIScale(self.m_ModelData.uimodelscalemodify)
    -- end
    self:ShowTexture()
end

function Partner:IsRolePet()
    local master = self:GetMaster()
    if master then return self.m_Master:IsRole() end
    return false
end

function Partner:init(skinid)
    self.m_SkinId = skinid or 0
    self.m_NameColor = PetManager.GetQualityColor(self)
    self:LoadSkin()
end

function Partner:ChangeAttr(attrs)
    Character.ChangeAttr(self,attrs)
    if self:IsRolePet() and uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain","RefreshPetAttributes",self)
    end
end

function Partner:GetName()

      return '[' .. self.m_NameColor .. ']' .. self.m_Name .. '[-]'

end

function Partner:ShowTexture()
    if not self.m_IsModel and self.m_HeadInfo then
        local NameTexutre = PetManager.GetQualityColorTexture(self)
        if NameTexutre == nil or NameTexutre == "" then return end
        self.m_HeadInfo:SetAwakeTexture(NameTexutre)
    end
end

function Partner:ChangeSkin(skinid)
    self.m_SkinId = skinid or 0
    self:LoadSkin()
end

function Partner:update()
    Character.update(self)
end


function Partner:GetMaster()
    if self.m_Master then return self.m_Master end
    local master = CharacterManager.GetCharacter(self.m_MasterId)
    if master then
        self.m_Master = master
    end
    return master
end

function Partner:Death()
    Character.Death(self)
    if self:IsRolePet() then
        PetManager.Death(self.m_CsvId)
    end
end

function Partner:Revive()
    Character.Revive(self)
    if self:IsRolePet() then
        PetManager.Revive(self.m_CsvId)
    end
end

function Partner:ChangeStarLevel(level)
    self.m_StarLevel = level
end

function Partner:ChangeAwakeLevel(level)
    self.m_AwakeLevel = level
    self:ShowTexture()
end

function Partner:OnTeamChanged(b)
    if self.m_HeadInfo then
        self.m_HeadInfo:OnTeamChanged(b)
    end
end

function Partner:GetMessage()
    local ret               = {}
    ret.agentid             = self.m_Id
    ret.petkey              = self.m_CsvId
    ret.owenrid             = self.m_MasterId
    ret.level               = self.m_Level
    ret.starlevel           = self.m_StarLevel
    ret.awakelevel          = self.m_AwakeLevel
    ret.skinid              = self.m_SkinId
    return Character.GetMessage(self,ret)
end

function Partner:HaveRelationshipWithRole()
    local master = self:GetMaster()
    if master then
        return master:HaveRelationshipWithRole()
    else
        local PlayerRole = require"character.playerrole"
        local camprelationInfo = ConfigManager.getConfigData("camprelation",PlayerRole.Instance().m_Camp)
        if camprelationInfo then
            return (camprelationInfo.relations[self.m_Camp+1] == cfg.fight.Relation.FRIEND
            or camprelationInfo.relations[self.m_Camp+1] == cfg.fight.Relation.SELF)
        end
    end
end

function Partner:ToSimplified()
    local CharacterManager = require"character.charactermanager"
    return CharacterManager.AlterCharacter(self.m_Id,true)
end

function Partner:PlayReviveEffect(effectId)
    local effectData = ConfigManager.getConfigData("effect",effectId)
    if effectData then 
        self:PlayAction(effectData.reviveactionname)
    end
    
end

return Partner
