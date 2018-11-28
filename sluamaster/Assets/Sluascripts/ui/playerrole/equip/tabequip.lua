local unpack              = unpack
local print               = print
local format              = string.format
local EventHelper         = UIEventListenerHelper
local UIManager           = require("uimanager")
local BagManager          = require("character.bagmanager")
local Define              = require("define")
local network             = require("network")
local login               = require("login")
local Player              = require("character.player")
local PlayerRole          = require("character.playerrole")
local ItemIntroduct       = require("item.itemintroduction")
local HumanoidAvatar      = require("character.avatar.humanoidavatar")
local ItemManager         = require("item.itemmanager")
local ItemEnum 		      = require("item.itemenum")
local GameEvent           = require("gameevent")
local ModuleLockManager   = require("ui.modulelock.modulelockmanager")
local ConfigManager       = require("cfg.configmanager")
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")
local Functionalswitch    = require("functionalswitch")
--local GemstoneManager     = require("ui.playerrole.gemstone.gemstonemanager") -- 宝石


local gameObject
local name
local fields

local g_Player
local g_bPreLoaded = { }

local SLOT2TYPE = 
{
	[1] = ItemEnum.EquipType.Weapon,
	[2] = ItemEnum.EquipType.Hat,
	[3] = ItemEnum.EquipType.Cloth,
	[4] = ItemEnum.EquipType.Shoe,
	[5] = ItemEnum.EquipType.Ring,
	[6] = ItemEnum.EquipType.Ring,
	[7] = ItemEnum.EquipType.Necklace,
	[8] = ItemEnum.EquipType.Bangle,
}

--模型加载
local function OnModelLoaded(go)
	if not g_Player and not g_Player.m_Object then return end

	local playerTrans = g_Player.m_Object.transform
	playerTrans.parent = fields.UITexture_PlayerModel.transform
	playerTrans.localScale = Vector3.one * 150
	playerTrans.localPosition = Vector3(-5, -200, -170)
	playerTrans.rotation = Quaternion.Euler(-90,0,0)
	ExtendedGameObject.SetLayerRecursively(g_Player.m_Object, Define.Layer.LayerUICharacter)
end

local function RefreshModel()
	g_Player:ChangeArmour(PlayerRole:Instance().m_Dress,PlayerRole:Instance().m_Equips)
	g_Player:LoadWeapon(PlayerRole:Instance().m_Equips)
end

local function RefreshPlayerInfo()
	fields.UILabel_PlayerLV.text = PlayerRole:Instance():GetLevel()
	fields.UILabel_PlayerName.text = PlayerRole:Instance():GetName()
	fields.UILabel_Power.text = PlayerRole:Instance():GetPower()
end

--获取武器的表格
local function ResetPlayerEquipSlotList()
	for i = 1, fields.UIList_Equipment.Count do
		local listItem = fields.UIList_Equipment:GetItemByIndex(i - 1)
		listItem:SetIconTexture("null")
		listItem:SetText("UILabel_AnnealLevel", "+0")
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(false)
		listItem.Controls["UISprite_Quality"].spriteName = "N_CoverSprite_ItemQuality"
		listItem:GetLabel(format("UILabel_%02d", i)).gameObject:SetActive(true)
        listItem.Controls["UILabel_NotOpen"].gameObject:SetActive(false)
	end
end

--设置武器的信息
local function ResetPlayerEquipSlot(equipPos)
	local listItem = fields.UIList_Equipment:GetItemByIndex(equipPos - 1)
	if listItem then
		listItem:SetIconTexture("null")
		listItem:SetText("UILabel_AnnealLevel", "+0")
		listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(false)
		return true
	end
	return false
end

