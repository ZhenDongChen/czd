local unpack        = unpack
local print         = print
local math = math
local timeutils         = timeutils
local UIManager       = require("uimanager")
local dlgReward       = require("ui.activity.tournament.dlgtournamentreward")
local EventHelper       = UIEventListenerHelper
local TournamentInfo = require("ui.activity.tournament.tournamentinfo")
local TournamentManager   =require("ui.activity.tournament.tournamentmanager")
local LimitTimeManager       = require("limittimemanager")
local ConfigManager 	  = require "cfg.configmanager"
local DlgDialogBox_ListWithRadio = require"ui.common.dlgdialogbox_listwithradio"
local DlgDialogBox_ListWithTab = require"ui.common.dlgdialogbox_listwithtab"
local BonusManager 	  = require "item.bonusmanager"
local Player=require("character.player")
local Define=require("define")
local PlayerRole=require("character.playerrole"):Instance()

local fields
local name
local gameObject

local m_TournamentCfg
local m_Factions
local m_CurrentTermid
local m_CurrentChampioninfo
local m_Player

local function CanWorship()
    local worshipLimit = LimitTimeManager.GetLimitTime(cfg.cmd.ConfigId.HUIWU, cfg.cmd.CmdId.WORSHIP)
    local worshipTime = 0
    if worshipLimit then
        worshipTime=worshipLimit[1]
    end
    return (m_TournamentCfg.daiylyworshiptimes.num > worshipTime)
end

local function OnUIButton_Worship()
    if m_CurrentTermid>0 and  m_CurrentChampioninfo and CanWorship() then
        TournamentManager.send_CWorship(m_CurrentTermid, m_CurrentChampioninfo.showinfo.profession);
    end
end

local function GetNeighbourFaction(curfaction, isnext)
    local neighbourFaction

    if m_Factions and table.getn(m_Factions)>0 then
        for i=1, #m_Factions do
            if m_Factions[i].faction == curfaction then
                local index
                if isnext then
                    index = ((i+1)>#m_Factions) and 1 or (i+1)
                else
                    index = ((i-1)<1) and #m_Factions or (i-1);
                end

                if true==m_Factions[index].isopen then
                    neighbourFaction = m_Factions[index].faction
                else
                    neighbourFaction = GetNeighbourFaction(m_Factions[index].faction, isnext)
                end
                break
            end
        end
    end

    -- printyellow("[tabtournament:GetNeighbourFaction] m_CurrentFaction = "..m_CurrentFaction..", neighbourFaction = "..neighbourFaction)
    return neighbourFaction
end

local function GetChampionInfo()
    local targetTerm = TournamentInfo.GetCurrentTerm()-1
	local temp = TournamentInfo.GetCurrentStage()
    if TournamentInfo.GetCurrentStage()==cfg.huiwu.Stage.END_BATTLE then
        targetTerm = TournamentInfo.GetCurrentTerm()
    end
    if targetTerm >= 1 then
        --printyellow("[tabtournament:GetChampionInfo] Get ChampionInfo, term = "..targetTerm..", faction = "..m_CurrentFaction)
        TournamentManager.send_CGetChampion(targetTerm, m_CurrentFaction, cfg.huiwu.HuiWu.CHAMPION_CTX_MAIN)
    end
end

local function OnButton_ArrowsLeft()
    -- printyellow("[tabtournament:OnButton_ArrowsLeft] Button_ArrowsLeft clicked!")
    m_CurrentFaction = GetNeighbourFaction(m_CurrentFaction, false)
    GetChampionInfo()
end

local function OnUIButton_ArrowsRight()
    -- printyellow("[tabtournament:OnUIButton_ArrowsRight] ArrowsRight clicked!")
    m_CurrentFaction = GetNeighbourFaction(m_CurrentFaction, true)
    GetChampionInfo()
end

local function OnUIButton_Apply()
    -- printyellow("[tabtournament:OnUIButton_Apply] UIButton_Apply clicked!")
    if m_TournamentCfg.requirelevel.level<=TournamentInfo.GetCurrentLevel() then
        TournamentManager.send_CEnroll()
    else
        UIManager.ShowSingleAlertDlg({content=string.format(LocalString.Tournament_Enroll_Level_Invalid,m_TournamentCfg.requirelevel.level)})        
    end
end

local function OnUIButton_Celebrity()
    -- printyellow("[tabtournament:OnUIButton_Celebrity] UIButton_Celebrity clicked!")
    UIManager.show("activity.tournament.dlgtournamentcelebrity")
end

local function OnUIButton_VSInfo()
    -- printyellow("[tabtournament:OnUIButton_VSInfo] UIButton_VSInfo clicked!")
    UIManager.show("common.dlgdialogbox_listwithtab", {type = DlgDialogBox_ListWithTab.DlgType.TournamentVS, round = TournamentInfo.GetCurrentRound()})

    --test
    --UIManager.show("common.dlgdialogbox_list", {type = DlgDialogBox_ListWithRadio.DlgType.TournamentGuess})
end

local function OnUIButton_Award()
    -- printyellow("[tabtournament:OnUIButton_Award] UIButton_Award clicked!")
    dlgReward.show()
end

local function OnUIButton_Flow()
    -- printyellow("[tabtournament:OnUIButton_Flow] UIButton_Flow clicked!")
    UIManager.show("activity.tournament.tabpreliminarymatch")
    fields.UISprite_Warning.gameObject:SetActive(false)
end

local function registereventhandler()
    printyellow("[tabtournament:registereventhandler]tabtournament registereventhandler!")

    EventHelper.SetClick(fields.UIButton_Worship, OnUIButton_Worship)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, OnButton_ArrowsLeft)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, OnUIButton_ArrowsRight)
    EventHelper.SetClick(fields.UIButton_Apply, OnUIButton_Apply)
    EventHelper.SetClick(fields.UIButton_Celebrity, OnUIButton_Celebrity)
    EventHelper.SetClick(fields.UIButton_VSInfo, OnUIButton_VSInfo)
    EventHelper.SetClick(fields.UIButton_Award, OnUIButton_Award)
    EventHelper.SetClick(fields.UIButton_Flow, OnUIButton_Flow)    
