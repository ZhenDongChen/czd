local require        = require
local unpack         = unpack
local print          = print
local math           = math
local utils          = require("common.utils")
local format         = string.format
local GameEvent      = require("gameevent")
local UIManager      = require("uimanager")
local network        = require("network")
local PlayerRole     = require("character.playerrole")
local BagManager     = require("character.bagmanager")
local ConfigManager  = require("cfg.configmanager")
local ItemManager    = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local ItemEnum       = require("item.itemenum")
local CheckCmd       = require("common.checkcmd")
local EventHelper    = UIEventListenerHelper
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")


local gameObject
local name
local fields
-- 全局变量
local g_SelectedItem
local g_SelectedEquipPos
local g_Equips
-- 所有配置里的神器(红色品质装备且等级满足要求(75级，90级...))
local g_UpgradedEquips
local g_SelectedUpgradedEquip
local g_SelectedUpgradeProp1
local g_SelectedUpgradeProp2
local g_Prop3_Validate = false

local ShowEquipUpgrade

local listenerIds

local INDEX_2_EQUIPTYPE = 
{
	[0] = ItemEnum.EquipType.Weapon,
	[1] = ItemEnum.EquipType.Hat,
	[2] = ItemEnum.EquipType.Cloth,
	[3] = ItemEnum.EquipType.Shoe,
}

-- 是否是神器(红色品质装备且等级满足要求(75级，90级...))
local function IsUpgradedEquip(equip)
	local deltaLevel = cfg.equip.Equip.UPGRADE_DELTA_LEVEL
	local minLevel = cfg.equip.Equip.MIN_UPGRADE_LEVEL
	local maxLevel = cfg.equip.Equip.MAX_UPGRADE_LEVEL
	--local level = equip:GetLevel()
	--local quality = equip:GetQuality()
	if equip:IsMainEquip() and (equip:GetQuality() == cfg.item.EItemColor.RED) then
		for level = minLevel,maxLevel,deltaLevel do 
			if equip:GetLevel() == level then
				return true
			end
		end
	end
	return false
end

-- 设置材料1(界面左下角材料)
local function SetUpgradeProp1Box(equip)
	if not equip then
		fields.UISprite_AddProp1.gameObject:SetActive(true)
		fields.UIGroup_Prop1_Slot.gameObject:SetActive(false)
		-- fields.UISprite_Prop1_Binding.gameObject:SetActive(false)
   
		-- fields.UISprite_Prop1_Quality.color = Color(1,1,1,1)
		-- fields.UILabel_Prop1_AnnealLevel.gameObject:SetActive(false)
		-- 设置prop1名字
		if g_SelectedUpgradedEquip then 
			if g_SelectedUpgradedEquip:GetLevel() == cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				fields.UILabel_Prop1Name.text = format(LocalString.EquipEnhance_Upgrade_OrangeEquip,g_SelectedUpgradedEquip:GetLevel())
			elseif g_SelectedUpgradedEquip:GetLevel() > cfg.equip.Equip.MIN_UPGRADE_LEVEL then 
				fields.UILabel_Prop1Name.text = format(LocalString.EquipEnhance_Upgrade_RedEquip,g_SelectedUpgradedEquip:GetLevel()-cfg.equip.Equip.UPGRADE_DELTA_LEVEL)
			end
		else
			fields.UILabel_Prop1Name.text = ""
		end
	else
		fields.UISprite_AddProp1.gameObject:SetActive(false)
		fields.UILabel_Prop1Name.text = equip:GetName()
		fields.UIGroup_Prop1_Slot.gameObject:SetActive(true)
		-- 设置具体属性信息,炼器等级为0，不显示
		-- fields.UILabel_Prop1_AnnealLevel.gameObject:SetActive(true)
		if equip:GetAnnealLevel() == 0 then 
			fields.UILabel_Prop1_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_Prop1_AnnealLevel.text = ""
		else
			fields.UILabel_Prop1_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_Prop1_AnnealLevel.text = "+" .. equip:GetAnnealLevel()
		end
		fields.UITexture_Prop1_Icon:SetIconTexture(equip:GetTextureName())
		-- 绑定类型
		-- fields.UISprite_Prop1_Binding.gameObject:SetActive(true)
		fields.UISprite_Prop1_Binding.gameObject:SetActive(equip:IsBound())
		-- 设置品质
		fields.UISprite_Prop1_Quality.spriteName = colorutil.GetQualitySprite(equip:GetQuality())
	end
