local require             = require
local unpack              = unpack
local print               = print
local math                = math
local utils               = require("common.utils")
local format              = string.format
local UIManager           = require("uimanager")
local network             = require("network")
local PlayerRole          = require("character.playerrole")
local BagManager          = require("character.bagmanager")
local ConfigManager       = require("cfg.configmanager")
local ItemManager         = require("item.itemmanager")
local ItemIntroduct       = require("item.itemintroduction")
local GameEvent           = require("gameevent")
local CheckCmd            = require("common.checkcmd")
local EventHelper         = UIEventListenerHelper
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")


local gameObject
local name
local fields
-- 全局变量
local g_SelectedItem = nil
local g_SelectedIndex
local g_SelectedPage
local g_SelectedEquipPos
local g_SelectedExtraAcc = nil
local g_Accessories
local ShowPage
local ShowAccessoryWashPage
local ShowAccessoryTransferPage
-- list初始位置信息
local g_InitPanelLocalPos
local g_InitPanelOffsetY

local listenerIds

local EQUIP_POS =
{
    EQUIP_ON_PLAYER = 1,
    EQUIP_IN_BAG    = 2
}

local function SetEquipListItem(listItem, equip)
	
	if equip:GetAnnealLevel() ~= 0 then
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
		listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
	else
	    listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
		listItem:SetText("UILabel_AnnealLevel", "")
	end
	colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipName"],equip:GetQuality(),equip:GetName())
	colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipAnnealLevel"],equip:GetQuality(),format(LocalString.EquipEnhance_List_AnnealLevel,equip:GetAnnealLevel()))
	colorutil.SetQualityColorText(listItem.Controls["UILabel_EquipPerfuseLevel"],equip:GetQuality(),format(LocalString.EquipEnhance_List_PerfuseLevel,equip:GetPerfuseLevel()))
	
	listItem:SetIconTexture(equip:GetTextureName())
    -- 设置绑定类型
    listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())
    -- 设置品质
    listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())
end

-- 设置单个属性信息
local function GetSpecifiedAttributeText(accLevel, bMainAttr, attrType, attrValue)
    local colorList = cfg.equip.AccessoryColor.JUDGE_COLOR_LIST
    local coefficientOfMainAttr = cfg.equip.AccessoryColor.JUDGE_COLOR_MAIN
    local accessoryColorData = ConfigManager.getConfigData("accessorycolor", accLevel)
    local denominatorOfAttrColor = nil

    for _, attrData in ipairs(accessoryColorData.standard) do
        if attrType == attrData.propertytype then
            denominatorOfAttrColor = attrData.value
            break
        end
    end
    local coefficientOfAttrColor = 0.0
    if bMainAttr then
        -- 计算主属性颜色系数值
        coefficientOfAttrColor = attrValue / denominatorOfAttrColor / coefficientOfMainAttr
    else
        -- 计算附加属性颜色系数值
        coefficientOfAttrColor = attrValue / denominatorOfAttrColor
    end
    local attrTypeToText = ConfigManager.getConfigData("statustext", attrType)
    local attrText = attrTypeToText.text
    local attributeText = ""
    if attrTypeToText.displaytype == cfg.fight.DisplayType.NORMAL then
        attributeText = format("%s%+.1f", attrText, attrValue)
    elseif attrTypeToText.displaytype == cfg.fight.DisplayType.ROUND then
        attributeText = format("%s%+d", attrText, attrValue)
    elseif attrTypeToText.displaytype == cfg.fight.DisplayType.PERCENT then
        attributeText = format("%s%+.1f%%", attrText, 100 * attrValue)
    else
        logError("attribute display type error!")
    end
    -- 判断属性显示颜色
    if coefficientOfAttrColor < colorList[1] and coefficientOfAttrColor >= 0 then
        -- 白色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.WHITE,attributeText)
    elseif coefficientOfAttrColor < colorList[2] and coefficientOfAttrColor >= colorList[1] then
        -- 绿色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.GREEN,attributeText)
    elseif coefficientOfAttrColor < colorList[3] and coefficientOfAttrColor >= colorList[2] then
        -- 蓝色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.BLUE,attributeText)
    elseif coefficientOfAttrColor < colorList[4] and coefficientOfAttrColor >= colorList[3] then
        -- 紫色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.PURPLE,attributeText)
    elseif coefficientOfAttrColor < colorList[5] and coefficientOfAttrColor >= colorList[4] then
        -- 橙色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.ORANGE,attributeText)
    elseif coefficientOfAttrColor >= colorList[5] then
        -- 红色
        attributeText = colorutil.GetQualityColorText(cfg.item.EItemColor.RED,attributeText)
    else
        logError("Attribute value is wrong!")
    end

    return attributeText
end