end

local function init(params)
    --printyellow("[tabtournament:init]tabtournament init!")

    name, gameObject, fields    = unpack(params)

    m_Factions = ConfigManager.getConfig("profession")
    m_CurrentFaction = m_Factions[1].faction

    m_CurrentTermid = 0
    m_CurrentChampioninfo = nil
    m_TournamentCfg  = ConfigManager.getConfig("huiwu")
    if m_TournamentCfg == nil then
         printyellow("[tabtournament:init] m_TournamentCfg null!")
    end

    registereventhandler()
end

local function OnPlayerLoaded(params)
    -- printyellow("[tabtournament:OnPlayerLoaded]", params)
    if not m_Player.m_Object then return end
    local playerObj = m_Player.m_Object
    local playerTrans           = playerObj.transform
    playerTrans.parent          = fields.UITexture_Player.gameObject.transform
	playerTrans.localScale      = Vector3.one*200
    playerTrans.localPosition   = Vector3(0,-200,200)
    playerTrans.rotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(playerObj,Define.Layer.LayerUICharacter)
    playerObj:SetActive(true)
    m_Player:PlayLoopAction(cfg.skill.AnimType.Stand)

    EventHelper.SetDrag(fields.UITexture_Player,function(o,delta)
        local vecRotate = Vector3(0,-delta.x,0)
        playerObj.transform.localEulerAngles = playerObj.transform.localEulerAngles + vecRotate
    end)
end

local function ShowPlayer(id,profession,gender,showheadinfo,dress,equips,iscreat)
    if m_Player then
        m_Player:release()
        m_Player=nil
    end

    if id and id>0 then
        m_Player = Player:new(true)
        m_Player.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
        m_Player:init(id, profession, gender, showheadinfo, dress, equips, iscreat)
        m_Player:RegisterOnLoaded(OnPlayerLoaded)
    end
end