end
-- 设置材料2(界面上部材料)
local function SetUpgradeProp2Box(equip,bLocked)
	if bLocked then
		fields.UISprite_Prop2Lock.gameObject:SetActive(true)
		fields.UISprite_AddProp2.gameObject:SetActive(false)
		fields.UILabel_Prop2Name.text = ""
		fields.UIGroup_Prop2_Slot.gameObject:SetActive(false)
	else
		fields.UISprite_Prop2Lock.gameObject:SetActive(false)
		if not equip then
			fields.UISprite_AddProp2.gameObject:SetActive(true)
			fields.UIGroup_Prop2_Slot.gameObject:SetActive(false)
			-- 设置prop2名字
			if g_SelectedUpgradedEquip then 
				if g_SelectedUpgradedEquip:GetLevel() == cfg.equip.Equip.MIN_UPGRADE_LEVEL then
					fields.UILabel_Prop2Name.text = ""
				elseif g_SelectedUpgradedEquip:GetLevel() > cfg.equip.Equip.MIN_UPGRADE_LEVEL then 
					fields.UILabel_Prop2Name.text = format(LocalString.EquipEnhance_Upgrade_OrangeEquip,g_SelectedUpgradedEquip:GetLevel())
				end
			else
				fields.UILabel_Prop2Name.text = ""
			end
		else
			fields.UISprite_AddProp2.gameObject:SetActive(false)
			fields.UILabel_Prop2Name.text = equip:GetName()
			fields.UIGroup_Prop2_Slot.gameObject:SetActive(true)
			-- 设置具体属性信息,炼器等级为0,不显示
			if equip:GetAnnealLevel() == 0 then
				fields.UILabel_Prop2_AnnealLevel.gameObject:SetActive(false)
				fields.UILabel_Prop2_AnnealLevel.text = ""
			else
				fields.UILabel_Prop2_AnnealLevel.gameObject:SetActive(true)
				fields.UILabel_Prop2_AnnealLevel.text = "+" .. equip:GetAnnealLevel()
			end
			fields.UITexture_Prop2_Icon:SetIconTexture(equip:GetTextureName())
			-- 绑定类型
			fields.UISprite_Prop2_Binding.gameObject:SetActive(equip:IsBound())
			-- 设置品质
			fields.UISprite_Prop2_Quality.spriteName = colorutil.GetQualitySprite(equip:GetQuality())
		end
	end
end

-- 设置材料3(目前消耗千华龙筋)
local function SetUpgradeProp3Box(prop1)
	local prop3Id = cfg.equip.Equip.UPGRADE_COST_ITEM

	local allProp3NumInBag = BagManager.GetItemNumById(prop3Id)
	local bHasBindedProp3 = false
	local prop3CostNum = 0
	if prop1 then
		-- 计算龙筋消耗(即prop3消耗)
		local upgradedEquipId = prop1:GetUpgradedEquipId()
		local upgradedEquip = ItemManager.CreateItemBaseById(upgradedEquipId)
		-- 龙筋消耗 = 进阶后的目标装备所携带的龙筋数-进阶前的材料装备所携带的龙筋数
		prop3CostNum = upgradedEquip:GetCarryingItemNum() - prop1:GetCarryingItemNum()
	end
	local prop3 = { }
	-- 背包中有龙筋
	if allProp3NumInBag ~= 0  then 
		-- 判断是否有绑定类型
		local prop3s = BagManager.GetItemById(prop3Id)
		for _,prop in pairs(prop3s) do
			if prop:IsBound() then
				bHasBindedProp3 = true
				break
			end
		end
		prop3 = prop3s[1]
		-- 绑定类型
		fields.UISprite_Prop3_Binding.gameObject:SetActive(bHasBindedProp3)
	else
		-- 背包中无龙筋
		prop3 = ItemManager.CreateItemBaseById(prop3Id,nil,0)
		-- 绑定类型,因背包中无装备，默认显示为绑定
		fields.UISprite_Prop3_Binding.gameObject:SetActive(true)

	end
	fields.UILabel_Prop3Name.text = prop3:GetName()
	-- 设置具体属性信息
	fields.UITexture_Prop3_Icon:SetIconTexture(prop3:GetTextureName())
	-- 设置品质
	fields.UISprite_Prop3_Quality.spriteName = colorutil.GetQualitySprite(prop3:GetQuality())
	-- 设置数量
	if allProp3NumInBag >= prop3CostNum then
		-- 绿色
		colorutil.SetLabelColorText(fields.UILabel_Prop3_Amount,colorutil.ColorType.Green_Remind,allProp3NumInBag .. "/" .. prop3CostNum)
		return true
	else
		-- 红色
		colorutil.SetLabelColorText(fields.UILabel_Prop3_Amount,colorutil.ColorType.Red_Remind,allProp3NumInBag .. "/" .. prop3CostNum)
		return false
	end