-- 初始化主饰品属性列表(界面左边)
local function InitCurAccAttributesList(accessory)
    if not accessory then
        return
    end
    if fields.UIList_CurAcc_ExtraAttributes.Count == 0 then
        local accExtraAtrributes = accessory:GetAccExtraAttributes()
        if #accExtraAtrributes == 0 then
            logError("Can not get Attributes!")
            return
        end

        for _, attribute in ipairs(accExtraAtrributes) do
            local listItem = fields.UIList_CurAcc_ExtraAttributes:AddListItem()
            listItem.Controls["UILabel_CurAcc_AttributeInfo"].text = GetSpecifiedAttributeText(accessory:GetLevel(), false, attribute.AttrType, attribute.AttrValue)
        end
    end
end

local function ClearCurAccAttributesList()
    if fields.UIList_CurAcc_ExtraAttributes.Count ~= 0 then
        fields.UIList_CurAcc_ExtraAttributes:Clear()
    end
end
-- 清除列表内容
local function ResetCurAccAttributesList(curAcc)
    if fields.UIList_CurAcc_ExtraAttributes.Count ~= 0 then
        if not curAcc then
            for i = 1, fields.UIList_CurAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_CurAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UILabel_CurAcc_AttributeInfo"].text = ""
            end
        else
            local accExtraAtrributes = curAcc:GetAccExtraAttributes()
            if #accExtraAtrributes == 0 then
                logError("Can not get Attributes!")
                return
            end
            for i = 1, fields.UIList_CurAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_CurAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UILabel_CurAcc_AttributeInfo"].text = GetSpecifiedAttributeText(curAcc:GetLevel(), false, accExtraAtrributes[i].AttrType, accExtraAtrributes[i].AttrValue)
            end
        end
    end
end

-- 初始化副饰品属性列表(界面右边)
local function InitExtraAccAttributesList(accessory)
    if not accessory then
        return
    end
    if fields.UIList_ExtraAcc_ExtraAttributes.Count == 0 then
        local accExtraAtrributes = accessory:GetAccExtraAttributes()
        if #accExtraAtrributes == 0 then
            logError("Can not get Attributes!")
            return
        end
        for _, attribute in ipairs(accExtraAtrributes) do
            local listItem = fields.UIList_ExtraAcc_ExtraAttributes:AddListItem()
            listItem.Controls["UILabel_ExtraAcc_AttributeInfo"].text = GetSpecifiedAttributeText(accessory:GetLevel(), false, attribute.AttrType, attribute.AttrValue)
        end
    end
end

local function ClearExtraAccAttributesList()
    if fields.UIList_ExtraAcc_ExtraAttributes.Count ~= 0 then
        fields.UIList_ExtraAcc_ExtraAttributes:Clear()
    end
end
-- 清除列表内容
local function ResetExtraAccAttributesList(extraAcc)
    if fields.UIList_ExtraAcc_ExtraAttributes.Count ~= 0 then
        if not extraAcc then
            for i = 1, fields.UIList_ExtraAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_ExtraAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UILabel_ExtraAcc_AttributeInfo"].text = ""
            end
        else
            local accExtraAtrributes = extraAcc:GetAccExtraAttributes()
            if #accExtraAtrributes == 0 then
                logError("Can not get Attributes!")
                return
            end
            for i = 1, fields.UIList_ExtraAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_ExtraAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UILabel_ExtraAcc_AttributeInfo"].text = GetSpecifiedAttributeText(extraAcc:GetLevel(), false, accExtraAtrributes[i].AttrType, accExtraAtrributes[i].AttrValue)
            end
        end
    end
end

-- 由于饰品洗炼和转移中，主饰品的附加属性列表公用一个list
-- 但toggle组件只在洗炼中需要，需要设置toggle显隐
local function ResetToggleStatusInCurAccAttrList(bShowToggle)
    if fields.UIList_CurAcc_ExtraAttributes.Count ~= 0 then
        if bShowToggle then
            -- 显示
            for i = 1, fields.UIList_CurAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_CurAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UISprite_Checkmark"].gameObject:SetActive(true)
                listItem.gameObject:GetComponent("UISprite").enabled = true
            end

        else
            -- 隐藏
            for i = 1, fields.UIList_CurAcc_ExtraAttributes.Count do
                local listItem = fields.UIList_CurAcc_ExtraAttributes:GetItemByIndex(i - 1)
                listItem.Controls["UISprite_Checkmark"].gameObject:SetActive(false)
                listItem.gameObject:GetComponent("UISprite").enabled = false
            end
        end
    end
end

