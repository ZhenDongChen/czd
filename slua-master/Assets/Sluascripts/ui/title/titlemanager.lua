
local NetWork 				= require("network")
local ConfigManager         = require("cfg.configmanager")
local UIManager             = require("uimanager")
local GameEvent             = require("gameevent")

local Title                 = require("ui.title.info.titleinfo")
local TitleGroup            = require("ui.title.info.titlegroup")
-------------------------------------------------------------------------------------
local AlertList = {
    ExpireList = {},
}

------------------------------------------------------------------------------------------------
local TitleGroupList = {}
local listenerIds
local loveName = ""

local function GetAllLocalTitle()
    local titleTypeName = ConfigManager.getConfig("titletypename")
    if titleTypeName == nil then
        return
    end
    for ki = 1, #titleTypeName do
        TitleGroupList[ki] = TitleGroup:new(ki,titleTypeName[ki].typename)
    end
    
    for id,value in pairs(ConfigManager.getConfig("title")) do
        if TitleGroupList[value.titletype] == nil then
            TitleGroupList[value.titletype] = TitleGroup:new(value.titletype,value.titletypename)
        else
            TitleGroupList[value.titletype]:Add(value)
        end
    end

    for _,group in pairs(TitleGroupList) do
        group:Sort()
    end

end

local function GetGroupNumber()
    return #TitleGroupList
end
-------------------------------------------------------------------------------------
local function GetCurrentEquipedTitle()
    return PlayerRole:Instance().m_Title
end

local function EquipTitle(title)
    --printyellowmodule(Local.LogModuals.Title,"EquipTitle",title:GetName())
    PlayerRole:Instance():ChangeTitle(title.m_Id)
  --  UIManager.refresh("")
    if UIManager.isshow("title.tabtitle") then
        UIManager.call("title.tabtitle","RefreshWithoutSort")
    end
end

local function UnEquipTitle(title)
    --printyellowmodule(Local.LogModuals.Title,"UnEquipTitle",PlayerRole:Instance().m_Title:GetName())
    if PlayerRole:Instance().m_Title and title.m_Id == PlayerRole:Instance().m_Title.m_Id then
        PlayerRole:Instance():ChangeTitle(nil)
    end
    --UIManager.refresh("title.tabtitle")
    if UIManager.isshow("title.tabtitle") then
        UIManager.call("title.tabtitle","RefreshWithoutSort")
    end
end

local function GetTitleFromGroupList(titletype,titlekey)
    local group = TitleGroupList[titletype]
    if group ~= nil then
        local title = group:GetTitleById(titlekey)
        if title ~= nil then
            return title
        end
    end
end

local function GetTitleById(titlekey)
    for _, group in pairs(TitleGroupList) do
        local title = group:GetTitleById(titlekey)
        if title ~= nil then
            return title
        end
    end
    return nil
end


local function GetTitleGroup(titletype)
    --printt(TitleGroupList)
    return TitleGroupList[titletype]
end

local function SetTitleServerMsg(title, msgTitle)
    title.m_IsActive = ((msgTitle.state == 0) and false) or true
    title.m_ObtainedTime = msgTitle.gettime/1000
    title.m_EquipTime = msgTitle.activetime/1000
    title.m_Expiretime = msgTitle.expiretime/1000
end
--获取所有特性
local function GetAllProperty()
    local properties = {}
    local num = 0
    for i, group in pairs(TitleGroupList) do
        for i2,title in pairs(group.m_List) do
            if title.m_IsActive == true then
                for k,v in pairs(title:GetProperty()) do
                    if properties[v.propertytype] == nil then
                        properties[v.propertytype] = {}
                        properties[v.propertytype].type = v.propertytype
                        properties[v.propertytype].value = v.value
                    else
                        properties[v.propertytype].value = properties[v.propertytype].value + v.value
                        num = num + 1
                    end
                end
            end
        end
    end
    local resetproperties = {}
    for i,k in pairs(properties) do
        --printyellowmodule(Local.LogModuals.Title,i,k)
        table.insert( resetproperties, k )
    end

    return resetproperties,#resetproperties
end

local function GetAvailableTitleNum()
    local num = 0
    for i,k in pairs(TitleGroupList) do
        num = num + k:GetAvailableNumber()
    end
    return num
end

local function GetAllTitleNumber()
    local num = 0
    for i,k in pairs(TitleGroupList) do
        num = num + k:GetNumber()
    end
    return num
end

--获取称号信息
local function GetTitleInfo()
    --printyellow("GetTitleInfo")
    local re = lx.gs.role.title.msg.CGetTitleInfo({})
    NetWork.send(re)
end
--装备称号
local function ActiveTitle(title)
    local id = title.m_Id
    local type = title.m_ConfigData.titletype
    --printyellow("ActiveTitle")
    local re = lx.gs.role.title.msg.CActiveTitle({titlekey = id,titletype = type})
    NetWork.send(re)
