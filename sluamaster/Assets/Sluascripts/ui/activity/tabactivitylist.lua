local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local ConfigManager = require("cfg.configmanager")

local HEROCHALLENGE_ORDER = 7   --英雄挑战序列号

local m_GameObject
local m_Name
local m_Fields
local m_Index = -1
local m_Total = 0

local m_RedDotList = {
    ["activity.worldboss.tabworldboss"] = require("ui.activity.worldboss.worldbossmanager").UnRead,
    ["activity.multipve.tabmultipve"] = require("ui.ectype.guardtower.guardtowermanager").UnRead,
    ["activity.tournament.tabtournament"] = require("ui.activity.tournament.tournamentmanager").UnRead,
    ["activity.herobook.tabherobook"] = require("ui.activity.herobook.herobookmanager").UnRead,
    ["activity.personalboss.tabpersonalboss"] = require("ui.activity.personalboss.personalboss").UnRead,
    ["activity.attackcity.tabattackcity"] = require("ui.activity.attackcity.attackcitymanager").UnRead,
    ["activity.activityexp.tabactivityexp"] = require("ui.activity.activityexp.activityexpmanager").UnRead,
    ["activity.maimai.tabmaimaiectype"] = require("ui.activity.maimai.maimaiactmanager").UnRead,
    ["activity.teamcurrency.tabteamcurrencyectype"] = require("ui.activity.teamcurrency.teamcurrencymanager").UnRead,
    ["activity.tabdailyectypeone"] = require("ui.ectype.dailyectype.dailyectypemanager").HasRemainChallengeTimeByType,
    ["activity.tabdailyectypetwo"] = require("ui.ectype.dailyectype.dailyectypemanager").HasRemainChallengeTimeByType,
    ["activity.tabdailyectypethree"] = require("ui.ectype.dailyectype.dailyectypemanager").HasRemainChallengeTimeByType,
    ["activity.tabdailyectypefour"] = require("ui.ectype.dailyectype.dailyectypemanager").HasRemainChallengeTimeByType,
}

local function GetActivtiyData(activitytabindex)
    local activtiyData
    if 2 == activitytabindex then
        --日常活动
        activtiyData = ConfigManager.getConfig("dailyactivitytab")
    elseif 3 == activitytabindex then
        --周末活动
        activtiyData = ConfigManager.getConfig("weekendactivitytab")
    elseif 4 == activitytabindex then
        --节日活动
        activtiyData = ConfigManager.getConfig("festivalactivitytab")
    end
    return activtiyData
end

local function destroy()
end

local function show(params)
    local defaultTabIndex = 0
    if params and type(params) == "table" then
        if params.tabindex2 then
            defaultTabIndex = params.tabindex2 - 1
        elseif params.index then
            defaultTabIndex = params.index - 1
        end
    end
    m_Fields.UIList_Activity:Clear()
    local TeamManager = require("ui.team.teammanager")
    local activitytabindex = UIManager.gettabindex("ectype.dlgentrance_copy")
    local activtiyData = GetActivtiyData(activitytabindex)
    if activtiyData then
        m_Total = 0
        for _, activity in pairs(activtiyData) do

            local listItem = m_Fields.UIList_Activity:AddListItem()
            local UILabel_Theme = listItem.Controls["UILabel_Theme"]
            UILabel_Theme.text = activity.name
            local UISprite_Date = listItem.Controls["UISprite_Date"]
            if activity.label == nil or activity.label == "" then
                UISprite_Date.gameObject:SetActive(false)
            else
                UISprite_Date.gameObject:SetActive(true)
            end
            local UISprite_Warning = listItem.Controls["UISprite_Warning"]
            if m_RedDotList and m_RedDotList[activity.tabindex] then
                UISprite_Warning.gameObject:SetActive(m_RedDotList[activity.tabindex](activity.ectypetype))
            else
                UISprite_Warning.gameObject:SetActive(false)
            end
            listItem.Data = activity
            m_Total = m_Total + 1

        end
        EventHelper.SetListSelect(m_Fields.UIList_Activity, function(item)
            if (item.Data) and (item.Data.tabindex) then
                UIManager.showtab(item.Data.tabindex, params)
                m_Index = item.Index
                for i = 0, (m_Total - 1) do
                    if m_Index ~= i then
                        UIManager.hidetab(activtiyData[i + 1].tabindex)
                    end
                end
            end
        end)
        m_Fields.UIList_Activity:SetSelectedIndex(defaultTabIndex)
    end
end

local function DisplayDetailDailyEctype(ectypeType)
    for i = 1, (m_Fields.UIList_Activity.Count) do
        local item = m_Fields.UIList_Activity:GetItemByIndex(i-1)
        if item and item.Data and item.Data.ectypetype == ectypeType then
            local UISprite_Warning = item.Controls["UISprite_Warning"]
            if m_RedDotList and m_RedDotList[item.Data.tabindex] then
                UISprite_Warning.gameObject:SetActive(m_RedDotList[item.Data.tabindex](item.Data.ectypetype))
            else
                UISprite_Warning.gameObject:SetActive(false)
            end
        end
    end
end

local function showtab(params)
    UIManager.show("activity.tabactivitylist", params)
end

local function hide()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function refresh()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)
end

local function UnRead(index)
    local activtiyData = GetActivtiyData(index)
    if activtiyData and m_RedDotList then
        for _, activity in pairs(activtiyData) do
            if m_RedDotList[activity.tabindex] and m_RedDotList[activity.tabindex](index) then
                return true
            end
        end
    end
    return false
end

return {
    init = init,
    show = show,
    hide = hide,
    destroy = destroy,
    refresh = refresh,
    showtab = showtab,
    uishowtype = uishowtype,
    UnRead = UnRead,
    DisplayDetailDailyEctype = DisplayDetailDailyEctype,
}
