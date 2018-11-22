local DefineEnum=require"defineenum"
local UIManager=require"uimanager"
local PlayerRole=(require"character.playerrole"):Instance()
local EctypeManager="ectype.ectypemanager"
local TimeUtils=require"common.timeutils"
local NoviceGuideManager
local NoviceGuideTrigger
local NoviceGuideLockObj
local NoviceGuideSyncServer

local m_GuideFsm=DefineEnum.NoviceGuideType.NONE
local m_FindObjTime=0
local m_AlreadyFindTimes=0
local m_Time=nil
local m_Count=nil

local function NeedTriggerNext()
    return m_GuideFsm==DefineEnum.NoviceGuideType.TRIGGERNEXT
end

local function SwitchToNone()
    m_GuideFsm=DefineEnum.NoviceGuideType.NONE
end

local function SwitchToCanNotFindObjs()
    m_GuideFsm=DefineEnum.NoviceGuideType.NONE
    NoviceGuideManager.ResetGuide()
end

local function SwitchToTriggerNext()
    --printyellow("SwitchToTriggerNext")   
    m_GuideFsm = DefineEnum.NoviceGuideType.TRIGGERNEXT  
    NoviceGuideTrigger.ResetTriggerNextTime()  
    NoviceGuideTrigger.TriggerNext()
end

local function DisplayCurveEffect(targetId)
--    printyellow("DisplayCurveEffect")
--    printyellow("NoviceGuideManager.GetTargetId():",NoviceGuideManager.GetTargetId())
--    local targetId=NoviceGuideManager.GetTargetId()
--    local DlgUIMain_Combat=require"ui.dlguimain_combat"
--    local target=DlgUIMain_Combat.GetSkillItemPos(targetId)
--    m_TargetPos=Vector3(target.x,target.y,0)
--    local DefineEnum=require"defineenum"
--    local CurveModelManager=require"character.curve.curvemodelmanager"
--    local curveType=DefineEnum.TraceType.Line2D   
--    Util.Load(string.format("sfx/s_%s.bundle", "ui_unlock"), define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)       
--        m_EffectObject=GameObject.Instantiate(asset_obj)   
--        local root=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root")
--        m_EffectObject.transform.parent=root.gameObject.transform    
--        m_EffectObject.transform.localPosition = Vector3.zero
--        local particle = m_EffectObject:GetComponent("ParticleSystem")
--        if particle then
--            particle:Stop(true)
--            particle:Play(true)
--        end
--        m_EffectObject:SetActive(true)
--        m_EffectDir = Vector3(m_TargetPos.x - 0, m_TargetPos.y - 0, 0)
--        m_EffectBeginTime=Time.time
--        m_ShowEffect=true     
--        printyellow("m_ShowEffect:",m_ShowEffect)
----        CurveModelManager.AddCurveData(effectObject,function()    
----        end,curveType,targetPos)
--    end)
    UIManager.show("noviceguide.dlgunlock",{targetId=targetId})
end

local function FinishCurrentGuide()
    if m_Count then
        m_Count=nil
        m_Time=nil
    end
    
    local hasnextGuide = NoviceGuideManager.HasNextGuide()
    --UIManager.call("dlgnoviceguide","CompleteCurrentCuide")
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        NoviceGuideManager.PlayAudio(guideData.overaudio)
    end
    NoviceGuideManager.CloseGuideDlg()
    local targetId=0
    local displayEffect=false
    if (NoviceGuideManager.GetDisplayEffect()==true) then
        targetId=NoviceGuideManager.GetTargetId()
        displayEffect=true
    end
    if (hasnextGuide) then
        --printyellow("trigger next")
        local nextdata = NoviceGuideManager.GetNextGuideData()
        --printt(nextdata)
        if (nextdata) then
            SwitchToTriggerNext()
        end
    else
        --printyellow("finish")
        NoviceGuideTrigger.SetUpdateInterval()

		if NoviceGuideManager.GetGuildExec() == true then
			local TaskManager=require"taskmanager"
			TaskManager.DoExecutingTask()
		end
		
        NoviceGuideManager.ResetGuide()
        if displayEffect==true then
            DisplayCurveEffect(targetId)
        end
		
		
		
--        local callBack=NoviceGuideManager.GetCallBack()
--        if callBack then
--            callBack()
--            NoviceGuideManager.SetCallBack()
--        end
    end
