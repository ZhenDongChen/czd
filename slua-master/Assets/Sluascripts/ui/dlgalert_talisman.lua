local require = require
local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local TalismanManager = require("ui.playerrole.talisman.talismanmanager")
local ConfigManager = require("cfg.configmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local BonusManager = require("item.bonusmanager")
local ItemManager = require("item.itemmanager")
local ColorUtil = require("common.colorutil")

local name
local gameObject
local fields

local function SetInfo(talisman)
    local textOrderStar = TalismanUITools.GetStarOrderText(talisman)
    local textAwake = TalismanUITools.GetAwakeText(talisman)

    local titleText = string.format("%s (%s) (%s)", talisman:GetName(), textOrderStar, textAwake)
  --  fields.UILabel_InfoName.text = 
  --  fields.UILabel_InfoName.color = ColorUtil.GetQualityColor(talisman:GetQuality())
  --  fields.UILabel_InfoName.effectColor = ColorUtil.GetOutlineColor(talisman:GetQuality())
    ColorUtil.SetQualityColorText(fields.UILabel_InfoName, talisman:GetQuality(), titleText)
  --  fields.UITexture_InfoIcon:SetIconTexture(talisman:GetIconPath())
    BonusManager.SetRewardItemShow(fields.UITexture_InfoIcon, fields.UISprite_BoxQuality, talisman)

    fields.UILabel_ItemType.text = LocalString.Talisman.TypeName
    fields.UILabel_Binding.text = LocalString.BindType[talisman.Isbound == true and 1 or 2]

    fields.UILabel_ItemLevel.text = (talisman:GetLevel() .. LocalString.Level)
    fields.UILabel_PowerValue.text = talisman:GetPower()
    fields.UILabel_Discription.text = talisman:GetIntroduction()
end

local function SetButtons(talisman, isShowButton)
    if isShowButton then
        fields.UIButton_Equip.gameObject:SetActive(true)
        fields.UIButton_Intensify.gameObject:SetActive(true)
    else
        fields.UIButton_Equip.gameObject:SetActive(false)
        fields.UIButton_Intensify.gameObject:SetActive(false)
    end

    -- fields.UIButton_Intensify.gameObject:SetActive(false)       --暂时屏蔽强化
    if talisman:CanUse() ~= false then
        fields.UIButton_Equip.isEnabled = true
        EventHelper.SetClick(fields.UIButton_Equip, function()
            TalismanManager.EquipTalisman(talisman)
            UIManager.hide("dlgalert_talisman")
        end)
    else
        fields.UIButton_Equip.isEnabled = false
    end

    if talisman:CanUse() ~= false then
        fields.UIButton_Intensify.isEnabled = true
        EventHelper.SetClick(fields.UIButton_Intensify, function()
            UIManager.hide("dlgalert_talisman")
            UIManager.show("playerrole.talisman.dlgtalisman_advanced",{talisman = talisman})
        end)
    else
        fields.UIButton_Intensify.isEnabled = false
    end
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide("dlgalert_talisman",{talisman = talisman})
    end)
end
--====================================================================

local function destroy()

end

local function show(params)

end

local function hide()

end

local function refresh(params)
    local talisman = params.item
    local isShowButton
    if params.showButton == nil then
        isShowButton = true
    else
        isShowButton = false
    end
    SetInfo(talisman)
    TalismanUITools.SetSkills(fields.UIList_Skill,talisman,"UITexture_Skill","UISprite_SkillBG","UILabel_SkillName","UILabel_SkillLevel")
    TalismanUITools.SetBaiscAttribute(fields.UIList_Attribute,talisman:GetMainProperty(),"UILabel_AttributeName","UILabel_Attribute")
    TalismanUITools.SetAwakeInfo(fields.UIList_Awakening, talisman)
    fields.UIList_Awakening:Reposition()
    SetButtons(talisman,isShowButton)
end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)
    gameObject.transform.localPosition = Vector3(0,0,-1000)
end

return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}