local function RefreshPlayerEquip()
	ResetPlayerEquipSlotList()
    local curTabIndex = UIManager.gettabindex("playerrole.dlgplayerrole")
    if curTabIndex == 5 then  -- 宝石界面
    	for equipSlot = 1, fields.UIList_Equipment.Count do
		    local listItem = fields.UIList_Equipment:GetItemByIndex(equipSlot - 1)      
		        local equip = BagManager.GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,equipSlot)
		        if equip ~= nil then

			        -- 隐藏装备类型字体
			        listItem:GetLabel(format("UILabel_%02d", equipSlot)).gameObject:SetActive(false)
			        listItem:SetIconTexture(equip:GetTextureName())
			
			        if equip:GetAnnealLevel() ~= 0 then 
				        listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
				        listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
			        else
				        listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
				        listItem:SetText("UILabel_AnnealLevel", "")
			        end
			        -- 设定绑定类型
			        listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())

			        -- 设置品质
			        listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
			        listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())
		        end
            --end
        end
    else
	    for equipSlot = 1, fields.UIList_Equipment.Count do
		    local listItem = fields.UIList_Equipment:GetItemByIndex(equipSlot - 1)       
		    local equip = BagManager.GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,equipSlot)
			if equip ~= nil then
				listItem.Controls["UISprite_BG"].gameObject:SetActive(false)
				-- 隐藏装备类型字体
				listItem:GetLabel(format("UILabel_%02d", equipSlot)).gameObject:SetActive(false)
				listItem:SetIconTexture(equip:GetTextureName())

				if equip:GetAnnealLevel() ~= 0 then
					listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
					listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
				else
					listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
					listItem:SetText("UILabel_AnnealLevel", "")
				end
				-- 设定绑定类型
				listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())

				-- 设置品质
				listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
				listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())
			else
				listItem.Controls["UISprite_BG"].gameObject:SetActive(true)
			end
		    -- 有装备装载上,播放UI特效
		    if (equip ~= nil ) and (not g_bPreLoaded[equipSlot] or g_bPreLoaded[equipSlot] ~= equip ) then
			    local loadEffectObj = GameObject.Instantiate(fields.UIGroup_LoadEquipEffect.gameObject) 
			    loadEffectObj.transform.parent = listItem.transform
				loadEffectObj.transform.localScale = Vector3.one
			    loadEffectObj.transform.localPosition = Vector3.zero			    
			    UIManager.PlayUIParticleSystem(loadEffectObj)
			    -- 播放完毕后释放资源
			    local effect_EventId = 0
			    effect_EventId = GameEvent.evt_update:add(function()
				    if not UIManager.IsPlaying(loadEffectObj) then
					    GameEvent.evt_update:remove(effect_EventId)
					    GameObject.Destroy(loadEffectObj)
				    end
			    end)			
		    end
		    g_bPreLoaded[equipSlot] = equip
	    end
    end
end

