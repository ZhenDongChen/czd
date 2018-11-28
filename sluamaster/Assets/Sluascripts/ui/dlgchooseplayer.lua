local unpack = unpack
local uimanager = require("uimanager")
local EventHelper = UIEventListenerHelper
local network = require("network")
local login	= require("login")
local Player = require ("character.player")
local HumanoidAvatar = require("character.avatar.humanoidavatar")
local CameraManager = require("cameramanager") 
local defineenum = require("defineenum") 
local Define = require("define") 
local Resourcemanager = require("resource.resourcemanager")
local characters = require("character.charactermanager")
local TalismanModel     = require("character.talisman.talisman")
local ConfigManager = require("cfg.configmanager")

local selectedRoleID
local name 
local gameObject
local fields
local currRoles
local m_player
local m_talisman --宝物模型对象
local playerModel
local obj_dlgDel
local fractionSelects
local canloadnewmodel
local CharacterType = defineenum.CharacterType
local TimeUtils = require"common.timeutils"
local ListItems = {}

local function SetItemsEnable(b)
    for i=1,4 do
        if i ~= selectedRoleID then
            ListItems[i].item.Enable = b
        end
    end
    ListItems[selectedRoleID].item.Checked = b
end

--保留时间
local function GetRemainTime(delTime)
    local serverTime = TimeUtils.GetServerTime()
    local removeTime = delTime + 3600*24*3
    return (removeTime - serverTime)
end

local function GetRemainDeleteDateTimeStr(remainTime)
    local datetime = TimeUtils.getDateTime(remainTime)
    return string.format(LocalString.Login_Delete_Time,datetime.days,datetime.hours,datetime.minutes,datetime.seconds)
end

local function OnModelLoaded(go)

    if not m_player or not m_player.m_Object then return end
	
    local playerTrans         = m_player.m_Object.transform
    playerTrans.localScale    = Vector3(2.5, 2.5, 2.5)
    playerTrans.position =  Vector3(-0.1, -4.1, 22)
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
    m_player:RefreshAvatarObject()
    canloadnewmodel = true
    if m_player.m_ShadowObject then
        m_player.m_ShadowObject:SetActive(false)
    end
	standTime = 0
    IdleTime = 0
	isPlayerIdle_logOver = false
    SetItemsEnable(true)
	
	local tempChoosePlayerBG = LuaHelper.FindGameObject("ChoosePlayerBG").transform:Find("ChoosePlayerBG")
	local tempposition = characters:GetCharacterManagerObject().transform.position + Vector3(0,0,55)
	tempChoosePlayerBG.transform.parent.position = tempposition
	tempChoosePlayerBG.gameObject:SetActive(true)


    if  m_talisman and m_talisman.m_Object then
        m_talisman:release()
    end
    m_talisman = TalismanModel:new()

    m_talisman.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_talisman:RegisterOnLoaded(function(asset_obj)
        asset_obj:SetActive(true)
        --asset_obj.transform.parent = self.fields.UITexture_TalismanModel.gameObject.transform
		asset_obj.transform.localScale = Vector3(2.5, 2.5, 2.5)
        asset_obj.transform.localPosition = Vector3(-3, 0, 22)
        asset_obj.transform.rotation = Quaternion.Euler(-90,0,0)
        --ExtendedGameObject.SetLayerRecursively(asset_obj, define.Layer.LayerUICharacter)
    end)

    if currRoles[selectedRoleID].talismanid ~= 0 then
        m_talisman:init2(currRoles[selectedRoleID].talismanid, m_player)
    end


end



