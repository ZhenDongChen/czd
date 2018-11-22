local unpack           = unpack
local print            = print
local require          = require
local format           = string.format
local UIManager        = require("uimanager")
local ConfigManager    = require("cfg.configmanager")
local BagManager       = require("character.bagmanager")
local DepotManager     = require("character.depotmanager")
local PlayerRole       = require("character.playerrole")
local ItemIntroduct    = require("item.itemintroduction")
local ItemManager      = require("item.itemmanager")
local CheckCmd         = require("common.checkcmd")
local FamilyMgr        = require("family.familymanager")
local EventHelper      = UIEventListenerHelper

local name
local gameObject
local fields

local playerRoleInfo

-- 背包信息
local selectedBagType
local selectedDepotType
local isInBatch = true

local initBagPosition = 0
local initBagOffsetY = 0

local initWarehousePosition = 0
local initWarehouseOffsetY = 0
local lastClearUpTime =0
local UTime = UnityEngine.Time

local WAREHOUSE_ACTION =
{
    ACTION_SAVE = 1,
    ACTION_TAKE = 2,
}
local action

local Validation = enum 
	{
		"None",
		"Integer",
		"Float",
		"Alphanumeric",
		"Username",
		"Name",
		"Filename",
	}

--设置仓库网格的显示
local function SetBagSlot(listItem, item, bagType)
    BagManager.SetBagSlotBasicInfo(listItem, item, bagType, true, true)
end

local function BagItemInit(go, index, realIndex)
    BagManager.WrapContentItemInit(go, index, realIndex,selectedBagType,SetBagSlot)
end

local function WarehouseItemInit(go, index, realIndex)
    BagManager.WrapContentItemInit(go, index, realIndex,selectedDepotType,SetBagSlot)
end

local function InitSlotLists()
    -- init bag list
    BagManager.InitBagSlotList(selectedBagType,fields.UIList_Bag,BagItemInit)
    -- init warehouse list
    BagManager.InitBagSlotList(selectedDepotType,fields.UIList_Warehouse,WarehouseItemInit)
end

local function RefreshMoneyText()
    fields.UILabel_WarehouseGold.text = DepotManager.GetDepotSavedCurrency()
end

--刷新背包和仓库的列表
local function RefreshWarehouceAndBagInfo()
    BagManager.RefreshBagList(fields.UIList_Bag)
    BagManager.RefreshBagList(fields.UIList_Warehouse)
end

local function ResetListsToTop()
    -- bag
    BagManager.ResetBagListToTop(fields.UIScrollView_Bag,fields.UIList_Bag,initBagPosition,initBagOffsetY)
    -- warehouse
    BagManager.ResetBagListToTop(fields.UIScrollView_Warehouse,fields.UIList_Warehouse,initWarehousePosition,initWarehouseOffsetY)
end

local function refresh(params)
    -- print(name, "refresh")
    RefreshWarehouceAndBagInfo()
end

local function destroy()
    -- print(name, "destroy")
end

local function showtab(params)
    BagManager.ResetBag(cfg.bag.BagType.FAMILY_EQUIP)
    DepotManager.SendCSyncFamilyDepot()
end

local function show(params)
    InitSlotLists()
    RefreshMoneyText()
end

local function hide()
    -- print(name, "hide")
end

local function update()
    -- print(name, "update")
    if (lastClearUpTime == 0 or UTime.time - lastClearUpTime >= 3.5)  and  fields.UIButton_Depot_ClearUp.isEnabled == false then
        fields.UIButton_Depot_ClearUp.isEnabled = true
    end
end

