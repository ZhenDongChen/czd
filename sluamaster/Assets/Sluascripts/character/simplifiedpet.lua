local print             = print
local require           = require
local SimplifiedCharacter
                        = require "character.simplifiedcharacter"
local DefineEnum        = require "defineenum"
local Define            = require "define"
local ConfigManager     = require "cfg.configmanager"
local PetManager        = require"character.pet.petmanager"
local CharacterType     = DefineEnum.CharacterType
local MountType         = DefineEnum.MountType

local SimplifiedPet = Class:new(SimplifiedCharacter)

function SimplifiedPet:__new(msg)
    SimplifiedCharacter.__new(self)
    self.m_Type                     = CharacterType.Pet
    self.m_Camp                     = msg.fightercommon.camp
    self.m_Level                    = msg.level
    self.m_StarLevel                = msg.starlevel
    self.m_AwakeLevel               = msg.awakelevel
    self.m_SkinId                   = msg.skinid
    self.m_Id                       = msg.agentid
    self.m_CsvId                    = msg.petkey
    self.m_MasterId                 = msg.owenrid
    self.m_FighterCommon            = msg.fightercommon
    self.m_Data                     = ConfigManager.getConfigData("petbasicstatus",self.m_CsvId)
    self.m_ModelData                = ConfigManager.getConfigData("model",self.m_Data.modelname)
    self.m_Name                     = self.m_Data.name
    self.m_NameColor                = PetManager.GetQualityColor(self)
    self.m_Effects                  = {}
end


function SimplifiedPet:init(skinid)
    -- self.m_SkinId                   = skinid or 0
    self:ChangeSkin(skinid)
    SimplifiedCharacter.init(self)
end

function SimplifiedPet:GetMessage()
    local ret                       = {}
    ret.agentid                     = self.m_Id
    ret.petkey                      = self.m_CsvId
    ret.owenrid                     = self.m_MasterId
    ret.level                       = self.m_Level
    ret.starlevel                   = self.m_StarLevel
    ret.awakelevel                  = self.m_AwakeLevel
    ret.skinid                      = self.m_SkinId
    return SimplifiedCharacter.GetMessage(self,ret)
end

function SimplifiedPet:IsRolePet()
    return false
end

function SimplifiedPet:GetName()

    return '[' .. self.m_NameColor .. ']' .. self.m_Name .. '[-]'
end

function SimplifiedPet:ChangeSkin(skinid)
    self.m_SkinId = skinid or 0
    if self.m_SkinId == 0 then
        self.m_ModelData = ConfigManager.getConfigData("model",self.m_Data.modelname)
    else
        local skinInfo = ConfigManager.getConfigData("petskin",skinid)
        self.m_ModelData = ConfigManager.getConfigData("model",skinInfo.modelname)
    end
end

function SimplifiedPet:GetMaster()
    if self.m_Master then return self.m_Master end
    local master = CharacterManager.GetCharacter(self.m_MasterId)
    self.m_Master = master
    return master
end

function SimplifiedPet:ChangeStarLevel(level)
    self.m_StarLevel = level
end

function SimplifiedPet:ChangeAwakeLevel(level)
    self.m_AwakeLevel = level
end

function SimplifiedPet:ToComplete()
    local CharacterManager = require"character.charactermanager"
    return CharacterManager.AlterCharacter(self.m_Id,false)
end

function SimplifiedPet:OnTeamChanged(b)
    if self.m_HeadInfo then
        self.m_HeadInfo:TurnHPProgressColor(b)
    end
end

function SimplifiedPet:update()
    -- local CharacterManager = require"caracter.charactermanager"
	print("SimplifiedPet:update")
    if self.m_Master then
        if not self.m_Master:IsSimplified() then
            return CharacterManager.AlterCharacter(self.m_Id,false)
        end
    end
    SimplifiedCharacter.update(self)
end


return SimplifiedPet
