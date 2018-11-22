local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local bonusmanager 	  = require "item.bonusmanager"
local ItemEnum = require"item.itemenum"
local ItemManager = require("item.itemmanager")

local m_BossName
local m_BossLevelCfg
--local m_BossId
--local m_BossLevel
--local m_BossCfg

local function ShowItem(item, count, awardList)
    --printyellow("[dlgfamilybossreward:ShowItem] Show Item!")
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
            labelNum.text = count and count or 1
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

local function ShowAwards(typeAward, count, typeAwardListItem)
    -- printyellow("[dlgfamilybossreward:ShowAwards] Show Rewards!")
    if typeAward and typeAwardListItem then        
        --hide resource group
        local resourceGroup = typeAwardListItem.Controls["UIGroup_Resource"]
        if resourceGroup then
            resourceGroup.gameObject:SetActive(false)
        end

        --show awars
        local awardList = typeAwardListItem.Controls["UIList_Rewards"]
        if awardList == nil then
            printyellow("[dlgfamilybossreward:ShowAwards] UIList_Rewards null!")
        else
            local items = bonusmanager.GetItemsByBonusConfig(typeAward)
            if items and items[1] then
               ShowItem(items[1], count, awardList)
            end
        end
    end
end

local function ShowTypeAward(title, typeAward, count, fields)
    -- printyellow("[dlgfamilybossreward:ShowTypeAward] Show rank ", rankAward.rank)
    if title and typeAward then
        if nil==count or count<=0 then
            count=1
        end
        local typeAwardListItem = fields.UIList_RewardGroups:AddListItem()
        --set title
        local titleLabel = typeAwardListItem.Controls["UILabel_Line1"]
        if titleLabel then
            titleLabel.text = title
        end

        --show rank award
        ShowAwards(typeAward, count, typeAwardListItem)
    end
end

local function ShowBossAwardList(params,fields)
    -- printyellow("[dlgfamilybossreward:ShowBossAwardList] dlgdialogbox_reward show callback!") 
    if nil==fields then
        printyellow("[dlgfamilybossreward:ShowBossAwardList] show failed, fields nil!") 
        return 
    end

    if UIManager.isshow("family.boss.dlgfamilyboss") then
        UIManager.call("family.boss.dlgfamilyboss", "SetModelActive", false)   
    end 

    if LocalString.Family_Boss_Award_Title and m_BossName then
        fields.UILabel_Title.text = string.format(LocalString.Family_Boss_Award_Title, m_BossName)
    else
        fields.UILabel_Title.text = ""
    end
    fields.UIList_RewardGroups:Clear()

    if m_BossLevelCfg then
        if m_BossLevelCfg.dropitem and m_BossLevelCfg.dropamount then 
            --rank award
            if LocalString.Family_Boss_Award_Rank then
                for rank=1, 3 do
                    ShowTypeAward(LocalString.Family_Boss_Award_Rank[rank], m_BossLevelCfg.dropitem, m_BossLevelCfg.dropamount[rank], fields)
                end
            end
            
            --kill award
            ShowTypeAward(LocalString.Family_Boss_Award_Drop, m_BossLevelCfg.dropitem, m_BossLevelCfg.dropamount[4], fields)
        end

        --last shot award
        ShowTypeAward(LocalString.Family_Boss_Award_Last, m_BossLevelCfg.lasthitbonus, 1, fields)

        --lucky award
        ShowTypeAward(LocalString.Family_Boss_Award_Lucky, m_BossLevelCfg.luckybonus, 1, fields)
    else
        printyellow("[dlgfamilybossreward:ShowBossAwardList] m_BossLevelCfg null!")
    end
end

local function show(bossname, bosslevelcfg)
    if bossname and bosslevelcfg then
        --m_BossId = bossid
        --m_BossLevel = bosslevel
        --m_BossCfg = bosscfg
        m_BossName = bossname
        m_BossLevelCfg = bosslevelcfg
        UIManager.show("common.dlgdialogbox_reward", {type = 0, callBackFunc = ShowBossAwardList}) 
    else
        printyellow("[dlgfamilyboss:show] show dlgfamilybossreward failed!, bossname=", bossname)  
        printyellow("[dlgfamilyboss:show] show dlgfamilybossreward failed!, bosslevelcfg=", bosslevelcfg)    
    end
end

return{
    show = show,
}
