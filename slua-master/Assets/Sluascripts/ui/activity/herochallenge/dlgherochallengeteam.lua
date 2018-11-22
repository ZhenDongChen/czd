local UIManager = require("uimanager")
local EventHelper = UIEventListenerHelper

local m_Name
local m_GameObject
local m_Fields

local function hide()
end

local function destroy()
end

local function refresh()
end

local function show()
    m_Fields.UIGroup_Message.gameObject:SetActive(false)
    m_Fields.UIButton_Close.gameObject:SetActive(true)
    m_Fields.UILabel_SituResurrection.text = LocalString.Team_Create
    m_Fields.UILabel_StwpResurrection.text = LocalString.Team_Search
    EventHelper.SetClick(m_Fields.UIButton_Close,function()
        UIManager.hide(m_Name)
    end)
    EventHelper.SetClick(m_Fields.UIButton_SituResurrection,function()
        --创建队伍
        UIManager.hide(m_Name)
        local TeamManager = require("ui.team.teammanager")
        TeamManager.SendCreateTeam()
    end)
    EventHelper.SetClick(m_Fields.UIButton_StwpResurrection,function()
        --搜索队伍
        UIManager.hide(m_Name)
        UIManager.showdialog("team.dlgteam",nil,5)
    end)
end

local function init(name,gameObject,fields)
    m_Name = name
    m_GameObject = gameObject
    m_Fields = fields
end

return
{
    init = init,
    show = show,
    hide = hide,
    refresh = refresh,
    destroy = destroy,
}