end
-- 设置神器进阶钱币消耗信息
local function SetCurrencyCostInfo(upgradedEquip)
	local currencyData = { }
	if not upgradedEquip then
		currencyData = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
	else
		currencyData = ItemManager.GetCurrencyData(upgradedEquip:GetUpgradeEquipCost())
	end
	fields.UISprite_Currency_Icon.spriteName = currencyData:GetIconName()
	fields.UILabel_Needed_Currency.text = currencyData:GetNumber()
end
-- 设置神器
local function SetUpgradedEquipBox(equip)
	if not equip then
		fields.UITexture_UpgradedEquip_Icon:SetIconTexture("null")
		fields.UILabel_UpgradedEquipName.text = ""
		fields.UISprite_UpgradedEquip_Quality.gameObject:SetActive(false)
		SetCurrencyCostInfo()
		fields.UILabel_Prop1Name.text = ""
		fields.UILabel_Prop2Name.text = ""
	else
		fields.UITexture_UpgradedEquip_Icon:SetIconTexture(equip:GetTextureName())
		fields.UILabel_UpgradedEquipName.text = equip:GetName()
		fields.UISprite_UpgradedEquip_Quality.gameObject:SetActive(true)
		fields.UISprite_UpgradedEquip_Quality.spriteName = colorutil.GetQualitySprite(equip:GetQuality())
		SetCurrencyCostInfo(equip)
	end
end

local function InitUpgradedEquipList()
	if fields.UIList_Formulas.Count == 0 then 
		local deltaLevel = cfg.equip.Equip.UPGRADE_DELTA_LEVEL
		local minLevel = cfg.equip.Equip.MIN_UPGRADE_LEVEL
		local maxLevel = cfg.equip.Equip.MAX_UPGRADE_LEVEL
		local upgradedEquips = g_UpgradedEquips[g_SelectedItem:GetProfessionLimit()]

		for level = minLevel,maxLevel,deltaLevel do
			if PlayerRole:Instance():GetLevel() < level then
				break
			end

			local listItem = fields.UIList_Formulas:AddListItem()
			listItem:SetText("UILabel_EquipsName",format(LocalString.EquipEnhance_Upgrade_EquipName,level)) 
			
			local subList = listItem.Controls["UIList_SubEquips"]
			for itemIndex = 0,subList.Count-1 do
				local subListItem = subList:GetItemByIndex(itemIndex)
				subListItem:SetText("UILabel_UpgradedEquipName",format(LocalString.EquipEnhance_Upgrade_EquipNameList[itemIndex+1],level))
				local item = upgradedEquips[level][INDEX_2_EQUIPTYPE[itemIndex]]
				if item ~= nil then 
					subListItem:SetIconTexture(item:GetTextureName())
					subListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(upgradedEquips[level][INDEX_2_EQUIPTYPE[itemIndex]]:GetQuality())
				end
			end
			EventHelper.SetListClick(subList,function(item)
				g_SelectedUpgradedEquip = upgradedEquips[level][INDEX_2_EQUIPTYPE[item.Index]]
				g_SelectedUpgradeProp1 = nil
				g_SelectedUpgradeProp2 = nil
				SetUpgradeProp1Box()
				SetUpgradeProp3Box()
				SetUpgradedEquipBox(g_SelectedUpgradedEquip)

				if g_SelectedUpgradedEquip:GetLevel() ~= cfg.equip.Equip.MIN_UPGRADE_LEVEL then
					SetUpgradeProp2Box(nil,false)
				end
			end)
		end
		EventHelper.SetListClick(fields.UIList_Formulas,function(listItem)
			-- 清除信息
			g_SelectedUpgradeProp1 = nil
			g_SelectedUpgradeProp2 = nil
			g_SelectedUpgradedEquip = nil
			SetUpgradeProp1Box()
			SetUpgradeProp3Box()
			SetUpgradedEquipBox()

			if listItem.Index == 0 then 
				-- 还原锁定状态
				SetUpgradeProp2Box(nil,true)
			else
				SetUpgradeProp2Box(nil,false)
			end
		end)
	end