--加强装备的状态
local function RefreshButtonStatus(uiList)
	for index = 0,uiList.Count-1 do
		local buttonItem = uiList:GetItemByIndex(index)
		local funcType = nil 
		if index == 0 then 
			funcType = cfg.ui.UIFunctionList.BAG_AMULET			--背包护符
		elseif index == 1 then 
			funcType = cfg.ui.UIFunctionList.BAG_JADE			--背包玉佩
		elseif index == 2 then 
			funcType = cfg.ui.UIFunctionList.BAG_GANGQI			--背包罡气
		elseif index == 3 then 
			funcType = cfg.ui.UIFunctionList.BAG_FASHEN			--背包法身
		end
		local configData = ConfigManager.getConfigData("uifunctionopen", funcType)
		local conditionData = ConfigManager.getConfigData("moduleunlockcond",configData.conid)
		local status = ModuleLockManager.GetUIFuncStatusByType(funcType)
		if status == defineenum.ModuleStatus.LOCKED then
			-- 未解锁
			if configData.opentype == cfg.ui.FunctionOpenType.APPEAR then
				buttonItem.gameObject:SetActive(false)
			elseif configData.opentype == cfg.ui.FunctionOpenType.UNLOCK then
				local lockObj = buttonItem.Controls["UISprite_Lock"]
				lockObj.gameObject:SetActive(true)
				EventHelper.SetClick(buttonItem, function()
					if conditionData then 
						local text = ""
						if conditionData.openlevel ~= 0 then
							text =(conditionData.openlevel) ..(LocalString.WorldMap_OpenLevel)
						elseif conditionData.opentaskid ~= 0 then
							local taskData = ConfigManager.getConfigData("task", conditionData.opentaskid)
							if taskData then
								text = string.format(LocalString.CompleteTaskOpen, taskData.basic.name)
							end
						end
						UIManager.ShowSystemFlyText(text)
					end
				end )
			end
		elseif status == defineenum.ModuleStatus.UNLOCK then
			-- 已解锁
			if configData.opentype == cfg.ui.FunctionOpenType.APPEAR then
				buttonItem.gameObject:SetActive(true)
			elseif configData.opentype == cfg.ui.FunctionOpenType.UNLOCK then
				local lockObj = buttonItem.Controls["UISprite_Lock"]
				if lockObj then
					lockObj.gameObject:SetActive(false)
				end
			end
			--注册相应函数
			if index == 0 then 
				-- 护符
				EventHelper.SetClick(buttonItem, function()
					 UIManager.showdialog("playerrole.equip.dlgamuletenhance")
				end)
			elseif index == 1 then 
				-- 玉佩
				EventHelper.SetClick(buttonItem, function()
					-- UIManager.showdialog("playerrole.equip.dlgjadeenhance")
				end)
			elseif index == 2 then 
				-- 罡气			
				EventHelper.SetClick(buttonItem, function()
					UIManager.showdialog("pureair.dlgpureair")
				end)
			elseif index == 3 then 
				-- 法身
				EventHelper.SetClick(buttonItem, function()
					UIManager.showdialog("dharmakaya.dlgdharmakaya")
				end)
			end
		end
	end 
end

local function refresh(params)
	PCLog.Log(print("tab equipinfo"))
	RefreshPlayerInfo()
	RefreshPlayerEquip()
	RefreshButtonStatus(fields.UIList_Enhance)
	RefreshModel()
	PlayerRole:Instance():LoadWeapon( PlayerRole:Instance().m_Dress,PlayerRole:Instance().m_Equips)
end
local function update()
	if g_Player and g_Player.m_Object and g_Player.m_Avatar then
		g_Player.m_Avatar:Update()
	end
end
local function destroy()
	if g_Player then
		g_Player:release()
		g_Player = nil
	end
end
local function show(params)
	
	if g_Player then
		g_Player:release()
		g_Player = nil
	end
	-- 初始化模型
	g_Player = Player:new(true)
	g_Player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	g_Player:RegisterOnLoaded(OnModelLoaded)
	g_Player:init(PlayerRole:Instance().m_Id, PlayerRole:Instance().m_Profession, PlayerRole:Instance().m_Gender,false,
        PlayerRole.Instance().m_Dress,PlayerRole.Instance().m_Equips,nil,0.75)
	-- 初始化数据
	for equipSlot = 1, fields.UIList_Equipment.Count do
		local equip = BagManager.GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,equipSlot)
		g_bPreLoaded[equipSlot] = equip
	end
