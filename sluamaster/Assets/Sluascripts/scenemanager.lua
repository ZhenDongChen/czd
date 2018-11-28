local SceneManager = Game.SceneMgr
local CharacterManager
local AudioMgr = require"audiomanager"
local GameEvent = require "gameevent"
local ConfigManager = require "cfg.configmanager"
local UIManager = require "uimanager"
local DefineEnum = require "defineenum"
local AudioMgr = require"audiomanager"
local EctypeManager
local CameraManager
local MapManager
local PlayerRole

local currentAudio = nil
local m_HideLoading = nil
local m_IsLoading = false
local m_IsClearOldScene = false
local m_Scene = 'maincity_01'

local m_Mapsize = nil;

local m_SceneStartCutscene = {
    m_CutsceneIndex = nil,
    m_Played = true,
}

local function PlayBackgroundMusic(id,mst)
    currentAudio = id or currentAudio

    if (currentAudio and not EctypeManager.IsInEctype()) or mst then
        AudioMgr.PlayBackgroundMusic(currentAudio)
    end
end


local function GetMapName()
    return Game.SceneMgr.Instance.MapName
end


local function GetSceneName()
    return Game.SceneMgr.Instance.SceneName
end


local function LoadBySceneName(sceneName)
    if sceneName then
        m_Scene = sceneName
        SceneManager.Instance:ChangeMap(sceneName)
    else
        SceneManager.Instance:ChangeMap("maincity_01")
    end
end


local function LoadTransitScene(params)
    SceneManager.Instance:ChangeScene("transit")
end


local function ShouldPlayMapCutscene()
    if m_SceneStartCutscene ~= nil and m_SceneStartCutscene.m_CutsceneIndex ~= nil and m_SceneStartCutscene.m_Played == false then
        return true
    end
    return false
end

local function GetCurMapId()
    return PlayerRole:GetMapId()
end

local function SceneCutsceneFadeIn()
    m_SceneStartCutscene = {}
end


local function SetAllAudioInScene()

    local currentScene=UnityEngine.SceneManagement.SceneManager.GetSceneByName(m_Scene)
    if currentScene then
        local sceneChildList=currentScene:GetRootGameObjects()
        if sceneChildList then
            for i=1,sceneChildList.Length do
                if (string.lower(sceneChildList[i].name)==m_Scene) then
                    local SettingManager=require "character.settingmanager"
                    local SystemSetting = SettingManager.GetSettingSystem()
                    local volume = (SystemSetting["MusicEffect"] or 0)
                    m_AudioList=sceneChildList[i].transform:GetComponentsInChildren(AudioSource,true)
                    for i = 1, m_AudioList.Length do
                        local audio=m_AudioList[i]
                        if audio then
                            audio.volume=volume
                        end
                    end
                    return
                end
            end
        end
    end
    m_AudioList=nil
end

local function SetAudioVolumeInScene(value)
    if m_AudioList then
        for i=1,m_AudioList.Length do
            local audio=m_AudioList[i]
            audio.volume=value
        end
    end
end

local function MuteAudioInScene(ismute)
    if m_AudioList then
        for i=1,m_AudioList.Length do
            local audio=m_AudioList[i]
            audio.mute=ismute
        end
    end
end

local function GetHeight(pos)
	 return 0
end

local function GetHeight1(pos)
	--[[
    if m_Terrian1==nil or m_HasSkyHeight==false then
        return nil
    end
    local height=m_Terrian1:GetHeight(pos)
    if (height<cfg.map.Scene.HEIGHTMAP_MIN) or (height<GetHeight(pos)) then
        height=GetHeight(pos)
    end
	]]
    return 0
end


local function OnLoad(params,sceneName,callBack)
	--SetAllAudioInScene()
	
    local sceneData = ConfigManager.getConfigData("scene",m_Scene)
	
    if UIManager.isshow("dlgloading") then
        local DlgLoading=require"ui.dlgloading"
        DlgLoading.SetLoadingProgress(1)
    end
    if UIManager.isshow("dlgjoystick") then
        Game.JoyStickManager.singleton:Reset()
    end
	
	PlayBackgroundMusic(sceneData.backgroundmusicid)
	
    GameEvent.evt_notify:trigger("loadscene_end",{m_SceneName = sceneName})

	CameraManager.reset()
	
    m_IsLoading = false

    if ShouldPlayMapCutscene() == false then
        m_HideLoading=os.time()
    else
        SceneCutsceneFadeIn()
    end
    
	m_Mapsize = SceneManager.Instance:GetMapSize();
	
    if callBack then
        callBack()
    end
end


local function LoadScene(params,sceneName,callBack)
    SceneManager.Instance:RegisteOnSceneLoadFinish(function(result)
        if result==true then
            m_LoadTimes=0
            local LoadOver=function() OnLoad(params,sceneName,callBack) end
            local timer=Timer.New(LoadOver,0.5,false)
            timer:Start()
        else
            m_LoadTimes=m_LoadTimes+1
            if (m_LoadTimes>cfg.map.Scene.RELOADTIME) then
                m_LoadTimes=0
                m_IsLoading=false
                CameraManager.reset()
                local login=require"login"
                login.role_logout(login.LogoutType.to_choose_player)
            else
                LoadBySceneName(sceneName)
            end
        end
    end)
    LoadBySceneName(sceneName)
    for _,v in ipairs(params) do
        UIManager.show(v)
    end
end


