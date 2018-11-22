local UIManager         = require("uimanager")
local EventHelper       = UIEventListenerHelper
local TalismanManager   = require("ui.playerrole.talisman.talismanmanager")
local BagManager        = require("character.bagmanager")
local ItemEnum          = require("item.itemenum")
local ConfigManager     = require("cfg.configmanager")
local TalismanUITools   = require("ui.playerrole.talisman.talismanuitool")
local BonusManager      = require("item.bonusmanager")

local PageTalismanStar  = {
}
local m_StarNum = 9

local function IsSelected(item)
    for i,talisman in pairs(TalismanManager.TalismanSystemConfig.ConsumeTalismans) do
        if talisman.BagPos == item.BagPos then
            return true, i
        end
    end
    return false,nil
end

local function CanAutoAdd(talisman, item)
    
     if item:GetQuality() > cfg.item.EItemColor.PURPLE then
        return false
     end
     if TalismanManager.CanAddStarOrder(talisman, item) == false then
        return false
     end
     return true
end

local function TalismanSortFunc(itemA, itemB)
    local qualityA = itemA:GetQuality()
    local qualityB = itemB:GetQuality()
    if qualityA < qualityB then
        return true
    else
        return false
    end
end

function PageTalismanStar:GetAllAvaliableItemsInBag(talisman)
    local items = BagManager.GetItems(cfg.bag.BagType.TALISMAN)
    local newList = {}

    for i, item in ipairs(items) do
        if item:GetConfigId() ~= talisman:GetConfigId() and (not isItemSelected) then
            if CanAutoAdd(talisman, item) then
                table.insert(newList,item)
            end
        end
    end
    return newList
end

function PageTalismanStar:AutoAddItems(talisman,num)
    local items = BagManager.GetItems(cfg.bag.BagType.TALISMAN)

    table.sort( items, TalismanSortFunc)
    for i, item in ipairs(items) do
        if #TalismanManager.TalismanSystemConfig.ConsumeTalismans >= num then
            break
        end
        local isItemSelected, pos = IsSelected(item)

        if item:GetConfigId() ~= talisman:GetConfigId() and (not isItemSelected) then
            if CanAutoAdd(talisman, item) then
                table.insert(TalismanManager.TalismanSystemConfig.ConsumeTalismans,item)
            end
        end

    end
    UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
end


function PageTalismanStar:SetAttribute(talisman)
    BonusManager.SetRewardItemShow(self.fields.UITexture_StarMagicKey, self.fields.UISprite_StarBoxQuality, talisman)
    
    self.fields.UILabel_Star01.text = TalismanUITools.GetStarOrderText(talisman)
    TalismanUITools.SetBaiscAttribute(self.fields.UIList_Properties01,talisman:GetMainProperty(),"UILabel_Properties","UILabel_Amount",2)

end

function PageTalismanStar:SetStarInfo(talisman)
    local starLevel = talisman:GetStarLevel()
    local orderLevel = talisman:GetOrderLevel()
    UIHelper.ResetItemNumberOfUIList(self.fields.UIList_Star, m_StarNum )
    for i = 1, m_StarNum do
        local uiItem = self.fields.UIList_Star:GetItemByIndex(i-1)
        local spriteStar = uiItem.Controls["UISprite_Star"]       
        if (starLevel > 0) and ((i - 1) <= (starLevel - 1) % m_StarNum) then
            if (starLevel <= m_StarNum) then
                spriteStar.spriteName = "Sprite_Star_Btn"
            else
                spriteStar.spriteName = "Sprite_Star_Red"
            end
            spriteStar.gameObject:SetActive(true)           
        else
            spriteStar.gameObject:SetActive(false)
        end
    end

    local starExp = talisman:GetStarOrderExp()
    local maxExp = talisman:GetMaxStarExp()
    self.fields.UILabel_StarOrderExp.text = ("" .. tostring(starExp) .. "/" .. tostring(maxExp))
    
    self.fields.UIProgressBar_Star.value =  starExp/maxExp
    self.fields.UILabel_Order.text = tostring(talisman:GetOrderLevel())
end

