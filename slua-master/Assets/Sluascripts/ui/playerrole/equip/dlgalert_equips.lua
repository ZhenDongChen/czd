local require     = require
local unpack      = unpack
local print       = print
local format      = string.format
local UIManager   = require("uimanager")
local network     = require("network")
local BagManager  = require("character.bagmanager")
local EventHelper = UIEventListenerHelper
local ItemManager = require("item.itemmanager")

local gameObject
local name
local fields

-- 全局变量
local g_DlgType
local g_Equips = { }

local function SetEquipListItem(listItem, equip)

    -- 设置公用Label显隐
    listItem.Controls["UIGroup_Line1"].gameObject:SetActive(true)
    listItem.Controls["UIGroup_Line2_Resize"].gameObject:SetActive(true)
    -- 设置右边具体信息
    listItem:SetText("UILabel_Line1", equip:GetName())
    listItem:SetText("UILabel_Line2_Resize", LocalString.EquipEnhance_TransferEquip)
	listItem:SetText("UILabel_Line1_2", format(LocalString.EquipEnhance_AnnealAndPerfuseLevel, equip:GetAnnealLevel(), equip:GetPerfuseLevel()))

    -- 设置左边itembox中的信息
    listItem:SetIconTexture(equip:GetTextureName())
	if equip:GetAnnealLevel() ~= 0 then
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(true)
		listItem:SetText("UILabel_AnnealLevel", "+" .. equip:GetAnnealLevel())
	else 
		listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(false)
		listItem:SetText("UILabel_AnnealLevel", "")
	end
    -- 设置绑定类型
    listItem.Controls["UISprite_Binding"].gameObject:SetActive(equip:IsBound())
    -- 设置品质
    listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
    listItem.Controls["UISprite_Quality"].spriteName = "Sprite_ItemQuality"
    listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(equip:GetQuality())
	-- 是否已经装备
	listItem.Controls["UILabel_EquipStatus"].gameObject:SetActive(equip.BagType == cfg.bag.BagType.EQUIP_BODY)
end

local function RankListItemRefresh(listItem, wrapIndex, realIndex)
    local ep = g_Equips[realIndex]
    SetEquipListItem(listItem, ep)
    EventHelper.SetClick(listItem, function()
        local DlgDialogBox_ItemList = require("ui.common.dlgdialogbox_itemlist")
        if g_DlgType == DlgDialogBox_ItemList.DlgType.TransferredEquips then
			if UIManager.isshow("playerrole.equip.tabequiptransfer") then 
				UIManager.call("playerrole.equip.tabequiptransfer", "AddTransEquip", { equip = ep })
			end
        elseif g_DlgType == DlgDialogBox_ItemList.DlgType.AccEnhance then
			if UIManager.isshow("playerrole.equip.tabaccessorywashandtrans") then
				UIManager.call("playerrole.equip.tabaccessorywashandtrans", "AddExtraAcc", { equip = ep })
			end
		elseif g_DlgType == DlgDialogBox_ItemList.DlgType.UpgradedProp1 then
			if UIManager.isshow("playerrole.equip.tabequipupgrade") then 
				UIManager.call("playerrole.equip.tabequipupgrade", "AddUpgradeProp1", { equip1 = ep })
			end
		elseif g_DlgType == DlgDialogBox_ItemList.DlgType.UpgradedProp2 then
			if UIManager.isshow("playerrole.equip.tabequipupgrade") then 
				UIManager.call("playerrole.equip.tabequipupgrade", "AddUpgradeProp2", { equip2 = ep })
			end
        end
		-- 选择后隐藏界面
		UIManager.hide(name)
    end )
end

local function RefreshRanklist()
    local wrapList = fields.UIList_ItemShow.gameObject:GetComponent("UIWrapContentList")
    EventHelper.SetWrapListRefresh(wrapList, RankListItemRefresh)
    wrapList:SetDataCount(getn(g_Equips))
    wrapList:CenterOnIndex(0)
end

local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    fields.UIScrollView_ItemShow.gameObject:SetActive(true)
    fields.UIScrollView_Reward.gameObject:SetActive(false)
	fields.UILabel_Title.text = LocalString.Enhance_EquipList_Title
    if params then
        g_DlgType = params.type
        g_Equips = params.equips
        RefreshRanklist()
    end
end

local function hide()
    -- print(name, "hide")
end

local function refresh(params)
    -- print(name, "refresh")
end

local function update()
    -- print(name, "update")
end

local function init(Name, GameObject, Fields)
    name, gameObject, fields = Name, GameObject, Fields

end

return {
    init    = init,
    show    = show,
    hide    = hide,
    update  = update,
    destroy = destroy,
    refresh = refresh,
}
