local require             = require
local unpack              = unpack
local print               = print
local math                = math
local utils               = require("common.utils")
local format              = string.format
local GameEvent           = require("gameevent")
local UIManager           = require("uimanager")
local network             = require("network")
local PlayerRole          = require("character.playerrole")
local BagManager          = require("character.bagmanager")
local ConfigManager       = require("cfg.configmanager")
local ItemManager         = require("item.itemmanager")
local ItemIntroduct       = require("item.itemintroduction")
local ItemEnum            = require("item.itemenum")
local CheckCmd            = require("common.checkcmd")
local EventHelper         = UIEventListenerHelper
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")


local gameObject
local name
local fields
-- 全局变量
local g_SelectedItem
local g_SelectedIndex
local g_SelectedAnnealProp
local g_SelectedEquipPos
local g_Equips
-- list初始位置信息
local g_InitPanelLocalPos
local g_InitPanelOffsetY

local ShowEquipAnneal


local listenerIds

local EQUIP_POS =
{
	EQUIP_ON_PLAYER = 1,
	EQUIP_IN_BAG = 2
}

local INDEX_2_EQUIPTYPE =
{
	[0] = ItemEnum.EquipType.Weapon,
	[1] = ItemEnum.EquipType.Hat,
	[2] = ItemEnum.EquipType.Cloth,
	[3] = ItemEnum.EquipType.Shoe,
}

local function SetEquipListItem(listItem, equip)
	if equip then 
		if equip:GetAnnealLevel() ~= 0 then
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
			listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
		else
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
			listItem:SetText("UILabel_AnnealLevel", "")
		end
		colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipName"], equip:GetQuality(), equip:GetName())
		colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipAnnealLevel"], equip:GetQuality(), format(LocalString.EquipEnhance_List_AnnealLevel, equip:GetAnnealLevel()))
		colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipPerfuseLevel"], equip:GetQuality(), format(LocalString.EquipEnhance_List_PerfuseLevel, equip:GetPerfuseLevel()))

		listItem:SetIconTexture(equip:GetTextureName())
		-- 设置绑定类型
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())
		-- 设置品质
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())
		-- 是否属于本门派
		if equip:GetProfessionLimit() ~= cfg.Const.NULL and equip:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
			listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
		else
			listItem.Controls["UISprite_RedMask"].gameObject:SetActive(false)
		end
	end
end

local function EquipListItemInit(go, wrapIndex, realIndex)
	local listItem = go:GetComponent("UIListItem")
	if g_SelectedIndex == realIndex then 
		listItem.Checkbox:Set(true)
	elseif listItem.Checked then 
		listItem.Checkbox:Set(false)
	end
	-- UIGirdWrapContent组件，偶尔会出现切换页签时，有些item背景消失
	-- 下面处理可以解决
	go:SetActive(false)
	go:SetActive(true)

	if (realIndex + 1) > #g_Equips then
		go:SetActive(false)
	else
		go:SetActive(true)
		SetEquipListItem(listItem, g_Equips[realIndex + 1])
	end

end

local function InitEquipList()
	if fields.UIList_Equip.Count == 0 then
		for i = 1, 6 do
			fields.UIList_Equip:AddListItem()
		end
	end
end