function PageTalismanStar:SetConsume(talisman)
    local consumeBoxNum = TalismanManager.GetMaxStarOrderConsumeCount()
    UIHelper.ResetItemNumberOfUIList(self.fields.UIList_ConsumeProps,consumeBoxNum)
    for i = 1,consumeBoxNum do
        local uiItem = self.fields.UIList_ConsumeProps:GetItemByIndex(i-1)
        local item = TalismanManager.TalismanSystemConfig.ConsumeTalismans[i]
        --BonusManager.SetRewardItem(uiItem, item, {notSetAmount = true, notSetClick = true})
        
        local button = uiItem.gameObject:GetComponent("UIButton")
        local texture = uiItem.Controls["UITexture_ConsumeItem"]
        local sprite = uiItem.Controls["UISprite_Add"]
        local spriteQulity = uiItem.Controls["UISprite_BoxQuality"]
        
        if item ~= nil then
            spriteQulity.gameObject:SetActive(true)
            BonusManager.SetRewardItemShow(texture, spriteQulity, item)

            sprite.gameObject:SetActive(false)
            EventHelper.SetClick(button, function()
                table.remove(TalismanManager.TalismanSystemConfig.ConsumeTalismans,i)
                UIManager.refresh("playerrole.talisman.dlgtalisman_advanced")
            end)
        else
            spriteQulity.gameObject:SetActive(false)
            texture:SetIconTexture("")
            sprite.gameObject:SetActive(true)
            EventHelper.SetClick(button, function()
                UIManager.show( "playerrole.talisman.dlgtalisman_select",{talisman = talisman})
            end)
        end
    end
end

function PageTalismanStar:SetButtons(talisman)
    --local result = TalismanUITools.SetMoneyCostText(self.fields.UILabel_ConsumeAmount,talisman:GetIntensifyCurrency())
    EventHelper.SetClick(self.fields.UIButton_ConsumeAdd, function()
        self:AutoAddItems(talisman,TalismanManager.GetMaxStarOrderConsumeCount())
    end)
    local isExpFull = talisman:IsStarOrderExpFull()

    local requiredLevel = talisman:GetRequiredPlayerLevel()
    EventHelper.SetClick(self.fields.UIButton_Intensify, function()
       -- if result then
            if isExpFull and requiredLevel > PlayerRole:Instance().m_Level then
                local helpinfo = ConfigManager.getConfigData("talismanhelpinfo","Update/ExpMax")
                UIManager.ShowAlertDlg({ content        = helpinfo.helpinfo,
                                         immediate      = true,
                                         callBackFunc   = function()
                                            TalismanManager.AddStarExp(talisman,TalismanManager.TalismanSystemConfig.ConsumeTalismans)
                                        end})
            else
                if #TalismanManager.TalismanSystemConfig.ConsumeTalismans > 0 then
                    TalismanManager.AddStarExp(talisman,TalismanManager.TalismanSystemConfig.ConsumeTalismans)
                end
            end
     --   else
    --        TalismanUITools.ShowNotMoney()
     --   end
    end)
end

function PageTalismanStar:refresh(talisman)
    self:SetAttribute(talisman)
    self:SetStarInfo(talisman)
    self:SetConsume(talisman)
    self:SetButtons(talisman)
end

function PageTalismanStar:show()
    
    self.fields.UIGroup_Intensify.gameObject:SetActive(true)
end

function PageTalismanStar:hide()
    self.fields.UIGroup_Intensify.gameObject:SetActive(false)
    TalismanUITools.StopEffect(self.fields.UIGroup_Order.gameObject)
    TalismanUITools.StopEffect(self.fields.UIGroup_Star.gameObject)
end

function PageTalismanStar:OnMsgStarOrder(params)
    TalismanUITools.PlayEffect(self.fields.UIGroup_Order.gameObject)
    if params.star and params.star >= 1 then
        local uiItem = self.fields.UIList_Star:GetItemByIndex(params.star-1)
        if uiItem then
            TalismanUITools.PlayEffect(self.fields.UIGroup_Star.gameObject, uiItem.gameObject.transform.position)
        end
    end
end

function PageTalismanStar:init(name, gameObject, fields)
    self.fields = fields
end

function PageTalismanStar:ShowRedDot(talisman)
    if talisman == nil then
        return false
    end
    local items = self:GetAllAvaliableItemsInBag(talisman)
    local starOrderLevel = talisman:GetStarOrderLevel()
    local maxStarOrderLv = talisman:GetMaxStarOrderLevel()
    if #items > 0 then
        if starOrderLevel < maxStarOrderLv then
            local requirePlayerLv = talisman:GetRequiredPlayerLevel(starOrderLevel+1)
            if requirePlayerLv <= PlayerRole:Instance().m_Level then
                return true
            end
        end
    end
    
    return false
end


return PageTalismanStar
