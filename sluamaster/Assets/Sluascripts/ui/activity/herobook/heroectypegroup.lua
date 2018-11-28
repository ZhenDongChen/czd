local ConfigManager     = require("cfg.configmanager")
local HeroEctype        = require("ui.activity.herobook.heroectype")
local LimitManager      = require("limittimemanager")
local PetManager        = require("character.pet.petmanager")

local HeroEctypeGroup = Class:new()

function HeroEctypeGroup:__new(groupId, defaultEctypeId, refreshTimes)
    self.m_GroupId = groupId
    self.m_CurrentEctypeId = defaultEctypeId
    self.m_RefreshTimes = refreshTimes
    
    self.m_ConfigData = nil
    self.m_OpenLevel = 0
    
    self.m_HeroEctypes = {}
    
    self.m_ChangeCost = nil
    self.m_ResetTime = nil
   
    
    self.m_TotalChallengeTimes = 0
    
    
    self:LoadConfig()
end

function HeroEctypeGroup:LoadConfig()
    local herosets = ConfigManager.getConfig("herosets")
    
    self.m_TotalChallengeTimes = herosets.dailylimit.num
    self.m_ChangeCost = herosets.changecost
    self.m_ResetTime = herosets.resettime



    for i, cfgGroup in pairs(herosets.ectypemsg) do
        if cfgGroup.id == self.m_GroupId then
            self.m_ConfigData = cfgGroup
            break
        end
    end


    if self.m_ConfigData then
        self.m_OpenLevel = self.m_ConfigData.openlevel.level
        for i, cfgEctype in pairs(self.m_ConfigData.ectyperandom) do
            self.m_HeroEctypes[i] = HeroEctype:new(cfgEctype)
        end
    end
end

function HeroEctypeGroup:GetId()
    return self.m_GroupId
end

function HeroEctypeGroup:GetGroupName()
    return self.m_ConfigData.groupname
end

function HeroEctypeGroup:GetChangeCost()
    if self.m_RefreshTimes + 1 > #self.m_ChangeCost then
        return self.m_ChangeCost[#self.m_ChangeCost].amount
    end
    return self.m_ChangeCost[self.m_RefreshTimes + 1].amount
end

function HeroEctypeGroup:ResetServerInfo(serverId, defaultEctypeId, refreshTimes)
    self.m_CurrentEctypeId = defaultEctypeId or self.m_CurrentEctypeId
    self.m_RefreshTimes = refreshTimes or self.m_RefreshTimes
    --printyellow("<<<<<<<<<<<<<<<<?")
   -- printyellow("self.m_CurrentEctypeId",defaultEctypeId, self.m_CurrentEctypeId)
end


function HeroEctypeGroup:SetCurrentEctypeId(ectypeId)
    self.m_CurrentEctypeId = ectypeId
end

function HeroEctypeGroup:AddRefreshTimes()
    self.m_RefreshTimes = self.m_RefreshTimes +1
end

function HeroEctypeGroup:GetRefreshTimes()
    return self.m_RefreshTimes
end


function HeroEctypeGroup:GetChallengeTimesInfo()
    local challengedTimes = LimitManager.GetLifelongLimitTime(cfg.cmd.ConfigId.HEROES_ECTYPE,0)
    return challengedTimes, self.m_TotalChallengeTimes
end

function HeroEctypeGroup:GetFreeRefreshTimes()
    local times = 0
    for i = 1, #self.m_ChangeCost do
        if self.m_ChangeCost[i].amount<=0 then
            times = times + 1
        end
    end
    return times - self.m_RefreshTimes
end


function HeroEctypeGroup:GetResetTimeStr()
    local resetTimeStr = ""
    
    for i, resetHour in pairs(self.m_ResetTime) do
        resetTimeStr = resetTimeStr .. tostring(resetHour) .. ":" .. "00"
        if i ~= #self.m_ResetTime then
            resetTimeStr = resetTimeStr .. ", "
        end
    end
    
    return resetTimeStr
end

function HeroEctypeGroup:GetCurrentHeroEctype()
    for i, heroEctype in pairs(self.m_HeroEctypes) do
        if heroEctype.m_Id == self.m_CurrentEctypeId then
            return heroEctype
        end
    end
    return self.m_HeroEctypes[1]
end 

function HeroEctypeGroup:GetPetItems()
    local items = {}
    for i, heroEctype in pairs(self.m_HeroEctypes) do
        table.insert( items, heroEctype:GetPetItem() )
    end
    return items
end

function HeroEctypeGroup:GetPets()
    local pets = {}
    for i, petid in pairs(self.m_ConfigData.petid) do
        --printyellow("petid:=> ", petid)
        local icon = PetManager.GetPetHeadIcon(petid)
        local qcolor = PetManager.GetPetQuality(petid)
        pets[i] = {m_Id = petid, m_Icon = icon, m_QualityColor = qcolor}
    end
    return pets
end

function HeroEctypeGroup:IsMatchLevel()
    return PlayerRole:Instance().m_Level >= self.m_OpenLevel
end

function HeroEctypeGroup:GetOpenLevel()
    return self.m_OpenLevel
end

function HeroEctypeGroup:GetGroupIcon()
    return self.m_ConfigData.icon
end

function HeroEctypeGroup:CanChallenge()
    if self:IsMatchLevel() then
        local challengedTimes, totalTimes = self:GetChallengeTimesInfo()
        if totalTimes - challengedTimes > 0 then
            return true
        end
    end
    return false
end


return HeroEctypeGroup