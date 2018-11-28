local NetWork = require "network"
local UIManager=require "uimanager"
local ConfigManager=require"cfg.configmanager"

local m_WorldBossList={}
local m_Lines={}
local m_BossName=""
local m_NeedNav=nil
local m_TargetPos=nil
--local m_NewBoss=false

local function GetWorldBoss(id)
    return m_WorldBossList[id]
end

local function GetRefreshTimeList(worldBossId)
    local refreshTimes={}
    local worldBossList=ConfigManager.getConfig("worldboss")
    for _,worldBoss in pairs(worldBossList) do
        if worldBoss.id==worldBossId then
            for _,controller in pairs(worldBoss.opentimes) do
                local time={}
                time.hour=controller.hour
                time.min=controller.minute
                time.sec=controller.second
                table.insert(refreshTimes,time)
            end
        end
    end
    return refreshTimes
end

local function GetMaxRefreshTime(worldBossId)
    local times=GetRefreshTimeList(worldBossId)
    local maxTime=times[1]
    for _,time in pairs(times) do
        if time.hour>maxTime.hour then
            maxTime=time
        elseif time.hour==maxTime.hour then
            if time.min>maxTime.min then
                maxTime=time
            end
        end
    end
    maxTime.sec=0
    return maxTime
end

local function GetLines()
    return m_Lines
end

local function SendGetWorldBoss()
    local msg=lx.gs.activity.worldboss.msg.CGetWorldBossList({})
    NetWork.send(msg)
end

local function SendGetWorldBossLineStatus(id,isAutoChangLine)
    local msg=lx.gs.activity.worldboss.msg.CGetWorldBossLineStatus({bossid=id,issenddata = isAutoChangLine})
    NetWork.send(msg)
end
local function OnMsg_SGetWorldBossList(msg)
    m_WorldBossList={}
    for _,worldBoss in pairs(msg.bosses) do
        m_WorldBossList[worldBoss.bossid]=worldBoss
    end
    if UIManager.isshow("activity.worldboss.tabworldboss") then
        UIManager.call("activity.worldboss.tabworldboss","RefreshBossIcon")
    end
end

local function OnMsg_SWorldBossNotice(msg)
    UIManager.ShowSystemFlyText(msg.msg)
    local ChatManager=require"ui.chat.chatmanager"
    ChatManager.AddMessageInfo({channel = cfg.chat.ChannelType.SYSTEM,text = msg.msg})
    local worldBossData= ConfigManager.getConfig("worldboss")
    for _,data in pairs(worldBossData) do
        if msg.msg==data.prebroadcast then
            --m_NewBoss=true
            UIManager.call("dlguimain","RefreshRedDotType",cfg.ui.FunctionList.ACTIVITY)
            break
        end
    end
    if UIManager.isshow("activity.worldboss.tabworldboss") then
        UIManager.call("activity.worldboss.tabworldboss","RefreshBossIcon")
    end
end

local function OnMsg_SWorldBossKillNotice(msg)
    UIManager.ShowSystemFlyText(string.format(msg.msg,msg.killername))
    if UIManager.isshow("activity.worldboss.tabworldboss") then
        UIManager.call("activity.worldboss.tabworldboss","RefreshBossIcon")
    end
end

local function OnMsg_SGetWorldBossLineStatus(msg)
	
    m_Lines=msg.lines
	
	if msg.issenddata == 0 then
		 if UIManager.isshow("activity.worldboss.tabworldboss") then
			UIManager.call("activity.worldboss.tabworldboss","ShowLines")
		 end
	end

end

local function SetCurBossName(name)
    m_BossName=name
end

local function init()
    NetWork.add_listeners({
        {"lx.gs.activity.worldboss.msg.SGetWorldBossList",OnMsg_SGetWorldBossList},
        {"lx.gs.activity.worldboss.msg.SWorldBossNotice",OnMsg_SWorldBossNotice},
        {"lx.gs.activity.worldboss.msg.SWorldBossKillNotice",OnMsg_SWorldBossKillNotice},
        {"lx.gs.activity.worldboss.msg.SGetWorldBossLineStatus",OnMsg_SGetWorldBossLineStatus},
    })
end

local function UnRead()
    --return m_NewBoss
    local result=false
    local worldBossData=ConfigManager.getConfig("worldboss")
    for _,worldBoss in pairs(worldBossData) do
        local openState=GetWorldBoss(worldBoss.id)
        if openState and openState.isopen~=0 then
            result=true
            break
        end
    end
    return result
end

local function Start()
    SendGetWorldBoss()
end

local function NavigateToLine(params)
    local PlayerRole=require"character.playerrole":Instance()
    local mapId=PlayerRole:GetMapId()
    local lineId=PlayerRole.m_MapInfo:GetLineId()
    if (params.mapId~=mapId) then
        PlayerRole:navigateTo({targetPos=Vector3(params.position.x,params.position.y,0),mapId=params.mapId,lineId=params.lineId})
    else
        if lineId~=params.lineId then
            m_NeedNav=true
            m_TargetPos=params.position
            local MapManager=require"map.mapmanager"
            MapManager.EnterMap(params.mapId,params.lineId)
        else
            PlayerRole:navigateTo({targetPos=Vector3(params.position.x,params.position.y,0),mapId=params.mapId,lineId=params.lineId})
        end
    end
end

local function CheckIsNeedNav()
    if m_NeedNav==true then
        m_NeedNav=nil
        if m_TargetPos then
            local PlayerRole=require"character.playerrole":Instance()
            PlayerRole:navigateTo({targetPos=Vector3(m_TargetPos.x,0,m_TargetPos.y)})
            m_TargetPos=nil
        end
    end
end

return{
    init=init,
    SendGetWorldBoss=SendGetWorldBoss,
    SendGetWorldBossLineStatus=SendGetWorldBossLineStatus,
    GetWorldBoss=GetWorldBoss,
    GetRefreshTimeList=GetRefreshTimeList,
    GetMaxRefreshTime=GetMaxRefreshTime,
    GetLines=GetLines,
    SetCurBossName=SetCurBossName,
    UnRead=UnRead,
    Start = Start,
    NavigateToLine = NavigateToLine,
    CheckIsNeedNav = CheckIsNeedNav,
}
