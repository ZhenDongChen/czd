local print             = print
local require           = require
local SimplifiedCharacter
                        = require "character.simplifiedcharacter"
local DefineEnum        = require "defineenum"
local Define            = require "define"
local ConfigManager     = require "cfg.configmanager"
local CharacterType     = DefineEnum.CharacterType
local MountType         = DefineEnum.MountType

local SimplifiedPlayer = Class:new(SimplifiedCharacter)

function SimplifiedPlayer:__new(msg)
    SimplifiedCharacter.__new(self)
    self.m_Type                     = CharacterType.Player
    self.m_Name                     = msg.name
    self.m_Level                    = msg.level
    self.m_VipLevel                 = msg.viplevel
    self.m_FamilyName               = msg.familyname
    self.m_MountId                  = msg.rideid
    self.m_RideStatus               = msg.ridestatus
    self.m_TitleId                  = msg.titleid
    self.m_FabaoId                  = msg.fabaoid
    self.m_Effects                  = msg.effects
    self.m_PKState                  = msg.pkstate
    self.m_FighterCommon            = msg.fightercommon
    self.m_Effects                  = {}
    self.m_DeclareWarFamilys = {}
end


function SimplifiedPlayer:init(roleid,profession,gender,showheadinfo,dressid,equips)
    self.m_Id                       = roleid
    self.m_Gender                   = gender
    self.m_Profession               = profession
    self.m_Dress                    = dressid
    self.m_Equips                   = equips
    self.m_ProfessionData           = ConfigManager.getConfigData("profession",self.m_Profession)
    self.m_ProfessionModel          = self.m_Gender == cfg.role.GenderType.MALE
                                    and self.m_ProfessionData.modelname
                                    or  self.m_ProfessionData.modelname2

    local characterModelData        = ConfigManager.getConfigData("model",self.m_ProfessionModel)
    self.m_ModelData                = characterModelData
    self.m_Image                    = characterModelData.portrait
    SimplifiedCharacter.init(self)
end

function SimplifiedPlayer:ChangeArmour(dresssid,equips)
    self.m_Dress = dressid or self.m_Dress
    self.m_Equips = equips or self.m_Equips
end

function SimplifiedPlayer:GetMessage()
    local ret           = {}
    ret.roleid          = self.m_Id
    ret.playerid        = self.m_Id
    ret.gender          = self.m_Gender
    ret.profession      = self.m_Profession
    ret.name            = self.m_Name
    ret.level           = self.m_Level
    ret.viplevel        = self.m_VipLevel
    ret.familyname      = self.m_FamilyName

    ret.dressid         = self.m_Dress
    ret.rideid          = self.m_MountId
    ret.ridestatus      = self.m_RideStatus
    ret.titleid         = self.m_TitleId
    ret.fabaoid         = self.m_FabaoId

    ret.equips          = self.m_Equips
    ret.effects         = self.m_Effects
    ret.pkstate         = self.m_PKState
    return SimplifiedCharacter.GetMessage(self,ret)
end

function SimplifiedPlayer:ChangeFabao(fabaokey)
    self.m_Fabao = fabaokey
end

function SimplifiedPlayer:LoadWeapon(equips)
    self.m_Equips = equips
end

function SimplifiedPlayer:ChangeRide(msg)
    self.m_MountType    = msg.ridetype
    self.m_MountId      = msg.rideid
    if msg.ridetype == 0 or msg.rideid == 0 then
        self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] = 6*SCALE_SPEED
    else
        self.m_MountData = ConfigManager.getConfigData("riding",self.m_MountId)
        self.m_Attributes[cfg.fight.AttrId.MOVE_SPEED] = self.m_MountData.ridespeed
    end
end

function SimplifiedPlayer:ChangeDress(dressid)
    self.m_Dress = dressid
end

function SimplifiedPlayer:ChangeEquip(equips)
    self.m_Equips = equips
end

function SimplifiedPlayer:ChangeTitle(titleid)
    self.m_TitleId = titleid
    local TitleManager = require "ui.title.titlemanager"
    if titleid ~= nil and titleid > 0 then
        self.m_Title = TitleManager.Title:new(titleid, true)
    else
        self.m_Title = nil
    end
    if self.m_HeadInfo then
        self.m_HeadInfo:OnChangeTitle()
    end
end

function SimplifiedPlayer:ChangePKState(state)
    SimplifiedCharacter.ChangePKState(self,state)
    local pets = CharacterManager.GetCharacterPets(self)
    for _,pet in pairs(pets) do
        pet:ChangePKState(state)
    end
end

function SimplifiedPlayer:ChangeVipLevel(level)
    self.m_VipLevel = level
end

function SimplifiedPlayer:ChangeFamily(familyname)
    self.m_FamilyName = familyname
    -- refresh name on dlgmonster_hp
end

function SimplifiedPlayer:ChangeName(name)
    self.m_Name = name
    self:ShowName()
end

function SimplifiedPlayer:ToComplete()
    local CharacterManager = require"character.charactermanager"
    return CharacterManager.AlterCharacter(self.m_Id,false)
end

function SimplifiedPlayer:OnTeamChanged(b)
    if not self:IsRole() then
        if self.m_HeadInfo then
            self.m_HeadInfo:TurnHPProgressColor(b)
        end
        local pets = CharacterManager.GetCharacterPets(self)
        for _,pet in pairs(pets) do
            pet:OnTeamChanged(b)
        end
    end
end

function SimplifiedPlayer:IsRiding()
    return self.m_MountId ~= 0
end

function SimplifiedPlayer:HideHeadInfo()
    local CharacterManager = require"character.charactermanager"
    local pets = CharacterManager.GetCharacterPets(self)
    for _,pet in pairs(pets) do
        pet:HideHeadInfo()
    end
    SimplifiedCharacter.HideHeadInfo(self)
end

function SimplifiedPlayer:ChangeDeclareWarFamilys(newFamilysId)
    if newFamilysId == nil then
        return
    end
    self.m_DeclareWarFamilys = {}
    for i, id in pairs(newFamilysId) do
        self.m_DeclareWarFamilys[id] = true
    end
    self:OnFamilyWarChange()
end

function SimplifiedPlayer:OnFamilyWarChange()
    if self.m_HeadInfo then
        self.m_HeadInfo:OnFamilyWarChange()
    end
end


function SimplifiedPlayer:IsInWarWithRoleFamily()
    local roleFamilyId = PlayerRole:Instance().m_FamilyID
    if self.m_FamilyID ~= nil and roleFamilyId ~= nil then
        if self.m_DeclareWarFamilys[roleFamilyId] == true then
            return true
        end
        if PlayerRole:Instance().m_DeclareWarFamilys[self.m_FamilyID] == true then
            return true
        end
    end
    return false
end

return SimplifiedPlayer
