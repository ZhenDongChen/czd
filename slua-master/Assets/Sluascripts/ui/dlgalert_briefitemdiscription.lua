local require       = require
local unpack        = unpack
local print         = print
local format        = string.format
local UIManager     = require("uimanager")
local network       = require("network")
local ItemManager   = require("item.itemmanager")
local ItemEnum      = require("item.itemenum")
local EventHelper   = UIEventListenerHelper

local gameObject
local name
local fields


local function ShowItemInfo(item)
	local quality    = item:GetQuality()
	local baseType   = item:GetBaseType()
    local detailType = item:GetDetailType()
	local itemName   = item:GetName()

    fields.UISprite_GemstoneType1.gameObject:SetActive(false)
    fields.UISprite_GemstoneType2.gameObject:SetActive(false)
    fields.UISprite_ItemProfessionBG.gameObject:SetActive(true)

    if baseType == ItemEnum.ItemBaseType.Item then
        if detailType == ItemEnum.ItemType.Gemstone then
            fields.UISprite_ItemProfessionBG.gameObject:SetActive(false)
            fields.UISprite_GemstoneType1.gameObject:SetActive(true)
            fields.UISprite_GemstoneType2.gameObject:SetActive(true)
            fields.UILabel_GemstoneType1.text = LocalString.Gemstone_Type1[item:GetGemstoneType1()]
            fields.UILabel_GemstoneType2.text = LocalString.Gemstone_Type2[item:GetGemstoneType2()]
		end
		fields.UILabel_ItemLevel.text = item:GetLevel() .. LocalString.Level
	elseif baseType == ItemEnum.ItemBaseType.Fragment then
		-- 碎片
		itemName = format("%s(%s)",itemName,LocalString.FragType) 
		fields.UILabel_ItemLevel.text = item:GetLevel() .. LocalString.Level
	elseif baseType == ItemEnum.ItemBaseType.Equipment then
		itemName = format(LocalString.BagAlert_EquipName, item:GetName(), item:GetAnnealLevel(), item:GetPerfuseLevel()) 
		fields.UILabel_ItemLevel.text = item:GetLevel() .. LocalString.Level
	elseif baseType == ItemEnum.ItemBaseType.Talisman then 
		-- 法宝
		fields.UILabel_ItemLevel.text = item:GetNormalLevel() .. LocalString.Level 
	elseif baseType == ItemEnum.ItemBaseType.Pet then 
		-- 伙伴
		fields.UILabel_ItemLevel.text = item:GetPetLevel() .. LocalString.Level 
	else
		fields.UILabel_ItemLevel.text = item:GetLevel() .. LocalString.Level
	end
	-- 图标
	fields.UITexture_Item_Icon:SetIconTexture(item:GetTextureName())
	-- 是否为碎片
	fields.UISprite_Fragment.gameObject:SetActive(baseType == ItemEnum.ItemBaseType.Fragment)
	-- 是否绑定
	fields.UILabel_Item_Binding.gameObject:SetActive(item:IsBound())
	fields.UISprite_Item_Binding.gameObject:SetActive(item:IsBound())
	-- 品质
	fields.UISprite_Item_Quality.spriteName = colorutil.GetQualitySprite(quality)
	-- 类型名
	fields.UILabel_ItemType.text = item:GetDetailTypeName()
	-- 名字
	fields.UILabel_ItemName.text = colorutil.GetQualityColorText(quality,itemName)
	-- 描述
	fields.UILabel_Item_Description.text = item:GetIntroduction()
	-- 职业
	fields.UILabel_ItemProfession.text = item:GetProfessionLimitName()

end

local function SetButton(button)
    if (not button) or (not button.display) then
        fields.UIButton_Common.gameObject:SetActive(false)
    else
        fields.UIButton_Common.gameObject:SetActive(true)
        fields.UILabel_CommonBtn_Desc.text = button.text
        EventHelper.SetClick(fields.UIButton_Common,function()
            button.callFunc()
            UIManager.hide(name)
        end)
    end
end

local function destroy()
	--print(name, "destroy")
end

local function show(params)
	print(name, "show")
	ShowItemInfo(params.item)
    SetButton(params.button)
end

local function hide()
	--print(name, "hide")
end

local function refresh(params)
	--print(name, "refresh")
end

local function update()
	--print(name, "update")
end

local function init(params)
  name, gameObject, fields = unpack(params)

  EventHelper.SetClick(fields.UIGroup_Container_Block,function()
	UIManager.hide(name)
  end)
  EventHelper.SetClick(fields.UIButton_Close,function()
	UIManager.hide(name)
  end)
end

return {
  init    = init,
  show    = show,
  hide    = hide,
  update  = update,
  destroy = destroy,
  refresh = refresh,
}

