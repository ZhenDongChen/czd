local require = require
local unpack = unpack
local print = print
local utils = require("common.utils")
local ExtendedGameObject = ExtendedGameObject
local UIManager = require("uimanager")
local network = require("network")
local PlayerRole = require("character.playerrole")
local BagManager = require("character.bagmanager")
local ItemManager = require("item.itemmanager")
local EventHelper = UIEventListenerHelper

local gameObject
local name
local fields

local g_FilteredBagItems = { }
local g_SelectedBagType

local function ResetBagSlotList()

    if fields.UIList_BatchSellBag.Count ~= 0 then

        local selectedListItems = fields.UIList_BatchSellBag:GetSelectedItems()

        if selectedListItems.Length ~= 0 then
            for i = 1, selectedListItems.Length do
                fields.UIList_BatchSellBag:SetUnSelectedIndex(selectedListItems[i].Index)
            end
        end

        for i = 1, fields.UIList_BatchSellBag.Count do
            local listItem = fields.UIList_BatchSellBag:GetItemByIndex(i - 1)
            listItem:SetIconTexture("null")
            listItem:SetText("UILabel_Amount", 0)
            listItem.Controls["UISprite_Quality"].spriteName = ""
            ExtendedGameObject.SetActiveRecursely(listItem.Controls["UIGroup_Slots"].gameObject, false)
            listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)
            listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
        end
    end
end

local function SetBagSlot(listItem, item, bagType)
	listItem.Id = item:GetConfigId()
	listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)

	if bagType == cfg.bag.BagType.ITEM then

		listItem.Controls["UISprite_AmountBG"].gameObject:SetActive(true)
		listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
		listItem:SetText("UILabel_Amount", item:GetNumber())

	elseif bagType == cfg.bag.BagType.FRAGMENT then

		listItem.Controls["UISprite_AmountBG"].gameObject:SetActive(true)
		listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
		-- 物品数量大于等于合成要求数量，字体为绿色显示
		if item:GetConvertNumber() <= item:GetNumber() then
			listItem:SetText("UILabel_Amount", colorutil.GetColorStr(colorutil.ColorType.Green_Tip,item:GetNumber() .. "/" .. item:GetConvertNumber()))
		else
			listItem:SetText("UILabel_Amount", item:GetNumber() .. "/" .. item:GetConvertNumber())
		end
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(true)
		-- 装备和碎片显示遮盖
		if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
			listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
		end

	elseif bagType == cfg.bag.BagType.EQUIP then
		if item:GetAnnealLevel() ~= 0 then
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
			listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(true)
			listItem:SetText("UILabel_AnnealLevel", "+" .. item:GetAnnealLevel())
		else
			listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
			listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(true)
			listItem:SetText("UILabel_AnnealLevel", "+0")
		end
		-- 装备和碎片显示遮盖
		if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
			listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
		end
		listItem.Controls["UISprite_ArrowUp"].gameObject:SetActive(false)
		-- 推荐用的箭头,只针对四大主要装备
		if item:IsMainEquip() and(item:GetProfessionLimit() == cfg.Const.NULL or item:GetProfessionLimit() == PlayerRole:Instance().m_Profession) then
			local equipsOnBody = BagManager.GetItemByType(cfg.bag.BagType.EQUIP_BODY, item:GetDetailType())
			if equipsOnBody[1] and item:GetRecommendRate() > equipsOnBody[1]:GetRecommendRate() then
				listItem.Controls["UISprite_ArrowUp"].gameObject:SetActive(true)
			end
		end
	elseif bagType == cfg.bag.BagType.TALISMAN then

	else
		logError("Bag type error!")
	end
	-- icon
	listItem.Controls["UITexture_Icon"].gameObject:SetActive(true)
	listItem:SetIconTexture(item:GetTextureName())
	-- 品质
	listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
	listItem.Controls["UISprite_Quality"].spriteName = "Sprite_ItemQuality"
	listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())
	-- 绑定
	listItem.Controls["UISprite_Binding"].gameObject:SetActive(item:IsBound())

end

local function FindFilteredBagItem(slotPos)
    -- slot从1开始
    for tempBagPos, item in ipairs(g_FilteredBagItems) do
        if tempBagPos == slotPos then
            return item
        end
    end
    return nil
end

