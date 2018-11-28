local UIManager=require"uimanager"
local NetWork=require"network"

local m_NormalQueueNum=0
local m_NormalInfoQuene={}
local m_ImmediateInfoQueue={}

local function AddNormalInfo(params)
    if #m_NormalInfoQuene==0 then
        m_NormalQueueNum=0
    end
    params.id=m_NormalQueueNum+1
    table.insert(m_NormalInfoQuene,params)
    if UIManager.isshow("dlguimain") then
        UIManager.call("dlguimain","RefreshInfoButton")
    end
    return params.id
end

local function AddImmeInfo(params)
    m_ImmediateInfoQueue:Push(params)
end

local function AddInfo(params)
    if params.immediate==true then
        AddImmeInfo(params)
    else
        return AddNormalInfo(params)
    end
end

local function ShowInfo(params)
    if params.immediate==true then
        if  (UIManager.isshow("dlgalert_reminderimportant")) then
            AddImmeInfo(params)
        else
            UIManager.show("dlgalert_reminderimportant",params)
        end
    else
        if (#m_NormalInfoQuene==0) and (not UIManager.isshow("dlgalert_reminder")) and (not UIManager.isshow("dlgalert_reminderimportant"))then
            UIManager.show("dlgalert_reminder",params)
        else
            return AddNormalInfo(params)
        end
    end
end

local function DisplayNormalInfo()
    for i,value in pairs(m_NormalInfoQuene) do
        local info=value
        if info then
            UIManager.show("dlgalert_reminder",info)
            table.remove(m_NormalInfoQuene,i)
            break
        end
    end
    if UIManager.isshow("dlguimain") then
        UIManager.call("dlguimain","RefreshInfoButton")
    end
end

local function DelNormalInfo(id)
    for i,value in pairs(m_NormalInfoQuene) do
       if value and (value.id==id) then
          table.remove(m_NormalInfoQuene,i)
          break
       end
    end
    if UIManager.isshow("dlguimain") then
        UIManager.call("dlguimain","RefreshInfoButton")
    end
end

local function DisplayImmediateInfo()
    local info=m_ImmediateInfoQueue:Pop()
    if info then
        UIManager.show("dlgalert_reminderimportant",info)
    end
end

local function IsNormalEmpty()
    return (#m_NormalInfoQuene==0)
end
 
local function OnMsg_STips(msg)
    local content=""
    if msg.contentid then
        local ConfigManager=require"cfg.configmanager"
        local configData=ConfigManager.getConfigData("tipscontent",msg.contentid)
        if configData and configData.content then
            content=configData.content
        else
            content=msg.content
        end
    else
        content=msg.content
    end
    if content and content~="" then
        local index=0
        local result=string.gsub(content, "{}", function() index=index+1 return msg.param[index] or "" end)
        if msg.location==cfg.tips.LocationType.CENTER then
            UIManager.ShowSystemFlyText(result)
        elseif msg.location==cfg.tips.LocationType.RIGHT_DOWN then
            UIManager.ShowItemFlyText(result)
        elseif msg.location==cfg.tips.LocationType.CENTER_SCROLL then
            local PaoMaDengManager=require"paomadeng.paomadengmanager"
            PaoMaDengManager.PushBroadCastMsg(result)
        elseif msg.location==cfg.tips.LocationType.ALERT then
            UIManager.ShowSingleAlertDlg({content=result})
        end
    end
end

local function ClearData()
    m_NormalInfoQuene={}
    m_ImmediateInfoQueue=Queue:new()
    m_NormalQueueNum=0
end

local function NotifyIdolLogin(data)
    printyellow("NotifyIdolLogin")
    local msg = {
        location =  cfg.tips.LocationType.CENTER_SCROLL, 
        contentid = cfg.tips.TipsCode.IDOL_PROTECTOR_LOGIN,
        content = "",
        param = {[1] = data.m_IdolName, [2] = data.m_GuardName, },
    }
    OnMsg_STips(msg)
end

local function NotifyIdolNew(data)
    printyellow("NotifyIdolNew")
    local msg = {
        location =  cfg.tips.LocationType.CENTER_SCROLL, 
        contentid = cfg.tips.TipsCode.BECOME_IDOL_PROTECTOR,
        content = "",
        param = {[1] = data.m_GuardName, [2] = data.m_IdolName, },
    }
    OnMsg_STips(msg)
end

local function init(params)
    m_NormalInfoQuene={}
    m_ImmediateInfoQueue=Queue:new()
    NetWork.add_listeners({ 
      {"lx.gs.STips",OnMsg_STips},
      },"infoManager")

    gameevent.evt_system_message:add("logout",ClearData)
    gameevent.evt_notify:add("idolguard_login",NotifyIdolLogin)
    gameevent.evt_notify:add("idolguard_new",NotifyIdolNew)

end

return{
    init = init,
    ShowInfo = ShowInfo,
    AddInfo = AddInfo,
    DisplayNormalInfo = DisplayNormalInfo,
    DisplayImmediateInfo = DisplayImmediateInfo,
    IsNormalEmpty = IsNormalEmpty,
    DelNormalInfo = DelNormalInfo,
}