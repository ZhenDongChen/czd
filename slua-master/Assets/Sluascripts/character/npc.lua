local print = print
local require = require
local Character = require "character.character"
local defineenum = require "defineenum"
local NpcStatusType = defineenum.NpcStatusType
local CharacterType = defineenum.CharacterType
local ConfigManager = require "cfg.configmanager"
local Define        = require"define"
local effectmanager = require"effect.effectmanager"

local Npc = Class:new(Character)

function Npc:__new(hideNpc,msg)
    Character.__new(self)
    self.m_Type = CharacterType.Npc
    self.m_AnimSelectType = cfg.skill.AnimTypeSelectType.Npc
    self.Msg = msg
    self.m_HasLoaded = not hideNpc
    if msg then
        self.m_Id = msg.agentid
        self.m_CsvId = msg.npcid
        self.m_Data = ConfigManager.getConfigData("npc",self.m_CsvId)
        if self.m_Data then
            self.m_Name = self.m_Data.name
        end
    end
end

function Npc:reset()
    Character.reset(self)
    self.m_Attributes[cfg.fight.AttrId.MP_VALUE] = 1
    self.m_Attributes[cfg.fight.AttrId.MP_FULL_VALUE] = 1
    self.m_Attributes[cfg.fight.AttrId.HP_VALUE] = 1
    self.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE] = 1
end

function Npc:init(id,csvId,showheadinfo)
    self.m_Id = id
    self.m_CsvId = csvId
    self.m_Data = ConfigManager.getConfigData("npc",self.m_CsvId)
    if self.m_Data then
        self.m_Name = self.m_Data.name
    end
    local ModelData =  ConfigManager.getConfigData("model",self.m_Data.modelname)
    self:CriticalLoadModel({ModelData,ModelData,showheadinfo})
end

function Npc:update()
    if not self.m_HasLoaded then return end
    Character.update(self)
end

function Npc:RefreshAvatarObject()
    ExtendedGameObject.SetLayerRecursively(self.m_Object,Define.Layer.LayerNPC)
end

function Npc:GetDefaultMotion() 
    if self.m_Data then
        return self.m_Data.motion
    end  
    return cfg.skill.AnimType.Stand
end 

function Npc:Show()
    if not self.m_HasLoaded then
        self.m_HasLoaded = true
        self:RegisterOnLoaded(function()
            Character.Show(self)
        end)
        self:init(self.Msg.agentid,self.Msg.npcid,true)
    else
        Character.Show(self)
    end
end

function Npc:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(false)
        local rand = math.random()
        if rand < self.m_Data.speakrate then
            if (#self.m_Data.opentext >0 ) then
                local idx = math.random(#self.m_Data.opentext)
                local uimanager = require"uimanager"
                printyellow("add headtalking content",self.m_Data.opentext[idx])
                uimanager.call("dlgheadtalking","Add",{content=self.m_Data.opentext[idx],target=self})
            end
        end
    end
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)

end

function Npc:HeadActive(b)
    if self.m_HeadInfo then
        self.m_HeadInfo:HeadActive(true)
    end
end

function Npc:QuestionMark(b)
    if b then
        printyellow("show question mark",self.m_Id)
        if self.m_QuestionMark == nil then
            self.m_QuestionMark = effectmanager.PlayEffect{
                id = 81001,
                bindCharacter = self,
                bSkill = false
            }
        end
    else
        printyellow("hide question mark",self.m_Id)
        if self.m_QuestionMark then
            effectmanager.StopEffect(self.m_QuestionMark)
            self.m_QuestionMark = nil
        end
    end
end

function Npc:ExclamationMark(b)
    if b then
        printyellow("show exclamation mark",self.m_Id)
        if self.m_ExclamationMark == nil then
            self.m_ExclamationMark = effectmanager.PlayEffect{
                id = 81002,
                bindCharacter = self,
                bSkill = false
            }
        end
    else
        printyellow("hide exclamation mark",self.m_Id)
        if self.m_ExclamationMark then
            effectmanager.StopEffect(self.m_ExclamationMark)
            self.m_ExclamationMark = nil
        end
    end
end

return Npc
