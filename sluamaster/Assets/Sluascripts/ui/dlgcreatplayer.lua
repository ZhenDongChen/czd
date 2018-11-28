local unpack = unpack
local print = print
local math = math
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local utils = require("common.utils")
local Player = require("character.player")
local ConfigManager = require("cfg.configmanager")
local HumanoidAvatar = require("character.avatar.humanoidavatar")
local characters = require("character.charactermanager")
local Define = require("define")
local CameraManager = require("cameramanager")
local TalismanModel     = require("character.talisman.talisman")


local UIList_FactionSelect
local gameObject
local name
local lateSelect,currentSelect
local fields
local selectedGender --性别
local fractionSelect -- 分数
local CurrentGender -- true male false female
local selectedFaction -- 选择门派
local selectProfession -- 选择职业
local m_player --主角模型对象
local m_talisman --宝物模型对象
local descriptions = {"LoginDescribe_QY","LoginDescribe_TY","LoginDescribe_GW"}

local newFaction --选择新的门派

local ListItems = {} -- 
local randomName = nil
local standTime =0
local isPlayerIdle_logOver = false
local isTalismanfly_logOver = false

local listenerId

---------自身函数  开始-------


local function SetItemsEnable(b)
	--i=3 如果鬼族开启
    for i=1,2 do
        if i ~= selectProfession then
            ListItems[i].Enable = b
        end
    end
    --fields.UIButton_SexSelection.enabled = b
	fields.UIButton_SexSelectionWoman.enabled = b
	fields.UIButton_SexSelectionMan.enabled = b
end



local function hide_UIs()
	fields.UIGroup_UIs.gameObject:SetActive(false)
end



local function show_UIs()
	fields.UIGroup_UIs.gameObject:SetActive(true)
end


local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_TopLeft)
    uimanager.SetAnchor(fields.UIWidget_Bottom)
    uimanager.SetAnchor(fields.UIWidget_BottomRight)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_Right)
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

local function LoadTalisman()
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
		isTalismanfly_logOver = false
		m_talisman:PlayAction(cfg.skill.AnimType.fly_log)
	end)
	local professionData    = ConfigManager.getConfigData("profession",selectProfession)
	local talismanid      = professionData.talismanid
	m_talisman:init2(talismanid, m_player)
end




local function update()
	if m_player and m_player.m_Object then
		m_player.m_Avatar:Update()
	end
	
	if standTime then
		
		if m_player and m_player.m_Object then
		
			if not  isPlayerIdle_logOver then
				 m_player:PlayAction(cfg.skill.AnimType.idle_log)
				isPlayerIdle_logOver = true
			end

			if not m_player:IsPlayingAction(cfg.skill.AnimType.idle_log) then
				--m_player:PlayLoopAction(cfg.skill.AnimType.Stand)
				 m_player:PlayLoopAction(cfg.skill.AnimType.stand_log)
				LoadTalisman()
				 standTime = nil
			end
		end
					
	end

	if not isTalismanfly_logOver then
		if m_talisman and m_talisman.m_Object then
			if not m_talisman:IsPlayingAction(cfg.skill.AnimType.fly_log) then
				m_talisman:PlayLoopAction(cfg.skill.AnimType.stand_log)
				--m_talisman:PlayAction(cfg.skill.AnimType.stand_log)
				isTalismanfly_logOver = true
			end
		end
	end

end



local function RefreshGenderBtn()
	if CurrentGender == true then
		fields.UISprite_ManSelect.gameObject:SetActive(true)
		fields.UISprite_ManDeselect.gameObject:SetActive(false)
		fields.UISprite_WomanSelect.gameObject:SetActive(false)
		fields.UISprite_WomanDeselect.gameObject:SetActive(true)
	else
		fields.UISprite_ManSelect.gameObject:SetActive(false)
		fields.UISprite_ManDeselect.gameObject:SetActive(true)
		fields.UISprite_WomanSelect.gameObject:SetActive(true)
		fields.UISprite_WomanDeselect.gameObject:SetActive(false)
	end

	--fields.UISprite_Man.gameObject:SetActive(not CurrentGender)
	--fields.UISprite_Woman.gameObject:SetActive(CurrentGender)
end


--模型加载出来之后开始加载模型的武器注释武器绑定在模型上面是根据ID来绑定的
local function OnModelLoaded(go)
    if not m_player.m_Object then return end
    local playerTrans         = m_player.m_Object.transform
   
	playerTrans.localScale    = Vector3(2.5, 2.5, 2.5)
    playerTrans.position = Vector3(-0.1, -4.1, 22)
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
    m_player:RefreshAvatarObject()
    --m_player.m_Avatar:Arm(selectedFaction,HumanoidAvatar.EquipDetailType.CREATEWEAPON)
    if m_player.m_ShadowObject then
        m_player.m_ShadowObject:SetActive(false)
    end

	local tempChoosePlayerBG = LuaHelper.FindGameObject("ChoosePlayerBG").transform:Find("ChoosePlayerBG")
	local tempposition = characters:GetCharacterManagerObject().transform.position + Vector3(0,0,55)
	tempChoosePlayerBG.transform.parent.position = tempposition
	tempChoosePlayerBG.gameObject:SetActive(true)
	SetItemsEnable(true)
	if  m_talisman and m_talisman.m_Object then
		m_talisman:release()
	end

