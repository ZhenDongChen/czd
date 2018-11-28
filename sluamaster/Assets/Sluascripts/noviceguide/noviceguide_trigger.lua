local NoviceGuideFsm
local NoviceGuideManager
local NoviceGuideSyncServer
local PlayerRole=(require"character.playerrole"):Instance()
local SceneManager=require"scenemanager"
local ConfigManager=require"cfg.configmanager"
local UIManager=require"uimanager"
local CheckCmd=require"common.checkcmd"
local PlotManager=require"plot.plotmanager"
local TaskManager

--local m_CanUpdate=true
local m_UpdateInterval=0
local m_TriggerNextTime=0
local m_CanNotTriggerGuideUIList={
    [1]="dlgloading",
    [2]="dlglogin",
    [3]="dlgchooseplayer",
    [4]="dlgtask",
    [5]="updateattr.dlgupdateattribute",
    [6]="noviceguide.dlgunlock",
}

local function IsShowSpecialUI()
    local validate=false
    for _,uiName in pairs(m_CanNotTriggerGuideUIList) do
        if UIManager.isshow(uiName) then
            validate=true
            break
        end
    end
    return validate
end

local function CanTriggerGuide()   
    local validate=true
    local UIManager=require"uimanager"
    if SceneManager.IsLoadingScene() or PlayerRole:IsNavigating() or PlayerRole:IsFlyNavigating() or PlotManager.IsPlayingCutscene() or (IsShowSpecialUI()==true) then
        validate=false
    end
    --printyellow("CanTriggerGuide:",validate)
    return validate
end

local function CanTriggerGuideIncludeNavigating()
    local validate=true
    local UIManager=require"uimanager"
    if SceneManager.IsLoadingScene()  or PlotManager.IsPlayingCutscene() or (IsShowSpecialUI()==true) then
        validate=false
    end
    return validate
end

local function ClickAnyWhere()
   -- printyellow("ClickAnyWhere")
    if (NoviceGuideManager.GetEffectByType("cfg.guide.ClickOver")~=nil) or (NoviceGuideManager.GetEffectByType("cfg.guide.Display")~=nil) or (NoviceGuideManager.GetEffectByType("cfg.guide.DisplaySkill")~=nil) then
        NoviceGuideFsm.SwitchToFinishGuide()
--    else
--        if NoviceGuideManager.GetClickTime()>=5 then
--            NoviceGuideManager.SetClickTime(0)
--            NoviceGuideFsm.SkipGuide()           
--        else
--            NoviceGuideManager.SetClickTime(NoviceGuideManager.GetClickTime()+1)
--        end
    end
end

local function ClickUIObjectComplete(trans)
    --printyellow("ClickUIObjectComplete")
    local guideData=NoviceGuideManager.GetGuideData()
    local lockedObject=NoviceGuideManager.GetLockedObj()
    --printyellow("----------")
    if lockedObject.collider or lockedObject.tempCollider then
        --printyellow("lockedObject.collider:",lockedObject.collider)
        --printt(trans.name)
        --printt(lockedObject.collider.gameObject.transform.name)
        if (lockedObject.collider.gameObject.transform == trans) or (lockedObject.tempCollider and lockedObject.tempCollider.gameObject.transform==trans) then
            if (lockedObject.lockedObjectData.id==106) and (trans.name=="UIButton_Stretch") then
                local playtweens=lockedObject.collider.gameObject:GetComponents(UIPlayTween)
                for i=1,playtweens.Length do
                    playtweens[i]:Play(true)
                end
            end
            NoviceGuideFsm.SwitchToFinishGuide()
        end
    end
end

local function ClickUIObject(trans)
    --printyellow("ClickUIObject")
    local guideData=NoviceGuideManager.GetGuideData()
    if (NoviceGuideManager.IsGuiding()) and guideData and (NoviceGuideManager.GetEffectByType("cfg.guide.LockUI")~=nil) and (NoviceGuideManager.GetLockedObj()~=nil) then  
        if not IsNull(trans) then        
            ClickUIObjectComplete(trans)
        end
    end
