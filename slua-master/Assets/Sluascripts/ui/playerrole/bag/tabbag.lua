local unpack              = unpack
local print               = print
local require             = require
local format              = string.format
local ItemEnum            = require("item.itemenum")
local UIManager           = require("uimanager")
local network             = require("network")
local CheckCmd            = require("common.checkcmd")
local PlayerRole          = require("character.playerrole")
local ConfigManager       = require("cfg.configmanager")
local BagManager          = require("character.bagmanager")
local ItemIntroduct       = require("item.itemintroduction")
local CheckCmd            = require("common.checkcmd")
local ItemManager         = require("item.itemmanager")
local EctypeManager       = require("ectype.ectypemanager")
local EventHelper         = UIEventListenerHelper
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")

local name
local gameObject
local fields

-- 背包信息
-- 全局变量
local g_SelectedBagType
local g_SelectedItem = nil
local g_InitPanelLocalPos
local g_InitPanelOffsetY
local g_CachedListItems

local bIsExchange = false

local BAG_SELECT_TABS =
{
    [cfg.bag.BagType.ITEM]     = 3,
    [cfg.bag.BagType.EQUIP]    = 0,
    [cfg.bag.BagType.FRAGMENT] = 2,
    [cfg.bag.BagType.TALISMAN] = 1,
}

local bBagRadioButtonClicked =
{
    [cfg.bag.BagType.ITEM]     = false,
    [cfg.bag.BagType.EQUIP]    = false,
    [cfg.bag.BagType.FRAGMENT] = false,
    [cfg.bag.BagType.TALISMAN] = false,
}

--设置背包格子里面item的数据
local function SetBagSlot(listItem, item, bagType)
    BagManager.SetBagSlotBasicInfo(listItem, item, bagType)

    local collider = listItem.gameObject.transform:GetComponent("BoxCollider")
    if bIsExchange == true then --是否可以交易
        local ExchangeMgr = require "ui.exchange.exchangemanager"
        local result = ExchangeMgr.CanExchange(item)
        listItem.Controls["UISprite_GrayMask"].gameObject:SetActive(not result)
    else
        listItem.Controls["UISprite_GrayMask"].gameObject:SetActive(false)
    end
end

