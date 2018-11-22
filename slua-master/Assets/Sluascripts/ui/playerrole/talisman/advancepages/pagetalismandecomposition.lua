local UIManager         = require("uimanager")
local ItemIntroduction  = require("item.itemintroduction")
local EventHelper       = UIEventListenerHelper
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local ItemManager       = require("item.itemmanager")
local BonusManager      = require("item.bonusmanager")

local PageTalismanDecomposition = {
 --   effect = {},
}

function PageTalismanDecomposition:SetLeft(talisman)
    BonusManager.SetRewardItemShow(self.fields.UITexture_TargetIcon, self.fields.UISprite_DecomBoxQuality, talisman)
   -- self.fields.UITexture_TargetIcon:SetIconTexture(talisman:GetIconPath())
    self.fields.UILabel_TargetName.text     = talisman:GetName()
    self.fields.UILabel_TargetLv.text       = talisman:GetLevel()--TalismanUITools.GetLevelText(talisman:GetLevel())
    self.fields.UILabel_TargetQuality1.text = TalismanUITools.GetStarOrderText(talisman)
    self.fields.UILabel_TargetQuality2.text = TalismanUITools.GetAwakeText(talisman)

    EventHelper.SetClick(self.fields.UIButton_DecompositionYES, function()
        TalismanManager.TalismanRecycle(talisman)
		self.fields.UIButton_DecompositionYES.isEnabled = false
    end)
    --EventHelper.SetClick(self.fields.UIButton_DecompositionNO, function()
    --    UIManager.hide("playerrole.talisman.dlgtalisman_advanced")
    --end)
end

function PageTalismanDecomposition:SetRight(talisman)
    local items = {}
    for j = 1,#talisman:GetRecycleAllItem() do
        local talismanItem = talisman:GetRecycleAllItem()[j]
        local num = talismanItem.Number
        if num ~= 0 then 
            table.insert(items,talismanItem)
        end
    end
    
    UIHelper.ResetItemNumberOfUIList(self.fields.UIList_Outcome,#items)
    for i =1, #items do
        local uiItem = self.fields.UIList_Outcome:GetItemByIndex(i-1)
        local item = items[i]
        local texture = uiItem.Controls["UITexture_OutcomeIcon"]
        local spriteQulity = uiItem.Controls["UISprite_BoxQuality"]

        BonusManager.SetRewardItemShow(texture, spriteQulity, item)
        local textInfo = item:GetName() .. "  X" .. item:GetNumber()
                
        uiItem:SetText("UILabel_OutcomeDes",textInfo)
        local sprite = uiItem.Controls["UISprite_OutcomeSlots"]
        
        EventHelper.SetClick(sprite, function()
            ItemIntroduction.DisplayItem({item = item})
        end)
    end
end

function PageTalismanDecomposition:refresh(talisman)
    self:SetLeft(talisman)
    self:SetRight(talisman)
end

function PageTalismanDecomposition:show()
    self.fields.UIGroup_Decomposition.gameObject:SetActive(true)
end

function PageTalismanDecomposition:hide()
    self.fields.UIGroup_Decomposition.gameObject:SetActive(false)
    TalismanUITools.StopEffect(self.fields.UIGroup_DecomEffect.gameObject)
end

function PageTalismanDecomposition:OnMsgDecom(params)
    --self.fields.UIGroup_Decomposition.gameObject:SetActive(true)
    TalismanUITools.PlayEffect(self.fields.UIGroup_DecomEffect.gameObject)
end

function PageTalismanDecomposition:init(name, gameObject, fields)
    self.fields = fields
end


return PageTalismanDecomposition
