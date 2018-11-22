local ConfigManager = require("cfg.configmanager")

local TalismanSkill = Class:new()
function TalismanSkill:__new(configId)
    self.SkillId = configId
    self.ConfigData = SkillManager.GetSkill(configId)
    if self.ConfigData == nil then
        logError("法宝技能配置错误，错误技能Id:" .. tostring(configId))
    end
    self.Level = 1
end
function TalismanSkill:GetConfigId()
    return self.SkillId
end
function TalismanSkill:GetSkillName()
    return self.ConfigData:GetSkillName()
end
function TalismanSkill:GetSkillIcon()
    return self.ConfigData:GetSkillIcon()
end

function TalismanSkill:GetSkillDescription()
    return self.ConfigData:GetSkillDescription()
end
function TalismanSkill:GetSkillDetailDesc()
    return self.ConfigData:GetSkillDetailDesc()
end
function TalismanSkill:GetSkillTime()
    return 1
end
function TalismanSkill:SetLevel(value)
    self.Level = value
end
function TalismanSkill:GetLevel()
    return self.Level
end

function TalismanSkill:IsMaxLevel()
    local lvA = self:GetLevel()
    local lvB = self:GetNextLevel()
    if lvB > lvA then
        return false
    end
    return true
end

function TalismanSkill:CanLevelUp(talismanLv)
    local cost1, cost2, reqlv = self:GetCurrencyCost()
    if talismanLv >= reqlv and (not self:IsMaxLevel()) then
        return true
    end
    return false
end
function TalismanSkill:IsCurrencyEnough(currency1,currency2)
    local cost1, cost2, reqlv = self:GetCurrencyCost()
    if currency1 >= cost1 then
        return true
    end
    return false
end

function TalismanSkill:GetNextLevel()
    local skilllvlupcost = ConfigManager.getConfigData("skilllvlupcost",self:GetConfigId())
    if skilllvlupcost then
        if self.Level + 1 > #(skilllvlupcost.skilllvlupdata) then
            return self.Level
        end
        
        return self.Level + 1
    else
        return 0
    end
end

function TalismanSkill:GetLevelDescription(lv)
    local level = lv or self:GetLevel()
    local skillDescription = ConfigManager.getConfigData("skilldescribe",self:GetConfigId())
    return skillDescription.description[level] or ""
end

function TalismanSkill:GetCurrencyCost()
    local skilllvlupcost = ConfigManager.getConfigData("skilllvlupcost",self:GetConfigId())
    if skilllvlupcost and (not self:IsMaxLevel()) then
        
        local skillLevel = self:GetLevel() + 1
        
        local cost1 = skilllvlupcost.skilllvlupdata[skillLevel].requirecurrency1.amount
        local cost2 = skilllvlupcost.skilllvlupdata[skillLevel].requirecurrency2.amount
        local reqlv = skilllvlupcost.skilllvlupdata[skillLevel].requirelvl
        
        cost1 = (((cost1<0) and 0) or cost1)
        cost2 = (((cost2<0) and 0) or cost2)
        reqlv = (((reqlv<0) and 0) or reqlv)
        
        return cost1, cost2, reqlv
    end
    
    return 0,0,0
end


return TalismanSkill