local function DrawSaveCurrency(amount)
    if action == WAREHOUSE_ACTION.ACTION_SAVE then
        DepotManager.SendCSaveGoldCoin(tonumber(amount))
    elseif action == WAREHOUSE_ACTION.ACTION_TAKE then
        DepotManager.SendCTakeGoldCoin(tonumber(amount))
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)
    local bagPanel = fields.UIScrollView_Bag.gameObject:GetComponent("UIPanel")
    initBagPosition = bagPanel.transform.localPosition
    initBagOffsetY = bagPanel:GetClipOffsetY()

    local warehousePanel = fields.UIScrollView_Warehouse.gameObject:GetComponent("UIPanel")
    initWarehousePosition = warehousePanel.transform.localPosition
    initWarehouseOffsetY = warehousePanel:GetClipOffsetY()

    playerRoleInfo = PlayerRole:Instance()
    -- 仓库代码由普通仓库和家族仓库共用
    if UIManager.currentdialogname() == "family.dlgfamily" then

        fields.UISprite_WarehouseGold.gameObject:SetActive(false)
        fields.UIGroup_Button.gameObject:SetActive(false)
        fields.UILabel_Log.text = LocalString.DlgWarehouse_LOG

        -- 目前需求只给红色且非绑定的饰品，因此只展示装备包裹
        selectedBagType = cfg.bag.BagType.EQUIP
        selectedDepotType = cfg.bag.BagType.FAMILY_EQUIP

        EventHelper.SetListClick(fields.UIList_Bag, function(listItem)
            local bagWrapContent = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
            local realIndex = bagWrapContent:Index2RealIndex(listItem.Index)

            local selectedItem = BagManager.GetItemBySlot(selectedBagType, realIndex + 1)
            if not selectedItem then
                return
            end

            if not (selectedItem:IsAccessory() and selectedItem:GetQuality() == cfg.item.EItemColor.RED and (not selectedItem:IsBound())) then
                UIManager.ShowSystemFlyText(LocalString.DlgWarehouse_OnlyRedAcc)
                return 
            end 

            local moveItemFunc = function(params)
                DepotManager.SendCPutEquipToFamilyDepot(realIndex + 1)
            end
            ItemIntroduct.DisplayItem( {
                item        = selectedItem,
                variableNum = false,
                buttons =
                {
                    { display = true, text = LocalString.DlgWarehouse_SAVE, callFunc = moveItemFunc }
                }
            } )
        end )

        EventHelper.SetListClick(fields.UIList_Warehouse, function(listItem)
            local warehouseWrapContent = fields.UIList_Warehouse.gameObject:GetComponent("UIGridWrapContent")
            local realIndex = warehouseWrapContent:Index2RealIndex(listItem.Index)
            local depotInfo = BagManager.GetBag(selectedDepotType)

            local selectedItem = depotInfo:GetItemBySlot(realIndex + 1)
            if not selectedItem then
                return
            end
            local buttonTxt = ""
            local bShowBtn = false
            local giveItemFunc = nil
            -- 只有家族族长和副组长可以给予其他同族里的人红色饰品
            if FamilyMgr.InFamily() and (FamilyMgr.IsChief() or FamilyMgr.IsViceChief()) then
                bShowBtn = true
                buttonTxt = LocalString.DlgWarehouse_GIVE
                local giveBtn_CB = function(roleId) 
                                        DepotManager.SendCFamilyDepotEquipGive(realIndex+1,roleId)
                                        UIManager.hide("citywar.tabrewarddistribution") 
                end
                local logBtn_CB = function() FamilyMgr.CGetFamilyDepotLog() end
                giveItemFunc = function(params)
                    UIManager.show("citywar.tabrewarddistribution",{ giveBtn_callback = giveBtn_CB,logBtn_callback = logBtn_CB, })
                end
            end


            ItemIntroduct.DisplayItem( {
                item        = selectedItem,
                variableNum = false,
                buttons =
                {
                    { display = bShowBtn, text = buttonTxt, callFunc = giveItemFunc }
                }
            } )

        end )
        EventHelper.SetClick(fields.UIButton_Log,function()
            FamilyMgr.CGetFamilyDepotLog()
        end )


        EventHelper.SetClick(fields.UIButton_Bag_ClearUp, function()
            BagManager.SendCSortBag(selectedBagType)
        end )

        -- 忽略下面设置
        return
    else

        fields.UISprite_WarehouseGold.gameObject:SetActive(true)
        fields.UIGroup_Button.gameObject:SetActive(true)
        fields.UILabel_Log.text = LocalString.DlgWarehouse_GET
    end

	

    EventHelper.SetListClick(fields.UIList_RadioButton, function(listItem)
        local index = fields.UIList_RadioButton:GetSelectedIndex()
        if listItem.Index == 0 then
            selectedBagType = cfg.bag.BagType.EQUIP
            selectedDepotType = cfg.bag.BagType.DEPOT_EQUIP
        elseif listItem.Index == 3 then
            selectedBagType = cfg.bag.BagType.FRAGMENT
            selectedDepotType = cfg.bag.BagType.DEPOT_FRAGMENT
        elseif listItem.Index == 2 then
            selectedBagType = cfg.bag.BagType.ITEM
            selectedDepotType = cfg.bag.BagType.DEPOT_ITEM
        elseif listItem.Index == 1 then
            selectedBagType = cfg.bag.BagType.TALISMAN
            selectedDepotType = cfg.bag.BagType.DEPOT_TALISMAN
        end
        ResetListsToTop()
    end )

    EventHelper.SetClick(fields.UIButton_Bag_ClearUp, function()
        BagManager.SendCSortBag(selectedBagType)
    end )

    EventHelper.SetClick(fields.UIButton_Depot_ClearUp, function()
        if lastClearUpTime == 0 or UTime.time - lastClearUpTime >= 3.5 then
            BagManager.SendCSortBag(selectedDepotType)
            fields.UIButton_Depot_ClearUp.isEnabled = false
            lastClearUpTime = UTime.time
        end
    end )

    EventHelper.SetClick(fields.UIButton_Log, function()
        action = WAREHOUSE_ACTION.ACTION_TAKE
        UIManager.show("common.dlgdialogbox_input", {
            callBackFunc = function(fields)
				--设置只能输入数字
				local UIInput_InputTransform =  fields.UIInput_Input.gameObject:GetComponent(UIInput)
				UIInput_InputTransform.validation = Validation.Integer

                --修改提示
				fields.UILabel_Input.text = LocalString.DlgWarehouse_InputTip				
				
                fields.UIGroup_Button_Mid.gameObject:SetActive(false)
                fields.UIGroup_Button_Norm.gameObject:SetActive(true)
                fields.UIGroup_Resource.gameObject:SetActive(false)
                fields.UIGroup_Select.gameObject:SetActive(false)
                fields.UIGroup_Clan.gameObject:SetActive(false)
                fields.UIGroup_Rename.gameObject:SetActive(false)
                fields.UIGroup_Slider.gameObject:SetActive(true)
                fields.UIGroup_Delete.gameObject:SetActive(false)
                fields.UIInput_Input.gameObject:SetActive(true)
                fields.UIInput_Input_Large.gameObject:SetActive(false)
                fields.UISprite_Currency_Icon.gameObject:SetActive(true)
                fields.UISprite_Currency_01.gameObject:SetActive(false)
				
				
				
                EventHelper.SetClick(fields.UIButton_Left, function()
                    if fields.UIInput_Input.value then
                        DrawSaveCurrency(fields.UIInput_Input.value)
                    end
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                EventHelper.SetClick(fields.UIButton_Right, function()
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                EventHelper.SetClick(fields.UIButton_Close, function()
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                fields.UISlider_Slider.value = 1
				
				
                EventHelper.AddSliderValueChange(fields.UISlider_Slider, function()
                    fields.UILabel_Count.text = math.floor(fields.UISlider_Slider.value * DepotManager.GetDepotSavedCurrency())
                    fields.UIInput_Input.value = math.floor(fields.UISlider_Slider.value * DepotManager.GetDepotSavedCurrency())
                end )
                
                fields.UIInput_Input.value = DepotManager.GetDepotSavedCurrency()

                local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
                fields.UISprite_Currency_Icon.spriteName = currency:GetIconName()
                fields.UILabel_Title.text = LocalString.DlgWarehouse_TAKE
                fields.UIInput_Input.selectAllTextOnFocus = true
                fields.UIInput_Input.characterLimit = 20
                fields.UIInput_Input.isSelected = true
                fields.UILabel_Button_Left.text = LocalString.Family.TagConfirm
                fields.UILabel_Button_Right.text = LocalString.Family.TagCancel
                fields.UILabel_Descrip.text = ""
				
				--修复输入金币变化跟金币滑动条的变化
				EventHelper.AddInputValueChange(fields.UIInput_Input,function(input)


					local currentstring = tonumber(input.value)
					local currenctCurrencytemp =  input.value

					if not currentstring then
                        --input.value = 0
                        fields.UILabel_Count.text = 0
						return
					end
					if currentstring < 0 then
						input.value = 0
						currenctCurrencytemp = 0
					elseif currentstring > DepotManager.GetDepotSavedCurrency() then
						input.value = DepotManager.GetDepotSavedCurrency()
						currenctCurrencytemp = DepotManager.GetDepotSavedCurrency()
					end

                    fields.UILabel_Count.text = currenctCurrencytemp

					--local percent =  (currenctCurrencytemp+1)/DepotManager.GetDepotSavedCurrency()
                    --
					--fields.UISlider_Slider.value = percent

				end)
            end
        } )
    end )

    EventHelper.SetClick(fields.UIButton_Med_Save, function()
        action = WAREHOUSE_ACTION.ACTION_SAVE
        UIManager.show("common.dlgdialogbox_input", {
		
            callBackFunc = function(fields)
                fields.UIGroup_Button_Mid.gameObject:SetActive(false)
                fields.UIGroup_Button_Norm.gameObject:SetActive(true)
                fields.UIGroup_Resource.gameObject:SetActive(false)
                fields.UIGroup_Select.gameObject:SetActive(false)
                fields.UIGroup_Clan.gameObject:SetActive(false)
                fields.UIGroup_Rename.gameObject:SetActive(false)
                fields.UIGroup_Slider.gameObject:SetActive(true)
                fields.UIGroup_Delete.gameObject:SetActive(false)
                fields.UIInput_Input.gameObject:SetActive(true)
                fields.UIInput_Input_Large.gameObject:SetActive(false)
                fields.UISprite_Currency_Icon.gameObject:SetActive(true)
                fields.UISprite_Currency_01.gameObject:SetActive(false)

                --修改提示
				fields.UILabel_Input.text = LocalString.DlgWarehouse_InputTip
				
				--设置只能输入数字
				local UIInput_InputTransform =  fields.UIInput_Input.gameObject:GetComponent(UIInput)
				UIInput_InputTransform.validation = Validation.Integer
				
                EventHelper.SetClick(fields.UIButton_Left, function()
                    DrawSaveCurrency(fields.UIInput_Input.value)
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                EventHelper.SetClick(fields.UIButton_Right, function()
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                EventHelper.SetClick(fields.UIButton_Close, function()
                    UIManager.hide("common.dlgdialogbox_input")
                end )
                fields.UISlider_Slider.value = 1
                EventHelper.AddSliderValueChange(fields.UISlider_Slider, function()
                    fields.UILabel_Count.text = math.floor(fields.UISlider_Slider.value * playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi])
                    fields.UIInput_Input.value = math.floor(fields.UISlider_Slider.value * playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi])
                end )
                fields.UIInput_Input.value = playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi]

                local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
                fields.UISprite_Currency_Icon.spriteName = currency:GetIconName()
                fields.UILabel_Title.text = LocalString.DlgWarehouse_SAVE
                fields.UIInput_Input.selectAllTextOnFocus = true
                fields.UIInput_Input.characterLimit = 20
                fields.UIInput_Input.isSelected = true
                fields.UILabel_Button_Left.text = LocalString.Family.TagConfirm
                fields.UILabel_Button_Right.text = LocalString.Family.TagCancel
                fields.UILabel_Descrip.text = ""
				
				--修复输入金币变化跟金币滑动条的变化
				EventHelper.AddInputValueChange(fields.UIInput_Input,function(input)


					local currentstring = tonumber(input.value)
					local currenctCurrencytemp =  input.value

					if not currentstring then
                        --input.value = 0
                        fields.UILabel_Count.text = 0
						return
					end
					if currentstring < 0 then
						input.value = 0
						currenctCurrencytemp = 0
					elseif currentstring > playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi] then
						input.value = playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi]
						currenctCurrencytemp = playerRoleInfo.m_Currencys[cfg.currency.CurrencyType.XuNiBi]
					end

                    fields.UILabel_Count.text = currenctCurrencytemp
				end)
            end
        } )
    end )

    EventHelper.SetClick(fields.UIButton_Med_Batch, function()
        if isInBatch then
            fields.UILabel_Batch.text = LocalString.DlgWarehouse_Batch
            -- fields.UISprite_Border.gameObject:SetActive(false)
            isInBatch = false
        else
            fields.UILabel_Batch.text = LocalString.DlgWarehouse_CancelBatch
            -- fields.UISprite_Border.gameObject:SetActive(true)
            isInBatch = true
        end
    end )

    EventHelper.SetListClick(fields.UIList_Bag, function(listItem)
        local bagWrapContent = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
        local realIndex = bagWrapContent:Index2RealIndex(listItem.Index)

        local selectedItem = BagManager.GetItemBySlot(selectedBagType, realIndex + 1)
        if not selectedItem then
            return
        end

        if isInBatch then
            DepotManager.SendCTransferItem(selectedBagType, realIndex + 1)
            return
        end

        local moveItemFunc = function(params)
            DepotManager.SendCTransferItem(selectedBagType, realIndex + 1)
        end

        ItemIntroduct.DisplayItem( {
            item        = selectedItem,
            variableNum = false,
            buttons =
            {
                { display = true, text = LocalString.DlgWarehouse_SAVE, callFunc = moveItemFunc }
            }
        } )
    end )

    EventHelper.SetListClick(fields.UIList_Warehouse, function(listItem)
        local warehouseWrapContent = fields.UIList_Warehouse.gameObject:GetComponent("UIGridWrapContent")
        local realIndex = warehouseWrapContent:Index2RealIndex(listItem.Index)
        local depotInfo = BagManager.GetBag(selectedDepotType)

        local curUnlockedSize = depotInfo:GetUnLockedSize()
        if (realIndex + 1) > curUnlockedSize then
            local unlockSlotCost = ConfigManager.getConfigData("bagconfig", selectedDepotType)
            local currency_cost = ItemManager.GetCurrencyData(unlockSlotCost.unlockgridcost)
            local unlockSlotNum =(realIndex + 1) - curUnlockedSize
            local params = { }
            params.immediate = true
            params.title = format(LocalString.Bag_UnlockSlot_Tip, unlockSlotCost.unlockgridcost.amount, currency_cost:GetName())
            params.content = format(LocalString.Bag_UnlockSlots_TotalCost, unlockSlotNum,(unlockSlotCost.unlockgridcost.amount * unlockSlotNum), currency_cost:GetName())
            params.callBackFunc = function()
                local validate, info = CheckCmd.CheckData( { data = unlockSlotCost.unlockgridcost, num = unlockSlotNum, showsysteminfo = true })
                if validate then
                    BagManager.SendCUnlockGrid(selectedDepotType, unlockSlotNum)
                end
            end
            UIManager.ShowAlertDlg(params)
            return
        end

        local selectedItem = depotInfo:GetItemBySlot(realIndex + 1)
        if not selectedItem then
            return
        end
		

        if isInBatch then
            DepotManager.SendCTransferItem(selectedDepotType, realIndex + 1)
            return
        end

        local moveItemFunc = function(params)
            DepotManager.SendCTransferItem(selectedDepotType, realIndex + 1)
        end

        ItemIntroduct.DisplayItem( {
            item        = selectedItem,
            variableNum = false,
            buttons =
            {
                { display = true, text = LocalString.DlgWarehouse_TAKE, callFunc = moveItemFunc }
            }
        } )
		

    end )

    selectedBagType   = cfg.bag.BagType.EQUIP
    selectedDepotType = cfg.bag.BagType.DEPOT_EQUIP
    fields.UIList_RadioButton:SetSelectedIndex(0)
    isInBatch = true
    fields.UILabel_Batch.text = LocalString.DlgWarehouse_CancelBatch

end
						
return {
    init             = init,
    show             = show,
    showtab          = showtab,
    hide             = hide,
    update           = update,
    destroy          = destroy,
    refresh          = refresh,
    RefreshMoneyText = RefreshMoneyText,
    uishowtype       = uishowtype,
}
						