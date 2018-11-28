local require           = require
local unpack            = unpack
local print             = print
local UIManager         = require("uimanager")
local network           = require("network")
local PlayerRole        = require("character.playerrole")
local JewelryBagManager = require("ui.jade.jewelrybagmanager")
local Jewelry           = require("item.jewelry")
local ItemManager       = require("item.itemmanager")

local EventHelper       = UIEventListenerHelper


local gameObject
local name
local fields

-- 全局变量
local g_SelectedJewelry
local g_SelectedJadeSlotPos
local g_PreButtonStatus
local g_CurButtonStatus
local g_Jewelries

local BUTTON_STATUS =
{
    -- 装载宝珠
    EQUIP_JEWELRY = 1,
    -- 最终升级宝珠界面(可以多选)
    UPDATE_JEWELRY = 2,
    -- 宝珠选择界面(只能单选)
    UPDATE_JEWELRY_INBAG = 3,
    -- 升级jade中的宝珠
    UPDATE_JEWELRY_INJADE = 4,

}

local function InitBagSlotList()
    if fields.UIList_JewelryBag.Count == 0 then
        -- 根据背包里宝珠具体数量生成格子
        for i = 1, JewelryBagManager.GetBagJewelrySize() do
            local listItem = fields.UIList_JewelryBag:AddListItem()
            listItem:SetIconTexture("null")
            listItem.Controls["UILabel_JewelryLevel"].text = ""
        end
    end
end

local function SetSelectedJewelryInfo(jewelry)
    if not jewelry then
        -- 无选择则清空信息
        fields.UILabel_Bag_SelectedJewelry_Name.text = ""
        fields.UITexture_Bag_SelectedJewelry_Icon:SetIconTexture("")
		fields.UISprite_Bag_SelectedJewelry_Quality.spriteName = colorutil.GetQualitySpriteYuan()
        fields.UILabel_Bag_SelectedJewelry_Level.text = ""
        fields.UILabel_Bag_SelectedJewelry_Attribute.text = ""
        fields.UILabel_Bag_SelectedJewelry_Discription.text = ""
        fields.UISlider_JewelryExpValue.value = 0
        fields.UILabel_JewelryExpValue_Progress.text = "0/0"
    else
        fields.UILabel_Bag_SelectedJewelry_Name.text = jewelry:GetName()
        fields.UITexture_Bag_SelectedJewelry_Icon:SetIconTexture(jewelry:GetTextureName())
		fields.UISprite_Bag_SelectedJewelry_Quality.spriteName = colorutil.GetQualitySpriteYuan(jewelry:GetQuality())
        fields.UILabel_Bag_SelectedJewelry_Level.text = "LV."..jewelry:GetLevel()
        fields.UILabel_Bag_SelectedJewelry_Attribute.text = jewelry:GetAttrText()
        fields.UILabel_Bag_SelectedJewelry_Discription.text = jewelry:GetIntroduce()
        --
        fields.UISlider_JewelryExpValue.value = jewelry:GetRemainingExpAfterAdvanced() / jewelry:GetRequiredExpIfAdvanced()
        fields.UILabel_JewelryExpValue_Progress.text = jewelry:GetRemainingExpAfterAdvanced() .. "/" .. jewelry:GetRequiredExpIfAdvanced()
    end
end

-- 此函数返回值 exp = 升级后剩余exp + 所有选择的宝珠经验总值
local function GetSelectedJewelryAddedExp(jewelry)
    -- 进度条不包括天生携带的经验值
    local remainingExp = jewelry:GetRemainingExpAfterAdvanced()
    local totalExp = remainingExp
    if fields.UIList_JewelryBag.IsMultiCheckBox then
        local selectedListItems = fields.UIList_JewelryBag:GetSelectedItems()
        if selectedListItems.Length == 0 then
            return totalExp
        end

        for i = 1,selectedListItems.Length do
            totalExp = totalExp + g_Jewelries[selectedListItems[i].Index + 1]:GetTotalExp()
        end
        return totalExp
    else
        return totalExp
    end

end

