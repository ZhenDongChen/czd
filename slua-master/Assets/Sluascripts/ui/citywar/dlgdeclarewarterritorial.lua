local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local define = require "define"
local PlayerRole = require "character.playerrole"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local dlgdeclareinvest = require "ui.citywar.dlgdeclareinvest"

--ui
local fields
local gameObject
local name

local Max_Item_Per_Page = 5
local m_CurrentPage
local m_Totalpage
local m_SortedCityIds

local function ShowCity(listitem, citydata)
    if nil==listitem then
        print("[ERROR][dlgdeclarewarterritorial:ShowCity] listitem  nil!")
        return
    elseif nil==citydata then
        print("[ERROR][dlgdeclarewarterritorial:ShowCity] citydata nil!")
        return
    else
        listitem.Data = citydata
    end

    --name
    local UILabel_TerritorialName = listitem.Controls["UILabel_TerritorialName"]
    if UILabel_TerritorialName then
        UILabel_TerritorialName.text = citydata:GetCityName()
    end
    
    --city level
    local UISprite_CityLevel1 = listitem.Controls["UISprite_CityLevel1"]
    local UISprite_CityLevel2 = listitem.Controls["UISprite_CityLevel2"]
    local UISprite_CityLevel3 = listitem.Controls["UISprite_CityLevel3"]
    if UISprite_CityLevel1 and UISprite_CityLevel2 and UISprite_CityLevel3 then
        UISprite_CityLevel1.gameObject:SetActive(cfg.family.citywar.CityLevelType.SENIOR==citydata:GetCityLevel())
        UISprite_CityLevel2.gameObject:SetActive(cfg.family.citywar.CityLevelType.MEDIUM==citydata:GetCityLevel())
        UISprite_CityLevel3.gameObject:SetActive(cfg.family.citywar.CityLevelType.PRIMARY==citydata:GetCityLevel())
        UISprite_CityLevel1.color = citydata:GetDefenderColor()
        UISprite_CityLevel2.color = citydata:GetDefenderColor()
        UISprite_CityLevel3.color = citydata:GetDefenderColor()
    end
    
    --defend family
    local UILabel_OccupyFamily = listitem.Controls["UILabel_OccupyFamily"]
    if UILabel_OccupyFamily then
        local defendfamily = citydata:GetDefenderFamilyName()
        UILabel_OccupyFamily.text = IsNullOrEmpty(defendfamily) and LocalString.City_War_None or defendfamily
    end

    --stability
    local UILabel_StableValue = listitem.Controls["UILabel_StableValue"]
    if UILabel_StableValue then
        UILabel_StableValue.text = citydata:GetStability() and (citydata:GetStability().."%") or ""
    end

    --Bidding status
    local UILabel_GovernTime = listitem.Controls["UILabel_GovernTime"]
    if UILabel_GovernTime then
        local state = (true==citydata:IsPeace()) and LocalString.City_War_Invest_None or LocalString.City_War_Invest_Yes
        UILabel_GovernTime.text = state
    end

    --invest money
    local UILabel_Money = listitem.Controls["UILabel_Money"]
    if UILabel_Money then        
        UILabel_Money.text = (citywarinfo.GetFamilyDeclareCity()==citydata:GetCityId()) and citywarinfo.GetFamilyDeclareMoney() or 0
    end

    --declare state
    local UILabel_DeclareWar = listitem.Controls["UILabel_DeclareWar"]
    if UILabel_DeclareWar then
        UILabel_DeclareWar.text = (citywarinfo.GetFamilyDeclareCity()==citydata:GetCityId()) and LocalString.City_War_Change_Invest or LocalString.City_War_Declare
    end        
    local UIButton_DeclareWar = listitem.Controls["UIButton_DeclareWar"]
    if UIButton_DeclareWar then
        local enable = false
        if cfg.family.citywar.CityWarStage.ENTROLL~=citywarinfo.GetFamilyCityWarStage() then
            enable = false
        else
            enable = false==citywarinfo.HasFamilyDeclareCity() or citywarinfo.GetFamilyDeclareCity()==citydata:GetCityId()
        end
        UIButton_DeclareWar.isEnabled = enable   
        --test        
        --UIButton_DeclareWar.isEnabled = true   
        
        EventHelper.SetClick(UIButton_DeclareWar, function()
            dlgdeclareinvest.show(citydata)
        end)
    end
