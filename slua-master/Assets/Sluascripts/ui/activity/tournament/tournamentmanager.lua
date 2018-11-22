local NetWork=require("network")
local UIManager=require("uimanager")
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local DlgDialogBox_ListWithRadio = require("ui.common.dlgdialogbox_listwithradio")
local Dlgdialogbox_listwithtab = require("ui.common.dlgdialogbox_listwithtab")
local EctypeManager = require "ectype.ectypemanager"
local CharacterManager  = require("character.charactermanager")
local PlayerRole=require("character.playerrole"):Instance()
local CharacterType     = defineenum.CharacterType
local ConfigManager 	  = require "cfg.configmanager"
local timeutils         = timeutils

local m_TournamentCfg

local function CanEnroll()
    --printyellow(string.format("[tournamentmanager:CanEnroll] m_TournamentCfg.requirelevel =%s,PlayerRole.m_Level ==%s.", m_TournamentCfg.requirelevel.level, PlayerRole.m_Level))
    return TournamentInfo.CanEnroll()
end

local function send_CEnroll()
    local msg=lx.gs.activity.huiwu.msg.CEnroll()
    --printyellow("[tournamentmanager:send_CEnroll] send:", msg)
    NetWork.send(msg)
end

local function on_SEnroll(msg)
    --printyellow("[tournamentmanager:on_SEnroll] receive:", msg)
    TournamentInfo.SetEnroll(true)
    if UIManager.isshow("activity.tournament.tabtournament") then
        UIManager.call("activity.tournament.tabtournament","UpdateEnrollInfo")
        UIManager.call("dlgdialog","RefreshRedDot","ectype.dlgentrance_copy")
        UIManager.call("ectype.weekend","RefreshRedDot")
    end
end

local function send_CWorship(termid, profession)
    local msg=lx.gs.activity.huiwu.msg.CWorship({termid = termid, profession = profession})
    --printyellow("[tournamentmanager:send_CWorship] send:", msg)
    NetWork.send(msg)
end

local function on_SWorship(msg)
    --printyellow("[tournamentmanager:on_SWorship] receive:", msg)
    if UIManager.isshow("activity.tournament.tabtournament") then
        UIManager.call("activity.tournament.tabtournament","UpdateWorshipInfo",msg)
    end
end

local function send_CGetPreselectionRoleList(profession)
    local msg=lx.gs.activity.huiwu.msg.CGetPreselectionRoleList({profession = profession})
    --printyellow("[tournamentmanager:send_CGetPreselectionRoleList] send:", msg)
    NetWork.send(msg)
end

local function on_SGetPreselectionRoleList(msg)
    --printyellow("[tournamentmanager:on_SGetPreselectionRoleList] receive:", msg)
    --local log = string.format("[tournamentmanager:on_SGetPreselectionRoleList] common.dlgdialogbox_listwithradio.isshow = %s, DlgDialogBox_ListWithRadio = %s, DlgDialogBox_ListWithRadio.currenttype() = %s.", UIManager.isshow("common.dlgdialogbox_listwithradio"), DlgDialogBox_ListWithRadio, DlgDialogBox_ListWithRadio.currenttype())
    --printyellow(log)
    if UIManager.isshow("common.dlgdialogbox_listwithradio") and DlgDialogBox_ListWithRadio and DlgDialogBox_ListWithRadio.currenttype() == DlgDialogBox_ListWithRadio.DlgType.TournamentGuess then
        UIManager.call("common.dlgdialogbox_listwithradio", "refresh", msg)
    end
end

local function send_CLeaveMap()
    local msg=lx.gs.map.msg.CLeaveMap({})
    --printyellow("[tournamentmanager:send_CLeaveMap] send:", msg)
    NetWork.send(msg)
end

local function send_CGuess(profession, roleid)
    local msg=lx.gs.activity.huiwu.msg.CGuess({profession = profession, target = roleid})
    --printyellow("[tournamentmanager:send_CGuess] send:", msg)
    NetWork.send(msg)
end

local function on_SGuess(msg)
    --printyellow("[tournamentmanager:on_SGuess] receive:", msg)
    TournamentInfo.SetGuessRoleid(msg.target)
end

local function send_CGetChampion(termid, profession, context)
    local msg=lx.gs.activity.huiwu.msg.CGetChampion({termid = termid, profession=profession, ctx = context})
    --printyellow("[tournamentmanager:send_CGetChampion] send:", msg)
    NetWork.send(msg)
end

local function on_SGetChampion(msg)
    printyellow("[tournamentmanager:on_SGetChampion] receive:",msg)
    if msg then
        if msg.ctx == cfg.huiwu.HuiWu.CHAMPION_CTX_MAIN and UIManager.isshow("activity.tournament.tabtournament") then
            UIManager.call("activity.tournament.tabtournament","on_SGetChampion",msg)
        elseif msg.ctx == cfg.huiwu.HuiWu.CHAMPION_CTX_CELEBRITY and UIManager.isshow("activity.tournament.dlgtournamentcelebrity") then
            UIManager.call("activity.tournament.dlgtournamentcelebrity","on_SGetChampion",msg)
        end
    end
