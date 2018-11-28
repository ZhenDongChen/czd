local print = print
local require = require
local Character = require "character.character"
local defineenum = require "defineenum"
local CharacterType = defineenum.CharacterType
local WorkType      = defineenum.WorkType
local ConfigManager = require "cfg.configmanager"

local Mineral = Class:new(Character)

function Mineral:__new()
    Character.__new(self)
    self.m_MineralState = nil
    self.m_Type = CharacterType.Mineral
end

function Mineral:init(id,csvId,showheadinfo)
    self.m_Id = id
    self.m_Born = true
    self.m_CsvId = csvId
    self.m_Data = ConfigManager.getConfigData("mineral",csvId)
    if self.m_Data then
        self.m_Name = self.m_Data.name
    end

    local ModelData =  ConfigManager.getConfigData("model",self.m_Data.path)
    self:CriticalLoadModel({ModelData,ModelData,showheadinfo})
end


function Mineral:update()
    Character.update(self)
    if self.m_Object and self.m_Born then
        self.m_Born = false
        self:PlayFreeAction(cfg.skill.AnimType.Born)
    end
end

function Mineral:SetDeath()
    self:Death()
end

function Mineral:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(false)
    end
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)


end


return Mineral