local function ShowBagInfo(bagType)

    local itemList = fields.UIList_BatchSellBag
    local bagItems = BagManager.GetItems(bagType)
    g_FilteredBagItems = { }
    for _, item in ipairs(bagItems) do
        if (item:GetQuality() == cfg.item.EItemColor.GREEN 
            or item:GetQuality() == cfg.item.EItemColor.BLUE
            or item:GetQuality() == cfg.item.EItemColor.PURPLE)
            and item:CanSell() == true then
                table.insert(g_FilteredBagItems, item)
        end
    end
	-- 按照品质排序(高到低)
	local sortFunc = function(item1,item2) 
		if (not item1) or (not item2) then
			return true
		end
		if item1:GetQuality() == item2:GetQuality() then
			return true
		else
			return (item1:GetQuality() > item2:GetQuality())
		end
	end
	utils.table_sort(g_FilteredBagItems,sortFunc)

    for tempBagPos, item in ipairs(g_FilteredBagItems) do
		--初始化数据
		local listItem = itemList:AddListItem()
        SetBagSlot(listItem, item, bagType)
    end

end

local function SelectSpecifiedQualityItems(filterdItems, specifiedQuality, isSelected, bagType)
    for tempBagPos, item in ipairs(filterdItems) do
        if item:GetQuality() == specifiedQuality then
            local listItem = fields.UIList_BatchSellBag:GetItemByIndex(tempBagPos - 1)
            listItem.Checked = isSelected
        end
    end
end

local function RefreshMoneyText(bagType)
    local totalPrice = 0
    local selectedListItems = fields.UIList_BatchSellBag:GetSelectedItems()
    if selectedListItems.Length == 0 then
        return 0
    end
    for i = 1, selectedListItems.Length do
        local selectedBagItem = FindFilteredBagItem(selectedListItems[i].Index + 1)
        if selectedBagItem then
            totalPrice = totalPrice + selectedBagItem:GetPrice() * selectedBagItem:GetNumber()
        end
    end
    return totalPrice

end

local function destroy()
end

local function show(params)
    g_SelectedBagType = params.bagType
    ShowBagInfo(params.bagType)
    fields.UIToggle_Green.value    = false
    fields.UIToggle_Blue.value     = false
    fields.UIToggle_Purple.value   = false
    fields.UILabel_TotalPrice.text = RefreshMoneyText()
end

local function hide()
    fields.UIList_BatchSellBag:Clear()
end

local function refresh(params)

end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)

	gameObject.transform.localPosition = Vector3(0,0,-600)

    fields.UIList_BatchSellBag.IsMultiCheckBox = true

    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("playerrole.bag.dlgbag_batchsell")
        UIManager.refresh("playerrole.bag.tabbag")
    end )

    EventHelper.SetListSelect(fields.UIList_BatchSellBag, function(listItem)
        local item = FindFilteredBagItem(listItem.Index + 1)
        if not item then
            fields.UIList_BatchSellBag:SetUnSelectedIndex(listItem.Index)
        end
        fields.UILabel_TotalPrice.text = RefreshMoneyText()
    end )

    EventHelper.SetListUnSelect(fields.UIList_BatchSellBag, function(listItem)
        fields.UILabel_TotalPrice.text = RefreshMoneyText()
    end )

    EventHelper.SetClick(fields.UIButton_Sell, function()
        local listItems = fields.UIList_BatchSellBag:GetSelectedItems()
        if listItems.Length == 0 then
            UIManager.ShowSystemFlyText(LocalString.Bag_BatchSell_Nothing)
            return
        end
        local bagPosSet = { }
        for i = 1, listItems.Length do
            local item = FindFilteredBagItem(listItems[i].Index + 1)
            if item then
                bagPosSet[#bagPosSet + 1] = item.BagPos
            end
        end
        if #bagPosSet ~= 0 then
           BagManager.SendCBatchSell(g_SelectedBagType,bagPosSet)
           UIManager.hide("playerrole.bag.dlgbag_batchsell")
        end
    end )

    -- 以下三个UIToggle不是互斥关系，只关注自己的开与关
    EventHelper.SetClick(fields.UIToggle_Green, function()

        local quality = cfg.item.EItemColor.GREEN
        if fields.UIToggle_Green.value then
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, true, g_SelectedBagType)
        else
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, false, g_SelectedBagType)
        end
        fields.UILabel_TotalPrice.text = RefreshMoneyText()

    end )

    EventHelper.SetClick(fields.UIToggle_Blue, function()

        local quality = cfg.item.EItemColor.BLUE
        if fields.UIToggle_Blue.value then
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, true, g_SelectedBagType)
        else
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, false, g_SelectedBagType)
        end
        fields.UILabel_TotalPrice.text = RefreshMoneyText()

    end )

    EventHelper.SetClick(fields.UIToggle_Purple, function()

        local quality = cfg.item.EItemColor.PURPLE
        if fields.UIToggle_Purple.value then
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, true, g_SelectedBagType)
        else
            SelectSpecifiedQualityItems(g_FilteredBagItems, quality, false, g_SelectedBagType)
        end
        fields.UILabel_TotalPrice.text = RefreshMoneyText()

    end )

end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}