local function RefreshModel()	

	if m_player then 
		m_player:release() 
	end
	
    if not currRoles[selectedRoleID] then
        fields.UIButton_DeletePlayer.gameObject:SetActive(false)
        return
    end
	canloadnewmodel = true

    if currRoles[selectedRoleID].deltime then
        local remainTime = GetRemainTime(currRoles[selectedRoleID].deltime)
        if remainTime and remainTime>0  then
            fields.UIButton_DeletePlayer.gameObject:SetActive(false)
        else
            fields.UIButton_DeletePlayer.gameObject:SetActive(true)
        end
    else
        fields.UIButton_DeletePlayer.gameObject:SetActive(true)
    end
	
	m_player = Player:new(false)
    m_player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_player:RegisterOnLoaded(OnModelLoaded)
    local roleInfo = currRoles[selectedRoleID]
    m_player:init(roleInfo.roleid,roleInfo.profession,roleInfo.gender,nil,roleInfo.dressid,roleInfo.equips)
    SetItemsEnable(false)
end


local function hide_UIs()
	fields.UIGroup_UIs.gameObject:SetActive(false)
end

local function show_UIs()
	fields.UIGroup_UIs.gameObject:SetActive(true)
end

local function SetAnchor(fields)
uimanager.SetAnchor(fields.UIWidget_TopLeft)
uimanager.SetAnchor(fields.UIWidget_BottomRight)

end



local function hide()
    if m_player then
        m_player:release()
        m_player = nil
    end
    if m_talisman then
        m_talisman:release()
        m_talisman = nil
    end
end

local function refresh(params)
      -- printyellow("refresh")
    local roles = login:get_roles()
    for i =1,4 do
        local uigroup_select = ListItems[i].item.Controls["UIGroup_Select"]
        local uilabel_create = ListItems[i].item.Controls["UILabel_Create"]
        local needCreate = true
        currRoles= roles
        if roles and roles[i] then
            needCreate = false
            if not needCreate then
                ListItems[i].spriteVip.gameObject:SetActive((not shouldHideVip()) and roles[i].viplevel > 0)
                ListItems[i].labelName.text = roles[i].rolename
                ListItems[i].labelVip.text = roles[i].viplevel
                ListItems[i].labelLevel.text = roles[i].level
                local professionInfo = ConfigManager.getConfigData("profession",roles[i].profession)
                local modelname = cfg.role.GenderType.MALE == roles[i].gender and professionInfo.modelname or professionInfo.modelname2
                local icon = ConfigManager.getConfigData("model",modelname).headicon
                ListItems[i].item:SetIconTexture(icon)
                ListItems[i].item.Enable = true
                if roles[i].deltime then					
                    local remainTime = GetRemainTime(roles[i].deltime)
                    if remainTime and remainTime>0  then
                        ListItems[i].btnRecover.gameObject:SetActive(true)
                        EventHelper.SetClick(ListItems[i].btnRecover,function()
                            uimanager.ShowAlertDlg{
                                content = LocalString.Login_RecoverDelRole,
                                callBackFunc = function()
                                    network.send(lx.gs.login.CCancelDelteRole{roleid=roles[i].roleid})
                                end
                            }
                        end)
                        ListItems[i].deltime = roles[i].deltime
                    else
                        ListItems[i].btnRecover.gameObject:SetActive(false)
                    end
                else
                    ListItems[i].btnRecover.gameObject:SetActive(false)
                end
            else
                ListItems[i].btnRecover.gameObject:SetActive(false)
                ListItems[i].item.Enable = false
            end
        else
            ListItems[i].btnRecover.gameObject:SetActive(false)
        end
        NGUITools.SetActive(uigroup_select.gameObject,not needCreate)
        NGUITools.SetActive(uilabel_create.gameObject,needCreate)
    end
    RefreshModel()

	--print("chooseplayer refresh over")
end