local function SetEquipList(equipPos,selectedItem)
	if equipPos == EQUIP_POS.EQUIP_ON_PLAYER then
		if selectedItem:IsMainEquip() then
			g_Equips = BagManager.GetMainEquipsOnBody()
		elseif selectedItem:IsAccessory() then
			g_Equips = BagManager.GetAccessoriesOnBody()
		end
	elseif equipPos == EQUIP_POS.EQUIP_IN_BAG then
		if selectedItem:IsMainEquip() then
			g_Equips = BagManager.GetMainEquipsInBag()
		elseif selectedItem:IsAccessory() then
			g_Equips = BagManager.GetAccessoriesInBag()
		end
	else
		logError("type error!")
	end

	if  #g_Equips == 0  or not g_Equips then
		print("No equip or acc in bag or on player")
		fields.UIList_Equip.gameObject:SetActive(false)
		return
	else
		fields.UIList_Equip.gameObject:SetActive(true)
	end

	g_SelectedIndex = -1

	-- 停止滑动
	fields.UIScrollView_Equipment.currentMomentum = Vector3(0,0,0)
	-- 重置信息
	local equipWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
	equipWrapContent:ResetAllChildPositions()
	local panel = fields.UIScrollView_Equipment.gameObject:GetComponent("UIPanel")
	panel.transform.localPosition = g_InitPanelLocalPos
	panel:SetClipOffsetY(g_InitPanelOffsetY)
	-- 重置数量
	equipWrapContent.minIndex = -(#g_Equips)
	equipWrapContent.maxIndex = 0
	-- 初始化数据
	EventHelper.SetWrapContentItemInit(equipWrapContent, EquipListItemInit)
	equipWrapContent.firstTime = true
	equipWrapContent:WrapContent()
end

local function RefreshEquipList(equipPos)
	local equipWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
	equipWrapContent.firstTime = true
	equipWrapContent:WrapContent()
end

-- 炼器符
local function SetAnnealSpellBox(curEquip)
	local annealSpellCost = ConfigManager.getConfigData("annealcost", curEquip:GetDetailType())
	local maxAnnealLevel =(ConfigManager.getConfigData("enhanceconfig", curEquip:GetLevel())).anneallimit

	-- 炼器符显示部分
	local annealSpellId = 0
	if curEquip:IsMainEquip() then
		annealSpellId = cfg.equip.AnnealCost.COST_ITEM_ID
	elseif curEquip:IsAccessory() then
		annealSpellId = cfg.equip.AnnealCost.ACCESSORY_COST_ITEM_ID
	end
	local allAnnealSpellNumInBag = BagManager.GetItemNumById(annealSpellId)
	local bHasBindedAnnealSpell = false
	-- 达到最大炼器等级时，所有信息默认显示为最大等级时的信息
	local nextEquipAnnealLevel = curEquip:GetAnnealLevel() + 1
	if curEquip:GetAnnealLevel() == maxAnnealLevel then
		nextEquipAnnealLevel = curEquip:GetAnnealLevel()
	end
	-- 背包里存在炼器符
	if allAnnealSpellNumInBag ~= 0 then
		-- 判断是否有绑定类型
		local annealSpells = BagManager.GetItemById(annealSpellId)
		for _, anneal in pairs(annealSpells) do
			-- 绑定类型
			if anneal:IsBound() then
				bHasBindedAnnealSpell = true
				break
			end
		end

		fields.UISprite_Lianqifu_Binding.gameObject:SetActive(bHasBindedAnnealSpell)
		fields.UITexture_Lianqifu_Icon:SetIconTexture(annealSpells[1]:GetTextureName())
		fields.UISprite_LianqifuBox_Quality.spriteName  = colorutil.GetQualitySprite(annealSpells[1]:GetQuality())
		fields.UILabel_Lianqifu_Name.text = annealSpells[1]:GetName()
		if allAnnealSpellNumInBag >= annealSpellCost.itemcost[nextEquipAnnealLevel] then
			colorutil.SetLabelColorText(fields.UILabel_Lianqifu_Number,colorutil.ColorType.Green_Remind,(allAnnealSpellNumInBag .. "/" .. annealSpellCost.itemcost[nextEquipAnnealLevel]))
		else
			colorutil.SetLabelColorText(fields.UILabel_Lianqifu_Number,colorutil.ColorType.Red_Remind,(allAnnealSpellNumInBag .. "/" .. annealSpellCost.itemcost[nextEquipAnnealLevel]))
		end
	else
		local annealSpell = ItemManager.CreateItemBaseById(annealSpellId, nil, 0)
		if annealSpell then 
			fields.UISprite_Lianqifu_Binding.gameObject:SetActive(true)
			fields.UITexture_Lianqifu_Icon:SetIconTexture(annealSpell:GetTextureName())
			fields.UISprite_LianqifuBox_Quality.spriteName = colorutil.GetQualitySprite(annealSpell:GetQuality())
			fields.UILabel_Lianqifu_Name.text = annealSpell:GetName()
			colorutil.SetLabelColorText(fields.UILabel_Lianqifu_Number,colorutil.ColorType.Red_Remind,("0/" .. annealSpellCost.itemcost[nextEquipAnnealLevel]))
		end
	end
end
-- 炼器辅助道具
local function SetAnnealPropBox(propId, propCostNum)

	local annealPropCost = ConfigManager.getConfigData("annealitemcost", propId)
	local annealProp = nil
	local propNumInBag = BagManager.GetItemNumById(propId)
	local bHasBindedProp = false

	-- 背包中有辅助道具
	if propNumInBag ~= 0 then
		-- 判断是否有绑定类型
		local props = BagManager.GetItemById(propId)
		for _, prop in pairs(props) do
			-- 绑定类型
			if prop:IsBound() then
				bHasBindedProp = true
				break
			end
		end
		annealProp = props[1]
	else
		-- 背包中无任何辅助道具，实例化一个辅助道具，用于填充资源信息
		local prop = ItemManager.CreateItemBaseById(propId, nil, 0)
		annealProp = prop
	end

	fields.UISprite_Prop_Binding.gameObject:SetActive(bHasBindedProp)
	fields.UITexture_Prop_Icon:SetIconTexture(annealProp:GetTextureName())
	fields.UISprite_Prop_Quality.spriteName = colorutil.GetQualitySprite(annealProp:GetQuality())
	if propNumInBag >= propCostNum then
		colorutil.SetLabelColorText(fields.UILabel_Prop_Number,colorutil.ColorType.Green_Remind,(propNumInBag .. "/" .. propCostNum))
	else
		colorutil.SetLabelColorText(fields.UILabel_Prop_Number,colorutil.ColorType.Red_Remind,(propNumInBag .. "/" .. propCostNum))
	end
	fields.UILabel_Prop_Name.text = annealProp:GetName()
	return annealProp
end

-- 设置成功率
local function SetEquipAnnealSuccessRate(levelAfterAnneal, propId, bShowExtraRate)

	local annealBaseRate = ConfigManager.getConfigData("annealrate", levelAfterAnneal)
	local baseSuccessRate = math.floor(annealBaseRate.rate * 100 / annealBaseRate.RATE_BASE_NUMBER)
	if propId ~= 0 and bShowExtraRate then
		local annealItemEffect = ConfigManager.getConfigData("annealitemeffect", propId)
		local extraSuccessRate = math.floor(annealItemEffect.effect[levelAfterAnneal] * 100 / annealItemEffect.RATE_BASE_NUMBER)

		fields.UILabel_Anneal_BaseSuccessRate.text = baseSuccessRate .. "%"
		fields.UILabel_Anneal_ExtraSuccessRate.text = format(LocalString.EquipEnhance_ExtraAnnealSuccRate, extraSuccessRate)
		
	else
		fields.UILabel_Anneal_BaseSuccessRate.text = baseSuccessRate .. "%"
		fields.UILabel_Anneal_ExtraSuccessRate.text = ""
	end

end

-- 显示炼器界面
ShowEquipAnneal = function()
	-- 炼器前装备信息
	fields.UITexture_Anneal_CurEquip_Icon:SetIconTexture(g_SelectedItem:GetTextureName())
	fields.UISprite_Anneal_CurEquip_Quality.spriteName = colorutil.GetQualitySprite(g_SelectedItem:GetQuality())
	-- 炼器等级为0,不显示炼器等级
	if g_SelectedItem:GetAnnealLevel() ~= 0 then
		fields.UILabel_CurEquip_AnnealLevel.gameObject:SetActive(true)
		fields.UILabel_CurEquip_AnnealLevel.text = "+" .. g_SelectedItem:GetAnnealLevel()
	else
		fields.UILabel_CurEquip_AnnealLevel.gameObject:SetActive(false)
		fields.UILabel_CurEquip_AnnealLevel.text = ""
	end
	-- 装备前绑定类型显示
	fields.UISprite_Anneal_CurEquip_Binding.gameObject:SetActive(g_SelectedItem:IsBound())


	-- 炼器后装备信息
	-- 炼器后装备，如果炼器等级超过最大炼器等级，面板信息显示最大炼器等级信息
	-- 不同等级的武器有不同的最大等级限制，具体参见enhanceconfig表
	local maxAnnealLevel =(ConfigManager.getConfigData("enhanceconfig", g_SelectedItem:GetLevel())).anneallimit
	local nextEquipAfterAnneal = utils.copy_table(g_SelectedItem)
	-- if g_SelectedItem:GetAnnealLevel() < cfg.equip.Equip.MAX_ANNEAL_LEVEL then
	if g_SelectedItem:GetAnnealLevel() < maxAnnealLevel then
		nextEquipAfterAnneal:SetAnnealLevel(g_SelectedItem:GetAnnealLevel() + 1)
	else
		-- 达到最大炼器等级
		fields.UILabel_Anneal_NextEquip_StatusDecs.text = LocalString.EquipEnhance_MaxLevel
	end

	fields.UITexture_Anneal_NextEquip_Icon:SetIconTexture(nextEquipAfterAnneal:GetTextureName())
	fields.UISprite_Anneal_NextEquip_Quality.spriteName = colorutil.GetQualitySprite(nextEquipAfterAnneal:GetQuality())
	fields.UILabel_NextEquip_AnnealLevel.text = "+" ..(nextEquipAfterAnneal:GetAnnealLevel())
	-- 战斗力提升数值显示
	fields.UILabel_EquipAnneal_AddedPower.text = "+" ..(nextEquipAfterAnneal:GetPower() - g_SelectedItem:GetPower())
	-- 装备后的绑定类型显示
	fields.UISprite_Anneal_NextEquip_Binding.gameObject:SetActive(nextEquipAfterAnneal:IsBound())

	local annealCost = ConfigManager.getConfigData("annealcost", g_SelectedItem:GetDetailType())

	-- 炼器符显示部分
	SetAnnealSpellBox(g_SelectedItem)
	-- 完璧符显示部分

	local propId = 0
	local propCostNum = 0
	g_SelectedAnnealProp = nil
	local annealPropsData = ConfigManager.getConfig("annealitemcost")
	for id, propData in pairs(annealPropsData) do
		if propData.itemcost[nextEquipAfterAnneal:GetAnnealLevel()] ~= 0 then
			propId = id
			propCostNum = propData.itemcost[nextEquipAfterAnneal:GetAnnealLevel()]
			break
		end
	end
	-- 是否使用辅助道具(完璧符)
	if propId ~= 0 then
		-- 使用完璧符
		fields.UIGroup_Prop.gameObject:SetActive(true)
		-- fields.UISprite_Add.gameObject:SetActive(true)
		g_SelectedAnnealProp = SetAnnealPropBox(propId, propCostNum)
		-- 炼器成功率
		if fields.UIToggle_AlwaysUseWanbifu.value then
			SetEquipAnnealSuccessRate(nextEquipAfterAnneal:GetAnnealLevel(), propId, true)
		else
			SetEquipAnnealSuccessRate(nextEquipAfterAnneal:GetAnnealLevel(), propId, false)
		end
	else
		-- 不使用完璧符
		-- 炼器成功率
		fields.UIGroup_Prop.gameObject:SetActive(false)
		-- fields.UISprite_Add.gameObject:SetActive(false)
		SetEquipAnnealSuccessRate(nextEquipAfterAnneal:GetAnnealLevel(), propId, false)
	end

	-- 虚拟币消耗部分，不消耗其他币种，配置写死
	local annealCost_Currency = annealCost.expenses[nextEquipAfterAnneal:GetAnnealLevel()]
	local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi, nil, annealCost_Currency)
	fields.UISprite_Anneal_Money_Icon.spriteName = currency:GetIconName()
	fields.UILabel_Anneal_Needed_Money.text = currency:GetNumber()

	EventHelper.SetToggle(fields.UIToggle_AlwaysUseWanbifu, function(toggle, toggleValue)
		if toggleValue then
			SetEquipAnnealSuccessRate(nextEquipAfterAnneal:GetAnnealLevel(), propId, true)
			-- fields.UIGroup_PropBox.gameObject:SetActive(true)
			-- fields.UISprite_Add.gameObject:SetActive(true)
		else
			SetEquipAnnealSuccessRate(nextEquipAfterAnneal:GetAnnealLevel(), propId, false)
			-- fields.UIGroup_PropBox.gameObject:SetActive(false)
			-- fields.UISprite_Add.gameObject:SetActive(false)
		end
	end )
	-- 目前需求隐藏炼器成功率
	fields.UIGroup_Anneal_Success.gameObject:SetActive(false)
	-- 炼器界面里点击查看当选炼器装备的详细信息
	EventHelper.SetClick(fields.UIButton_Anneal_CurEquip, function()
		ItemIntroduct.DisplayItem( {
			item = g_SelectedItem,
			variableNum = false,
			-- bInCenter = true,
			buttons =
			{
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil }
			}
		} )

	end )
	-- 炼器界面里点击查看炼器后装备的详细信息
	EventHelper.SetClick(fields.UIButton_Anneal_NextEquip, function()
		ItemIntroduct.DisplayItem( {
			item = nextEquipAfterAnneal,
			variableNum = false,
			-- bInCenter = true,
			buttons =
			{
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil }
			}
		} )
	end )

	EventHelper.SetClick(fields.UIButton_EquipAnneal, function()
		-- 达到最大炼器等级,最先检查
		-- if g_SelectedItem:GetAnnealLevel() == cfg.equip.Equip.MAX_ANNEAL_LEVEL then
		if g_SelectedItem:GetAnnealLevel() >= maxAnnealLevel then
			UIManager.ShowSystemFlyText(LocalString.EquipEnhance_MaxAnnealLevel)
			return
		end
		-- 配置未设cmd，检查炼器所需虚拟币是否足够
		if PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi) < annealCost_Currency then
			UIManager.ShowSystemFlyText(LocalString.DlgLottery_SError[1])
            if g_SelectedItem:IsMainEquip() then
			    ItemManager.GetSource(currency:GetConfigId(), "playerrole.equip.dlgequipenhance")
            elseif g_SelectedItem:IsAccessory() then
			    ItemManager.GetSource(currency:GetConfigId(), "playerrole.equip.dlgaccessoryenhance")
            end
			return
		end

		-- 检查背包中炼器符是否足够
		local annealSpellId = 0
		if g_SelectedItem:IsMainEquip() then 
			annealSpellId = cfg.equip.AnnealCost.COST_ITEM_ID
		elseif g_SelectedItem:IsAccessory() then
			annealSpellId = cfg.equip.AnnealCost.ACCESSORY_COST_ITEM_ID
		end
		local annealSpellNumInBag = BagManager.GetItemNumById(annealSpellId)
		local annealSpell = ItemManager.CreateItemBaseById(annealSpellId,nil,annealCost.itemcost[g_SelectedItem:GetAnnealLevel() + 1])

		if annealSpell and (annealSpell:GetNumber() > annealSpellNumInBag) then
			UIManager.ShowSystemFlyText(format(LocalString.Enhance_PropNotEnough,annealSpell:GetName()))
            if g_SelectedItem:IsMainEquip() then
			    ItemManager.GetSource(annealSpellId, "playerrole.equip.dlgequipenhance")
            elseif g_SelectedItem:IsAccessory() then 
			    ItemManager.GetSource(annealSpellId, "playerrole.equip.dlgaccessoryenhance")
            end
			return
		end

		local bOnlyUseNotBoundProps = fields.UIToggle_Anneal_OnlyUseNotBoundProps.value and 1 or 0
		local bAlwaysUseWanbifu = 0
		local usedPropId = nil
		if g_SelectedAnnealProp then
			bAlwaysUseWanbifu = fields.UIToggle_AlwaysUseWanbifu.value and 1 or 0
			if bAlwaysUseWanbifu == 1 then
				usedPropId = g_SelectedAnnealProp:GetConfigId()
			end
		end

		-- 校验背包中完璧符是否足够
		if bAlwaysUseWanbifu == 1 then
			local annealPropNumInBag = BagManager.GetItemNumById(usedPropId)
			local annealProp = ItemManager.CreateItemBaseById(usedPropId,nil,annealPropsData[usedPropId].itemcost[g_SelectedItem:GetAnnealLevel() + 1])

			if  annealProp:GetNumber() > annealPropNumInBag then
				UIManager.ShowSystemFlyText(format(LocalString.Enhance_PropNotEnough, annealProp:GetName()))
                if g_SelectedItem:IsMainEquip() then
				    ItemManager.GetSource(usedPropId, "playerrole.equip.dlgequipenhance")
                elseif g_SelectedItem:IsAccessory() then
				    ItemManager.GetSource(usedPropId, "playerrole.equip.dlgaccessoryenhance")
                end
				return
			end
		end

		local msg = lx.gs.equip.normalequip.CAnnealEquip(
		{
			bagtype         = g_SelectedItem.BagType,
			pos             = g_SelectedItem.BagPos,
			unbindonly      = bOnlyUseNotBoundProps,
			usewanbifu      = bAlwaysUseWanbifu,
			helpitemmodelid = usedPropId,
		} )
		network.send(msg)

	end )

