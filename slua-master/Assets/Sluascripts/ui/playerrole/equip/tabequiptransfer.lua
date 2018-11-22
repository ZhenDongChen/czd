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
local g_SelectedIndex 
local g_SelectedItem
local g_SelectedEquipPos
local g_Equips
local g_SelectedTransEquip
-- list初始位置信息
local g_InitPanelLocalPos
local g_InitPanelOffsetY

local ShowEquipTransfer

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
	if equip == nil then 
		return
	end	
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
	-- 是否属于本门派
	if equip:GetProfessionLimit() ~= cfg.Const.NULL and equip:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
		listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
	else 
		listItem.Controls["UISprite_RedMask"].gameObject:SetActive(false)
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

	if #g_Equips == 0 or not g_Equips then
		print("No main equip or acc in bag or on player")
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

-- 设置转移界面里的当前装备
local function SetCurEquipBox(curEquip)
	if not curEquip then
		fields.UITexture_Transfer_CurEquip_Icon:SetIconTexture("null")
		fields.UILabel_Transfer_CurEquip_AnnealLevel.gameObject:SetActive(false)
		fields.UILabel_Transfer_CurEquip_AnnealLevel.text = ""
		fields.UISprite_Transfer_CurEquip_Binding.gameObject:SetActive(false)
		fields.UISprite_Transfer_CurEquip_Quality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
	else
		fields.UITexture_Transfer_CurEquip_Icon:SetIconTexture(curEquip:GetTextureName())
		fields.UISprite_Transfer_CurEquip_Quality.spriteName = colorutil.GetQualitySprite(curEquip:GetQuality())
		-- 炼器等级为0,不显示炼器等级
		if curEquip:GetAnnealLevel() ~= 0 then
			fields.UILabel_Transfer_CurEquip_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_Transfer_CurEquip_AnnealLevel.text = "+" .. curEquip:GetAnnealLevel()
		else
			fields.UILabel_Transfer_CurEquip_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_Transfer_CurEquip_AnnealLevel.text = ""
		end
		fields.UISprite_Transfer_CurEquip_Binding.gameObject:SetActive(curEquip:IsBound())
	end
end
-- 设置转移界面里的转移装备
local function SetTransferredEquipBox(transEquip)
    if not transEquip then
        fields.UITexture_TransferredEquip_Icon:SetIconTexture("null")
        fields.UISprite_AddTransferredEquip.gameObject:SetActive(true)
        fields.UISprite_TransferredEquip_Binding.gameObject:SetActive(false)
        fields.UILabel_TransferredEquip_AnnealLevel.text = ""
        fields.UILabel_TransferredEquip_AnnealLevel.gameObject:SetActive(false)
		fields.UISprite_TransferredEquip_Quality.gameObject:SetActive(false)
    else
        fields.UITexture_TransferredEquip_Icon:SetIconTexture(transEquip:GetTextureName())
        fields.UISprite_AddTransferredEquip.gameObject:SetActive(false)
		if transEquip:GetAnnealLevel() ~= 0 then
			fields.UILabel_TransferredEquip_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_TransferredEquip_AnnealLevel.text = "+" .. transEquip:GetAnnealLevel()
		else
			fields.UILabel_TransferredEquip_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_TransferredEquip_AnnealLevel.text = ""
		end
		-- 绑定
        fields.UISprite_TransferredEquip_Binding.gameObject:SetActive(transEquip:IsBound())
        -- 设置品质
		fields.UISprite_TransferredEquip_Quality.gameObject:SetActive(true)
		--fields.UISprite_TransferredEquip_Quality.spriteName = "Sprite_ItemQuality"
        fields.UISprite_TransferredEquip_Quality.spriteName = colorutil.GetQualitySprite(transEquip:GetQuality())
    end
end

local function SetEquipTransferSuccessRate()
    fields.UILabel_Transfer_SuccessRate.text = "100%"
end