local function update()
	if m_player and m_player.m_Avatar then
        m_player.m_Avatar:Update()
    end



	if standTime then
		
		if m_player and m_player.m_Object then
		
			if not  isPlayerIdle_logOver then
				 m_player:PlayAction(cfg.skill.AnimType.idle_log)
				isPlayerIdle_logOver = true
			end

			if not m_player:IsPlayingAction(cfg.skill.AnimType.idle_log) then
				  m_player:PlayLoopAction(cfg.skill.AnimType.Stand)
				 standTime = nil
			end
		end
					
	end	
	local bNeedRefresh = false
    for i=4,1,-1 do
        if ListItems[i] then
            if ListItems[i].deltime then
                local remainTime = GetRemainTime(ListItems[i].deltime)
                if remainTime < -10 then
                    ListItems[i].btnRecover.gameObject:SetActive(false)
                    ListItems[i].deltime = nil
                    table.remove(roles,i)
                    bNeedRefresh = true
                elseif remainTime>0 and remainTime <= 24*3600*3 then
                    ListItems[i].labelDeleteTime.text = GetRemainDeleteDateTimeStr(remainTime)
                end
            end
        end
    end


    if bNeedRefresh then
       refresh()
    end
 
end

local function init(params)
	
	name, gameObject, fields = unpack(params)
    SetAnchor(fields)
	fields.UIList_FactionSelect:SetSelectedIndex(0)
    for i=1,4 do
        local item = fields.UIList_FactionSelect:GetItemByIndex(i-1)
        ListItems[i] = {}
        ListItems[i].item = item
        item.Controls["UISprite_VIP"].gameObject:SetActive(not shouldHideVip())
        ListItems[i].btnRecover = item.Controls["UIButton_Recovery"]
        ListItems[i].spriteVip = item.Controls["UISprite_VIP"]
        ListItems[i].labelDeleteTime = item.Controls["UILabel_DeleteTime"]
        ListItems[i].labelName = item.Controls["UILabel_Name"]
        ListItems[i].labelLevel = item.Controls["UILabel_LV"]
        ListItems[i].labelVip = item.Controls["UILabel_VIP"]
    end
	
	
	

	EventHelper.SetListClick(fields.UIList_FactionSelect,function(item)
        local index = item.m_nIndex
        local roles = login:get_roles()
        if roles and roles[index+1] then
            selectedRoleID = index+1
            if canloadnewmodel then
                canloadnewmodel = false
                RefreshModel()
            end
            --refresh info and recreate player model
        else
            uimanager.show("dlgcreatplayer",true)
            uimanager.destroy(name)
        end
    end)
	
	 EventHelper.SetClick(fields.UIButton_DeletePlayer,function()
        local roles = login:get_roles()
        if roles and roles[selectedRoleID] then
            uimanager.show("dlgalert_reminder",{content=LocalString.Login.DeleteRole,callBackFunc=function()
                login.remove_role(selectedRoleID)
            end})
        end
    end)
	
	
	 EventHelper.SetClick(fields.UIButton_Return,function()
        local roles = login:get_roles()
		hide_UIs()
        CameraManager.LoginPush("dlgchooseplayer")
    end)
	
	
	 EventHelper.SetClick(fields.UIButton_Play, function ()
        local roles = login:get_roles()
        if selectedRoleID <0 or not roles[selectedRoleID] then
            uimanager.ShowSingleAlertDlg({content=LocalString.login.SelectARole})
        else
            login.role_login(selectedRoleID)
        end
    end)
	  EventHelper.SetDrag(fields.UISprite_PlayerModel,function(o,delta)
		local tempcharacters = characters:GetCharacterManagerObject()
		local tempcharactersTransform = tempcharacters.transform:GetChild(0)
		tempcharactersTransform.transform:Rotate(0,0,-delta.x)
    end)

	

    local MapManager=require"map.mapmanager"
    MapManager.PreLoadLoadingTexture()

	
end

local function show(params)
	
	CameraManager.CreatLoginAssist()
    CameraManager.stop()
    standTime = 0
    if not params then
        hide_UIs()
    end

    selectedRoleID = 1
end

local function destroy()

end

return 
{
  init = init,
  show = show,
  hide = hide,
  update = update,
  refresh = refresh,
  show_UIs = show_UIs,
  hide_UIs = hide_UIs,
  destroy = destroy,
}