local function SetCurAccessoryBox(curAcc)
    if not curAcc then
        fields.UISprite_CurAcc_Binding.gameObject:SetActive(false)
        fields.UISprite_CurAcc_Quality.spriteName = ""
        fields.UITexture_CurAcc_Icon:SetIconTexture("null")
        fields.UILabel_CurAcc_AnnealLevel.text = ""
        fields.UILabel_CurAcc_AnnealLevel.gameObject:SetActive(false)
        fields.UILabel_CurAcc_Name.text = ""
        -- 设置主属性
        fields.UILabel_CurAcc_MainAttribute1.text = 0
        fields.UILabel_CurAcc_MainAttribute1.gameObject:SetActive(false)
        fields.UILabel_CurAcc_MainAttribute2.text = 0
        fields.UILabel_CurAcc_MainAttribute2.gameObject:SetActive(false)
    else
        -- 绑定类型
        fields.UISprite_CurAcc_Binding.gameObject:SetActive(curAcc:IsBound())
        -- 品质
        fields.UISprite_CurAcc_Quality.spriteName = colorutil.GetQualitySprite(curAcc:GetQuality())

        fields.UITexture_CurAcc_Icon:SetIconTexture(curAcc:GetTextureName())
        if curAcc:GetAnnealLevel() ~= 0 then
			fields.UILabel_CurAcc_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_CurAcc_AnnealLevel.text = "+"..curAcc:GetAnnealLevel()
		else
			fields.UILabel_CurAcc_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_CurAcc_AnnealLevel.text = ""
		end
        -- 设置主属性

        local accMainAttributes = curAcc:GetAccMainAttributes()
        fields.UILabel_CurAcc_Name.text = curAcc:GetName() .. "LV" .. curAcc:GetLevel()
        fields.UILabel_CurAcc_MainAttribute1.gameObject:SetActive(true)
        fields.UILabel_CurAcc_MainAttribute1.text = GetSpecifiedAttributeText(curAcc:GetLevel(), true, accMainAttributes[1].AttrType, accMainAttributes[1].AttrValue)
        fields.UILabel_CurAcc_MainAttribute2.gameObject:SetActive(true)
        fields.UILabel_CurAcc_MainAttribute2.text = GetSpecifiedAttributeText(curAcc:GetLevel(), true, accMainAttributes[2].AttrType, accMainAttributes[2].AttrValue)
    end

end

local function SetExtraAccessoryBox(extraAcc)
    if not extraAcc then
        fields.UISprite_ExtraAcc_Binding.gameObject:SetActive(false)
        fields.UISprite_ExtraAcc_Quality.gameObject:SetActive(false)
        fields.UITexture_ExtraAcc_Icon:SetIconTexture("null")
        fields.UISprite_AddExtraAcc.gameObject:SetActive(true)
        fields.UILabel_ExtraAcc_AnnealLevel.text = "+0"
        fields.UILabel_ExtraAcc_AnnealLevel.gameObject:SetActive(false)
        fields.UILabel_ExtraAcc_Name.text = LocalString.AccEnhance_ChoseExtraAcc

        -- 设置主属性
        fields.UILabel_ExtraAcc_MainAttribute1.text = 0
        fields.UILabel_ExtraAcc_MainAttribute1.gameObject:SetActive(false)
        fields.UILabel_ExtraAcc_MainAttribute2.text = 0
        fields.UILabel_ExtraAcc_MainAttribute2.gameObject:SetActive(false)
    else
        fields.UISprite_AddExtraAcc.gameObject:SetActive(false)
        -- 绑定类型
        fields.UISprite_ExtraAcc_Binding.gameObject:SetActive(extraAcc:IsBound())

        -- 品质
        fields.UISprite_ExtraAcc_Quality.gameObject:SetActive(true)
        fields.UISprite_ExtraAcc_Quality.spriteName = colorutil.GetQualitySprite(extraAcc:GetQuality())


        fields.UITexture_ExtraAcc_Icon:SetIconTexture(extraAcc:GetTextureName())
        if extraAcc:GetAnnealLevel() ~= 0 then
			fields.UILabel_ExtraAcc_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_ExtraAcc_AnnealLevel.text = "+"..extraAcc:GetAnnealLevel()
		else
			fields.UILabel_ExtraAcc_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_ExtraAcc_AnnealLevel.text = ""
		end

        -- 设置主属性
        local accMainAttributes = extraAcc:GetAccMainAttributes()
        fields.UILabel_ExtraAcc_Name.text = extraAcc:GetName() .. "LV" .. extraAcc:GetLevel()
        fields.UILabel_ExtraAcc_MainAttribute1.gameObject:SetActive(true)
        fields.UILabel_ExtraAcc_MainAttribute1.text = GetSpecifiedAttributeText(extraAcc:GetLevel(), true, accMainAttributes[1].AttrType, accMainAttributes[1].AttrValue)
        fields.UILabel_ExtraAcc_MainAttribute2.gameObject:SetActive(true)
        fields.UILabel_ExtraAcc_MainAttribute2.text = GetSpecifiedAttributeText(extraAcc:GetLevel(), true, accMainAttributes[2].AttrType, accMainAttributes[2].AttrValue)

    end