end

local function SatisfyTriggerCondition(condition)
    local result=false
    result=CheckCmd.CheckData({data=condition,showsysteminfo=false,num=1})
    --printyellow("SatisfyTriggerCondition:",result)
    return result
end

local function CompleteTask(taskId)
--    printyellow("Completetask:",taskId)
    local notExecutedTriggers=NoviceGuideManager.GetNotExecutedTriggers()
    if notExecutedTriggers then      
        for id,index in pairs(notExecutedTriggers) do
            local guideData=NoviceGuideManager.GetDataByPIdAndIndex(id,index)         
            if guideData and guideData.triggerconditions then
                if not NoviceGuideManager.IsGuiding() then     
                    local result=false              
                    for _,condition in pairs(guideData.triggerconditions) do
                        if condition.class=="cfg.cmd.condition.CompleteTask" and condition.taskid==taskId then
 --                           printyellow("completetask")
                            result=true
                        else
                            if not SatisfyTriggerCondition(condition) then
--                                printt(condition)
                                result=false
                                break
                            end
                        end
                    end
                    if result then    
                        NoviceGuideSyncServer.SendSetOnGoingGuide(id,index)
                        NoviceGuideManager.ShowGuide(id,index) 
                        break  
                    end                         
                end
            end
        end            
    end
end

local function PlayCGOver(cgId)
    local notExecutedTriggers=NoviceGuideManager.GetNotExecutedTriggers()
    if notExecutedTriggers then      
        for id,index in pairs(notExecutedTriggers) do
            local guideData=NoviceGuideManager.GetDataByPIdAndIndex(id,index)         
            if guideData and guideData.triggerconditions then
                if not NoviceGuideManager.IsGuiding() then     
                    local result=false              
                    for _,condition in pairs(guideData.triggerconditions) do
                        if condition.class=="cfg.cmd.condition.PlayCGOver" and condition.cgids then
                            local CGId=condition.cgids[PlayerRole.m_Profession]
                            if CGId and CGId==cgId then
 --                           printyellow("completetask")
                                result=true
                            end
                        else
                            if not SatisfyTriggerCondition(condition) then
--                                printt(condition)
                                result=false
                                break
                            end
                        end
                    end
                    if result then    
                        NoviceGuideSyncServer.SendSetOnGoingGuide(id,index)
                        NoviceGuideManager.ShowGuide(id,index) 
                        break  
                    end                         
                end
            end
        end            
    end
end

local function Rotate()  --视角旋转
    --printyellow("Rotate")
    if NoviceGuideManager.IsGuiding() then
        local sliderData=NoviceGuideManager.GetEffectByType("cfg.guide.Slider")
        if (sliderData~=nil) and (sliderData.type==0) then
            NoviceGuideFsm.SwitchToFinishGuide()
        end
    end
end

local function MoveJoy()
    --printyellow("MoveJoy")
    if NoviceGuideManager.IsGuiding() then
        local lockObj=NoviceGuideManager.GetLockedObj()
        if lockObj and lockObj.lockedObjectData and lockObj.lockedObjectData.controldlg=="dlgjoystick" then
            NoviceGuideFsm.SwitchToFinishGuide()
        end
    end
end

local function HideDialog(viewName)
--    printyellow("HideDialog:",viewName)
    if NoviceGuideManager.IsGuiding() and (viewName~="noviceguide.dlgnoviceguide") and (viewName~="dlgopenloading") then
        if (not NoviceGuideManager.IsMandatory()) then
            NoviceGuideFsm.SwitchToFinishGuide()
        end 
    end
    if  (viewName=="dlguimain") then
        if UIManager.isshow("noviceguide.dlgunlock") then
            UIManager.hide("noviceguide.dlgunlock")
        end
    end