end

local function send_CGetBattleRound(round, profession)
    local msg=lx.gs.activity.huiwu.msg.CGetBattleRound({round = round, profession = profession})
    printyellow("[tournamentmanager:send_CGetBattleRound] send:", round)
    NetWork.send(msg)
end

local function on_SGetBattleRound(msg)
    --printyellow("[tournamentmanager:on_SGetBattleRound] receive:", msg)
    if UIManager.isshow("common.dlgdialogbox_listwithtab") and Dlgdialogbox_listwithtab and Dlgdialogbox_listwithtab.DlgType.TournamentVS == Dlgdialogbox_listwithtab.currenttype() then
        UIManager.call("common.dlgdialogbox_listwithtab", "refresh", msg)
    end

    if UIManager.isshow("activity.tournament.tabpreliminarymatch") then
        UIManager.call("activity.tournament.tabpreliminarymatch", "on_SGetBattleRound", msg)
    end
end

local function on_SAttendNextBattle(msg)
    --printyellow("[tournamentmanager:on_SAttendNextBattle] receive:", msg)
    TournamentInfo.SetRoleRoundInfo(msg)
end

local function on_SBattleResult(msg)
    --printyellow("[tournamentmanager:on_SBattleResult]", msg)
end

local function send_CEnterBattleEctype()
    local msg=lx.gs.activity.huiwu.msg.CEnterBattleEctype()
    --printyellow("[tournamentmanager:send_CEnterBattleEctype] send:", msg)
    NetWork.send(msg)
end

local function on_STermInfo(msg)
    --printyellow("[tournamentmanager:on_STermInfo] receive:", msg)
    TournamentInfo.SetTermInfo(msg)
    
    if UIManager.isshow("activity.tournament.tabpreliminarymatch") then
        UIManager.call("activity.tournament.tabpreliminarymatch","UpdateStages")
    end
end

local function on_STermStageChange(msg)
    --printyellow("[tournamentmanager:on_STermStageChange] receive:", msg)
    TournamentInfo.SetStageInfo(msg)
    
    if UIManager.isshow("activity.tournament.tabpreliminarymatch") then
        UIManager.call("activity.tournament.tabpreliminarymatch","UpdateStages")
    end
end

local function on_SRoundStage(msg)
    --printyellow("[tournamentmanager:on_SRoundStage] receive:", msg)
    TournamentInfo.SetRoundStageInfo(msg)

    if UIManager.isshow("activity.tournament.tabpreliminarymatch") then
        UIManager.call("activity.tournament.tabpreliminarymatch","UpdateStages")
    end
end

local function on_SLeaveMap(msg)
    --printyellow("[tournamentmanager:on_SLeaveMap] receive:", msg)
    if UIManager.isshow("activity.tournament.dlgtournament") then
        TournamentInfo.UpdateDlgTournament()
    end
end

local function UnRead()
    --printyellow("[tournamentmanager:UnRead] UnRead=", ( CanEnroll() and (false == TournamentInfo.HasEnroll())) )
    return (CanEnroll() and false == TournamentInfo.HasEnroll()) or true==TournamentInfo.HasNewSchedule()
end

local function IsInTournamentEctype()
    if EctypeManager.IsInEctype() then
        local huiwuCfg = ConfigManager.getConfig("huiwu")
        if huiwuCfg then
            return huiwuCfg.ectypeid == EctypeManager.CurrentEctypeId()
        else
            return false
        end
    else
        return false
    end
end

local function send_CEctypeStatistic()
    local msg = map.msg.CEctypeStatistic({})
    --printyellow("[tournamentmanager:send_CEctypeStatistic] send:", msg)
    NetWork.send(msg)
end

local function om_SEctypeStatistic(msg)
    if false == IsInTournamentEctype() then
        return
    end
    --printyellow("[tournamentmanager:om_SEctypeStatistic] receive:", msg)
    local selfdmg = 0
    local foedmg = 0
    for i = 1, #msg.teams do
        local team = msg.teams[i]
        for i = 1, #team.members do
            local memberInfo = team.members[i]
            if PlayerRole.m_Name == memberInfo.name or PlayerRole.m_Name == memberInfo.ownername then
                selfdmg = selfdmg + memberInfo.damage
            else
                foedmg = foedmg + memberInfo.damage
            end
        end
    end
    TournamentInfo.SetStatistic(selfdmg, foedmg)
end

local function on_SEnterHuiWu(msg)
    --printyellow("[tournamentmanager:on_SEnterHuiWu] receive:", msg)
    TournamentInfo.SetHuiwuEctypeInfo(msg)
    send_CEctypeStatistic()
