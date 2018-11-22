local require       = require
local unpack        = unpack
local print         = print
local math          = math
local utils         = require("common.utils")
local format        = string.format
local GameEvent     = require("gameevent")
local UIManager     = require("uimanager")
local network       = require("network")
local PlayerRole    = require("character.playerrole")
local BagManager    = require("character.bagmanager")
local ConfigManager = require("cfg.configmanager")
local ItemManager   = require("item.itemmanager")
local ItemIntroduct = require("item.itemintroduction")
local ItemEnum      = require("item.itemenum")
local CheckCmd      = require("common.checkcmd")
local EventHelper   = UIEventListenerHelper
local EquipEnhanceManager = require("ui.playerrole.equip.equipenhancemanager")


local gameObject
local name
local fields
-- 全局变量
local g_SelectedItem
local g_SelectedIndex
local g_SelectedEquipPos
local g_Equips
-- list初始位置信息
local g_InitPanelLocalPos
local g_InitPanelOffsetY

local ShowEquipPerfuse

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

-- 灌注符
local function SetPerfuseSpellBox(curEquip)
    local perfuseSpellCost = ConfigManager.getConfigData("appendcost", curEquip:GetDetailType())
	local maxPerfuseLevel = (ConfigManager.getConfigData("enhanceconfig",curEquip:GetLevel())).appendlimit

    -- 灌注符显示部分
	local perfuseSpellId = 0
	if curEquip:IsMainEquip() then
		perfuseSpellId = cfg.equip.AppendCost.COST_ITEM_ID
	elseif curEquip:IsAccessory() then
		perfuseSpellId = cfg.equip.AppendCost.ACCESSORY_COST_ITEM_ID
	end
    local allPerfuseSpellNumInBag = BagManager.GetItemNumById(perfuseSpellId)
    local bHasBindedPerfuseSpell = false

    -- 灌注后装备，如果灌注等级超过最大灌注等级，面板信息显示最大灌注等级信息
    local nextEquipPerfuseLevel = curEquip:GetPerfuseLevel() + 1
	if curEquip:GetPerfuseLevel() >= maxPerfuseLevel then
        nextEquipPerfuseLevel = curEquip:GetPerfuseLevel()
    end
    -- 背包里存在灌注符
    if allPerfuseSpellNumInBag ~= 0 then
		-- 判断是否有绑定类型
		local perfuseSpells = BagManager.GetItemById(perfuseSpellId)
        for _, perfuse in pairs(perfuseSpells) do
            -- 绑定类型
            if perfuse:IsBound() then
                bHasBindedPerfuseSpell = true
				break
            end
        end

        fields.UISprite_PerfuseSpell_Binding.gameObject:SetActive(bHasBindedPerfuseSpell)
        fields.UITexture_PerfuseSpell_Icon:SetIconTexture(perfuseSpells[1]:GetTextureName())
		fields.UISprite_PerfuseSpellBox_Quality.spriteName = colorutil.GetQualitySprite(perfuseSpells[1]:GetQuality())
		fields.UILabel_PerfuseSpell_Name.text = perfuseSpells[1]:GetName()
		if allPerfuseSpellNumInBag >= perfuseSpellCost.itemcost[nextEquipPerfuseLevel] then 
			colorutil.SetLabelColorText(fields.UILabel_PerfuseSpell_Number,colorutil.ColorType.Green_Remind,(allPerfuseSpellNumInBag .. "/" .. perfuseSpellCost.itemcost[nextEquipPerfuseLevel]))
		else
			colorutil.SetLabelColorText(fields.UILabel_PerfuseSpell_Number,colorutil.ColorType.Red_Remind,(allPerfuseSpellNumInBag .. "/" .. perfuseSpellCost.itemcost[nextEquipPerfuseLevel]))
		end
    else
        local perfuseSpell = ItemManager.CreateItemBaseById(perfuseSpellId, nil, 0)
		if perfuseSpell then 
			fields.UISprite_PerfuseSpell_Binding.gameObject:SetActive(true)
			fields.UITexture_PerfuseSpell_Icon:SetIconTexture(perfuseSpell:GetTextureName())
			fields.UISprite_PerfuseSpellBox_Quality.spriteName = colorutil.GetQualitySprite(perfuseSpell:GetQuality())
			fields.UILabel_PerfuseSpell_Name.text = perfuseSpell:GetName()
			colorutil.SetLabelColorText(fields.UILabel_PerfuseSpell_Number,colorutil.ColorType.Red_Remind,("0/" .. perfuseSpellCost.itemcost[nextEquipPerfuseLevel]))
		end
    end

end

-- 刷新灌注等级进度条
local function RefreshPerfuseLevelProgressbar(curEquip)

	local maxPerfuseLevel = (ConfigManager.getConfigData("enhanceconfig",curEquip:GetLevel())).appendlimit
    fields.UISlider_CurEquipPerfuseLevel.value = curEquip:GetPerfuseLevel() / maxPerfuseLevel
    fields.UILabel_CurEquipPerfuseLevel.text = curEquip:GetPerfuseLevel() .. "/" .. maxPerfuseLevel
