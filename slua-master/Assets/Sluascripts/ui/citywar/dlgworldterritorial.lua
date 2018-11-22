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

local Max_Item_Per_Page = 5
local m_CurrentPage
local m_Totalpage
local m_SortedCityIds

local function Clear()
end

local function ShowCity(listitem, citydata)
    if nil==listitem then
        print("[ERROR][dlgworldterritorial:ShowCity] listitem  nil!")
        return
    elseif nil==citydata then
        print("[ERROR][dlgworldterritorial:ShowCity] citydata nil!")
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

    --state
    local UILabel_State = listitem.Controls["UILabel_State"]
    if UILabel_State then
        --printyellow("[dlgworldterritorial:ShowCity] citydata:IsPeace():", citydata:IsPeace())
        local state = (true==citydata:IsPeace()) and LocalString.City_War_State[1] or LocalString.City_War_State[2]
        UILabel_State.text = state
    end

    --war time
    local UILabel_WarTime = listitem.Controls["UILabel_WarTime"]
    if UILabel_WarTime then
        UILabel_WarTime.text = citydata:GetWarTimeRangeText()
    end

    --attack family
    local UILabel_DeclareFamily = listitem.Controls["UILabel_DeclareFamily"]
    if UILabel_DeclareFamily then
        local attackfamily = citydata:GetAttackerFamilyName()
        UILabel_DeclareFamily.text = IsNullOrEmpty(attackfamily) and LocalString.City_War_None or attackfamily
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
end

local function ShowPage(pageindex)
    if pageindex and pageindex>0 and pageindex<=m_Totalpage then
        printyellow("[dlgworldterritorial:ShowPage] show page:", pageindex)
		printyellow("[m_SortedCityIds]:",#m_SortedCityIds)
        --reset
        m_CurrentPage = pageindex
        fields.UILabel_Page.text = m_CurrentPage.."/"..m_Totalpage
        fields.UIList_Territorial:Clear()
        
        --show
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
        if cfg.family.citywar.CityWarStage.BATTLE~=citywarinfo.GetFamilyCityWarStage() or city1:IsPeace()==city2:IsPeace() then            
            if city1:GetCityLevel()~=city2:GetCityLevel() then
                return city1:GetCityLevel()<city2:GetCityLevel()
            else
                return city2:GetCityId() >= city1:GetCityId()
            end
        else
            return (false==city1:IsPeace())
        end
    else
        return true
    end    
end

local function SortCityIds()
    m_SortedCityIds = keys(citywarinfo.GetAllCities())
    utils.table_sort(m_SortedCityIds, CompareCityId)
end

local function refresh()
    --printyellow("[dlgworldterritorial:refresh] refresh dlgworldterritorial.")
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
    end
end

local function show()
    --printyellow("[dlgworldterritorial:show] show dlgworldterritorial.")
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
    uimanager.hide("citywar.dlgworldterritorial")
end

local function OnUIButton_ArrowsLeft()
    --printyellow("[dlgworldterritorial:OnUIButton_ArrowsLeft] prepare show page:", m_CurrentPage-1)
    if m_CurrentPage>1 then
        ShowPage(m_CurrentPage-1)
    end
end

local function OnUIButton_ArrowsRight()
    --printyellow("[dlgworldterritorial:OnUIButton_ArrowsRight] prepare show page:", m_CurrentPage+1)
    if m_CurrentPage<m_Totalpage then
        ShowPage(m_CurrentPage+1)
    end
end

local function OnUIButton_Rule()
    local citywarcfg = ConfigManager.getConfig("citywar")
    if citywarcfg then    
        citywarmanager.ShowRule(citywarcfg.tipsworld)
    else
        print("[ERROR][dlgworldterritorial:OnUIButton_Rule] citywarcfg nil!")
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