end

local function ContainTaskCondition(triggerconditions)
    if triggerconditions then
        for _,condition in pairs(triggerconditions) do
            if condition then
                if (condition.class=="cfg.cmd.condition.OwnTask") or (condition.class=="cfg.cmd.condition.CompleteTask") then
                    return true
                end
            end
        end
    end
    return false
end

local function ContainNavigatingCondition(triggerconditions)
    if triggerconditions then
        for _,condition in pairs(triggerconditions) do
            if condition then
                if (condition.class=="cfg.cmd.condition.IsNavigating") then
                    return true
                end
            end
        end
    end
    return false
end

local function CanTriggerInEctype(guideData)
   -- printyellow("CanTriggerInEctype:")
    local validate=true
    local EctypeManager=require"ectype.ectypemanager"
    if (guideData.isinectype==false) then
        if EctypeManager.IsInEctype() then 
            validate=false
        end
    end  
    return validate
end

local function Trigger()
    --printyellow("Trigger")
    local notExecutedTriggers=NoviceGuideManager.GetNotExecutedTriggers()
    --printt(notExecutedTriggers)
    if notExecutedTriggers then      
        for id,index in pairs(notExecutedTriggers) do
            --printyellow("id:",id,"index:",index)
            local guideData=NoviceGuideManager.GetDataByPIdAndIndex(id,index)         
            if guideData and (SatisfyTriggerCondition(guideData.triggerconditions)==true) and CanTriggerInEctype(guideData) then
                if (CanTriggerGuide()) or (CanTriggerGuideIncludeNavigating() and ContainNavigatingCondition(guideData.triggerconditions)) then
                    if not NoviceGuideManager.IsGuiding() then
                    --printyellow("id:",id,"index:",index)
                        NoviceGuideSyncServer.SendSetOnGoingGuide(id,index)
                        NoviceGuideManager.ShowGuide(id,index)
                    else
                        local guidingData=NoviceGuideManager.GetGuideData()
                        if guidingData then
                            if guidingData.ismandatory==false then
                                NoviceGuideSyncServer.SendSetOnGoingGuide(id,index)
                                NoviceGuideManager.ShowGuide(id,index)
                            end
                        end
                    end
                    break
                end
            end
        end            
    end
end

--local function TriggerById(id,callBack)
--    local guideData=NoviceGuideManager.GetDataByPIdAndIndex(id,1)         
--    if guideData and (SatisfyTriggerCondition(guideData.triggerconditions)==true) and CanTriggerGuide() and CanTriggerInEctype(guideData) then
--        NoviceGuideManager.SetCallBack(callBack)
--        NoviceGuideSyncServer.SendSetOnGoingGuide(id,1)
--        NoviceGuideManager.ShowGuide(id,1)
--    end
--end

