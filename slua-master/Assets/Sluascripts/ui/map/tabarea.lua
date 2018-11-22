local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ConfigManager=require("cfg.configmanager")
local CharacterManager=require "character.charactermanager"
local MapManager=require("map.mapmanager")
local NetWork = require("network")
local PlayerRole=require("character.playerrole")

local m_GameObject
local m_Name
local m_Fields
local m_NpcItem -- tab����
local m_MonsterItem
local m_WarpItem
local m_WRatio
local m_HRatio
local m_IsExpand  --ģ�ͱ���
local m_UITexture_AreaObj --����ͼ���ĸ��ڵ�
local m_MapId=0
local m_NPCObjList={}
local m_MonsterObjList={}
local m_TeamMemberList={}
local m_RefreshTime=nil

local function LoadNPC()
	local npcObj = m_Fields.UISprite_NPCInAreaMap.gameObject
	local allNpcs = CharacterManager.GetAllNpcsByCsv()
    local UIList_NPC=m_NpcItem.Controls["UIList_Classification"]
	for _,npc in ipairs(allNpcs) do
		--����npc��ͼ��
		local targetObj=NGUITools.AddChild(m_UITexture_AreaObj,npcObj)
		targetObj:SetActive(true)
        table.insert(m_NPCObjList,targetObj)
		targetObj.transform.localPosition=MapManager.GetTransferCoordInArea(npc.position,m_WRatio,m_HRatio)
        local UIListItem_NPC=UIList_NPC:AddListItem()--����UIlist�е�Ԥ��
        UIListItem_NPC.Id=npc.npcid
        UIListItem_NPC.Data=npc.position
		
		--�����ƶ���npc��λ��
		EventHelper.SetClick(UIListItem_NPC,function()
		UIManager.hidedialog("map.dlgmap")
		PlayerRole:Instance():navigateTo({
			targetPos = Vector3(npc.position.x*SCALE_XY,npc.position.y*SCALE_XY,0),
			roleId = npc.npcid,
			newStopLength = 90,
			callback = function ()
			end}	
		)	
	end)
        local UILabel_NPC=UIListItem_NPC.Controls["UILabel_SubName"]
        UILabel_NPC.text=ConfigManager.getConfigData("npc",npc.npcid).name	
	end
	local UISprite_AddInNPC=m_NpcItem.Controls["UISprite_Add"]
    local UISprite_MinusInNPC=m_NpcItem.Controls["UISprite_Minus"]
	if#allNpcs == 0 then
		UISprite_AddInNPC.gameObject:SetActive(false)
		UISprite_MinusInNPC.gameObject:SetActive(false)
	end
	
	    EventHelper.SetClick(m_NpcItem,function()
        m_IsExpand.npcs=not (m_IsExpand.npcs)
        m_IsExpand.warps=false
        m_IsExpand.monsters=false
        if m_IsExpand.npcs==false then --
            local UIToggle=m_NpcItem:GetComponent("UIToggle")
            UIToggle:Set(false)
        end
    end)
	
	
end