-- 设置属性链表里的炼器
local function SetEquipTransfer_AttributeList_Anneal(toggleValue)

    if toggleValue then
        fields.UILabel_AttributeList_CurEquip_AnnealLevel.gameObject:SetActive(true)
        fields.UILabel_AttributeList_CurEquip_AnnealLevel.text = format(LocalString.EquipEnhance_Transfer_AnnealLevel, g_SelectedItem:GetAnnealLevel())

        if not g_SelectedTransEquip then
            fields.UILabel_AttributeList_TransEquip_AnnealLevel.text = format(LocalString.EquipEnhance_Transfer_AnnealLevel, 0)
            fields.UILabel_AttributeList_TransEquip_AnnealLevel.gameObject:SetActive(false)

        else
            fields.UILabel_AttributeList_TransEquip_AnnealLevel.gameObject:SetActive(true)
            fields.UILabel_AttributeList_TransEquip_AnnealLevel.text = format(LocalString.EquipEnhance_Transfer_AnnealLevel, g_SelectedTransEquip:GetAnnealLevel())
        end
    else
        fields.UILabel_AttributeList_CurEquip_AnnealLevel.gameObject:SetActive(false)
        fields.UILabel_AttributeList_TransEquip_AnnealLevel.gameObject:SetActive(false)
    end
end
-- 设置属性链表里的灌注
local function SetEquipTransfer_AttributeList_Perfuse(toggleValue)

    if toggleValue then
        fields.UILabel_AttributeList_CurEquip_PerfuseLevel.gameObject:SetActive(true)
        fields.UILabel_AttributeList_CurEquip_PerfuseLevel.text = format(LocalString.EquipEnhance_Transfer_PerfuseLevel, g_SelectedItem:GetPerfuseLevel())

        if not g_SelectedTransEquip then
            fields.UILabel_AttributeList_TransEquip_PerfuseLevel.text = format(LocalString.EquipEnhance_Transfer_PerfuseLevel, 0)
            fields.UILabel_AttributeList_TransEquip_PerfuseLevel.gameObject:SetActive(false)

        else
            fields.UILabel_AttributeList_TransEquip_PerfuseLevel.gameObject:SetActive(true)
            fields.UILabel_AttributeList_TransEquip_PerfuseLevel.text = format(LocalString.EquipEnhance_Transfer_PerfuseLevel, g_SelectedTransEquip:GetPerfuseLevel())
        end
    else
        fields.UILabel_AttributeList_CurEquip_PerfuseLevel.gameObject:SetActive(false)
        fields.UILabel_AttributeList_TransEquip_PerfuseLevel.gameObject:SetActive(false)
    end
end
-- 设置属性列表里的炼器和灌注
local function SetEquipTransfer_AttributeList(toggle_Anneal, toggle_Perfuse)
    SetEquipTransfer_AttributeList_Anneal(toggle_Anneal)
    SetEquipTransfer_AttributeList_Perfuse(toggle_Perfuse)
end

local function AddTransEquip(params)
	g_SelectedTransEquip = params.equip
	SetTransferredEquipBox(g_SelectedTransEquip)
	local tvalue1 = fields.UIToggle_TransferAnnealLevel.value
	local tvalue2 = fields.UIToggle_TransferPerfuseLevel.value
	SetEquipTransfer_AttributeList(tvalue1, tvalue2)
