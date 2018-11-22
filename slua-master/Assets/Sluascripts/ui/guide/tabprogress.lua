local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")

local player = require("character.playerrole"):Instance()

local UIGROUP_PROGRESS_NAME =
{
    [1] = "UIGroup_Upgrade",
    [2] = "UIGroup_Material",
    [3] = "UIGroup_Richer",
    [4] = "UIGroup_Pet",
    [5] = "UIGroup_Talisman",
    [6] = "UIGroup_Equip",
}

local fields
local m_CurEventId
local m_AllEventList
local m_curFocusIndex

local m_EventUpgradeList
local m_EventMaterialList
local m_EventRicherList
local m_EventPetList
local m_EventTalismanList
local m_EventEquipList

-- local function showtab(params)
--     -- printyellow("on show tabbasic")
-- end

local function show()
end

-- local function hidetab()
-- end

local function hide()
end

local function destroy()
end

local function refresh(params)
    local wrapContent = fields.UIList_Entry.gameObject:GetComponent("UIWrapContentList")
    wrapContent:SetDataCount(m_AllEventList[m_CurEventId] and #m_AllEventList[m_CurEventId] or 0)
    if m_curFocusIndex < (#m_AllEventList[m_CurEventId]) then
        wrapContent:CenterOnIndex(m_curFocusIndex)
        --wrapContent:Refresh()
        wrapContent:WrapContent()
    else
        wrapContent:CenterOnIndex(0)
    end
end

-- local function update()
-- end

local function init(params)
    name, gameObject, fields = unpack(params)
	local ConfigManager = require("cfg.configmanager")
    m_EventUpgradeList  = {}
    m_EventMaterialList = {}
    m_EventRicherList   = {}
    m_EventPetList      = {}
    m_EventTalismanList = {}
    m_EventEquipList    = {}
    m_CurEventId        = 1
    m_curFocusIndex     = 0
    for id,dataevent in pairs(ConfigManager.getConfig("growup")) do
        if dataevent.growtype == cfg.active.GrowupType.UPGRADE  then
            m_EventUpgradeList[#m_EventUpgradeList+1] = dataevent
        elseif dataevent.growtype == cfg.active.GrowupType.MATERIAL  then
            m_EventMaterialList[#m_EventMaterialList+1] = dataevent
        elseif dataevent.growtype == cfg.active.GrowupType.RICHER  then
            m_EventRicherList[#m_EventRicherList+1] = dataevent
        elseif dataevent.growtype == cfg.active.GrowupType.PET  then
            m_EventPetList[#m_EventPetList+1] = dataevent
        elseif dataevent.growtype == cfg.active.GrowupType.TALISMAN  then
            m_EventTalismanList[#m_EventTalismanList+1] = dataevent
        elseif dataevent.growtype == cfg.active.GrowupType.EQUIP  then
            m_EventEquipList[#m_EventEquipList+1] = dataevent
        end
    end
    m_AllEventList = {m_EventUpgradeList, m_EventMaterialList, m_EventRicherList, m_EventPetList, m_EventTalismanList, m_EventEquipList}

    for i = 1, #UIGROUP_PROGRESS_NAME do
        local item = fields.UIList_Left:AddListItem()
        item:SetText("UILabel_Theme", LocalString.ProgressType[i])
        item.Id = i

        EventHelper.SetClick(item, function()
            m_CurEventId = item.Id
            m_curFocusIndex = 0
            refresh()
        end)
    end

    if  #UIGROUP_PROGRESS_NAME > 0 then
        fields.UIList_Left:SetSelectedIndex(0)
    end

    EventHelper.SetWrapListRefresh(fields.UIList_Entry.gameObject:GetComponent("UIWrapContentList"), function(item, itemi, i)
        if i > #m_AllEventList[m_CurEventId] then return end
        local dataevent = m_AllEventList[m_CurEventId][i]
        item.Data = dataevent
        item.Controls["UILabel_AcitvityName"].text = dataevent.name
        item.Controls["UILabel_Descrip"].text = dataevent.desc
        item.Controls["UIButton_Go"].isEnabled = (dataevent.uientry ~= nil and dataevent.uientry ~= "" and dataevent.uientry ~= "null")

        EventHelper.SetClick(item.Controls["UIButton_Go"], function()
            local wrapContent = fields.UIList_Entry.gameObject:GetComponent("UIWrapContentList")
            m_curFocusIndex = wrapContent:GetCenterOnIndex()

            uimanager.GoToDlg(dataevent.uientry,dataevent.uitabindex,dataevent.uitabindex02,nil)           
        end)
    end)
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
}