end
local function DeActiveTitle(title)
    local id = title.m_Id
    local type = title.m_ConfigData.titletype
    --printyellow("DeActiveTitle")
    local re = lx.gs.role.title.msg.CDeActiveTitle({titlekey = id,titletype = type})
    NetWork.send(re)
end


--服务器返回的获取称号信息
local function OnMsgSGetTitleInfo(msg)
    --printyellowmodule(Local.LogModuals.Title,msg)
    if msg == nil or msg.titleinfo == nil then
        return
    end
    local activeTitle = GetTitleFromGroupList(msg.titleinfo.activetype,msg.titleinfo.activekey)
    if activeTitle ~= nil then
        EquipTitle(activeTitle)
    end

    for id,msgGroup in pairs(msg.titleinfo.titles) do
        for key,msgTitle in pairs(msgGroup.titleinfo) do
            if msgTitle ~= nil then
                local title = GetTitleFromGroupList(msgTitle.titletype,msgTitle.titlekey)
                if title ~= nil then
                    SetTitleServerMsg(title,msgTitle)
                end
            end
        end
    end
end
--服务器返回的激活称号
local function OnMsgSActiveTitle(msg)
    --printyellowmodule(Local.LogModuals.Title,msg)
    if msg == nil then
        return
    end
    local activeTitle = GetTitleFromGroupList(msg.titletype,msg.titlekey)
    if activeTitle ~= nil then
        EquipTitle(activeTitle)
    end

end
--服务器返回的获取称号
local function OnMsgSTitleGetNotify(msg)
    --printyellowmodule(Local.LogModuals.Title,msg)
    if msg == nil or msg.title == nil then
        return
    end

    local title = GetTitleFromGroupList(msg.title.titletype,msg.title.titlekey)
    local group = GetTitleGroup(msg.title.titletype)
    if group ~= nil then
        group.m_ExistNew = true
    end

    if title ~= nil then
        SetTitleServerMsg(title,msg.title)
    end
end
--称号到时间通知
local function OnMsgSTitleTimeOutNotify(msg)
    --printyellowmodule(Local.LogModuals.Title,msg)
    if msg == nil or msg.title == nil then
        return
    end
    local title = GetTitleFromGroupList(msg.title.titletype,msg.title.titlekey)
    if title ~= nil then
        title:TimeOut()
    end
end
local function OnMsgSDeActiveTitle(msg)
    --printyellowmodule(Local.LogModuals.Title,msg)
    if msg == nil then
        return
    end
    local title = GetTitleFromGroupList(msg.titletype,msg.titlekey)
    if title ~= nil then
        UnEquipTitle(title)
    end
end

local function  OnSGetLovername(msg)
     loveName = msg.lovername
end

local function GetLoveName()
    return loveName
end

local function update()
    for i,k in pairs(TitleGroupList) do
        k:Check()
    end
end


local function Start()
	if listenerIds then
		NetWork.remove_listeners(listenerIds)
		listenerIds = nil
	end
   listenerIds = NetWork.add_listeners( {
		{ "lx.gs.role.title.msg.SGetTitleInfo", 		OnMsgSGetTitleInfo	      },
		{ "lx.gs.role.title.msg.SActiveTitle",          OnMsgSActiveTitle	      },
        { "lx.gs.role.title.msg.STitleGetNotify",       OnMsgSTitleGetNotify	  },
        { "lx.gs.role.title.msg.STitleTimeOutNotify",   OnMsgSTitleTimeOutNotify  },
        { "lx.gs.role.title.msg.SDeActiveTitle",        OnMsgSDeActiveTitle       },
    } )
    GetAllLocalTitle()
    GetTitleInfo()
    GameEvent.evt_second_update:add(update)
end

local function init()
    NetWork.add_listeners({
    { "lx.gs.marriage.msg.SGetLovername",           OnSGetLovername       },})
end

local function GetTitleName(id)
    local titlecfg = ConfigManager.getConfigData("title",id)
    if titlecfg then
        return titlecfg.name
    end
    return LocalString.TitleSystem.None
end

local function UnRead()
    local existNew = false 
    for ki =1, #TitleGroupList do
        local group = TitleGroupList[ki]
        if group.m_ExistNew == true then
            existNew = true
        end
    end
    return existNew
end

return {
    init                    = init,
    Start                   = Start,

    Title                   = Title,
    AlertList               = AlertList,
    GetGroupNumber          = GetGroupNumber,
    TitleGroupList          = TitleGroupList,
    GetCurrentEquipedTitle  = GetCurrentEquipedTitle,

    GetAllProperty          = GetAllProperty,
    GetAllTitleNumber       = GetAllTitleNumber,
    GetAvailableTitleNum    = GetAvailableTitleNum,
    ActiveTitle             = ActiveTitle,
    DeActiveTitle           = DeActiveTitle,
    GetTitleGroup           = GetTitleGroup,
    GetTitleFromGroupList   = GetTitleFromGroupList,
    GetTitleById            = GetTitleById,
    GetLoveName             = GetLoveName,

    GetTitleName            = GetTitleName,
    UnRead                  = UnRead,
}
