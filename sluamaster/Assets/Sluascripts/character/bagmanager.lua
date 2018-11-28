local print              = print
local unpack             = unpack
local require            = require
local format             = string.format
local octets             = require("common.octets")
local gameevent          = require("gameevent")
local network            = require("network")
local utils              = require("common.utils")
local UIManager          = require("uimanager")
local ConfigManager      = require("cfg.configmanager")
local ItemManager        = require("item.itemmanager")
local ItemEnum           = require("item.itemenum")
local CommonBag          = require("ui.playerrole.bag.commonbag")
local BodyBag            = require("ui.playerrole.bag.bodybag")
local CheckCmd           = require("common.checkcmd")
local PlayerRole         = require("character.playerrole")
local EctypeManager      = require("ectype.ectypemanager")
local CharacterManager   = require("character.charactermanager")
local Mineral            = require "character.mineral"
local EventHelper        = UIEventListenerHelper
local ExtendedGameObject = ExtendedGameObject

local CurrenctFlyItem

local bagsInfo = { } --背包里面所有的数据
local recmdedEquips = { }
local itemsInCD = { }
local chickState = true
local MsgCounter =
{
	-- common bag
	[cfg.bag.BagType.EQUIP]         = 0,
	[cfg.bag.BagType.ITEM]          = 0,
	[cfg.bag.BagType.FRAGMENT]      = 0,
	[cfg.bag.BagType.TALISMAN]      = 0,
    -- depot
    [cfg.bag.BagType.DEPOT_EQUIP]   = 0,
	[cfg.bag.BagType.DEPOT_ITEM]    = 0,
	[cfg.bag.BagType.DEPOT_FRAGMENT]= 0,
	[cfg.bag.BagType.DEPOT_TALISMAN]= 0,
    -- family depot
    [cfg.bag.BagType.FAMILY_EQUIP]  = 0,
	-- body bag
	[cfg.bag.BagType.EQUIP_BODY]    = 0,
	[cfg.bag.BagType.TALISMAN_BODY] = 0,
}

local FlyTextIgnoredDlgList = 
{
	--[1] = "lottery.tablottery_result", 
	[1] = "ectype.dlggradebox",
	--[3] = "lottery.tablottery_partner",
	--[4] = "lottery.tablottery_talisman", 
	--[2] = "lottery.lotteryfragment.dlglotteryfragment", 
    [2] = "cornucopia.tabcompress",     
}

local LotteryDlgList = 
{
	[1] = "lottery.tablottery_result", 
	[2] = "lottery.tablottery_partner",
	[3] = "lottery.tablottery_talisman", 
	[4] = "lottery.lotteryfragment.dlglotteryfragment", 

}

local BODYBAG_TO_COMMONBAG = 
{
    [cfg.bag.BagType.EQUIP_BODY]    = cfg.bag.BagType.EQUIP,
    [cfg.bag.BagType.TALISMAN_BODY] = cfg.bag.BagType.TALISMAN,
}

local COMMONBAG_TO_BODYBAG =
{
	[cfg.bag.BagType.EQUIP]    = cfg.bag.BagType.EQUIP_BODY,
	[cfg.bag.BagType.TALISMAN] = cfg.bag.BagType.TALISMAN_BODY,
}

