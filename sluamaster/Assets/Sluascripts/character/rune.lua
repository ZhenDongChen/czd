local print = print
local require = require
local Character = require "character.character"
local defineenum = require "defineenum"
local CharacterType = defineenum.CharacterType
local WorkType      = defineenum.WorkType
local ConfigManager = require "cfg.configmanager"
local PlayerRole = require "character.playerrole"
local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"

local Rune = Class:new(Character)

function Rune:__new()
    Character.__new(self)
    self.m_Type = CharacterType.Rune
    self.m_BeEaten = false
end

function Rune:init(id,csvId)
    self.m_Id = id
    self.m_Born = true
    self.m_CsvId = csvId
    self.m_Data = ConfigManager.getConfigData("rune",csvId)
--    if self.m_Data then
--        self.m_Name = self.m_Data.name
--    end

    local ModelData =  ConfigManager.getConfigData("model",self.m_Data.model)
    self:CriticalLoadModel({ModelData,ModelData,false})
end


function Rune:update()
    --print("Rune update")
    Character.update(self)
    if not self.m_BeEaten then
        if mathutils.DistanceOfXoY(PlayerRole.Instance():GetRefPos(),self.m_Pos) < self:GetBodyRadius() then
            guardtowermanager.EatRune(self.m_Id)
            self.m_BeEaten = true
        end
    end
end

function Rune:OnCharacterLoaded(bundlename,asset_obj,isShowHeadInfo,playbornaction)
    if self.m_Object then
        self.m_Object:SetActive(true)
    end
    Character.OnCharacterLoaded(self,bundlename,asset_obj,isShowHeadInfo,playbornaction)
end


return Rune
