local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local bonusmanager 	  = require "item.bonusmanager"
local ItemEnum = require"item.itemenum"
local ItemManager = require("item.itemmanager")
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local ItemIntroduct=require"item.itemintroduction"

local function ShowCurrency(item, labelGold, labelDiamond, labelBindDiamond)
    --printyellow("[dlgtaxbonus:ShowCurrency] Show Currency!")
    if nil==item or item:GetDetailType()~=ItemEnum.ItemType.Currency then
        print("[dlgtaxbonus:ShowCurrency] item nil or item:GetDetailType()~=ItemEnum.ItemType.Currency, return!")
        return
    else
        --printyellow("[dlgtaxbonus:ShowCurrency] type(item):", type(item))
        --printyellow("[dlgtaxbonus:ShowCurrency] item:GetDetailType2():", item:GetDetailType2())
        --printyellow("[dlgtaxbonus:ShowCurrency] item:GetCurrencyType():", item:GetCurrencyType())
    end
    
    if cfg.currency.CurrencyType.XuNiBi == item:GetCurrencyType() then
        labelGold.text = item:GetNumber()
    elseif cfg.currency.CurrencyType.YuanBao == item:GetCurrencyType() then
        labelDiamond.text = item:GetNumber()
    elseif cfg.currency.CurrencyType.BindYuanBao == item:GetCurrencyType() then
        labelBindDiamond.text = item:GetNumber()
    end
end

local function ShowItem(item, awardList)
    --printyellow("[dlgtaxbonus:ShowItem] Show Item!")
    if item then
        local listitem = awardList:AddListItem()
        --data
        listitem.Data = item

        --icon
        listitem:SetIconTexture(item:GetIconPath())

        --name
        local labelName = listitem.Controls["UILabel_ItemName"]
        if labelName then
            --labelName.text = item:GetName()
            colorutil.SetQualityColorText(labelName, item:GetQuality(), item:GetName())
        end

        --count
        local labelNum = listitem.Controls["UILabel_Amount"]
        if labelNum then
            labelNum.gameObject:SetActive(true)
            labelNum.text = item:GetNumber()
        end

        --quality
        local spriteQuality = listitem.Controls["UISprite_Quality"]
        if spriteQuality then
            spriteQuality.color = colorutil.GetQualityColor(item:GetQuality())
        end

        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(item:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end
    end
end

local function OnUIListItemClicked(listitem)
    if listitem and listitem.Data then
        --printyellow(string.format("[tabcitywaraward:OnUIListItemClicked] [%s] clicked!", listitem.gameObject.name))
        local params={item=listitem.Data, buttons={{display=false,text="",callFunc=nil}, {display=false,text="",callFunc=nil}}}
        ItemIntroduct.DisplayBriefItem(params) 
    end
end

local function ShowBonus(bonus, taxBonusListItem)
    -- printyellow("[dlgtaxbonus:ShowBonus] Show Rewards!")

    if bonus and taxBonusListItem then
        local awardList = taxBonusListItem.Controls["UIList_Rewards"]
        if awardList == nil then
            -- printyellow("[dlgtaxbonus:ShowBonus] awardList null!")
            return
        end
        EventHelper.SetListClick(awardList, OnUIListItemClicked)

        local labelGold = taxBonusListItem.Controls["UILabel_Gold"]
        if labelGold then
            print("[ERROR][dlgtaxbonus:ShowBonus] UILabel_Gold nil!")
        else
            labelGold.text = 0
        end
        local labelDiamond = taxBonusListItem.Controls["UILabel_Diamond"]
        if labelDiamond == nil then
            print("[ERROR][dlgtaxbonus:ShowBonus] UILabel_Diamond nil!")
        else
            labelDiamond.text = 0
        end
        local labelBindDiamond = taxBonusListItem.Controls["UILabel_BindingDiamond"]
        if labelBindDiamond == nil then
            print("[ERROR][dlgtaxbonus:ShowBonus] UILabel_BindingDiamond nil!")
        else
            labelBindDiamond.text = 0
        end

        local items = bonusmanager.GetItemsOfSingleBonus(bonus)
        if items and #items>0 then
            for i=1, #items do
                local item = items[i]
                if item:GetDetailType() == ItemEnum.ItemType.Currency and cfg.currency.CurrencyType.LingJing~=item:GetCurrencyType() then
                    ShowCurrency(item, labelGold, labelDiamond, labelBindDiamond)
                else
                    ShowItem(item, awardList)
                end
            end
        end
    end
end

local function ShowScoreBonus(scorebonus, taxBonusListItem, lowerscore)
    -- printyellow("[dlgtaxbonus:ShowScoreBonus] Show rank ", scorebonus.rank)
    if scorebonus and taxBonusListItem then
        --set title
        local titleLabel = taxBonusListItem.Controls["UILabel_Line1"]
        if titleLabel then
            local title = string.format(LocalString.City_War_Tax_Bonus_Interval, lowerscore, scorebonus.upperboundscore)
            titleLabel.text = title
        end

        --show rank award
        if scorebonus.bonus then
            ShowBonus(scorebonus.bonus, taxBonusListItem)
        end
    end
end

local function ShowAllScoreBonus(fields)
    fields.UILabel_Title.text = LocalString.City_War_Tax_Bonus_Title

    local alltaxbonus = citywarinfo.GetAllTaxBonus()
    if alltaxbonus then
        local lowerscore = 1
        local taxBonusListItem
        for _,scorebonus in ipairs(alltaxbonus) do
            taxBonusListItem = fields.UIList_RewardGroups:AddListItem()
            ShowScoreBonus(scorebonus, taxBonusListItem, lowerscore)
            lowerscore = scorebonus.upperboundscore and (scorebonus.upperboundscore+1) or 1
        end
    else
        -- printyellow("[dlgtaxbonus:ShowAllScoreBonus] citywarinfo.GetAllTaxBonus() nil!")
    end    
end

local function ShowCityScore(fields)
    local citylevelcfg = citywarinfo.GetCityLevelCfg(cfg.family.citywar.CityLevelType.SENIOR)
    local seniorcityscore = citylevelcfg and citylevelcfg.score or 0
    
    citylevelcfg = citywarinfo.GetCityLevelCfg(cfg.family.citywar.CityLevelType.MEDIUM)
    local mediumcityscore = citylevelcfg and citylevelcfg.score or 0
    
    citylevelcfg = citywarinfo.GetCityLevelCfg(cfg.family.citywar.CityLevelType.PRIMARY)
    local primarycityscore = citylevelcfg and citylevelcfg.score or 0
    
    --printyellow("[dlgtaxbonus:ShowCityScore] fields.UILabel_City:", fields.UILabel_City)
    --printyellow("[dlgtaxbonus:ShowCityScore] seniorcityscore, mediumcityscore, primarycityscore:", seniorcityscore, mediumcityscore, primarycityscore)
    fields.UILabel_City.gameObject:SetActive(true)
    fields.UILabel_City.text = string.format(LocalString.City_War_Tax_Bonus_Score, seniorcityscore, mediumcityscore, primarycityscore)
end

local function ShowAllTaxBonus(params,fields)
    -- printyellow("[dlgtaxbonus:ShowAllTaxBonus] dlgdialogbox_reward show callback!")
    ShowCityScore(fields)
    ShowAllScoreBonus(fields)    
end

local function show()
    UIManager.show("common.dlgdialogbox_reward", {type = 0, callBackFunc = ShowAllTaxBonus})
end

return{
    show = show,
}