end

local function on_SEndHuiWu(msg)
    --printyellow("[tournamentmanager:on_SEndHuiWu] receive:", msg)
    TournamentInfo.ClearStatistic()

    local content
    if msg.result == 1 then
        content = LocalString.Tournament_Fight_Win
    else
        content = LocalString.Tournament_Fight_Lose
    end
    UIManager.ShowSingleAlertDlg({content=content})
end

local function on_SSkillAttack(msg)
    if IsInTournamentEctype() then
        local attacker = CharacterManager.GetCharacter(msg.attackerid)
        if not attacker then
            return
        end

        if attacker.m_Type == CharacterType.PlayerRole or
            attacker.m_Type == CharacterType.Player or
            attacker.m_Type == CharacterType.Pet then

            local dmg = 0
            for _,attackinfo in pairs(msg.attacks) do
                dmg = dmg+ attackinfo.attack
            end

            local selfdmg = 0
            local foedmg = 0
            if attacker.m_Id == PlayerRole.m_Id or attacker.m_MasterId == PlayerRole.m_Id then
                selfdmg = dmg
            else
                foedmg = dmg
            end
            TournamentInfo.SetStatistic(selfdmg, foedmg)
        end
    end
end

local function on_SDayOver(msg)
    --printyellow("[tournamentmanager:on_SDayOver] receive:", msg)
    if UIManager.isshow("activity.tournament.tabtournament") then
        UIManager.call("activity.tournament.tabtournament","refresh")
    end
end

local function ShowEntrance()
    return TournamentInfo.UpdateDlgTournament()
end

local function IsEntranceShowed()
    return UIManager.isshow("activity.tournament.dlgtournament")
end

local function GetWeektimeText(weektime)
    if nil==weektime then
        return ""
    end

    --week
    local week = LocalString.WeekCapitalForm[weektime.weekday]
    week = week and week or ""
    
    --time
    local time = 0
    time = time + weektime.hour*3600
    time = time + weektime.minute*60
    time = time + weektime.second
    time = timeutils.getDateTimeString(time,"hh:mm")

    --weektime
    local weektimestring = string.format(LocalString.Tournament_Weektime, week, time)
    return weektimestring
end

local function init()
    --printyellow("[tournamentmanager:init] init!")
    m_TournamentCfg  = ConfigManager.getConfig("huiwu")

    TournamentInfo.init()

    NetWork.add_listeners({
        {"lx.gs.activity.huiwu.msg.SEnroll",on_SEnroll},
        {"lx.gs.activity.huiwu.msg.SWorship",on_SWorship},
        {"lx.gs.activity.huiwu.msg.SGetPreselectionRoleList",on_SGetPreselectionRoleList},
        {"lx.gs.activity.huiwu.msg.SGuess",on_SGuess},
        {"lx.gs.activity.huiwu.msg.SGetChampion",on_SGetChampion},
        {"lx.gs.activity.huiwu.msg.SGetBattleRound",on_SGetBattleRound},
        {"lx.gs.activity.huiwu.msg.SAttendNextBattle",on_SAttendNextBattle},
        {"lx.gs.activity.huiwu.msg.SBattleResult",on_SBattleResult},
        {"lx.gs.activity.huiwu.msg.STermInfo",on_STermInfo},
        {"lx.gs.activity.huiwu.msg.STermStageChange",on_STermStageChange},
        {"lx.gs.activity.huiwu.msg.SRoundStage",on_SRoundStage},
        {"lx.gs.map.msg.SLeaveMap",on_SLeaveMap},

        {"map.msg.SEnterHuiWu",on_SEnterHuiWu},
        {"map.msg.SEndHuiWu",on_SEndHuiWu},

        { "map.msg.SSkillAttack",         on_SSkillAttack},
        { "map.msg.SEctypeStatistic", om_SEctypeStatistic},

		{ "lx.gs.role.msg.SDayOver",				on_SDayOver			},
    })
end

return{
    init=init,
    send_CEnroll = send_CEnroll,
    send_CWorship = send_CWorship,
    send_CGetPreselectionRoleList = send_CGetPreselectionRoleList,
    send_CGuess = send_CGuess,
    send_CGetChampion = send_CGetChampion,
    send_CGetBattleRound = send_CGetBattleRound,
    send_CEnterBattleEctype = send_CEnterBattleEctype,
    send_CLeaveMap = send_CLeaveMap,
    send_CEctypeStatistic = send_CEctypeStatistic,

    UnRead = UnRead,
    ShowEntrance = ShowEntrance,
    IsEntranceShowed = IsEntranceShowed,
    IsInTournamentEctype = IsInTournamentEctype,
    CanEnroll = CanEnroll,
    GetWeektimeText = GetWeektimeText,
}
