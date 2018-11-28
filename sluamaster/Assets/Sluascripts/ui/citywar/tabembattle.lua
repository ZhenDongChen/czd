local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local define = require "define"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"

--ui
local fields
local gameObject
local name

local CityIcons = {
"Sign_City_1",
"Sign_City_2",
"Sign_City_3_Stroke",
}
local Max_Item_Per_Page = 5
local m_CurrentPage
local m_Totalpage
local m_BattleButtons

local function Clear()
end 

local function ShowCity(listitem, citydata)
    if nil==listitem or  nil == citydata then
        print("[ERROR][dlgworldterritorial:ShowCity] listitem or citydata nil!")
        return
    else
        listitem.Data = citydata
    end

    local UILabel_TerritorialName = listitem.Controls["UILabel_TerritorialName"]
    if UILabel_TerritorialName then
        UILabel_TerritorialName.text = citydata:GetCityName()
    end

    local UILabel_State = listitem.Controls["UILabel_State"]
    if UILabel_State then
        local state = (true==citydata:IsPeace()) and LocalString.City_War_State[1] or LocalString.City_War_State[2]
        UILabel_State.text = state
    end

    local UILabel_WarTime = listitem.Controls["UILabel_WarTime"]
    if UILabel_WarTime then
        UILabel_WarTime.text = citydata:GetWarTimeRangeText()
    end

    local UISprite_CityLevel = listitem.Controls["UISprite_CityLevel"]
    if UISprite_CityLevel then
        --TODO:��uiֱ������ȥ������ͼƬ�л���ʾ
    end

    local UILabel_DeclareFamily = listitem.Controls["UILabel_DeclareFamily"]
    if UILabel_DeclareFamily then
        UILabel_DeclareFamily.text = citydata:GetAttackerFamilyName()
    end

    local UILabel_OccupyFamily = listitem.Controls["UILabel_OccupyFamily"]
    if UILabel_OccupyFamily then
        UILabel_OccupyFamily.text = citydata:GetDefenderFamilyName()
    end

    local UILabel_StableValue = listitem.Controls["UILabel_StableValue"]
    if UILabel_StableValue then
        UILabel_StableValue.text = citydata:GetStability() and (citydata:GetStability().."%") or ""
    end
end

local function ShowMemberPage(pageindex)
    if pageindex and pageindex>0 and pageindex<=m_Totalpage then
        printyellow("[dlgworldterritorial:ShowMemberPage] show page:", pageindex)
        m_CurrentPage = pageindex
        fields.UILabel_Page.text = m_CurrentPage.."/"..m_Totalpage
        fields.UIList_Territorial:Clear()
        
        local allcityconfig = citywarinfo.GetAllCityCfg()
        if allcityconfig and #allcityconfig>0 then
            local listitem
            local citycfg
            local citydata
            for index=(m_CurrentPage-1)*Max_Item_Per_Page+1, m_CurrentPage*Max_Item_Per_Page do
                citycfg = allcityconfig[index]
                citydata = citycfg and citywarinfo.GetCity(citycfg.cityid)
                if citydata then
                    listitem = fields.UIList_Territorial:AddListItem()
                    ShowCity(listitem, citydata)
                end
            end
        end
    end
end

local function refresh()
    printyellow("[dlgworldterritorial:refresh] refresh dlgworldterritorial.")
    fields.UILabel_Page.text = ""
    fields.UIList_Territorial:Clear()
    m_Totalpage = math.ceil(citywarinfo.GetAllCityCount()/Max_Item_Per_Page)
    if m_CurrentPage<1 then
        m_CurrentPage = 1
    end
    if m_CurrentPage>m_CurrentPage then
        m_CurrentPage = m_CurrentPage
    end

    ShowMemberPage(m_CurrentPage)
end

