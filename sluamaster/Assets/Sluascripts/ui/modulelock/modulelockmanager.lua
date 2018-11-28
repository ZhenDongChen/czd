local NetWork=require"network"
local ConfigManager=require"cfg.configmanager"
local PlayerRole=require("character.playerrole"):Instance()
local UIManager=require"uimanager"

local m_UnLockTask={}
local m_UnLockMainModule={}
local m_UnLockDlgModule={}
local m_UnLockAllModules=false

local function CheckCondion(conId)
    local status=defineenum.ModuleStatus.UNLOCK
    local conData=ConfigManager.getConfigData("moduleunlockcond",conId)
    if conData then
        if conData.openlevel~=0 then
            if (conData.openlevel>PlayerRole:GetLevel()) then
                status= defineenum.ModuleStatus.LOCKED
            end
        elseif conData.opentaskid~=0 then
            if (m_UnLockTask[conData.opentaskid]==nil) then
                status= defineenum.ModuleStatus.LOCKED
            end
        end
    end
    return status
end

local function GetModuleStatusByType(type)
    if m_UnLockAllModules==true then
        return defineenum.ModuleStatus.UNLOCK
    else
        local moduleData=ConfigManager.getConfigData("uimainreddot",type)
        if moduleData then
            if moduleData.conid==0 then
                return defineenum.ModuleStatus.UNLOCK
            else
                for id,status in pairs(m_UnLockMainModule) do
                    if id==type then
                        return status
                    end
                end
                return CheckCondion(moduleData.conid)
            end
        else
            return defineenum.ModuleStatus.UNLOCK
        end     
        return defineenum.ModuleStatus.LOCKED
    end
end
-- UI界面中各个功能开启状态
-- 参数funcType为ui.xml里定义的枚举值UIFunctionList
local function GetUIFuncStatusByType(funcType)
    local uiFuncData=ConfigManager.getConfigData("uifunctionopen",funcType)
    if uiFuncData then
        if uiFuncData.conid==0 then
            return defineenum.ModuleStatus.UNLOCK
        else
            return CheckCondion(uiFuncData.conid)
        end
    end     
    return defineenum.ModuleStatus.LOCKED
end

local function GetModuleStatusByIndex(dlgName,index)
    if m_UnLockAllModules==true then
        return defineenum.ModuleStatus.UNLOCK
    else
        local dialogData=UIManager.getdialog(dlgName)
        if dialogData then
            if dialogData.parenttype~=cfg.ui.FunctionList.NONE then
                local parentStatus=GetModuleStatusByType(dialogData.parenttype)
                if parentStatus==defineenum.ModuleStatus.LOCKED then
                    return defineenum.ModuleStatus.LOCKED
                end
            end
        end
        local tabData=UIManager.gettabgroup(dlgName,index)
        if tabData then
            if (tabData.conid==0) then
                return defineenum.ModuleStatus.UNLOCK
            else
                for _,data in pairs(m_UnLockDlgModule) do
                    if data.dlgname==dlgName and data.index==index then
                        return data.status
                    end
                end
                return CheckCondion(tabData.conid)
            end
        end    
        return defineenum.ModuleStatus.LOCKED
    end
end

local function SetModuleStatusByType(type,status)
    m_UnLockMainModule[type]=status
end

local function SetModuleStateByIndex(dlgName,index,status)    
    for i,data in pairs(m_UnLockDlgModule) do
        if (data.dlgname==dlgName) and (data.index==index) then
            m_UnLockDlgModule[i].status=status
            return
        end 
    end
    table.insert(m_UnLockDlgModule,{dlgname=dlgName,index=index,status=status})
end

local function SetUnLockTask(id)
    if m_UnLockTask[id]==nil then
        m_UnLockTask[id]=1
    end
end

local function OnMsg_SGetConfigures(msg)
    if msg then        
        for key,settingData in pairs(msg.datas) do
            if key=="unlockallmodules" then
                m_UnLockAllModules=true
            end
        end
    end
end

local function OnMsg_STask(msg)
    m_UnLockTask={}
    if msg and msg.unlockcomtasks then
        for _,taskid in pairs(msg.unlockcomtasks) do
            m_UnLockTask[taskid]=1
        end
    end
end

--返回值：true表示已完成；false表示未完成
local function GetTaskStatus(taskId)
    local status=false
    if m_UnLockTask[taskId]~=nil then
        status=true
    end
    return status
end