--暂时存储背包里面的所有数据
local function CacheListItems()
    local tempList = { }
    for i = 1, fields.UIList_Bag.Count do
        local listItem = fields.UIList_Bag:GetItemByIndex(i - 1)
        tempList[#tempList + 1] = listItem
    end
    return tempList
end
local function BagItemInit(go, index, realIndex)
    BagManager.WrapContentItemInit(go, index, realIndex, g_SelectedBagType, SetBagSlot)
end

local function InitBagSlotList(bagType)
    BagManager.InitBagSlotList(bagType, fields.UIList_Bag, BagItemInit)
end

local function RefreshBagInfo(bagType)
    BagManager.RefreshBagList(fields.UIList_Bag)
    fields.UILabel_BagItemAmount.text = BagManager.GetItemSlotsNum(bagType) .. "/" .. BagManager.GetTotalSize(bagType)
end

local function RefreshBagItemPos(offValue)
    local defaultPosY = 18
    local defaultClipy = 26
    local origiPos = fields.UIScrollView_Bag.transform.localPosition
    fields.UIScrollView_Bag.transform.localPosition = Vector3(origiPos.x, defaultPosY + offValue, origiPos.z)
    local UIPanel_Clip = fields.UIScrollView_Bag.transform:GetComponent("UIPanel")
    UIPanel_Clip.clipOffset = Vector2(UIPanel_Clip.clipOffset.x, defaultClipy - offValue)
end

local function ResetBagListToTop(bagType)
    BagManager.ResetBagListToTop(fields.UIScrollView_Bag, fields.UIList_Bag, g_InitPanelLocalPos, g_InitPanelOffsetY)
    fields.UILabel_BagItemAmount.text = BagManager.GetItemSlotsNum(bagType) .. "/" .. BagManager.GetTotalSize(bagType)
end

local function PutAway(params)
    local num =(not params.num) and 1 or params.num

    if params.price <= 0 then
        UIManager.ShowSingleAlertDlg( { content = LocalString.Exchange_InvalidPrice })
    elseif params.price >= 100000 then
        UIManager.ShowSingleAlertDlg( { content = LocalString.Exchange_InvalidExceedMaxPrice })
    elseif (num <= 0) or(num > g_SelectedItem:GetNumber()) then
        UIManager.ShowSingleAlertDlg( { content = LocalString.Exchange_InvalidNum })
    else
        local params = { bagType = g_SelectedBagType, bagPos = g_SelectedItem:GetBagPos(), num = num, unitPrice = params.price }
        local ExchangeMgr = require "ui.exchange.exchangemanager"
        ExchangeMgr.SendCAddItem(params)
    end
end

local function RefreshRedDot()
    for bagType, tabIndex in pairs(BAG_SELECT_TABS) do
        local listItem = fields.UIList_BagRadioButton:GetItemByIndex(tabIndex)
        listItem.Controls["UISprite_Warning"].gameObject:SetActive(BagManager.UnReadType(bagType))
        UIManager.RefreshRedDot()
    end
end

local function refresh(params)
    -- print(name, "refresh")
    if bIsExchange or(params and params.exchange) or UIManager.isshow("exchange.tabexchangesell") then
        fields.UIButton_BatchSell.gameObject:SetActive(false)
        fields.UIButton_MixingDevice.gameObject:SetActive(false)
        bIsExchange = true
    else
        fields.UIButton_BatchSell.gameObject:SetActive(true)
        fields.UIButton_MixingDevice.gameObject:SetActive(true)
        bIsExchange = false
    end

    if params and params.BagSelectIndex then
        g_SelectedBagType = params.BagSelectIndex
    else
        g_SelectedBagType = g_SelectedBagType or cfg.bag.BagType.EQUIP
    end

    if params and params.BagSelectMenu == false then
        fields.UIList_BagRadioButton.gameObject:SetActive(false)
        fields.UISprite_BG.gameObject:SetActive(false)
    end
    -- 法宝会复用此界面，清除所有button选中状态
    for i = 0,(fields.UIList_BagRadioButton.Count - 1) do
        local listItem = fields.UIList_BagRadioButton:GetItemByIndex(i)
        listItem.Checkbox:Set(false)
    end

    fields.UIList_BagRadioButton:SetSelectedIndex(BAG_SELECT_TABS[g_SelectedBagType])

    RefreshBagInfo(g_SelectedBagType)
    -- 刷新红点提示
    RefreshRedDot()
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
   -- print(name, "show")
    if bIsExchange or(params and params.exchange) or UIManager.isshow("exchange.tabexchangesell") then
        fields.UIButton_BatchSell.gameObject:SetActive(false)
        fields.UIButton_MixingDevice.gameObject:SetActive(false)
        bIsExchange = true
    else
        fields.UIButton_BatchSell.gameObject:SetActive(true)
        fields.UIButton_MixingDevice.gameObject:SetActive(true)
        bIsExchange = false
    end
    -- 清除推荐列表
    local recmdEquipPanel = require("ui.uimain.recommendequip")
    recmdEquipPanel.RemoveRecmdedEquips()

    if params and params.BagSelectIndex then
        g_SelectedBagType = params.BagSelectIndex
    else
        g_SelectedBagType = g_SelectedBagType or cfg.bag.BagType.EQUIP
    end
    InitBagSlotList(g_SelectedBagType)
    g_CachedListItems = CacheListItems()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function hide()
    -- print(name, "hide")
    g_SelectedBagType = cfg.bag.BagType.EQUIP
    fields.UIList_BagRadioButton.gameObject:SetActive(true)
    fields.UISprite_BG.gameObject:SetActive(true)
    fields.UIList_BagRadioButton:SetSelectedIndex(BAG_SELECT_TABS[g_SelectedBagType])
    bIsExchange = false
end

local function update()
    -- 物品中的药品类有buff属性
    -- print(name,"update")
    if g_SelectedBagType == cfg.bag.BagType.ITEM then
        for i = 1, #g_CachedListItems do
            local cdData = g_CachedListItems[i].Data			
            if cdData then
				local cdtime = cdData:GetCDRatio()

                g_CachedListItems[i].Controls["UISprite_CD"].fillAmount = cdtime
            end
        end
    end

end

local function init(params)
    name, gameObject, fields = unpack(params)
    BagManager.UpdateChickState(true)
    local bagPanel = fields.UIScrollView_Bag.gameObject:GetComponent("UIPanel")
    g_InitPanelLocalPos = bagPanel.transform.localPosition
    g_InitPanelOffsetY = bagPanel:GetClipOffsetY()

    EventHelper.SetListClick(fields.UIList_BagRadioButton, function(listItem)

        if listItem.Controls["UISprite_Warning"].gameObject.activeSelf then
            listItem.Controls["UISprite_Warning"].gameObject:SetActive(false)
            BagManager.UpdateChickState(false)
            UIManager.RefreshRedDot()
        end
        local index = listItem.Index
        if listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.EQUIP] then
            g_SelectedBagType = cfg.bag.BagType.EQUIP
        elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.FRAGMENT] then
            g_SelectedBagType = cfg.bag.BagType.FRAGMENT
        elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.ITEM] then
            g_SelectedBagType = cfg.bag.BagType.ITEM
        elseif listItem.Index == BAG_SELECT_TABS[cfg.bag.BagType.TALISMAN] then
            g_SelectedBagType = cfg.bag.BagType.TALISMAN
        end
        -- 置顶
        ResetBagListToTop(g_SelectedBagType)
        bBagRadioButtonClicked[g_SelectedBagType] = true
        BagManager.ResetBagNewStatus(g_SelectedBagType)
    end )
    -- 整理
    EventHelper.SetClick(fields.UIButton_ClearUp, function()
        BagManager.SendCSortBag(g_SelectedBagType)
    end )
    -- 聚宝盆
    EventHelper.SetClick(fields.UIButton_MixingDevice, function()
        UIManager.showdialog("cornucopia.dlgcornucopia")
    end )
    EventHelper.SetListClick(fields.UIList_Bag, function(listItem)
        local bagWrapContent = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
        local realIndex = bagWrapContent:Index2RealIndex(listItem.Index)

        if UIManager.isshow("exchange.tabexchangesell") then
            local selectedItem = BagManager.GetItemBySlot(g_SelectedBagType, realIndex + 1)
            if selectedItem then
                g_SelectedItem = selectedItem
                if not selectedItem:IsBound() then
                    if selectedItem:GetConfigId() then
                        local exchangeData = ConfigManager.getConfigData("exchange", selectedItem:GetConfigId())
                        if exchangeData then
                            local params = { 
                                  bIsExchange = true,
                                  item = selectedItem, 
                                  priceType = cfg.currency.CurrencyType.YuanBao, 
                                  price = exchangeData.defaultyuanbao, 
                                  num = selectedItem:GetNumber(), 
                                  variablePrice = true, 
                                  buttons = { { display = true, text = LocalString.Exchange_Shelf, callFunc = PutAway }, { display = false, text = "", callFunc = nil } } }
                            ItemIntroduct.DisplayItem(params)
                        else
                            UIManager.ShowSingleAlertDlg( { content = LocalString.Exchange_NotInExchangeItemList })
                        end
                    end
                else
                    UIManager.ShowSingleAlertDlg( { content = LocalString.Exchange_AddUnBind })
                end
            end
            return
        end

        local selectedItem = nil
        if g_SelectedBagType == cfg.bag.BagType.ITEM then

            selectedItem = BagManager.GetItemBySlot(cfg.bag.BagType.ITEM, realIndex + 1)
            if selectedItem then
                local detailType = selectedItem:GetDetailType()
                --[[if detailType == ItemEnum.ItemType.Medicine then
                    local cdData = selectedItem:GetCDData()
                    if not cdData:IsReady() then
                        UIManager.ShowSystemFlyText(LocalString.Bag_ItemCDNotReady)
                        return
                    end
                end--]]


                local sellItemFunc = nil
                local bCanSell = false
                if selectedItem:CanSell() then
                    bCanSell = true
                    sellItemFunc = function(ps)
                        if ps.num > 0 and selectedItem:GetNumber() >= ps.num then
                            local params = { }
                            params.immediate = true
                            params.title = LocalString.Bag_Tip
                            params.content = LocalString.Bag_SellForSure
                            params.callBackFunc = function()
                                BagManager.SendCSell(cfg.bag.BagType.ITEM, selectedItem:GetBagPos(), ps.num)
                            end
                            UIManager.ShowAlertDlg(params)
                        elseif ps.num <= 0 then
                            UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumIllegal)
                        else
                            UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumNotEnough)
                        end
                    end
                end

                local useItemFunc = nil
                local bUseButtonDisplay = false
                local bNeedAutoHide = true
                -- 检查使用等级等信息是否满足条件
                local validated, info = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.ITEMBASIC, cmdid = selectedItem:GetConfigId(), num = 1, showsysteminfo = true })
                -- 目前强化类、经验类和宝石类不能使用
                if detailType ~= ItemEnum.ItemType.Exp
                    and detailType ~= ItemEnum.ItemType.Enhance
                    and detailType ~= ItemEnum.ItemType.Gemstone then
                    -- if detailType ~= ItemEnum.ItemType.Exp and detailType ~= ItemEnum.ItemType.Enhance then
                    if not validated then
                        bNeedAutoHide = false
                    end

                    useItemFunc = function(params)
                        if not validated and info and info ~= "" then
                            UIManager.ShowSystemFlyText(info)
                            return
                        end

                        if detailType == ItemEnum.ItemType.Medicine then
                            -- 药品有冷却时间无法批量使用
							local cdData = selectedItem:GetCDData()
                            if not cdData:IsReady() then
                            UIManager.ShowSystemFlyText(LocalString.Bag_ItemCDNotReady)
                            return
                        end
                            BagManager.SendCUseItem(selectedItem:GetBagPos(), 1)
						elseif detailType == ItemEnum.ItemType.Scene then 
							if PlayerRole.Instance():IsFighting() or EctypeManager.IsInEctype() or PlayerRole.Instance():IsRiding() then
								UIManager.ShowSystemFlyText(LocalString.Bag_CannotUseFirework)
							else
								--鞭炮无法批量使用
								BagManager.SendCUseItem(selectedItem:GetBagPos(), 1)
							end
                        else
                            if detailType == ItemEnum.ItemType.Riding then
                                local RideManager = require "ui.ride.ridemanager"
                                local ItemManager = require "item.itemmanager"
                                local ridingData = ItemManager.CreateItemBaseById(selectedItem:GetConfigId())
                                if RideManager.NotAcquired(ridingData:GetRidingId()) then
                                    BagManager.SendCUseItem(selectedItem:GetBagPos(), params.num)
                                else
                                    UIManager.ShowSystemFlyText(LocalString.Ride_AcquiredTip)
                                end
                            else
                                if params.num > 0 and selectedItem:GetNumber() >= params.num then
                                    -- 主要检查使用次数限制
                                    local validated, info = CheckCmd.Check( { moduleid = cfg.cmd.ConfigId.ITEMBASIC, cmdid = selectedItem:GetConfigId(), num = params.num, showsysteminfo = true })
                                    if validated then
                                        BagManager.SendCUseItem(selectedItem:GetBagPos(), params.num)
                                    end
                                elseif params.num <= 0 then
                                    UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumIllegal)
                                else
                                    UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumNotEnough)
                                end
                            end
                        end
                    end
                    bUseButtonDisplay = true
                end

                local splitItemFunc = nil
                local bSplitButtonDisplay = false

                -- 礼包类，时装，坐骑均不可拆分
                if detailType ~= ItemEnum.ItemType.GiftPack and detailType ~= ItemEnum.ItemType.Dress and
                    detailType ~= ItemEnum.ItemType.Riding and selectedItem:GetNumber() > 1 then

                    splitItemFunc = function(params)
                        if params.num > 0 and params.num < selectedItem:GetNumber() then
                            BagManager.SendCSplitItem(cfg.bag.BagType.ITEM, selectedItem:GetBagPos(), params.num)
                        elseif params.num <= 0 then
                            UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumIllegal)
                        else
                            UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumNotEnough)
                        end
                    end
                    bSplitButtonDisplay = true
                end

                ItemIntroduct.DisplayItem( {
                    item = selectedItem,
                    variableNum = true,
					forceShowItem = true,
					variablePrice  = true,
					forceShowSolidUnitPrice = true,
                    buttons =
                    {
                        { display = bCanSell, text = LocalString.BagAlert_Sell, callFunc = sellItemFunc },
                        { display = bUseButtonDisplay, text = LocalString.BagAlert_Use, callFunc = useItemFunc, autoHide = bNeedAutoHide },
                        { display = bSplitButtonDisplay, text = LocalString.BagAlert_Split, callFunc = splitItemFunc }
                    }
                } )
            end
        elseif g_SelectedBagType == cfg.bag.BagType.FRAGMENT then

            selectedItem = BagManager.GetItemBySlot(cfg.bag.BagType.FRAGMENT, realIndex + 1)
            if selectedItem then
                local sellFragFunc = function(ps)
                    if ps.num > 0 and selectedItem:GetNumber() >= ps.num then
                        local params = { }
                        params.immediate = true
                        params.title = LocalString.Bag_Tip
                        params.content = LocalString.Bag_SellForSure
                        params.callBackFunc = function()
                            BagManager.SendCSell(cfg.bag.BagType.FRAGMENT, selectedItem:GetBagPos(), ps.num)
                        end
                        UIManager.ShowAlertDlg(params)
                    elseif ps.num <= 0 then
                        UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumIllegal)
                    else
                        UIManager.ShowSystemFlyText(LocalString.Bag_ItemNumNotEnough)
                    end

                end

                local scText = nil
                local fragSourceOrCompandFunc = nil
                -- 目前碎片合成数量判断是绑定和非绑定的总和
                local totalFragNum = BagManager.GetItemNumById(selectedItem:GetConfigId(), cfg.bag.BagType.FRAGMENT)
                -- if selectedItem:GetNumber() < selectedItem:GetConvertNumber() then
                if totalFragNum < selectedItem:GetConvertNumber() then
                    scText = LocalString.BagAlert_FragSource
                    fragSourceOrCompandFunc = function() ItemManager.GetSource(selectedItem:GetConfigId(), "playerrole.dlgplayerrole") end
                else
                    scText = LocalString.BagAlert_CompoundFrag
                    fragSourceOrCompandFunc = function()
                        BagManager.SendCCompoundFragment(selectedItem:GetBagPos())
                    end
                end

                ItemIntroduct.DisplayItem( {
                    item = selectedItem,
                    variableNum = true,
                    buttons =
                    {
                        { display = true, text = LocalString.BagAlert_Sell, callFunc = sellFragFunc },
                        { display = false, text = "", callFunc = nil },
                        { display = true, text = scText, callFunc = fragSourceOrCompandFunc }
                    }
                } )
            end
        elseif g_SelectedBagType == cfg.bag.BagType.EQUIP then
            selectedItem = BagManager.GetItemBySlot(cfg.bag.BagType.EQUIP, realIndex + 1)
            if selectedItem then
                -- 卖出
                local sellEquipFunc = function()
                    -- 1.红色和橙色装备提示 2.强化过装备提示
                    if selectedItem:GetQuality() == cfg.item.EItemColor.ORANGE or selectedItem:GetQuality() == cfg.item.EItemColor.RED
                        or((selectedItem:GetAnnealLevel() > 0) or(selectedItem:GetPerfuseLevel() > 0)) then

                        local params = { }
                        params.immediate = true
                        params.title = LocalString.Bag_Tip
                        if ((selectedItem:GetAnnealLevel() > 0) or(selectedItem:GetPerfuseLevel() > 0)) then
                            params.content = colorutil.GetColorStr(colorutil.ColorType.Red, LocalString.Bag_RealSell2)
                        else
                            params.content = colorutil.GetColorStr(colorutil.ColorType.Red, LocalString.Bag_RealSell)
                        end
                        params.callBackFunc = function()
                            BagManager.SendCSell(cfg.bag.BagType.EQUIP, selectedItem:GetBagPos(), 1)
                        end
                        UIManager.ShowAlertDlg(params)
                    else
                        local params = { }
                        params.immediate = true
                        params.title = LocalString.Bag_Tip
                        params.content = LocalString.Bag_SellForSure
                        params.callBackFunc = function()
                            BagManager.SendCSell(cfg.bag.BagType.EQUIP, selectedItem:GetBagPos(), 1)
                        end
                        UIManager.ShowAlertDlg(params)
                    end
                end
                -- 装备和饰品强化函数
                local enhanceEquipFunc = function()

                    local detailType = selectedItem:GetDetailType()
                    if detailType == ItemEnum.EquipType.Bangle or
                        detailType == ItemEnum.EquipType.Necklace or
                        detailType == ItemEnum.EquipType.Ring then
                        -- 饰品
                        if selectedItem:GetLevel() <= PlayerRole:Instance():GetLevel() then
                            EquipEnhanceManager.SetEquip(selectedItem)
                            UIManager.showdialog("playerrole.equip.dlgaccessoryenhance")
                        else
                            UIManager.ShowSystemFlyText(LocalString.BagAlert_CanNotEnhanceEquip_NotEnoughLevel)
                        end
                    elseif detailType == ItemEnum.EquipType.Weapon or
                        detailType == ItemEnum.EquipType.Cloth or
                        detailType == ItemEnum.EquipType.Hat or
                        detailType == ItemEnum.EquipType.Shoe then
                        -- 装备
                        EquipEnhanceManager.SetEquip(selectedItem)
                        UIManager.showdialog("playerrole.equip.dlgequipenhance")
                    else
                        logError("Equip Type Error!")
                    end
                end

                local equipOnBody = BagManager.GetItemByType(cfg.bag.BagType.EQUIP_BODY, selectedItem:GetDetailType(), PlayerRole:Instance().m_Profession)
                -- 四大装备和饰品的装载
                local scText = LocalString.BagAlert_LoadEquip
                local loadEquipFunc = function() BagManager.SendCLoadEquip(selectedItem:GetBagPos()) end

                -- 所选装备与玩家装备职业不符合
                if selectedItem:GetProfessionLimit() ~= cfg.Const.NULL and
                    selectedItem:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
                    loadEquipFunc = function() UIManager.ShowSystemFlyText(LocalString.BagAlert_CanNotLoadEquip) end
                end

                if selectedItem:GetLevel() > PlayerRole:Instance():GetLevel() then
                    loadEquipFunc = function() UIManager.ShowSystemFlyText(LocalString.BagAlert_CanNotLoadEquip_NotEnoughLevel) end
                end
                local decomposeFunc = function()
                    local checkQuality = function()
                        local alertText = ""
                        if selectedItem:GetQuality() == cfg.item.EItemColor.ORANGE or selectedItem:GetQuality() == cfg.item.EItemColor.RED then
                            alertText = string.format(LocalString.CornuCopia_GetLingJingWithHighQuality,selectedItem:GetName(),selectedItem:GetDisassembly())                       
                        else
                            alertText = string.format(LocalString.CornuCopia_GetLingJing,selectedItem:GetName(),selectedItem:GetDisassembly())
                        end
                        local itemList = {}
                        table.insert(itemList,selectedItem:GetBagPos())
                        UIManager.ShowAlertDlg({immediate = true,content = alertText, callBackFunc = function()
                            local CompressManager = require("ui.cornucopia.compressmanager")
                            CompressManager.Decompose(itemList)
                        end})
                    end
                    if (selectedItem:GetAnnealLevel() > 0) or (selectedItem:GetPerfuseLevel() > 0) then
                        UIManager.ShowAlertDlg({immediate = true,content = LocalString.CornuCopia_Enhanced, callBackFunc = function()
                            checkQuality()
                        end})
                    else
                        checkQuality()
                    end
                end
                ItemIntroduct.DisplayItem( {
                    item = selectedItem,
                    item2 = equipOnBody[1],
                    variableNum = true,
                    buttons =
                    {
                        { display = true, text = LocalString.BagAlert_Sell, callFunc = sellEquipFunc },
                        { display = true, text = LocalString.BagAlert_UpdateEquip, callFunc = enhanceEquipFunc },
                        { display = true, text = scText, callFunc = loadEquipFunc },
                        --{ display = true, text = LocalString.CornuCopia_Decompose,callFunc = decomposeFunc }
                    }
                } )
            end
        elseif g_SelectedBagType == cfg.bag.BagType.TALISMAN then
            selectedItem = BagManager.GetItemBySlot(cfg.bag.BagType.TALISMAN, realIndex + 1)
            if selectedItem then
                UIManager.show("dlgalert_talisman", { item = selectedItem })
            end
        else
            logError("Selected bag type error")
        end

        if not selectedItem then
            -- 判断当前所选格子是否是被锁定的，锁定的格子提示开启花费，按照顺序开启
            local curUnlockedSize = BagManager.GetUnLockedSize(g_SelectedBagType)
            if (realIndex + 1) > curUnlockedSize then
                local unlockSlotCost = ConfigManager.getConfigData("bagconfig", g_SelectedBagType)
                local currency_cost = ItemManager.GetCurrencyData(unlockSlotCost.unlockgridcost)
                local unlockSlotNum =(realIndex + 1) - curUnlockedSize
                local params = { }
                params.immediate = true
                params.title = format(LocalString.Bag_UnlockSlot_Tip, currency_cost:GetNumber(), currency_cost:GetName())
                params.content = format(LocalString.Bag_UnlockSlots_TotalCost, unlockSlotNum,(currency_cost:GetNumber() * unlockSlotNum), currency_cost:GetName())
                params.callBackFunc = function()
                    local validate, info = CheckCmd.CheckData( { data = unlockSlotCost.unlockgridcost, num = unlockSlotNum, showsysteminfo = true })
                    if validate then
                        BagManager.SendCUnlockGrid(g_SelectedBagType, unlockSlotNum)
                    end
                end
                UIManager.ShowAlertDlg(params)
            end
        end
    end )

    EventHelper.SetClick(fields.UIButton_BatchSell, function()
        if g_SelectedBagType == cfg.bag.BagType.TALISMAN then
            UIManager.ShowSystemFlyText(LocalString.Bag_CanNotBatchSell)
        else
            local bagItems = BagManager.GetItems(g_SelectedBagType)
            local filterdItems = { }
            for _, item in ipairs(bagItems) do
                if (item:GetQuality() == cfg.item.EItemColor.GREEN
                    or item:GetQuality() == cfg.item.EItemColor.BLUE
                    or item:GetQuality() == cfg.item.EItemColor.PURPLE)
                    and item:CanSell() == true then
                    table.insert(filterdItems, item)
                end
            end
            if #filterdItems == 0 then
                UIManager.ShowSystemFlyText(LocalString.Bag_NoBatchSellItems)
            else
                UIManager.show("playerrole.bag.dlgbag_batchsell", { bagType = g_SelectedBagType })
            end
        end
    end )

end

return {
    init              = init,
    show              = show,
    hide              = hide,
    update            = update,
    destroy           = destroy,
    refresh           = refresh,
    uishowtype        = uishowtype,
    RefreshBagItemPos = RefreshBagItemPos,
}
