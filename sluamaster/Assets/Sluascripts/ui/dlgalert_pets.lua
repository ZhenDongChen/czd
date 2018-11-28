local require        = require
local unpack         = unpack
local print          = print
local format         = string.format
local UIManager      = require("uimanager")
local network        = require("network")
local ItemEnum       = require("item.itemenum")
local EventHelper    = UIEventListenerHelper
local WelfareManager = require("ui.welfare.welfaremanager")
local ItemManager    = require("item.itemmanager")
local PetManager     = require("character.pet.petmanager")

local gameObject
local name
local fields

-- 全局变量

local g_Pets = { }

local function SetPetListItem(listItem, pet)
	-- 设置公用Label显隐
	listItem.Controls["UILabel_Line1"].gameObject:SetActive(true)
	listItem.Controls["UILabel_Line2"].gameObject:SetActive(false)
	-- 设置右边具体信息
	
	local uiLabel = listItem.Controls["UILabel_Line1"]
	colorutil.SetQualityColorText(uiLabel,pet:GetQuality(),pet:GetName())
	-- 设置左边itembox中的信息
	listItem:SetIconTexture(pet:GetTextureName())
	-- 设置品质
	listItem.Controls["UISprite_Quality"].gameObject:SetActive(true)
	listItem.Controls["UISprite_Quality"].spriteName = "Sprite_ItemQuality"
	listItem.Controls["UISprite_Quality"].color = colorutil.GetQualityColor(pet:GetQuality())

    -- 绑定类型
	listItem.Controls["UISprite_Binding"].gameObject:SetActive(pet:IsBound())
end

local function PetListItemRefresh(listItem, wrapIndex, realIndex)
	local selectedPet = g_Pets[realIndex]
	SetPetListItem(listItem, selectedPet)
    local button = listItem.Controls["UIButton_Reward"]
    listItem:SetText("UILabel_Button_Reward",LocalString.Welfare_WishingTree_ButtonText_PutIn)
	EventHelper.SetClick(button, function()
        local wishData = WelfareManager.GetWishData()
        wishData.SelectedPet = selectedPet
		UIManager.call("lottery.dlgwishingtree", "ShowWishPage")
        UIManager.hide("common.dlgdialogbox_itemlist")
	end )
end

local function RefreshPetlist()
    g_Pets = { }
    local pets = PetManager.GetSortedAttainedPets()

    for _,pet in pairs(pets) do
        g_Pets[#g_Pets + 1] = pet
    end

	local wrapList = fields.UIList_Reward.gameObject:GetComponent("UIWrapContentList")
	EventHelper.SetWrapListRefresh(wrapList, PetListItemRefresh)
	wrapList:SetDataCount(#g_Pets)
	wrapList:CenterOnIndex(0)
end

local function destroy()
	-- print(name, "destroy")
end

local function show(params)
	-- print(name, "show")
    fields.UIScrollView_ItemShow.gameObject:SetActive(false)
    fields.UIScrollView_Reward.gameObject:SetActive(true)

	fields.UILabel_Title.text = LocalString.Welfare_WishingTree_PetList_Title
	RefreshPetlist()
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
