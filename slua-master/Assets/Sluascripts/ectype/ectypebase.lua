local floor         = math.floor
local tinsert       = table.insert
local tremove       = table.remove
local tsort         = table.sort
local PlayerRole    = require"character.playerrole"
local network       = require"network"
local uimanager     = require"uimanager"
local tools         = require"ectype.ectypetools"
local Ectype        = Class:new()
local SceneManager  = require"scenemanager"
local AudioManager  = require"audiomanager"
local AirWallArea   = require"ectype.airwallarea"
local EctypeOthersManager =  require"ectype.ectypeothersmanager"
local ApertureManager = require("ectype.aperturemanager")

Ectype.EctypeLoadState = enum{
    "BeforeLoading=0",
    "Loading=1",
    "LoadingFinished=2",
    "BeforeStart=3",
    "Done=4",
}

local EctypesRequiresAperture = {
    [cfg.ectype.EctypeType.TEAMFIGHT] = true,
    [cfg.ectype.EctypeType.FAMILYWAR] = true,
    [cfg.ectype.EctypeType.CITY_WAR] = true,
}

Ectype.EctypeTables = {
    [cfg.ectype.EctypeType.CLIMB_TOWER]     = "climbtowerectype",
    [cfg.ectype.EctypeType.CURRENCY]        = "currencyectype",
    [cfg.ectype.EctypeType.EXP]             = "expectype",
    [cfg.ectype.EctypeType.YUPEI]           = "dailyectype",
    [cfg.ectype.EctypeType.HUFU]            = "dailyectype",
    [cfg.ectype.EctypeType.PERSONAL_BOSS]   = "personalboss",
    [cfg.ectype.EctypeType.CHALLENGE]       = "",
    [cfg.ectype.EctypeType.ARENA]           = "arenaectype",
    [cfg.ectype.EctypeType.GUARDTOWER]      = "guardtower",
    [cfg.ectype.EctypeType.TEAMFIGHT]       = "teamfight",
    [cfg.ectype.EctypeType.HEROES]          = "heroectype",
    [cfg.ectype.EctypeType.TEAM_SPEED]      = "teamspeed",
    [cfg.ectype.EctypeType.HUIWU]           = "huiwu",
    [cfg.ectype.EctypeType.ATK_CITY]        = "attackcity",
	[cfg.ectype.EctypeType.PROLOGUE]        = "storylayout",
    [cfg.ectype.EctypeType.FAMILY_TEAM]     = "familyteam",
    [cfg.ectype.EctypeType.MAIMAIECTYPE]    = "mmectype",
    [cfg.ectype.EctypeType.FAMILYWAR]       = "familywar",
    [cfg.ectype.EctypeType.CITY_WAR]        = "citywar",
    [cfg.ectype.EctypeType.HERO_CHALLENGE]  = "herochallenge",
    [cfg.ectype.EctypeType.CURRENCY_ACTIVITY] = "currencyactivityectype",
}

function Ectype:IsReady()
    return self.m_bIsReady
end

function Ectype:__new(entryInfo,ectypetype,callback)
    self.m_bIsReady                 = false
    self.m_ServerMsg                = entryInfo
    self.m_EctypeID                 = entryInfo.ectypeid
    self.m_ID                       = entryInfo.ectypeid
    self.m_State                    = Ectype.EctypeLoadState.BeforeLoading
    self.m_EctypeCallBack           = callback
    self.m_EctypeType               = ectypetype
    self.m_IsLeaving                = false
    self.m_bEnd                     = false
    self.m_bBeginFight              = false
    self.m_EctypeInfo				= self:GetEctypeInfo()
    self.m_BasicEctypeInfo          = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    self.m_AirWallAreas             = {}
    if self.m_DelayWall == nil then
        self:SetDefaultAirWallArea()
    end
    self.m_ApertureManager = (EctypesRequiresAperture[ectypetype]~=nil) and ApertureManager:new(self) or nil
    self.m_RemainTime               = (entryInfo.remaintime ~= nil) and floor(entryInfo.remaintime/1000) or self.m_BasicEctypeInfo.totaltime
    self.m_EctypeUI                 = nil
    self.m_UIList                   = Local.EctypeDlgList
    self.m_UI                       = "ectype.dlguiectype"
    self.m_PlayerRole               = PlayerRole.Instance()
    self.m_CurrentReviveTime        = 0
    self.m_ReviveFunction           = 0
    self.m_bEnd                     = false
    if self.m_EctypeType == cfg.ectype.EctypeType.CLIMB_TOWER or self.m_EctypeType == cfg.ectype.EctypeType.GUARDTOWER then
        self.m_ReviveFunction = 1  -- count down
    else
        if self.m_BasicEctypeInfo.reviveinfo.maxcount == -1 then
            self.m_ReviveFunction = 1  -- count down
        elseif self.m_BasicEctypeInfo.reviveinfo == 0 then
            self.m_ReviveFunction = 2  -- can not revive
        else
            self.m_ReviveFunction = 0  -- click
        end
    end

    EctypeOthersManager.ShowUI()
end