local function TriggerNext()
    if (NoviceGuideFsm.NeedTriggerNext()) then
        local nextGuideId = NoviceGuideManager.GetNextGuideId()
        local nextGuideData = ConfigManager.getConfigData("noviceguide",nextGuideId)
        if nextGuideData then
            if (#(nextGuideData.triggerconditions) == 0) or (#(nextGuideData.triggerconditions)>0 and SatisfyTriggerCondition(nextGuideData.triggerconditions)) then
                if nextGuideId==1210 then  --判断一下玩家是否拥有法宝
                    if PlayerRole:GetTalisman()~=nil then
                        m_TriggerNextTime=0
                        NoviceGuideFsm.SkipGuide()
                    else
                        NoviceGuideSyncServer.SendSetOnGoingGuide(NoviceGuideManager.GetPId(),NoviceGuideManager.GetGuideIndex()+1)
                        NoviceGuideManager.ShowNextGuide()  
                        m_TriggerNextTime=0
                    end
                else
                    NoviceGuideSyncServer.SendSetOnGoingGuide(NoviceGuideManager.GetPId(),NoviceGuideManager.GetGuideIndex()+1)
                    NoviceGuideManager.ShowNextGuide()  
                    m_TriggerNextTime=0
                end 
            else
                m_TriggerNextTime=m_TriggerNextTime+Time.deltaTime
                if (m_TriggerNextTime>=cfg.guide.NoviceGuide.TRIGGERNEXTGUIDETIME) then
                    m_TriggerNextTime=0
                    NoviceGuideFsm.SkipGuide()
                end 
            end 
            
        end                             
    end
end

local function SetUpdateInterval()
    m_UpdateInterval=0
end

local function update()
    if (not NoviceGuideManager.IsGuiding()) then
        m_UpdateInterval=m_UpdateInterval+Time.deltaTime
        if m_UpdateInterval and (m_UpdateInterval>=0.5) then
            m_UpdateInterval=0
            if (NoviceGuideSyncServer.IsSyncServerOver()==true) then
                Trigger()
            end
        end
    end
--    elseif Input.GetMouseButtonDown(0) or ((Input.touchCount > 0) and (Input.GetTouch(0).phase == TouchPhase.Began)) then 
--        printyellow("touch")  
--        m_Click=true
----            if UICamera.hoveredObject then
------                ClickUIObject(UICamera.hoveredObject.transform)
----                printyellow("ClickUIObject",UICamera.hoveredObject.transform.gameObject.name)
----            end
--        if UICamera.currentTouch then
--            m_Click=false
--            ClickUIObject(UICamera.currentTouch.current.transform)
--             printyellow("ClickUIObject",UICamera.currentTouch.current.transform.name)
--        end
----    else
----        local lockedObject=NoviceGuideManager.GetLockedObj()
----        if lockedObject.collider then
----            if UICamera.IsPressed(lockedObject.collider.gameObject) then
----                ClickUIObject(lockedObject.collider.gameObject.transform)
----            end
----        end
--    elseif m_Click==true then
--        printyellow("m_Click:true")
--        printt(UICamera.currentTouch)
--        if UICamera.currentTouch then
--            m_Click=false
--            ClickUIObject(UICamera.currentTouch.current.transform)
--            printyellow("ClickUIObject:1",UICamera.currentTouch.current.transform.name)
--        end
--    
--    else
--        if UICamera.onClick then
--        printyellow("onClick")
--        if UICamera.currentTouch then
--            ClickUIObject(UICamera.currentTouch.current.transform)
--            printyellow("ClickUIObject:1",UICamera.currentTouch.current.transform.name)
--        end
--        end
--    end
end

local function ResetTriggerNextTime()
    m_TriggerNextTime=0
end

local function ClearData()
    m_UpdateInterval=0
    m_TriggerNextTime=0
end

local function init()
    NoviceGuideFsm=require"noviceguide.noviceguide_fsm"
    NoviceGuideManager=require"noviceguide.noviceguidemanager"
    NoviceGuideSyncServer=require"noviceguide.noviceguide_syncserver"
    TaskManager=require"taskmanager"
    m_UpdateInterval=0
end

return{
    update = update,
    init = init,
    TriggerNext =TriggerNext,
    SatisfyTriggerCondition = SatisfyTriggerCondition,
    Rotate = Rotate,
    MoveJoy = MoveJoy,
    HideDialog = HideDialog,
    SetUpdateInterval =SetUpdateInterval,
    ClickAnyWhere = ClickAnyWhere,
    ClickUIObject = ClickUIObject,
    CanTriggerGuide = CanTriggerGuide,
	  CompleteTask = CompleteTask,
	  PlayCGOver = PlayCGOver,
	  ContainNavigatingCondition = ContainNavigatingCondition,
	  ClearData = ClearData,
	  ResetTriggerNextTime = ResetTriggerNextTime,
	  --TriggerById = TriggerById,
}
