local SkillBase = Class:new()

function SkillBase:__new()
    self.skillid                       = 0
    self.ispassive                     = false --是否是被动技能
    self.SkillLvlupCost                = nil --技能升级所需
    self.NextSkillLvlupCost            = nil --进阶后技能升级所需
    self.SkillDescribe                 = nil --技能详细描述
    self.OriginalSkillId               = 0  --进阶的原始技能ID
    self.EvolveSkillId                 = 0 --进阶后的技能ID
    self.FirstSkillID                  = 0  --第一个技能
    
end

--------技能简介 -----------
--[[
	获取技能的基础信息（技能描述，技能升级的费用）
	]]

----------------------------

function SkillBase:initData(skillid)
    local skilllvlupcost = ConfigManager.getConfig("skilllvlupcost") --技能升级的花费
    self.skillid         = skillid
    self.SkillLvlupCost  = skilllvlupcost [self.skillid]

    if self.SkillLvlupCost and self.SkillLvlupCost.nextskillid >0 then
        self.NextSkillLvlupCost =skilllvlupcost[self.SkillLvlupCost.nextskillid]
        self.EvolveSkillId = self.SkillLvlupCost.nextskillid
    end

    self.SkillDescribe  = ConfigManager.getConfigData("skilldescribe",self.skillid)

    self.OriginalSkillId = self.skillid
    local hasoriginal = true
    while hasoriginal do
        hasoriginal = false
        for k,v in pairs(skilllvlupcost) do
            if v.nextskillid == self.OriginalSkillId then
                self.OriginalSkillId = v.skillid
                hasoriginal = true
                break
            end
        end
    end

    self.FirstSkillID =  self.skillid
    

    if Local.LogModuals.Skill then
    printyellow("self.skillid",self.skillid,"self.OriginalSkillId",self.OriginalSkillId,"self.FirstSkillID",self.FirstSkillID)
    end
end


--获取第一个技能
function SkillBase:GetFirstSkill()
    return SkillManager.GetSkill(self.FirstSkillID)
end

--获取进阶前技能
function SkillBase:GetOriginalSkill()
    if self.OriginalSkillId then
        return SkillManager.GetSkill(self.OriginalSkillId)
    end
    return nil
end

function SkillBase:GetFirstOriginalSkill()
    local firstskill = self:GetFirstSkill()
    if firstskill then 
        return firstskill:GetOriginalSkill()
    end 
    return nil
end 

--获取技能图标
function SkillBase:GetSkillIcon()
    --子类实现
    return ""
end

--获取技能名称
function SkillBase:GetSkillName()
    --子类实现
    return ""
end

--获取技能描述
function SkillBase:GetSkillDescription()
    --子类实现
    return ""
end

--获取技能细节描述
function SkillBase:GetSkillDetailDesc(skilllevel)
    if self.SkillDescribe and self.SkillDescribe.description[skilllevel] then
        return self.SkillDescribe.description[skilllevel]
    end
    return ""
end

--是否可以升级
function SkillBase:CanUpgrade(skilllevel)
    if self.SkillLvlupCost then
        return skilllevel < #self.SkillLvlupCost.skilllvlupdata
    end
    return false
end


--获取技能升级所需角色等级
function SkillBase:GetRequirelv(skilllevel)
    if self.SkillLvlupCost and self.SkillLvlupCost.skilllvlupdata[skilllevel] then
        return self.SkillLvlupCost.skilllvlupdata[skilllevel].requirelvl
    end
    return 0
end


--获取技能升级Cost1
function SkillBase:GetUpgradeCost1(skilllevel)
    if self.SkillLvlupCost and self.SkillLvlupCost.skilllvlupdata[skilllevel] then
        local cost =  self.SkillLvlupCost.skilllvlupdata[skilllevel].requirecurrency1.amount
        if cost>=0 then return cost end
    end
    return 0
end

--获取技能升级Cost2
function SkillBase:GetUpgradeCost2(skilllevel)
    if self.SkillLvlupCost and self.SkillLvlupCost.skilllvlupdata[skilllevel] then
        local cost =  self.SkillLvlupCost.skilllvlupdata[skilllevel].requirecurrency2.amount
        if cost>=0 then return cost end
    end
    return 0
end


--获取进阶技能
function SkillBase:GetEvolveSkill()
	print("GetEvolveSkill")
    if self.NextSkillLvlupCost then
        return SkillManager.GetSkill(self.NextSkillLvlupCost.skillid)
    end
    return nil
end

--技能是否可进阶
function SkillBase:CanEvolve(skilllevel)
    if self.SkillLvlupCost and self.NextSkillLvlupCost then
        return skilllevel >= #self.SkillLvlupCost.skilllvlupdata and self.NextSkillLvlupCost
    end
    return false
end

--获取进阶技能所需等级
function SkillBase:GetEvolveRequirelv()
    if self.NextSkillLvlupCost and self.NextSkillLvlupCost.skilllvlupdata[1] then
        return self.NextSkillLvlupCost.skilllvlupdata[1].requirelvl
    end
    return 0
end

--获取技能进阶Cost1
function SkillBase:GetEvolveCost1()
    if self.NextSkillLvlupCost and self.NextSkillLvlupCost.skilllvlupdata[1] then
        local cost =  self.NextSkillLvlupCost.skilllvlupdata[1].requirecurrency1.amount
        if cost>=0 then return cost end
    end
    return 0
end

--获取技能进阶Cost2
function SkillBase:GetEvolveCost2()
    if self.NextSkillLvlupCost and self.NextSkillLvlupCost.skilllvlupdata[1] then
        local cost =  self.NextSkillLvlupCost.skilllvlupdata[1].requirecurrency2.amount
        if cost>=0 then return cost end
    end
    return 0
end

--技能达到满级
function SkillBase:IsMaxLevel(skilllevel)
    if self.SkillLvlupCost then
        return skilllevel >= #self.SkillLvlupCost.skilllvlupdata and self.NextSkillLvlupCost == nil
    end
    return false
end

--角色等级是否满足要求
function SkillBase:RoleLevelAchieve(rolelevel,skilllevel)

    if self:CanUpgrade(skilllevel-1) then

        return rolelevel >= self.SkillLvlupCost.skilllvlupdata[skilllevel].requirelvl
    elseif self:CanEvolve(skilllevel-1) then
		

        return self.NextSkillLvlupCost and rolelevel >= self.NextSkillLvlupCost.skilllvlupdata[1].requirelvl
    end
    return false
end

function SkillBase:GetSkillLvlupData(skilllevel)
    return self.SkillLvlupCost.skilllvlupdata[skilllevel]
end

function SkillBase:IsPassive() 
    return self.ispassive
end 


return SkillBase