local DEPOT_TO_COMMONBAG = 
{
    [cfg.bag.BagType.DEPOT_ITEM]     = cfg.bag.BagType.ITEM,
    [cfg.bag.BagType.DEPOT_EQUIP]    = cfg.bag.BagType.EQUIP,
    [cfg.bag.BagType.DEPOT_FRAGMENT] = cfg.bag.BagType.FRAGMENT,
    [cfg.bag.BagType.DEPOT_TALISMAN] = cfg.bag.BagType.TALISMAN,
    [cfg.bag.BagType.FAMILY_EQUIP]    = cfg.bag.BagType.EQUIP,
}
local function CanFlyTextlotteryItemData(item)
	
	if #item > 0 then
		CurrenctFlyItem = item[#item]
	else
		CurrenctFlyItem = item 
	end

	local tempbShowFlyText = false
	for _,ignoredDlgName in ipairs(LotteryDlgList) do
		local bShow = UIManager.isshow(ignoredDlgName)
        if bShow then 
            tempbShowFlyText = true 
            break;
        end
	end
	
	return tempbShowFlyText
	
end

local function IsBlendLotteryData(newItem)
	
	local tempItem
	if #newItem > 0 then
		tempItem = newItem[#newItem]
	else
		tempItem = newItem 
	end
	
	local tempLotterydata = ConfigManager.getConfig("lotteryitemconfig")
	local result = false
	
	for _ , itemdata in ipairs(tempLotterydata) do
		if itemdata.items.itemid == tempItem.ConfigData.id then
			result =  true
			break;
		else
			result =  false
		end
	end
	return result
end


local function CanShowFlyText()
    local bShowFlyText = true
    for _,ignoredDlgName in ipairs(FlyTextIgnoredDlgList) do
        local bShow = UIManager.isshow(ignoredDlgName)
        if bShow then 
            bShowFlyText = false 
            break
        end
    end
    -- 金钱本和经验本也不飘字(有开宝箱界面)
    if EctypeManager.IsInDailyEctype() then 
       bShowFlyText = false
    end
    return bShowFlyText
end

-- 根据BagPos升序排序
local function Sort(item1,item2)
	if (not item1) or (not item2) then
		return true
	end
	return (item1:GetBagPos() < item2:GetBagPos())
end
-- 装备排序(有类型)
-- 根据门派>品质>装备类型

local function Sort2(item1,item2)
	if (not item1) or (not item2) then
		return true
	end
	if item1:GetProfessionLimit() == item2:GetProfessionLimit() then

		if item1:GetQuality() == item2:GetQuality() then
			if item1:GetDetailType() == item2:GetDetailType() then
				return true
			else
				return (item1:GetDetailType() < item2:GetDetailType())
			end
		else
			return (item1:GetQuality() > item2:GetQuality())
		end
	else
		return (item1:GetProfessionLimit() < item2:GetProfessionLimit())
	end
end
-- 饰品排序(无类型)
-- 根据品质>装备类型
local function Sort3(item1,item2)
	if (not item1) or (not item2) then
		return true
	end
	if item1:GetQuality() == item2:GetQuality() then
		if item1:GetDetailType() == item2:GetDetailType() then
			return true
		else
			return (item1:GetDetailType() < item2:GetDetailType())
		end
	else
		return (item1:GetQuality() > item2:GetQuality())
	end
end
-- 推荐排序
-- 推荐指数>类型
local function Sort4(item1,item2)
	if (not item1) or (not item2) then
		return true
	end
	if item1:GetRecommendRate() == item2:GetRecommendRate() then
		if item1:GetDetailType() == item2:GetDetailType() then
			return true
		else
			return (item1:GetDetailType() < item2:GetDetailType())
		end
	else
		return (item1:GetRecommendRate() > item2:GetRecommendRate())
	end
end

local function GetBag(bagType)
      return bagsInfo[bagType]
end

--设置背包网格里面的数据
local function SetBag(bagType,newBag)
	bagsInfo[bagType] = newBag
end

local function ResetBag(bagType)
    local bagData = ConfigManager.getConfig("bagconfig")
	bagsInfo[bagType] = CommonBag:new(bagType,bagData[bagType].initcapacity,bagData[bagType].maxcapacity)
    MsgCounter[bagType] = 0
end

local function GetTotalSize(bagType)
    return bagsInfo[bagType]:GetTotalSize()
end

local function SetTotalSize(bagType, size)
    bagsInfo[bagType]:SetTotalSize(size)
end

local function GetLockedSize(bagType)
    return bagsInfo[bagType]:GetLockedSize()
end

local function GetUnLockedSize(bagType)
    return bagsInfo[bagType]:GetUnLockedSize()
end

local function SetUnLockedSize(bagType, size)
    bagsInfo[bagType]:SetUnLockedSize(size)
end

local function GetItems(bagType)
    return bagsInfo[bagType]:GetItems()
end

-- 此函数只返回格子不为空的格子数量
-- 不是全部物品的总数量(eg. 支持堆叠的物品)
local function GetItemSlotsNum(bagType)
    return bagsInfo[bagType]:GetItemSlotsNum()
end

local function GetItemBySlot(bagType, slot)
    return bagsInfo[bagType]:GetItemBySlot(slot)
end

-- 根据配置文件里的ID获取物品总数(包括绑定和非绑定类型)
local function GetItemNumById(configId,bagType)
	if not bagType then
		for bagType, bag in pairs(bagsInfo) do
			-- 仅遍历common bag
			if bag:GetType() == cfg.bag.BagType.EQUIP
				or bag:GetType() == cfg.bag.BagType.ITEM
				or bag:GetType() == cfg.bag.BagType.FRAGMENT
				or bag:GetType() == cfg.bag.BagType.TALISMAN then

				local num = bag:GetItemNumById(configId)
				if num ~= 0 then
					return num
				end
			end
		end
		return 0
	else
		local bag = GetBag(bagType)
		return bag:GetItemNumById(configId)
	end
end
-- 根据配置文件里的ID获取物品，装备等
local function GetItemById(configId,bagType)
	if not bagType then
		for bagType, bag in pairs(bagsInfo) do
			-- 仅遍历common bag
			if bag:GetType() == cfg.bag.BagType.EQUIP
				or bag:GetType() == cfg.bag.BagType.ITEM
				or bag:GetType() == cfg.bag.BagType.FRAGMENT
				or bag:GetType() == cfg.bag.BagType.TALISMAN then

				local items = bag:GetItemById(configId)
				if #items ~= 0 then
					return items
				end
			end
		end
		return { }
	else
		local bag = GetBag(bagType)
		return bag:GetItemById(configId)
	end
end



-- 根据具体类型获取,返回list类型
-----------------------------------------------------------------
-- profession参数可以不指定，默认不分职业；若指定则返回指定职业的装备
-- bagType，detailType使用itemenum.lua里的定义，不可使用配置中的定义
-----------------------------------------------------------------
local function GetItemByType(bagType, detailType, profession)
    local items = { }
    if not detailType then
        local bagItems = GetItems(bagType)
        for _, item in ipairs(bagItems) do
            if not profession then
                items[#items + 1] = item
            else
                if (item:GetProfessionLimit() == cfg.Const.NULL or item:GetProfessionLimit() == profession) then
                    items[#items + 1] = item
                end
            end
        end
    else
        local bagItems = GetItems(bagType)
        for _, item in ipairs(bagItems) do
            if item:GetDetailType() == detailType then
                if not profession then
                    items[#items + 1] = item
                else
                    if (item:GetProfessionLimit() == cfg.Const.NULL or item:GetProfessionLimit() == profession) then
                        items[#items + 1] = item
                    end
                end
            end
        end
    end

	-- 根据BagPos升序排序
	utils.table_sort(items,Sort)
    return items
end

-- 所有可以加血的物品，按照配置id降序排列
 local function GetHPItem()
	local hpItems = { }
	local items = GetItemByType(cfg.bag.BagType.ITEM,ItemEnum.ItemType.Medicine)
	for _, item in pairs(items) do
		local bValidated = CheckCmd.CheckData( { data = item:GetLevelLimit(), showsysteminfo = false })
 		if item:GetDetailType2() == cfg.item.MedicineType.WHITE and bValidated then
			hpItems[#hpItems + 1] = item
		end
	end
	utils.table_sort(hpItems,function(item1,item2) 
		if (not item1) or (not item2) then
			return false
		end
		return (item1:GetConfigId() > item2:GetConfigId()) 
	end)
	return hpItems
 end
-- 所有可以加蓝的物品，按照配置id降序排列
 local function GetMPItem()
	local mpItems = { }
	local items = GetItemByType(cfg.bag.BagType.ITEM,ItemEnum.ItemType.Medicine)
	for _, item in pairs(items) do
		local bValidated = CheckCmd.CheckData( { data = item:GetLevelLimit(), showsysteminfo = false })
		if item:GetDetailType2() == cfg.item.MedicineType.GREEN and bValidated then
			mpItems[#mpItems + 1] = item
		end
	end
	utils.table_sort(mpItems,function(item1,item2) 
		if (not item1) or (not item2) then
			return false
		end
		return (item1:GetConfigId() > item2:GetConfigId()) 
	end)
	return mpItems
 end

local function AddItem(bagType, slot, item)
    return bagsInfo[bagType]:AddItem(slot, item)
end
-- 删除指定数量
local function RemoveItem(bagType, slot, num)
    return bagsInfo[bagType]:RemoveItem(slot, item)
end
-- 全部删除
local function DeleteItem(bagType, slot)
    return bagsInfo[bagType]:DeleteItem(slot)
end
-- 清除所有背包NEW状态
local function ResetNewStatus()
    for bagType, bag in pairs(bagsInfo) do
        if bag.ResetNewStatus then
            bag:ResetNewStatus()
        end
    end
end

-- 清除指定背包NEW状态
local function ResetBagNewStatus(bagType)
    local bag = GetBag(bagType)
    if bag.ResetNewStatus then
        bag:ResetNewStatus()
    end
end

local function IsEmpty(bagType)
    return bagsInfo[bagType]:IsEmpty()
end

-- 获取四大主要装备，衣服、帽子、鞋子、武器
local function GetMainEquipsOnBody()
    local equips = { }
    for slot = 1,4 do
        local equip = GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,slot)
        if equip then
            equips[#equips + 1] = equip
        end
    end
	utils.table_sort(equips,Sort2)
    return equips
end
-- 获取三大饰品，戒指、手镯、项链
local function GetAccessoriesOnBody()
    local accs = { }
    for slot = 5,8 do
        local acc = GetItemBySlot(cfg.bag.BagType.EQUIP_BODY,slot)
        if acc then
            accs[#accs + 1] = acc
        end
    end
	utils.table_sort(accs,Sort3)
    return accs
end
-- 获取背包中主要装备,包括本门派和其他门派
local function GetMainEquipsInBag()
    local equips = { }
    local equipsInBag = GetItems(cfg.bag.BagType.EQUIP)
    for _, equip in ipairs(equipsInBag) do
        local equipDetailType = equip:GetDetailType()
		if equipDetailType == ItemEnum.EquipType.Weapon or
			equipDetailType == ItemEnum.EquipType.Cloth or
			equipDetailType == ItemEnum.EquipType.Hat or
			equipDetailType == ItemEnum.EquipType.Shoe  then

            equips[#equips + 1] = equip
        end
    end
	utils.table_sort(equips,Sort2)
    return equips
end
-- 获取背包中饰品,包括本门派和其他门派
local function GetAccessoriesInBag()
    local accs = { }
    local equipsInBag = GetItems(cfg.bag.BagType.EQUIP)
    for _, equip in ipairs(equipsInBag) do
        local equipDetailType = equip:GetDetailType()

        if equipDetailType == ItemEnum.EquipType.Bangle or
			equipDetailType == ItemEnum.EquipType.Necklace or
			equipDetailType == ItemEnum.EquipType.Ring then

            accs[#accs + 1] = equip
        end
    end
	utils.table_sort(accs,Sort3)
    return accs
end

local function GetRecommendEquips()
	return recmdedEquips
end

local function OnNotifyLoadSceneEnd()
	if UIManager.hasloaded("dlguimain") then
		local recmdEquipPanel = require("ui.uimain.recommendequip")
		recmdEquipPanel.show()
	end
end

-- 仓库和背包共同使用的函数 设置
local function ResetBagSlot(listItem)
	if listItem then
		-- set false true 解决item背景消失的隐性bug
		listItem.gameObject:SetActive(false)
		listItem.gameObject:SetActive(true)
		listItem:SetIconTexture("null")
		listItem:SetText("UILabel_Amount", 0)
		listItem.Controls["UISprite_Quality"].spriteName = "N_CoverSprite_ItemQuality"
		listItem:SetText("UILabel_AnnealLevel", "+0")
		listItem.Data = nil
		listItem.Controls["UISprite_Lock"].gameObject:SetActive(false)
        if listItem.Controls["UISprite_CD"] then
		    listItem.Controls["UISprite_CD"].gameObject:SetActive(false)
        end
		ExtendedGameObject.SetActiveRecursely(listItem.Controls["UIGroup_Slots"].gameObject, false)
		listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)
		listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
	end
end
-- UIGridWrapContent组件初始化函数
local function WrapContentItemInit(go, index, realIndex,bagType,SetSlot)
    if not go then 
        logError("BagManager:func->WrapContentItemInit,params->go:nil")
        return 
    end
    local uiItem = go:GetComponent("UIListItem")
    if not uiItem then 
        logError("BagManager:func->WrapContentItemInit,uiItem:nil")
        return 
    end
    ResetBagSlot(uiItem)
    if realIndex + 1 > GetUnLockedSize(bagType) then
        uiItem.Controls["UISprite_Lock"].gameObject:SetActive(true)
    else
        uiItem.Controls["UISprite_Lock"].gameObject:SetActive(false)
        local item = GetItemBySlot(bagType, realIndex + 1)
        if item and SetSlot and type(SetSlot) == "function" then
            SetSlot(uiItem, item, bagType)
        end
    end
end

local function InitBagSlotList(bagType,uiList,initFunc)
	if uiList and uiList.Count == 0 then
		for i = 1, 24 do
			local bagItem = uiList:AddListItem()
		end
		local bagWrapContent = uiList.gameObject:GetComponent("UIGridWrapContent")
		bagWrapContent.minIndex = -(GetTotalSize(bagType) / 4) + 1
		bagWrapContent.maxIndex = 0
		EventHelper.SetWrapContentItemInit(bagWrapContent, initFunc)
	end
end

local function RefreshBagList(uiList)
	local bagWrapContent = uiList.gameObject:GetComponent("UIGridWrapContent")
	bagWrapContent.firstTime = true
	bagWrapContent:WrapContent()
end

local function SetBagSlotBasicInfo(listItem, item, bagType, bNotShowCD, bNotShowNew)

    listItem.Id = item:GetConfigId()  --新手指引用
	listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)
	if bagType == cfg.bag.BagType.ITEM 
        or bagType == cfg.bag.BagType.DEPOT_ITEM then

		listItem.Controls["UISprite_AmountBG"].gameObject:SetActive(true)
		listItem.Controls["UILabel_Amount"].gameObject:SetActive(true)
		listItem:SetText("UILabel_Amount", item:GetNumber())
		if (not bNotShowCD) and bagType == cfg.bag.BagType.ITEM and item:GetDetailType() == ItemEnum.ItemType.Medicine then
			local cdData = item:GetCDData()
			listItem.Controls["UISprite_CD"].gameObject:SetActive(true)
			listItem.Data = cdData
		end

	elseif bagType == cfg.bag.BagType.FRAGMENT 
        or bagType == cfg.bag.BagType.DEPOT_FRAGMENT then

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

	elseif bagType == cfg.bag.BagType.EQUIP 
        or bagType == cfg.bag.BagType.DEPOT_EQUIP 
        or bagType == cfg.bag.BagType.FAMILY_EQUIP then
		
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
		if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession  or item:GetLevel() > PlayerRole:Instance().m_Level then
			listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
		end
		listItem.Controls["UISprite_ArrowUp"].gameObject:SetActive(false)
		-- 推荐用的箭头,只针对四大主要装备
		if bagType == cfg.bag.BagType.EQUIP and item:IsMainEquip() and(item:GetProfessionLimit() == cfg.Const.NULL or item:GetProfessionLimit() == PlayerRole:Instance().m_Profession) then
			local equipsOnBody = GetItemByType(cfg.bag.BagType.EQUIP_BODY, item:GetDetailType())
			if equipsOnBody[1] and item:GetRecommendRate() > equipsOnBody[1]:GetRecommendRate() then
				listItem.Controls["UISprite_ArrowUp"].gameObject:SetActive(true)
			end
		end
	elseif bagType == cfg.bag.BagType.TALISMAN
        or bagType == cfg.bag.BagType.DEPOT_TALISMAN then

	else
		logError("Bag type error!")
	end
	-- icon
	listItem.Controls["UITexture_Icon"].gameObject:SetActive(true)
	listItem:SetIconTexture(item:GetTextureName())
	-- 品质
	listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
	listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())
	-- 绑定
	listItem.Controls["UISprite_Binding"].gameObject:SetActive(item:IsBound())

	if (bagType == cfg.bag.BagType.ITEM 
        or bagType == cfg.bag.BagType.EQUIP
        or bagType == cfg.bag.BagType.FRAGMENT
        or bagType == cfg.bag.BagType.TALISMAN)
        and item.bNewAdded and (not bNotShowNew) then
		listItem.Controls["UISprite_New"].gameObject:SetActive(true)
	else
		listItem.Controls["UISprite_New"].gameObject:SetActive(false)
	end
end
-- 背包置顶(注意：对应UIScrollView的设置：DragEffect=Momenttum,Scroll Wheel Factor=0)
-- 若DragEffect=MomenttumAndSprint，会导致在回弹过程中，在lateupdate中重新计算位置信息而无法置顶
local function ResetBagListToTop(uiScrollView,uiList,initPanelLocalPos,initPanelOffsetY)
	-- 停止滑动
	uiScrollView.currentMomentum = Vector3(0,0,0)
	local bagWrapContent = uiList.gameObject:GetComponent("UIGridWrapContent")
	--bagWrapContent:ResetChildPositions()
	bagWrapContent:ResetAllChildPositions()
	local bagPanel = uiScrollView.gameObject:GetComponent("UIPanel")
	bagPanel.transform.localPosition = initPanelLocalPos
	bagPanel:SetClipOffsetY(initPanelOffsetY)
	bagWrapContent.firstTime = true
	bagWrapContent:WrapContent()
end

-- common msg
local function SendCSortBag(bagType)
    local msg = lx.gs.bag.msg.CSortBag( { bagtype = bagType })
    network.send(msg)
end

local function SendCSell(bagType, slot, num)
    local msg = lx.gs.bag.msg.CSell( { bagtype = bagType, pos = slot, sellnum = num })
    network.send(msg)
end

local function SendCBatchSell(bagType, slotList)
    local msg = lx.gs.bag.msg.CBatchSell( { bagtype = bagType, posset = slotList })
    network.send(msg)
end

local function SendCSplitItem(bagType, slot, num)
    local msg = lx.gs.bag.msg.CSplitItem( { bagtype = bagType, pos = slot, splitnumber = num })
    network.send(msg)
end

local function SendCUnlockGrid(bagType, num)
	print("=-=---------------------------------------------------------------------------")
    local msg = lx.gs.bag.msg.CUnlockGrid( { bagtype = bagType, unlocknum = num })
    network.send(msg)
end

-- item msg
local function SendCUseItem(slot, num)
    if not PlayerRole:Instance().m_Effect:CanUseItem() then
        local item = GetItemBySlot(cfg.bag.BagType.ITEM,slot)

        if item : GetDetailType() == ItemEnum.ItemType.Medicine then
            return
        end
    end
	
--[[	local item = GetItemBySlot(cfg.bag.BagType.ITEM,slot)
	if item : GetDetailType() == ItemEnum.ItemType.Flower then
		UIManager.showdialog("friend.dlgfriend")
		return 
		--printyellow(">>>>>>>>>>>>>Flower")
	end--]]
	--print("SendCUseItem",slot,num)
	
    local msg = lx.gs.item.CUseItem( { pos = slot, usenumber = num })
    network.send(msg)
end

-- fagment msg
local function SendCCompoundFragment(slot)
    local msg = lx.gs.fragment.CCompoundFragment( { pos = slot })
    network.send(msg)
end

-- equip msg
local function SendCLoadEquip(slot)
    local msg = lx.gs.equip.CLoadEquip({ pos = slot })
    network.send(msg)
end

local function SendCUnloadEquip(slot)
    local msg = lx.gs.equip.CUnloadEquip({ pos = slot })
    network.send(msg)
end
-- talisman msg
local function SendCEquipTalisman(slot)
	local msg = lx.gs.talisman.CEquipTalisman({ pos = slot })
    network.send(msg)
end

local function SendCUnEquipTalisman()
	network.create_and_send("lx.gs.talisman.CUnEquipTalisman")
end
-- pet msg
local function SendCEquipPet(petSlot,equipSlot)
	local msg = lx.gs.pet.msg.CEquip({ petpos = petSlot,equippos = equipSlot })
    network.send(msg)
end

local function SendCUnequipPet(slot)
	local msg = lx.gs.pet.msg.CUnequip({ pos = slot })
    network.send(msg)
end

local function SendCAssistPet(petSlot,assistSlot)
	local msg = lx.gs.pet.msg.CAssist({ petpos = petSlot,assistpos = assistSlot })
    network.send(msg)
end

local function SendCUnassistPet(slot)
	local msg = lx.gs.pet.msg.CUnassist({ assistpos = slot })
    network.send(msg)
end

local function SendCRecommendEquip(slot)
	local msg = lx.gs.equip.CRecommandEquip({ pos = slot })
    network.send(msg)
end

-- region msg
local function OnMsg_SSyncCapacity(msg)
	print("++++++++++++++++++++++OnMsg_SSyncCapacitys++++++++++++++++++++++++++++++++++++++++++++++++")
	print(msg.capacity)
    SetUnLockedSize(msg.bagtype, msg.capacity)
    if MsgCounter[msg.bagtype] >= 1 then 
        if msg.bagtype == cfg.bag.BagType.EQUIP 
            or msg.bagtype == cfg.bag.BagType.ITEM
		    or msg.bagtype == cfg.bag.BagType.TALISMAN 
            or msg.bagtype == cfg.bag.BagType.FRAGMENT then

            UIManager.refresh("playerrole.bag.tabbag")
        elseif msg.bagtype == cfg.bag.BagType.DEPOT_ITEM 
            or msg.bagtype == cfg.bag.BagType.DEPOT_EQUIP 
            or msg.bagtype == cfg.bag.BagType.DEPOT_FRAGMENT 
            or msg.bagtype == cfg.bag.BagType.DEPOT_TALISMAN 
            or msg.bagtype == cfg.bag.BagType.FAMILY_EQUIP then
            UIManager.refresh("dlgwarehouse")
        end
    end
end

--物品里面所有的数据
local function OnMsg_SSyncItems(msg)
	print("OnMsg_SSyncItems")
	-- 计算接收协议次数,用来区别刚登陆还是已在游戏中
	if MsgCounter[msg.bagtype] then
		MsgCounter[msg.bagtype] = MsgCounter[msg.bagtype] + 1
	end
	-- 装备推荐中新增装备
	local newEquips = nil
	local recmdRate = nil 
    if msg.bagtype == cfg.bag.BagType.EQUIP and MsgCounter[msg.bagtype] > 1 then
        newEquips = { }
        recmdRate = { } -- {key = 武器类型，value = { Index,MaxRate}}
    end
	-- 缓存所有入包物品，飘字用
	local newItems = { }

    for slot, serializedData in pairs(msg.iteminfo) do
        local datastream = octets.new(serializedData)
        if octets.size(datastream) == 0 then
            DeleteItem(msg.bagtype, slot)
        else
            local item = { }
            if msg.bagtype == cfg.bag.BagType.EQUIP
                or msg.bagtype == cfg.bag.BagType.EQUIP_BODY 
                or msg.bagtype == cfg.bag.BagType.DEPOT_EQUIP 
                or msg.bagtype == cfg.bag.BagType.FAMILY_EQUIP then
                -- 装备
                local itemData = octets.pop_lx_gs_equip_Equip(datastream)
                item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, 1)
            elseif msg.bagtype == cfg.bag.BagType.ITEM 
                or msg.bagtype == cfg.bag.BagType.GEMSTONE 
                or msg.bagtype == cfg.bag.BagType.DEPOT_ITEM then
                -- 物品
				print("OnMsg_SSyncItems_pop_lx_gs_item_Item")
                local itemData = octets.pop_lx_gs_item_Item(datastream)
                item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, itemData.count)

				if MsgCounter[msg.bagtype] <= 1 and item:GetDetailType() == ItemEnum.ItemType.Medicine and item:GetCDGroupId() ~= cfg.Const.NULL then
					-- 单位为毫秒
					local LimitManager  = require("limittimemanager")
					local expireTime = LimitManager.GetExpireTime(cfg.cmd.ConfigId.ITEMBASIC,item:GetCDGroupId())
					if expireTime and expireTime ~= 0 then 
						expireTime = math.ceil(expireTime/1000)
						local cdData = item:GetCDData()
                        if cdData then 
						    cdData:BeginCD(expireTime)
                        end
					end
				end
            elseif msg.bagtype == cfg.bag.BagType.FRAGMENT 
                or msg.bagtype == cfg.bag.BagType.DEPOT_FRAGMENT then
                -- 碎片
                local itemData = octets.pop_lx_gs_fragment_Fragment(datastream)
                item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, itemData.count)
            elseif msg.bagtype == cfg.bag.BagType.TALISMAN
                or msg.bagtype == cfg.bag.BagType.TALISMAN_BODY 
                or msg.bagtype == cfg.bag.BagType.DEPOT_TALISMAN then
                -- 法宝
                local itemData = octets.pop_lx_gs_talisman_Talisman(datastream)
                item = ItemManager.CreateItemBaseById(itemData.modelid, itemData, 1)
            end
            -- 加入指定类型背包中
            if slot ~= item:GetBagPos() then
				print("BagManager:Bag Data Error")
            end
            AddItem(msg.bagtype, item:GetBagPos(), item)
			-- 仅缓存属于背包的物品，且新入包，后续代码统一处理飘字
			if (msg.bagtype == cfg.bag.BagType.EQUIP or msg.bagtype == cfg.bag.BagType.ITEM
				or msg.bagtype == cfg.bag.BagType.TALISMAN or msg.bagtype == cfg.bag.BagType.FRAGMENT)
				and item.bNewAdded then

				newItems[#newItems + 1] = item
			end

            local transportData = ConfigManager.getConfig("transport")
            if item and transportData and(transportData.requireitemid) and(item:GetConfigId() == transportData.requireitemid.itemid) then
                if PlayerRole:Instance():IsNavigating() and UIManager.isshow("dlguimain") then
                    UIManager.call("dlguimain", "SetTargetHoming", { pathFinding = true })
                end
            end
			-- 装备推荐，符合推荐条件加入
			if msg.bagtype == cfg.bag.BagType.EQUIP and MsgCounter[msg.bagtype] > 1 then
				if item:IsMainEquip() and item.bNewAdded and (item:GetProfessionLimit() == cfg.Const.NULL or item:GetProfessionLimit() == PlayerRole:Instance().m_Profession)
					and PlayerRole:Instance():GetLevel() >= item:GetLevel() then

					local equipsOnBody = GetItemByType(cfg.bag.BagType.EQUIP_BODY,item:GetDetailType())
					if #equipsOnBody ~= 0 then
						if item:GetRecommendRate() > equipsOnBody[1]:GetRecommendRate() then
							-- 加入推荐列表(同一类型准备只保留推荐值最高的)
							if recmdRate[item:GetDetailType()] then
								if item:GetRecommendRate() > recmdRate[item:GetDetailType()].MaxRate then
									table.remove(newEquips,recmdRate[item:GetDetailType()].Index)
									recmdRate[item:GetDetailType()].MaxRate = item:GetRecommendRate()
									recmdRate[item:GetDetailType()].Index = #newEquips + 1
									newEquips[#newEquips + 1] = item
								end
							else
								recmdRate[item:GetDetailType()] = { }
								recmdRate[item:GetDetailType()].MaxRate = item:GetRecommendRate()
								recmdRate[item:GetDetailType()].Index = #newEquips + 1
								newEquips[#newEquips + 1] = item
							end

						end
					else
						-- 加入推荐列表(同一类型准备只保留推荐值最高的)
						if recmdRate[item:GetDetailType()] then
							if item:GetRecommendRate() > recmdRate[item:GetDetailType()].MaxRate then
								table.remove(newEquips,recmdRate[item:GetDetailType()].Index)
								recmdRate[item:GetDetailType()].MaxRate = item:GetRecommendRate()
								recmdRate[item:GetDetailType()].Index = #newEquips + 1
								newEquips[#newEquips + 1] = item
							end
						else
							recmdRate[item:GetDetailType()] = { }
							recmdRate[item:GetDetailType()].MaxRate = item:GetRecommendRate()
							recmdRate[item:GetDetailType()].Index = #newEquips + 1
							newEquips[#newEquips + 1] = item
						end
					end
				end

			end
        end
    end
    -- 登录时，第一次接收SSyncitems协议(登陆时同步)，
	-- 清除New状态
    if MsgCounter[msg.bagtype] <= 1 then
        ResetBagNewStatus(msg.bagtype)
    end

	if msg.bagtype == cfg.bag.BagType.EQUIP or msg.bagtype == cfg.bag.BagType.ITEM
		or msg.bagtype == cfg.bag.BagType.TALISMAN or msg.bagtype == cfg.bag.BagType.FRAGMENT then

		if MsgCounter[msg.bagtype] <= 1 then
            if msg.bagtype == cfg.bag.BagType.ITEM then 
                local items = GetItemByType(cfg.bag.BagType.ITEM, ItemEnum.ItemType.Medicine)
                utils.clear_table(itemsInCD)
                for _,item in ipairs(items) do
                    local cdData = item:GetCDData()
                    if cdData and (not cdData:IsReady()) then 
                        itemsInCD[#itemsInCD + 1] = item
                    end
                end
            end
		else
			-- 飘字统一在背包处理
			--TODOCanFlyTextlotteryItemData(newItems)为在招募界面做出招募法宝碎片的处理
			if  CanShowFlyText()   then 
				if CanFlyTextlotteryItemData(newItems) then
					if IsBlendLotteryData(newItems) then
						for _, newItem in ipairs(newItems) do
							UIManager.ShowSyncItem(newItem)
						end
					end
				else
					for _, newItem in ipairs(newItems) do
						UIManager.ShowSyncItem(newItem)
					end
				end

			end
            UIManager.refresh("playerrole.bag.tabbag")

            if msg.bagtype == cfg.bag.BagType.EQUIP then
                -- 仓库处理饰品转移
                UIManager.refresh("dlgwarehouse")
                --聚宝盆界面刷新
                UIManager.refresh("cornucopia.tabtreasurebowl")
            end
            -- 装备自动推荐功能
		    -- 同时加入的装备会按照推荐指数排序;非同时加入的装备，要与当前推荐列表对比，留下比当前列表中同种类型推荐值高的装备
		    -- 在收到一次SSyncItems协议时，获得的装备算作同时获得的，其他属于非同时获得
		    if msg.bagtype == cfg.bag.BagType.EQUIP and #newEquips ~= 0 then
			    utils.table_sort(newEquips,Sort4)
			    for _,eqp in ipairs(newEquips) do
				    -- 要比推荐装备列表中的同类装备推荐值高才会加入推荐列表
				    local bRecmded = false
				    local bFindSameType = false
				    for _,recmdedEquip in ipairs(recmdedEquips) do
					    if eqp:GetDetailType() == recmdedEquip:GetDetailType() then
						    bFindSameType = true
						    if eqp:GetPower() > recmdedEquip:GetPower() then
							    bRecmded = true
						    end
					    end
				    end
				    if not bFindSameType then bRecmded = true end

				    if bRecmded then
					    recmdedEquips[#recmdedEquips + 1] = eqp
				    end
			    end
			    -- 只有UIMain显示时候才会显示推荐
			    if UIManager.hasloaded("dlguimain") then
				    local recmdEquipPanel = require("ui.uimain.recommendequip")
				    recmdEquipPanel.show()
			    elseif EctypeManager.IsInEctype() then
					
			    else
				    -- 清空数据
					--printyellow(" utils.clear_table(recmdedEquips)")
				   -- utils.clear_table(recmdedEquips)
			    end
		    end
		end
	end

	if msg.bagtype == cfg.bag.BagType.EQUIP_BODY 
	or msg.bagtype == cfg.bag.BagType.GEMSTONE
        or msg.bagtype == cfg.bag.BagType.TALISMAN_BODY then
		-- 1.登录时，第一次接收SSyncitems协议(登陆时同步)
		-- 2.玩家身上装备id加入到背包中，用于处理登陆后第一次卸载出现New状态问题
        if MsgCounter[msg.bagtype] <= 1 then 
			local itemsOnBody = GetItems(msg.bagtype)
			local bag = GetBag(BODYBAG_TO_COMMONBAG[msg.bagtype])
			for _,item in pairs(itemsOnBody) do
				bag:AddId(item:GetId())
			end
        else
            if msg.bagtype == cfg.bag.BagType.EQUIP_BODY then
                UIManager.refresh("playerrole.equip.tabequip") 
			elseif msg.bagtype == cfg.bag.BagType.TALISMAN_BODY then 
				if UIManager.isshow("playerrole.talisman.tabtalisman") then
					UIManager.refresh("playerrole.talisman.tabtalisman")
				end
            end 
        end
	end

    if msg.bagtype == cfg.bag.BagType.DEPOT_ITEM 
        or msg.bagtype == cfg.bag.BagType.DEPOT_EQUIP 
        or msg.bagtype == cfg.bag.BagType.DEPOT_FRAGMENT 
        or msg.bagtype == cfg.bag.BagType.DEPOT_TALISMAN 
        or msg.bagtype == cfg.bag.BagType.FAMILY_EQUIP then
        -- 1.登录时，第一次接收SSyncitems协议(登陆时同步)
		-- 2.玩家身上装备id加入到背包中，用于处理登陆后第一次卸载出现New状态问题
        if MsgCounter[msg.bagtype] <= 1 then 
			local itemsInDepot = GetItems(msg.bagtype)
			local bag = GetBag(DEPOT_TO_COMMONBAG[msg.bagtype])
			for _,item in pairs(itemsInDepot) do
				bag:AddId(item:GetId())
			end
            if msg.bagtype == cfg.bag.BagType.FAMILY_EQUIP then 
                UIManager.showorrefresh("dlgwarehouse")
            end
        else 
            if msg.bagtype == cfg.bag.BagType.FAMILY_EQUIP then 
                UIManager.showorrefresh("dlgwarehouse")
            else
                UIManager.refresh("dlgwarehouse")
            end
        end
    end

    -- 红点刷新
	if UIManager.hasloaded("dlguimain") then
		UIManager.call("dlguimain", "RefreshRedDotType", cfg.ui.FunctionList.BAG)
	end
end

-- 整理 回调
local function OnMsg_SSort(msg)

	local preBag       = GetBag(msg.bagtype)
	local unLockedSize = preBag:GetUnLockedSize()
	local totalSize    = preBag:GetTotalSize()
	local newBag       = CommonBag:new(msg.bagtype,unLockedSize,totalSize)

	local preItems = preBag:GetItems()
	local bBagPosChanged = { }
	for _,item in ipairs(preItems) do
		bBagPosChanged[item:GetBagPos()] = false
	end
	-- 处理位置变化的
	for preBagPos,newBagPos in pairs(msg.itempos) do
		bBagPosChanged[preBagPos] = true
		local item = preBag:GetItemBySlot(preBagPos)
		newBag:AddItem(newBagPos,item)
	end
	-- 处理位置未变化的
	for pos,bPosChanged in pairs(bBagPosChanged) do
		if bPosChanged == false then
			local item = preBag:GetItemBySlot(pos)
			newBag:AddItem(pos,item)
		end
	end
	newBag:ResetNewStatus()
	if msg.bagtype == cfg.bag.BagType.EQUIP
			or msg.bagtype == cfg.bag.BagType.TALISMAN then
		local itemsOnBody = GetItems(msg.bagtype)
		local bag = GetBag(COMMONBAG_TO_BODYBAG[msg.bagtype])
		for _, item in pairs(bag:GetItems()) do
			newBag:AddId(item:GetId())
		end
	end
	SetBag(msg.bagtype,newBag)
	UIManager.refresh("playerrole.bag.tabbag")
    UIManager.refresh("dlgwarehouse")

end

local function OnMsg_SChange(msg)
    local item = GetItemBySlot(msg.bagtype, msg.pos)
    local preNum = item:GetNumber()
    item:AddNumber(msg.newnum - preNum)
	getnumber = msg.newnum - preNum
	-- 获取飘字统一在背包处理
	if (msg.bagtype == cfg.bag.BagType.EQUIP 
		or msg.bagtype == cfg.bag.BagType.ITEM
		or msg.bagtype == cfg.bag.BagType.TALISMAN 
		or msg.bagtype == cfg.bag.BagType.FRAGMENT) 
		and (msg.newnum - preNum) > 0 
		and (CanShowFlyText())then 
		if  CanFlyTextlotteryItemData(item) then
			if IsBlendLotteryData(item) then
				UIManager.ShowSyncItem(item,getnumber)
			end
		else
			if msg.showfly == 1 then 
				UIManager.ShowSyncItem(item,getnumber)
			end
		end 
		
	
	end
	UIManager.refresh("playerrole.bag.tabbag")
    UIManager.refresh("dlgwarehouse")
end

local function OnMsg_SItemBind(msg)
	local item = GetItemBySlot(msg.bagtype,msg.pos)
	if item then
		item:SetBound(true)
		UIManager.refresh("playerrole.bag.tabbag")
	end
end

local function OnMsg_SChangeAttrs(msg)
	-- 战力变化，刷新
    if UIManager.isshow("playerrole.equip.tabequip") then
	    UIManager.call("playerrole.equip.tabequip","RefreshPlayerInfo")
    end
end

local function OnMsg_SRecommandEquip(msg)
	if msg.result == 0 then
		local recmdEquipPanel = require("ui.uimain.recommendequip")
		table.remove(recmdedEquips, 1)
		recmdEquipPanel.SetEquipBox()
		UIManager.ShowSystemFlyText(LocalString.Bag_RecommendEquip_Success)
	end
end


local function OnCDChange(params)
	local id,moduleId,expireTime = unpack(params)
	if moduleId ~= cfg.cmd.ConfigId.ITEMBASIC  then
		return 
	end 
	-- id可能为物品配置id或者CD组的id
	local medicineItems = { }
	local items = GetItemByType(cfg.bag.BagType.ITEM, ItemEnum.ItemType.Medicine)

	--优先搜索组Id
	for _, item in pairs(items) do
		if (item:GetDetailType2() == cfg.item.MedicineType.GREEN or item:GetDetailType2() == cfg.item.MedicineType.WHITE)
			and item:GetCDGroupId() == id then
			medicineItems[#medicineItems + 1] = item
		end
	end
	if #medicineItems == 0 then
		--此id为配置id，而不是组id，搜索配置id
		for _, item in pairs(items) do
				if (item:GetDetailType2() == cfg.item.MedicineType.GREEN or item:GetDetailType2() == cfg.item.MedicineType.WHITE)
				and item:GetConfigId() == id then
				medicineItems[#medicineItems + 1] = item
			end
		end
	end

	for _,item in ipairs(medicineItems) do
		if item.CDData then
			item.CDData:BeginCD(expireTime)
		end
	end

    utils.clear_table(itemsInCD)
    for _,item in ipairs(items) do
        local cdData = item:GetCDData()
        if not cdData:IsReady() then 
            itemsInCD[#itemsInCD + 1] = item
        end
    end
end
-- 清除new状态回调
local function OnResetNewStatus(params)
	if params.name == "playerrole.dlgplayerrole" then
		ResetNewStatus()
	end
end

local function Release()
    -- 初始化数据
	MsgCounter =
	{
		-- common bag
		[cfg.bag.BagType.EQUIP]         = 0,
		[cfg.bag.BagType.ITEM]          = 0,
		[cfg.bag.BagType.FRAGMENT]      = 0,
		[cfg.bag.BagType.TALISMAN]      = 0,
        -- depot
        [cfg.bag.BagType.DEPOT_EQUIP]   = 0,
		[cfg.bag.BagType.DEPOT_ITEM]    = 0,
		[cfg.bag.BagType.DEPOT_FRAGMENT]= 0,
		[cfg.bag.BagType.DEPOT_TALISMAN]= 0,
        -- family depot
        [cfg.bag.BagType.FAMILY_EQUIP]  = 0,
		-- body bag
		[cfg.bag.BagType.EQUIP_BODY]    = 0,
		[cfg.bag.BagType.TALISMAN_BODY] = 0,
	}
    utils.clear_table(bagsInfo)
    local bagData = ConfigManager.getConfig("bagconfig")
    bagsInfo =
    {
        -- common bag
        [cfg.bag.BagType.EQUIP]         = CommonBag:new(cfg.bag.BagType.EQUIP,bagData[cfg.bag.BagType.EQUIP].initcapacity,bagData[cfg.bag.BagType.EQUIP].maxcapacity),
        [cfg.bag.BagType.ITEM]          = CommonBag:new(cfg.bag.BagType.ITEM,bagData[cfg.bag.BagType.ITEM].initcapacity,bagData[cfg.bag.BagType.ITEM].maxcapacity),
        [cfg.bag.BagType.FRAGMENT]      = CommonBag:new(cfg.bag.BagType.FRAGMENT,bagData[cfg.bag.BagType.FRAGMENT].initcapacity,bagData[cfg.bag.BagType.FRAGMENT].maxcapacity),
        [cfg.bag.BagType.TALISMAN]      = CommonBag:new(cfg.bag.BagType.TALISMAN,bagData[cfg.bag.BagType.TALISMAN].initcapacity,bagData[cfg.bag.BagType.TALISMAN].maxcapacity),
        -- depot
        [cfg.bag.BagType.DEPOT_EQUIP]   = CommonBag:new(cfg.bag.BagType.DEPOT_EQUIP,bagData[cfg.bag.BagType.DEPOT_EQUIP].initcapacity,bagData[cfg.bag.BagType.DEPOT_EQUIP].maxcapacity),
		[cfg.bag.BagType.DEPOT_ITEM]    = CommonBag:new(cfg.bag.BagType.DEPOT_ITEM,bagData[cfg.bag.BagType.DEPOT_ITEM].initcapacity,bagData[cfg.bag.BagType.DEPOT_ITEM].maxcapacity),
		[cfg.bag.BagType.DEPOT_FRAGMENT]= CommonBag:new(cfg.bag.BagType.DEPOT_FRAGMENT,bagData[cfg.bag.BagType.DEPOT_FRAGMENT].initcapacity,bagData[cfg.bag.BagType.DEPOT_FRAGMENT].maxcapacity),
		[cfg.bag.BagType.DEPOT_TALISMAN]= CommonBag:new(cfg.bag.BagType.DEPOT_TALISMAN,bagData[cfg.bag.BagType.DEPOT_TALISMAN].initcapacity,bagData[cfg.bag.BagType.DEPOT_TALISMAN].maxcapacity),
		-- family depot
        [cfg.bag.BagType.FAMILY_EQUIP]  = CommonBag:new(cfg.bag.BagType.FAMILY_EQUIP,bagData[cfg.bag.BagType.FAMILY_EQUIP].initcapacity,bagData[cfg.bag.BagType.FAMILY_EQUIP].maxcapacity),
        -- body bag
        [cfg.bag.BagType.EQUIP_BODY]    = BodyBag:new(cfg.bag.BagType.EQUIP_BODY,8,8),
        [cfg.bag.BagType.TALISMAN_BODY] = BodyBag:new(cfg.bag.BagType.TALISMAN_BODY,1,1),
    }
    utils.clear_table(itemsInCD)
	utils.clear_table(recmdedEquips)
end

local function OnLogout()
	Release()
end

local function Update()
	-- itemsInCD是背包中所有的药品
    if #itemsInCD ~= 0 then
        local bInCD = false
	    for _, item in ipairs(itemsInCD) do
	        local cdData = item:GetCDData()
	        cdData:Update()
            if (not cdData:IsReady()) and (not bInCD) then
                bInCD = true
            end
	    end
        if not bInCD then 
            utils.clear_table(itemsInCD)
        end
    end

end
-- 红点提示
local function UnReadType(bagType)
    local bagItems = GetItems(bagType)
    for _, item in pairs(bagItems) do
        if item.bNewAdded then
            -- 有新增物品即显示红点
            return true
        end
    end
    return false
end
-- 显示红点
local function UnRead()
	if chickState then  --- 红点特殊处理
		for bagType, _ in pairs(bagsInfo) do
			local bUnRead = UnReadType(bagType)
			if bUnRead then
				return true
			end
		end
		return false
	else
		return chickState
	end
end

local function UpdateChickState(state)
	chickState = state
end


---主界面背包红点方法
local function UnUimainRead()
	chickState = true
	local StoryNoteManager   = require("ui.playerrole.storynote.storynotemanager")
	local tabtalismanManager = require("ui.playerrole.talisman.tabtalisman")
	if tabtalismanManager.UnRead() or UnRead() then --or StoryNoteManager.UnRead()--fenghualu
		return true
	else
		return false
	end
end

local function init()
    -- 初始化数据
    utils.clear_table(bagsInfo)
    local bagData = ConfigManager.getConfig("bagconfig")
    bagsInfo =
    {
        -- common bag
        [cfg.bag.BagType.EQUIP]         = CommonBag:new(cfg.bag.BagType.EQUIP,bagData[cfg.bag.BagType.EQUIP].initcapacity,bagData[cfg.bag.BagType.EQUIP].maxcapacity),
        [cfg.bag.BagType.ITEM]          = CommonBag:new(cfg.bag.BagType.ITEM,bagData[cfg.bag.BagType.ITEM].initcapacity,bagData[cfg.bag.BagType.ITEM].maxcapacity),
        [cfg.bag.BagType.FRAGMENT]      = CommonBag:new(cfg.bag.BagType.FRAGMENT,bagData[cfg.bag.BagType.FRAGMENT].initcapacity,bagData[cfg.bag.BagType.FRAGMENT].maxcapacity),
        [cfg.bag.BagType.TALISMAN]      = CommonBag:new(cfg.bag.BagType.TALISMAN,bagData[cfg.bag.BagType.TALISMAN].initcapacity,bagData[cfg.bag.BagType.TALISMAN].maxcapacity),
        -- depot
        [cfg.bag.BagType.DEPOT_EQUIP]   = CommonBag:new(cfg.bag.BagType.DEPOT_EQUIP,bagData[cfg.bag.BagType.DEPOT_EQUIP].initcapacity,bagData[cfg.bag.BagType.DEPOT_EQUIP].maxcapacity),
		[cfg.bag.BagType.DEPOT_ITEM]    = CommonBag:new(cfg.bag.BagType.DEPOT_ITEM,bagData[cfg.bag.BagType.DEPOT_ITEM].initcapacity,bagData[cfg.bag.BagType.DEPOT_ITEM].maxcapacity),
		[cfg.bag.BagType.DEPOT_FRAGMENT]= CommonBag:new(cfg.bag.BagType.DEPOT_FRAGMENT,bagData[cfg.bag.BagType.DEPOT_FRAGMENT].initcapacity,bagData[cfg.bag.BagType.DEPOT_FRAGMENT].maxcapacity),
		[cfg.bag.BagType.DEPOT_TALISMAN]= CommonBag:new(cfg.bag.BagType.DEPOT_TALISMAN,bagData[cfg.bag.BagType.DEPOT_TALISMAN].initcapacity,bagData[cfg.bag.BagType.DEPOT_TALISMAN].maxcapacity),
		-- family depot
        [cfg.bag.BagType.FAMILY_EQUIP]  = CommonBag:new(cfg.bag.BagType.FAMILY_EQUIP,bagData[cfg.bag.BagType.FAMILY_EQUIP].initcapacity,bagData[cfg.bag.BagType.FAMILY_EQUIP].maxcapacity),
        -- body bag
        [cfg.bag.BagType.EQUIP_BODY]    = BodyBag:new(cfg.bag.BagType.EQUIP_BODY,8,8),
        [cfg.bag.BagType.TALISMAN_BODY] = BodyBag:new(cfg.bag.BagType.TALISMAN_BODY,1,1),
    }
    network.add_listeners( {
        { "lx.gs.bag.msg.SSyncCapacity", OnMsg_SSyncCapacity },
        { "lx.gs.bag.msg.SSyncItems", OnMsg_SSyncItems },
        { "lx.gs.bag.msg.SChange", OnMsg_SChange },
        { "lx.gs.bag.msg.SItemBind", OnMsg_SItemBind },
		{ "lx.gs.bag.msg.SSort", OnMsg_SSort },
		-- 人物属性变化(包括战力)
		{ "lx.gs.role.msg.SChangeAttrs", OnMsg_SChangeAttrs },
		{ "lx.gs.equip.SRecommandEquip", OnMsg_SRecommandEquip },
    } ,"bagmanager")
    gameevent.evt_update:add(Update)

	-- 改变CD的回调函数
	gameevent.evt_cdchange:add(OnCDChange)
	gameevent.evt_resetnewstatus:add(OnResetNewStatus)
	gameevent.evt_system_message:add("logout", OnLogout)

	gameevent.evt_notify:add("loadscene_end", OnNotifyLoadSceneEnd)
end

return {

    init                    = init,
    GetBag                  = GetBag,
    ResetBag                = ResetBag,
    GetItems                = GetItems,
    GetTotalSize            = GetTotalSize,
    SetTotalSize            = SetTotalSize,
    GetLockedSize           = GetLockedSize,
    GetUnLockedSize         = GetUnLockedSize,
    SetUnLockedSize         = SetUnLockedSize,
    GetItemSlotsNum         = GetItemSlotsNum,
    GetItemBySlot           = GetItemBySlot,
    GetItemNumById          = GetItemNumById,
    GetItemById             = GetItemById,
    GetItemByType           = GetItemByType,
    ResetNewStatus          = ResetNewStatus,
	GetRecommendEquips		= GetRecommendEquips,
    -- common functions for depot and bag
    InitBagSlotList         = InitBagSlotList, 
    RefreshBagList          = RefreshBagList,
    WrapContentItemInit     = WrapContentItemInit,
    SetBagSlotBasicInfo     = SetBagSlotBasicInfo,
    ResetBagListToTop       = ResetBagListToTop,
    ResetBagSlot            = ResetBagSlot,

    -- send
    SendCSortBag            = SendCSortBag,
    SendCSell               = SendCSell,
    SendCBatchSell          = SendCBatchSell,
    SendCSplitItem          = SendCSplitItem,
    SendCUnlockGrid         = SendCUnlockGrid,
    SendCUseItem            = SendCUseItem,
    SendCCompoundFragment   = SendCCompoundFragment,
    SendCLoadEquip          = SendCLoadEquip,
    SendCUnloadEquip        = SendCUnloadEquip,
	SendCEquipTalisman	    = SendCEquipTalisman,
	SendCUnEquipTalisman    = SendCUnEquipTalisman,
	SendCEquipPet		    = SendCEquipPet,
	SendCUnequipPet		    = SendCUnequipPet,
	SendCAssistPet		    = SendCAssistPet,
	SendCUnassistPet	    = SendCUnassistPet,
	SendCRecommendEquip	    = SendCRecommendEquip,

    GetHPItem			    = GetHPItem,
    GetMPItem			    = GetMPItem,

    GetMainEquipsOnBody     = GetMainEquipsOnBody,
    GetAccessoriesOnBody    = GetAccessoriesOnBody,
    GetMainEquipsInBag      = GetMainEquipsInBag,
    GetAccessoriesInBag     = GetAccessoriesInBag,

    UnRead                  = UnRead,
	UnReadType              = UnReadType,
	UpdateChickState        = UpdateChickState,
	AddItem				    = AddItem,
	DeleteItem			    = DeleteItem,
	CanShowFlyText          = CanShowFlyText,
	UnUimainRead            = UnUimainRead,
	ResetBagNewStatus       = ResetBagNewStatus,
	CanFlyTextlotteryItemData = CanFlyTextlotteryItemData,
}
