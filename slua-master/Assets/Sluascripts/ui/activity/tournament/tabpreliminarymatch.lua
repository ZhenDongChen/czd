local unpack        = unpack
local print         = print
local UIManager       = require("uimanager")
local EventHelper       = UIEventListenerHelper
local ConfigManager= require("cfg.configmanager")
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local Utils             = require "common.utils"
local Player=require("character.player")
local Define=require("define")
local PlayerRole=require("character.playerrole"):Instance()
local colorutil = colorutil
local name
local gameObject
local fields

local m_TournamentCfg
local m_StageList

local internaltime = 0.2

local function hide()
    --printyellow("[tabpreliminarymatch:hide]tabpreliminarymatch hide!")
end

local function OnUIButton_Close()
    -- printyellow("[tabpreliminarymatch:OnUIButton_Close] UIButton_Close clicked!")
    UIManager.hide("activity.tournament.tabpreliminarymatch")
end

local function reset()
end

local function SetColorText(uilabel, text, enable, iscurrent)
    if uilabel and text then
        if true==enable then
            if true==iscurrent then
                uilabel.text = colorutil.GetColorStr(colorutil.ColorType.Yellow, text and text or "")
            else
                uilabel.text = colorutil.GetColorStr(colorutil.ColorType.Green, text and text or "")
            end
        else
            uilabel.text = colorutil.GetColorStr(colorutil.ColorType.Gray, text and text or "")
        end
    end
end

local function SetStageText(index, duration, stage, foename, enable, iscurrent)
    local stageListitem = fields.UIList_Match:GetItemByIndex(index)
	printyellow(stageListitem.transform.name..tostring(index+1)..tostring(stage) )
    if stageListitem then        
       -- printyellow(string.format("[tabpreliminarymatch:SetStageText] show UIList_Match at index[%s]: duration=[%s], stage=[%s], foename=[%s].", index, duration, stage, foename))

        --time
        local UILabel_Time = stageListitem.Controls["UILabel_Time"]
        if UILabel_Time then
            UILabel_Time.text = duration and duration or ""
            SetColorText(UILabel_Time, duration, enable, iscurrent)
        end

        --stage
        local UILabel_Type = stageListitem.Controls["UILabel_Type"]
        if UILabel_Type then
            UILabel_Type.text = stage and stage or ""
            SetColorText(UILabel_Type, stage, enable, iscurrent)
        end

        --foename
        local UILabel_PlayerName = stageListitem.Controls["UILabel_PlayerName"]
        if UILabel_PlayerName then
            UILabel_PlayerName.text = foename and foename or ""
            SetColorText(UILabel_PlayerName, foename, enable, iscurrent)
        end

        --progress
        local UISprite_Sign = stageListitem.Controls["UISprite_Sign"]
        if UISprite_Sign then
            UISprite_Sign.gameObject:SetActive(enable)
        end
        local UISprite_Progress = stageListitem.Controls["UISprite_Progress"]
        if UISprite_Progress then
            UISprite_Progress.gameObject:SetActive(enable)
        end  
    else
        print("[ERROR][tabpreliminarymatch:SetStageText] UIList_Match listitem nil at index:", index)
    end
end


local function AddWeekTime(weektime, seconds)
    local newweektime = {}
    if weektime and seconds then
        newweektime.weekday = weektime.weekday
        newweektime.hour = weektime.hour + math.floor(seconds/3600)
        newweektime.minute = weektime.minute + math.floor(seconds/60)%60
        newweektime.second = weektime.second + seconds%60
    end 
    return newweektime
    
    --[[
    <field name="weekday" type="int"/> 1 - 7 ��Ӧ��һ������
	<field name="hour" type="int"/>
	<field name="minute" type="int"/>
	<field name="second" type="int"/>
    --]]
end

local function GetRoundTime(roundindex)
    local roundtime = 0
    local roundTimeControler = m_TournamentCfg.battletime[roundindex]
    if roundTimeControler then
        roundtime = roundTimeControler.wait+roundTimeControler.battle+roundTimeControler.relax
    end
    return roundtime
end

local function GetRoundInfo(round)
    if round and round>0 then    
        TournamentManager.send_CGetBattleRound(round, PlayerRole.m_Profession)
    end
end

local function GetWeekTimeDurationText(startweektime, endweektime)
    local duration = ""
    if startweektime and endweektime then
        duration = string.format(LocalString.Tournament_Duration, TournamentManager.GetWeektimeText(startweektime), TournamentManager.GetWeektimeText(endweektime))
    end
    return duration
end

