local SceneManager = require "scenemanager"
local CameraManager = require"cameramanager"
local ConfigManager = require"cfg.configmanager"
local PlayerRole = require"character.playerrole"
local Layout = require "ectype.layout"
local network = require"network"
local uimanager = require"uimanager"
local tools = require"ectype.ectypetools"
local Ectype = require"ectype.ectypebase"
--local errorcode = require "assistant.errormanager"
local errormanager = require "assistant.errormanager"
local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
-- class DuardTower
local DuardTower = Class:new(Ectype)

function DuardTower:__new(entryInfo)
    Ectype.__new(self,entryInfo,cfg.ectype.EctypeType.GUARDTOWER)
    self.m_ReviveCountDown  = self.m_BasicEctypeInfo.reviveinfo.time
    self.m_baseid           = entryInfo.ishardmode == 0 and self.m_EctypeInfo.baseid or self.m_EctypeInfo.hardbaseid
    self.m_CurrentWaveId    = entryInfo.curwaveid
    -- self.m_TotalReviveTime  = self.m_EctypeInfo.maxrevivecount
    -- self.m_CurrentReviveTime= self.m_EctypeInfo.maxrevivecount
    -- self.m_ExitSceneID      = self.m_EctypeInfo.exitworldmapid
    self.m_UseTime          = 0
    self.m_TotalTime        = self.m_BasicEctypeInfo.totaltime
    self.m_UIList           = Local.GuardTowerDlgList
    self.m_UI               = "ectype.guardtower.dlgguardtower"
    self.m_Drade            = nil
    self.m_CurrentBuffLevel = {}
    self.m_Buffs            = guardtowermanager.GetRuneBuffs()
end

function DuardTower:EatRune(runeid)

--    local rune = ConfigManager.getConfigData("rune",runeid)
--    printyellow("EatRune",rune.buffid)
--    if rune and self.m_Buffs[rune.buffid] then
--        self.m_Buffs[rune.buffid] = 1
--    end
--    self.m_EctypeUI.RefreshBuff(self.m_Buffs)
end

function DuardTower:ShowTasks(b)
    if uimanager.hasloaded(self.m_UI) then
        uimanager.call(self.m_UI,"ShowTasks",b)
    end
end

function DuardTower:CanRevive()
    return true
end

function DuardTower:Revive(count)
    return true
end

function DuardTower:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function DuardTower:AddEffect(effect)
    if Local.GuardTower then
        printyellow("AddEffect")
        printt(effect)
    end
    if self.m_Buffs[effect.id] then
        self.m_Buffs[effect.id].Num = self.m_Buffs[effect.id].Num+1
    end
    self.m_EctypeUI.RefreshBuff(self.m_Buffs)
end

function DuardTower:RemoveEffect(effectid)
    if Local.GuardTower then
        printyellow("RemoveEffect",effectid)
    end
    if self.m_Buffs[effectid] then
        self.m_Buffs[effectid].Num = self.m_Buffs[effectid].Num -1
    end
    self.m_EctypeUI.RefreshBuff(self.m_Buffs)
end

function DuardTower:NewWaveOpen(currentwaveid)
    self.m_CurrentWaveId = currentwaveid
    self.m_EctypeUI.RefreshLayer(currentwaveid)
end

function DuardTower:GetEctypeInfo()
    return  guardtowermanager.GetEctypeInfo()
end

function DuardTower:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    self.m_Drade = msg
    network.send(map.msg.CEctypeStatistic({}))
    --self.m_EctypeUI.ShowResult(msg)
end

function DuardTower:Success()
    if self.m_Drade then
        local errorEnum = errormanager.GetErrorEnum()
        return self.m_Drade.errcode==0 or self.m_Drade.errcode == errorEnum.GD_MAX_WAVE
    end
    return false
end

function DuardTower:EctypeStatistic(msg)
    -- printyellow("DuardTower:EctypeStatistic(msg)")
    Ectype.EctypeStatistic(self, msg)
    uimanager.showdialog("ectype.dlgstatistic", { statisticMsg = msg ,grade = self.m_Drade,success = self:Success(),groupindex = 2,callback = function() self:ShowDrade() end})
end

function DuardTower:GetTowerHp()
    local hp = 0
    if self.m_baseid  then
        local tower = CharacterManager.GetCharacterByCsvId(self.m_baseid)
        if tower then
            hp= tower.m_Attributes[cfg.fight.AttrId.HP_VALUE] or 0
        end
    end
    return hp
end

function DuardTower:ShowDrade(msg)
    local msg = self.m_Drade
    uimanager.showdialog("ectype.dlggrade",
            {   result      = self:Success(),
                bonus       = msg.bonus,
                text        = "",--(((msg.errcode==0) and string.format(LocalString.Arena.ArenaGrade_Success,msg.newrank)) or LocalString.Arena.ArenaGrade_Failure),
                callback    = function()
                                uimanager.hidedialog("ectype.dlggrade")
                                uimanager.show(self.m_UI)
                                network.send(lx.gs.map.msg.CLeaveMap({}))
                            end})
  --  uimanager.show("ectype.dlggrade",{showArena = true,errcode = msg.errcode, newrank = msg.newrank, bonus = msg.bonus})
end

function DuardTower:TimeUpdate()

    if self.m_RemainTime>0 then
        self.m_RemainTime = self.m_RemainTime-Time.deltaTime

        if self.m_RemainTime>=0 then
            if self.m_TotalTime>= self.m_RemainTime then
                self.m_UseTime = self.m_TotalTime -self.m_RemainTime
                local h,m,s = tools.GetFixedTime(self.m_RemainTime)
                if self.m_EctypeUI then
                    self.m_EctypeUI.UpdateRemainTime(true,h,m,s)
                end
            else
                if self.m_EctypeUI then
                    self.m_EctypeUI.UpdateRemainTime(false)
                end
            end

        end
    end
    -- Ectype.TimeUpdate(self)
end


function DuardTower:late_update()
end

function DuardTower:OnUpdateLoading()
    Ectype.OnUpdateLoading(self)
    if not SceneManager.IsLoadingScene() and uimanager.isshow(self.m_UI) then
        -- printyellow(self.m_CurrentWaveId)
        -- printyellow(self.m_baseid)
        self.m_EctypeUI.EnterDuardTower(self.m_CurrentWaveId,self.m_baseid,self.m_Buffs)
--        self.m_EctypeUI.InitBuff(self.m_Buffs,self.m_CurrentBuffLevel)
    end
end

function DuardTower:Update()
    if self.m_State==Ectype.EctypeLoadState.BeforeLoading then
        self:OnUpdateBeforeLoading()
    elseif self.m_State==Ectype.EctypeLoadState.Loading then
        self:OnUpdateLoading()
    elseif self.m_State==Ectype.EctypeLoadState.LoadingFinished then
        self:OnUpdateLoadingFinished()
    elseif self.m_State== Ectype.EctypeLoadState.BeforeStart then
        self:OnUpdateBeforeStart()
    else
        self:WallsUpdate()
    end
    self:TimeUpdate()
end

return DuardTower
