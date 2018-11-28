local UIManager         = require("uimanager")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local ColorUtil         = require("common.colorutil")
local ItemManager       = require("item.itemmanager")
local EventHelper       = UIEventListenerHelper
local Format            = string.format

local PageTalismanSkill = {}

function PageTalismanSkill:SetSkillItem(uiItem, talisman, skill)

    local canLvUp = skill:CanLevelUp(talisman:GetNormalLevel())
    local isCurrencyEnough = skill:IsCurrencyEnough(PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi),
                                                    PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua))

    uiItem:SetText("UILabel_SkillName",skill:GetSkillName())
    uiItem:SetText("UILabel_LevelCount",skill:GetLevel())
    
    local cost1, cost2, reqlv = skill:GetCurrencyCost()
    if isCurrencyEnough == true then
        uiItem:SetText("UILabel_Amount01", ColorUtil.GetColorStr(ColorUtil.ColorType.White, tostring(cost1)))
    else
        uiItem:SetText("UILabel_Amount01", ColorUtil.GetColorStr(ColorUtil.ColorType.Red_Item, tostring(cost1)))
    end

    uiItem:SetText("UILabel_SkillDiscription",skill:GetSkillDescription())
    
    local upButton = uiItem.Controls["UIButton_Update"]

    if skill:GetLevel() < reqlv then 
        EventHelper.SetClick(upButton, function()
            UIManager.ShowSystemFlyText(string.format(LocalString.Talisman.SkillLevelUpReqLv[1],reqlv))
        end)
    end

    local spriteWarning = uiItem.Controls["UISprite_UpdateWarning"]
    if upButton then
        if canLvUp then
            upButton.isEnabled = true
			uiItem.Controls["UILabel_Button"].gameObject:SetActive(true)
			uiItem.Controls["UILabel_NextLevelUp"].gameObject:SetActive(false)
            if isCurrencyEnough == true then
                if spriteWarning then
                    spriteWarning.gameObject:SetActive(true)
                end
                EventHelper.SetClick(upButton, function()
                    TalismanManager.UpgradeSkill(talisman,skill:GetConfigId())
                end)
            else
                if spriteWarning then
                    spriteWarning.gameObject:SetActive(false)
                end
                EventHelper.SetClick(upButton, function()
                    ItemManager.GetSource(cfg.currency.CurrencyType.XuNiBi, "playerrole.dlgplayerrole")
                end)
            end
        else
            if spriteWarning then
                spriteWarning.gameObject:SetActive(false)
            end
            upButton.isEnabled = false
			uiItem.Controls["UILabel_Button"].gameObject:SetActive(false)
			uiItem.Controls["UILabel_NextLevelUp"].gameObject:SetActive(true)
			--设置下一级等级的text
			uiItem:SetText("UILabel_NextLevelUp",Format(LocalString.Talisman["TalismanSkillUpLevel"],reqlv))
        end
    end
    --UIGroup_EffectLevelUp
end

function PageTalismanSkill:OnMsgUpdateSkill(talisman, skillId)
    local skills = talisman:GetSkills()
    local skillNum = #skills
    for i = 1, skillNum do
        if skillId == skills[i]:GetConfigId() then
            local uiItem = self.fields.UIList_Skill:GetItemByIndex(i-1)
            if uiItem and uiItem.Controls["UIGroup_EffectLevelUp"] then
                local uigroupEffect = uiItem.Controls["UIGroup_EffectLevelUp"]
                TalismanUITools.PlayEffect(uigroupEffect.gameObject)
            end
        end
    end
end

function PageTalismanSkill:refresh(talisman)
    local skills = talisman:GetSkills()
    local skillNum = #skills
    
    UIHelper.ResetItemNumberOfUIList(self.fields.UIList_Skill,skillNum)
    for i = 1, skillNum do
        local uiItem = self.fields.UIList_Skill:GetItemByIndex(i-1)
        local talismanSkill = skills[i]
        self:SetSkillItem(uiItem, talisman, talismanSkill)
    end
    
    self.fields.UILabel_SkillPageStar.text = TalismanUITools.GetStarOrderText(talisman)
    self.fields.UILabel_SkillPageAwakening.text = TalismanUITools.GetAwakeText(talisman)
end
function PageTalismanSkill:show()
    self.fields.UIGroup_MagicKeySkill.gameObject:SetActive(true)
end

function PageTalismanSkill:hide()
    self.fields.UIGroup_MagicKeySkill.gameObject:SetActive(false)
end

function PageTalismanSkill:update()

end

function PageTalismanSkill:ShowRedDot(talisman)
    local skills = talisman:GetSkills()
    local skillNum = #skills
    for i = 1, skillNum do
        local talismanSkill = skills[i]
        local canLevelUp = talismanSkill:CanLevelUp(talisman:GetNormalLevel())
        local isCurrencyEnough = talismanSkill:IsCurrencyEnough(PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi),
                                                    PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua))
        if canLevelUp and isCurrencyEnough then
            return true
        end
    end
    return false
end

function PageTalismanSkill:init(name, gameObject, fields)
    self.fields = fields
end

return PageTalismanSkill
