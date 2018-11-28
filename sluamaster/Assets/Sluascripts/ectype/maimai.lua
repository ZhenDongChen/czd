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
-- class Maimai
local Maimai = Class:new(Ectype)

function Maimai:__new(entryInfo)
    local basic = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    Ectype.__new(self,entryInfo,basic.type)
    self.m_Name             = self.m_EctypeInfo.storyname
    self.m_Introduction     = self.m_EctypeInfo.introduction
    self.m_WaveIndex        = entryInfo.monsterwaveindex
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
end


function Maimai:Revive()
    return true
end

function Maimai:CanRevive()
    local result=false
    if (self.m_TotalReviveTime==-1) then
        result=true
    elseif (self.m_CurrentReviveTime<self.m_TotalReviveTime) then
        result=true
    end
    return result
end

function Maimai:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide("ectype.dlguiectype")
    local bonus = msg.totalbonus
    uimanager.showdialog("ectype.dlggrade",{
        result = (((msg.errcode == 0) and true) or false),
        bonus  = msg.bonus,
        callback = function()
           uimanager.hidedialog("ectype.dlggrade")
            uimanager.show("ectype.dlguiectype")
            network.send(lx.gs.map.msg.CLeaveMap({}))
        end})
end

function Maimai:GetWaveInfo()
    local MaimaiManager = require("ui.activity.maimai.maimaiactmanager")
    local levelData = MaimaiManager.getConfigData().levelmonsterinfos
    local num = 6
    for i,data in ipairs(levelData) do
        if PlayerRole:Instance():GetLevel() < data.level then
            break
        else
            num = #data.monsterwaves
        end  
    end
    return string.format(LocalString.EctypeText.CurrentEctypeProgress,self.m_WaveIndex,num)
end

function Maimai:NewMonsterWave(waveindex)
    self.m_WaveIndex = waveindex
    uimanager.call(self.m_UI,"AddDescription",self:GetWaveInfo())
end

function Maimai:OnUpdateLoadingFinished()
    Ectype.OnUpdateLoadingFinished(self)
    if not SceneManager.IsLoadingScene() then
        if uimanager.isshow(self.m_UI) then
            uimanager.call(self.m_UI,"EnterFamilyEctype",self:GetWaveInfo())
        end
    end
end

function Maimai:OnUpdateBeforeStart()
    Ectype.OnUpdateBeforeStart(self)
    -- if cfg.ectype.EctypeType.EXP == self.m_EctypeType then
    --     self:PlayCG(cfg.ectype.ExpEctype.OPEN_CG)
    -- end
end

function Maimai:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function Maimai:Update()
    Ectype.Update(self)
end

function Maimai:late_update()
end

return Maimai