-- 返回两个值: 1.是否可以升级，2.原宝珠信息或者新宝珠
-- 参数1：curJewelry：当前需要升级的宝珠
-- 参数2：curSelectedJewelry：被选择用来升级的宝珠(可以设置为nil),在检测当前选择的宝珠是否可以用来升级时使用
local function CanUpdateAfterUsedSelectedJewelriesInBag(curJewelry,curSelectedJewelryIndex)
    -- 不包括本身天生携带的经验值
    local tempTotalAddedExp = curJewelry:GetTotalAddedExp()
    local totalRequiredExp = 0
    local newJewelry = nil
    local bCanUpdate = false

    if fields.UIList_JewelryBag.IsMultiCheckBox then
        -- 检查升级的宝珠等级限制
        -- 按照索引排列(白，绿，蓝，紫，橙),品质枚举从0开始
        local limitLevel =(ConfigManager.getConfigData("jewelrylvllimit", PlayerRole:Instance():GetLevel())).jewelrylvl[curJewelry:GetQuality() + 1]

        if curJewelry:GetLevel() > limitLevel then
            -- 宝珠数据错误
            logError(name, "jewelry data error")
            return bCanUpdate, newJewelry
        end
        local selectedListItems = fields.UIList_JewelryBag:GetSelectedItems()
        if selectedListItems.Length == 0 and not curSelectedJewelryIndex then
            -- 没有选择任何宝珠
            return bCanUpdate, curJewelry
        end
		-- 将已选择的宝珠经验求和
        for i = 1,selectedListItems.Length do
            tempTotalAddedExp = tempTotalAddedExp + g_Jewelries[selectedListItems[i].Index + 1]:GetTotalExp()
        end
		-- 把将要选择的宝珠经验加上，并判断是否可以用来升级当前宝珠
		if curSelectedJewelryIndex then
			tempTotalAddedExp = tempTotalAddedExp + g_Jewelries[curSelectedJewelryIndex + 1]:GetTotalExp()
		end

        local levelUpdDataList = ConfigManager.getConfig("jewelrylvlup")
        for level = 1, #levelUpdDataList do
            local preTotalRequiredExp = totalRequiredExp
            totalRequiredExp = totalRequiredExp + levelUpdDataList[level].requireexp
            -- 找到增加经验值后所能升级到的等级，并且等级不超过宝珠品质限制的最高等级
            if tempTotalAddedExp >= preTotalRequiredExp and tempTotalAddedExp < totalRequiredExp
                and level <= limitLevel then
                newJewelry = Jewelry:new(curJewelry:GetId(), level, 0, tempTotalAddedExp, curJewelry:GetType())
                bCanUpdate = true
                return bCanUpdate, newJewelry
            end
        end
		local errorCode = LocalString.Jewelry_Error_LevelLimit
        return bCanUpdate, newJewelry, errorCode
    end
    -- 非多选情况(选择要升级的宝珠界面)
    return bCanUpdate, curJewelry


end
-- 在最终宝珠升级界面中刷新增加的经验值,返回true或者false(是否刷新成功)
local function RefreshSelectedJewelryInfo(curJewelry)

    local totalAddedExpOfCurLevel = GetSelectedJewelryAddedExp(curJewelry)
    local bCanUpdate, newJewelry, errorCode = CanUpdateAfterUsedSelectedJewelriesInBag(curJewelry)
    local bRefreshed = false
    if bCanUpdate then
        -- 刷新等级和属性信息
        fields.UILabel_Bag_SelectedJewelry_Level.text = "LV."..newJewelry:GetLevel()
        fields.UILabel_Bag_SelectedJewelry_Attribute.text = newJewelry:GetAttrText()
        fields.UISlider_JewelryExpValue.value = totalAddedExpOfCurLevel / curJewelry:GetRequiredExpIfAdvanced()
        fields.UILabel_JewelryExpValue_Progress.text = totalAddedExpOfCurLevel .. "/" .. curJewelry:GetRequiredExpIfAdvanced()
        bRefreshed = true
    else
        SetSelectedJewelryInfo(curJewelry)
    end
    return bRefreshed, errorCode