end

local function AddUpgradeProp1(params)
	g_SelectedUpgradeProp1 = params.equip1
	SetUpgradeProp1Box(g_SelectedUpgradeProp1)
	g_Prop3_Validate = SetUpgradeProp3Box(g_SelectedUpgradeProp1)
end

local function AddUpgradeProp2(params)
	g_SelectedUpgradeProp2 = params.equip2
	SetUpgradeProp2Box(g_SelectedUpgradeProp2,false)
end
-- 显示神器进阶界面
ShowEquipUpgrade = function()
	-- UI特效
	fields.UIGroup_UpgradeEffect_Bottom.gameObject:SetActive(false)
	fields.UIGroup_UpgradeEffect_Top.gameObject:SetActive(false)
	fields.UIGroup_UpgradeEffect_Common.gameObject:SetActive(true)

	-- 清空信息
	g_Prop3_Validate = false
	-- g_SelectedUpgradedEquip = nil
	SetUpgradedEquipBox(g_SelectedUpgradedEquip)
	-- 清空材料
	-- g_SelectedUpgradeProp1 = nil
	-- g_SelectedUpgradeProp2 = nil
	SetUpgradeProp1Box(g_SelectedUpgradeProp1)
	SetUpgradeProp2Box(g_SelectedUpgradeProp2,true)
	SetUpgradeProp3Box(g_SelectedUpgradeProp1)
	-- 初始化神器列表
	InitUpgradedEquipList()
	-- 材料1,界面左下
	EventHelper.SetClick(fields.UIButton_AddProp1,function()
		if not g_SelectedUpgradedEquip then
			UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoUpgradedEquip)
		else
			local props = { }
			if g_SelectedUpgradedEquip:GetLevel() == cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				local equipsInBag = BagManager.GetItemByType(cfg.bag.BagType.EQUIP,g_SelectedUpgradedEquip:GetDetailType(),g_SelectedUpgradedEquip:GetProfessionLimit())
				local equipOnBody = BagManager.GetItemByType(cfg.bag.BagType.EQUIP_BODY,g_SelectedUpgradedEquip:GetDetailType(),g_SelectedUpgradedEquip:GetProfessionLimit())
				local tempProps = { }
				-- 优先身上装备
				if #equipOnBody ~= 0 then
					for _,equip in ipairs(equipOnBody) do
						tempProps[#tempProps + 1] = equip
					end
				end
				if #equipsInBag ~= 0 then 
					for _,equip in ipairs(equipsInBag) do
						tempProps[#tempProps + 1] = equip
					end
				end
				-- 筛选橙色并且等级为MIN_UPGRADE_LEVEL
				for _,prop in ipairs(tempProps) do
					if prop:GetQuality() == cfg.item.EItemColor.ORANGE and 
						prop:GetLevel() == g_SelectedUpgradedEquip:GetLevel() then
						props[#props + 1] = prop
					end
				end
			elseif g_SelectedUpgradedEquip:GetLevel() > cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				local equipsInBag = BagManager.GetItemByType(cfg.bag.BagType.EQUIP,g_SelectedUpgradedEquip:GetDetailType(),g_SelectedUpgradedEquip:GetProfessionLimit())
				local equipOnBody = BagManager.GetItemByType(cfg.bag.BagType.EQUIP_BODY,g_SelectedUpgradedEquip:GetDetailType(),g_SelectedUpgradedEquip:GetProfessionLimit())
				local tempProps = { }
				-- 优先身上装备
				if #equipOnBody ~= 0 then
					for _,equip in ipairs(equipOnBody) do
						tempProps[#tempProps + 1] = equip
					end
				end
				if #equipsInBag ~= 0 then 
					for _,equip in ipairs(equipsInBag) do
						tempProps[#tempProps + 1] = equip
					end
				end
				-- 筛选红色并且等级为(神器等级-等级差值(15级))
				for _,prop in ipairs(tempProps) do
					if prop:GetQuality() == cfg.item.EItemColor.RED and 
						prop:GetLevel() == (g_SelectedUpgradedEquip:GetLevel()-cfg.equip.Equip.UPGRADE_DELTA_LEVEL) then
						props[#props + 1] = prop

					end
				end				
				
			end

			if #props == 0 then
				UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoProps)
				return
			end
			
			local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
		    UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.UpgradedProp1, equips = props })
		end
	end)
	-- 材料2,界面中上
	EventHelper.SetClick(fields.UIButton_AddProp2,function()
		if g_SelectedUpgradedEquip then
			-- 选择75级神器进阶时不需要额外材料Prop2
			if g_SelectedUpgradedEquip:GetLevel() > cfg.equip.Equip.MIN_UPGRADE_LEVEL then

				if not g_SelectedUpgradeProp1 then
					UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoRedProp1)
					return 
				end

				local prop2Id = g_SelectedUpgradeProp1:GetExtraPropId()
				local props = { }
				local equipsInBag = BagManager.GetItemById(prop2Id)
				local equipOnBody = BagManager.GetItemById(prop2Id,cfg.bag.BagType.EQUIP_BODY)

				if #equipOnBody ~= 0 then
					for _,equip in ipairs(equipOnBody) do
						props[#props + 1] = equip
					end
				end
				if #equipsInBag ~= 0 then 
					for _,equip in ipairs(equipsInBag) do
						props[#props + 1] = equip
					end
				end
				
				-- 上述利用配置id获取装备(id必为橙色品质，并和g_SelectedUpgradedEquip同级的装备)
				-- 因此无需进行筛选,除非配置出错				 
				if #props == 0 then
					UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoProps)
					return
				end

				local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
			    UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.UpgradedProp2, equips = props })
			end
		end
	end)

	EventHelper.SetClick(fields.UIButton_EquipUpgrade, function()
		if not g_SelectedUpgradedEquip then
			UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoUpgradedEquip)
		else
			local bagType1 = 0 
			local pos1 = 0
			local bagType2 = 0
			local pos2 = 0
			if g_SelectedUpgradedEquip:GetLevel() == cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				if not g_SelectedUpgradeProp1 then
					UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoOrangeProp1)
					return 
				end
				bagType1 = g_SelectedUpgradeProp1.BagType
				pos1 = g_SelectedUpgradeProp1.BagPos

			elseif g_SelectedUpgradedEquip:GetLevel() > cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				if not g_SelectedUpgradeProp1 then
					UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoRedProp1)
					return 
				end
				if not g_SelectedUpgradeProp2 then
					UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Upgrade_NoOrangeProp2)
					return 
				end
				bagType1 = g_SelectedUpgradeProp1.BagType
				pos1 = g_SelectedUpgradeProp1.BagPos
				bagType2 = g_SelectedUpgradeProp2.BagType
				pos2 = g_SelectedUpgradeProp2.BagPos

			else
				logError("UpgradedEquip Level Error")

			end
			-- 校验等级
			-- if PlayerRole:Instance():GetLevel() < cfg.equip.Equip.MIN_UPGRADE_LEVEL then
				-- UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_Upgrade_LevelNotSatisfied,cfg.equip.Equip.MIN_UPGRADE_LEVEL))
				-- return 
			-- end
			-- 校验虚拟币消耗
			local currencyCost = g_SelectedUpgradedEquip:GetUpgradeEquipCost()
			local currency = ItemManager.GetCurrencyData(currencyCost)
			local currency_validate = CheckCmd.CheckData( { data = currencyCost, num = 1, showsysteminfo = true })
			if not currency_validate then 
				ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgequipenhance")
				return 
			end
			if not g_Prop3_Validate then
				local prop3 = ItemManager.CreateItemBaseById(cfg.equip.Equip.UPGRADE_COST_ITEM) 
				UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_Upgrade_Prop3NotEnough,prop3:GetName()))
				ItemManager.GetSource(cfg.equip.Equip.UPGRADE_COST_ITEM,"playerrole.equip.dlgequipenhance")
				return 
			end
			if currency_validate and g_Prop3_Validate then
				local msg = lx.gs.equip.normalequip.CUpgradeEquip( {
					bagtype1 = bagType1,
					pos1     = pos1,
					bagtype2 = bagType2,
					pos2     = pos2,

				} )
				network.send(msg)
			end
		end
	end)