end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_AnnealEffect_Start.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_AnnealEffect_Success.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_AnnealEffect_Fail.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_Prop1Effect.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_Prop2Effect.gameObject)
end

-- region msg
local function OnMsg_SAnnealEquip(msg)
	-- print("OnMsg_SAnnealEquip")
	if g_SelectedItem and msg.bagtype == g_SelectedItem:GetBagType() and msg.pos == g_SelectedItem:GetBagPos() then 

		local deltaAnnealLevel = msg.newlevel - g_SelectedItem:GetAnnealLevel()
		-- 播放炼器特效
		UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Start.gameObject)
		-- 辅助道具1特效(炼器符)
		UIManager.PlayUIParticleSystem(fields.UIGroup_Prop1Effect.gameObject)

		if fields.UIGroup_PropBox.gameObject.activeInHierarchy and fields.UIToggle_AlwaysUseWanbifu.value then
			-- 辅助道具2(完璧符)
			UIManager.PlayUIParticleSystem(fields.UIGroup_Prop2Effect.gameObject)
		end
		if deltaAnnealLevel > 0 then
			-- 炼器成功
			UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_AnnealSuccess, 1))
			-- 播放炼器特效
			--UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Success.gameObject)
			UIManager.showorrefresh("dlgtweenset", {
				tweenfield = "UIPlayTweens_EquipAnnealSuccess",
			} )
		else
			-- 炼器失败
			if deltaAnnealLevel == 0 then
				UIManager.ShowSystemFlyText(LocalString.EquipEnhance_AnnealFail_Zero)
			else
				UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_AnnealFail, math.abs(deltaAnnealLevel)))
			end
			-- 播放炼器特效
			--UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Fail.gameObject)
			UIManager.showorrefresh("dlgtweenset", {
				tweenfield = "UIPlayTweens_EquipAnnealFail",
			} )
		end
		g_SelectedItem:SetAnnealLevel(msg.newlevel)
		RefreshEquipList(g_SelectedEquipPos)
		ShowEquipAnneal()
	end