local function SetRoundText(round, foename, enable)
    if round>0 then
        --time
        local startweektime = m_TournamentCfg.battleopen
        if round>1 then
            for i=1,round-1 do
                startweektime = AddWeekTime(startweektime, GetRoundTime(i))
            end        
        end
        local endweektime = AddWeekTime(startweektime, GetRoundTime(round))
        local duration = GetWeekTimeDurationText(startweektime, endweektime)

        --set label
		printyellow("[SetRoundText:GetCurrentRound]"..TournamentInfo.GetCurrentRound())
        SetStageText(round+3-1, duration, LocalString.Tournament_Schedule_Finals[round], foename, enable, round==TournamentInfo.GetCurrentRound())    
    end
end

local function UpdateStages()
   printyellow(string.format("[tabpreliminarymatch:UpdateStages] TournamentInfo.GetCurrentStage()=[%s], TournamentInfo.GetCurrentRound()=[%s].", TournamentInfo.GetCurrentStage(), TournamentInfo.GetCurrentRound() ))

    fields.UILabel_Title.text = LocalString.Tournament_My_Schedule
    local duration = ""
    local enable = false

    --enroll
    enable = TournamentInfo.GetCurrentStage()>=cfg.huiwu.Stage.BEGIN_ENROLL
    duration = GetWeekTimeDurationText(m_TournamentCfg.enrollopen, m_TournamentCfg.enrollend)
    SetStageText(0, duration, LocalString.Tournament_Schedule_Enroll, "", enable, TournamentInfo.GetCurrentStage()==cfg.huiwu.Stage.BEGIN_ENROLL)
    
    --preselect 1
    enable = TournamentInfo.GetCurrentStage()>=cfg.huiwu.Stage.BEGIN_PRESELECT1
    duration = GetWeekTimeDurationText(m_TournamentCfg.preselectopen1, m_TournamentCfg.preselectend1)
    SetStageText(1, duration, LocalString.Tournament_Schedule_Preselect1, "", enable, TournamentInfo.GetCurrentStage()==cfg.huiwu.Stage.BEGIN_PRESELECT1)

    --preselect 2
    enable = TournamentInfo.GetCurrentStage()>=cfg.huiwu.Stage.BEGIN_PRESELECT2
    duration = GetWeekTimeDurationText(m_TournamentCfg.preselectopen2, m_TournamentCfg.preselectend2)
    SetStageText(2, duration, LocalString.Tournament_Schedule_Preselect2, "", enable, TournamentInfo.GetCurrentStage()==cfg.huiwu.Stage.BEGIN_PRESELECT2)
    
    --rounds
    for round=1,6 do
        SetRoundText(round, "", false)
        GetRoundInfo(round)
    end
end

local function show()
    --printyellow("[tabpreliminarymatch:show]tabpreliminarymatch show!")
    reset()
    TournamentInfo.SetNewSchedule(false)
    UpdateStages()
end

local function SetFoeName(msg)
    if msg.profession==PlayerRole.m_Profession and msg.battles and #msg.battles>0 then
        local foename
        local myname = PlayerRole.m_Name
        for i=1,#msg.battles do
            local battle = msg.battles[i]            
            if battle and myname then
                if battle.role1.name==myname then
                    foename = IsNullOrEmpty(battle.role2.name) and LocalString.Tournament_Round_Bye or battle.role2.name
                elseif battle.role2.name==myname then
                    foename = IsNullOrEmpty(battle.role1.name) and LocalString.Tournament_Round_Bye or battle.role1.name
                end
            end
        end

        if foename then
            SetRoundText(msg.round, foename, true)
        end
    end
end

local function on_SGetBattleRound(msg)
    printyellow("[on_SGetBattleRound] set Term stage:", msg.stage)
	printyellow("[on_SGetBattleRound] set Term roundindex:", msg.roundindex)
	printyellow("[on_SGetBattleRound] set Term round:", msg.round)
    if UIManager.isshow("activity.tournament.tabpreliminarymatch") then
        SetFoeName(msg)
    end
end

local function update()
end

local function registereventhandler()
    --printyellow("[tabpreliminarymatch:registereventhandler]tabpreliminarymatch registereventhandler!")
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
end

local function init(params)
    --printyellow("[tabpreliminarymatch:init]tabpreliminarymatch init!")
    name, gameObject, fields    = unpack(params)
    
    m_TournamentCfg  = ConfigManager.getConfig("huiwu")
    if m_TournamentCfg == nil then
        -- printyellow("[tabtournament:init] m_TournamentCfg null!")
    end

    registereventhandler()
end

return{
    init = init,
    show = show,
    hide = hide,
    update = update,
    UpdateStages = UpdateStages,
    on_SGetBattleRound = on_SGetBattleRound,
}