end




local function RefreshModel()
	if  m_player and m_player.m_Object then
		m_player:release()
	end
	selectProfession = newFaction or selectProfession
	
	fields.UITexture_Describe:SetIconTexture(descriptions[selectProfession])
	local newGender = CurrentGender and 0 or 1
	selectedFaction,selectedGender = selectProfession,newGender
	
	m_player = Player:new(true)
    m_player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_player:RegisterOnLoaded(OnModelLoaded)
	m_player:init(0,selectedFaction,selectedGender,nil,nil,{},true)
	standTime = 0
	isPlayerIdle_logOver = false
    SetItemsEnable(false)


end

local function refresh(params)
	
    CurrentGender = true
    RefreshGenderBtn()
    RefreshModel()
end



---------自身函数  结束-------



---------收发协议模块 开始-----------

local function onmsg_RandomName(msg)
    randomName = msg.name
    fields.UIInput_Name.value = randomName
end


---------收发模块模块  结束-----

local function show(params)
	selectProfession = 1
	print("createPlayer show")
	fields.UIList_FactionSelect:SetSelectedIndex(0)

	
    network.send(lx.gs.login.CRandomName({gender=gender}))
	
end

local function init(params)
	
	name, gameObject, fields = unpack(params)
	SetAnchor(fields)

	--屏蔽未开启种族
	fields.UIButton_RaceLock.gameObject:SetActive(false)


	for i = 1,3 do
		local item = fields.UIList_FactionSelect:GetItemByIndex(i-1)
		ListItems[i] = item
	end
	math.randomseed(os.time())


	listenerId = network.add_listener("lx.gs.login.SRandomName",onmsg_RandomName)
	fields.UIList_FactionSelect:SetSelectedIndex(0)
	selectedGender = 1
	selectedFaction = 0
	
	
	EventHelper.SetClick(fields.UIButton_Play, function ()
		local rolename          = fields.UILabel_Name.text
		local roleprofession    = selectProfession
		local gender            = CurrentGender and 0 or 1
		local bLegal,sInfo 		= utils.CheckName(rolename)
		if bLegal then
			login.create_role(sInfo,roleprofession,gender)		
		else

			uimanager.ShowSingleAlertDlg{content = sInfo}
		end
	end)
	
	EventHelper.SetClick(fields.UIButton_Return, function ()
		local roles = login:get_roles()
		uimanager.hide(name)
    if #roles >0 then
		uimanager.show("dlgchooseplayer",true)
    else
		hide_UIs()
        CameraManager.LoginPush("dlgcreatplayer")
    end
  end)

		EventHelper.SetClick(fields.UIButton_Random,function()
		local gender = CurrentGender and 0 or 1
		local re = lx.gs.login.CRandomName({gender = gender})
		
		network.send(re)
	end)
	
	EventHelper.SetClick(fields.UIButton_SexSelectionMan,function()
		--CurrentGender = not CurrentGender
		if CurrentGender == true then return end
		CurrentGender = true
		local gender = CurrentGender and 0 or 1
		RefreshGenderBtn()
		RefreshModel()
		local gender = CurrentGender and 0 or 1
		local re = lx.gs.login.CRandomName({gender = gender})

		network.send(re)
	end)

	EventHelper.SetClick(fields.UIButton_SexSelectionWoman,function()
		--CurrentGender = not CurrentGender
		if CurrentGender == false then return end
		CurrentGender = false
		local gender = CurrentGender and 0 or 1
		RefreshGenderBtn()
		RefreshModel()
		local gender = CurrentGender and 0 or 1
		local re = lx.gs.login.CRandomName({gender = gender})

		network.send(re)
	end)
	
	  EventHelper.SetListSelect(fields.UIList_FactionSelect,function(item)
          newFaction = item.m_nIndex + 1
		  item.transform:GetChild(1).gameObject:SetActive(true)
		  item.transform:GetChild(2).gameObject:SetActive(false)
		  local childCount =  fields.UIList_FactionSelect.transform.childCount
		  for i = 0, childCount-1 do
			  if i ~=item.m_nIndex then
				  local tempItemTransform = fields.UIList_FactionSelect.transform:GetChild(i)
				  tempItemTransform:GetChild(1).gameObject:SetActive(false)
				  tempItemTransform:GetChild(2).gameObject:SetActive(true)
			  end
		  end
          RefreshModel()
  end)


	  EventHelper.SetDrag(fields.UISprite_PlayerModel,function(o,delta)
        --CameraManager.Rotate(delta.x,delta.y/20)
		local tempcharacters = characters:GetCharacterManagerObject()
		local tempcharactersTransform = tempcharacters.transform:GetChild(0)
		tempcharactersTransform.transform:Rotate(0,0,-delta.x)
    end)

	EventHelper.SetClick(fields.UIButton_RaceLock, function ()
		uimanager.ShowSystemFlyText( "暂未开启，敬请期待")
	end)

	fields.UITexture_DescribeBG:SetIconTexture("LoginDescribe_BG")
end


local function destroy()
  --print(name, "destroy")
	network.remove_listener(listenerId)
end


local function getPlayerObj()
	return m_player
end

local function getTalismanObj()
	return m_talisman
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
	getPlayerObj = getPlayerObj,
	getTalismanObj = getTalismanObj
}