end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_UpgradeEffect_Common.gameObject)
end
-- region msg
local function OnMsg_SUpgradeEquip(msg)
	-- print("OnMsg_SUpgradeEquip")
	if g_SelectedUpgradeProp1 and msg.bagtype1 == g_SelectedUpgradeProp1:GetBagType() and msg.pos1 == g_SelectedUpgradeProp1:GetBagPos() then 
		-- 播放特效
		local uiEffectObject = nil 
		if msg.pos2 > 0 then
			-- 使用材料2 
			if g_SelectedUpgradeProp2 and msg.bagtype2 == g_SelectedUpgradeProp2:GetBagType() and msg.pos2 == g_SelectedUpgradeProp2:GetBagPos() then 
				uiEffectObject = fields.UIGroup_UpgradeEffect_Top.gameObject
				UIManager.PlayUIParticleSystem(fields.UIGroup_UpgradeEffect_Top.gameObject)
			end
		else
			uiEffectObject = fields.UIGroup_UpgradeEffect_Bottom.gameObject
			UIManager.PlayUIParticleSystem(fields.UIGroup_UpgradeEffect_Bottom.gameObject)
		end
		-- 播放特效
		if g_SelectedUpgradedEquip then
			UIManager.showorrefresh("dlgtweenset",{
					tweenfield = "UIPlayTweens_EquipUpgrade",
					fieldparams = { texture = g_SelectedUpgradedEquip:GetTextureName()},
			})
		else
			logError("[TabEquipUpgrade]:Selected UpgradedEquip is nil")
		end
		-- UIManager.ShowSystemFlyText(LocalString.EquipEnhance_UpgradeSuccess)

		-- UI特效播完后再清除信息
		local eventId = 0
		eventId = GameEvent.evt_update:add(function()
			if not UIManager.IsPlaying(uiEffectObject) then	
				g_SelectedUpgradeProp1 = nil
				g_SelectedUpgradeProp2 = nil
				g_SelectedUpgradedEquip = nil
				SetUpgradeProp1Box()
				SetUpgradeProp2Box(nil,true)
				SetUpgradeProp3Box()
				SetUpgradedEquipBox()

				GameEvent.evt_update:remove(eventId)
			end
		end)
	end