local function SetChampionInfo(msg)

    if msg and msg.championinfo.showinfo.roleid>0 then
        fields.UISprite_Await01.gameObject:SetActive(false)
        fields.UILabel_Times.gameObject:SetActive(true)
        --fields.UILabel_ChampionName.gameObject:SetActive(true)
        fields.UISprite_TitleBackground.gameObject:SetActive(true)
        fields.UIButton_Worship.gameObject:SetActive(true)
        --fields.UILabel_Empty.gameObject:SetActive(false)

        fields.UISprite_Fighting.gameObject:SetActive(true)
        fields.UILabel_Power.gameObject:SetActive(true)
        fields.UILabel_Name.gameObject:SetActive(true)
        fields.UISprite_LV.gameObject:SetActive(true)

        m_CurrentTermid = msg.termid
        m_CurrentChampioninfo = msg.championinfo

        --fields.UILabel_ChampionName.text = msg.championinfo.showinfo.name   --role name
        fields.UILabel_Name.text = msg.championinfo.showinfo.name   --role name
        fields.UILabel_Power.text = msg.championinfo.showinfo.combatpower   --fightpowder
        fields.UILabel_LastTimes.text = msg.championinfo.worshipnum         --worshipnum
        fields.UILabel_Level.text = msg.championinfo.showinfo.level         --worshipnum
        
        local faction = ConfigManager.getConfigData("profession", msg.profession)
        local factionname = faction and faction.name or ""
        fields.UILabel_Guild.text = factionname

        --testimonials
        fields.UISprite_Pop.gameObject:SetActive(false)
        --[[
        --���ݲ߻��������ظ���
        --printyellow("[tabtournament:SetChampionInfo] msg.championinfo.awardword=", msg.championinfo.awardword)
        local testimonials = msg.championinfo.awardword
        if IsNullOrEmpty(testimonials) then
            testimonials = string.format(LocalString.Tournament_Testimonials, msg.championinfo.showinfo.name, factionname)
        end
        --printyellow("[tabtournament:SetChampionInfo] testimonials=", testimonials)
        fields.UILabel_BossTalk.text = testimonials and testimonials or ""
        fields.UISprite_Pop.gameObject:SetActive(not IsNullOrEmpty(testimonials))
        --]]

        --show model
        local showinfo = msg.championinfo.showinfo
        ShowPlayer(showinfo.roleid, showinfo.profession, showinfo.gender, false, showinfo.dressid, showinfo.equips)
    else
        fields.UISprite_Await01.gameObject:SetActive(true)
        fields.UILabel_Times.gameObject:SetActive(false)
        --fields.UILabel_ChampionName.gameObject:SetActive(false)
        fields.UISprite_Pop.gameObject:SetActive(false)
        fields.UISprite_TitleBackground.gameObject:SetActive(false)
        fields.UIButton_Worship.gameObject:SetActive(false)
        --fields.UILabel_Empty.gameObject:SetActive(true)

        fields.UISprite_Fighting.gameObject:SetActive(false)
        fields.UILabel_Power.gameObject:SetActive(false)
        fields.UILabel_Name.gameObject:SetActive(false)
        fields.UISprite_LV.gameObject:SetActive(false)

        m_CurrentTermid = 0
        m_CurrentChampioninfo = nil

        fields.UILabel_Guild.text = ""
        fields.UILabel_BossTalk.text = ""
        --fields.UILabel_ChampionName.text = ""
        fields.UILabel_LastTimes.text = ""
        if m_Player then
            m_Player:release()
            m_Player=nil
        end
    end

    --test
    --ShowPlayer(PlayerRole.m_Id, PlayerRole.m_Profession, PlayerRole.m_Gender, false, PlayerRole.m_Dress, PlayerRole.m_Equips)
end

local function on_SGetChampion(msg)
    if msg and msg.ctx == cfg.huiwu.HuiWu.CHAMPION_CTX_MAIN then
        SetChampionInfo(msg)
    end
end

local function UpdateEnrollInfo()
    if TournamentInfo.GetCurrentStage() == cfg.huiwu.Stage.BEGIN_ENROLL then
        -- local log = string.format("[tabtournament:UpdateEnrollInfo] TournamentInfo.GetCurrentStage() = %s, TournamentInfo.HasEnroll() = %s.", TournamentInfo.GetCurrentStage(), TournamentInfo.HasEnroll())
        -- printyellow(log)
        if TournamentInfo.HasEnroll() then
            printyellow("[tabtournament:UpdateEnrollInfo] HasEnroll = true!")
            fields.UILabel_State.text = LocalString.Tournament_State_Applied
            fields.UILabel_Apply.text = LocalString.Tournament_Apply_Button_YES
            fields.UIButton_Apply.isEnabled = false
        else
            printyellow("[tabtournament:UpdateEnrollInfo] HasEnroll = false!")
            fields.UILabel_State.text = LocalString.Tournament_State_Can_Apply
            fields.UILabel_Apply.text = LocalString.Tournament_Apply_Button_NO
            fields.UIButton_Apply.isEnabled = true
        end
    else
        printyellow("[tabtournament:UpdateEnrollInfo] CurrentStage ~=", cfg.huiwu.Stage.BEGIN_ENROLL)
        --fields.UILabel_Apply.text = LocalString.Tournament_Apply_Button_NO
        --fields.UIButton_Apply.isEnabled = false
        
        fields.UIButton_Apply.isEnabled = false
        if TournamentInfo.HasEnroll() then
            fields.UILabel_State.text = LocalString.Tournament_State_Applied
            fields.UILabel_Apply.text = LocalString.Tournament_Apply_Button_YES
        else
            fields.UILabel_State.text = LocalString.Tournament_State_Cannot_Apply
            fields.UILabel_Apply.text = LocalString.Tournament_Apply_Button_NO
        end
    end