local function IsContainModule(dlgName,index)
    local result=false
    for _,data in pairs(m_UnLockDlgModule) do
        if data.dlgname==dlgName and data.index==index then
            result=true
            break
        end
    end
    return result
end

local function OnPlayerLevelUp()
    local PrologueManager = require"prologue.prologuemanager"
    if PrologueManager.IsInPrologue() then
        return
    end
    local mainModuleData=ConfigManager.getConfig("uimainreddot")
    for _,module in pairs(mainModuleData) do
        if m_UnLockMainModule[module.functionname]==nil then
            if module.conid~=0 then
                local unlockData=ConfigManager.getConfigData("moduleunlockcond",module.conid)
                if unlockData and unlockData.openlevel~=0 then
                    if PlayerRole.m_Level>=unlockData.openlevel then
                        SetModuleStatusByType(module.functionname,defineenum.ModuleStatus.UNLOCK)
                        if UIManager.isshow("dlguimain") then
                            UIManager.call("dlguimain","RefreshModuleByType",module.functionname)
                        end
                        if UIManager.isshow("dlgmain_open") then
                            UIManager.call("dlgmain_open","RefreshModuleByType",module.functionname)
                        end
                    end
                end
            end
        end
    end
    local tabModuleData=ConfigManager.getConfig("dialog")
    for _,module in pairs(tabModuleData) do
        for index,group in pairs(module.tabgroups) do
            if (not IsContainModule(module.dlgname,index)) then
                if group.conid~=0 then
                    local unlockData=ConfigManager.getConfigData("moduleunlockcond",group.conid)
                    if unlockData and unlockData.openlevel~=0 then
                        if PlayerRole.m_Level>=unlockData.openlevel then
                            SetModuleStateByIndex(module.dlgname,index,defineenum.ModuleStatus.UNLOCK)
                        end
                    end  
                end  
            end
        end
    end
end

local function OnCompleteTask(taskId)
    local mainModuleData=ConfigManager.getConfig("uimainreddot")
    for _,module in pairs(mainModuleData) do
        if m_UnLockMainModule[module.functionname]==nil then
            if module.conid~=0 then
                local unlockData=ConfigManager.getConfigData("moduleunlockcond",module.conid)
                if unlockData and unlockData.opentaskid~=0 then
                    if taskId==unlockData.opentaskid then
                        SetModuleStatusByType(module.functionname,defineenum.ModuleStatus.UNLOCK)
                        SetUnLockTask(taskId)
                        if UIManager.isshow("dlguimain") then
                            UIManager.call("dlguimain","RefreshModuleByType",module.functionname)
                        end
                        if UIManager.isshow("dlgmain_open") then
                            UIManager.call("dlgmain_open","RefreshModuleByType",module.functionname)
                        end
                    end
                end
            end
        end
    end
    local tabModuleData=ConfigManager.getConfig("dialog")
    for _,module in pairs(tabModuleData) do
        for index,group in pairs(module.tabgroups) do
            if (not IsContainModule(module.dlgname,index)) then
                if group.condid~=0 then
                    local unlockData=ConfigManager.getConfigData("moduleunlockcond",group.conid)
                    if unlockData and unlockData.opentaskid~=0 then
                        if taskId==unlockData.opentaskid then
                            SetUnLockTask(taskId)
                            SetModuleStateByIndex(module.dlgname,index,defineenum.ModuleStatus.UNLOCK)
                        end
                    end
                end  
            end  
        end
    end
end

local function ClearData()
    m_UnLockTask={}
    m_UnLockMainModule={}
    m_UnLockDlgModule={}
    m_UnLockAllModules=false
end

local function init()
    gameevent.evt_system_message:add("logout",ClearData)
    NetWork.add_listeners({
       {"lx.gs.role.msg.SGetConfigures", OnMsg_SGetConfigures },
       {"lx.gs.task.msg.STask", OnMsg_STask},
    })
end

return{
    init                   = init,
    GetModuleStatusByType  = GetModuleStatusByType,
	GetUIFuncStatusByType  = GetUIFuncStatusByType,
    GetModuleStatusByIndex = GetModuleStatusByIndex,
    SetModuleStatusByType  = SetModuleStatusByType,
    SetModuleStateByIndex  = SetModuleStateByIndex,
    OnPlayerLevelUp        = OnPlayerLevelUp,
    OnCompleteTask         = OnCompleteTask,
    GetTaskStatus          = GetTaskStatus,
}