end
-- endregion msg

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
	g_SelectedItem = EquipEnhanceManager.GetEquip()
    listenerIds = network.add_listeners( {
		{ "lx.gs.equip.normalequip.SUpgradeEquip", OnMsg_SUpgradeEquip },
    } )
end

local function hide()
    -- print(name, "hide")
    network.remove_listeners(listenerIds)
	fields.UIList_Formulas:Clear()
    g_SelectedItem = nil
	g_SelectedUpgradedEquip = nil
	g_SelectedUpgradeProp1 = nil
	g_SelectedUpgradeProp2 = nil
	StopUIParticleSystem()
end

local function refresh(params)
    -- print(name, "refresh")
	ShowEquipUpgrade()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function update()
    -- print(name, "update")
end

local function init(params)
    name, gameObject, fields = unpack(params)

	local allEquipData = ConfigManager.getConfig("equip")
	-- 初始化equip配置表里所有的神器装备数据(结构为:table[profession][level][type])
	g_UpgradedEquips = { }
	for configId in pairs(allEquipData) do
		local equip = ItemManager.CreateItemBaseById(configId)
		-- 是否是神器 
		if IsUpgradedEquip(equip) then
			if not g_UpgradedEquips[equip:GetProfessionLimit()] then
				g_UpgradedEquips[equip:GetProfessionLimit()] = { }
			end
			if not g_UpgradedEquips[equip:GetProfessionLimit()][equip:GetLevel()] then
				g_UpgradedEquips[equip:GetProfessionLimit()][equip:GetLevel()] = { }
			end
			g_UpgradedEquips[equip:GetProfessionLimit()][equip:GetLevel()][equip:GetDetailType()] = equip
		end
	end
end

return {
    init              = init,
    show              = show,
    hide              = hide,
    update            = update,
    destroy           = destroy,
    refresh           = refresh,
	uishowtype        = uishowtype,
	AddUpgradeProp2   = AddUpgradeProp2,
	AddUpgradeProp1   = AddUpgradeProp1,
}
