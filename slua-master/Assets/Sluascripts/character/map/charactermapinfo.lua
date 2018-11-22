local MapInfoBase = require("map.base.mapinfobase")
local SceneManager = require("scenemanager")
local MapManager = require("map.mapmanager")
local ConfigManager = require("cfg.configmanager")
local DefineEnum = require("defineenum")

local CharacterMapInfo = Class:new(MapInfoBase)

function CharacterMapInfo:__new()
    self.m_InstanceId   = 0
    self.m_MapId        = cfg.map.WorldMap.DEFAULT_MAPID
    self.m_LineId       = 1
    self.m_EctypeId     = 0
    self.m_SceneName    = ""
    self.m_ChangingScene= false
    self.m_MapType      = DefineEnum.MapType.WorldMap
    self.m_Config       = nil
    self.m_SceneConfig  = nil
    self.m_EctypeType   = nil
end

function CharacterMapInfo:EnterWorldMap(instanceId, mapId, lineId)
    local needLoadScene = true

    self.m_InstanceId = instanceId
    self.m_MapId = mapId
    self.m_LineId = lineId

    self.m_Config = ConfigManager.getConfigData("worldmap", self.m_MapId)
    if self.m_Config == nil then
        logError("找不到地图配置：", self.m_MapId)
    else
        self.m_SceneName = self.m_Config.scenename
    end
    self.m_SceneConfig = ConfigManager.getConfigData("scene", self.m_SceneName)
    if self.m_SceneConfig == nil then
        logError("找不到场景配置：", self.m_SceneName)
    end
    self.m_MapType = DefineEnum.MapType.WorldMap
end

function CharacterMapInfo:EnterEctypeMap(instanceId, ectypeId, ectypeType)

    self.m_InstanceId = instanceId
    self.m_EctypeId = ectypeId
    self.m_Config = ConfigManager.getConfigData("ectypebasic", self.m_EctypeId)
    self.m_EctypeType = ectypeType

    if self.m_Config == nil then
        logError("找不到副本配置：", self.m_EctypeId)
    else
        self.m_SceneName = self.m_Config.scenename
    end
    self.m_SceneConfig = ConfigManager.getConfigData("scene", self.m_SceneName)
    if self.m_SceneConfig == nil then
        logError("找不到场景配置：", self.m_SceneName)
    end
    self.m_MapType = DefineEnum.MapType.EctypeMap
end

function CharacterMapInfo:EnterFamilyStation()
    self.m_MapType = DefineEnum.MapType.FamilyStation
end

function CharacterMapInfo:RegCallback(callback)
    self.m_Callback = callback
end


function CharacterMapInfo:GetMapId()
    return self.m_MapId
end

function CharacterMapInfo:SetMapId(mapId)
    self.m_MapId = mapId
end

function CharacterMapInfo:GetLineId()
    return self.m_LineId
end

function CharacterMapInfo:IsInWorldMap()
    return self.m_MapType == DefineEnum.MapType.WorldMap
end

function CharacterMapInfo:IsInEctype()
    return self.m_MapType == DefineEnum.MapType.EctypeMap
end

function CharacterMapInfo:IsInFamilyStation()
    return self.m_MapType == DefineEnum.MapType.FamilyStation
end


function CharacterMapInfo:GetSceneName()
    local sceneName = SceneManager.GetMapName()
    if sceneName == self.m_SceneName then
        return self.m_SceneName
    else
        logError("当前PlayerRole的MapInfo中保存的场景信息与实际场景信息不符合", self.m_SceneName, sceneName)
    end
end

function CharacterMapInfo:IsChangingScene()
    return SceneManager.IsLoadingScene()
end

function CharacterMapInfo:NeedLoadMapOnEnterWorld(mapId)
    local currentSceneName = SceneManager.GetMapName()
	print(mapId)
    local mapData = ConfigManager.getConfigData("worldmap", mapId)
    if mapData == nil then
        logError("找不到地图配置：", mapId)
    end
    local sceneName = mapData.scenename

    if currentSceneName == sceneName then
        return false
    else
        return true
    end

   -- if self.self.m_EctypeType == cfg.ectype.EctypeType.STORY then

   -- end
end


function CharacterMapInfo:GetStartPoint()
    if self.m_MapType == DefineEnum.MapType.WorldMap then
        local mapData = ConfigManager.getConfigData("worldmap", self.m_MapId)
        if mapData and mapData.WorldFlyInX and mapData.WorldFlyInY then
            return  Vector3(mapData.WorldFlyInX,mapData.WorldFlyInY,0)
        end
    end
    return Vector3(0,0,0)
end

return CharacterMapInfo
