local BagManager        = require("character.bagmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local BonusManager      = require("item.bonusmanager")
local ItemManager       = require("item.itemmanager")
local ColorUtil         = require("common.colorutil")
local UIManager         =require"uimanager"

local EventHelper = UIEventListenerHelper

local PageTalismanAwake = {
}

function PageTalismanAwake:CanAdd(talisman, item)
    return TalismanManager.CanAddAwake(talisman, item)
end

function PageTalismanAwake:BasicInfo(talisman)
    BonusManager.SetRewardItemShow(self.fields.UITexture_AwakeIcon, self.fields.UISprite_AwakeBoxQuality, talisman)
    self.fields.UILabel_AwakePageAwakening.text = string.format(LocalString.Talisman.Top.Awake,talisman:GetAwakeLevel())
    TalismanUITools.SetBaiscAttribute(self.fields.UIList_Properties02,talisman:GetMainProperty(),"UILabel_Properties","UILabel_Amount")
end
function PageTalismanAwake:AwakeInfo(talisman)
    TalismanUITools.SetAwakeInfo(self.fields.UIList_Props,talisman)
end

function PageTalismanAwake:GetConsumeItemsInBag(talisman)
    local items = BagManager.GetItemById(talisman:GetConfigId())
    local pos = -1
    local newList = {}
    for i, item in pairs(items) do
        if item:GetId() ~= talisman:GetId() and self:CanAdd(talisman, item) then
            table.insert( newList, item )
        end
    end
    return newList
end

function PageTalismanAwake:AwakeConsumeItem(talisman)
    local newList = self:GetConsumeItemsInBag(talisman)

    local totalNum = #newList
    local consumeNum = talisman:GetAwakeItemCost()
    
    local uiItem = self.fields.UIList_AwakeConsume:GetItemByIndex(0)

    uiItem:SetText("UILabel_AwakeningName",talisman:GetName())
    
    local amountText
    local amountStr = string.format("%s/%s", totalNum, consumeNum)
    if consumeNum > totalNum then
        amountText = ColorUtil.GetColorStr(ColorUtil.ColorType.Red_Item, amountStr) 
    else
        amountText = ColorUtil.GetColorStr(ColorUtil.ColorType.Green, amountStr) 
    end

    uiItem:SetText("UILabel_AwakeAmount", amountText)
    BonusManager.SetRewardItem(uiItem,talisman,{notSetClick=true,notShowAmount=true})

    EventHelper.SetClick(self.fields.UIButton_Awakening, function()
        local maxLevel = #talisman:GetAwakeInfo()
        local awakeLv =  talisman:GetAwakeLevel()
        if awakeLv >= maxLevel then 
            return  UIManager.ShowSystemFlyText(LocalString.Talisman.TalismanAwakenMax)
        end
        TalismanManager.TalismanAwake(talisman)
    end)
    
    local addButton = uiItem.Controls["UIButton_AwakeAdd"]
    EventHelper.SetClick(addButton, function()
        ItemManager.GetSource(talisman:GetConfigId(),self.name)
    end)
end


function PageTalismanAwake:refresh(talisman)
    self:BasicInfo(talisman)
    self:AwakeInfo(talisman)
    self:AwakeConsumeItem(talisman)
end

function PageTalismanAwake:show()
    self.fields.UIGroup_Awakening.gameObject:SetActive(true)
end

function PageTalismanAwake:OnMsgAwake(params)
    local awakeLevel = params.awakeLevel
    if awakeLevel and awakeLevel >= 1 then
        local uiItem = self.fields.UIList_Props:GetItemByIndex(awakeLevel-1)
        if uiItem then
            TalismanUITools.PlayEffect(self.fields.UIGroup_Awake.gameObject, uiItem.gameObject.transform.position)
            TalismanUITools.PlayEffect(self.fields.UIGroup_AwakeConsume.gameObject)
        end
    end
    
end

function PageTalismanAwake:hide()
    self.fields.UIGroup_Awakening.gameObject:SetActive(false)
    TalismanUITools.StopEffect(self.fields.UIGroup_AwakeConsume.gameObject)
    TalismanUITools.StopEffect(self.fields.UIGroup_Awake.gameObject)
end

function PageTalismanAwake:init(name, gameObject,fields)
    self.fields = fields
    self.name = name

end

function PageTalismanAwake:ShowRedDot(talisman)
    if talisman == nil then
        return false
    end
    local newList = self:GetConsumeItemsInBag(talisman)
    local totalNum = #newList
    local consumeNum = talisman:GetAwakeItemCost()
    local maxAwakeLevel = talisman:GetMaxAwakeLevel()
    local curAwakeLevel = talisman:GetAwakeLevel()

    if consumeNum <= totalNum then
        if curAwakeLevel < maxAwakeLevel then
            return true
        end
    end
    return false
end



return PageTalismanAwake
