-- local PassiveSkill = require "character.skill.passiveskill"
local SkillBase = require "character.skill.skillbase"

local PassiveSkill = Class:new(SkillBase)

function PassiveSkill:__new()
    SkillBase.__new(self)
    self.PassiveSkill               = nil
end


function PassiveSkill:initData(datapassiveskill)
  --  printyellow("Skill:initData(dataskill)")
    --printyellow(self.skillid)
    --self.Data            = dataskill
    SkillBase.initData(self,datapassiveskill.id)
    self.PassiveSkill        = datapassiveskill
    self.ispassive       = true
    
end




--获取技能图标
function PassiveSkill:GetSkillIcon()
    if self.PassiveSkill then
        return self.PassiveSkill.icon
    end
    return ""
end




--获取技能名称
function PassiveSkill:GetSkillName()
    if self.PassiveSkill then
        return self.PassiveSkill.name
    end
    return ""
end

--获取技能描述
function PassiveSkill:GetSkillDescription()
--    if self.PassiveSkill then
--        return self.PassiveSkill.introduction
--    end
    return ""
end



return PassiveSkill