end

local function SkipGuide()
    local notExecuted=NoviceGuideManager.GetNotExecutedTriggers()
    notExecuted[NoviceGuideManager.GetPId()]=nil
    NoviceGuideSyncServer.SendSetGuideConfigure(NoviceGuideManager.GetPId(),0)
    NoviceGuideSyncServer.SendSetOnGoingGuide()
    NoviceGuideManager.SetOnGoingGuide()
    if m_Count then
        m_Count=nil
        m_Time=nil
    end
    NoviceGuideManager.StopAudio()
    NoviceGuideManager.CloseGuideDlg()
    NoviceGuideTrigger.SetUpdateInterval()
    NoviceGuideManager.ResetGuide()
end

local function SwitchToFinishGuide()
    --printyellow("SwitchToFinishGuide")
    local hasNextGuide = NoviceGuideManager.HasNextGuide()
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        if (NoviceGuideTrigger.SatisfyTriggerCondition(guideData.completeconditions)) then
            local notExecuted=NoviceGuideManager.GetNotExecutedTriggers()
            if hasNextGuide then
                if (guideData.issavepoint == true) then
                    NoviceGuideSyncServer.SendSetGuideConfigure(NoviceGuideManager.GetPId(),NoviceGuideManager.GetGuideIndex())
                    notExecuted[NoviceGuideManager.GetPId()]=(NoviceGuideManager.GetGuideIndex()+1)
                end                        
            else
                notExecuted[NoviceGuideManager.GetPId()]=nil
                --printt(NoviceGuideManager.GetNotExecutedTriggers())
                NoviceGuideSyncServer.SendSetGuideConfigure(NoviceGuideManager.GetPId(),0)
            end
            NoviceGuideSyncServer.SendSetOnGoingGuide()
            NoviceGuideManager.SetOnGoingGuide()
            FinishCurrentGuide()
        end       
    end
    
end

local function SwitchToShowingGuide()
    --printyellow("SwitchToShowingGuide")
    m_GuideFsm=DefineEnum.NoviceGuideType.SHOWINGGUIDE
    UIManager.show("noviceguide.dlgnoviceguide")
    local guideData=NoviceGuideManager.GetGuideData()
    if (guideData) then       
        if(guideData.ispause == 1) then
            NoviceGuideManager.SetPauseGame(true)
        end   
        local displayEffect=NoviceGuideManager.GetEffectByType("cfg.guide.Display")
        if (guideData.ismandatory==false) then
            m_Time=cfg.guide.NoviceGuide.NONMANDOTORYTIME
            m_Count=true
        elseif (displayEffect~=nil) then
            m_Time=cfg.guide.NoviceGuide.OPENDISPLAYTIME
            m_Count=true
        end   
    end
end

local function OpenStrech(objId)
    local result=false
    local strechOpen = 106  --加号按钮展开
    local strechClose = 186 --加号按钮关闭
    if (objId==strechOpen) or (objId==strechClose) then
        local ConfigManager=require"cfg.configmanager"
        local Tween_Close=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root/dlguimain/UIWidget_TopRight/UIGroup_FunctionsArea/UIGroup_ActivitiesClose/Tween_Close")
        if Tween_Close then
            if ((objId==strechOpen) and (Tween_Close.gameObject.transform.localScale.x~=0)) or ((objId==strechClose) and (Tween_Close.gameObject.transform.localScale.x==0)) then
                result=true
            end
        end
    end
    return result
end

local function SwitchToFindObjs()
    --printyellow("SwitchToFindObjs")
    m_GuideFsm=DefineEnum.NoviceGuideType.FINDOBJ
    local guideData=NoviceGuideManager.GetGuideData()
    local uiEffect=NoviceGuideManager.GetEffectByType("cfg.guide.LockUI")
    local objId=nil
    if uiEffect then
        objId=uiEffect.controlobject
    end
    if OpenStrech(objId)==true then
        SwitchToFinishGuide()
    else
        if (NoviceGuideLockObj.FindLockedObject(objId)==true) then
            SwitchToShowingGuide()
            m_AlreadyFindTimes=0
        else
            m_FindObjTime = TimeUtils.getTime()
            m_AlreadyFindTimes=m_AlreadyFindTimes+1                  
            if (m_AlreadyFindTimes > (cfg.guide.NoviceGuide.TOTALFINDOBJECTTIMES)) then  
                m_AlreadyFindTimes=0                     
                SwitchToCanNotFindObjs()
            end
        end
    end