--���ӹ���
local function LoadMonsters()
    local monsterObj = m_Fields.UISprite_MonsterInAreaMap.gameObject
    local allMonsters=CharacterManager.GetAllPolygonRegions()
    local UIList_Monsters=m_MonsterItem.Controls["UIList_Classification"]
		
	for _,monster in ipairs(allMonsters) do
		--���ӹ�����ͼ��
		local targetObj=NGUITools.AddChild(m_UITexture_AreaObj,monsterObj)
		targetObj:SetActive(true)
		table.insert(m_MonsterObjList,targetObj)
		targetObj.transform.localPosition = MapManager.GetTransferCoordInArea(monster.position,m_WRatio,m_HRatio)
		local UIListItem_Monster=UIList_Monsters:AddListItem() --����UIlist�е�Ԥ�� ���ص���һ��UIListItem��һ������
		UIListItem_Monster.Data = monster.position
		
		EventHelper.SetClick(UIListItem_Monster,function()
			UIManager.hidedialog("map.dlgmap")
			PlayerRole:Instance():navigateTo({
				targetPos = Vector3(monster.position.x*SCALE_XY,monster.position.y*SCALE_XY,0),
				callback  = function ()
			end
			})
		end)
		
	    local UILabel_Monster=UIListItem_Monster.Controls["UILabel_SubName"]
        UILabel_Monster.text=monster.monsterName.."  ("..monster.level.."级)"
	end
	local UISprite_AddInMonster=m_MonsterItem.Controls["UISprite_Add"]
    local UISprite_MinusInMonster=m_MonsterItem.Controls["UISprite_Minus"]
	    if #allMonsters==0 then
        UISprite_AddInMonster.gameObject:SetActive(false)
        UISprite_MinusInMonster.gameObject:SetActive(false)
    end
    EventHelper.SetClick(m_MonsterItem,function()
        m_IsExpand.monsters=not (m_IsExpand.monsters)
        m_IsExpand.warps=false
        m_IsExpand.npcs=false
        if m_IsExpand.monsters==false then
            local UIToggle=m_MonsterItem:GetComponent("UIToggle")
            UIToggle:Set(false)
        end
    end)
end

local function LoadWarps()
    local allWarps=CharacterManager.GetAllWarps()
    local UIList_Warps=m_WarpItem.Controls["UIList_Classification"]
--    UIList_Warps:Clear()
    for _,warp in ipairs(allWarps) do
--            --���Ӵ��͵�ͼ��
--            local targetObj=NGUITools.AddChild(m_UITexture_AreaObj,monsterObj)
--            targetObj:SetActive(true)
--            targetObj.transform.localPosition=Vector3((warp.position.x)*ratio,(warp.position.z)*ratio,0)
        local UIListItem_Warp=UIList_Warps:AddListItem()
        UIListItem_Warp.Id=warp.id
        UIListItem_Warp.Data=warp.position      
        EventHelper.SetClick(UIListItem_Warp,function()
            PlayerRole:Instance().m_NavigateToWarp=true
            UIManager.hidedialog("map.dlgmap")
            PlayerRole:Instance():navigateTo({
                targetPos = Vector3(warp.position.x * SCALE_XY,warp.position.y * SCALE_XY, 0),
                callback = function ()
                end})
            end)
        local UILabel_Warp=UIListItem_Warp.Controls["UILabel_SubName"]
        UILabel_Warp.text=warp.name
    end
    local UISprite_AddInWarp=m_WarpItem.Controls["UISprite_Add"]
    local UISprite_MinusInWarp=m_WarpItem.Controls["UISprite_Minus"]
    if #allWarps==0 then
        UISprite_AddInWarp.gameObject:SetActive(false)
        UISprite_MinusInWarp.gameObject:SetActive(false)
    end
    EventHelper.SetClick(m_WarpItem,function()
        m_IsExpand.warps=not (m_IsExpand.warps)
        m_IsExpand.monsters=false
        m_IsExpand.npcs=false
        if m_IsExpand.warps==false then
            local UIToggle=m_WarpItem:GetComponent("UIToggle")
            UIToggle:Set(false)
        end
    end)  
end

--�����Ŷӳ�Ա
local function LoadTeamMembers()
   
end
--ˢ���Ŷӳ�Ա��λ��
local function RefreshTeamMemberLocation(params)
    
end