function Ectype:RoleEnterEctype()

end



function Ectype:DeadCount()

end

function Ectype:Init()

end

function Ectype:RealTimeStatistic(msg)
    local info = {}
    info.frameCount = 3
    info.totalDmg = 0
    info.players = {}
    for _,player in pairs(msg.teams[1].members) do
        local tb = {}
        tb.name = player.name .. (player.ownername=="" and "" or ('-'..player.ownername))
        tb.dmg = player.damage
        tinsert(info.players,tb)
        info.totalDmg = info.totalDmg + player.damage
    end
    tsort(info.players,function(a,b) return a.dmg>b.dmg end)
    return info
end

function Ectype:GetEctypeInfo()
    if self.m_EctypeType == cfg.ectype.EctypeType.FAMILY_TEAM
    or self.m_EctypeType == cfg.ectype.EctypeType.MAIMAIECTYPE
    or self.m_EctypeType == cfg.ectype.EctypeType.FAMILYWAR
    or self.m_EctypeType == cfg.ectype.EctypeType.CITY_WAR then
		printyellow(">>>>>>>>Ectype.EctypeTables[self.m_EctypeType]",Ectype.EctypeTables[self.m_EctypeType])
        return ConfigManager.getConfig(Ectype.EctypeTables[self.m_EctypeType])
    else
        return ConfigManager.getConfigData(Ectype.EctypeTables[self.m_EctypeType],self.m_EctypeID)
    end
end

function Ectype:SetDefaultAirWallArea()
    if self.m_EctypeInfo.mainregionid  then
        self:AddAirWallArea(self.m_BasicEctypeInfo.regionsetid, self.m_EctypeInfo.mainregionid)
    end
end

function Ectype:AddAirWallArea(regionSetId, regionId)
    local airWallArea = AirWallArea:new(regionSetId, regionId)
    airWallArea:init()
    tinsert( self.m_AirWallAreas, airWallArea )
end

function Ectype:RemoveAirWallArea(regionId)
    for i, airWallArea in pairs(self.m_AirWallAreas) do
        local pos = nil
        if airWallArea:GetId() == regionId then
            airWallArea:Destroy()
            pos = i
        end

        if pos then
            tremove( self.m_AirWallAreas, pos )
        end
    end
end

function Ectype:RemoveAllAirWallArea()
    for i, airWallArea in pairs(self.m_AirWallAreas) do
        airWallArea:Destroy()
    end
    self.m_AirWallAreas = {}
end

function Ectype:Release()
    for i, airWallArea in pairs(self.m_AirWallAreas) do
        airWallArea:Destroy()
    end
    self.m_AirWallAreas = {}
    if self.m_ApertureManager then
        self.m_ApertureManager:OnEnd()
        self.m_ApertureManager = nil
    end
end

function Ectype:IsLeaving()
    return self.m_IsLeaving()
end

function Ectype:CheckPosition(position)
    local num = 0
    -- if #self.m_AirWallAreas == 0 then 
    --     return true
    -- end
    for i, airWallArea in pairs(self.m_AirWallAreas) do
        if airWallArea:CheckPosition(position) == true then
            return true
        end
        num = num +1
    end
    if num >= 1 then
        return false
    else
        return true
    end
end

function Ectype:TimeUpdate()
    if self.m_RemainTime>0 then
        self.m_RemainTime = self.m_RemainTime - Time.deltaTime
        if self.m_RemainTime>=0 then
            local h,m,s = tools.GetFixedTime(self.m_RemainTime)
            if uimanager.isshow(self.m_UI) then
                self.m_EctypeUI.UpdateRemainTime(h,m,s)
            end
        end
    end
end

function Ectype:WallsUpdate()
    local playerPos = self.m_PlayerRole:GetPos()

    for i, airWallArea in pairs(self.m_AirWallAreas) do
        airWallArea:Update(playerPos)
    end
end

function Ectype:OnUpdateBeforeLoading()
    PlayerRole:Instance():sync_SEnterEctype({id = self.m_ServerMsg.id, ectypeid = self.m_ServerMsg.ectypeid, ectypetype = self.m_EctypeType})
    SceneManager.load(self.m_UIList,self.m_BasicEctypeInfo.scenename)
    self.m_State = Ectype.EctypeLoadState.Loading
end

function Ectype:OnUpdateLoading()
    if not SceneManager.IsLoadingScene() then
        if uimanager.isshow("dlguimain") and uimanager.isshow(self.m_UI) then
            self.m_EctypeUI = require("ui."..self.m_UI)
            uimanager.call(self.m_UI,"EnterEctype",self.m_BasicEctypeInfo.ectypename)
            uimanager.call("dlguimain","EnterEctype")
            self:Init()
            self.m_State = Ectype.EctypeLoadState.LoadingFinished
        end
    end
end

function Ectype:LeaveEctype(msg)
    uimanager.call("dlguimain","LeaveEctype")
    uimanager.call("dlguimain","SwitchAutoFight",false)
    SceneManager.PlayBackgroundMusic()
    if (self.m_UI) and (uimanager.isshow(self.m_UI)) then
        uimanager.destroy(self.m_UI)
    end
    if uimanager.isshow("ectype.dlggrade") then
        uimanager.destroy("ectype.dlggrade")
    end
    if uimanager.isshow("ectype.dlggradebox") then
        uimanager.destroy("ectype.dlggradebox")
    end
