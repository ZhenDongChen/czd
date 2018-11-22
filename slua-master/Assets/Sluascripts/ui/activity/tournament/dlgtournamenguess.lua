local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager 	  = require "cfg.configmanager"
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local EventHelper       = UIEventListenerHelper

local name
local gameObject
local fields

local m_IsShow = false

local m_LabelColumnName
local m_LabelColumnStrength
local m_LabelColumnVotes
local m_LabelColumnOther
local m_UIListGuess
local m_UIListFaction

local m_CurrentFaction
local m_CurrentGuessRole

local function reset()
    m_CurrentFaction = nil
    m_CurrentGuessRole = nil
    m_IsShow = false
end

local function UpdateGuessList()
    if true~=m_IsShow then
        return
    end

    for i=1,m_UIListGuess.Count do
        local listItem = m_UIListGuess:GetItemByIndex(i-1)
        local roleInfo = listItem.Data
        if listItem.Checkbox and roleInfo then
            if m_CurrentGuessRole then
                if m_CurrentGuessRole == roleInfo then
                    listItem.Checkbox.gameObject:SetActive(true)
                    listItem.Checked = true
                    listItem.Checkbox.enabled = false
                else
                    listItem.Checkbox.gameObject:SetActive(false)
                    listItem.Checked = false
                    listItem.Checkbox.enabled = false
                end
            else
                listItem.Checkbox.gameObject:SetActive(true)
                listItem.Checked = false
                listItem.Checkbox.enabled = true
            end
        else
            -- printyellow("[dlgtournamenguess:UpdateGuessList] listItem.Checkbox NIL!")
        end
    end
end

local function OnConfirmGuessOK()
    -- printyellow("[dlgtournamenguess:OnConfirmGuessOK] On Confirm Guess OK!")
    UpdateGuessList()
    if m_CurrentGuessRole then
        TournamentManager.send_CGuess(m_CurrentFaction, m_CurrentGuessRole.roleid)
    end
end

local function OnConfirmGuessCancel()
    -- printyellow("[dlgtournamenguess:OnConfirmGuessCancel] On Confirm Guess Cancel!")
    m_CurrentGuessRole = nil
    UpdateGuessList()
end

local function OnGuessToggle(uitoggle, value)
    -- printyellow("[dlgtournamenguess:OnGuessToggle] On GuessToggle", uitoggle.transform.parent.parent.name, value)
    if value then
        local selectedListItem
        --disable all toggles
        for i=1, m_UIListGuess.Count do
            local listItem = m_UIListGuess:GetItemByIndex(i-1)
            if listItem and listItem.Checkbox then
                if listItem.Checkbox == uitoggle then
                    selectedListItem = listItem
                end
                listItem.Checkbox.enabled = false
            end
        end

        --pop up confirm
        m_CurrentGuessRole = nil
        if selectedListItem and selectedListItem.Data then
            m_CurrentGuessRole = selectedListItem.Data
            --local log = string.format("[dlgtournamenguess:OnGuessToggle] m_CurrentGuessRole = %s, m_CurrentGuessRole.name = %s.", m_CurrentGuessRole, m_CurrentGuessRole.name)
            -- printyellow(log)
            local confirmContent = string.format(LocalString.Tournament_Guess_Confirm, m_CurrentGuessRole.name)
            UIManager.ShowAlertDlg({immediate = true,content = confirmContent, callBackFunc = OnConfirmGuessOK, callBackFunc1 = OnConfirmGuessCancel})
        end
    end
end