end

local function SetEquipPerfuseSuccessRate()
    fields.UILabel_Perfuse_SuccessRate.text = "100%"
end

-- 显示灌注界面
-- 目前1级装备不显示灌注界面
ShowEquipPerfuse = function()
	-- 不同等级的武器有不同的最大等级限制，具体参见enhanceconfig表
	local maxPerfuseLevel = (ConfigManager.getConfigData("enhanceconfig",g_SelectedItem:GetLevel())).appendlimit
	if maxPerfuseLevel == 0 then
		fields[UIGROUP_COMS_NAME[2]].gameObject:SetActive(false)
		UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_CanNotPerfuse,g_SelectedItem:GetLevel()))
		return
	end

    -- 灌注前装备信息
    fields.UITexture_Perfuse_CurEquip_Icon:SetIconTexture(g_SelectedItem:GetTextureName())
	fields.UISprite_Perfuse_CurEquip_Quality.spriteName = colorutil.GetQualitySprite(g_SelectedItem:GetQuality())
	-- 灌注等级为0,不显示灌注等级
	if g_SelectedItem:GetPerfuseLevel() == 0 then
		fields.UILabel_CurEquip_PerfuseLevel.gameObject:SetActive(false)
		fields.UILabel_CurEquip_PerfuseLevel.text = ""
	else
		fields.UILabel_CurEquip_PerfuseLevel.gameObject:SetActive(true)
		fields.UILabel_CurEquip_PerfuseLevel.text = "+" .. g_SelectedItem:GetPerfuseLevel()
	end
	-- 绑定类型
    fields.UISprite_Perfuse_CurEquip_Binding.gameObject:SetActive(g_SelectedItem:IsBound())


    -- 灌注后装备信息
	-- 如果灌注等级超过最大灌注等级，面板信息显示最大灌注等级信息
    local nextEquipAfterPerfuse = utils.copy_table(g_SelectedItem)

    if g_SelectedItem:GetPerfuseLevel() < maxPerfuseLevel then
        nextEquipAfterPerfuse:SetPerfuseLevel(g_SelectedItem:GetPerfuseLevel() + 1)
    else
        -- 达到最大灌注等级
        fields.UILabel_Perfuse_NextEquip_StatusDecs.text = LocalString.EquipEnhance_MaxLevel
    end

    fields.UITexture_Perfuse_NextEquip_Icon:SetIconTexture(nextEquipAfterPerfuse:GetTextureName())
	fields.UISprite_Perfuse_NextEquip_Quality.spriteName = colorutil.GetQualitySprite(nextEquipAfterPerfuse:GetQuality())
    fields.UILabel_NextEquip_PerfuseLevel.text = "+" ..(nextEquipAfterPerfuse:GetPerfuseLevel())

	-- 战斗力提升数值显示
	fields.UILabel_EquipPerfuse_AddedPower.text = "+" .. (nextEquipAfterPerfuse:GetPower()-g_SelectedItem:GetPower())
	-- 绑定类型
    fields.UISprite_Perfuse_NextEquip_Binding.gameObject:SetActive(nextEquipAfterPerfuse:IsBound())
    -- 灌注等级进度条显示
    RefreshPerfuseLevelProgressbar(g_SelectedItem)
    local perfuseCost = ConfigManager.getConfigData("appendcost", g_SelectedItem:GetDetailType())

    -- 灌注符显示
    SetPerfuseSpellBox(g_SelectedItem)

    -- 成功率
    SetEquipPerfuseSuccessRate()
	-- 灌注消耗虚拟币，配置写死，不消耗其他币种
    local perfuseCost_Currency = perfuseCost.expenses[nextEquipAfterPerfuse:GetPerfuseLevel()]
	local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.XuNiBi,nil,perfuseCost_Currency)
	fields.UISprite_Perfuse_Money_Icon.spriteName = currency:GetIconName()
    fields.UILabel_Perfuse_Needed_Money.text = currency:GetNumber()

    -- 灌注界面里点击查看当选炼器装备的详细信息
    EventHelper.SetClick(fields.UIButton_Perfuse_CurEquip, function()
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
    -- 灌注界面里点击查看炼器后装备的详细信息
    EventHelper.SetClick(fields.UIButton_Perfuse_NextEquip, function()
        ItemIntroduct.DisplayItem( {
            item = nextEquipAfterPerfuse,
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

    EventHelper.SetClick(fields.UIButton_EquipPerfuse, function()

        -- 灌注等级会根据武器装备等级进行限制
        -- 达到配置最大灌注等级,优先检查是否达到最大灌注等级
        if g_SelectedItem:GetPerfuseLevel() >= maxPerfuseLevel then
            UIManager.ShowSystemFlyText(LocalString.EquipEnhance_MaxPerfuseLevel)
            return
        end
        -- 钱币类型写死，为虚拟币，检查虚拟币是否足够
        if PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi) < perfuseCost_Currency then
            UIManager.ShowSystemFlyText(LocalString.Enhance_CurrencyNotEnough)
            if g_SelectedItem:IsMainEquip() then
			    ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgequipenhance")
            elseif g_SelectedItem:IsAccessory() then
			    ItemManager.GetSource(currency:GetConfigId(),"playerrole.equip.dlgaccessoryenhance")
            end
            return
        end
        -- 配置未设cmd，检查道具(灌注符)是否足够
		local perfuseSpellId = 0
		if g_SelectedItem:IsMainEquip() then 
			perfuseSpellId = cfg.equip.AppendCost.COST_ITEM_ID
		elseif g_SelectedItem:IsAccessory() then
			perfuseSpellId = cfg.equip.AppendCost.ACCESSORY_COST_ITEM_ID
		end
        local perfuseSpellNumInBag = BagManager.GetItemNumById(perfuseSpellId)
		local perfuseSpell = ItemManager.CreateItemBaseById(perfuseSpellId,nil,perfuseCost.itemcost[g_SelectedItem:GetPerfuseLevel() + 1])
        if perfuseSpell and (perfuseSpell:GetNumber() > perfuseSpellNumInBag) then
            UIManager.ShowSystemFlyText(format(LocalString.Enhance_PropNotEnough,perfuseSpell:GetName()))
            if g_SelectedItem:IsMainEquip() then
			    ItemManager.GetSource(perfuseSpellId,"playerrole.equip.dlgequipenhance")
            elseif g_SelectedItem:IsAccessory() then
			    ItemManager.GetSource(perfuseSpellId,"playerrole.equip.dlgaccessoryenhance")
            end
            return
        end

        local bOnlyUseNotBoundProps = fields.UIToggle_Perfuse_OnlyUseNotBoundProps.value and 1 or 0
        local msg = lx.gs.equip.normalequip.CPerfuseEquip(
        {
            bagtype      = g_SelectedItem.BagType,
            pos          = g_SelectedItem.BagPos,
            unbindonly   = bOnlyUseNotBoundProps,
        } )
        network.send(msg)

    end )
end

local function StopUIParticleSystem()
	UIManager.StopUIParticleSystem(fields.UIGroup_PropEffect.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_PerfuseEffect_Frame.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_AnnealEffect_Start.gameObject)
	UIManager.StopUIParticleSystem(fields.UIGroup_AnnealEffect_Success.gameObject)
end
-- region msg
local function OnMsg_SPerfuseInfoUpdate(msg)
    -- print("OnMsg_SPerfuseInfoUpdate")
	if g_SelectedItem and msg.bagtype == g_SelectedItem:GetBagType() and msg.pos == g_SelectedItem:GetBagPos() then
		-- 播放灌注特效，和炼器特效基本一致
		UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Start.gameObject)
		UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Success.gameObject)
		-- 播放UI特效
		UIManager.PlayUIParticleSystem(fields.UIGroup_PropEffect.gameObject)
		UIManager.PlayUIParticleSystem(fields.UIGroup_PerfuseEffect_Frame.gameObject)

		UIManager.ShowSystemFlyText(format(LocalString.EquipEnhance_PerfuseSuccess , 1))
		-- 播放炼器特效
		--UIManager.PlayUIParticleSystem(fields.UIGroup_AnnealEffect_Success.gameObject)
		UIManager.showorrefresh("dlgtweenset", {
			tweenfield = "UIPlayTweens_EquipPerfuseSuccess",
		} )

		g_SelectedItem:SetPerfuseLevel(msg.newlevel)
		-- 刷新灌注等级进度条
		RefreshPerfuseLevelProgressbar(g_SelectedItem)
		RefreshEquipList(g_SelectedEquipPos)
		ShowEquipPerfuse()
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
		fields.UILabel_Title.text = LocalString.Enhance_Perfuse_Title[1]
	elseif g_SelectedItem:IsAccessory() then 
		fields.UILabel_Title.text = LocalString.Enhance_Perfuse_Title[2]
	end
	-- fields.UIList_Equip:Clear()
	local btnToggle = fields.UIButton_Body.gameObject:GetComponent(UIToggle)
	btnToggle.value = true
    g_SelectedEquipPos = EQUIP_POS.EQUIP_ON_PLAYER
    SetEquipList(g_SelectedEquipPos,g_SelectedItem)

    listenerIds = network.add_listeners( {
        { "lx.gs.equip.normalequip.SPerfuseInfoUpdate", OnMsg_SPerfuseInfoUpdate },
    } )
end

local function hide()
    -- print(name, "hide")
    network.remove_listeners(listenerIds)
    g_SelectedItem = nil
	StopUIParticleSystem()
end

local function refresh(params)
    -- print(name, "refresh")
	RefreshEquipList(g_SelectedEquipPos)
	ShowEquipPerfuse()
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
		ShowEquipPerfuse()
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
    init       = init,
    show       = show,
    hide       = hide,
    update     = update,
    destroy    = destroy,
    refresh    = refresh,
	uishowtype = uishowtype,
}