end

local function ShowPage(pageindex)
    if pageindex and pageindex>0 and pageindex<=m_Totalpage then
        --printyellow("[dlgdeclarewarterritorial:ShowPage] show page:", pageindex)
        m_CurrentPage = pageindex
        fields.UILabel_Page.text = m_CurrentPage.."/"..m_Totalpage
        fields.UIList_Territorial:Clear()
        
        if m_SortedCityIds and table.getn(m_SortedCityIds)>0 then
            local listitem
            local cityid
            local citydata
            for index=(m_CurrentPage-1)*Max_Item_Per_Page+1, m_CurrentPage*Max_Item_Per_Page do
                cityid = m_SortedCityIds[index]
                citydata = cityid and citywarinfo.GetCity(cityid) or nil
                if citydata then
                    listitem = fields.UIList_Territorial:AddListItem()
                    ShowCity(listitem, citydata)
                end
            end
        end
    end
end

local function CompareCityId(id1, id2)
    local city1 = citywarinfo.GetCity(id1)
    local city2 = citywarinfo.GetCity(id2)
    if city1 and city2 then
        if city1:GetCityId()==citywarinfo.GetFamilyDeclareCity() then
            return true
        elseif city2:GetCityId()==citywarinfo.GetFamilyDeclareCity() then
            return false
        elseif city1:GetCityLevel()~=city2:GetCityLevel() then
            return city1:GetCityLevel()<city2:GetCityLevel()
        else
            return id2 >= id1 
        end
    else
        return true
    end   
end

local function SortCityIds()
    m_SortedCityIds = keys(citywarinfo.GetDeclareCities())
    utils.table_sort(m_SortedCityIds, CompareCityId)
end

local function refresh()
    --printyellow("[dlgdeclarewarterritorial:refresh] refresh dlgdeclarewarterritorial.")
    --reset
    m_Totalpage = 0
    fields.UILabel_Page.text = ""
    fields.UIList_Territorial:Clear()

    --show
    SortCityIds()
    if m_SortedCityIds and table.getn(m_SortedCityIds)>0 then
        m_Totalpage = math.ceil(table.getn(m_SortedCityIds)/Max_Item_Per_Page)
        if m_CurrentPage<1 then
            m_CurrentPage = 1
        end
        if m_CurrentPage>m_Totalpage then
            m_CurrentPage = m_Totalpage
        end

        ShowPage(m_CurrentPage)   
    else 
        print("[dlgdeclarewarterritorial:refresh] m_SortedCityIds empty.")
    end
end

local function show()
    m_CurrentPage = 1
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
    uimanager.hide("citywar.dlgdeclarewarterritorial")
end

local function OnUIButton_ArrowsLeft()
    --printyellow("[dlgdeclarewarterritorial:OnUIButton_ArrowsLeft] prepare show page:", m_CurrentPage-1)
    if m_CurrentPage>1 then
        ShowPage(m_CurrentPage-1)
    end
end

local function OnUIButton_ArrowsRight()
    --printyellow("[dlgdeclarewarterritorial:OnUIButton_ArrowsRight] prepare show page:", m_CurrentPage+1)
    if m_CurrentPage<m_Totalpage then
        ShowPage(m_CurrentPage+1)
    end
end

local function OnUIButton_Rule()
    local citywarcfg = ConfigManager.getConfig("citywar")
    if citywarcfg then    
        citywarmanager.ShowRule(citywarcfg.tipsdeclare)
    else
        print("[ERROR][dlgdeclarewarterritorial:OnUIButton_Rule] citywarcfg nil!")
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    --ui
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, OnUIButton_ArrowsLeft)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, OnUIButton_ArrowsRight) 
    EventHelper.SetClick(fields.UIButton_Rule, OnUIButton_Rule)
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
