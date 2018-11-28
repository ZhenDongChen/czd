local SceneManager = require "scenemanager"
local CameraManager = require"cameramanager"
local ConfigManager = require"cfg.configmanager"
local PlayerRole = require"character.playerrole"
local Layout = require "ectype.layout"
local network = require"network"
local uimanager = require"uimanager"
local tools = require"ectype.ectypetools"
local define = require"define"

local dlgectype
local dlgmain
local ui
local Ectype = require"ectype.ectypebase"
-- class FamilyEctype
local FamilyEctype = Class:new(Ectype)

function FamilyEctype:__new(entryInfo)
    local basic             = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    Ectype.__new(self,entryInfo,basic.type)
    -- self.m_Name             = self.m_EctypeInfo.storyname
    -- self.m_Introduction     = self.m_EctypeInfo.introduction
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_CurrentReviveTime= 0
    self.m_WaveIndex        = entryInfo.monsterwaveindex
    self.m_TotalCurrencys   = 0
    self.m_RegionEffects    = {}
    -- self.m_TotalWaveCount   = #self.m_EctypeInfo.levelmonsterinfos.monsterwaves

end

function FamilyEctype:Release()
    for _,v in pairs(self.m_RegionEffects) do
        GameObject.Destroy(v)
    end
    Ectype.Release(self)
end

function FamilyEctype:Revive()
    if (self.m_TotalReviveTime==-1) or (self.m_CurrentReviveTime < self.m_TotalReviveTime) then
        self.m_CurrentReviveTime = self.m_CurrentReviveTime + 1
        return true
    else
        return false
    end
end

function FamilyEctype:CanRevive()
    local result=false
    if (self.m_TotalReviveTime==-1) then
        result=true
    elseif (self.m_CurrentReviveTime<self.m_TotalReviveTime) then
        result=true
    end
    return result
end

function FamilyEctype:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    msg.finishTime = self.m_UseTime
    uimanager.hide("ectype.dlguiectype")
    uimanager.showdialog("ectype.dlggrade",
            {   result      = (((msg.errcode == 0) and true) or false),
                bonus       = msg.bonus,
                star        = msg.star,
                callback    = function()
                    uimanager.hidedialog("ectype.dlggrade")
                    uimanager.show("ectype.dlguiectype")
                    network.send(lx.gs.map.msg.CLeaveMap({}))
                end,})
end

function FamilyEctype:AddAction(cg_id)
    self:PlayCG(cg_id)
end

function FamilyEctype:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function FamilyEctype:OnUpdateLoading()
    Ectype.OnUpdateLoading(self)
    if not SceneManager.IsLoadingScene() then
        if uimanager.isshow(self.m_UI) then
            -- uimanager.EnterFamilyEctype(self:GetWaveInfo())
            uimanager.call(self.m_UI,"EnterFamilyEctype",self:GetWaveInfo())
        end
    end
end

function FamilyEctype:TimeUpdate()
    Ectype.TimeUpdate(self)
    if cfg.ectype.EctypeType.CURRENCY == self.m_EctypeType then
        if self.m_RemainTime>0 then
            if uimanager.isshow(self.m_UI) then
                 local value=(self.m_RemainTime)/self.m_BasicEctypeInfo.totaltime
                 self.m_EctypeUI.UpdateRemainCurrencyTime(value)
            end
        end
    end
end

function FamilyEctype:GetWaveInfo()
    return string.format(LocalString.EctypeText.CurrentEctypeProgress,self.m_WaveIndex,10)
end

function FamilyEctype:NewMonsterWave(waveindex)
    self.m_WaveIndex = waveindex
    uimanager.call(self.m_UI,"AddDescription",self:GetWaveInfo())
end

function FamilyEctype:late_update()
end

return FamilyEctype