end
local function hide()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)
	--时装
	EventHelper.SetClick(fields.UIButton_Fashion, function()
		UIManager.showdialog("dlgfashion",{fashiontype="role"})
	end )

	--坐骑
	EventHelper.SetClick(fields.UIButton_Riding, function()
		UIManager.showdialog("ride.dlgridedisplay")
	end )

	EventHelper.SetDrag(fields.UITexture_PlayerModel, function(go, delta)
		if g_Player and g_Player.m_Object then
			local vecRotate = Vector3(0, - delta.x, 0)
			g_Player.m_Object.transform.localEulerAngles = g_Player.m_Object.transform.localEulerAngles + vecRotate
		end
	end )
	
	EventHelper.SetListClick(fields.UIList_Equipment, function(listItem)
		local playerEquip = BagManager.GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,listItem.Index + 1)
		EquipEnhanceManager.SetEquip(playerEquip)

        local curTabIndex = UIManager.gettabindex("playerrole.dlgplayerrole")
        if curTabIndex == 5 then 
			--todo:宝石功能 还未开放
            --GemstoneManager.SetEquipSlot(listItem.Index + 1)
            --UIManager.refresh("playerrole.gemstone.tabgemstone")
            return 
        end
            
		if playerEquip ~= nil then

			local equipUnloadFunc = function()
				BagManager.SendCUnloadEquip(listItem.Index + 1)
			end

			local enhanceEquipFunc = function()

				local detailType = playerEquip:GetDetailType()
                if detailType == ItemEnum.EquipType.Bangle or
					detailType == ItemEnum.EquipType.Necklace or
                    detailType == ItemEnum.EquipType.Ring then
					-- 饰品
					UIManager.showdialog("playerrole.equip.dlgaccessoryenhance")
                elseif detailType == ItemEnum.EquipType.Weapon or
						detailType == ItemEnum.EquipType.Cloth or 
						detailType == ItemEnum.EquipType.Hat or 
						detailType == ItemEnum.EquipType.Shoe  then
					-- 装备
					UIManager.showdialog("playerrole.equip.dlgequipenhance")
				else
					logError("Equip Type Error!")
				end
			end

			ItemIntroduct.DisplayItem( {
				item = playerEquip,
				buttons =
				{
					{ display = false, text = "", callFunc = nil },
					{ display = true, text = LocalString.BagAlert_UpdateEquip, callFunc = enhanceEquipFunc },
					{ display = true, text = LocalString.BagAlert_UnloadEquip, callFunc = equipUnloadFunc }
				}
			} )
		else
			ItemManager.GetEquipSource(SLOT2TYPE[listItem.Index + 1],"playerrole.dlgplayerrole")
		end
	end )

--	-- 护符、玉佩、法身等
	EventHelper.SetListClick(fields.UIList_Enhance, function(listItem)
		if listItem.Index == 0 then
			-- 护符
			local pageOpenLevel =(ConfigManager.getConfig("amuletconfig")).expandlevel
			if pageOpenLevel[1] > PlayerRole:Instance():GetLevel() then
				UIManager.ShowSystemFlyText(format(LocalString.AmuletWash_WashOpenMinLevel, pageOpenLevel[1]))
			else
				UIManager.showdialog("playerrole.equip.dlgamuletenhance")
			end
		elseif listItem.Index == 1 then
			-- 玉佩
			local jadeOpenLevel =(ConfigManager.getConfig("jadeenhance")).openlevel
			if jadeOpenLevel > PlayerRole:Instance():GetLevel() then
				UIManager.ShowSystemFlyText(format(LocalString.JadeEnhance_EnhanceOpenMinLevel, jadeOpenLevel))
			else
				UIManager.showdialog("playerrole.equip.dlgjadeenhance")
			end

		elseif listItem.Index == 2 then
			UIManager.ShowSystemFlyText(LocalString.Bag_NotOpen)
		elseif listItem.Index == 3 then
			UIManager.ShowSystemFlyText(LocalString.Bag_NotOpen)
		end

	end )

	
	for i = 2, 3 do
		local listItem = fields.UIList_Enhance:GetItemByIndex(i)
		local state = Functionalswitch:GetSwitchState()
		listItem.gameObject:SetActive(state)
	end
end

return {
	init         = init,
	show         = show,
	hide         = hide,
	update       = update,
	destroy      = destroy,
	refresh      = refresh,
	RefreshModel = RefreshModel,
	showtab      = showtab,
	hidetab      = hidetab,
    uishowtype   = uishowtype,
}