end
-- 显示转移界面
ShowEquipTransfer = function()
    -- 当前装备
	SetCurEquipBox(g_SelectedItem)

    -- 清空选择材料
    -- g_SelectedTransEquip = nil
    SetTransferredEquipBox(g_SelectedTransEquip)
    -- 转移不消耗虚拟币
	local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,0)
	fields.UISprite_Transfer_Money_Icon.spriteName = currency:GetIconName()
    fields.UILabel_Transfer_Needed_Money.text = currency:GetNumber()
    -- 设置转移列表
    local tvalue1 = fields.UIToggle_TransferAnnealLevel.value
    local tvalue2 = fields.UIToggle_TransferPerfuseLevel.value
    SetEquipTransfer_AttributeList(tvalue1, tvalue2)
    -- 成功率
    SetEquipTransferSuccessRate()
    -- 显示当前装备
    EventHelper.SetClick(fields.UIButton_CurEquipBox, function()
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
    -- 添加转移装备
    EventHelper.SetClick(fields.UIButton_AddTransferredEquip, function()
        -- 只有同类型和同职业的装备可以转移,转移包括身上和背包的装备
        local allTransEquipsInBag = BagManager.GetItemByType(cfg.bag.BagType.EQUIP, g_SelectedItem:GetDetailType(), g_SelectedItem:GetProfessionLimit())
        -- 去掉本身,背包里的全部加入
        local trans = { }
        for _, trnEquipInBag in ipairs(allTransEquipsInBag) do
            if g_SelectedItem:GetId() ~= trnEquipInBag:GetId() then
                trans[#trans + 1] = trnEquipInBag
            end
        end
        -- 去掉本身,所选装备职业和玩家职业一致或者无限制职业，才可以转移玩家身上装备
        local allTransEquipsOnPlayer = BagManager.GetItemByType(cfg.bag.BagType.EQUIP_BODY, g_SelectedItem:GetDetailType(), g_SelectedItem:GetProfessionLimit())
        for _, trnEquipOnPlayer in ipairs(allTransEquipsOnPlayer) do
            if g_SelectedItem:GetId() ~= trnEquipOnPlayer:GetId() then
                trans[#trans + 1] = trnEquipOnPlayer
            end
        end

        if #trans == 0 then
            UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Transfer_NoTransEquips)
        else
            local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
            UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.TransferredEquips, equips = trans })

        end

    end )

    EventHelper.SetToggle(fields.UIToggle_TransferAnnealLevel, function(toggle, toggleValue)

        SetEquipTransfer_AttributeList_Anneal(toggleValue)
    end )


    EventHelper.SetToggle(fields.UIToggle_TransferPerfuseLevel, function(toggle, toggleValue)

        SetEquipTransfer_AttributeList_Perfuse(toggleValue)
    end )


    -- 转移
    EventHelper.SetClick(fields.UIButton_EquipTransfer, function()
        if not g_SelectedTransEquip then
            UIManager.ShowSystemFlyText(LocalString.EquipEnhance_Transfer_ChoseEquip)
        else
            local bTransferAnnealLevel = fields.UIToggle_TransferAnnealLevel.value and 1 or 0
            local bTransferPerfuseLevel = fields.UIToggle_TransferPerfuseLevel.value and 1 or 0

            if bTransferAnnealLevel == 0 and bTransferPerfuseLevel == 0 then
                UIManager.ShowSystemFlyText(LocalString.EquipEnhance_TransferTip1)
                return
            end
            local curEquipLimitLevel = (ConfigManager.getConfigData("enhanceconfig",g_SelectedItem:GetLevel())).appendlimit
            local transEquipLimitLevel = (ConfigManager.getConfigData("enhanceconfig",g_SelectedTransEquip:GetLevel())).appendlimit
			
            if bTransferPerfuseLevel == 1 and math.max(g_SelectedItem:GetPerfuseLevel(), g_SelectedTransEquip:GetPerfuseLevel()) > math.min(curEquipLimitLevel, transEquipLimitLevel) then
                -- 转移灌注等级并且有灌注等级损失，则无法转移
                UIManager.ShowSystemFlyText(LocalString.EquipEnhance_TransferTip2)
                return
            end
            local msg = lx.gs.equip.normalequip.CSwapEquipProp( {

                bagtype1      = g_SelectedItem.BagType,
                pos1          = g_SelectedItem.BagPos,
                bagtype2      = g_SelectedTransEquip.BagType,
                pos2          = g_SelectedTransEquip.BagPos,
                isswapanneal  = bTransferAnnealLevel,
                isswapperfuse = bTransferPerfuseLevel,

            } )
            network.send(msg)
        end
    end )


end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_TransferEffect_Common.gameObject)
end

