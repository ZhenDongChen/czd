local ConfigManager     = require("cfg.configmanager")
local UIManager         = require("uimanager")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local TalismanHelpInfo  = require("ui.playerrole.talisman.talismanhelpinfo")
local AttributeHelper   = require("attribute.attributehelper")
local EventHelper       = UIEventListenerHelper

local function SetAttr(typeShow, uiItem, basicAttr, labelName, labelValue, type1, type2, iconType)
    local nameStr = tostring(AttributeHelper.GetAttributeName(typeShow)) ..": "
    uiItem:SetText(labelName, nameStr)
    local attrSprite = uiItem.Controls["UISprite_Icon"]
    if attrSprite then
        local SpriteName = AttributeHelper.GetAttributeSpriteName(typeShow)
        if iconType ~= nil then
            SpriteName = SpriteName --去除iconType
        end
        attrSprite.spriteName = SpriteName
    end
    local valueStr = AttributeHelper.GetAttributeValueString(type1, basicAttr[type1])
    if type2 then
        valueStr = tostring(valueStr) .. "-" .. AttributeHelper.GetAttributeValueString(type2, basicAttr[type2])
    end
    uiItem:SetText(labelValue,valueStr)
end


local function SetBaiscAttribute(UIList, basicAttr, labelName, labelValue, iconType)
    
    local basicAttrNum = 0
    for k,v in pairs(basicAttr) do
        basicAttrNum = basicAttrNum + 1
    end

    if basicAttrNum > 0 then 
        basicAttrNum =  basicAttrNum - 1
    end

    UIHelper.ResetItemNumberOfUIList(UIList, basicAttrNum)
    local attrUIItem = {}
    for i = 1, basicAttrNum do
        attrUIItem[i] = UIList:GetItemByIndex(i-1)
    end

    SetAttr(cfg.fight.AttrId.ATTACK_VALUE, attrUIItem[1], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.ATTACK_VALUE_MIN, cfg.fight.AttrId.ATTACK_VALUE_MAX, iconType)

    SetAttr(cfg.fight.AttrId.DEFENCE, attrUIItem[2], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.DEFENCE, nil, iconType)

    SetAttr(cfg.fight.AttrId.HP_FULL_VALUE,     attrUIItem[3], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.HP_FULL_VALUE, nil, iconType)

    SetAttr(cfg.fight.AttrId.MP_FULL_VALUE,     attrUIItem[4], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.MP_FULL_VALUE, nil, iconType)

    SetAttr(cfg.fight.AttrId.HIT_RATE,          attrUIItem[5], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.HIT_RATE, nil, iconType)
            
    SetAttr(cfg.fight.AttrId.HIT_RESIST_RATE,   attrUIItem[6], basicAttr,
            labelName, labelValue, cfg.fight.AttrId.HIT_RESIST_RATE, nil, iconType)
    
end

local function SetAwakeInfo(UIList,talisman)
    local awakeLevel = talisman:GetAwakeLevel()
    local awakeInfos = talisman:GetAwakeInfo()
    local awakeNum = #awakeInfos
    UIHelper.ResetItemNumberOfUIList(UIList,awakeNum)
    for i = 1, awakeNum do
        local uiItem = UIList:GetItemByIndex(i-1)
        local awakeInfo = awakeInfos[i]
        local groupTrue = uiItem.Controls["UIGroup_AwakeningTrue"]
        local groupFalse = uiItem.Controls["UIGroup_AwakeningFalse"]
        if i <= awakeLevel then
            groupTrue.gameObject:SetActive(true)
            groupFalse.gameObject:SetActive(false)
            uiItem:SetText("UILabel_AwakeningTrue",awakeInfo.displaytext)
            uiItem:SetText("UILabel_AwakeningFalse",awakeInfo.displaytext)
        else
            groupTrue.gameObject:SetActive(false)
            groupFalse.gameObject:SetActive(true)
            uiItem:SetText("UILabel_AwakeningTrue",awakeInfo.displaytext)
            uiItem:SetText("UILabel_AwakeningFalse",awakeInfo.displaytext)
        end
    end
end


