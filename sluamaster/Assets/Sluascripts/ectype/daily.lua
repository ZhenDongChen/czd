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
-- class Daily
local Daily = Class:new(Ectype)

function Daily:__new(entryInfo)
    local basic             = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    Ectype.__new(self,entryInfo,basic.type)
    self.m_Name             = self.m_EctypeInfo.storyname
    self.m_Introduction     = self.m_EctypeInfo.introduction
    self.m_TotalReviveTime  = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_CurrentReviveTime= 0
    self.m_WaveIndex        = entryInfo.waveindex + 1
    self.m_TotalCurrencys   = 0
    self.m_RegionEffects    = {}
end

function Daily:Release()
    for _,v in pairs(self.m_RegionEffects) do
        GameObject.Destroy(v)
    end
    Ectype.Release(self)
end

function Daily:Revive()
    if (self.m_TotalReviveTime==-1) or (self.m_CurrentReviveTime < self.m_TotalReviveTime) then
        self.m_CurrentReviveTime = self.m_CurrentReviveTime + 1
        return true
    else
        return false
    end
end

function Daily:CanRevive()
    local result=false
    if (self.m_TotalReviveTime==-1) then
        result=true
    elseif (self.m_CurrentReviveTime<self.m_TotalReviveTime) then
        result=true
    end
    return result
end

function Daily:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    uimanager.hide(self.m_UI)

    if msg.errcode==0 then
        local bonus = msg.totalbonus
        local hurtText=nil
        local descText=nil
        if self.m_EctypeType~=cfg.ectype.EctypeType.CURRENCY then
            hurtText=string.format(LocalString.Ectype_ExtraReward,self.m_EctypeInfo.doublebonustime/60)
            descText = string.format(LocalString.Ectype_ExtraReward,self.m_EctypeInfo.doublebonustime/60)
        end
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
        if self.m_EctypeType==cfg.ectype.EctypeType.CURRENCY then
            bonus = msg.totalbonus
        end
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

function Daily:AddAction(cg_id)
    self:PlayCG(cg_id)
end

function Daily:OnUpdateLoadingFinished()
    if uimanager.isshow(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshDailyInformation",{ectypetype=self.m_EctypeType,ectypeid=self.m_EctypeID,wave=self.m_WaveIndex})
        if self.m_EctypeType~=cfg.ectype.EctypeType.CURRENCY then
            uimanager.call(self.m_UI,"AddDescription",self.m_EctypeInfo.introduction)
        elseif self.m_EctypeType == cfg.ectype.EctypeType.CURRENCY then
            uimanager.call(self.m_UI,"ShowGoal")
--            for _,v in pairs(self.m_EctypeInfo.regioneffect) do
--                local sfxName = string.format("sfx/s_%s.bundle",v.effect)
--                Util.Load(sfxName, define.ResourceLoadType.LoadBundleFromFile, function(asset_obj)
--                    if IsNull(asset_obj) then
--                        return
--                    end
--                    local obj = GameObject.Instantiate(asset_obj)
--                    local pos = Vector3(v.position.x,0,v.position.y)
--                    obj.transform.rotation = Quaternion.Euler(0,v.angle,0)
--                    obj.transform.position = Vector3(pos.x,SceneManager.GetHeight(pos),pos.z)
--                    table.insert(self.m_RegionEffects,obj)
--                end)
--            end
        end
    end
    Ectype.OnUpdateLoadingFinished(self)
end

function Daily:OnUpdateBeforeStart()
	
    Ectype.OnUpdateBeforeStart(self)
	
    if cfg.ectype.EctypeType.EXP == self.m_EctypeType then
		
	   --TODO��ʱ����CG
      -- self:PlayCG(cfg.ectype.ExpEctype.OPEN_CG)
        local re = map.msg.CClientActionEnd({actionid=10009005})
        network.send(re)
    end
end

function Daily:SendRevive()
    local msg=map.msg.CRevive({})
    network.send(msg)
end

function Daily:TimeUpdate()
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

function Daily:AddGold(value)
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

function Daily:NewMonsterWave(waveindex)
    self.m_WaveIndex = waveindex + 1
    if uimanager.isshow(self.m_UI) then
        uimanager.call(self.m_UI,"RefreshDailyInformation",{ectypeid=self.m_EctypeID,wave=self.m_WaveIndex,ectypetype=self.m_EctypeType})
    end
    if self.m_EctypeType == cfg.ectype.EctypeType.CURRENCY or self.m_EctypeType == cfg.ectype.EctypeType.EXP then
        local warnning = self.m_EctypeInfo.refmsg
        uimanager.ShowSystemFlyText(warnning)
    end
end

function Daily:late_update()
end

return Daily