end

local function SetBagSlot(listItem, jewelry)
    listItem:SetIconTexture(jewelry:GetTextureName())
    listItem.Controls["UILabel_JewelryLevel"].text = "LV."..jewelry:GetLevel()
	listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySpriteYuan(jewelry:GetQuality())
end

local function ClearListSelectedStatus()
    if fields.UIList_JewelryBag.IsMultiCheckBox then
        -- 多选
        local selectedListItems = fields.UIList_JewelryBag:GetSelectedItems()

        if selectedListItems.Length ~= 0 then
            for i = 1, selectedListItems.Length do
                fields.UIList_JewelryBag:SetUnSelectedIndex(selectedListItems[i].Index)
            end
        end
        fields.UIToggle_White.value = false
        fields.UIToggle_Green.value = false
        fields.UIToggle_Blue.value = false
    else
        -- 单选
        local selectedListItem = fields.UIList_JewelryBag:GetSelectedItem()
        if selectedListItem and selectedListItem.Index then
            fields.UIList_JewelryBag:SetUnSelectedIndex(selectedListItem.Index)
        end
    end
end

local function ResetBagSlotList(curButtonStatus, jewelryList)
    -- 是否可以多选
    fields.UIList_JewelryBag.IsMultiCheckBox =(curButtonStatus == BUTTON_STATUS.UPDATE_JEWELRY)
	fields.UIList_JewelryBag:ResetListCount(#jewelryList)
	fields.UIScrollView_Jewelry:ResetPosition()
end



local function ShowBagInfo(curButtonStatus)
    -- Clear函数必须放在g_Jewelries数据更新之前
    ClearListSelectedStatus()
    -- g_Jewelries数据更新
    if curButtonStatus == BUTTON_STATUS.UPDATE_JEWELRY then
        -- 升序获取背包中宝珠，当选择的宝珠在背包中时去除自己，装备在玉佩上的宝珠背包显示时不去除自己
        -- (升序显示是因为低品质在前排列，优先选择低品质宝珠)
        g_Jewelries = JewelryBagManager.GetJewelriesSortedByQuality(JewelryBagManager.SORT_ORDER.ASCENDING)
        for idx, jewelry in ipairs(g_Jewelries) do
            if g_SelectedJewelry:GetType() == JewelryBagManager.JEWELRY_TYPE.JEWELRY_INBAG and jewelry:GetPos() == g_SelectedJewelry:GetPos() then
                table.remove(g_Jewelries, idx)
                break
            end
        end

    else
        -- 降序序获取背包中宝珠(降序排列是因为升级时优选选择高品质宝珠进行升级和替换)
        g_Jewelries = JewelryBagManager.GetJewelriesSortedByQuality(JewelryBagManager.SORT_ORDER.DESCENDING)

    end

    ResetBagSlotList(curButtonStatus, g_Jewelries)

    for index, jewelry in ipairs(g_Jewelries) do
        local listItem = fields.UIList_JewelryBag:GetItemByIndex(index - 1)
        SetBagSlot(listItem, jewelry)
        -- 当界面返回到被选择宝珠界面时,设置被选择状态
        if g_SelectedJewelry and g_SelectedJewelry:GetType() == JewelryBagManager.JEWELRY_TYPE.JEWELRY_INBAG
            and g_SelectedJewelry:GetPos() == jewelry:GetPos() and curButtonStatus ~= BUTTON_STATUS.UPDATE_JEWELRY then
            fields.UIList_JewelryBag:SetSelectedIndex(index - 1)
        end
    end


    -- fields.UILabel_JewelryBag_Capacity.text = #g_Jewelries .. "/" .. JewelryBagManager.GetBagTotalSize()
end

local function SelectSpecifiedQualityItems(curJewelry,specifiedQuality, isSelected)
    -- 此函数只有在宝珠升级时使用，此时界面中是品质升序显示宝珠，并且无所选宝珠本身
    for bagPos, jewelry in ipairs(g_Jewelries) do
        if jewelry ~= nil then
            if jewelry:GetQuality() == specifiedQuality then
                local listItem = fields.UIList_JewelryBag:GetItemByIndex(bagPos - 1)
				if isSelected then 
					-- 批量选择宝珠的情况下，对当前宝珠是否可以被选择进行提前判断，防止errorCode飘字数过多
					local bCanUpdate = CanUpdateAfterUsedSelectedJewelriesInBag(curJewelry,listItem.Index)
					if bCanUpdate then
						listItem.Checked = isSelected
					else
						local errorCode = LocalString.Jewelry_Error_LevelLimit2
						UIManager.ShowSystemFlyText(errorCode)
						--品质升序显示宝珠,bagPos后的宝珠必然不能用来升级
						break
					end
				else
					listItem.Checked = isSelected
				end
            end
        end
    end
end


local function SetButtons(buttonStatus)
    g_CurButtonStatus = buttonStatus

    ShowBagInfo(buttonStatus)
    -- 这组按钮公用三个功能：1.装备/取消，2.宝珠升级/替换/取消，3.升级/取消选择(最终的宝珠升级界面)
    if buttonStatus == BUTTON_STATUS.EQUIP_JEWELRY or buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY
        or buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY_INBAG then

        fields.UIGroup_Button01.gameObject:SetActive(true)
        if buttonStatus == BUTTON_STATUS.EQUIP_JEWELRY then
            -- 装载宝珠
            fields.UILabel_Button01_01_Name.text = LocalString.JewelryBag_EquipJewelry
            fields.UILabel_Button01_02_Name.text = LocalString.JewelryBag_Cancel
            -- 装备宝珠
            EventHelper.SetClick(fields.UIButton_EquipOrUpdateJewelry, function()
                -- 发装备协议
                if not g_SelectedJewelry then
                    UIManager.ShowSystemFlyText(LocalString.JewelryBag_SelectNothing)
                else
                    if not g_SelectedJadeSlotPos then
                        logError("Not Specify jade slot pos parameter!")
                    else
                        local msg = lx.gs.jade.CLoadJewelry( { index = g_SelectedJewelry:GetPos(), position = g_SelectedJadeSlotPos })
                        network.send(msg)
                    end
                end
            end )
            -- 关闭背包界面
            EventHelper.SetClick(fields.UIButton_CloseOrCancel, function()
                -- 和close按钮功能一致
                UIManager.hide("jade.dlgalert_jewelrybag")

            end )
        elseif buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY then

            fields.UILabel_Button01_01_Name.text = LocalString.JewelfyBag_Update
            fields.UILabel_Button01_02_Name.text = LocalString.JewelryBag_CancelSelect

            -- 升级宝珠
            EventHelper.SetClick(fields.UIButton_EquipOrUpdateJewelry, function()
                -- 宝珠包裹中除去所选宝珠本身

                -- 发装备协议
                if not g_SelectedJewelry then
                    UIManager.ShowSystemFlyText(LocalString.JewelryBag_SelectNothing)
                else
                    -- 升级宝珠
                    local selectedListItems = fields.UIList_JewelryBag:GetSelectedItems()
                    if selectedListItems.Length == 0 then
                        -- 没有选择升级要消耗掉的宝珠
                        UIManager.ShowSystemFlyText(LocalString.JewelryBag_SelectNothing)
                        return
                    end
                    -- 检查升级宝珠的等级限制,每次选择宝珠都做了检查，此处不再检查
					-- local bCanUpdate = CanUpdateAfterUsedSelectedJewelriesInBag(g_SelectedJewelry)
					-- if not bCanUpdate then
					--     UIManager.ShowSystemFlyText(LocalString.JewelryBag_Enhance_LimitLevel)
					--     return
					-- end

                    local selectedPropIndexes = { }
                    for i = 1,selectedListItems.Length do
                        selectedPropIndexes[#selectedPropIndexes + 1] = g_Jewelries[selectedListItems[i].Index + 1]:GetPos()
                    end
                    -- 发送协议
                    local indexInBagList = nil
                    local jadeSlotPos = nil
                    if g_SelectedJewelry:GetType() == JewelryBagManager.JEWELRY_TYPE.JEWELRY_INBAG then
                        -- 升级背包中的宝珠
                        indexInBagList = g_SelectedJewelry:GetPos()
                        jadeSlotPos = 0
                    else
                        -- 升级玉佩装载的宝珠
                        indexInBagList = 0
                        jadeSlotPos = g_SelectedJewelry:GetPos()
                    end
                    local msg = lx.gs.jade.CEnhanceJewelry( { index = indexInBagList, position = jadeSlotPos, doglist = selectedPropIndexes })
                    network.send(msg)
                end
            end )
            -- 取消选择
            EventHelper.SetClick(fields.UIButton_CloseOrCancel, function()
                -- 清楚list的选择状态
                ClearListSelectedStatus()
                -- 重设选择的宝珠信息
                SetSelectedJewelryInfo(g_SelectedJewelry)

            end )
        else
            -- 选择要升级的宝珠并转到最终宝珠升级界面

            fields.UILabel_Button01_01_Name.text = LocalString.JewelfyBag_UpdateJewelry
            fields.UILabel_Button01_02_Name.text = LocalString.JewelryBag_Cancel
            EventHelper.SetClick(fields.UIButton_EquipOrUpdateJewelry, function()
                if not g_SelectedJewelry then
                    UIManager.ShowSystemFlyText(LocalString.JewelryBag_SelectNothing)
                else
                    -- 转到最终宝珠升级界面
                    SetButtons(BUTTON_STATUS.UPDATE_JEWELRY)
                end
            end )
            -- 关闭背包界面
            EventHelper.SetClick(fields.UIButton_CloseOrCancel, function()
                -- 和close按钮功能一致
                UIManager.hide("jade.dlgalert_jewelrybag")

            end )
        end
    else
        fields.UIGroup_Button01.gameObject:SetActive(false)
    end
    -- 显示或隐藏宝珠升级\替换\卸下按钮
    fields.UIGroup_Button02.gameObject:SetActive(buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY_INJADE)
    if buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY_INJADE then

        -- 替换宝珠
        EventHelper.SetClick(fields.UIButton_ChangeJewelry, function()
            local msg = lx.gs.jade.CLoadJewelry( { index = g_SelectedJewelry:GetPos(), position = g_SelectedJadeSlotPos })
            network.send(msg)
        end )
        -- 卸载宝珠
        EventHelper.SetClick(fields.UIButton_UnloadJewelry, function()
            local msg = lx.gs.jade.CUnloadJewelry( { position = g_SelectedJadeSlotPos })
            network.send(msg)

        end )

        -- 转到最终宝珠升级界面
        EventHelper.SetClick(fields.UIButton_UpdateJewelryDlg, function()
            if not g_SelectedJewelry then
                UIManager.ShowSystemFlyText(LocalString.JewelryBag_SelectNothing)
            else
                -- 转到最终宝珠升级界面
                SetButtons(BUTTON_STATUS.UPDATE_JEWELRY)
            end
        end )

    end


    -- 最终的宝珠升级界面中其他组件显示和隐藏
    -- 显示多选选toggle组
    fields.UIGroup_Select.gameObject:SetActive(buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY)


    if buttonStatus == BUTTON_STATUS.UPDATE_JEWELRY then
        -- 以下三个UIToggle不是互斥关系，只关注自己的开与关
        EventHelper.SetClick(fields.UIToggle_White, function()

            SelectSpecifiedQualityItems(g_SelectedJewelry,cfg.item.EItemColor.WHITE, fields.UIToggle_White.value)
        end )

        EventHelper.SetClick(fields.UIToggle_Green, function()

            SelectSpecifiedQualityItems(g_SelectedJewelry,cfg.item.EItemColor.GREEN, fields.UIToggle_Green.value)
        end )

        EventHelper.SetClick(fields.UIToggle_Blue, function()

            SelectSpecifiedQualityItems(g_SelectedJewelry,cfg.item.EItemColor.BLUE, fields.UIToggle_Blue.value)
        end )
    end
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    g_SelectedJewelry = params and params.jewelry
    g_SelectedJadeSlotPos = params and params.jadeSlotPos
    SetSelectedJewelryInfo(g_SelectedJewelry)

    -- tabjade界面中点击slot
    if params and params.jadeSlotPos then
        if params.jewelry then
            -- jadeSlot有装备的宝珠
            SetButtons(BUTTON_STATUS.UPDATE_JEWELRY_INJADE)
            g_PreButtonStatus = BUTTON_STATUS.UPDATE_JEWELRY_INJADE
        else
            -- jadeSlot没有装备的宝珠
            SetButtons(BUTTON_STATUS.EQUIP_JEWELRY)
            g_PreButtonStatus = BUTTON_STATUS.EQUIP_JEWELRY
        end

    else
        -- 仅打开宝珠背包对背包中宝珠升级，无需jadeSlotPos
        SetButtons(BUTTON_STATUS.UPDATE_JEWELRY_INBAG)
        g_PreButtonStatus = BUTTON_STATUS.UPDATE_JEWELRY_INBAG
    end
end

local function hide()
    -- print(name, "hide")
    ClearListSelectedStatus()
	UIManager.refresh("jade.tabjade")
end

local function refresh(params)
    -- print(name, "refresh")
    if params and params.jewelry then
        g_SelectedJewelry = params.jewelry
    end
    ShowBagInfo(g_CurButtonStatus)
end

local function update()
    -- print(name, "update")
end

local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_JewelryBag_Close, function()
        if g_CurButtonStatus == BUTTON_STATUS.UPDATE_JEWELRY then
            SetButtons(g_PreButtonStatus)
            RefreshSelectedJewelryInfo(g_SelectedJewelry)
        else
            UIManager.hide("jade.dlgalert_jewelrybag")
        end

    end )

    EventHelper.SetListSelect(fields.UIList_JewelryBag, function(listItem)
        if g_CurButtonStatus == BUTTON_STATUS.UPDATE_JEWELRY then
            -- 多选情况，即在最终宝珠升级界面,IsMultiCheckBox为true
            local bRefresh,errorCode = RefreshSelectedJewelryInfo(g_SelectedJewelry)
			--添加确认选择
			if g_Jewelries[listItem.Index + 1]:GetQuality() >= cfg.item.EItemColor.PURPLE  then
			UIManager.ShowAlertDlg({
            title        = LocalString.PersonalBoss_AlertTitle, 
            content      = LocalString.Jewelry_UpdateTip,        
            callBackFunc1 = function()
               fields.UIList_JewelryBag:SetUnSelectedIndex(listItem.Index)        
            end,
            immediate = true,
            })
			end
			
            if not bRefresh then
				if errorCode then 
					UIManager.ShowSystemFlyText(errorCode)
				end
                fields.UIList_JewelryBag:SetUnSelectedIndex(listItem.Index)
                UIManager.ShowSystemFlyText(LocalString.JewelryBag_Enhance_MaxLevel)
            end
        else
            -- 单选情况，即在选择升级宝珠界面
            g_SelectedJewelry = g_Jewelries[listItem.Index + 1]
            SetSelectedJewelryInfo(g_Jewelries[listItem.Index + 1])
        end
    end )

    EventHelper.SetListUnSelect(fields.UIList_JewelryBag, function(listItem)
        if g_CurButtonStatus == BUTTON_STATUS.UPDATE_JEWELRY then
            -- 多选情况，即在最终宝珠升级界面，此时IsMultiCheckBox未必为true
            -- 在关闭最终升级宝珠界面时，在ResetBagSlotList函数执行前为true，执行后为false
            RefreshSelectedJewelryInfo(g_SelectedJewelry)
        elseif not fields.UIList_JewelryBag.IsMultiCheckBox then
            -- 单选情况，即在选择升级宝珠界面
            fields.UIList_JewelryBag:SetUnSelectedIndex(listItem.Index)
        end
    end )

end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}

