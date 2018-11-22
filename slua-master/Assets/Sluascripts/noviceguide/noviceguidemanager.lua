local NoviceGuideFSM
local NoviceGuideLockObj
local NoviceGuideSyncServer
local NoviceGuideTrigger
local UIManager=require"uimanager"
local AudioManager=require"audiomanager"
local ConfigManager=require"cfg.configmanager"
local EctypeManager=require"ectype.ectypemanager"
local network=require"network"

local m_PId=0
local m_GuideId=0
local m_Locked=false
local m_GuideData=nil
local m_GuideList={}
local m_GuideIndex=-1
local m_GuideFinishTaskExec=false
local m_NeedPauseGame=false
local m_LockedObj=nil
local m_Collider=nil
local m_ExecutedTriggers={}
local m_NotExecutedTiggers={}  --key:pId value:index
local m_OnGoingGuide=nil
local m_IsChecking=false
--local m_ClickTime=0
local m_CallBack=nil
local m_DisplayEffect=false
local m_TargetId=nil
local m_AudioSource=nil

local function IsGuiding()
    return m_GuideId~=0
end

local function GetPId()
    return m_PId
end

local function GetGuideId()
    return m_GuideId
end

local function GetGuildExec()
	return m_GuideFinishTaskExec
end

local function isDisableGuide()
	local selectedServer = network.getSelectedServer()
	return selectedServer and selectedServer.bDisableGuide and selectedServer.bDisableGuide==1
end

---关闭新手引导
local function GetGuideData()
    -- 暂时屏蔽引导
    -- if true then return nil end
	if isDisableGuide() then return nil end
	
    return m_GuideData
end

local function GetGuideIndex()
    return m_GuideIndex
end

local function GetLockedObj()
    return m_LockedObj
end

local function GetCollider()
    return m_Collider
end

local function GetNotExecutedTriggers()
    return m_NotExecutedTiggers
end

local function GetExecutedTriggers()
    return m_ExecutedTriggers
end

--local function GetClickTime()
--    return m_ClickTime
--end

local function GetCallBack()
    return m_CallBack
end

local function GetDelayTime()
    return m_GuideData.delaytime
end

local function GetDisplayEffect()
    return m_DisplayEffect
end

local function GetTargetId()
    return m_TargetId
end

--local function SetClickTime(time)
--    m_ClickTime=time
--end

local function InsertIntoExecutedTriggers(pId,index)
    m_ExecutedTriggers[pId]=index
end

local function SetExecutedTriggers(triggerList)
    m_ExecutedTriggers=triggerList
end

local function SetCallBack(callBack)
    m_CallBack=callBack
end

local function SetDisplayEffect(result)
    m_DisplayEffect=result
end

local function SetTargetId(id)
    m_TargetId=id
end

local function GetOnGoingGuide()
    return m_OnGoingGuide
end

local function IsNeedPauseGame()
    return m_NeedPauseGame
end

local function IsMandatory()
    return m_GuideData.ismandatory
end

local function IsLocked()
    return m_Locked
end

local function SetLocked(result)
    m_Locked=result
end

local function SetPauseGame(pause)
    m_NeedPauseGame=pause
end

local function SetLockedObj(obj)
    m_LockedObj=obj
end

local function SetNotExecutedTriggers(triggerList)
    m_NotExecutedTiggers=triggerList
end

local function SetOnGoingGuide(guide)
    --printyellow("SetOnGoingGuide")    
    m_OnGoingGuide=guide
    --printt(m_OnGoingGuide)
end

local function IsNewGuide(guideId)
    local result=-1
    if m_GuideList then
        for index,id in pairs(m_GuideList) do
            if id==guideId then
                result=index
                break
            end
        end
    end
    return result
end

