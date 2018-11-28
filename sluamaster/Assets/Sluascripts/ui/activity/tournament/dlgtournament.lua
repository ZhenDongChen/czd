local unpack        = unpack
local print         = print
local timeutils         = timeutils
local math = math
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local LimitTimeManager       = require("limittimemanager")
local CfgManager 	  = require "cfg.configmanager"
local DlgDialogBox_ListWithRadio = require"ui.common.dlgdialogbox_listwithradio"
local DlgDialogBox_ListWithTab = require"ui.common.dlgdialogbox_listwithtab"

local fields
local name
local gameObject

local function OnUIButton_Guess()
    -- printyellow("[dlgtournament:OnUIButton_Guess] UIButton_Guess clicked!")
    UIManager.show("common.dlgdialogbox_listwithradio", {type = DlgDialogBox_ListWithRadio.DlgType.TournamentGuess})
end

local function OnConfirmJoinOK()
    -- printyellow("[dlgtournament:OnConfirmJoinOK] On Confirm OK!")
    if TournamentInfo.GetRoleRoundOpponent() and TournamentInfo.GetRoleRoundOpponent()~="" then
        TournamentManager.send_CEnterBattleEctype()
    end
end

local function OnConfirmJoinCancel()
    -- printyellow("[dlgtournament:OnConfirmJoinCancel] On Confirm Cancel!")
end

local function OnUIButton_Contest()
    -- printyellow("[dlgtournament:OnUIButton_Contest] UIButton_Contest clicked!")
    
    if TournamentInfo.GetCurrentStage() == cfg.huiwu.Stage.BEGIN_BATTLE 
        and TournamentInfo.GetCurrentRoundStage() == cfg.huiwu.RoundStage.ROUND_PREPARE 
        and not TournamentManager.IsInTournamentEctype() then

        -- local log = string.format("[dlgtournament:OnUIButton_Contest] TournamentInfo.GetRoleRound()=%s, TournamentInfo.GetCurrentRound()=%s, TournamentInfo.GetCurrentRoundStage()=%s.", TournamentInfo.GetRoleRound(), TournamentInfo.GetCurrentRound(), TournamentInfo.GetCurrentRoundStage())
        -- printyellow(log)
        if TournamentInfo.GetRoleRound() ~= TournamentInfo.GetCurrentRound() then
            --show vs
            UIManager.show("common.dlgdialogbox_listwithtab", {type = DlgDialogBox_ListWithTab.DlgType.TournamentVS, round = TournamentInfo.GetCurrentRound()})
        elseif TournamentInfo.GetCurrentRoundStage() == cfg.huiwu.RoundStage.ROUND_PREPARE then
            --show opponent
            if TournamentInfo.GetRoleRoundOpponent() and TournamentInfo.GetRoleRoundOpponent()~="" then
                local confirmContent1 = string.format(LocalString.Tournament_Join_Confirm1, TournamentInfo.GetRoleRoundOpponent(), TournamentInfo.GetRoleRoundOpponentStrength())
                UIManager.ShowAlertDlg({immediate = true,content = confirmContent1, callBackFunc = OnConfirmJoinOK, callBackFunc1 = OnConfirmJoinCancel, time=TournamentInfo.GetRoleRoundBeginTime()})
            else
                UIManager.ShowAlertDlg({immediate = true,content = LocalString.Tournament_Join_Confirm2, callBackFunc = OnConfirmJoinOK, callBackFunc1 = OnConfirmJoinCancel})
            end
        else
            fields.UIGroup_Join.gameObject:SetActive(false)
        end
    else
        fields.UIGroup_Join.gameObject:SetActive(false)
    end
end

local function LeaveEctype()
    TournamentManager.send_CLeaveMap()
end

local function OnUIButton_RequestLeave()
    -- printyellow("[dlgtournament:OnUIButton_RequestLeave] UIButton_RequestLeave clicked!")

    local tb = {}
    tb.immediate = true
    tb.title = LocalString.EctypeText.LeaveWarningTitle
    tb.content = LocalString.EctypeText.LeaveWarningContent
    tb.callBackFunc = LeaveEctype
    UIManager.ShowAlertDlg(tb)
end

local function registereventhandler()
    --printyellow("[dlgtournament:registereventhandler]dlgtournament registereventhandler!")

    EventHelper.SetClick(fields.UIButton_Guess, OnUIButton_Guess)
    EventHelper.SetClick(fields.UIButton_Contest, OnUIButton_Contest)
    EventHelper.SetClick(fields.UIButton_RequestLeave, OnUIButton_RequestLeave)
