local unpack, print, math   = unpack, print, math
local EventHelper           = UIEventListenerHelper
local TalismanManager       = require("ui.playerrole.talisman.talismanmanager")
local UIManager             = require("uimanager")

local name, gameObject, fields

local function destroy()
end

local function refresh(params)

    if not (params and params.skill and params.talisman) then
        return
    end
    local talisman = params.talisman
    local skill = params.skill
    fields.UILabel_Button.text = LocalString.Talisman.SkillLevelUp[1]
    --[[
            fields.UITexture_Skill01:SetIconTexture(skill:GetSkillIcon())
    fields.UILabel_SkillName01.text = skill:GetSkillName()
    fields.UILabel_Discription.text = skill:GetSkillDescription()
    fields.UILabel_Discription01.text = skill:GetSkillDetailDesc()
    fields.UILabel_Level.text = skillLevel
    ]]
    local cost1,cost2 ,reqlv = skill:GetCurrencyCost()
    
    local canLvUp = skill:CanLevelUp(talisman:GetNormalLevel(),
                PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi),
                PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ZaoHua))
    
    fields.UILabel_Resource.text = tostring(cost1) .. "/" .. tostring(PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.XuNiBi))
    fields.UITexture_Skill:SetIconTexture(skill:GetSkillIcon())
    fields.UILabel_SkillName.text = skill:GetSkillName()
    fields.UILabel_Discription.text = skill:GetSkillDescription()
    
    fields.UILabel_Level01.text = skill:GetLevel()
    fields.UILabel_Level02.text = skill:GetNextLevel()
    
    fields.UILabel_Discription01.text = skill:GetLevelDescription()
    fields.UILabel_Discription02.text = skill:GetLevelDescription(skill:GetNextLevel())
    if not canLvUp then
        fields.UIButton_LevelUpgrade.isEnabled = false
    else
        fields.UIButton_LevelUpgrade.isEnabled = true
        EventHelper.SetClick(fields.UIButton_LevelUpgrade, function()
            TalismanManager.UpgradeSkill(talisman,skill:GetConfigId())
        end)
    end
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide(name)
    end)
end

local function show(params)
    fields.UIGroup_Button_1.gameObject:SetActive(true)
    fields.UIGroup_Resource.gameObject:SetActive(true)
    fields.UIGroup_Skill.gameObject:SetActive(true)
    fields.UIGroup_SkillCheck.gameObject:SetActive(false)
    fields.UIGroup_SkillUpdate.gameObject:SetActive(true)
    fields.UIGroup_SkillEquip.gameObject:SetActive(false)
end

local function hide()
    
end

local function update()

end

local function init(params)
    name, gameObject, fields = unpack(params)

end



return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
