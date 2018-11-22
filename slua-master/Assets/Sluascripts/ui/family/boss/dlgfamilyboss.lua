local unpack = unpack
local print = print
local timeutils         = timeutils
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local PlayerRole = require("character.playerrole"):Instance()
local FamilyBossInfo = require("ui.family.boss.familybossinfo")
local FamilyBossMgr = require("ui.family.boss.familybossmanager")
local Monster       = require("character.monster")
local FamilyManager = require("family.familymanager")
local Define=require("define")
local DlgDialogBox_Commodity = require"ui.common.dlgdialogbox_commodity"
local DlgReward       = require("ui.family.boss.dlgfamilybossreward")

local fields
local name
local gameObject

local m_BossIndex
local m_BossModel

local m_BossesCfg
local m_BossTimeCfg

local function GetBoss(index)
    local bosscfg
    local bossinfo
    local bosslevelcfg
    if m_BossesCfg and index>0 and index<=#m_BossesCfg then
        --printyellow("[dlgfamilyboss:GetBoss] boss cfg count=", #m_BossesCfg)
        bosscfg = m_BossesCfg[index]
        bossinfo = FamilyBossInfo.GetBossInfo(bosscfg.bossid)
        if bossinfo then
            bosslevelcfg = bosscfg.bossinfo[bossinfo.animallevel]
        else
            bosslevelcfg = bosscfg.bossinfo[1]
        end
    end
    return bosscfg, bossinfo, bosslevelcfg
end


local function OnBossModelLoaded(obj)
    -- printyellow("[dlgfamilyboss:OnBossModelLoaded]", obj.name)

    local offsety = -2*SCALE_XY
    local scale = 100
    local bosscfg, bossinfo, bosslevelcfg = GetBoss(m_BossIndex)
    if bosscfg and bosslevelcfg then
        local monster = ConfigManager.getConfigData("monster",bosslevelcfg.monsterid)
        local modelData =  ConfigManager.getConfigData("model",monster.modelname)
        if modelData and nil == string.match(obj.name, modelData.modelpath) then
            --printyellow(string.format("[dlgfamilyboss:OnBossModelLoaded] obj.name=[%s],modelData.modelpath=[%s], not match destroy!",obj.name, modelData.modelpath))
            GameObject.Destroy(obj)
            return
        end
        if bosscfg.offsety then
            offsety = bosscfg.offsety
        end
        if bosscfg.scale then
            scale = bosscfg.scale
        end
        --printyellow(string.format("[dlgfamilyboss:OnBossModelLoaded] offsety=[%f], scale=[%f].",offsety,scale))
    end

    local bossTrans           = obj.transform
    bossTrans.parent          = fields.UITexture_Boss.gameObject.transform
	bossTrans.localScale      = Vector3.one*scale
    bossTrans.localPosition   = Vector3(0,offsety,-10*SCALE_XY)
    bossTrans.rotation = Quaternion.Euler(-90,0,0)
    ExtendedGameObject.SetLayerRecursively(obj,Define.Layer.LayerUICharacter)
    obj:SetActive(true)
    m_BossModel:PlayLoopAction(cfg.skill.AnimType.Stand)

    EventHelper.SetDrag(fields.UITexture_Boss,function(o,delta)
        local vecRotate = Vector3(0,-delta.x,0)
        obj.transform.localEulerAngles = obj.transform.localEulerAngles + vecRotate
    end)


    --test
    --printyellow("[dlgfamilyboss:OnBossModelLoaded] texture test!")
    --fields.UITexture_Boss:SetIconTexture("")
    --fields.UITexture_Boss:SetByteTexture(nil)

end

local function ShowBossModel(bossid)
    -- printyellow("[dlgfamilyboss:ShowBossModel] Show BossModel:", bossid)
    if m_BossModel then
        m_BossModel:release()
        m_BossModel=nil
    end

    m_BossModel = Monster:new()
    --m_BossModel.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
    m_BossModel:RegisterOnLoaded(OnBossModelLoaded)
    m_BossModel:init(bossid, bossid, false)
end

--[[
--�������Ѵ���������Ҫ�ͻ��˼�
local function GetBossCurrentExp(bossinfo, bosscfg)
    local curexp = bossinfo.exp
    if bossinfo.animallevel>1 then
        for i=1, (bossinfo.animallevel-1) do
            local levelcfg = bosscfg.bossinfo[i]
            curexp = curexp - levelcfg.requireexp
        end
    end
    return curexp
end--]]

local function UpdateEvolution()
    local rolefamilyinfo = FamilyManager.RoleMember()
    --printyellow("[dlgfamilyboss:UpdateEvolution]", PlayerRole.m_Level, bosslevelcfg.requipreplayerlvl.level)
    if rolefamilyinfo.familyjob ~=cfg.family.FamilyJobEnum.CHIEF and rolefamilyinfo.familyjob~=cfg.family.FamilyJobEnum.VICE_CHIEF then--family job
        fields.UIButton_Evolution.gameObject:SetActive(false)
    else
        local bosscfg, bossinfo, bosslevelcfg = GetBoss(m_BossIndex)
        if bosscfg and bossinfo and bosslevelcfg then
            fields.UIButton_Evolution.gameObject:SetActive(true)

            if bossinfo.exp < bosslevelcfg.requireexp then
                fields.UIButton_Evolution.isEnabled = false
            else
                fields.UIButton_Evolution.isEnabled = true
            end
        else
            fields.UIButton_Evolution.gameObject:SetActive(false)
        end
    end
end

local function GetOpentimeText(bossid)
    local opentime = ""
    local textformat = LocalString.Family_Boss_Open_Time
    local weekday
    local weekbossmap = m_BossTimeCfg.monsterinfo
    if weekbossmap then
        for week,id in pairs(weekbossmap) do
            if id==bossid then
                weekday = LocalString.WeekCapitalForm[week]
                break
            end
        end
    end
    if weekday and textformat then    
        opentime = string.format(textformat, weekday)
    end
    return opentime
end

local function ShowBoss(index, isforce)
    if true~=isforce and index==m_BossIndex then
        --printyellow(string.format("[dlgfamilyboss:ShowBoss] no need to show: true~=isforce and index[%d]==m_BossIndex.", index))
        return
    end

    local bosscfg, bossinfo, bosslevelcfg = GetBoss(index)
    if bosscfg and bosslevelcfg then
        m_BossIndex = index
        --printyellow("[dlgfamilyboss:ShowBoss] show boss at index:", index)
        --model
        if nil == m_BossModel or m_BossModel.m_Id ~=bosslevelcfg.monsterid then
            ShowBossModel(bosslevelcfg.monsterid)
        end

        --name level
        fields.UILabel_Name.text = bosscfg.name
        fields.UILabel_Level.text = string.format(LocalString.Family_Boss_Level, bossinfo and bossinfo.animallevel or 1)

        --exp
        local levelexp = bosslevelcfg.requireexp
        local curexp = bossinfo and bossinfo.exp or 0 --GetBossCurrentExp(bossinfo, bosscfg)
        local progress
        if curexp<=0 or levelexp<=0 then
            progress = 0
        elseif curexp>=levelexp then
            progress = 1
        else
            progress = curexp/levelexp
        end
        fields.UISlider_Evolution.value = progress
        fields.UILabel_Exp.text = curexp.."/"..levelexp
        --printyellow(string.format("[dlgfamilyboss:ShowBoss] curexp=[%d], levelexp=[%d].",curexp,levelexp))

        --introduction
        fields.UILabel_Introduction.text = bosscfg.introduction

        --opentime
        fields.UILabel_OpenTime.text = GetOpentimeText(bosscfg.bossid)
    else
        printyellow("[dlgfamilyboss:ShowBoss] boss info nil for index:", index)
    end

    UpdateEvolution()
end

local function UpdateBoss()
    --printyellow("[dlgfamilyboss:UpdateBoss] Update boss info!")
    ShowBoss(m_BossIndex, true)
end

--[[
local function UpdateCountdown()
    if m_BossTimeCfg and FamilyBossInfo.GetBossChallengeTime()>0 and FamilyBossInfo.GetBossChallengeTime()< m_BossTimeCfg.battletime then  --challenge time
        fields.UILabel_Time.gameObject:SetActive(true)
        fields.UILabel_TimeNum.gameObject:SetActive(false)
        fields.UILabel_TimeNumRed.gameObject:SetActive(true)

        fields.UILabel_Time.text = LocalString.Family_Boss_Countdown_Challenge
        local challengecountdown = math.ceil(FamilyBossInfo.GetBossChallengeTime())
        fields.UILabel_TimeNumRed.text = timeutils.getDateTimeString(challengecountdown,"hh:mm:ss")
    elseif FamilyBossInfo.GetBossOpenTime()>0 then  --opentime
        fields.UILabel_Time.gameObject:SetActive(true)
        fields.UILabel_TimeNum.gameObject:SetActive(true)
        fields.UILabel_TimeNumRed.gameObject:SetActive(false)

        fields.UILabel_Time.text = LocalString.Family_Boss_Countdown_Open
        local opencountdown = math.ceil(FamilyBossInfo.GetBossOpenTime())
        fields.UILabel_TimeNum.text = timeutils.getDateTimeString(opencountdown,"hh:mm:ss")
    else
        fields.UILabel_Time.gameObject:SetActive(false)
        fields.UILabel_TimeNum.gameObject:SetActive(false)
        fields.UILabel_TimeNumRed.gameObject:SetActive(false)
    end
end
--]]

local function UpdateTrain()
    fields.UISprite_Warning.gameObject:SetActive(FamilyBossMgr.UnRead())
end

local function UpdateDlg()
    --evolution
    UpdateEvolution()

    --open
    --UpdateOpen()

    --countdown
    --UpdateCountdown()

    --train
    UpdateTrain()
end

local function GetBossIndexByWeekday()
    local bossindex = 1
    local weekday = timeutils.TimeNow().wday
    --sunday is the first day
    if weekday == 1 then
        weekday = 7
    else
        weekday = weekday -1
    end
    --printyellow(string.format("[dlgfamilyboss:GetBossIndexByWeekday] weekday=%d, #m_BossesCfg=%d.", weekday, #m_BossesCfg))
    if weekday<=#m_BossesCfg then
        bossindex = weekday
    else
        bossindex = 1
    end
    return bossindex
end

local function show()
    m_BossIndex = 0
    UpdateDlg()
    ShowBoss(GetBossIndexByWeekday())
end

local function OnUIButton_Close()
    --printyellow("[dlgfamilyboss:OnUIButton_Close] UIButton_Close clicked!")
    UIManager.hide("family.boss.dlgfamilyboss")
end

local function OnUIButton_ArrowsRight()
    --printyellow("[dlgfamilyboss:OnUIButton_ArrowsRight] UIButton_ArrowsRight clicked!")
    if m_BossIndex<#m_BossesCfg then
        ShowBoss(m_BossIndex+1)
    end
end

local function OnUIButton_ArrowsLeft()
    --printyellow("[dlgfamilyboss:OnUIButton_ArrowsLeft] UIButton_ArrowsLeft clicked!")
    if m_BossIndex>1 then
        ShowBoss(m_BossIndex-1)
    end
end

local function OnEvolutionConfirmGuessOK()
    --printyellow("[dlgfamilyboss:OnEvolutionConfirmGuessOK] On Confirm Evolution OK!")
    local bosscfg, bossinfo, bosslevelcfg = GetBoss(m_BossIndex)
    if bossinfo then
        FamilyBossMgr.send_CEvolveGodAnimal(bossinfo.animalid)
    end
end

local function OnEvolutionConfirmGuessCancel()
    --printyellow("[dlgfamilyboss:OnEvolutionConfirmGuessCancel] On Confirm Evolution Cancel!")
end

local function OnUIButton_Evolution()
    --printyellow("[dlgfamilyboss:OnUIButton_Evolution] UIButton_Evolution clicked!")
    local bosscfg, bossinfo, bosslevelcfg = GetBoss(m_BossIndex)
    local familyinfo = FamilyManager.Info()
    local rolefamilyinfo = FamilyManager.RoleMember()
    if bosscfg and bossinfo and bosslevelcfg and familyinfo and rolefamilyinfo then
        local levelexp = bosslevelcfg.requireexp
        local curexp = bossinfo.exp --GetBossCurrentExp(bossinfo, bosscfg)

        local bossnextlevelcfg = bosscfg.bossinfo[bossinfo.animallevel+1]
        if bossnextlevelcfg then
            --test
            --rolefamilyinfo.familyjob =cfg.family.FamilyJobEnum.MEMBER
            --PlayerRole.m_Level = 0
            --curexp = 1000
            --familyinfo.flevel = 0

            if curexp<levelexp then --exp
                UIManager.ShowSingleAlertDlg({content=LocalString.Family_Boss_Evolution_Fail_Exp})
            elseif rolefamilyinfo.familyjob~=cfg.family.FamilyJobEnum.CHIEF and rolefamilyinfo.familyjob~=cfg.family.FamilyJobEnum.VICE_CHIEF then--family job
                UIManager.ShowSingleAlertDlg({content=LocalString.Family_Boss_Evolution_Fail_Jop})
            elseif familyinfo.flevel<bossnextlevelcfg.requirefamilylvl.level then --family level
                UIManager.ShowSingleAlertDlg({content=string.format(LocalString.Family_Boss_Evolution_Fail_FamilyLevel, bossnextlevelcfg.requirefamilylvl.level)})
            elseif PlayerRole.m_Level<bossnextlevelcfg.requipreplayerlvl.level then    --chief level
                UIManager.ShowSingleAlertDlg({content=string.format(LocalString.Family_Boss_Evolution_Fail_RoleLevel, bossnextlevelcfg.requipreplayerlvl.level)})
            else
                local confirmContent = string.format(LocalString.Family_Boss_Evolution_Confirm, bosslevelcfg.requirefamilycapital.money, bosscfg.name, bossnextlevelcfg.requirefamilylvl.level, bosslevelcfg.requipreplayerlvl.level)
                UIManager.ShowAlertDlg({content = confirmContent, callBackFunc = OnEvolutionConfirmGuessOK, callBackFunc1 = OnEvolutionConfirmGuessCancel, immediate = true,})
            end
        else
            UIManager.ShowSingleAlertDlg({content=LocalString.Family_Boss_Evolution_Fail_Max})
        end
    end
end

local function OnChallengeConfirmOK()
    --printyellow("[dlgfamilyboss:OnChallengeConfirmOK] On Confirm Challenge OK!")
    FamilyManager.CEnterFamilyStation(FamilyManager.EnterType.GOD_ANIMAL)
end

local function OnChallengeConfirmCancel()
    --printyellow("[dlgfamilyboss:OnChallengeConfirmCancel] On Confirm Challenge Cancel!")
end

local function OnUIButton_Challenge()
    --printyellow(string.format("[dlgfamilyboss:OnUIButton_Challenge] UIButton_Challenge clicked! FamilyBossInfo.GetBossChallengeTime()=%s, m_BossTimeCfg.battletime=%s.", FamilyBossInfo.GetBossChallengeTime(), m_BossTimeCfg.battletime))
    --if m_BossTimeCfg and FamilyBossInfo.GetBossChallengeTime()>0 and FamilyBossInfo.GetBossChallengeTime()<= m_BossTimeCfg.battletime then  --challenge time
    if true==FamilyBossInfo.CanChallenge() then
        UIManager.ShowAlertDlg({content = LocalString.Family_Boss_Challenge_Confirm, callBackFunc = OnChallengeConfirmOK, callBackFunc1 = OnChallengeConfirmCancel, immediate = true,})
    else
        UIManager.ShowSingleAlertDlg({content=LocalString.Family_Boss_Challenge_Not_Ready})
    end
end

local function OnUIButton_Train()
    --printyellow("[dlgfamilyboss:OnUIButton_Train] UIButton_Train clicked!")
    UIManager.show("common.dlgdialogbox_commodity", {type = DlgDialogBox_Commodity.DlgType.FamilyBossTrain, bossid = m_BossIndex })
end

local function OnUISprite_Rewards()
    printyellow("[dlgfamilyboss:OnUISprite_Rewards] UISprite_Rewards clicked!")    
    local bosscfg, bossinfo, bosslevelcfg = GetBoss(m_BossIndex)
    local bossname = bosscfg and bosscfg.name or nil
    --local bossid = bossinfo and bossinfo.animalid or nil
    --local bosslevel = bossinfo and bossinfo.animallevel or nil
    local bosslevelcfg
    if bossinfo and bosscfg then
        bosslevelcfg = bosscfg.bossinfo[bossinfo.animallevel]
    else
        bosslevelcfg = bosscfg.bossinfo[1]
    end
    DlgReward.show(bossname, bosslevelcfg)  
end

local function registereventlistener()
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, OnUIButton_ArrowsRight)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, OnUIButton_ArrowsLeft)
    EventHelper.SetClick(fields.UIButton_Evolution, OnUIButton_Evolution)
    EventHelper.SetClick(fields.UIButton_Challenge, OnUIButton_Challenge)
    EventHelper.SetClick(fields.UIButton_Train, OnUIButton_Train)
    --EventHelper.SetClick(fields.UIButton_Open, OnUIButton_Open)
    EventHelper.SetClick(fields.UISprite_Rewards, OnUISprite_Rewards)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    registereventlistener()

    m_BossesCfg = ConfigManager.getConfig("boss")
    m_BossTimeCfg  = ConfigManager.getConfig("bossconfig")
    if m_BossTimeCfg == nil then
        print("[ERROR][dlgfamilyboss:init] m_BossTimeCfg null!")
    end

    --应策划需求，去除开启功能，改为自动开启
    if fields.UIButton_Open then
        fields.UIButton_Open.gameObject:SetActive(false)
    end
    --应策划需求，去除倒计时显示
    fields.UILabel_Time.gameObject:SetActive(false)
end

local function hide()
    --printyellow("[dlgfamilyboss:hide] hide!")
    if m_BossModel then
        m_BossModel:release()
        m_BossModel=nil
    end
end

local function destroy()
    --printyellow("[dlgfamilyboss:destroy] destroy!")
end

local function refresh(params)
end

local function update()
    if m_BossModel and m_BossModel.m_Object then
        m_BossModel.m_Avatar:Update()
    end

    --countdown
    --UpdateCountdown()

    --open
    --UpdateOpen()
end

local function SetModelActive(value)
    if m_BossModel then
        m_BossModel:SetVisiable(value)
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    update = update,
    uishowtype   = uishowtype,
    UpdateEvolution = UpdateEvolution,
    --UpdateOpen = UpdateOpen,
    UpdateBoss = UpdateBoss,
    UpdateTrain = UpdateTrain,
    SetModelActive = SetModelActive,
}