local function OnMsg_SSwapEquipProp(msg)
    -- print("OnMsg_SSwapEquipProp")
	if g_SelectedItem and g_SelectedTransEquip 
		and msg.bagtype1 == g_SelectedItem:GetBagType() and msg.pos1 == g_SelectedItem:GetBagPos()  
		and msg.bagtype2 == g_SelectedTransEquip:GetBagType() and msg.pos2 == g_SelectedTransEquip:GetBagPos() then

		UIManager.ShowSystemFlyText(LocalString.EquipEnhance_TransferSuccess)
		-- 交换炼器和灌注等级
		if msg.isswapanneal == 1 then
			local curEquipAnnealLevel = g_SelectedItem:GetAnnealLevel()
			g_SelectedItem:SetAnnealLevel(g_SelectedTransEquip:GetAnnealLevel())
			g_SelectedTransEquip:SetAnnealLevel(curEquipAnnealLevel)
		end
		if msg.isswapperfuse == 1 then
			local curEquipPerfuseLevel = g_SelectedItem:GetPerfuseLevel()
			g_SelectedItem:SetPerfuseLevel(g_SelectedTransEquip:GetPerfuseLevel())
			g_SelectedTransEquip:SetPerfuseLevel(curEquipPerfuseLevel)
		end
		-- 播放UI特效
		fields.UIGroup_TransAnnealEffect.gameObject:SetActive(msg.isswapanneal == 1)
		fields.UIGroup_TransPerfuseEffect.gameObject:SetActive(msg.isswapperfuse == 1)
		UIManager.PlayUIParticleSystem(fields.UIGroup_TransferEffect_Common.gameObject)
		UIManager.showorrefresh("dlgtweenset",{
				tweenfield = "UIPlayTweens_EquipTransfer",
		})
		-- 刷新界面
		SetCurEquipBox(g_SelectedItem)
		SetTransferredEquipBox(g_SelectedTransEquip)
		local tvalue1 = fields.UIToggle_TransferAnnealLevel.value
		local tvalue2 = fields.UIToggle_TransferPerfuseLevel.value
		SetEquipTransfer_AttributeList(tvalue1, tvalue2)
		-- 刷新列表
		RefreshEquipList(g_SelectedEquipPos)
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
		fields.UILabel_Title.text = LocalString.Enhance_Transfer_Title[1]
	elseif g_SelectedItem:IsAccessory() then 
		fields.UILabel_Title.text = LocalString.Enhance_Transfer_Title[2]
	end

	local btnToggle = fields.UIButton_Body.gameObject:GetComponent(UIToggle)
	btnToggle.value = true
    g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
    SetEquipList(g_SelectedEquipPos,g_SelectedItem)

    listenerIds = network.add_listeners( {
        { "lx.gs.equip.normalequip.SSwapEquipProp", OnMsg_SSwapEquipProp },
    } )
end

local function hide()
    -- print(name, "hide")
    network.remove_listeners(listenerIds)
    g_SelectedItem = nil
    g_SelectedTransEquip = nil
	StopUIParticleSystem()
end

local function refresh(params)
    -- print(name, "refresh")
	RefreshEquipList(g_SelectedEquipPos)
	ShowEquipTransfer()
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
		local equipWrapContent = fields.UIList_Equip.gameObject:GetComponent("UIGridWrapContent")
		local realIndex = equipWrapContent:Index2RealIndex(listItem.Index)
		g_SelectedIndex = realIndex
		g_SelectedItem = g_Equips[realIndex + 1]
		EquipEnhanceManager.SetEquip(g_SelectedItem)
		g_SelectedTransEquip = nil
		SetTransferredEquipBox(g_SelectedTransEquip)
		ShowEquipTransfer()
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
end

return {
    init           = init,
    show           = show,
    hide           = hide,
    update         = update,
    destroy        = destroy,
    refresh        = refresh,
	uishowtype     = uishowtype,
	AddTransEquip  = AddTransEquip,
}