end

local function init(params)
    --printyellow("[dlgtournament:init]dlgtournament init!")

    name, gameObject, fields    = unpack(params)
    registereventhandler()
end

local function UpdatePrepareCountdown()
    if TournamentInfo.GetCurrentRoundStage() == cfg.huiwu.RoundStage.ROUND_PREPARE then

        if TournamentManager.IsInTournamentEctype() then
            if TournamentInfo.GetRoleRoundBeginTime() and TournamentInfo.GetRoleRoundBeginTime()>0 then
                fields.UIGroup_Countdown.gameObject:SetActive(true)
                local leftsecond = math.ceil(TournamentInfo.GetRoleRoundBeginTime())
                if 1== leftsecond then
                    fields.UILabel_01.gameObject:SetActive(true)
                    fields.UILabel_02.gameObject:SetActive(false)
                    fields.UILabel_03.gameObject:SetActive(false)
                    fields.UILabel_PrepareTime.gameObject:SetActive(false)
                elseif 2== leftsecond then
                    fields.UILabel_01.gameObject:SetActive(false)
                    fields.UILabel_02.gameObject:SetActive(true)
                    fields.UILabel_03.gameObject:SetActive(false)
                    fields.UILabel_PrepareTime.gameObject:SetActive(false)
                elseif 3== leftsecond then
                    fields.UILabel_01.gameObject:SetActive(false)
                    fields.UILabel_02.gameObject:SetActive(false)
                    fields.UILabel_03.gameObject:SetActive(true)
                    fields.UILabel_PrepareTime.gameObject:SetActive(false)
                else
                    fields.UILabel_01.gameObject:SetActive(false)
                    fields.UILabel_02.gameObject:SetActive(false)
                    fields.UILabel_03.gameObject:SetActive(false)
                    fields.UILabel_PrepareTime.gameObject:SetActive(true)
                    local countdown = string.format(LocalString.Tournament_Round_Remain_Time, leftsecond)
                    fields.UILabel_PrepareTime.text = countdown
                end
            else
                fields.UIGroup_Countdown.gameObject:SetActive(false)
            end
        else
        end
    else
        fields.UIGroup_Countdown.gameObject:SetActive(false)
        fields.UIGroup_Join.gameObject:SetActive(false)
    end
end

local function UpdateJoinCountdown()
    if TournamentInfo.GetCurrentStage() == cfg.huiwu.Stage.BEGIN_BATTLE 
        and TournamentInfo.GetCurrentRoundStage() == cfg.huiwu.RoundStage.ROUND_PREPARE 
        and not TournamentManager.IsInTournamentEctype() then

        fields.UIGroup_Join.gameObject:SetActive(true)
        if TournamentInfo.GetRoleRoundBeginTime()>0 then
            --printyellow("[dlgtournament:UpdateJoinCountdown] TournamentInfo.GetRoleRoundBeginTime() = ", TournamentInfo.GetRoleRoundBeginTime())
            local countdown = math.ceil(TournamentInfo.GetRoleRoundBeginTime())
            fields.UILabel_Time01.text = timeutils.getDateTimeString(countdown,"mm:ss")
        else
            fields.UILabel_Time01.text = ""              
        end
    else
        fields.UIGroup_Join.gameObject:SetActive(false)
    end
end

local function UpdateFightCountdown()
    if TournamentManager.IsInTournamentEctype() then
        fields.UIGroup_Fighting.gameObject:SetActive(true)

        --use dlguiectype countdown
        fields.UISprite_CountDownBG.gameObject:SetActive(false)
        fields.UIButton_RequestLeave.gameObject:SetActive(false)

        --[[if TournamentInfo.GetRoleRoundEctypeFightRemainTime() and TournamentInfo.GetRoleRoundEctypeFightRemainTime()>0 then
            fields.UILabel_FightTime.text = timeutils.getDateTimeString(TournamentInfo.GetRoleRoundEctypeFightRemainTime(),"hh:mm:ss")
        else
            fields.UILabel_FightTime.text = timeutils.getDateTimeString(0,"hh:mm:ss")
        end--]]
    end
end