end


function Ectype:SendReady()
    if self:IsReady() then
        local re = map.msg.CReady({})
        network.send(re)
    end
end

function Ectype:OnMsgSReady(msg)
    if uimanager.isshow("ectype.dlguiectype") then
        uimanager.call("ectype.dlguiectype","EctypeReady")
    end
end

function Ectype:EctypeStatistic(msg)
    local info = self:RealTimeStatistic(msg)
    if uimanager.isshow(self.m_UI) then
        if uimanager.hasmethod(self.m_UI,"OnStatistic") then
            uimanager.call(self.m_UI,"OnStatistic",info)
        end
    end
end

function Ectype:CountDown(msg)
    self.m_CountDownTimeBeforeStart = msg.endtime/1000 - timeutils.GetServerTime()
    uimanager.ShowCountDownFlyText(self.m_CountDownTimeBeforeStart)
end

function Ectype:BeginFight(msg)
    self.m_bBeginFight = true
    if self.m_ApertureManager then
        self.m_ApertureManager:OnStart()
    end
end

function Ectype:OnUpdateLoadingFinished()
    AudioManager.PlayBackgroundMusic(self.m_BasicEctypeInfo.audioid)
    self.m_State = Ectype.EctypeLoadState.BeforeStart
end

function Ectype:ShowTasks(b)
    self.m_EctypeUI.ShowTasks(b)
end

function Ectype:OnUpdateBeforeStart()
    local callback = self.m_EctypeCallBack
    if callback then callback() end
    self.m_State = Ectype.EctypeLoadState.Done
    self.m_bIsReady = true
    self:SendReady()
end

function Ectype:LoadDone()
    return self.m_State == Ectype.EctypeLoadState.Done
end

function Ectype:GetReviveFunction()
    return self.m_ReviveFunction
end

function Ectype:Revive()
    if self.m_CurrentReviveTime < self.m_BasicEctypeInfo.reviveinfo.maxcount then
        self.m_CurrentReviveTime = self.m_CurrentReviveTime + 1
        return true
    else
        return false
    end
end

function Ectype:CanRevive()
    if self.m_ReviveFunction == 0 then
        return self.m_CurrentReviveTime < self.m_BasicEctypeInfo.reviveinfo.maxcount
    elseif self.m_ReviveFunction == 1 then
        return true
    end
end

function Ectype:ReviveMsg()
    if self.m_ReviveFunction == 0 then
        return {self.m_CurrentReviveTime,self.m_BasicEctypeInfo.reviveinfo.maxcount}
    elseif self.m_ReviveFunction == 1 then
        return self.m_BasicEctypeInfo.reviveinfo.time
    end
end

function Ectype:PlayOneOffCG(cg_id)
	print("___________________")
	printyellow(cg_id)
    if not GetUserConfig(PlayerRole:Instance().m_Id,{path={"EctypeOpenCG",self.m_EctypeType},idx=cg_id}) then
        UserConfig[PlayerRole:Instance().m_Id].EctypeOpenCG[self.m_EctypeType][cg_id] = true
        SaveUserConfig()
        local PlotManager = require"plot.plotmanager"
        PlotManager.CutscenePlayById(cg_id,function()
            uimanager.show("ectype.dlguiectype")
            local re = map.msg.CClientActionEnd({actionid=cg_id})
            network.send(re)
        end)
    else
        local re = map.msg.CClientActionEnd({actionid=cg_id})
        network.send(re)
    end
end

function Ectype:PlayCG(cg_id)

	local PlotManager = require"plot.plotmanager"
    PlotManager.CutscenePlayById(cg_id,function()
        uimanager.show("ectype.dlguiectype")
        local re = map.msg.CClientActionEnd({actionid=cg_id})
        network.send(re)
    end)

end

function Ectype:Update()
    if self.m_State==Ectype.EctypeLoadState.BeforeLoading then
        self:OnUpdateBeforeLoading()
    elseif self.m_State==Ectype.EctypeLoadState.Loading then
        self:OnUpdateLoading()
    elseif self.m_State==Ectype.EctypeLoadState.LoadingFinished then
        self:OnUpdateLoadingFinished()
    elseif self.m_State== Ectype.EctypeLoadState.BeforeStart then
        self:OnUpdateBeforeStart()
    else
        self:TimeUpdate()
        self:WallsUpdate()
    end
    if self.m_ApertureManager then
        self.m_ApertureManager:OnUpdate()
    end
end

function Ectype:late_update()
end

function Ectype:second_update()
end

function Ectype:OnEnd()
    self.m_bEnd = true
    EctypeOthersManager.HideUI()
    if self.m_ApertureManager then
        self.m_ApertureManager:OnEnd()
        self.m_ApertureManager = nil
    end
end

function Ectype:NewMonsterWave(msg)

end


return Ectype
