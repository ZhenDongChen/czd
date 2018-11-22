local ConfigManager = require"cfg.configmanager"
local network = require"network"
local uimanager = require"uimanager"
local Ectype = require"ectype.ectypebase"

local TeamCurrency = Class:new(Ectype)

function TeamCurrency:__new(entryInfo)
printyellow("TeamCurrency:__new")
    local basic             = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    printt(basic)
    printt(entryInfo)
    Ectype.__new(self,entryInfo,basic.type)
    self.m_Name             = self.m_EctypeInfo.storyname
    self.m_Introduction     = self.m_EctypeInfo.introduction
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_CurrentReviveTime= 0
    self.m_WaveIndex        = entryInfo.waveindex + 1
    self.m_TotalCurrencys   = 0
    self.m_RegionEffects    = {}
end

function TeamCurrency:Release()
    for _,v in pairs(self.m_RegionEffects) do
        GameObject.Destroy(v)
    end
    Ectype.Release(self)
end

function TeamCurrency:Revive()
    if (self.m_TotalReviveTime==-1) or (self.m_CurrentReviveTime < self.m_TotalReviveTime) then
        self.m_CurrentReviveTime = self.m_CurrentReviveTime + 1
        return true
    else
        return false
    end
end

function TeamCurrency:CanRevive()
    local result=false
    if (self.m_TotalReviveTime==-1) then
        result=true
    elseif (self.m_CurrentReviveTime<self.m_TotalReviveTime) then
        result=true
    end
    return result
end

function TeamCurrency:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)
    if msg.errcode==0 then
        local bonus = msg.totalbonus
        local hurtText=nil
        local descText=nil
        uimanager.showdialog("ectype.dlggrade",{
            result = true,
            bonus = bonus,
            hurtText = hurtText,
            callback = function()
                uimanager.hidedialog("ectype.dlggrade")
                uimanager.showdialog("ectype.dlggradebox",{
                    result = true,
                    bonuss = msg.bonuss,
                    descText = descText,
                    callback = function()
                        uimanager.hidedialog("ectype.dlggradebox")
                        uimanager.show(self.m_UI)
                        network.send(lx.gs.map.msg.CLeaveMap({}))
                    end})
            end})
    else
        local bonus=nil
        bonus = msg.totalbonus
        uimanager.showdialog("ectype.dlggrade",
                            {   result = false,
                                bonus  = bonus,
                                callback = function()
                                    uimanager.hidedialog("ectype.dlggrade")
                                    if self.m_EctypeType~=cfg.ectype.EctypeType.CURRENCY then
                                        uimanager.show(self.m_UI)
                                        network.send(lx.gs.map.msg.CLeaveMap({}))
                                    else
                                        uimanager.showdialog("ectype.dlggradebox",{
                                        result = true,
                                        bonuss = msg.bonuss,
                                        callback = function()
                                            uimanager.hidedialog("ectype.dlggradebox")
                                            uimanager.show(self.m_UI)
                                            network.send(lx.gs.map.msg.CLeaveMap({}))
                                        end})
                                    end
                                end})
    end
end

function TeamCurrency:AddAction(cg_id)
    self:PlayCG(cg_id)
end

function TeamCurrency:OnUpdateLoadingFinished()
    if uimanager.isshow(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshDailyInformation",{ectypetype=self.m_EctypeType,ectypeid=self.m_EctypeID,wave=self.m_WaveIndex})
        uimanager.call(self.m_UI,"ShowGoal")
    end
    Ectype.OnUpdateLoadingFinished(self)
end

function TeamCurrency:OnUpdateBeforeStart()
    Ectype.OnUpdateBeforeStart(self)
    --self:PlayCG(cfg.ectype.CurrencyActivityEctype.OPEN_CG)
end

function TeamCurrency:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function TeamCurrency:TimeUpdate()
    Ectype.TimeUpdate(self)
    if self.m_RemainTime>0 then
        if uimanager.isshow(self.m_UI) then
            local value=(self.m_RemainTime)/self.m_BasicEctypeInfo.totaltime
            self.m_EctypeUI.UpdateRemainCurrencyTime(value)
        end
    end
end

function TeamCurrency:AddGold(value)
    if self.m_TotalCurrencys and (value>self.m_TotalCurrencys) then
        self.m_TotalCurrencys=value
        uimanager.call(self.m_UI,"RefreshDailyCurrency",{totalValue=self.m_TotalCurrencys,maxValue=self.m_EctypeInfo.maxgetcurrency})
        if (self.m_TotalCurrencys/self.m_EctypeInfo.maxgetcurrency)>0.99 and (self.m_PlayDropMoneyEffect~=true)then
            self.m_PlayDropMoneyEffect=true
            uimanager.ShowSystemFlyText(LocalString.CurrencyEctype_KillCat)
            uimanager.call("ectype.dlguiectype","PlayDropMoneyEffect")
        end
    end
end

function TeamCurrency:NewMonsterWave(waveindex)
    self.m_WaveIndex = waveindex + 1
    if uimanager.isshow(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshDailyInformation",{ectypeid=self.m_EctypeID,wave=self.m_WaveIndex,ectypetype=self.m_EctypeType})
    end
    if self.m_EctypeType == cfg.ectype.EctypeType.CURRENCY or self.m_EctypeType == cfg.ectype.EctypeType.EXP then
        local warnning = self.m_EctypeInfo.refmsg
        uimanager.ShowSystemFlyText(warnning)
    end
end

function TeamCurrency:late_update()
end

return TeamCurrency