local function refresh(msg)
    --local log = string.format("[dlgtournamenguess:refresh] m_UIListGuess = %s, msg = %s, m_CurrentFaction = %s, msg.profession = %s.", m_UIListGuess, msg, m_CurrentFaction, msg.profession)
    -- printyellow(log)

    --[[
    --test
    if nil == msg then
        printyellow("[dlgtournamenguess:refresh] msg NIL!")
    end
    msg.roles = {
        {roleid = 1, name="1", combatpower=1,beguessnum=1},
        {roleid = 2, name="2", combatpower=2,beguessnum=2},
        {roleid = 3, name="3", combatpower=3,beguessnum=3},
        {roleid = 4, name="4", combatpower=4,beguessnum=4},
    }
    --]]

    if m_UIListGuess and msg and m_CurrentFaction == msg.profession then
        m_UIListGuess:Clear()
        local guessroleid = TournamentInfo.GetGuessRoleid()
        if msg.roles and #msg.roles>0 then
            for i=1,#msg.roles do
                local roleinfo = msg.roles[i]
                --printyellow("[dlgtournamenguess:refresh] adding guess role:", roleinfo.name)
                local listItem = m_UIListGuess:AddListItem()
                local UILabel_Name = listItem.Controls["UILabel_ListWithRadio_1"]
                local UILabel_Strength = listItem.Controls["UILabel_ListWithRadio_2"]
                local UILabel_Votes = listItem.Controls["UILabel_ListWithRadio_3"]
                local UILabel_Other = listItem.Controls["UILabel_ListWithRadio_4"]
                UILabel_Name.text = roleinfo.name
                UILabel_Strength.text = roleinfo.combatpower
                UILabel_Votes.text = roleinfo.beguessnum
                if UILabel_Other then
                    UILabel_Other.gameObject:SetActive(false)
                end
                listItem.Data = roleinfo

                --set guess state
                if listItem.Checkbox then
                    if guessroleid and guessroleid>0 then
                        if guessroleid == roleinfo.roleid then
                            listItem.Checkbox.gameObject:SetActive(true)
                            listItem.Checked = true
                            listItem.Checkbox.enabled = false
                        else
                            listItem.Checkbox.gameObject:SetActive(false)
                            listItem.Checked = false
                            listItem.Checkbox.enabled = false
                        end
                    else
                        listItem.Checkbox.gameObject:SetActive(true)
                        listItem.Checked = false
                        listItem.Checkbox.enabled = true
                    end
                    --printyellow("[dlgtournamenguess:refresh] adding toggle event listener for:", roleinfo.name)
                    EventHelper.SetToggle(listItem.Checkbox, OnGuessToggle)
                end
            end
        end
    else
    end
end

local function update()
end

local function hide()
    --printyellow("[dlgtournamenguess:hide] hide dlgtournamenguess!")
    reset()
end

local function destroy()
end

local function showFactions()
    --printyellow("[dlgtournamentguess:showFactions] show Faction List!")
    local selectFaction
    if m_UIListFaction then
        local professions = ConfigManager.getConfig("profession")
        if professions then
            local selectFactionIndex = 1
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

            m_UIListFaction:SetSelectedIndex(selectFactionIndex-1)
        else
            -- printyellow("[dlgtournamentguess:showFactions] professions null!")
        end
    else
        -- printyellow("[dlgtournamentguess:showFactions] m_UIListFaction null!")
    end
    return selectFaction
end

local function showGuessList(profession)
    --local log = string.format("[dlgtournamenguess:showGuessList] m_UIListGuess = %s, profession = %s, m_CurrentFaction = %s.", m_UIListGuess, profession, m_CurrentFaction)
    -- printyellow(log)
    --printyellow("[dlgtournamentguess:showGuessList] show Faction Guess List!")

    if m_UIListGuess and profession and profession~=m_CurrentFaction then
        m_UIListGuess:Clear()
        m_CurrentFaction = profession
        TournamentManager.send_CGetPreselectionRoleList(profession)
    end
end

local function OnFactionListItemClicked(listitem)
    showGuessList(listitem.Data)
end

local function registereventhandler()
    --printyellow("[dlgtournamenguess:registereventhandler]dlgtournamenguess registereventhandler!")

    EventHelper.SetListClick(m_UIListFaction,OnFactionListItemClicked)
end

local function InitPanels()
    fields.UIGroup_ListWithRadio.gameObject:SetActive(true)

    m_UIListGuess = fields.UIList_ListWithRadio
    m_UIListFaction = fields.UIList_LogRadioButton

    m_LabelColumnName = fields.UILabel_ListTitle_1
    if m_LabelColumnName then
        m_LabelColumnName.text = LocalString.Tournament_Guess_Column_1
    end
    m_LabelColumnStrength = fields.UILabel_ListTitle_2
    if m_LabelColumnStrength then
        m_LabelColumnStrength.text = LocalString.Tournament_Guess_Column_2
    end
    m_LabelColumnVotes = fields.UILabel_ListTitle_3
    if m_LabelColumnVotes then
        m_LabelColumnVotes.text = LocalString.Tournament_Guess_Column_3
    end
    m_LabelColumnOther = fields.UILabel_ListTitle_4
    if m_LabelColumnOther then
        m_LabelColumnOther.text = LocalString.Tournament_Guess_Column_4
    end
end

local function show(params)
    --printyellow("[dlgtournamenguess:show] show dlgtournamenguess!")   
    fields.UILabel_Title.text = LocalString.Tournament_Guess_Title
    m_IsShow = true
    if nil == params.msg then
        InitPanels()
        registereventhandler()
        local selectFaction = showFactions()
        showGuessList(selectFaction)
    else
        refresh(params.msg)
    end
end

local function init(pname, gpameobject, pfields)
    name = "dlgtournamenguess"
    gameObject = gpameobject
    fields = pfields
end

return{
    show = show,
    init = init,
    destroy = destroy,
    refresh = refresh,
    update = update,
    hide = hide,
}
