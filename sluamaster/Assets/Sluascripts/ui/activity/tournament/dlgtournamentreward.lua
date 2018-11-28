local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local bonusmanager 	  = require "item.bonusmanager"
local ItemEnum = require"item.itemenum"
local ItemManager = require("item.itemmanager")

local function ShowCurrency(item, labelGold, labelDiamond, labelBindDiamond)
    --printyellow("[dlgtournamentreward:ShowCurrency] Show Currency!")
    if nil==item or item:GetDetailType()~=ItemEnum.ItemType.Currency then
        print("[dlgtournamentreward:ShowCurrency] item nil or item:GetDetailType()~=ItemEnum.ItemType.Currency, return!")
        return
    else
        --printyellow("[dlgtournamentreward:ShowCurrency] type(item):", type(item))
        --printyellow("[dlgtournamentreward:ShowCurrency] item:GetDetailType2():", item:GetDetailType2())
        --printyellow("[dlgtournamentreward:ShowCurrency] item:GetCurrencyType():", item:GetCurrencyType())
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
    --printyellow("[dlgtournamentreward:ShowItem] Show Item!")
    if item then
        local listitem = awardList:AddListItem()

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
            spriteQuality.spriteName = colorutil.GetQualitySprite(item:GetQuality())
        end

        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(item:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end
    end
end

local function ShowAwards(multiBonus, rankAwardListItem)
    -- printyellow("[dlgtournamentreward:ShowAwards] Show Rewards!")

    if multiBonus and rankAwardListItem then
        local awardList = rankAwardListItem.Controls["UIList_Rewards"]
        if awardList == nil then
            -- printyellow("[dlgtournamentreward:ShowAwards] awardList null!")
            return
        end
        local labelGold = rankAwardListItem.Controls["UILabel_Gold"]
        if labelGold == nil then
            -- printyellow("[dlgtournamentreward:ShowAwards] labelGold null!")
            return
        else
            labelGold.text = 0
        end
        local labelDiamond = rankAwardListItem.Controls["UILabel_Diamond"]
        if labelDiamond == nil then
            -- printyellow("[dlgtournamentreward:ShowAwards] labelDiamond null!")
            return
        else
            labelDiamond.text = 0
        end
        local labelBindDiamond = rankAwardListItem.Controls["UILabel_BindingDiamond"]
        if labelBindDiamond == nil then
            -- printyellow("[dlgtournamentreward:ShowAwards] labelBindDiamond null!")
            return
        else
            labelBindDiamond.text = 0
        end

        local items = bonusmanager.GetItemsOfSingleBonus(multiBonus)
        if items and #items>0 then
            for i=1, #items do
                local item = items[i]
                if item:GetDetailType() == ItemEnum.ItemType.Currency then
                    ShowCurrency(item, labelGold, labelDiamond, labelBindDiamond)
                else
                    ShowItem(item, awardList)
                end
            end
        end
    end
end

local function ShowRankAward(rankAward, rankAwardListItem)
    -- printyellow("[dlgtournamentreward:ShowRankAward] Show rank ", rankAward.rank)
    if rankAward and rankAwardListItem then
        --set title
        local titleLabel = rankAwardListItem.Controls["UILabel_Line1"]
        if titleLabel then
            local title = LocalString.Tournament_Reward_Rank[rankAward.rank]
            titleLabel.text = title
        end

        --show rank award
        if rankAward.award then
            ShowAwards(rankAward.award, rankAwardListItem)
        end
    end
end

local function ShowRankAwardList(params,fields)
    -- printyellow("[dlgtournamentreward:ShowRankAwardList] dlgdialogbox_reward show callback!")

    fields.UILabel_Title.text = LocalString.Tournament_Reward_Title
    local huiwuCfg = ConfigManager.getConfig("huiwu")
    if huiwuCfg then
        local awardList = huiwuCfg.battleaward
        if awardList then
            for i=1, #awardList do
                local rankAwardListItem = fields.UIList_RewardGroups:AddListItem()
                local rankAward = awardList[i]
                ShowRankAward(rankAward, rankAwardListItem)
            end
            --[[
	        local uitable = fields.UIList_RewardGroups.gameObject:GetComponent(UITable)
            uitable:SetMaxHeight(1000)
            printyellow("[dlgtournamentreward:ShowRankAwardList] set uitable.repositionNow=true!")
            uitable.repositionNow = true
            printyellow("[dlgtournamentreward:ShowRankAwardList] set uitable:Reposition()!")
            uitable:Reposition()
            --]]
        else
            -- printyellow("[dlgtournamentreward:ShowRankAwardList] huiwuCfg.battleaward null!")
        end
    else
        -- printyellow("[dlgtournamentreward:ShowRankAwardList] huiwu config null!")
    end
end

local function show()
    UIManager.show("common.dlgdialogbox_reward", {type = 0, callBackFunc = ShowRankAwardList})
end

return{
    show = show,
}
