local NetWork=require"network"
local SettingManager=require"character.settingmanager"
local ConfigManager=require"cfg.configmanager"

local m_SyncServerOver=false
local m_PId=nil
local m_GuideIndex=nil
local m_NGKey="noviceguide"   --已完成指引key
local m_GoingNGKey="ongoingnoviceguide"  --正在执行中指引key
local m_ClearNGKey="clearnoviceguide"   --指引全部清除key

local function SendSetGuideConfigure(pId,guideIndex) --已完成指引(pId:指引父id guideIndex:指引索引值)
    local NoviceGuideManager=require"noviceguide.noviceguidemanager"
    NoviceGuideManager.InsertIntoExecutedTriggers(pId,guideIndex)
    local executedTriggers=NoviceGuideManager.GetExecutedTriggers()
    local msg=lx.gs.role.msg.CSetConfigure({key=m_NGKey,data=SettingManager.TableToString(executedTriggers)})
    NetWork.send(msg)
end

local function SendSetOnGoingGuide(pId,guideIndex)
    local onGoingGuide={}
    local text=""
    if (m_PId~=pId) or (m_GuideIndex~=guideIndex) then
        if pId and guideIndex then
            m_PId=pId
            m_GuideIndex=guideIndex
            onGoingGuide={pId=pId,index=guideIndex}
            text=SettingManager.TableToString(onGoingGuide)
        end
        local msg=lx.gs.role.msg.CSetConfigure({key=m_GoingNGKey,data=text})
        NetWork.send(msg)
    end
end

local function SendClearNoviceGuide()
    local msg=lx.gs.role.msg.CSetConfigure({key=m_ClearNGKey,data=""})
    NetWork.send(msg)
end

local function OnMsg_SGetConfigures(msg)
    --printyellow("OnMsg_SGetConfigures")
	if not cfg.guide then
		--todo 暂时屏蔽 实际应该有这个
		  return 
	end
    if cfg.guide.NoviceGuide.CONTROLLER==0 then
        return
    end
    local NoviceGuideManager=require"noviceguide.noviceguidemanager"
    if msg then
        --printt(msg)
        local noviceGuideSet=ConfigManager.getConfig("noviceguideset")
        local notExecutedTriggers={}
        if noviceGuideSet then
            --printt(noviceGuideSet)
            for _,data in pairs(noviceGuideSet) do
                notExecutedTriggers[data.id]=1
            end        
            for key,settingData in pairs(msg.datas) do
                local onGoingGuide={}
                if key==m_GoingNGKey then
                    onGoingGuide=SettingManager.StringToTable(settingData)
                    if onGoingGuide then
                        NoviceGuideManager.SetOnGoingGuide(onGoingGuide)
                    end
                    break
                end
            end
            for key,settingData in pairs(msg.datas) do
                local containOnGoing=false
                if key==m_NGKey then
                    local dataString=settingData
                    local executedTriggers=SettingManager.StringToTable(dataString)
                    NoviceGuideManager.SetExecutedTriggers(executedTriggers)
                    for pId,index in pairs(executedTriggers) do
                        if notExecutedTriggers[pId] then
                            if index==0 then   --已全部执行完
                                local onGoingGuide=NoviceGuideManager.GetOnGoingGuide()
                                if onGoingGuide then
                                    if onGoingGuide.pId==pId then
                                        containOnGoing=true
                                        NoviceGuideManager.SetOnGoingGuide(nil)
                                        SendSetOnGoingGuide()
                                    end
                                end
                                notExecutedTriggers[pId]=nil
                            else    --执行到某个保存点
                                local onGoingGuide=NoviceGuideManager.GetOnGoingGuide()
                                if onGoingGuide and onGoingGuide.pId and onGoingGuide.index then
                                    if onGoingGuide.pId==pId then
                                        containOnGoing=true
                                        if onGoingGuide.index<=index then
                                            NoviceGuideManager.SetOnGoingGuide(nil) 
                                            SendSetOnGoingGuide()
                                        else
                                            onGoingGuide.index=index
                                            NoviceGuideManager.SetOnGoingGuide(onGoingGuide)                                     
                                        end
                                    end
                                end
                                notExecutedTriggers[pId]=index+1
                            end                           
                        end
                    end
                end
                if containOnGoing==false then
                    local onGoingGuide=NoviceGuideManager.GetOnGoingGuide()
                    if onGoingGuide and onGoingGuide.pId then
                        onGoingGuide.index=1
                        NoviceGuideManager.SetOnGoingGuide(onGoingGuide)
                    end
                end
                if key==m_ClearNGKey then
                    notExecutedTriggers={}
                    NoviceGuideManager.SetOnGoingGuide(nil) 
                    SendSetOnGoingGuide()
                    break
                end                        
            end                      
            NoviceGuideManager.SetNotExecutedTriggers(notExecutedTriggers)
            NoviceGuideManager.CheckOnGoingGuide()
        end
    end
    m_SyncServerOver=true
end

local function IsSyncServerOver()
    return m_SyncServerOver
end

local function ClearData()
    m_SyncServerOver=false
end
    
local function init()
    m_SyncServerOver=false
    NetWork.add_listeners({
       {"lx.gs.role.msg.SGetConfigures", OnMsg_SGetConfigures },
    })
end

return{
    init = init,
    SendSetGuideConfigure = SendSetGuideConfigure,
    SendSetOnGoingGuide = SendSetOnGoingGuide,
    SendClearNoviceGuide = SendClearNoviceGuide,
    IsSyncServerOver = IsSyncServerOver,
    ClearData = ClearData,
}