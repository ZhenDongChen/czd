local require        = require
local unpack         = unpack
local print          = print
local os             = os
local math           = math
local format         = string.format
local UIManager      = require("uimanager")
local network        = require("network")
local PlayerRole     = require("character.playerrole")
local ConfigManager  = require("cfg.configmanager")
local timeutils      = require("common.timeutils")
local ItemManager    = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local ItemEnum       = require("item.itemenum")
local BonusManager   = require("item.bonusmanager")
local BagManager     = require("character.bagmanager")
local PetManager     = require("character.pet.petmanager")
local WelfareManager = require("ui.welfare.welfaremanager")
local CheckCmd       = require("common.checkcmd")
local EventHelper    = UIEventListenerHelper


local UIGROUP_COMS_NAME =
{

	 [1] = "UIGroup_WishingTree",
}

local ONLINE_GIFTBOX_NUM = 6

local gameObject
local name
local fields
local ShowPage

local selectedPet

local g_LeftSecs = 0
local g_TabIndex = 0 

local function InitGiftBagList()
    fields.UILabel_Title.text = LocalString.Welfare_GiftBagTitle;
    if fields.UIList_GiftBag.Count == 0 then
		local playerGiftData = WelfareManager.GetNewPlayerGiftData()
        for _, day in ipairs(playerGiftData.DayList) do
            local listItem = fields.UIList_GiftBag:AddListItem()
            listItem:SetText("UILabel_Day", format(LocalString.Welfare_Day, day))
            local buttonReceive = listItem.Controls["UIButton_Receive01"]

            local items = BonusManager.GetItemsOfBonus( { bonustype = "cfg.bonus.BeginnerBonus", csvid = day })

            local dayGiftList = listItem.Controls["UIList_DayGifts"]

            for i = 1, #items do
                local dayGiftListItem = dayGiftList:AddListItem()

                dayGiftListItem:SetIconTexture(items[i]:GetTextureName())
                dayGiftListItem.Controls["UILabel_Amount"].text = items[i]:GetNumber()
				dayGiftListItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(items[i]:GetQuality())
				dayGiftListItem.Controls["UISprite_Fragment"].gameObject:SetActive(items[i]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
				dayGiftListItem.Controls["UISprite_Get"].gameObject:SetActive(false)
				dayGiftListItem.Controls["UISprite_Binding"].gameObject:SetActive(items[i]:IsBound())
                dayGiftListItem.Data = items[i]
            end
        end
    end
end

local function InitContinueLoginBoxList()
    if fields.UIList_GiftBox.Count == 0 then
        local loginData = WelfareManager.GetContinueLoginData()
        for i = 1, 8 do
            local listItem = fields.UIList_GiftBox:AddListItem()
            listItem:GetTexture("UITexture_GiftBox_Close").gameObject:SetActive(true)
			listItem:GetTexture("UITexture_GiftBox_Open").gameObject:SetActive(false)
			listItem.Controls["UISprite_Get"].gameObject:SetActive(false)
        end

        EventHelper.SetListClick(fields.UIList_GiftBox, function(listItem)

            if loginData.LeftGiftNum >= 1 then
                local msg = lx.gs.bonus.msg.CContinueLoginGift( { boxid = listItem.Index + 1 })
                network.send(msg)
            end
        end )
    end
end

local function InitWelfareTypeList()
    if fields.UIList_WelfareTab.Count == 0 then
		local hiddenTabs = WelfareManager.GetHiddenTabs()
        for i = 1, #UIGROUP_COMS_NAME do
            local listItem = fields.UIList_WelfareTab:AddListItem()
            listItem:SetText("UILabel_WelfareTypeName", LocalString.WelfareType[7])
            listItem.Controls["UISprite_Warning"].gameObject:SetActive(false)
            fields[UIGROUP_COMS_NAME[i]].gameObject:SetActive(false)
			if hiddenTabs[i] then 
				-- 去掉入口按钮
				listItem.gameObject:SetActive(false)
			end 
        end
    end
end

local function ClearWelfareTypeList()
    if fields.UIList_WelfareTab.Count ~= 0 then
        fields.UIList_WelfareTab:Clear()
    end
end

local function RefreshRedDot()
    local UnRead = WelfareManager.UntreeRed()
    for pageIndex = 1,fields.UIList_WelfareTab.Count do
        local listItem = fields.UIList_WelfareTab:GetItemByIndex(pageIndex - 1)
        listItem.Controls["UISprite_Warning"].gameObject:SetActive(UnRead)
    end
    -- 红点刷新
	if UIManager.needrefresh("dlguimain") then
		UIManager.call("dlguimain","RefreshRedDotType",cfg.ui.FunctionList.WELFARE)
	end
	if UIManager.needrefresh("dlgdialog") then
		UIManager.call("dlgdialog","RefreshRedDot","lottery.dlglottery")
	end
end



-- 许愿界面
local function ShowWishPage()
	fields.UILabel_WishDesc.gameObject:SetActive(not shouldHideVip())
    fields.UILabel_WishDesc.text = LocalString.Welfare_WishDescTxt1
    local wishData = WelfareManager.GetWishData()

    local bonusConfig = ConfigManager.getConfig("bonusconfig")
    local vipWishLimitNum = bonusConfig.viptimes[PlayerRole:Instance().m_VipLevel + 1]

    local leftWishPropNum = BagManager.GetItemNumById(bonusConfig.vowitem)
	local wishProp = ItemManager.CreateItemBaseById(bonusConfig.vowitem,nil,leftWishPropNum)
	-- 设置许愿道具信息
	fields.UITexture_WishPropIcon:SetIconTexture(wishProp:GetTextureName())
	fields.UILabel_LeftWishPropNum.text = wishProp:GetNumber()
	fields.UISprite_WishPropQuality.spriteName = colorutil.GetQualitySprite(wishProp:GetQuality())

    if wishData.SelectedPet then
        selectedPet = wishData.SelectedPet
        fields.UITexture_PartnerIcon:SetIconTexture(wishData.SelectedPet:GetTextureName())
		fields.UISprite_PartnerQuality.spriteName = colorutil.GetQualitySprite(wishData.SelectedPet:GetQuality())
    else
        selectedPet = nil
        fields.UITexture_PartnerIcon:SetIconTexture("null")
		fields.UISprite_PartnerQuality.spriteName = colorutil.GetQualitySprite(cfg.item.EItemColor.WHITE)
    end

    fields.UILabel_VipWishLimit.text = (vipWishLimitNum-wishData.UsedWishTime) .. "/" .. vipWishLimitNum

	EventHelper.SetClick(fields.UITexture_WishPropIcon,function()
		ItemIntroduct.DisplayBriefItem({ item = wishProp })
	end)

    EventHelper.SetClick(fields.UIButton_WishingTree, function()
        if vipWishLimitNum then
            if wishData.SelectedPet then
                    if wishProp:GetNumber() <= 0 then
                        UIManager.ShowSystemFlyText(format(LocalString.Welfare_WishPropNotEnough,wishProp:GetName()))
						ItemManager.GetSource(wishProp:GetConfigId(),"welfare.dlgwelfare")
                    else
                        if wishData.UsedWishTime < vipWishLimitNum then
                            local msg = lx.gs.bonus.msg.CGetWishGift( { petid = wishData.SelectedPet:GetConfigId() })
                            network.send(msg)
                        else
                            UIManager.ShowSystemFlyText(LocalString.Welfare_VipUpperLimitWishTime)
                        end
                    end
            else
                -- 提示选择伙伴
                UIManager.ShowSystemFlyText(LocalString.Welfare_WishingTree_NoPet)
            end
		else
			logError(format("No Vip:%s wish limit time data",PlayerRole:Instance().m_VipLevel))
        end
    end )

    EventHelper.SetClick(fields.UIButton_Partner, function()
        local bagPets = PetManager.GetSortedAttainedPets()
        if getn(bagPets) ~= 0 then
            local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
			UIManager.show("common.dlgdialogbox_itemlist", { type = DlgDialogBox_ItemList.DlgType.WelfarePets})
        else
            -- 提示背包中无伙伴
            UIManager.ShowSystemFlyText(LocalString.Welfare_WishingTree_PetEmpty)
        end
    end )

    if  selectedPet == nil then
        fields.UIButton_WishingTree.isEnabled = false
    else
        fields.UIButton_WishingTree.isEnabled = true
    end

end








ShowPage =
{
	 [1] = ShowAddStrengthPage,
}



local function destroy()

end

local function show(params)
    ShowWishPage()
end

local function hide()

end

local function refresh(params)

	if params and type(params) == "table" and params.tabindex2 then 
		g_TabIndex = params.tabindex2-1
	end
	fields.UIList_WelfareTab:SetUnSelectedIndex(g_TabIndex)
	fields.UIList_WelfareTab:SetSelectedIndex(g_TabIndex)
    RefreshRedDot()
end

local function update()
end



local function init(params)
    name, gameObject, fields = unpack(params)

    InitWelfareTypeList()
	ShowWishPage()
    EventHelper.SetListSelect(fields.UIList_WelfareTab, function(listItem)
        fields[UIGROUP_COMS_NAME[listItem.Index + 1]].gameObject:SetActive(true)
		g_TabIndex = listItem.Index
        --ShowPage[listItem.Index + 1]()
    end )

    EventHelper.SetListUnSelect(fields.UIList_WelfareTab, function(listItem)
        fields[UIGROUP_COMS_NAME[listItem.Index + 1]].gameObject:SetActive(false)
    end )

end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    init                      = init,
    show                      = show,
    hide                      = hide,
    update                    = update,
    destroy                   = destroy,
    refresh                   = refresh,
    ShowWishPage              = ShowWishPage,
	ShowAddStrengthPage	      = ShowAddStrengthPage,
    RefreshRedDot             = RefreshRedDot,
    uishowtype                = uishowtype,
}
