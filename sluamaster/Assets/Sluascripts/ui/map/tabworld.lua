local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ConfigManager=require("cfg.configmanager")
local MapManager=require("map.mapmanager")
local NetWork = require("network")
local PlayerRole=require("character.playerrole")

local m_GameObject
local m_Name
local m_Fields

local function GetMapInfoByName(name)
	local mapInfo
    local maps=ConfigManager.getConfig("worldmap")
    for _,map in pairs(maps) do
        if map.mapname==name then
            mapInfo=map
            break
        end
    end
    return mapInfo
end

local function show(params)
end

local function hide()
end

local function LoadWorldMap()
    local UITexture_Area=m_Fields.UITexture_Area
    UITexture_Area:SetIconTexture(cfg.map.WorldMap.WORLDMAP_PATH)
	
    local UIPanel_Clip=m_Fields.UIPanel_Clip
	
	
	local realViewSize = Util.GetScreenSize()

	--UIPanel_Clip:SetRect(0,0,realViewSize.x,realViewSize.y)
	local multipleX = realViewSize.x/1280
	local multipleY = realViewSize.y/720
	
	local tempmultiple = 1280/720
	
	local targetmultiple = realViewSize.x/realViewSize.y
	
	printyellow("viewSize",tostring(realViewSize.x),tostring(realViewSize.y))
    local textureW=UITexture_Area.width
    local textureH=UITexture_Area.height
	
	
    local clipRange=UIPanel_Clip:GetViewSize()

	
    local marginHeight=(textureH-clipRange.y)/2
    local marginWidth=(textureW-clipRange.x)/2
	
	--UIRoot基础是以1280X720做基础适应所以算的只能是以1280这个尺寸作为基础
	--这边可以做一张表去做每一个尺寸的自适应因为基于1280乘720相除的话得到的尺寸不太精确所以减一百
	if realViewSize.x == 1624 and realViewSize.y == 750 then
		printyellow(">>>>>>>>>>>>marginWidth",marginWidth)
		if targetmultiple > tempmultiple then
		 marginWidth = marginWidth/multipleX - 100
		printyellow(">>>>>>>>>>>>marginWidth",marginWidth)
		end
		
		if targetmultiple < tempmultiple then
			marginHeight = marginHeight/multipleY 
		end
	
	else
		if targetmultiple > tempmultiple then
		 marginWidth = marginWidth/multipleX - 100
		end
		
		if targetmultiple < tempmultiple then
			marginHeight = marginHeight/multipleY - 100
		end
	
	end
	
	
    EventHelper.SetDrag(m_Fields.UITexture_Area,function(go,delta)
        local targetPos=UITexture_Area.transform.localPosition
        if ((targetPos.y+delta.y)<=-marginHeight) then
            targetPos.y=-marginHeight
        elseif ((targetPos.y+delta.y)>=marginHeight) then
            targetPos.y=marginHeight
        else
            targetPos.y=targetPos.y+delta.y
        end
		
        if ((targetPos.x+delta.x)<=-marginWidth) then
            targetPos.x=-marginWidth
        elseif ((targetPos.x+delta.x)>=marginWidth) then
            targetPos.x=marginWidth
        else
            targetPos.x=targetPos.x+delta.x
        end           
        UITexture_Area.transform.localPosition=targetPos
		
    end)
    for i=0,(UITexture_Area.transform.childCount-1) do
        local oneMap=UITexture_Area.transform:GetChild(i).gameObject.transform
        local UISprite_NameBG=oneMap:Find("UISprite_NameBG")
        if UISprite_NameBG then
            local UILabel_Name=UISprite_NameBG:Find("UILabel_Name"):GetComponent("UILabel")
            local mapName=UILabel_Name.text      
            local mapInfo=GetMapInfoByName(mapName)
            local UIButton_Map=oneMap:GetComponent("UIButton")
            local UILabel_Level=oneMap:Find("UILabel_Level"):GetComponent("UILabel")
            local UISprite_Map=oneMap:GetComponent("UISprite")
            local UISprite_DisabledMap=oneMap:Find("UISprite_Disabled"):GetComponent("UISprite")
            local UISprite_Select_Effect=oneMap:Find("UISprite_Select_Effect"):GetComponent("UISprite")
            UISprite_Select_Effect.gameObject:SetActive(false)
            if mapInfo then          
                UILabel_Level.text= mapInfo.openlevel..(LocalString.WorldMap_Level)       
                if PlayerRole:Instance().m_Level>=mapInfo.openlevel then
                    if UISprite_DisabledMap then
                        UISprite_DisabledMap.gameObject:SetActive(false)
                    end
                    UISprite_Select_Effect.gameObject:SetActive(mapInfo.id==PlayerRole:Instance():GetMapId())
                    EventHelper.SetClick(UIButton_Map,function()
                        local mapId=mapInfo.id
                        if mapId~=PlayerRole:Instance():GetMapId() then
                           -- local TeamManager = require("ui.team.teammanager")
                            local tip=string.format(LocalString.WorldMap_SureCut,mapName)
                                UIManager.ShowAlertDlg({immediate = true,title="",content=tip,callBackFunc=function()
                                    MapManager.EnterMap(mapId,0)
                                end})                    
                        else
                            local dlgflytext = require "ui.dlgflytext"
                            dlgflytext.AddSystemInfo(LocalString.WorldMap_InTheMap)
                        end
                    end)
                else               
                    if UISprite_DisabledMap then
                        UISprite_DisabledMap.gameObject:SetActive(true)
                    end
                    EventHelper.SetClick(UIButton_Map,function()
                        UIManager.ShowSystemFlyText((mapInfo.openlevel)..(LocalString.WorldMap_OpenLevel))
                    end)
                end  
            else 
                oneMap.gameObject:SetActive(false)                   
                UIButton_Map.isEnabled=false         
            end 
        end      
    end
end

local function destroy()
end

local function refresh(params)
    LoadWorldMap()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)          
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}