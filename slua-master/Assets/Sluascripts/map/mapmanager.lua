local NetWork = require("network")
local UIManager = require("uimanager")
local ConfigManager = require("cfg.configmanager")
local SceneManager  = require("scenemanager")
local PlayerRole

local m_FirstLogin = true

local function OnMsg_SGetMapLines(msg)
    if UIManager.isshow("map.tabline") then
        UIManager.call("map.tabline","ShowMapLines",msg)
    end
end

local function AllowRide()
    local result = false
    local mapData = ConfigManager.getConfigData("worldmap",PlayerRole:GetMapId())
    if mapData then
        result = mapData.allowride
    end
    return result 
end

local function PreLoadLoadingTexture()
    Util.Load("ui/dlgloading.ui", define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
    end)
    local mapLoading = ConfigManager.getConfig("maploading")
    for texture,text in pairs(mapLoading) do
        if texture then
            local texName=string.format("texture/t_%s.bundle",texture)
            Util.Load(texName, define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
            end)
        end
    end   
end

local function IsFirstLogin()
    return m_FirstLogin
end

local function SetFirstLogin()
    m_FirstLogin = false
end


local function GetMapIdBySceneName(name)
    local mapData = ConfigManager.getConfig("worldmap")
    for _,map in pairs(mapData) do
        if map.scenename == name then
            return map.id
        end
    end
end


local function GetCenterPosOfPortal(regionsetId,portalId)
    local circleRegion = ConfigManager.getConfigData("circleregionset",regionsetId)
    if circleRegion == nil then 
        return nil 
    end
    local center = nil
    for _, region in pairs(circleRegion.regions) do
          if region.id == portalId then
              center = region.circle.center
              break
          end
    end
    return center
end

local function GetPortalOfMap(currentMapId, targetMapId)
    if currentMapId == nil or targetMapId == nil then
        return nil,nil
    end
    local mapData = ConfigManager.getConfigData("worldmap",currentMapId)
    for i, portal in pairs(mapData.portals) do
        if portal.dstworldmapid == targetMapId then
            local centerPos = GetCenterPosOfPortal(mapData.circleregionsetid, portal.srcregionid)
            if centerPos then
                return Vector3(centerPos.x * 100,centerPos.y * 100, 0), portal.srcregionid
            end
        end
    end
    return nil,nil
end


local function GetPortalOfMap_PortalId(currentMapId, portalId)
    if currentMapId == nil or portalId == nil then
        return nil
    end
    local mapData = ConfigManager.getConfigData("worldmap",currentMapId)
	local centerPos = GetCenterPosOfPortal(mapData.circleregionsetid, portalId)
    if centerPos then
        return Vector3(centerPos.x * 100,centerPos.y * 100, 0)
    end
    
	return nil
end

local function EnterMapWithoutStop(mapId,lineId)
    local line = lineId
    if line == nil then
        line = 0
    end
    if mapId == nil then
        mapId = PlayerRole:GetMapId()
    end
    local msg = lx.gs.map.msg.CEnterWorld({worldid = mapId,lineid = line})
    NetWork.send(msg)
end

local function EnterMap(mapId,lineId)
    PlayerRole:stop()
    EnterMapWithoutStop(mapId,lineId)
end

local function TransferMapWithoutStop(portalId)
    local msg = map.msg.CTransferWorld({ portalid = portalId })
    NetWork.send(msg)
end

local function TransferMap(portalId)
    PlayerRole:stop()
    TransferMapWithoutStop(portalId)
end


local function NotifySceneLoaded()
	--local vec = SceneManager.Instance.GetBlockSize();
	--BlockSizeX = vec.x;
	--BlockSizeY = vec.y;
end


--�õ���·
local function GetMapLines()

   local msg = lx.gs.map.msg.CGetWorldLines({worldid = PlayerRole:GetMapId()})      
   NetWork.send(msg)
	
end

local function OnMsg_SGetMapLines(msg)
    if UIManager.isshow("map.tabline") then
        UIManager.call("map.tabline","ShowMapLines",msg)
    end
end

local function Clear()
    m_FirstLogin = true
end

local function init()
    m_FirstLogin = true
    PlayerRole = require("character.playerrole"):Instance()
    NetWork.add_listener("lx.gs.map.msg.SGetWorldLines",OnMsg_SGetMapLines)
	
    gameevent.evt_system_message:add("logout",Clear)	
	gameevent.evt_notify:add("loadscene_end",NotifySceneLoaded)
end

local function GetTransferCoord(oldCoord,wRatio,hRatio)

    local newCoord = Vector3.zero
    local mapData = ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId())
    if mapData then
        local sceneName = mapData.scenename
        local sceneData = ConfigManager.getConfigData("scene",sceneName)
       -- local sceneSize = sceneData.scenesize
		local scenesizeX=sceneData.scenesizeX
		local scenesizeY=sceneData.scenesizeY
		local offsetx = sceneData.offsetx
		local offsety = sceneData.offsety
		
        newCoord = Vector3((-(oldCoord.x*SCALE_XY ) + scenesizeX / 2) * wRatio-offsetx,(-(oldCoord.y*SCALE_XY ) + scenesizeY / 2) * hRatio - offsety,0)

    end
    return newCoord
end

local function GetTransferCoordInArea(oldCoord,wRatio,hRatio)
    local sceneName = ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId()).scenename
    local sceneData = ConfigManager.getConfigData("scene",sceneName)
    --local sceneSize = sceneData.scenesize
 --   local type = sceneData.pivot
    local scenesizeX = sceneData.scenesizeX
    local scenesizeY = sceneData.scenesizeY
	local offsetx = sceneData.offsetx
	local offsety = sceneData.offsety
    local newCoord = Vector3.zero
   -- if type == cfg.map.PivotPos.CENTER then
        --newCoord = Vector3((oldCoord.x)* wRatio, (oldCoord.y) * hRatio, 0)
   -- elseif type == cfg.map.PivotPos.LEFTBOTTOM then

	newCoord = Vector3(((oldCoord.x*SCALE_XY )-scenesizeX/2)*wRatio,((oldCoord.y*SCALE_XY )-scenesizeY/2)*hRatio,0)
  --  end
    return newCoord
end



return {
    init = init,
	PreLoadLoadingTexture = PreLoadLoadingTexture,
	IsFirstLogin = IsFirstLogin,
    SetFirstLogin = SetFirstLogin,
	GetMapIdBySceneName = GetMapIdBySceneName,
	GetPortalOfMap = GetPortalOfMap,
	GetPortalOfMap_PortalId = GetPortalOfMap_PortalId,
	EnterMap = EnterMap,
    EnterMapWithoutStop = EnterMapWithoutStop,
    TransferMap = TransferMap,
    TransferMapWithoutStop = TransferMapWithoutStop,

    AllowRide = AllowRide,
    GetTransferCoord = GetTransferCoord,
	GetTransferCoordInArea = GetTransferCoordInArea,
	GetMapLines = GetMapLines,
}