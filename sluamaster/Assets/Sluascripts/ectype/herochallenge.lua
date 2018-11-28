local NetWork = require("network")
local ConfigManager = require("cfg.configmanager")
local UIManager = require("uimanager")
local Ectype = require("ectype.ectypebase")

-- class HeroChallenge
local HeroChallenge = Class:new(Ectype)

local HeroChallengeType = 
{
    [cfg.herotask.HeroChallengeType.COMMON] = "herocommon",
    [cfg.herotask.HeroChallengeType.COOPERATE] = "herocooperate",
    [cfg.herotask.HeroChallengeType.LIMIT] = "herolimit",
    [cfg.herotask.HeroChallengeType.ABBOSS] = "heroabboss",
    [cfg.herotask.HeroChallengeType.MANYBOSS] = "heromanyboss",
}

function HeroChallenge:__new(entryInfo)
    local basic = ConfigManager.getConfigData("ectypebasic",entryInfo.ectypeid)
    local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
    self.m_DetailType = HeroChallengeManager.GetCurTaskEctypeType(entryInfo.ectypeid)
    if Local.LogManager then
        printyellow("basic.type:",basic.type)
    end
    Ectype.__new(self,entryInfo,basic.type)   
    self.m_Name = self.m_EctypeInfo.storyname
    self.m_Introduction = self.m_EctypeInfo.introduction
    self.m_TotalReviveTime = self.m_BasicEctypeInfo.reviveinfo.maxcount
    self.m_CurrentReviveTime = 0
    self.m_WaveIndex = entryInfo.monsterwaveindex
    self.m_TotalCurrencys = 0
    self.m_RegionEffects = {}
end

function HeroChallenge:Release()
    for _,v in pairs(self.m_RegionEffects) do
        GameObject.Destroy(v)
    end
    Ectype.Release(self)
end

function HeroChallenge:OnEnd(msg)
    Ectype.OnEnd(self,msg)
    UIManager.hide(self.m_UI)
    NetWork.send(lx.gs.map.msg.CLeaveMap({}))
end

function HeroChallenge:GetEctypeInfo()
    if Local.LogManager then
        printyellow("HeroChallenge:GetEctypeInfo")
        printyellow("self.m_DetailType:",self.m_DetailType)
        printyellow("self.m_EctypeID:",self.m_EctypeID)
    end
    return ConfigManager.getConfigData(HeroChallengeType[self.m_DetailType],self.m_EctypeID)
end

function HeroChallenge:GetWaveInfo()
    local num = 5
    local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
    local openLevel,stage = HeroChallengeManager.GetStageByLevel()     
    for _,monsterInfo in pairs(self.m_EctypeInfo.monsterlist) do
        if monsterInfo.level == stage then
            if monsterInfo.monsterlist then
                num = #(monsterInfo.monsterlist)
            end
        end
    end
    return string.format(LocalString.EctypeText.CurrentEctypeProgress,self.m_WaveIndex,num)
end

function HeroChallenge:SetCommonInfo()
    UIManager.call(self.m_UI,"AddDescription",self:GetWaveInfo())
    local targetBossName = ""
    local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
    local openLevel,stage = HeroChallengeManager.GetStageByLevel()
    for _,monsterInfo in pairs(self.m_EctypeInfo.monsterlist) do
        if monsterInfo.level == stage then
            local monsterData = monsterInfo.monsterlist[self.m_WaveIndex]
            if monsterData then
                for id ,value in pairs(monsterData.monster) do
                    local bossData = ConfigManager.getConfigData("monster",id)
                    targetBossName = bossData.name
                end
            end
            break
        end
    end
    self.m_EctypeUI.InsertMissionInfomation(0, { string.format(LocalString.EctypeText.KillMonster,targetBossName),"" } ,nil)
end