local function load(params,sceneName,callBack)
	printyellow(string.format("[scenemanager:load] start loading scene [%s]!", sceneName))
    UIManager.DestroyAllDlgs()
    if sceneName == GetMapName() then
        m_IsLoading = false
        if params then
            for _,v in ipairs(params) do
                UIManager.show(v)
            end
        end
        if callBack then
            callBack()
        end
        return
    end

    UIManager.show("dlgloading")
    GameEvent.evt_notify:trigger("loadscene_start",{m_SceneName = sceneName})
    LoadedMap = EctypeManager.IsInEctype()
    m_IsLoading = true
    m_IsClearOldScene = true
    CameraManager.stop()
    AudioMgr.StopBackgroundMusic()
    
    SceneManager.Instance:RegisteOnSceneLoadFinish(function(result)
        if result==true then
            m_LoadTimes=0
            m_IsClearOldScene = false
            LuaGC()
            LoadScene(params,sceneName,callBack)
        else
            m_LoadTimes=m_LoadTimes+1
            if (m_LoadTimes>cfg.map.Scene.RELOADTIME) then
                m_LoadTimes=0
                m_IsLoading=false
                CameraManager.reset()
                local login=require"login"
                login.role_logout(login.LogoutType.to_choose_player)
            else
               LoadBySceneName(sceneName)
            end
        end
    end)
    local mapId=MapManager.GetMapIdBySceneName(sceneName)
    if mapId then
        PlayerRole.m_MapInfo:SetMapId(mapId)
    end
    LoadTransitScene(params)
end



local function update()
    if m_HideLoading and ((os.time()-m_HideLoading)>=cfg.map.Scene.LOADSCENEDELAYTIME) then
        m_HideLoading=nil
        UIManager.hide("dlgloading")
    end
end

local function late_update()
end

local function IsLoadingScene()
    return m_IsLoading
end

local function OnLoginFinish(b)

	CharacterManager.NotifySceneLoginLoaded()
    UIManager.NotifySceneLoginLoaded()
	CameraManager.NotifySceneLoginLoaded()
    local login = require"login"
    login.NotifySceneLoginLoaded()
	
	if not b then
        network.send(lx.gs.login.CRoleLogout({}))
    end
	
    local sceneInfo = ConfigManager.getConfigData("scene","login")
    AudioMgr.PlayBackgroundMusic(sceneInfo.backgroundmusicid)
    UIManager.show("dlgflytext")
    UIManager.show("dlgheadtalking")
    UIManager.hide("dlgloading")

end


local function RegisteOnLoginFinish(b)
    if not b then
        UIManager.show("dlgloading")
        m_IsLoading = false
    end
	
    SceneManager.Instance:RegisteOnSceneLoadFinish(function(result)
        if result==true then
            local LoadOver=function()
                OnLoginFinish(b)
                UIManager.show("dlglogin_reminder")
            end
            local timer=Timer.New(LoadOver,0.5,false)
            timer:Start()
        else
            SceneManager.Instance:ChangeScene("login")
        end
    end)
end


local function GetLoadingProgress()
    if SceneManager.Instance.AsyncRate then
        if m_IsClearOldScene == true then
            return 0.15
        end
        return 0.15 + SceneManager.Instance.AsyncRate.progress * 0.85
    end
    return 0.9
end


local function AlterLoadedEctypeMap(b)
    loadedEctypeMap = b
end


local function LoadedEctypeMap()
    local ret = loadedEctypeMap
    loadedEctypeMap = false
    return ret
end

local function GetLandscapeId()
    local landscapeId=0
    local mapData=ConfigManager.getConfigData("worldmap",PlayerRole:GetMapId())
    if mapData then
        landscapeId=mapData.landscapeid
    end
    return landscapeId
end

local function IsCurMapWarp(id)
    local isCurWarp=false
    local worldMapData=ConfigManager.getConfigData("worldmap",PlayerRole:GetMapId())
    if worldMapData then
        if worldMapData.circleregionsetid==id then
            isCurWarp=true
        end
    end
    return isCurWarp
end


local function SetChangeMapCutscene(cutsceneIndex)
    if m_SceneStartCutscene == nil then
        m_SceneStartCutscene = {}
    end
    m_SceneStartCutscene.m_CutsceneIndex = cutsceneIndex
    m_SceneStartCutscene.m_Played = false
end

local function init()
    GameEvent.evt_update:add(update)
    GameEvent.evt_late_update:add(late_update)
	EctypeManager = require"ectype.ectypemanager"
	CameraManager = require "cameramanager"
	CharacterManager = require "character.charactermanager"
	MapManager = require "map.mapmanager"
	PlayerRole=(require"character.playerrole"):Instance()
    SceneManager.Instance:RegisteOnSceneLoadFinish(OnLoad)
end

local function GetMapSize()
	return m_Mapsize;
end
return {
    init = init,
	load = load,
	RegisteOnLoginFinish = RegisteOnLoginFinish,
	IsCurMapWarp = IsCurMapWarp,
	GetLandscapeId=GetLandscapeId,
    GetLoadingProgress = GetLoadingProgress,
	IsLoadingScene = IsLoadingScene,
	GetMapName = GetMapName,
	GetSceneName = GetSceneName,
	AlterLoadedEctypeMap = AlterLoadedEctypeMap,
	LoadedEctypeMap = LoadedEctypeMap,
	GetCurMapId = GetCurMapId,
    SetChangeMapCutscene = SetChangeMapCutscene,
	PlayBackgroundMusic = PlayBackgroundMusic,
    SetAudioVolumeInScene = SetAudioVolumeInScene,
	
	GetHeight1=GetHeight1,
	GetHeight=GetHeight,
	MuteAudioInScene = MuteAudioInScene,
	GetMapSize = GetMapSize,
	
}