local function HasNextGuide()
--    printyellow("HasNextGuide")
--    printt("#m_GuideList:",#m_GuideList)
--    printyellow("m_GuideIndex:",m_GuideIndex)
    return (#m_GuideList>0) and (m_GuideIndex < #m_GuideList)
end

local function GetNextGuideId()
    local guideId = 0
    if IsGuiding and m_GuideList and (#m_GuideList>0) and (m_GuideIndex < #m_GuideList) then
        guideId = m_GuideList[m_GuideIndex+1]
    end
    return guideId
end

local function GetNextGuideData()
    local data
    local nextGuideId=GetNextGuideId()
    if nextGuideId then
        data=ConfigManager.getConfigData("noviceguide",nextGuideId)
    end
    return data
end

local function GetGuideListById(guideId)
    local result={}
    local setData=ConfigManager.getConfig("noviceguideset")
    for _,value in pairs(setData) do
        for _,subId in pairs(value.subset) do
            if subId==guideId then
                result=value.subset
            end
        end
    end
    return result
end

local function GetDataByPIdAndIndex(pId,index)
    local guideData=nil
    local pData=ConfigManager.getConfigData("noviceguideset",pId)
    if pData then
        local guideId=pData.subset[index]
        if guideId then
            guideData=ConfigManager.getConfigData("noviceguide",guideId)
        end
    end
    return guideData
end

local function GetAudioSource()
    if IsNull(m_AudioSource) then
        local obj=GameObject("noviceaudio")
        local uiRoot = LuaHelper.FindGameObject("/UI Root (2D)/UI_Root")
        obj.transform.parent=uiRoot.transform
        m_AudioSource=obj:AddComponent(AudioSource)
    end
    return m_AudioSource
end

local function PlayAudio(audio)
    if audio then
        local data=ConfigManager.getConfigData("audio",audio)
        if data then
            AudioManager.PlaySoundBySelfAudioSource(audio,GetAudioSource())
        end
    end
end

local function StopAudio()
    if m_AudioSource then
        m_AudioSource:Stop()
    end
end

local function GetEffectByType(type)
    local needEffect=nil
    if m_GuideData then
        local guideEffect=m_GuideData.guideeffect
        if guideEffect then   
            for _,effect in pairs(guideEffect) do
                if effect.class==type then
                    needEffect=effect
                    break
                end
            end
        end
    end
    return needEffect
end

local function DisplayUI()
    if UIManager.isshow("dlguimain") then
        local DlgUIMain=require"ui.dlguimain"
        DlgUIMain.OnGuideShowTask()
        local DlgUIMainHide=(require"ui.dlguimain_hide")
        DlgUIMainHide.ChangeHideMode()        
    end
end

local function ShowGuideDlg()
    if UIManager.isshow("updateattr.dlgupdateattribute") then
        UIManager.hide("updateattr.dlgupdateattribute")
    end
    DisplayUI()
    if (GetEffectByType("cfg.guide.LockUI")~=nil) or (GetEffectByType("cfg.guide.HightLight")~=nil) then
        NoviceGuideFSM.SwitchToFindObjs()
    else
        NoviceGuideFSM.SwitchToShowingGuide()
    end
end

local function CloseGuideDlg()
    if (UIManager.isshow("noviceguide.dlgnoviceguide")) then
        UIManager.hide("noviceguide.dlgnoviceguide")
    end
    NoviceGuideLockObj.FreeUIObj()
	
	
end

local function ResetGuide()
    NoviceGuideFSM.SwitchToNone()
    --printyellow("++++++++")
    m_PId=0
    m_GuideId=0
    m_Locked=false
    m_GuideData=nil
    m_GuideList={}
    m_GuideIndex=-1
    m_NeedPauseGame=false
    m_LockedObj={}
    m_Collider={}   
    --m_ClickTime=0 
    m_DisplayEffect=false
    m_TargetId=nil  
    m_OnGoingGuide=nil
    m_IsChecking=false
    m_CallBack=nil
    m_DisplayEffect=false
    m_TargetId=nil
	m_GuideFinishTaskExec = false
end

local function ShowGuide(pId,index)
    ResetGuide()
    local guideData=GetDataByPIdAndIndex(pId,index)
    if guideData then
        m_PId=pId
        m_GuideIndex = index
        m_GuideData = guideData
        m_GuideId=guideData.id
        m_GuideList = ConfigManager.getConfigData("noviceguideset",pId).subset    
		m_GuideFinishTaskExec = ConfigManager.getConfigData("noviceguideset",pId).finishauto
        m_NeedPauseGame=guideData.ispause      
        ShowGuideDlg()
    end
end

local function ShowNextGuide()
    m_GuideIndex=m_GuideIndex+1
    m_GuideId=m_GuideList[m_GuideIndex]
    m_GuideData=ConfigManager.getConfigData("noviceguide",m_GuideId)
    m_NeedPauseGame=m_GuideData.ispause      
    ShowGuideDlg()
    --m_ClickTime=0
end

local function CheckTriggerCondition(triggerconditions)
    local validate=false
    local i=0
    for _,condition in pairs(triggerconditions) do
        if condition.class=="cfg.cmd.condition.DisplayDlg" then
            i=i+1
            if UIManager.isshow(condition.dialogname) then
                validate=true
                break
            end
        end
    end
    if i==0 then
        validate=true
    end
    return validate
end

--[[
--检查是否有正在执行的指引，有：如果是非强制指引则跳过;如果是强制指引，判断是否满足触发条件，不满足则跳过判断下一条，满足则执行当前指引
]]--
local function CheckOnGoingGuide()
    --printyellow("CheckOnGoingGuide")
    if m_OnGoingGuide and m_OnGoingGuide.pId and m_OnGoingGuide.index then
        --printyellow("pId:",m_OnGoingGuide.pId,"m_OnGoingGuide.index:",m_OnGoingGuide.index)
        local pId=m_OnGoingGuide.pId
        local index=m_OnGoingGuide.index
        local guideData=GetDataByPIdAndIndex(pId,index)
        local guideSetData=ConfigManager.getConfigData("noviceguideset",pId)
        if guideData and guideData.ismandatory then
            --printyellow("NoviceGuideTrigger.CanTriggerGuide():",NoviceGuideTrigger.CanTriggerGuide())
            if NoviceGuideTrigger.CanTriggerGuide()==true and CheckTriggerCondition(guideData.triggerconditions)==true then
                m_IsChecking=false
                local i=0
                local j=0              
                for _,condition in pairs(guideData.triggerconditions) do
                    i=i+1
                    if condition.class=="cfg.cmd.condition.CompleteTask" then
                        local TaskManager=require"taskmanager"
                        if TaskManager.GetTaskStatus(condition.taskid)==defineenum.TaskStatusType.Completed then
                            j=j+1
                        end
                    else
                        if NoviceGuideTrigger.SatisfyTriggerCondition(condition) then
                            j=j+1
                        end
                    end
                end
                if (i==j) then
                    ShowGuide(pId,index)
                else               
                    if guideSetData then
                    local guideSet=guideSetData.subset
                    index=index+1
                    while(index<=#guideSet) do
                        local guideData=GetDataByPIdAndIndex(pId,index)
                        if guideData.issavepoint then
                            break
                        else
                            index=index+1
                        end
                    end
                    end
                    NoviceGuideSyncServer.SendSetOnGoingGuide()
                    if index<#guideSetData then
                    NoviceGuideSyncServer.SendSetGuideConfigure(pId,index)
                    m_NotExecutedTiggers[pId]=index+1
                    else
                    NoviceGuideSyncServer.SendSetGuideConfigure(pId,0)
                    m_NotExecutedTiggers[pId]=nil
                    end
                end               
            else
                m_IsChecking=true
            end
        else
            NoviceGuideSyncServer.SendSetOnGoingGuide()
        end
    end
end

local function update()     
    NoviceGuideFSM.update()
    if m_IsChecking==true then
        CheckOnGoingGuide()
    else
        NoviceGuideTrigger.update()
    end
end

local function ClearData()
    NoviceGuideSyncServer.ClearData()
    NoviceGuideTrigger.ClearData()
    m_ExecutedTriggers={}
    m_NotExecutedTiggers={}    
    
    ResetGuide()
end

local function BreakLine()
    if IsGuiding() then
        NoviceGuideFSM.SkipGuide()
    end
end

local function init()
    NoviceGuideFSM=require"noviceguide.noviceguide_fsm"
    NoviceGuideLockObj=require"noviceguide.noviceguide_lockobject"
    NoviceGuideSyncServer=require"noviceguide.noviceguide_syncserver"
    NoviceGuideTrigger=require"noviceguide.noviceguide_trigger"
    NoviceGuideFSM.init()
    NoviceGuideLockObj.init()
    NoviceGuideSyncServer.init()
    NoviceGuideTrigger.init()
    gameevent.evt_update:add(update)
    gameevent.evt_system_message:add("logout",ClearData)
    gameevent.evt_notify:add("plotcutscene_load",BreakLine)
end

local function HasFinishedGuide(guideId)
    local result=true
    if m_GuideList then
        for pId,index in pairs(m_NotExecutedTiggers) do
            if pId==guideId then
                result=false
                break
            end
        end
    end
    return result
end

--local function TestSkillEffect()
--    local DlgUIMain_Combat=require"ui.dlguimain_combat"
--    local target=DlgUIMain_Combat.GetSkillItemPos(90007)
--    local targetPos=Vector3(target.x,target.y,0)
--    local DefineEnum=require"defineenum"
--    local CurveModelManager=require"character.curve.curvemodelmanager"
--    local curveType=DefineEnum.TraceType.Line2D   
--    Util.Load(string.format("sfx/s_%s.bundle", "ui_unlock"), define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
--        if IsNull(asset_obj) then
--            return
--        end       
--        local effectObject=GameObject.Instantiate(asset_obj)   
--        local root=LuaHelper.FindGameObject("/UI Root (2D)/UI_Root")
--        effectObject.transform.parent=root.gameObject.transform    
--        effectObject.transform.localPosition = Vector3.zero
--        effectObject:SetActive(true)
--        CurveModelManager.AddCurveData(effectObject,function()    
--        end,curveType,targetPos)
--    end)
--end

return{
    init = init,
    update = update,
    GetPId = GetPId,
    GetGuideId = GetGuideId,
	GetGuildExec = GetGuildExec,
    GetGuideIndex = GetGuideIndex,
    GetGuideData = GetGuideData,
    GetDelayTime = GetDelayTime,
    GetLockedObj = GetLockedObj,
    GetCollider = GetCollider,
    GetExecutedTriggers = GetExecutedTriggers,
    GetNotExecutedTriggers = GetNotExecutedTriggers,
    GetOnGoingGuide = GetOnGoingGuide,
    GetDataByPIdAndIndex = GetDataByPIdAndIndex,
    GetEffectByType = GetEffectByType,
    GetDisplayEffect = GetDisplayEffect,
    GetTargetId = GetTargetId,
    InsertIntoExecutedTriggers = InsertIntoExecutedTriggers,
    SetLockedObj = SetLockedObj,
    SetNotExecutedTriggers = SetNotExecutedTriggers,
    SetExecutedTriggers = SetExecutedTriggers,
    SetOnGoingGuide = SetOnGoingGuide,
    SetDisplayEffect = SetDisplayEffect,
    SetTargetId = SetTargetId,
    IsGuiding = IsGuiding,
    IsMandatory = IsMandatory,
    IsLocked = IsLocked,
    IsNeedPauseGame = IsNeedPauseGame,
    ShowGuide = ShowGuide,
    ShowNextGuide = ShowNextGuide,
    CloseGuideDlg = CloseGuideDlg,
    HasNextGuide = HasNextGuide, 
    GetNextGuideData = GetNextGuideData,
    GetNextGuideId = GetNextGuideId,
    ResetGuide = ResetGuide,
    CheckOnGoingGuide = CheckOnGoingGuide,
    --SetClickTime = SetClickTime,
    --GetClickTime = GetClickTime,
    SetCallBack = SetCallBack,
    GetCallBack = GetCallBack,
    HasFinishedGuide = HasFinishedGuide,
    --TestSkillEffect = TestSkillEffect,
    PlayAudio = PlayAudio,
    StopAudio = StopAudio,
    BreakLine = BreakLine,
    GetAudioSource = GetAudioSource,
}