end

-- endregion msg

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
	g_SelectedItem = EquipEnhanceManager.GetEquip()
	if g_SelectedItem:IsMainEquip() then 
		fields.UILabel_Title.text = LocalString.Enhance_Anneal_Title[1]
	elseif g_SelectedItem:IsAccessory() then 
		fields.UILabel_Title.text = LocalString.Enhance_Anneal_Title[2]
	end

	local btnToggle = fields.UIButton_Body.gameObject:GetComponent(UIToggle)
	btnToggle.value = true
	g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
	SetEquipList(g_SelectedEquipPos,g_SelectedItem)
	listenerIds = network.add_listeners( {
		{ "lx.gs.equip.normalequip.SAnnealEquip", OnMsg_SAnnealEquip },
	} )
end

local function hide()
	-- print(name, "hide")
	network.remove_listeners(listenerIds)
	g_SelectedItem = nil
	g_SelectedAnnealProp = nil
	StopUIParticleSystem()
end

local function refresh(params)
	-- print(name, "refresh")
	RefreshEquipList(g_SelectedEquipPos)
	ShowEquipAnneal()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function update()
	-- print(name, "update")
end

local function init(params)
	name, gameObject, fields = unpack(params)

	InitEquipList()
	local panel         = fields.UIScrollView_Equipment.gameObject:GetComponent("UIPanel")
	g_InitPanelLocalPos = panel.transform.localPosition
	g_InitPanelOffsetY  = panel:GetClipOffsetY()

	EventHelper.SetListClick(fields.UIList_Equip, function(listItem)
		local equipWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
		local realIndex = equipWrapContent:Index2RealIndex(listItem.Index)
		g_SelectedIndex = realIndex
		g_SelectedItem = g_Equips[realIndex + 1]
		EquipEnhanceManager.SetEquip(g_SelectedItem)
		ShowEquipAnneal()
	end )

	EventHelper.SetClick(fields.UIButton_Body, function()
		if g_SelectedEquipPos == EQUIP_POS.EQUIP_ON_PLAYER then
			return
		end
		g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
		SetEquipList(g_SelectedEquipPos,g_SelectedItem)
	end )

	EventHelper.SetClick(fields.UIButton_Bag, function()
		if g_SelectedEquipPos == EQUIP_POS.EQUIP_IN_BAG then
			return
		end
		g_SelectedEquipPos = EQUIP_POS.EQUIP_IN_BAG
		SetEquipList(g_SelectedEquipPos,g_SelectedItem)
	end )
	fields.UIToggle_AlwaysUseWanbifu.value = true
end

return {
	init            = init,
	show            = show,
	hide            = hide,
	update          = update,
	destroy         = destroy,
	refresh         = refresh,
	uishowtype      = uishowtype,
	AddUpgradeProp2 = AddUpgradeProp2,
	AddUpgradeProp1 = AddUpgradeProp1,
}
