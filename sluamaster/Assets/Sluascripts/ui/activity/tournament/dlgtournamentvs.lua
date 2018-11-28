local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")

local name
local gameObject
local fields

local m_UIListVS
local m_UIListFaction
local m_UIListRound

local m_CurrentFaction
local m_CurrentRound
local TOTAL_ROUND = 6

local function GetColorName(color, name)
    local colorname = ""
    if color then
        colorname = colorname..color
    end
    if name then
        colorname = colorname..name
    end
    return colorname
end

local function refresh(msg)
    -- printyellow("[dlgtournamentvs:refresh] refresh VSList!")
    if m_UIListVS and msg and m_CurrentFaction ==  msg.profession and m_CurrentRound == msg.round then --
        --printyellow("[dlgtournamentvs:refresh] refresh 1!")
        m_UIListVS:Clear()

        --[[
        --test
        msg = {}
        msg.battles = {
            {role1 = {name = "1"}, role2 = {name = "1"}, state=1},
            {role1 = {name = "2"}, role2 = {name = "2"}, state=0},
            {role1 = {name = "3"}, role2 = {name = "3"}, state=1},
            {role1 = {name = "4"}, role2 = {name = "4"}, state=0},
        }--]]

        if msg.battles and #msg.battles>0 then
            --printyellow("[dlgtournamentvs:refresh] refresh 2!")
            for i=1,#msg.battles do
                --printyellow("[dlgtournamentvs:refresh] refresh 3!")
                local battle = msg.battles[i]
                --print(string.format("[dlgtournamentvs:refresh] battle.role1.name=%s, battle.role2.name=%s!", battle.role1.name, battle.role2.name))
                local listItem = m_UIListVS:AddListItem()
                local UILabel_Player_1 = listItem.Controls["UILabel_Line1"]
                local UILabel_Player_2 = listItem.Controls["UILabel_Line2"]
                local rolename1=""
                local rolename2=""
                if battle.state == cfg.huiwu.BattleState.WIN then
                    rolename1 = GetColorName(LocalString.Tournament_VS_Color_Win, battle.role1.name)
                    rolename2 = GetColorName(LocalString.Tournament_VS_Color_LOSS, battle.role2.name)
                elseif battle.state == cfg.huiwu.BattleState.LOSE then
                    rolename1 = GetColorName(LocalString.Tournament_VS_Color_LOSS ,battle.role1.name)
                    rolename2 = GetColorName(LocalString.Tournament_VS_Color_Win, battle.role2.name)
                else
                    rolename1 = GetColorName(LocalString.Tournament_VS_Color_Other, battle.role1.name)
                    rolename2 = GetColorName(LocalString.Tournament_VS_Color_Other, battle.role2.name)
                end
                UILabel_Player_1.text = rolename1
                UILabel_Player_2.text = rolename2
            end
        end
    end
end

local function ShowVSList(faction, round)
    -- local log = string.format("[dlgtournamentvs:ShowVS] ShowVS faction = %s, round = %s, m_CurrentFaction = %s, m_CurrentRound = %s!", faction, round, m_CurrentFaction, m_CurrentRound)
    -- printyellow(log)
    if m_CurrentFaction~=faction or m_CurrentRound~=round then
        m_CurrentFaction = faction
        m_CurrentRound = round
        m_UIListVS:Clear()
        TournamentManager.send_CGetBattleRound(round, faction)
    end
end

local function ShowRounds(round)
    -- printyellow("[dlgtournamentvs:ShowRounds] ShowRounds!")
    local rounds = LocalString.Tournament_Rounds
    if m_UIListRound and rounds then
        for i=1,#rounds do
            local listItem = m_UIListRound:AddListItem()
            local UILabel_Round = listItem.Controls["UILabel_RadioButton"]
            UILabel_Round.text = rounds[i]
            listItem.Data = i
        end

        if nil == round or round <1 then
            round = 1
        end
        m_UIListRound:SetSelectedIndex(round-1)
    else
        -- printyellow("[dlgtournamentvs:ShowFactions] m_UIListRound null!")
    end
    return round
end

local function ShowFactions()
    -- printyellow("[dlgtournamentvs:ShowFactions] ShowFactions")
    local selectFaction
    local selectFactionIndex
    if m_UIListFaction then
        local professions = ConfigManager.getConfig("profession")
        if professions then
            for i=1,#professions do
                local profession = professions[i]                
                if profession and true==profession.isopen then
                    local listItem = m_UIListFaction:AddListItem()
                    local UILabel_Name = listItem.Controls["UILabel_LogRadioButton"]
                    UILabel_Name.text = profession.name
                    listItem.Data = profession.faction

                    if PlayerRole:Instance().m_Profession == profession.faction then
                        selectFactionIndex = i
                        selectFaction = profession.faction
                    end
                end
            end

            if selectFactionIndex and selectFactionIndex>0 then
                m_UIListFaction:SetSelectedIndex(selectFactionIndex-1)
            end
        else
            -- printyellow("[dlgtournamentvs:ShowFactions] professions null!")
        end
    else
        -- printyellow("[dlgtournamentvs:ShowFactions] m_UIListFaction null!")
    end
    return selectFaction
end

local function OnFactionListItemClicked(listitem)
    ShowVSList(listitem.Data, m_CurrentRound)
end

local function OnRoundListItemClicked(listitem)
    ShowVSList(m_CurrentFaction, listitem.Data)
end

local function registereventhandler()
    --printyellow("[dlgtournamentvs:registereventhandler]dlgtournamenguess registereventhandler!")

    EventHelper.SetListClick(m_UIListFaction,OnFactionListItemClicked)
    EventHelper.SetListClick(m_UIListRound,OnRoundListItemClicked)
end

local function InitPanels()
    m_UIListVS = fields.UIList_Log
    m_UIListFaction = fields.UIList_LogRadioButton
    m_UIListRound = fields.UIList_left
end

local function show(params)
     printyellow("[dlgtournamentvs:show] show!")
    InitPanels()
    registereventhandler()

    fields.UILabel_Title.text = LocalString.Tournament_VS_Title

    local faction = ShowFactions()
    local round = params.round
    round = ShowRounds(round)
    ShowVSList(faction, round)
end

local function init(pname, gpameobject, pfields)
    name = "dlgtournamentvs"
    gameObject = gpameobject
    fields = pfields
end

local function update()
end

local function reset()
    m_CurrentFaction = nil
    m_CurrentRound = nil
end

local function hide()
    reset()
end

local function destroy()
end

return{
    show = show,
    init = init,
    destroy = destroy,
    refresh = refresh,
    update = update,
    hide = hide,
}
