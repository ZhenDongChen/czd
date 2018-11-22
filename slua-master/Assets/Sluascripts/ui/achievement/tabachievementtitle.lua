--local tabachievementtitle       = require "ui.achievement.tabachievementtitle"
local EventHelper        = UIEventListenerHelper
local uimanager          = require "uimanager"
local network            = require "network"
local titlemanager       = require "ui.title.titlemanager"

local achievementmanager

local gameObject
local name
local fields


local function RefreshMoney()
    fields.UILabel_AchievementAmount2.text = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu)
end

local function RefreshBase()
    local titlegroup = titlemanager.GetTitleGroup(cfg.role.TitleType.ACHIEVEMENT)
    if titlegroup then 
       local currenttitle               = titlegroup:GetCurrentTitle() 
       if currenttitle then 
            fields.UILabel_CurrentTitle.text = currenttitle:GetName()
           
       else 
             fields.UILabel_CurrentTitle.text =LocalString.DlgAchievement_NoTitle 
       end 

       local nexttitle                  = titlegroup:GetNextTitle()
       if nexttitle then 
            EventHelper.SetClick(fields.UIButton_Advanced, function()
                achievementmanager.CEvolveTitle(nexttitle.m_Id)
            end )

            fields.UILabel_NextTitle.text     = string.format(LocalString.DlgAchievement_NextTitle, nexttitle:GetName())
            fields.UILabel_ProcessTitle.text = string.format("%s/%s",PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu),achievementmanager.GetAchievementEvolveNeedValue(nexttitle.m_Id))
            fields.UIProgressBar_ProcessTitle.value = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu) / achievementmanager.GetAchievementEvolveNeedValue(nexttitle.m_Id)
            --UITools.SetButtonEnabled(fields.UIButton_Advanced,true)
            fields.UIButton_Advanced.gameObject:SetActive(true)
       else 
            fields.UILabel_NextTitle.text  = LocalString.DlgAchievement_TitleMax
            fields.UILabel_ProcessTitle.text = string.format("%s/%s",PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu),PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.ChengJiu))
            fields.UIProgressBar_ProcessTitle.value = 1
            --UITools.SetButtonEnabled(fields.UIButton_Advanced,false)
            fields.UIButton_Advanced.gameObject:SetActive(false)
       end

       --GetAvailableNumber()
      
    end
end


local function RefreshTitle()
    local titlegroup = titlemanager.GetTitleGroup(cfg.role.TitleType.ACHIEVEMENT)
    if titlegroup then 
        fields.UIList_AchievementTitle:Clear()
        for _,title in pairs(titlegroup:GetTitleList()) do 
            local item = fields.UIList_AchievementTitle:AddListItem()
            item:SetText("UILabel_Achievement_TitleName",title:GetName())
            item.Controls["UITexture_Title"]:SetIconTexture(title:GetTexturePath())
            if title.m_IsActive then 
                item.Controls["UILabel_Get"].color = Color.green
                --LocalString.DlgAchievement_TitleActive
                item.Controls["UILabel_Get"].text = ""
            else 
                item.Controls["UILabel_Get"].color = Color.red
                item.Controls["UILabel_Get"].text = LocalString.DlgAchievement_TitleInActive
            end 

            viewutil.SetTextureGray(item.Controls["UITexture_Title"],not title.m_IsActive)
            local UIList_Property = item.Controls["UIList_Property"]
            UIList_Property:Clear()
            for _,preptery in pairs(title:GetPropertyStrs()) do 
                local propertyitem = UIList_Property:AddListItem()
                propertyitem:SetText("UILabel_Property",preptery)

            end 
        end
    end
end


local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    
end

local function hide()
    -- print(name, "hide")
end


local function refresh(params)
    --print(name, "refresh")
    RefreshMoney()
    RefreshTitle()
    RefreshBase()
end


local function update()
    -- print(name, "update")
end



local function init(params)
    name, gameObject, fields = unpack(params)
      print(name, "init")
    achievementmanager = require "ui.achievement.achievementmanager"
    
    
end




return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    destroy         = destroy,
    refresh         = refresh,
    RefreshMoney    = RefreshMoney,
}