local SkillBase = require "character.skill.skillbase"

local Skill = Class:new(SkillBase)

function Skill:__new()
    SkillBase.__new(self)
    self.SkillDmg                      = nil --技能伤害
end


function Skill:initData(dataskilldmg)
    SkillBase.initData(self,dataskilldmg.id)
    self.SkillDmg        = dataskilldmg
    self.ispassive       = false
    local hasoriginal = true
    while hasoriginal do
        hasoriginal = false
        for k,v in pairs(ConfigManager.getConfig("skilldmg")) do
            if v.nextskillid == self.FirstSkillID then
                self.FirstSkillID = v.id
                hasoriginal = true
                break
            end
        end
    end
end


--获取下一个技能
function Skill:GetNextSkill()
    if self.SkillDmg.nextskillid then
        return  SkillManager.GetSkill(self.SkillDmg.nextskillid)
    end
    return nil
end

--获取技能图标
function Skill:GetSkillIcon()
    if self.SkillDmg then
        return self.SkillDmg.icon
    end
    return ""
end

function Skill:GetSkillCD()
    if self.SkillDmg then
        return self.SkillDmg.cd
    end
    return 0
end

function Skill:IsNormal()
    return self.SkillDmg.isnormal
end 


function Skill:GetSkillUseMp(level)
    if self.SkillDmg then
        return self.SkillDmg.cost + level *self.SkillDmg.costperlvl
    end
    return 0
end

function Skill:GetRelation()
    if self.SkillDmg then
        for _,hit in pairs(self.SkillDmg.hitpoints) do
            if hit.target~=nil then 
                return hit.target
            elseif hit.damages~=nil then  
                for _,bombhit in pairs(hit.damages) do
                    return bombhit.target
                end 
            end 
        end
    end
    return nil
end



--获取技能名称
function Skill:GetSkillName()
    if self.SkillDmg then
        return self.SkillDmg.name
    end
    return ""
end

--获取技能描述
function Skill:GetSkillDescription()
    if self.SkillDmg then
        return self.SkillDmg.introduction
    end
    return ""
end


function Skill:GetActionType() 
    if self.SkillDmg then
        return self.SkillDmg.actiontype
    end
    return nil
end

function Skill:GetAction(character)
    if self.SkillDmg then
        if self:GetActionType() == cfg.skill.ActionType.TALISMAN then
            return SkillManager.GetTalismanAction(self.SkillDmg.actionname)
        else
            return character:GetAction(self.SkillDmg.actionname)
        end
        
    end
    return nil
end

function Skill:HasMovement(character) 
    local action = self:GetAction(character)
    if action  and #action.MovementList>0 then 
        return true
    end
    return false 
end 

return Skill