local function ShowBattle(listitem, citydata, status)
    if nil==listitem or  nil == citydata then
        print("[ERROR][tabembattle:ShowBattle] listitem or citydata nil!")
        return
    end

    listitem.gameObject:SetActive(true)
    local UILabel_TerritorialName = listitem.Controls["UILabel_TerritorialName"]
    if UILabel_TerritorialName then
        UILabel_TerritorialName.text = citydata:GetCityName()
    end
    
    local UISprite_CityLevel = listitem.Controls["UISprite_CityLevel"]
    if UISprite_CityLevel then
        --TODO:��uiֱ������ȥ������ͼƬ�л���ʾ
    end
    
    local UILabel_WarTime = listitem.Controls["UILabel_WarTime"]
    if UILabel_WarTime then
        UILabel_WarTime.text = citydata:GetWarTimeRangeText()
    end

    local UILabel_OccupyFamily = listitem.Controls["UILabel_OccupyFamily"]
    if UILabel_OccupyFamily then
        UILabel_OccupyFamily.text = citydata:GetDefenderFamilyName()
    end
    
    local UILabel_DeclareFamily = listitem.Controls["UILabel_DeclareFamily"]
    if UILabel_DeclareFamily then        
        UILabel_DeclareFamily.text = citywarinfo.GetDeclareWarFamilyName()
    end

    local UILabel_StableValue = listitem.Controls["UILabel_StableValue"]
    if UILabel_StableValue then
        UILabel_StableValue.text = citydata:GetStability() and (citydata:GetStability().."%") or ""
    end
        
    local UIButton_Enter = listitem.Controls["UIButton_Enter"]
    local UILabel_NotOpen = listitem.Controls["UILabel_NotOpen"]
    if UIButton_Enter and UILabel_NotOpen then
         UIButton_Enter.gameObject:SetActive(citydata:CanEnterCityWar())
         UILabel_NotOpen.gameObject:SetActive(not citydata:CanEnterCityWar())
         EventHelper.SetClick(UIButton_Enter, function()
            citywarmanager.send_CEnterBattle(citydata:GetCityId())
        end)
    end
end

local function RefreshBattles(msg)
    if msg.battlestatus then
        --reset buttons
        for index, button in ipairs(m_BattleButtons) do
            if button then
                button.gameObject:SetActive(false)
            end
        end
        
        --show city buttons
        local citydata
        local citybutton
        local buttonindex = 1
        for cityid, status in pairs(msg.battlestatus) do
            citydata = citywarinfo.GetCity(cityid)
            if citydata  then
                --citybutton = m_BattleButtons[buttonindex]
                listitem = fields.UIList_Territorial:AddListItem()
                ShowBattle(citybutton, citydata, status)
            end
        end
    end
end

local function show()
    printyellow("[dlgworldterritorial:show] show dlgworldterritorial.")
    m_CurrentPage = 1
    refresh()

    RefreshBattles()
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
    uimanager.hide("citywar.dlgworldterritorial")
end

local function OnUIButton_ArrowsLeft()
    printyellow("[dlgworldterritorial:OnUIButton_ArrowsLeft] prepare show page:", m_CurrentPage-1)
    if m_CurrentPage>1 then
        ShowMemberPage(m_CurrentPage-1)
    end
end

local function OnUIButton_ArrowsRight()
    printyellow("[dlgworldterritorial:OnUIButton_ArrowsRight] prepare show page:", m_CurrentPage+1)
    if m_CurrentPage<m_Totalpage then
        ShowMemberPage(m_CurrentPage+1)
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    m_BattleButtons = {}
    table.insert(m_BattleButtons, fields.UIButton_cityL1)
    table.insert(m_BattleButtons, fields.UIButton_cityM2)
    table.insert(m_BattleButtons, fields.UIButton_cityM1)
    table.insert(m_BattleButtons, fields.UIButton_cityS2)
    table.insert(m_BattleButtons, fields.UIButton_cityS1)
    table.insert(m_BattleButtons, fields.UIButton_cityL2)

    --ui
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, OnUIButton_ArrowsLeft)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, OnUIButton_ArrowsRight)    
    
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
}