local function UpdateGuess()
    --printyellow(string.format("[dlgtournament:UpdateGuess] TournamentInfo.GetCurrentStage()=%s!", TournamentInfo.GetCurrentStage() ))
    if TournamentInfo.GetCurrentStage() == cfg.huiwu.Stage.END_PRESELECT2 then
        if TournamentInfo.GetRemainGuessTime()>0 then
            --printyellow("[dlgtournament:UpdateGuess] show UIGroup_Guess!")
            fields.UIGroup_Guess.gameObject:SetActive(true)
            local countdown = math.ceil(TournamentInfo.GetRemainGuessTime())
            fields.UILabel_Time02.text = timeutils.getDateTimeString(countdown,"mm:ss")
        else
            --printyellow(string.format("[dlgtournament:UpdateGuess] hide UIGroup_Guess: TournamentInfo.GetRemainGuessTime()[%s]<=0!", TournamentInfo.GetRemainGuessTime() ))
            fields.UIGroup_Guess.gameObject:SetActive(false)
        end
    else
        --printyellow(string.format("[dlgtournament:UpdateGuess] hide UIGroup_Guess: TournamentInfo.GetCurrentStage()[%s]~=cfg.huiwu.Stage.END_PRESELECT2!", TournamentInfo.GetCurrentStage() ))
        fields.UIGroup_Guess.gameObject:SetActive(false)
    end
end

local function UpdateDamage()
    selfDamage = TournamentInfo.GetSelfDamage()
    foeDamage = TournamentInfo.GetFoeDamage()
    -- printyellow(string.format("[dlgtournament:UpdateDamage] selfDamage=%s, foeDamage=%s!", selfDamage, foeDamage))

    fields.UILabel_MyScore.text = selfDamage
    fields.UILabel_EnemyScore.text = foeDamage
end

local function update()
    --printyellow("[dlgtournament:update] update!")
    UpdateGuess()
    --UpdatePrepareCountdown()
    UpdateFightCountdown()
    UpdateJoinCountdown()
end

local function UpdateDlg()
    -- printyellow("[dlgtournament:updatedlg] update dlgtournament!")

    if TournamentInfo.NeedShowDlgTournament() then
        --guess
        UpdateGuess()

        if TournamentInfo.GetCurrentStage() == cfg.huiwu.Stage.BEGIN_BATTLE then
            --join
            UpdateJoinCountdown()

            --ectype
            if TournamentManager.IsInTournamentEctype() then
                --prepare
                --UpdatePrepareCountdown()

                fields.UIGroup_Fighting.gameObject:SetActive(true)
                --fight
                UpdateFightCountdown()

                --statistic

                --leave
                fields.UIButton_RequestLeave.gameObject:SetActive(true)
            else
                fields.UIGroup_Countdown.gameObject:SetActive(false)
                fields.UIGroup_Fighting.gameObject:SetActive(false)
            end
        else
            fields.UIGroup_Fighting.gameObject:SetActive(false)
            fields.UIGroup_Join.gameObject:SetActive(false)
            fields.UIGroup_Countdown.gameObject:SetActive(false)
        end
    else
        if UIManager.isshow("activity.tournament.dlgtournament") then
            -- printyellow("[dlgtournament:UpdateDlg] hide dlgtournament!")
            UIManager.hide("activity.tournament.dlgtournament")
        end
    end

end

local function refresh()
    --printyellow("[dlgtournament:refresh]dlgtournament refresh!")
    UpdateDlg()
end

local function initpanels()
    --printyellow("[dlgtournament:initpanels]dlgtournament initpanels!")

    fields.UIGroup_Guess.gameObject:SetActive(false)
    fields.UIGroup_Fighting.gameObject:SetActive(false)
    fields.UIGroup_Join.gameObject:SetActive(false)
    fields.UIGroup_Countdown.gameObject:SetActive(false)
    fields.UILabel_CountDown.gameObject:SetActive(false)

    --test
    --fields.UIGroup_Guess.gameObject:SetActive(true)
end

local function show()
    --printyellow("[dlgtournament:show]dlgtournament show!")
    initpanels()
    UpdateDamage()
end

local function hide()
    -- printyellow("[dlgtournament:hide]dlgtournament hide!")
end

local function uishowtype()
    return UIShowType.Refresh
end

return{
    show=show,
    hide=hide,
    init=init,
    refresh=refresh,
    update = update,
    uishowtype=uishowtype,
    UpdateDlg = UpdateDlg,
    UpdateDamage = UpdateDamage,
}
