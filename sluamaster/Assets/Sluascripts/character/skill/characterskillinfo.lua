local utils             = require "common.utils"
local mathutils         = require "common.mathutils"
local SkillManager      = require "character.skill.skillmanager"
local PlayerRole

local SkillInfoState = enum
{
    "NotActive",
}

---------------------------------------------------------------------
--SkillInfo
---------------------------------------------------------------------
local SkillInfo = Class:new()
function SkillInfo:__new(skillid,level,actived)
    self.skillid = skillid
    self.level   = level
    self.actived = actived
    PlayerRole = require "character.playerrole"
end

function SkillInfo:GetSkill()
    return SkillManager.GetSkill(self.skillid)
end

---------------------------------------------------------------------
--CharacterSkillInfo
---------------------------------------------------------------------

local CharacterSkillInfo = Class:new()
function CharacterSkillInfo:__new()
    self.AllSkills         = {} -- List<SkillInfo>
    self.EquipedSkills     = {} -- index,skillid
end

function CharacterSkillInfo:init(characterskills,msg_skills,msg_equipskills)

    self.AllSkills = {}
    self.EquipedSkills = {}
    for _,skillid in ipairs(characterskills) do
         table.insert(self.AllSkills,SkillInfo:new(skillid,1,false))
    end

    for _,v in pairs(msg_skills) do
        local skillid = SkillManager.GetOriginalSkillId(v.skillid)
        local skillinfo = self:GetSkillInfoBySkillId(skillid)
			skillinfo.skillid = v.skillid
			skillinfo.level = v.level
			skillinfo.actived = true
    end

    if msg_equipskills ~=nil then
        for k,v in pairs(msg_equipskills) do
            self.EquipedSkills [v] = k
        end
    end
end

function CharacterSkillInfo:GetSkillInfoBySkillId(skillid)
    for _,skillinfo in pairs(self.AllSkills) do
        if skillinfo.skillid == skillid then
            return skillinfo
        end
    end
    return nil
end

function CharacterSkillInfo:Reset()
    self.AllSkills         = {} -- List<SkillInfo>
    self.EquipedSkills     = {} -- index,skillid
end

function CharacterSkillInfo:GetAllSkills()
    return self.AllSkills
end

function CharacterSkillInfo:GetEquipedSkills()
    return self.EquipedSkills
end


function CharacterSkillInfo:ChangeEquipActiveSkill(equipskillpositions)
    self.EquipedSkills = {}
    for k,v in pairs(equipskillpositions) do
        self.EquipedSkills [v] = k
    end
end

function CharacterSkillInfo:GetEquipSkillsMap()
    local ret = {}
    for i,v in pairs(self.EquipedSkills) do
        ret[v.skillid] = v.level
    end
end



function CharacterSkillInfo:ActiveSkill(skillid,level)
    local skillinfo = self:GetSkillInfoBySkillId(skillid)
    skillinfo.actived = true
    skillinfo.level = level
    return skillinfo
end


function CharacterSkillInfo:UpgradeSkill(skillid,newlevel)
    local skillinfo = self:GetSkillInfoBySkillId(skillid)
    skillinfo.level = newlevel
    return skillinfo
end


function CharacterSkillInfo:EvolveSkill(oldskillid,newskillid)
    local skillinfo = self:GetSkillInfoBySkillId(oldskillid)
    if skillinfo then
        skillinfo.skillid =  newskillid
        skillinfo.level = 1
    end

    for index,skillid in pairs(self.EquipedSkills) do
        if skillid == oldskillid then
            self.EquipedSkills[index] = newskillid
        end
    end
    return skillinfo
end






return CharacterSkillInfo