end
--local function SwitchToHideObjs()
--    m_GuideFsm=DefineEnum.NoviceGuideType.HIDEOBJ
--    local hideDone = false
--    local guideData=NoviceGuideManager.GetGuideData()
--    if (#(guideData.hideobjects)>0) then
--        if (NoviceGuideLockObj.FindHideObjectList(guideData.hideobjects)) then
--            for _,lo in pairs(NoviceGuideManager.GetHideObjs()) do
--                lo.targetUIObject:SetActive(false)
--            end
--            hideDone = true
--        else
--            m_FindObjTime = TimeUtils.getTime()
--            m_AlreadyFindTimes=m_AlreadyFindTimes+1
--            if (guideData.isinectype == 0) then                    
--                if (m_AlreadyFindTimes > ((guideData.maxfindobjecttimes == 0) and cfg.guide.NoviceGuide.TOTALFINDOBJECTTIMES or guideData.maxfindobjecttimes)) then                       
--                    SwitchToCanNotFindObjs()
--                end
--            end
--        end
--    else
--        hideDone = true
--    end
--    if (hideDone) then
--        if (guideData.guidetype == cfg.guide.GuideType.UI) then
--            m_AlreadyFindTimes = 0
--            SwitchToFindObjs()
--        elseif (guideData.guidetype == cfg.guide.GuideType.DIRECT) then
--            SwitchToFinishGuide()
--        elseif (guideData.guidetype == cfg.guide.GuideType.NPCTALK) or (guideData.guidetype == cfg.guide.GuideType.GESTURE) or (guideData.guidetype == cfg.guide.GuideType.SOFTGUIDE) or (guideData.guidetype == cfg.guide.GuideType.HIGHLIGHT) or(guideData.guidetype == cfg.guide.GuideType.DYNAMICTEXTURE) then
--            SwitchToShowingGuide()
--        end
--     end
--end

local function UpdateTriggerNext()  
    local nextdata = NoviceGuideManager.GetNextGuideData()
    if (nextdata) then
        NoviceGuideTrigger.TriggerNext()
    end 
end

local function UpdateFindObjs()
    --printyellow("UpdateFindObjs")
    local guideData=NoviceGuideManager.GetGuideData()
    SwitchToFindObjs()
end

local function StopMove()
    if UIManager.isshow("noviceguide.dlgnoviceguide") then
        PlayerRole:StopNavigate()
    end
end

local function UpdateShowingGuide()
    local guideData=NoviceGuideManager.GetGuideData()
    if guideData then
        if (NoviceGuideTrigger.ContainNavigatingCondition(guideData.triggerconditions))==false then                          
            StopMove()
        end
    else
        StopMove()
    end
    if UIManager.isshow("updateattr.dlgupdateattribute") then
        UIManager.hide("updateattr.dlgupdateattribute")
    end
end

local function update()
    if NoviceGuideManager.IsGuiding() then
        if m_GuideFsm==DefineEnum.NoviceGuideType.TRIGGERNEXT then
            UpdateTriggerNext()
        elseif m_GuideFsm==DefineEnum.NoviceGuideType.FINDOBJ then
            UpdateFindObjs()      
        elseif m_GuideFsm==DefineEnum.NoviceGuideType.SHOWINGGUIDE then
            UpdateShowingGuide()
        end
        if m_Count==true then
            m_Time=m_Time-Time.deltaTime
            if m_Time<=0 then
                m_Count=nil
                m_Time=nil
                SwitchToFinishGuide()
            end
        end
    end   
end

local function init()
    NoviceGuideManager=require"noviceguide.noviceguidemanager"
    NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideLockObj=require"noviceguide.noviceguide_lockobject"
    NoviceGuideSyncServer=require"noviceguide.noviceguide_Syncserver"
end

return{
    init = init,
    update = update,
    SwitchToNone= SwitchToNone,
    SwitchToFindObjs = SwitchToFindObjs,
    SwitchToShowingGuide = SwitchToShowingGuide,
    SwitchToCanNotFindObjs = SwitchToCanNotFindObjs,
    SwitchToFinishGuide = SwitchToFinishGuide,
    NeedTriggerNext = NeedTriggerNext,
    SkipGuide = SkipGuide,
}