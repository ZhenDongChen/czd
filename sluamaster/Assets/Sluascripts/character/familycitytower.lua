local print = print
local require = require
local Character = require "character.character"
local defineenum = require "defineenum"
local CharacterType = defineenum.CharacterType
local WorkType      = defineenum.WorkType
local ConfigManager = require "cfg.configmanager"
local network       = require"network"
local EctypeManager
local define        = require"define"
local uimanager
local cfgCityWar
local ResourceManager   = require("resource.resourcemanager")
local FamilyCityTower = Class:new(Character)

function FamilyCityTower:__new()
    Character.__new(self)
    self.m_MineralState = nil
    self.m_Type = CharacterType.FamilyCityTower
    EctypeManager = require"ectype.ectypemanager"
    uimanager   = require"uimanager"
    self.m_EctypeConfig = ConfigManager.getConfig("citywar")
    self.m_ElapsedOccupyingTime = nil
end

function FamilyCityTower:init(index,csvId)
    self.m_Id = index
    self.m_CsvId = csvId
    self.m_Data = ConfigManager.getConfigData("mineral",csvId)
    if self.m_Data then
        self.m_Name = self.m_Data.name
    end
    local ModelData =  ConfigManager.getConfigData("model",self.m_Data.path)
    self:CriticalLoadModel({ModelData,ModelData})
end

function FamilyCityTower:LoadAvatar(type)
   if self.m_AvatarType == type then return end
    self.m_AvatarType = type
	local temptarget = m_Object
	GameObject.Destroy(temptarget)
    local modelname   = self.m_EctypeConfig.occupymodel[type]
    local ModelData   = ConfigManager.getConfigData("model",modelname)
    self:CriticalLoadModel({ModelData,ModelData})

end

function FamilyCityTower:OnCharacterLoaded(modelpath,asset_obj,isShowHeadInfo,playbornaction)
    Character.OnCharacterLoaded(self,modelpath,asset_obj,isShowHeadInfo,playbornaction)
    Util.Load("sfx/s_changjing_fazhen03.bundle",define.ResourceLoadType.LoadBundleFromFile,function(obj)
        if IsNull(obj) then
            return
        end
        self.m_Aperture = GameObject.Instantiate(obj)
        self.m_Aperture.transform:SetParent(self.m_Object.transform)
        self.m_Aperture:SetActive(true)
        -- self.m_Aperture.transform.localScale = Vector3.one * 2
        local children = self.m_Aperture.transform:GetComponentsInChildren(UnityEngine.Transform)
        for i=1,#children do
            child = children[i]
            child.localScale = Vector3.one
        end
        self.m_Aperture.transform.localPosition = Vector3.zero
        self.m_Aperture.transform.localRotation = Quaternion.identity
    end)
end

return FamilyCityTower
