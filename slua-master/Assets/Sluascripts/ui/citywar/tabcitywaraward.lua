local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local DefineEnum = require("defineenum")
local uimanager = require("uimanager")
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local bonusmanager 	  = require "item.bonusmanager"
local ItemEnum = require"item.itemenum"
local ItemIntroduct=require"item.itemintroduction"
local dlgTaxBonus       = require("ui.citywar.dlgtaxbonus")
local familymgr = require("family.familymanager")

--ui
local fields
local gameObject
local name

local m_CityCountLabelTable

local function Clear()
end 

local function ShowItem(bonusitem, listitem)
    --printyellow("[tabcitywaraward:ShowItem] Show bonusitem!")
    if bonusitem and listitem then
        --data
        listitem.Data = bonusitem

        --icon
        listitem:SetIconTexture(bonusitem:GetIconPath())

        --[[
        --name
        local labelName = listitem.Controls["UILabel_ItemName"]
        if labelName then
            --labelName.text = bonusitem:GetName()
            colorutil.SetQualityColorText(labelName, bonusitem:GetQuality(), bonusitem:GetName())
        end
        --]]

        --count
        local labelNum = listitem.Controls["UILabel_Amount"]
        if labelNum then
            labelNum.gameObject:SetActive(true)
            labelNum.text = bonusitem:GetNumber()
        end

        --quality
        local spriteQuality = listitem.Controls["UISprite_Quality"]
        if spriteQuality then
            spriteQuality.spriteName = colorutil.GetQualitySprite(bonusitem:GetQuality())
        end

        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(bonusitem:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end
    end
end

local function ShowBonus(uilist, bonuslist, isconfig)
    if uilist then
        uilist:Clear()
    else
        if Local.LogManager then
            print("[ERROR][tabcitywaraward:ShowBonus] uilist nil!")
        end
        return
    end

    if bonuslist and table.getn(bonuslist) then
        local listitem
        local bonusitems
        for _, bonus in ipairs(bonuslist) do         
            if true==isconfig then
                bonusitems = bonusmanager.GetItemsOfSingleBonus(bonus)
                --printyellow("[tabcitywaraward:ShowBonus] bonusmanager.GetItemsOfSingleBonus(bonus):")
                --printt(bonusitems)
            else
                bonusitems = bonusmanager.GetItemsOfServerBonus(bonus)
                --printyellow("[tabcitywaraward:ShowBonus] bonusmanager.GetItemsOfServerBonus(bonus):")
                --printt(bonusitems)
            end
            if bonusitems and #bonusitems>0 then
                for index=1, #bonusitems do
                    listitem = uilist:AddListItem()                   
                    ShowItem(bonusitems[index], listitem)                 
                end           
            end
        end        
    end
end 

local function RefreshTaxBonus()
    --printyellow("[tabcitywaraward:RefreshTaxBonus] refresh tax Bonus.")
    --printt(m_CityCountLabelTable)

    --show count
    if m_CityCountLabelTable then
        local levelcitycounts = citywarinfo.GetFamilyCityLevelCounts()
        if levelcitycounts then
            local count
            for level,uilabel in pairs(m_CityCountLabelTable) do
                count = levelcitycounts[level]
                if uilabel then
                    uilabel.text = string.format(LocalString.City_War_City_Count, count and count or 0)
                    --printyellow(string.format("[tabcitywaraward:RefreshTaxBonus] set label[%s].text = %s for level [%s].", uilabel.gameObject.name, uilabel.text, level))
                end
            end
        end     
    end

    --city color
    --[[
    printyellow("[tabcitywaraward:RefreshTaxBonus] fields.UISprite_cityL:")
    printt(fields.UISprite_cityL)
    printyellow("[tabcitywaraward:RefreshTaxBonus] citywarinfo.GetFamilyColor():")
    printt(citywarinfo.GetFamilyColor())    
    --]]
    if citywarinfo.GetFamilyColor() then
        fields.UISprite_cityL.color = citywarinfo.GetFamilyColor()
        fields.UISprite_cityM.color = citywarinfo.GetFamilyColor()
        fields.UISprite_cityS.color = citywarinfo.GetFamilyColor()
    end
        
    --show bonus
    ShowBonus(fields.UIList_Award, citywarinfo.GetFamilyTaxBonus(), true)
end

local function ShowLuckyCity(listitem, citydata)
    if listitem and citydata then
        listitem.gameObject:SetActive(true)
        --printyellow(string.format("[tabcitywaraward:ShowLuckyCity] Show Lucky City at listitem[%s]:", listitem.gameObject.name))
        --printt(citydata)

        --city level
        local UISprite_city1 = listitem.Controls["UISprite_city1"]
        local UISprite_city2 = listitem.Controls["UISprite_city2"]
        local UISprite_city3 = listitem.Controls["UISprite_city3"]
        if UISprite_city1 and UISprite_city2 and UISprite_city3 then
            UISprite_city1.gameObject:SetActive(cfg.family.citywar.CityLevelType.SENIOR==citydata:GetCityLevel())
            UISprite_city2.gameObject:SetActive(cfg.family.citywar.CityLevelType.MEDIUM==citydata:GetCityLevel())
            UISprite_city3.gameObject:SetActive(cfg.family.citywar.CityLevelType.PRIMARY==citydata:GetCityLevel())
            UISprite_city1.color = citydata:GetDefenderColor()
            UISprite_city2.color = citydata:GetDefenderColor()
            UISprite_city3.color = citydata:GetDefenderColor()
        end  
        
        --name
        local UILabel_cityname = listitem.Controls["UILabel_cityname"]
        if UILabel_cityname then
            UILabel_cityname.text = citydata:GetCityName()
        end
    end
end

local function RefreshLuckyCities(luckycities)
    --printyellow("[tabcitywaraward:RefreshLuckyCities] refresh Lucky Cities.")
    
    --reset
    local listcount = fields.UIList_Citys.Count    
    local listitem
    for i=0,(listcount-1) do
        listitem = fields.UIList_Citys:GetItemByIndex(i)
        if listitem then
            listitem.gameObject:SetActive(false)
        end
    end

    --show city name
    if luckycities then    
        local index = 0
        for _,citydata in ipairs(luckycities) do
            if index>=listcount then
                return
            end
            listitem = fields.UIList_Citys:GetItemByIndex(index)  
            ShowLuckyCity(listitem, citydata)
            index = index+1
        end        
    end
end

local function RefreshLuckyBonus()
    --printyellow("[tabcitywaraward:RefreshLuckyBonus] refresh Lucky Bonus.")

    --get data
    local luckybonus = citywarinfo.GetWorldLuckyBonus()--map<cityid, map.msg.Bonus>
    local bonuslist = {}
    local luckycities = {}
    if luckybonus then
        local citydata
        for cityid,bonus in pairs(luckybonus) do
            if bonus then
                table.insert(bonuslist, bonus)
            end
            citydata = citywarinfo.GetCity(cityid)
            if citydata then
                table.insert(luckycities, citydata)
            end
        end        
    end

    --show city name
    RefreshLuckyCities(luckycities)

    --show bonus
    ShowBonus(fields.UIList_Artifact, bonuslist, false)
end

local function CanAssignLuckyBonus()
	printyellow(">>>>>>>>>>>>>>>>>>>>>>>>>citywarinfo.HasFamilyLuckyBonus()",citywarinfo.HasFamilyLuckyBonus(),familymgr.IsChief())
    return citywarinfo.HasFamilyLuckyBonus() and familymgr.IsChief()
end

local function RefreshFamilyLuckyBonus()
    local tip = (true==citywarinfo.HasFamilyLucky()) and LocalString.City_War_Lucky_Bonus_Yes or LocalString.City_War_Lucky_Bonus_No
    fields.UILabel_tips.text = tip
    fields.UIButton_assign.isEnabled = CanAssignLuckyBonus()
end

local function refresh()
    --printyellow("[tabcitywaraward:refresh] refresh tabcitywaraward.")
    RefreshTaxBonus()
    RefreshLuckyBonus()
    RefreshFamilyLuckyBonus()
end

local function reset()
    fields.UILabel_tips.text = ""
    fields.UIButton_assign.isEnabled = false
end

local function show()
    --printyellow("[tabcitywaraward:show] show tabcitywaraward.")
    reset()
    citywarmanager.send_CGetAllLuckyBonusInfo()
end

local function destroy()
end

local function hide()
end

local function update()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function OnUIButton_Close()
    uimanager.hide("citywar.tabcitywaraward")
end

local function OnUIButton_ReceiveReward()
    --printyellow("[tabcitywaraward:OnUIButton_ReceiveReward] OnUIButton_ReceiveReward")
    dlgTaxBonus.show()
end

local function OnUIButton_assign()
    --printyellow("[tabcitywaraward:OnUIButton_assign] OnUIButton_assign")
    if true == CanAssignLuckyBonus() then
        --赐予界面
        uimanager.show("citywar.tabrewarddistribution")
    else
        local params = {}
        params.title = LocalString.TipText
		params.content = LocalString.City_War_Lucky_Bonus_Assign
		uimanager.ShowAlertDlg(params)
    end
end

local function OnUIButton_Check()
    --printyellow("[tabcitywaraward:OnUIButton_Check] OnUIButton_Check")
    
    --分配历史界面
    uimanager.show("citywar.tabworldterritoryrewarddistribution",{type = DefineEnum.RewardDistributionType.Territory})
end

local function OnUIButton_Rule()
    local citywarcfg = ConfigManager.getConfig("citywar")
    if citywarcfg then    
        citywarmanager.ShowRule(citywarcfg.tipsaward)
    else
        if Local.LogManager then
            print("[ERROR][tabcitywaraward:OnUIButton_Rule] citywarcfg nil!")
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

local function init(params)
    name, gameObject, fields = unpack(params)

    m_CityCountLabelTable = {}    
    m_CityCountLabelTable[cfg.family.citywar.CityLevelType.SENIOR] = fields.UILabel_cityL
    m_CityCountLabelTable[cfg.family.citywar.CityLevelType.MEDIUM] = fields.UILabel_cityM
    m_CityCountLabelTable[cfg.family.citywar.CityLevelType.PRIMARY] = fields.UILabel_cityS

    --ui
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_ReceiveReward, OnUIButton_ReceiveReward)
    EventHelper.SetClick(fields.UIButton_assign, OnUIButton_assign)    
    EventHelper.SetClick(fields.UIButton_Check, OnUIButton_Check)
    EventHelper.SetClick(fields.UIButton_Rule, OnUIButton_Rule)    
    EventHelper.SetListClick(fields.UIList_Artifact, OnUIListItemClicked)
    EventHelper.SetListClick(fields.UIList_Award, OnUIListItemClicked)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
  RefreshLuckyBonus = RefreshLuckyBonus,
  RefreshFamilyLuckyBonus = RefreshFamilyLuckyBonus,
}