--[[
local function UpdateOpen()
    --update open button state
    local rolefamilyinfo = FamilyManager.RoleMember()
    if rolefamilyinfo.familyjob ~=cfg.family.FamilyJobEnum.CHIEF and rolefamilyinfo.familyjob~=cfg.family.FamilyJobEnum.VICE_CHIEF then--family job
        fields.UIButton_Open.gameObject:SetActive(false)
    else
        fields.UIButton_Open.gameObject:SetActive(true)

        if FamilyBossInfo.GetBossOpenTime()>0 then
            fields.UIButton_Open.isEnabled = false
        else
            fields.UIButton_Open.isEnabled = true
        end
    end
end

local function GetOpenCostByDateIndex(index)
    local opencost = 0
    local openbosslist
    if index == 1 then
        openbosslist = m_BossTimeCfg.tuesday
    elseif index == 2 then
        openbosslist = m_BossTimeCfg.friday
    end

    if openbosslist and #openbosslist then
        for i=1, #openbosslist do
            local bosscfg, bossinfo, bosslevelcfg = GetBoss(openbosslist[i])
            if bosscfg and bossinfo and bosslevelcfg then
                local bosschallengecfg = ConfigManager.getConfigData("bosschallenge", bossinfo.animallevel)
                if bosschallengecfg then
                    opencost = opencost + bosschallengecfg.bossrequirecapital.money
                    --printyellow(string.format("[dlgfamilyboss:GetOpenCostByDateIndex] boss [%s] open costs [%s] on level [%s].", openbosslist[i], bosschallengecfg.bossrequirecapital.money, bossinfo.animallevel))
                else
                    -- printyellow("[dlgfamilyboss:GetOpenCostByDateIndex] ConfigManager.getConfigData(bosschallenge) null for level:", bossinfo.animallevel)
                end
            end
        end
    end

    -- printyellow(string.format("[dlgfamilyboss:GetOpenCostByDateIndex] cost for index [%s]=%s.", index, opencost))
    return opencost
end

local function GetWeekTime(opentime)
    local weektime = 0

    local curweekday = 0
    local curhour = 0
    local curminite = 0
    local cursecond = 0
    if opentime then
        curweekday = opentime.day
        curhour = opentime.hour
        curminite = opentime.minute
        cursecond = 0
    else
        local timenow= timeutils.TimeNow()
        curweekday = timenow.wday
        curhour = timenow.hour
        curminite = timenow.min
        cursecond = timenow.sec
        --sunday is the first day
        if curweekday == 1 then
            curweekday = 7
        else
            curweekday = curweekday -1
        end
    end

    weektime = weektime + (curweekday-1)*86400
    weektime = weektime + curhour*3600
    weektime = weektime + curminite*60
    weektime = weektime + cursecond

    return weektime
end

local function OnOpenConfirmOK()
    --printyellow("[dlgfamilyboss:OnOpenConfirmOK] On Confirm Open OK!")
    FamilyBossMgr.send_CLaunchGodAnimalActivity()
end

local function OnOpenConfirmCancel()
    --printyellow("[dlgfamilyboss:OnOpenConfirmCancel] On Confirm Open Cancel!")
end

local function GetOpenCost()
    local opencost = 0
    local curweektime = GetWeekTime()
    --printyellow("[dlgfamilyboss:GetOpenCost] curweektime=", curweektime)
    for i=1, #m_BossTimeCfg.opentime do
        local signendtime = GetWeekTime(m_BossTimeCfg.opentime[i]) - m_BossTimeCfg.signtime
        --printyellow(string.format("[dlgfamilyboss:GetOpenCost] signendtime[%s]=%s.", i, signendtime))
        if curweektime < signendtime then
            opencost = GetOpenCostByDateIndex(i)
            break
        elseif i == #m_BossTimeCfg.opentime then
            opencost = GetOpenCostByDateIndex(1)
            break
        end
    end

    return opencost
end

local function OnUIButton_Open()
    --printyellow("[dlgfamilyboss:OnUIButton_Open] UIButton_Open clicked!")
    local familyinfo = FamilyManager.Info()

    --test
    --familyinfo.money = 500

    local opencost = GetOpenCost()
    if opencost<=familyinfo.money then
        local confirmContent = string.format(LocalString.Family_Boss_Open_Confirm, opencost)
        UIManager.ShowAlertDlg({content = confirmContent, callBackFunc = OnOpenConfirmOK, callBackFunc1 = OnOpenConfirmCancel,immediate = true,})
    else
        UIManager.ShowSingleAlertDlg({content=string.format(LocalString.Family_Boss_Open_Fail_FamilyMoney, opencost)})
    end
end
    --]]