function HeroChallenge:SetLimitTargetInfo(killedCount)
    local target = ""
    local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
    local openLevel,stage = HeroChallengeManager.GetStageByLevel()
    for _,monsterInfo in pairs(self.m_EctypeInfo.monsterinfo) do
        if monsterInfo.level == stage then
            for _,monsterData in pairs(monsterInfo.monsterlist) do
                for id,count in pairs(monsterData.monster) do
                    local bossData = ConfigManager.getConfigData("monster",id)
                    target = bossData.name
                end
                break
            end
            break
        end
    end
    local description = HeroChallengeManager.GetEctypeDescriptionByType(self.m_DetailType)
    description = string.format(description,target)
    target = target .. "(" .. (self.m_WaveIndex) .. "/" .. self.m_EctypeInfo.requirekill .. ")"
    self.m_EctypeUI.InsertMissionInfomation(0, { string.format(LocalString.EctypeText.KillMonster,target),"" } ,nil)    
    UIManager.call(self.m_UI,"AddDescription",description)
end

function HeroChallenge:OnUpdateLoadingFinished()
    if UIManager.isshow(self.m_UI) then
        local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
        local openLevel,stage = HeroChallengeManager.GetStageByLevel()        
        if self.m_DetailType == cfg.herotask.HeroChallengeType.COMMON then
            self:SetCommonInfo()
        elseif self.m_DetailType == cfg.herotask.HeroChallengeType.COOPERATE or self.m_DetailType == cfg.herotask.HeroChallengeType.ABBOSS then
            local targetBossName = ""
            local description = HeroChallengeManager.GetEctypeDescriptionByType(self.m_DetailType)
            local bossA = ""
            local bossB = ""
            for _,monsterInfo in pairs(self.m_EctypeInfo.monsterinfo) do
                if monsterInfo.level == stage then
                    for _,boss in pairs(monsterInfo.bosslist) do
                        local bossData = ConfigManager.getConfigData("monster",boss.monsterid)
                        if targetBossName == "" then
                            targetBossName = bossData.name
                        else
                            targetBossName = targetBossName .. "、" .. bossData.name
                        end 
                        if boss.id == 1 then
                            bossA = bossData.name
                        elseif boss.id == 2 then
                            bossB = bossData.name
                        end
                    end
                    break
                end
            end
            self.m_EctypeUI.InsertMissionInfomation(0, { string.format(LocalString.EctypeText.KillMonster,targetBossName),"" } ,nil)
            if self.m_DetailType == cfg.herotask.HeroChallengeType.ABBOSS then
                if Local.LogManager then
                    printyellow("description:",description)
                    printyellow("bossA:",bossA)
                    printyellow("bossB:",bossB)
                end
                description = string.format(description,bossA,bossA,bossB)
            end
            UIManager.call(self.m_UI,"AddDescription",description)
        elseif self.m_DetailType == cfg.herotask.HeroChallengeType.MANYBOSS then
            self.m_EctypeUI.InsertMissionInfomation(0, {LocalString.EctypeText.FamilyEctypeTarget,"" } ,nil)
            local targetBossName = ""
            for _,monsterInfo in pairs(self.m_EctypeInfo.monsterinfo) do
                if monsterInfo.level == stage then
                    for _,monster in pairs(monsterInfo.bosslist) do
                        if monster.id == 1 then
                            local bossData = ConfigManager.getConfigData("monster",monster.monsterid)
                            targetBossName = bossData.name
                            break
                        end
                    end
                    break
                end
            end
            local description = HeroChallengeManager.GetEctypeDescriptionByType(self.m_DetailType)
            description = string.format(description,targetBossName,targetBossName)
            UIManager.call(self.m_UI,"AddDescription",description)
        elseif self.m_DetailType == cfg.herotask.HeroChallengeType.LIMIT then
            self:SetLimitTargetInfo()
        end
        UIManager.call(self.m_UI,"ShowGoal")
    end
    Ectype.OnUpdateLoadingFinished(self)
end

function HeroChallenge:SendRevive()
    local msg=map.msg.CRevive({})
    NetWork.send(msg)
end

function HeroChallenge:TimeUpdate()
    Ectype.TimeUpdate(self)
end

function HeroChallenge:NewMonsterWave(waveindex)
    self.m_WaveIndex = waveindex
    if UIManager.isshow(self.m_UI) then
        if self.m_DetailType == cfg.herotask.HeroChallengeType.COMMON then
            self:SetCommonInfo()
        elseif self.m_DetailType == cfg.herotask.HeroChallengeType.LIMIT then
            self:SetLimitTargetInfo()
        end
    end
end

function HeroChallenge:late_update()
end

return HeroChallenge
