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

local m_SortedCityIds

local function ShowBattle(listitem, citydata, battleinfo)
    if nil==listitem or nil == citydata  or nil==battleinfo then
        print("[ERROR][dlgweekbattle:ShowBattle] listitem or citydata or battleinfo nil!")
        return
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
        local defendfamily = citydata:OldfamilyName()
        UILabel_OccupyFamily.text = IsNullOrEmpty(defendfamily) and LocalString.City_War_None or defendfamily
    end

    --stability
    local UILabel_StableValue = listitem.Controls["UILabel_StableValue"]
    if UILabel_StableValue then
        UILabel_StableValue.text = citydata:GetStability() and (citydata:GetStability().."%") or ""
    end

    --enter
    local UIButton_Enter = listitem.Controls["UIButton_Enter"]
    local UILabel_NotOpen = listitem.Controls["UILabel_NotOpen"]
	local UILabel_Over = listitem.Controls["UILabel_Over"]
    if UIButton_Enter and UILabel_NotOpen then
         UIButton_Enter.gameObject:SetActive(citydata:CanEnterCityWar() and not citydata:IsCityWarOver())
         UILabel_NotOpen.gameObject:SetActive(not citydata:CanEnterCityWar() and not citydata:IsCityWarOver() )
		 UILabel_Over.gameObject:SetActive(citydata:IsCityWarOver())
         EventHelper.SetClick(UIButton_Enter, function()
            citywarmanager.send_CEnterBattle(citydata:GetCityId())
        end)
    end
end

local function CompareCityId(id1, id2)
    local city1 = citywarinfo.GetCity(id1)
    local city2 = citywarinfo.GetCity(id2)
    if city1 and city2 then
        if city1:GetCityLevel()~=city2:GetCityLevel() then
            return city1:GetCityLevel()<city2:GetCityLevel()
        else
            return id2 >= id1 
        end
    else
        return true
    end  
end

local function SortCityIds()
    m_SortedCityIds = keys(citywarinfo.GetFamilyWeekBattles())
    utils.table_sort(m_SortedCityIds, CompareCityId)
end

local function refresh()
    --reset
    fields.UIList_Territorial:Clear()
    --fields.UIList_Territorial:Reposition()
        
    --show
    SortCityIds()
    local familybattles = citywarinfo.GetFamilyWeekBattles()
    --printyellow("[dlgweekbattle:refresh] familybattles:")
    --printt(familybattles)
    --printyellow("[dlgweekbattle:refresh] m_SortedCityIds:")
    --printt(m_SortedCityIds)
    if familybattles and m_SortedCityIds and table.getn(m_SortedCityIds)>0 then
        local cityid
        local citydata
        local listitem        
        for index=1, table.getn(m_SortedCityIds) do
            cityid = m_SortedCityIds[index]
            citydata = cityid and citywarinfo.GetCity(cityid) or nil
            listitem = fields.UIList_Territorial:AddListItem()
            ShowBattle(listitem, citydata, familybattles[cityid])
        end
    end
    --fields.UIList_Territorial:Reposition()
end

local function show()
    citywarmanager.send_CGetMyBattles()
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
    uimanager.hide("citywar.dlgweekbattle")
end

local function init(params)
    name, gameObject, fields = unpack(params)
   -- local   citywarmanager 	  = require "ui.citywar.citywarmanager"
    --ui
	citywarmanager.send_CGetAllCitys()
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
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