end


---- 初始化包裹和身上的装备列表
--local function InitEquipList(equipPos)
--    if fields.UIList_Equip.Count == 0 then
--        if equipPos == EQUIP_POS.EQUIP_ON_PLAYER then
--            g_Accessories = BagManager.GetAccessoriesOnBody()
--        elseif equipPos == EQUIP_POS.EQUIP_IN_BAG then
--            g_Accessories = BagManager.GetAccessoriesInBag()
--        else
--            logError("type error!")
--        end

--        for _, accessory in ipairs(g_Accessories) do
--            local listItem = fields.UIList_Equip:AddListItem()
--            SetEquipListItem(listItem, accessory)
--        end
--        EventHelper.SetListClick(fields.UIList_Equip, function(listItem)
--            g_SelectedItem = g_Accessories[listItem.Index + 1]
--            SetCurAccessoryBox(g_SelectedItem)
--            ResetCurAccAttributesList(g_SelectedItem)
--            -- 清空副饰品
--            g_SelectedExtraAcc = nil
--            SetExtraAccessoryBox(g_SelectedExtraAcc)
--            -- 清空所选副饰品属性列表
--            ClearExtraAccAttributesList()
--        end )
--    end
--end
---- 炼器后刷新装备列表
--local function RefreshEquipList(equipPos)
--    if fields.UIList_Equip.Count ~= 0 then
--        if equipPos == EQUIP_POS.EQUIP_ON_PLAYER then
--            g_Accessories = BagManager.GetAccessoriesOnBody()
--        elseif equipPos == EQUIP_POS.EQUIP_IN_BAG then
--            g_Accessories = BagManager.GetAccessoriesInBag()
--        else
--            logError("type error!")
--        end
--        -- 删除炼器后的副饰品
--        if fields.UIList_Equip.Count > #g_Accessories then
--            for i =(#g_Accessories + 1), fields.UIList_Equip.Count do
--                fields.UIList_Equip:DelListItem(fields.UIList_Equip:GetItemByIndex(i - 1))
--            end
--        end
--        for i = 1, fields.UIList_Equip.Count do
--            local listItem = fields.UIList_Equip:GetItemByIndex(i - 1)
--            SetEquipListItem(listItem, g_Accessories[i])
--        end
--    end
--end


--local function ClearEquipList()
--    if fields.UIList_Equip.Count ~= 0 then
--        fields.UIList_Equip:Clear()
--    end
--end

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

	if (realIndex + 1) > #g_Accessories then
		go:SetActive(false)
	else
		go:SetActive(true)
		SetEquipListItem(listItem, g_Accessories[realIndex + 1])
	end

end

local function InitEquipList()
	if fields.UIList_Equip.Count == 0 then
		for i = 1, 6 do
			fields.UIList_Equip:AddListItem()
		end
	end
end

local function SetEquipList(equipPos)
	local tempAccessories = nil
	if equipPos == EQUIP_POS.EQUIP_ON_PLAYER then
		tempAccessories = BagManager.GetAccessoriesOnBody()
	elseif equipPos == EQUIP_POS.EQUIP_IN_BAG then
		tempAccessories = BagManager.GetAccessoriesInBag()
	else
		logError("type error!")
	end

	if not tempAccessories then
		print("No accessory in bag or on player")
		return
	end
	g_Accessories = { }
	for _,tempAcc in ipairs(tempAccessories) do
		if tempAcc:GetLevel() <= PlayerRole:Instance():GetLevel() then 
			g_Accessories[#g_Accessories + 1] = tempAcc
		end
	end

	g_SelectedIndex = -1

	-- 停止滑动
	fields.UIScrollView_Equipment.currentMomentum = Vector3(0,0,0)
	-- 重置信息
	local accWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
	accWrapContent:ResetAllChildPositions()
	local panel = fields.UIScrollView_Equipment.gameObject:GetComponent("UIPanel")
	panel.transform.localPosition = g_InitPanelLocalPos
	panel:SetClipOffsetY(g_InitPanelOffsetY)
	-- 重置数量
	accWrapContent.minIndex = -(#g_Accessories)
	accWrapContent.maxIndex = 0
	-- 初始化数据
	EventHelper.SetWrapContentItemInit(accWrapContent, EquipListItemInit)
	accWrapContent.firstTime = true
	accWrapContent:WrapContent()
end

local function RefreshEquipList(equipPos)
	local accWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
	accWrapContent.firstTime = true
	accWrapContent:WrapContent()
end

-- 以下两个界面共享一些资源
-- 显示饰品洗炼界面
ShowAccessoryWashPage = function()
    -- 重新选择副洗炼饰品
    g_SelectedExtraAcc = nil
    -- 清楚属性列表
    -- ClearCurAccAttributesList()
    ClearExtraAccAttributesList()
    -- 初始化主饰品和副饰品
    SetCurAccessoryBox(g_SelectedItem)
    SetExtraAccessoryBox(g_SelectedExtraAcc)
    -- 初始化属性列表
    InitCurAccAttributesList(g_SelectedItem)
    ResetToggleStatusInCurAccAttrList(true)
    InitExtraAccAttributesList(g_SelectedExtraAcc)

    fields.UILabel_WashAndTrans.text = LocalString.AccEnhance_ButtonWash
    fields.UILabel_AccEnhance_Des.text = LocalString.AccEnhance_Wash_Des
    local accWashCost = (ConfigManager.getConfig("accessoryconfig")).washcost
	local currency = ItemManager.GetCurrencyData(accWashCost)
	fields.UISprite_CurrencyIcon.spriteName = currency:GetIconName()
    fields.UILabel_Needed_Currency.text = currency:GetNumber()

	UITools.SetButtonEnabled(fields.UIButton_WashAndTrans ,true)
    EventHelper.SetClick(fields.UIButton_WashAndTrans, function()
        if not g_SelectedExtraAcc then
            UIManager.ShowSystemFlyText(LocalString.AccEnhance_Wash_ChoseExtraAcc)
        else
            -- 校验钱币是否足够
			local validate = CheckCmd.CheckData( { data = accWashCost, num = 1, showsysteminfo = true })
            if not validate then
                UIManager.ShowSystemFlyText(LocalString.Enhance_CurrencyNotEnough)
                return
            end
            if g_SelectedExtraAcc:GetAnnealLevel() ~= 0 or g_SelectedExtraAcc:GetPerfuseLevel() ~= 0 then
                local params = { }
			    params.immediate    = true
			    params.title = LocalString.Bag_Tip
			    params.content = LocalString.AccEnhance_Wash_ForSure
			    params.callBackFunc = function()
                    local attrIdx = fields.UIList_CurAcc_ExtraAttributes:GetSelectedIndex() + 1
                    local accExtraAtrributes = g_SelectedItem:GetAccExtraAttributes()
                    local msg = lx.gs.equip.accessory.CWashAccessory( {
                        bagtype       = g_SelectedItem:GetBagType(),
                        pos           = g_SelectedItem:GetBagPos(),
                        washpropindex = attrIdx,
                        materialpos   = g_SelectedExtraAcc:GetBagPos(),
                    } )
                    network.send(msg)
			    end
			    UIManager.ShowAlertDlg(params)
            else
                local attrIdx = fields.UIList_CurAcc_ExtraAttributes:GetSelectedIndex() + 1
                local accExtraAtrributes = g_SelectedItem:GetAccExtraAttributes()
                local msg = lx.gs.equip.accessory.CWashAccessory( {
                    bagtype       = g_SelectedItem:GetBagType(),
                    pos           = g_SelectedItem:GetBagPos(),
                    washpropindex = attrIdx,
                    materialpos   = g_SelectedExtraAcc:GetBagPos(),
                } )
                network.send(msg)
            end
        end
    end )

end

local function AddExtraAcc(params)
    g_SelectedExtraAcc = params.equip
    InitExtraAccAttributesList(g_SelectedExtraAcc)
    ResetExtraAccAttributesList(g_SelectedExtraAcc)
    SetExtraAccessoryBox(g_SelectedExtraAcc)
end
-- 显示饰品转移界面
ShowAccessoryTransferPage = function()
    -- 重新选择副转移饰品
    g_SelectedExtraAcc = nil
    -- 清楚属性列表
    -- ClearCurAccAttributesList()
    ClearExtraAccAttributesList()
    -- 初始化主饰品和副饰品
    SetCurAccessoryBox(g_SelectedItem)
    SetExtraAccessoryBox(g_SelectedExtraAcc)
    -- 初始化属性列表
    InitCurAccAttributesList(g_SelectedItem)
    ResetToggleStatusInCurAccAttrList(false)
    InitExtraAccAttributesList(g_SelectedExtraAcc)

    fields.UILabel_WashAndTrans.text = LocalString.AccEnhance_ButtonTransfer
    fields.UILabel_AccEnhance_Des.text = LocalString.AccEnhance_Transfer_Des
	-- 转移不消耗虚拟币
	local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
	fields.UISprite_CurrencyIcon.spriteName = currency:GetIconName()
    fields.UILabel_Needed_Currency.text = currency:GetNumber()

	UITools.SetButtonEnabled(fields.UIButton_WashAndTrans ,true)
    EventHelper.SetClick(fields.UIButton_WashAndTrans, function()
        if not g_SelectedExtraAcc then
            UIManager.ShowSystemFlyText(LocalString.AccEnhance_Transfer_ChoseExtraAcc)
        else
            local msg = lx.gs.equip.accessory.CSwapAccessoryProp( {
                bagtype1 = g_SelectedItem:GetBagType(),
                pos1     = g_SelectedItem:GetBagPos(),
                bagtype2 = g_SelectedExtraAcc:GetBagType(),
                pos2     = g_SelectedExtraAcc:GetBagPos(),
            } )
            network.send(msg)
        end
    end )

end

ShowPage =
{
    [4] = ShowAccessoryWashPage,
    [5] = ShowAccessoryTransferPage,
}

-- region msg
local function OnMsg_SWashAccessory(msg)
    -- print("OnMsg_SWashAccessory")
	if g_SelectedItem and msg.bagtype == g_SelectedItem:GetBagType() and msg.pos == g_SelectedItem:GetBagPos() then
		
		local washedCurAccAttrIdx = msg.oldpropindex
		local newExtraAttr =
		{
			AttrType = msg.newprop.key,
			AttrValue = msg.newprop.val,
		}

		fields.UIGroup_WashAcc_AlertDlg.gameObject:SetActive(true)
		local accRevertCost = (ConfigManager.getConfig("accessoryconfig")).abandoncost

		-- 设置交换的原附加属性条目（主饰品）
		local accExtraAtrributes = g_SelectedItem:GetAccExtraAttributes()
		local washedCurAccAttrType = accExtraAtrributes[washedCurAccAttrIdx].AttrType
		local washedCurAccAttrValue = accExtraAtrributes[washedCurAccAttrIdx].AttrValue
		fields.UILabel_AlertDlg_OriginalAttribute.text = GetSpecifiedAttributeText(g_SelectedItem:GetLevel(), false, washedCurAccAttrType, washedCurAccAttrValue)

		-- 设置生成的随机附加属性条目（副属性）
		fields.UILabel_AlertDlg_NewAttribute.text = GetSpecifiedAttributeText(g_SelectedItem:GetLevel(), false, newExtraAttr.AttrType, newExtraAttr.AttrValue)
		-- 设置恢复洗炼所需元宝数量
		local currency = ItemManager.GetCurrencyData(accRevertCost)
		fields.UISprite_Revert_CurrencyIcon.spriteName = currency:GetIconName()
		fields.UILabel_Revert_NeededCurrencyAmount.text = currency:GetNumber()

		EventHelper.SetClick(fields.UIButton_WashAcc_Sure, function()
			local msg = lx.gs.equip.accessory.CApplyAccessoryWashResult({ bagtype = g_SelectedItem:GetBagType(),pos = g_SelectedItem:GetBagPos(), })
			network.send(msg)
		end )

		EventHelper.SetClick(fields.UIButton_WashAcc_Revert, function()
			-- 校验钱币是否足够
			local validate = CheckCmd.CheckData( { data = accRevertCost, num = 1, showsysteminfo = true })
			if not validate then
				UIManager.ShowSystemFlyText(LocalString.Enhance_CurrencyNotEnough)
				return
			end
			local msg = lx.gs.equip.accessory.CRestoreAccessoryWashResult({ bagtype = g_SelectedItem:GetBagType(),pos = g_SelectedItem:GetBagPos(), })
			network.send(msg)
		end )
	end

end

local function OnMsg_SSwapAccessoryProp(msg)
    -- print("OnMsg_SSwapAccessoryProp")
	if g_SelectedItem and g_SelectedExtraAcc 
		and msg.bagtype1 == g_SelectedItem:GetBagType() and msg.pos1 == g_SelectedItem:GetBagPos()  
		and msg.bagtype2 == g_SelectedExtraAcc:GetBagType() and msg.pos2 == g_SelectedExtraAcc:GetBagPos() then

		-- UI特效需要播放时间，等待特效播放完毕再使按钮生效
		UITools.SetButtonEnabled(fields.UIButton_WashAndTrans ,false)
		UIManager.ShowSystemFlyText(LocalString.AccEnhance_Transfer_Success)
		local curOldAccAttrs = g_SelectedItem:GetAccExtraAttributes()
		local extraOldAccAttrs = g_SelectedExtraAcc:GetAccExtraAttributes()
		-- 交换属性信息
		local temp = utils.copy_table(curOldAccAttrs)
		utils.shallow_copy_to(extraOldAccAttrs, curOldAccAttrs)
		utils.shallow_copy_to(temp, extraOldAccAttrs)

		RefreshEquipList(g_SelectedEquipPos)
		ResetCurAccAttributesList(g_SelectedItem)
		-- ShowAccessoryTransferPage()
		-- 播放UI特效
		UIManager.PlayUIParticleSystem(fields.UIGroup_TransferEffect.gameObject)
		-- UI特效播完后更新界面
		local transEffect_EventId = 0
		transEffect_EventId = GameEvent.evt_update:add(function()
			if not UIManager.IsPlaying(fields.UIGroup_TransferEffect.gameObject) then
				GameEvent.evt_update:remove(transEffect_EventId)
				-- 清空副饰品，更新界面UIGroup_WashEffect_AttrFrame
				ShowAccessoryTransferPage()
			end
		end)
	end
end

local function OnMsg_SApplyAccessoryWashResult(msg)
    -- print("OnMsg_SApplyAccessoryWashResult")
	if g_SelectedItem and msg.bagtype == g_SelectedItem:GetBagType() and msg.pos == g_SelectedItem:GetBagPos() then
		
		fields.UIGroup_WashAcc_AlertDlg.gameObject:SetActive(false)
		-- UI特效需要播放时间，等待特效播放完毕再使按钮生效
		UITools.SetButtonEnabled(fields.UIButton_WashAndTrans ,false)
		UIManager.ShowSystemFlyText(LocalString.AccEnhance_Wash_Success)
		-- 更新主饰品所选择的附加属性条目
		local washedCurAccAttrIdx = msg.oldpropindex

		local newAttr =
		{
			AttrType  = msg.newprop.key,
			AttrValue = msg.newprop.val,
		}
		-- 更新界面
		local curAccListItem = fields.UIList_CurAcc_ExtraAttributes:GetItemByIndex(washedCurAccAttrIdx - 1)
		curAccListItem.Controls["UILabel_CurAcc_AttributeInfo"].text = GetSpecifiedAttributeText(g_SelectedItem:GetLevel(), false, newAttr.AttrType, newAttr.AttrValue)

		local exAccListItem = fields.UIList_ExtraAcc_ExtraAttributes:GetItemByIndex(washedCurAccAttrIdx - 1)
		-- 更新所选的主饰品的附加属性
		local accExtraAtrributes = g_SelectedItem:GetAccExtraAttributes()
		accExtraAtrributes[washedCurAccAttrIdx] = newAttr
		-- 重新设置列表，因为要消耗选择的饰品
		SetEquipList(g_SelectedEquipPos)
		-- ShowAccessoryWashPage()
		-- 播放UI特效
		-- CurAcc
		local curAccAttrEffectObj = GameObject.Instantiate(fields.UIGroup_WashEffect_AttrFrame.gameObject)
		curAccAttrEffectObj.transform.parent = curAccListItem.Controls["UILabel_CurAcc_AttributeInfo"].transform
		curAccAttrEffectObj.transform.localScale = Vector3.one
		curAccAttrEffectObj.transform.localPosition = Vector3(0.6*SCALE_XY,0,0)
		-- ExtraAcc
		local exAccAttrEffectObj = GameObject.Instantiate(fields.UIGroup_WashEffect_AttrFrame.gameObject)
		exAccAttrEffectObj.transform.parent = exAccListItem.Controls["UILabel_ExtraAcc_AttributeInfo"].transform
		exAccAttrEffectObj.transform.localScale = Vector3.one
		exAccAttrEffectObj.transform.localPosition = Vector3.zero

		UIManager.PlayUIParticleSystem(curAccAttrEffectObj)
		UIManager.PlayUIParticleSystem(exAccAttrEffectObj)
		-- UI特效播完后释放资源
		local attrEffect_EventId = 0
		attrEffect_EventId = GameEvent.evt_update:add(function()
			if not UIManager.IsPlaying(curAccAttrEffectObj) then
				GameEvent.evt_update:remove(attrEffect_EventId)
				GameObject.Destroy(curAccAttrEffectObj)
				GameObject.Destroy(exAccAttrEffectObj)
				-- 清空副饰品，更新界面
				ShowAccessoryWashPage()
			end
		end)
		-- 播放箭头特效
		UIManager.PlayUIParticleSystem(fields.UIGroup_WashEffect_Arrow.gameObject)
	end
end

local function OnMsg_SRestoreAccessoryWashResult(msg)
    -- print("OnMsg_SRestoreAccessoryWashResult")
	if g_SelectedItem and msg.bagtype == g_SelectedItem:GetBagType() and msg.pos == g_SelectedItem:GetBagPos() then
		
		fields.UIGroup_WashAcc_AlertDlg.gameObject:SetActive(false)
		local accRevertCost = (ConfigManager.getConfig("accessoryconfig")).abandoncost
		local currency = ItemManager.GetCurrencyData(accRevertCost)
		UIManager.ShowSystemFlyText(format(LocalString.AccEnhance_Wash_Revert, currency:GetNumber()))
		-- 重新设置列表，因为要消耗选择的饰品
		SetEquipList(g_SelectedEquipPos)
		-- 刷新当前持有钱币和清空副饰品
		ShowAccessoryWashPage()
	end
end

-- endregion msg

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_WashEffect_Arrow.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_TransferEffect.gameObject)
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    g_SelectedItem = EquipEnhanceManager.GetEquip()
    -- 重置所选界面
	local curTabIndex = UIManager.gettabindex("playerrole.equip.dlgaccessoryenhance")
    g_SelectedPage = curTabIndex
    fields.UILabel_Title.text = LocalString.Enhance_AccWashAndTrans[g_SelectedPage]
    -- 重置界面左边的饰品list
    local btnToggle = fields.UIButton_Body.gameObject:GetComponent(UIToggle)
	btnToggle.value = true
    g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
    SetEquipList(g_SelectedEquipPos)

    listenerIds = network.add_listeners( {
        { "lx.gs.equip.accessory.SWashAccessory", OnMsg_SWashAccessory },
        { "lx.gs.equip.accessory.SSwapAccessoryProp", OnMsg_SSwapAccessoryProp },
        { "lx.gs.equip.accessory.SApplyAccessoryWashResult", OnMsg_SApplyAccessoryWashResult },
        { "lx.gs.equip.accessory.SRestoreAccessoryWashResult", OnMsg_SRestoreAccessoryWashResult },
    } )
end

local function hide()
    -- print(name, "hide")
    network.remove_listeners(listenerIds)
    g_SelectedItem = nil
    g_SelectedExtraAcc = nil 
    --ClearEquipList()
    ClearCurAccAttributesList()
    ClearExtraAccAttributesList()
	StopUIParticleSystem()
end

local function refresh(params)
    -- print(name, "refresh")
	RefreshEquipList(g_SelectedEquipPos)
	if ShowPage[g_SelectedPage] then 
		ShowPage[g_SelectedPage]()
	end
end

local function update()
    -- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)

	InitEquipList()
	local panel         = fields.UIScrollView_Equipment.gameObject:GetComponent("UIPanel")
	g_InitPanelLocalPos = panel.transform.localPosition
	g_InitPanelOffsetY  = panel:GetClipOffsetY()

	EventHelper.SetListClick(fields.UIList_Equip, function(listItem)
		local accWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
		local realIndex = accWrapContent:Index2RealIndex(listItem.Index)
		g_SelectedIndex = realIndex
		g_SelectedItem  = g_Accessories[realIndex + 1]
		EquipEnhanceManager.SetEquip(g_SelectedItem)
        SetCurAccessoryBox(g_SelectedItem)
        ResetCurAccAttributesList(g_SelectedItem)
        -- 清空副饰品
        g_SelectedExtraAcc = nil
        SetExtraAccessoryBox(g_SelectedExtraAcc)
        -- 清空所选副饰品属性列表
        ClearExtraAccAttributesList()
	end )

	EventHelper.SetClick(fields.UIButton_Body, function()
		if g_SelectedEquipPos == EQUIP_POS.EQUIP_ON_PLAYER then
			return
		end
		g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
		SetEquipList(g_SelectedEquipPos)
	end )

	EventHelper.SetClick(fields.UIButton_Bag, function()
		if g_SelectedEquipPos == EQUIP_POS.EQUIP_IN_BAG then
			return
		end
		g_SelectedEquipPos = EQUIP_POS.EQUIP_IN_BAG
		SetEquipList(g_SelectedEquipPos)
	end )

    -- 添加洗炼或者转移的饰品
    EventHelper.SetClick(fields.UIButton_AddExtraAcc, function()
        local allAccessoriesInBag = BagManager.GetItemByType(cfg.bag.BagType.EQUIP, g_SelectedItem:GetDetailType())
        -- 除去本身
        local accs = { }
        for _, accInBag in ipairs(allAccessoriesInBag) do
            -- 类型一致，等级大于等于所选饰品,等级小于等于玩家等级，除去本身
            if g_SelectedItem:GetId() ~= accInBag:GetId() and g_SelectedItem:GetLevel() >= accInBag:GetLevel() 
				and accInBag:GetLevel() <= PlayerRole:Instance():GetLevel() then
                accs[#accs + 1] = accInBag
            end
        end

        if #accs == 0 then
            UIManager.ShowSystemFlyText(LocalString.AccEnhance_NoExtraAccessory)
        else
            local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
            UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.AccEnhance, equips = accs })
        end

    end )

end

return {
    init        = init,
    show        = show,
    hide        = hide,
    update      = update,
    destroy     = destroy,
    refresh     = refresh,
	uishowtype	= uishowtype,
	AddExtraAcc = AddExtraAcc,
}