--ˢ������������
local function RefreshOwnPos()

    local playerPos=PlayerRole:Instance():GetPos()
    local rotation=nil
    if PlayerRole:Instance():IsRiding() then
        rotation=PlayerRole:Instance().m_Mount.m_Object.transform.rotation
    else
        rotation=PlayerRole:Instance().m_Object.transform.rotation
    end
	
	local UILabel_Coordinate=m_Fields.UILabel_Coordinate
    UILabel_Coordinate.text=((LocalString.AreaMap_CurCoord)..string.format("%2d",playerPos.x)..(LocalString.AreaMap_CoordSeparator)..string.format("%2d",playerPos.y))
    m_Fields.UISprite_PlayerInAreaMap.transform.localPosition=MapManager.GetTransferCoordInArea(playerPos,m_WRatio,m_HRatio)
    m_Fields.UISprite_PlayerInAreaMap.transform.rotation = Quaternion.Euler(0, 0, - rotation.eulerAngles.y)
end

local function ClearSubObj()
    local UIList_NPC=m_NpcItem.Controls["UIList_Classification"]
    UIList_NPC:Clear()
    local UIList_Monsters=m_MonsterItem.Controls["UIList_Classification"]
    UIList_Monsters:Clear()
    local UIList_Warps=m_WarpItem.Controls["UIList_Classification"]
    UIList_Warps:Clear()
end

local function SelectFirst()

end

local function ClearObj()
    for _,targetObj in pairs(m_NPCObjList) do
        NGUITools.Destroy(targetObj)
    end
    for _,targetObj in pairs(m_MonsterObjList) do
        NGUITools.Destroy(targetObj)
    end
    m_MonsterObjList={}
    m_NPCObjList={}
end

local function LoadAreaMap()
    local width=m_Fields.UITexture_AreaInAreaMap.width
    local height=m_Fields.UITexture_AreaInAreaMap.height
    local sceneName=ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId()).scenename
    local sceneData=ConfigManager.getConfigData("scene",sceneName)
    local scenesizeX=sceneData.scenesizeX
	local scenesizeY=sceneData.scenesizeY
    m_WRatio= width/scenesizeX
    m_HRatio= height/scenesizeY
	 if m_MapId~=PlayerRole:Instance():GetMapId() then
        ClearObj()
        m_MapId=PlayerRole:Instance():GetMapId()
        m_IsExpand={npcs=false,monsters=false,warps=false}
        m_Fields.UIList_Parent:Clear()
        m_NpcItem=m_Fields.UIList_Parent:AddListItem() --����tab����
        m_NpcItem.Controls["UILabel_Name"].text="NPC"
        m_MonsterItem=m_Fields.UIList_Parent:AddListItem()
        m_MonsterItem.Controls["UILabel_Name"].text=LocalString.AreaMap_Monster
        m_WarpItem=m_Fields.UIList_Parent:AddListItem()
        m_WarpItem.Controls["UILabel_Name"].text=LocalString.AreaMap_Warp
        LoadNPC()
        LoadMonsters()
        LoadWarps()
       -- LoadTeamMembers()
        --SelectFirst()
    end
	
	--ˢ��λ��
	RefreshOwnPos()
	local UITexture_AreaInAreaMap = m_Fields.UITexture_AreaInAreaMap
	local iconTextureName = ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId()).scenename
	UITexture_AreaInAreaMap:SetIconTexture(ConfigManager.getConfigData("worldmap",PlayerRole:Instance():GetMapId()).scenename)
	print("bbbb")
end

local function update()
   --if PlayerRole:Instance():IsNavigating() or PlayerRole:Instance():IsFlyNavigating() then
        if m_RefreshTime and (os.time()-m_RefreshTime<1) then
            return
        end
        m_RefreshTime=os.time()
        RefreshOwnPos()
    --end
end

local function show(params)
	
end

local function hide()
	
end

local function refresh(params)

	LoadAreaMap()
end

local function destroy()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
    m_IsExpand={npcs=false,monsters=false,warps=false}
    m_UITexture_AreaObj=m_Fields.UITexture_AreaInAreaMap.gameObject
    local UISprite_LeftBackground=m_Fields.UISprite_LeftBackground
    local UISprite_LeftBackgroundObj=UISprite_LeftBackground.gameObject
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    RefreshTeamMemberLocation = RefreshTeamMemberLocation,
}
