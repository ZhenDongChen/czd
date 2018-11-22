local unpack            = unpack
local print             = print
local math              = math
local tsort             = table.sort
local min               = math.min
local tinsert           = table.insert
local tostring          = tostring
local strfmt            = string.format
local EventHelper       = UIEventListenerHelper
local uimanager         = require "uimanager"
local network           = require "network"
local CharacterManager  = require "character.charactermanager"
local EctypeManager     = require "ectype.ectypemanager"
local PetManager        = require "character.pet.petmanager"
local PrologueManager   = require "prologue.prologuemanager"
local PlayerRole        = require "character.playerrole"
local bStopNav          = false
local Mappings          = {}

local gameObject
local name
local fields
local DlgInfo
local targetPosition
local listenerID
local UIMain
local showHurt
local players
local uiRank
local dmgAltered
local totalDmg
local cntDown
local bFindAgent
local frameCount
local bNeedInit
local bIsPrologue
local m_Particle
local m_PlayParticle
local currEctypeId

local function RefreshDamanges()
    if fields.UIGroup_Rank.gameObject.activeSelf then
        fields.UIList_Rank:ResetListCount(#players)
        for idx,player in pairs(players) do
            local item = fields.UIList_Rank:GetItemByIndex(idx-1)
            local labelName = item.Controls["UILabel_Name"]
            local sliderHP = item.Controls["UISlider_HP"]
            local rank = item.Controls["UILabel_RankList"]
            rank.text = tostring(idx)
            labelName.text = player.name
            if totalDmg<1 then
                sliderHP.value = 0
            else
                sliderHP.value = player.dmg/totalDmg
            end
        end
    end
end

local function destroy()
    network.remove_listener(listenerID)
end

local function ShowRank(b)
    fields.UIGroup_Rank.gameObject:SetActive(b)
    RefreshDamanges()
end

local function SendStatistic()
    if fields.UIGroup_Rank.gameObject.activeSelf or bNeedInit then
		--副本静止主角无敌的状态
        network.send(map.msg.CEctypeStatistic({}))
    end
end

local function ShowTasks(b)
    if b then
        fields.UIGroup_Background.gameObject:SetActive(not showHurt)
        fields.UIGroup_Rank.gameObject:SetActive(showHurt)
    else
        fields.UIGroup_Background.gameObject:SetActive(false)
        fields.UIGroup_Rank.gameObject:SetActive(false)
    end
    fields.UIButton_Hurt.gameObject:SetActive(b and not bIsPrologue)
    fields.UISprite_Back.gameObject:SetActive(b)
    RefreshDamanges()
end

local function InitPlayersDmg()
    players = {}
    SendStatistic()
    bNeedInit = false
end

local function OnStatistic(statisticInfo)
    frameCount = statisticInfo.frameCount
    totalDmg = statisticInfo.totalDmg
    players = statisticInfo.players
    RefreshDamanges()
end

local function show(params)
    bIsPrologue = false
    bFindAgent = false
    fields.UILabel_Discription.text = ""
    showHurt = false
    cntDown = 2
    if EctypeManager.GetEctype() then
        if EctypeManager.GetEctype().m_EctypeType == cfg.ectype.EctypeType.HUIWU then
            ShowRank(false)
            ShowTasks(false)
        end
        currEctypeId = EctypeManager.GetEctype().m_ID
        local bInExp = EctypeManager.GetEctype().m_EctypeType == cfg.ectype.EctypeType.EXP
        fields.UIGroup_MainEctype.gameObject:SetActive(not bInExp)
		fields.UIScrollView_Discription.gameObject:SetActive( not bInExp)
        fields.UIGroup_ExpEctype.gameObject:SetActive(bInExp)
    end
end

local function second_update()
    if frameCount then
        frameCount = frameCount -1
        if frameCount < 0 then
            SendStatistic()
        end
    end
end

local function hide()
    fields.UIGroup_BombEffect_DropMoney.gameObject:SetActive(false)
    fields.UIWidget_Bottom.gameObject:SetActive(false)
end

local function update()
    if cntDown then
        cntDown = cntDown - Time.deltaTime
        if cntDown < 0 then
            TweenAlpha.Begin(fields.UITexture_CopyName.gameObject,1,0)
            cntDown = nil
        end
    end
    if m_PlayParticle==true then
        if not uimanager.IsPlaying(fields.UIGroup_BombEffect_DropMoney.gameObject) then
            m_PlayParticle=nil
            uimanager.StopUIParticleSystem(fields.UIGroup_BombEffect_DropMoney.gameObject)
        end
    end
end

local function refresh(params)

end

--请求离开副本
local function LeaveEctype()
    if EctypeManager.IsFinished() then
        EctypeManager.FuncEnd()
    else
        local TaskManager = require("taskmanager")
        TaskManager.SetExecutingTask(0)
        EctypeManager.RequestLeaveEctype()
        local TeamManager = require("ui.team.teammanager")
    end
    fields.UIList_Mission:Clear()
    players = nil
end

local function AutoFight()
    if PrologueManager.IsInPrologue() then
        return
    end
    uimanager.call("dlguimain","SwitchAutoFight",true)
end

local function CompareFunc(a,b)
    return a.score > b.score
end

local function late_update()
    if dmgAltered then
        tsort(players,function(a,b) return a.score>b.score end)
        local cnt = min(3,#players)
        for i=1,cnt do
            uiRank[i].labelName = players[i].name
            if totalDmg <1 then
                uiRank[i].sliderHP.value = 0
            else
                uiRank[i].sliderHP.value = players[i].score / totalDmg
            end
        end
        dmgAltered = false
    end
end

local function ATFight(idx)
    local currentFinding = Mappings[idx]
    if currentFinding then
        if currentFinding.type == "position" then
            local param         = {
                targetPos       = Mappings[idx].target,
            }
            PlayerRole.Instance():navigateTo(param)
        elseif currentFinding.type == "monster" then
            local mst = CharacterManager.GetRoleNearestAttackableTarget(cfg.fight.Relation.ENEMY)
            if mst then
                local mstPos = mst:GetPos()
                local param         = {
                    targetPos       = Vector3(mstPos.x,mstPos.y,0),
                    lengthCallback  = { [1] = {length = 1200, callback = AutoFight}},
                    stopCallback = AutoFight,
                }
                PlayerRole.Instance():navigateTo(param)
            else
                bFindAgent = true
                local re = map.msg.CFindAgentByType({agenttype = cfg.fight.AgentType.MONSTER})
                network.send(re)
            end
        elseif currentFinding.type == "mineral" then
            local re = map.msg.CFindMineral({agenttemplateid = currentFinding.target})
            network.send(re)
        end
    end
end
local function SetAnchor(fields)
    uimanager.SetAnchor(fields.UIWidget_Left)
    uimanager.SetAnchor(fields.UIWidget_TopRight)
    uimanager.SetAnchor(fields.UIWidget_Top)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    SetAnchor(fields)
    playerRole = PlayerRole.Instance()


    listenerID = network.add_listener("map.msg.SFindAgentByType",function(msg)
        if bFindAgent then
            local param         = {
                targetPos       = Vector3(msg.position.x,msg.position.y,0),
                lengthCallback  = { [1] = {length = 60, callback = AutoFight}}
            }
            bFindAgent = false
			
            playerRole:navigateTo(param)
        end
    end)
    -- listenerID_Statistic = network.add_listener("map.msg.SEctypeStatistic",onmsg_Statistic)

    EventHelper.SetClick(fields.UIButton_Leave,function()
        local tb = {}
        tb.title = LocalString.EctypeText.LeaveWarningTitle
        if EctypeManager.GetEctype().m_EctypeType == cfg.ectype.EctypeType.HERO_CHALLENGE then
            tb.content = LocalString.EctypeText.LeaveHeroChallengeWarning
        else    
            tb.content = LocalString.EctypeText.LeaveWarningContent
        end
        tb.immediate = true
        tb.callBackFunc = LeaveEctype
        uimanager.ShowAlertDlg(tb)
    end)


    EventHelper.SetListClick(fields.UIList_Mission,function(item)
        if not bStopNav then
            local index = item.m_nIndex
            ATFight(index)
        end
    end)

    EventHelper.SetClick(fields.UIButton_Hurt,function()
        showHurt = not showHurt
        fields.UIGroup_Rank.gameObject:SetActive(showHurt)
        fields.UIGroup_Background.gameObject:SetActive(not showHurt)
        RefreshDamanges()
    end)

    EventHelper.SetClick(fields.UISprite_Goal,function()
        if not bStopNav then
            ATFight(0)
        end
    end)
    fields.UIGroup_BombEffect_DropMoney.gameObject:SetActive(false)
    fields.UIWidget_Bottom.gameObject:SetActive(false)

    if PrologueManager.IsInPrologue() then
        fields.UIWidget_TopRight.gameObject:SetActive(false)
    else
        fields.UIWidget_TopRight.gameObject:SetActive(true)
    end
end


local function Clear()
    for i=0,fields.UIList_Mission.Count-1 do
        local item = fields.UIList_Mission:GetItemByIndex(i)
        local label = item.gameObject:GetComponent("UILabel")
        label.text = ""
    end
    Mappings = {}
end

local function UpdateRemainTime(h,m,s)
    if fields then
        if h==0 then
            fields.UILabel_Time.text = strfmt("%02d:%02d",m,s)
        else
            fields.UILabel_Time.text = strfmt("%02d:%02d:%02d",h,m,s)
        end
    end
end

local function UpdateRemainCurrencyTime(value)
    local UISlider_Timer=fields.UISprite_Slider_Timer.gameObject:GetComponent("UISlider")
    UISlider_Timer.value=value
end


local function InsertMissionInfomation(index,infos,pathInfos)
    local item = fields.UIList_Mission:GetItemByIndex(index)
    if not item then
        item = fields.UIList_Mission:AddListItem()
    end
    Mappings[index] = pathInfos
    local info = item.gameObject:GetComponent("UILabel")
    info.text = infos[1]..'[ff0000]'..infos[2]..'[-]'.. (infos[3] or "")
end

local function ShowGoal()
    fields.UISprite_GoalBackground.gameObject:SetActive(true)
end

local function HideGoal()
    fields.UISprite_GoalBackground.gameObject:SetActive(false)
end

local function EnterEctype(name,ectypetype,isPrologue)
    bIsPrologue = isPrologue
    fields.UIButton_Hurt.gameObject:SetActive(not isPrologue)
    bNeedInit = true
	if ectypetype==cfg.ectype.EctypeType.CLIMB_TOWER then
		--fields.UIButton_Leave.gameObject:SetActive(false)
	end
    fields.UILabel_CopyName.text = "[f0f61b]"..name.."[-]"
    fields.UILabel_CopyNameTitle.text = name

end

local function ShowEffect(params)
    if params.isEnter then
        uimanager.PlayUIParticleSystem(fields.UIGroup_EnterEctype.gameObject,params.callback)
    else
        uimanager.PlayUIParticleSystem(fields.UIGroup_LeaveEctype.gameObject,params.callback)
    end
end

local function EctypeReady()
    InitPlayersDmg()
end

local function StopNav()
    bStopNav = true
end

local function ContinueNav()
    bStopNav = false
end

local function AddDescription(content)
    fields.UILabel_Discription.text = content
end

local function RemoveDescription()
    fields.UILabel_Discription.text = ""
end

local function GetWaveInfo(name,cnt)
    local ret = {}
    local coloredName = ' '..LocalString.PartnerText.ActiveColor..name..LocalString.PartnerText.ColorSuffix..' '
    tinsert(ret,strfmt(LocalString.EctypeText.KillMonster, coloredName))
    tinsert(ret,"")
    return ret
end

local function InitCurrencyInfo()
    local UISlider_Money=fields.UISprite_Slider_Money.gameObject:GetComponent("UISlider")
    UISlider_Money.value=0
    fields.UILabel_MoneyAmount.text=0
    UpdateRemainCurrencyTime(1)
end

local function RefreshDailyCurrency(params)
    local tweenScale=fields.UIButton_RefreshMoney.gameObject:GetComponent(UIPlayTween)
    tweenScale:Play(true)
    if params.totalValue and params.maxValue then
        local UISlider_Money=fields.UISprite_Slider_Money.gameObject:GetComponent("UISlider")
        UISlider_Money.value=(params.totalValue/params.maxValue)
        fields.UILabel_MoneyAmount.text=params.totalValue
    end
end

local function PlayDropMoneyEffect()
    uimanager.PlayUIParticleSystem(fields.UIGroup_BombEffect_DropMoney.gameObject)
    m_PlayParticle=true
end

local function RefreshDailyInformation(params)
	print("RefreshDailyInformation")
    ectypeid = params.ectypeid
    idx = params.wave
    local cfgDaily
    if params.ectypetype == cfg.ectype.EctypeType.CURRENCY then
        cfgDaily = ConfigManager.getConfigData("currencyectype",ectypeid)
    elseif params.ectypetype == cfg.ectype.EctypeType.CURRENCY_ACTIVITY then
        cfgDaily = ConfigManager.getConfigData("currencyactivityectype",ectypeid)
    elseif params.ectypetype == cfg.ectype.EctypeType.EXP then
        cfgDaily = ConfigManager.getConfigData("expectype",ectypeid)
    else
        cfgDaily = ConfigManager.getConfigData("dailyectype",ectypeid)
    end
    Clear()
    local line = 0
    if idx > 0 or params.ectypetype == cfg.ectype.EctypeType.CURRENCY or (params.ectypetype == cfg.ectype.EctypeType.CURRENCY_ACTIVITY) then
        if (params.ectypetype == cfg.ectype.EctypeType.CURRENCY) or (params.ectypetype == cfg.ectype.EctypeType.CURRENCY_ACTIVITY) then
            AutoFight()
            fields.UIWidget_Bottom.gameObject:SetActive(true)
            local text = ""
            if (params.ectypetype == cfg.ectype.EctypeType.CURRENCY) then
                text = LocalString.EctypeText.DailyTarget
            elseif (params.ectypetype == cfg.ectype.EctypeType.CURRENCY_ACTIVITY) then
                text = LocalString.EctypeText.CurrencyActivityTarget
            end
            InsertMissionInfomation(line,{text,""})
            AddDescription(cfgDaily.refmsg)
            InitCurrencyInfo()
        elseif params.ectypetype == cfg.ectype.EctypeType.EXP then
            local m = idx-1 <= cfgDaily.buffstartindex and idx-1 or cfgDaily.buffstartindex
            fields.UILabel_Buff.text = strfmt("%d/%d",m,cfgDaily.buffstartindex)
            fields.UISlider_Buff.value = (idx-1)/cfgDaily.buffstartindex
            fields.UILabel_ProgressNumber.text = strfmt("%d/%d",idx,#cfgDaily.monsters)
            HideGoal()
        else
            for monsterid,cnt in pairs(cfgDaily.monsters[idx].monsters) do
                local cfgMonster = ConfigManager.getConfigData("monster",monsterid)
                InsertMissionInfomation(line,GetWaveInfo(cfgMonster.name,cnt),{type="monster",target=monsterid})
                line = line + 1
            end
            local text = {}
            tinsert(text, "[9afe19]"..LocalString.EctypeText.Progress.."[-]")
            tinsert(text, strfmt("[fa4926] (%s/%d)[-]",idx,#cfgDaily.monsters))
            InsertMissionInfomation(line,text)
        end
    end
end

local function EnterFamilyEctype(str)
    InsertMissionInfomation(0,{LocalString.EctypeText.FamilyEctypeTarget,""})
    ShowGoal()
    if waveIdx then
        AddDescription(str)
    end
end

local function clientCmd_ShowleaveBtn(params)	
	fields.UIWidget_TopRight.gameObject:SetActive(true)
	local dlguimain = require("ui.dlguimain")
	local dlguimainfields = dlguimain.clientCmd_ShowleaveBtn()
	dlguimainfields.UIButton_FightAuto.gameObject:SetActive(true)
end

RegisterClientCmd("/SLBtn",clientCmd_ShowleaveBtn)
RegisterClientCmd("/xzleave",clientCmd_ShowleaveBtn)

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  late_update = late_update,
  destroy = destroy,
  refresh = refresh,
  UpdateRemainTime = UpdateRemainTime,
  UpdateRemainCurrencyTime = UpdateRemainCurrencyTime,
  InsertMissionInfomation = InsertMissionInfomation,
  Clear = Clear,
  ShowGoal = ShowGoal,
  HideGoal = HideGoal,
  EnterEctype = EnterEctype,
  EnterFamilyEctype = EnterFamilyEctype,
  EnterDaily = EnterDaily,
  StopNav = StopNav,
  ContinueNav = ContinueNav,
  AddDescription = AddDescription,
  RemoveDescription = RemoveDescription,
  ShowTasks = ShowTasks,
  ShowRank = ShowRank,
  RefreshDailyInformation = RefreshDailyInformation,
  RefreshDailyCurrency = RefreshDailyCurrency,
  PlayDropMoneyEffect = PlayDropMoneyEffect,
  ATFight = ATFight,
  AlterScore = AlterScore,
  varrefresh = varrefresh,
  second_update = second_update,
  EctypeReady = EctypeReady,
  OnStatistic = OnStatistic,
  ShowEffect = ShowEffect,
  OnNewMonsterWave_FamilyEctype =OnNewMonsterWave_FamilyEctype,
}
