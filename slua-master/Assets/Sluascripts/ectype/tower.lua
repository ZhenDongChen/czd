local SceneManager = require "scenemanager"
local CameraManager = require"cameramanager"
local ConfigManager = require"cfg.configmanager"
local PlayerRole = require"character.playerrole"
local Layout = require "ectype.layout"
local network = require"network"
local uimanager = require"uimanager"
local tools = require"ectype.ectypetools"
local Ectype = require"ectype.ectypebase"
local dlgectype
local dlgmain
-- class Tower
local Tower = Class:new(Ectype)

function Tower:__new(entryInfo)
    Ectype.__new(self,entryInfo,cfg.ectype.EctypeType.CLIMB_TOWER)
    self.m_ReviveCountDown  = self.m_BasicEctypeInfo.reviveinfo.time
    self.m_Level            = entryInfo.curfloorid
    self.m_Buffs            = self.m_EctypeInfo.buffs_buffid
    self.m_CurrentScore     = entryInfo.totalscore
    self.m_CurrentBuffLevel = {}
    self.m_baseid           = self.m_EctypeInfo.baseid
    self.m_UseTime          = 0
    self.m_UIList           = Local.ClimbingTowerDlgList
    self.m_UI               = "ectype.dlgclimbingtower"
    self.m_RecordFloor      = PlayerRole.Instance().m_ClimbTowerInfo[self.m_ID].maxfloorid
    self.m_RemainReviveTime = 0
    for i,v in pairs(entryInfo.buffbuynums) do
        self.m_CurrentBuffLevel[i] = v
    end
    for i,v in pairs(self.m_Buffs) do
        if not self.m_CurrentBuffLevel[v.buffid] then
            self.m_CurrentBuffLevel[v.buffid] = 0
        end
    end
end

function Tower:CanRevive()
    return self.m_RemainReviveTime <= self.m_BasicEctypeInfo.reviveinfo.maxcount
end

function Tower:Revive()
    -- self.m_RemainReviveTime = self.m_RemainReviveTime + 1
    -- if uimanager.hasloaded(self.m_UI) then
    --     uimanager.call(self.m_UI,self.m_BasicEctypeInfo.reviveinfo.maxcount - self.m_RemainReviveTime)
    -- end
end
--
-- function Tower:EctypeStatistic(info)
--     if uimanager.isshow(self.m_UI) then
--         uimanager.call(self.m_UI,"OnStatistic",info)
--     end
-- end

function Ectype:OnMsgSReady(msg)
    if uimanager.isshow(self.m_UI) then
        uimanager.call(self.m_UI,"EctypeReady")
    end
end

function Tower:DeadCount(count)
    self.m_RemainReviveTime = count
    local remainReviveCount = self.m_BasicEctypeInfo.reviveinfo.maxcount - self.m_RemainReviveTime
    remainReviveCount = remainReviveCount>=0 and remainReviveCount or 0
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"Revive",remainReviveCount)
    end
end

function Tower:BuyBuff(msg)
    self.m_CurrentBuffLevel[msg.buffid] = self.m_CurrentBuffLevel[msg.buffid]+1
    self.m_EctypeUI.BuyBuff(msg.buffid,self.m_CurrentBuffLevel[msg.buffid],self.m_Buffs)
    self.m_EctypeUI.ChangeScore(msg.totalscore)
end

function Tower:ChangeScore(totalscore)
    self.m_EctypeUI.ChangeScore(totalscore)
end

function Tower:NewFloorOpen(floorid)
    self.m_Level = floorid
    self.m_EctypeUI.ChangeLayer(floorid)
end

function Tower:TimeUpdate()
    self.m_UseTime = self.m_UseTime + Time.deltaTime
    if self.m_RemainTime>0 then
        self.m_RemainTime = self.m_RemainTime-Time.deltaTime
        if self.m_RemainTime>=0 then
            local h,m,s = tools.GetFixedTime(self.m_RemainTime)
            if uimanager.isshow("ectype.dlgclimbingtower") then
                self.m_EctypeUI.UpdateRemainTime(h,m,s)
            end
        end
    end
    -- Ectype.TimeUpdate(self)
end

function Tower:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    self.m_EctypeUI.EndClimbTower(msg,self.m_ID,msg.lastfloorcosttime,self.m_Level,self.m_RecordFloor)
end

function Tower:late_update()
end

function Tower:OnUpdateLoading()
    Ectype.OnUpdateLoading(self)
    if not SceneManager.IsLoadingScene() then
        if uimanager.isshow("dlguimain") and uimanager.isshow(self.m_UI) then
            self.m_EctypeUI.EnterTower(self.m_Level,self.m_CurrentScore,self.m_baseid,self.m_CurrentBuffLevel,
                self.m_BasicEctypeInfo.reviveinfo.maxcount - self.m_RemainReviveTime)
            self.m_EctypeUI.InitBuff(self.m_Buffs,self.m_CurrentBuffLevel)
        end
    end
end

function Tower:Update()
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
end

return Tower