end

local function RefreshWorshipInfo()
    local worshipTime = LimitTimeManager.GetDayLimitTime(cfg.cmd.ConfigId.HUIWU, cfg.cmd.CmdId.WORSHIP)
    if worshipTime == nil then
        worshipTime = 0
    end
    -- local log = string.format("[tabtournament:RefreshWorshipInfo]total worship time = %s, used worship time = %s.", m_TournamentCfg.daiylyworshiptimes.num, worshipTime)
    -- printyellow(log)
    fields.UILabel_RemainTimes.text = (m_TournamentCfg.daiylyworshiptimes.num - worshipTime)
end

local function UpdateWorshipInfo(msg)
    if msg then
        if m_CurrentChampioninfo then
            m_CurrentChampioninfo.worshipnum = msg.worshipnum
        end

        fields.UILabel_LastTimes.text = msg.worshipnum
    else
        fields.UILabel_LastTimes.text = ""
    end

    RefreshWorshipInfo()
end

local function ShowEnrollAward()
    --printyellow("[tabtournament:ShowEnrollAward] ShowEnrollAward!")
    local awardstring = ""
    local awardItemList = BonusManager.GetMultiBonusItems(m_TournamentCfg.enrollaward)
    if awardItemList and #awardItemList>0 then
        for i=1, #awardItemList do
            local rankAward = awardItemList[i]
            if rankAward and rankAward:GetName() then
                awardstring = awardstring..rankAward:GetName().." "
            end
        end
    else
        -- printyellow("[tabtournament:ShowEnrollAward] BonusManager.GetMultiBonusItems(m_TournamentCfg.enrollaward) null!")
    end
    local disc = string.format(LocalString.Tournament_Enroll_Award, awardstring)
    fields.UILabel_Discription.text = disc
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

local function ShowTimeIntroduction()
    --activity time
    fields.UILabel_ActivityTime.text = LocalString.Tournament_Opentime
    fields.UILabel_SpecificActivityTime.text = TournamentManager.GetWeektimeText(m_TournamentCfg.battleopen)
    
    --apply time
    fields.UILabel_SpecificApplyTime.text = string.format(LocalString.Tournament_Duration, TournamentManager.GetWeektimeText(m_TournamentCfg.enrollopen), TournamentManager.GetWeektimeText(m_TournamentCfg.enrollend))
    
    --Preselect time
    fields.UILabel_SpecificPreselectedTime.text = string.format(LocalString.Tournament_Duration, TournamentManager.GetWeektimeText(m_TournamentCfg.preselectopen2), TournamentManager.GetWeektimeText(m_TournamentCfg.preselectend2))
end

local function RefreshReddot()
    fields.UISprite_Warning.gameObject:SetActive(TournamentInfo.HasNewSchedule())
end

local function initpanels()
    --printyellow("[tabtournament:initpanels]tabtournament initpanels!")

    --time introduction
    ShowTimeIntroduction()

    --last term champion info
    SetChampionInfo(nil)

    --enroll
    UpdateEnrollInfo()

    --worship
    UpdateWorshipInfo(nil)

    --enroll award
    ShowEnrollAward()

    --red dot
    RefreshReddot()
end

local function refresh()
    -- printyellow("[tabtournament:refresh]tabtournament refresh!")
    RefreshWorshipInfo()
end

local function update()
    if m_Player and m_Player.m_Object then
        m_Player.m_Avatar:Update()
    end
end

local function show()
    printyellow("[tabtournament:show]tabtournament show!")
    m_CurrentFaction = PlayerRole.m_Profession
    initpanels()
    GetChampionInfo()
end

local function hide()
    -- printyellow("[tabtournament:hide]tabtournament hide!")
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
    --SetChampionInfo = SetChampionInfo,
    UpdateEnrollInfo = UpdateEnrollInfo,
    UpdateWorshipInfo = UpdateWorshipInfo,
    on_SGetChampion = on_SGetChampion,
}