local function SetSkills(UIList,talisman,iconName,spriteName,labelName,labelLevel, costlabel1, costlabel2)
    local skills = talisman:GetSkills()
    local skillNum = #skills
    UIHelper.ResetItemNumberOfUIList(UIList,skillNum)
    for i = 1, skillNum do
        local uiItem = UIList:GetItemByIndex(i-1)
       -- local texture = uiItem:GetTexture(iconName)

        if costlabel1 and costlabel2 then
            local cost1, cost2, reqlv = skills[i]:GetCurrencyCost()
            if costlabel1 then
                uiItem:SetText("UILabel_Amount01",cost1)
            end
            if costlabel2 then
                uiItem:SetText("UILabel_Amount02",cost2)
            end
            
            local upButton = uiItem.Controls["UIButton_Update"]

            local level = talisman:GetNormalLevel()
            local XuNiBi = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi)
            local ZaoHua = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua)

            local canLvUp = skills[i]:CanLevelUp(talisman:GetNormalLevel(),
                    PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi),
                    PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua))
            if upButton then
                if canLvUp then
                    upButton.isEnabled = true
                    EventHelper.SetClick(upButton, function()
                        local Dlg_Skill = require("ui.common.dlgdialogbox_skill")
                        UIManager.show( "common.dlgdialogbox_skill", 
                                        {   type = Dlg_Skill.DlgType.TalismanSkill,
                                            talisman = talisman,
                                            skill = skills[i] })
                    end)
                else
                    upButton.isEnabled = false
                end
            end
            
        end
        if texture ~= nil then 
            texture:SetIconTexture(skills[i]:GetSkillIcon())
        end
        uiItem:SetText(labelName,skills[i]:GetSkillName())
        uiItem:SetText(labelLevel,skills[i]:GetLevel())
        local uiLabelDesc = uiItem.Controls["UILabel_Discription"]
        if uiLabelDesc then
            uiLabelDesc.text = skills[i]:GetSkillDescription()
        end
     --   local sprite = uiItem:GetSprite(spriteName)
     --   EventHelper.SetClick(sprite, function()
      --      UIManager.show("dlgalert_skill",{skillConfig = skills[i].ConfigData, skillLevel = skills[i]:GetLevel()})
      --  end)
    end
end



local function GetStarOrderText(talisman,starOrderLevel)
    if starOrderLevel ~= nil then
        return string.format(LocalString.Talisman.Top.Star,talisman:GetStarLevel(starOrderLevel),talisman:GetOrderLevel(starOrderLevel))
    else
        return string.format(LocalString.Talisman.Top.Star,talisman:GetStarLevel(),talisman:GetOrderLevel())
    end
end

local function GetAwakeText(talisman)
    return string.format(LocalString.Talisman.Top.Awake,talisman:GetAwakeLevel())
end

local function GetLevelText(level)
    return LocalString.TalismanLevel .. level
end

local function SetMoneyCostText(UIlabel, costMoney)
    local allmoney = TalismanManager.GetCurrency()
    if costMoney <= allmoney then
        UIlabel.text = costMoney .."/" .. allmoney
        return true
    else
        UIlabel.text = "[CC0000]" .. costMoney .."/" .. allmoney .. "[-]"
        return false
    end
end

local function ShowNotMoney()
    --printyellow("Not enough money")
end


local function GetLuckName(luckType)
    return LocalString.Talisman.FortuneType[luckType]
end

local function GetLuckIconName(luckType)
    return LocalString.Talisman.FortuneIcon[luckType]
end

local function GetLuckDescribe(luckType)
    local config = ConfigManager.getConfigData("talismanfeed",luckType)
    
    return config.decribe
end

local function PlayEffect(go, position)
    if position then
        go.transform.position = position
    end
    UIManager.PlayUIParticleSystem(go)
end
  
local function StopEffect(go)
    UIManager.StopUIParticleSystem(go)
end

return {
    SetBaiscAttribute = SetBaiscAttribute,
    SetAdvanceAttribute = SetAdvanceAttribute,
    SetAwakeInfo = SetAwakeInfo,
    SetSkills = SetSkills,
    GetStarOrderText = GetStarOrderText,
    GetAwakeText = GetAwakeText,
    GetLevelText = GetLevelText,
    SetMoneyCostText=SetMoneyCostText,
    ShowNotMoney = ShowNotMoney,
    GetFiveElementName = GetFiveElementName,
    GetFiveElementIconName = GetFiveElementIconName,
    ShowHelpInfo = TalismanHelpInfo.ShowInfo,
    GetLuckName=GetLuckName,
    GetLuckDescribe=GetLuckDescribe,
    PlayEffect = PlayEffect,
    StopEffect = StopEffect,
    GetLuckIconName = GetLuckIconName,
}
