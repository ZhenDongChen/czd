local utils         = require "common.utils"
local RoleSkill     = require "character.skill.roleskill"
local SkillManager  = require "character.skill.skillmanager"
local ConfigManager = require "cfg.configmanager"
local uimanager     = require "uimanager"
local DlgUIMain_Combat = require "ui.dlguimain_combat"

local MAXLINKCOUNT = 4



-------------------------------------------------------------------------------------
--Class PlayerSkillData
-------------------------------------------------------------------------------------

local PlayerSkillData = Class:new()

function PlayerSkillData:__new(playerskill,skillid,level)
    self.m_SkillSlotIndex           = nil         -- -1： 法宝技能 0 ：普攻 1-6：是技能槽对应的技能 nil 未装备已激活技能
    self.m_FirstSkillId             = skillid
    self.m_PlayerSkill              = playerskill
    self.m_Level                    = level             --技能的等级
    self.m_LeftCD                   = 0                 --剩余冷却时间
    self.m_SkillList                = {}                --List<Skill>
    self.m_CurrentSkillIndex        = 1                 --当前技能
    local skill                     = SkillManager.GetSkill(skillid)
    self.m_ExpireSkillCD            = skill:GetSkillCD()
    local count = 0
    repeat
        table.insert(self.m_SkillList,skill)
        skill = skill:GetNextSkill()
        count = count+1
    until skill == nil or count>=MAXLINKCOUNT

end

function PlayerSkillData:UpdateSkill(level,slotindex)
    self.m_Level =level
    self.m_SkillSlotIndex = slotindex
end 

function PlayerSkillData:HasSkill(skillid)
    for _,id in ipairs(self.m_SkillList) do 
        if skillid == id then 
            return true
        end 
    end 
    return false 
end 

function PlayerSkillData:GetFirstSkill()
    return self.m_SkillList[1]
end

function PlayerSkillData:GetCurrentSkill()
    return self.m_SkillList[self.m_CurrentSkillIndex]
end

function PlayerSkillData:GetCurrentAction()
    return self:GetCurrentSkill():GetAction(self.m_PlayerSkill.m_Player)
end

function PlayerSkillData:GetNextExpireSkillCD()
    local action = self:GetCurrentAction()
        return mathutils.TernaryOperation(action.nextskillexpiretime == -1,
                                      cfg.skill.SkillAction.DEFAULT_NEXTSKILLEXPIRETIME,
                                      action.nextskillexpiretime)
end

function PlayerSkillData:GetNextSkill()
    return  self.m_SkillList[self.m_CurrentSkillIndex+1]
end


function PlayerSkillData:HasNextSkill()
    return  self.m_CurrentSkillIndex+1 <= #self.m_SkillList
end

function PlayerSkillData:IsFirstSkill()
    return self.m_CurrentSkillIndex == 1
end

function PlayerSkillData:CanAttack()

    if not self:IsReady() then
        return false
    end

    if self:GetCurrentSkill() == nil then
        return false
    end

    if not self:IsMpEnough() then
        return false
    end
   

    if not self.m_PlayerSkill.m_Player:CanPlaySkill(self:GetCurrentSkill().skillid) then
        return false
    end
    return true
end

function PlayerSkillData:CanAttackNext()

    if self:GetCurrentSkill() == nil then
        return false
    end

    if not self:IsMpEnough() then
        return false
    end

    if not self:HasNextSkill() then
        return false
    end

    if not self.m_PlayerSkill.m_Player:CanPlaySkill(self:GetNextSkill().skillid) then
        return false
    end

    return true
end

function PlayerSkillData:ShowTips()
    if self:GetCurrentSkill() == nil then
        logError("PlayerSkillData:GetCurrentSkill() is nil")
        return false
    end

    if not self:IsReady() then
        DlgUIMain_Combat.ShowSkillTips(LocalString.DlgUIMain_SkillCdNotReady )
        return false
    end
    if not self:IsMpEnough() then
        DlgUIMain_Combat.ShowSkillTips(LocalString.DlgUIMain_MpNotEnough  )
        return false
    end
end

function PlayerSkillData:GetCDRatio()
    if self.m_ExpireSkillCD > 0 then
        return self.m_LeftCD/self.m_ExpireSkillCD
    end
    return 0
end

function PlayerSkillData:GetLeftCDSecond()
    return self.m_LeftCD
end

function PlayerSkillData:SetLeftCDSecond(leftCD)
    if leftCD > self.m_ExpireSkillCD then
        self.m_LeftCD = self.m_ExpireSkillCD
    elseif leftCD > 0 then
        self.m_LeftCD = leftCD
    else
        self.m_LeftCD = 0
    end
end

function PlayerSkillData:GetExpireSkillCD()
    return self.m_ExpireSkillCD
end


function PlayerSkillData:IsReady()
    return self.m_LeftCD == 0
end

function PlayerSkillData:IsMpEnough()
    local level = self.m_Level
    if self.m_PlayerSkill.m_Player:IsRole() then 
        level = level + RoleSkill.GetAmuletLevel(self:GetFirstSkill())
    end 
    if Local.LogModuals.Skill then 
    printyellowmodule(
    Local.LogModuals.Skill,
    "PlayerSkillData:IsMpEnough()",
    "level",level,
    " UseMp:",
    self:GetCurrentSkill():GetSkillUseMp(level),
    "CurrentMp:",
    self.m_PlayerSkill.m_Player.m_Attributes[cfg.fight.AttrId.MP_VALUE])
    end 
    if self:GetCurrentSkill():GetSkillUseMp(level)~=nil and self.m_PlayerSkill.m_Player.m_Attributes[cfg.fight.AttrId.MP_VALUE]~=nil then 
       return self:GetCurrentSkill():GetSkillUseMp(level) <= self.m_PlayerSkill.m_Player.m_Attributes[cfg.fight.AttrId.MP_VALUE]
    else 
       logError("skill config error","self:GetCurrentSkill():GetSkillUseMp(level)",self:GetCurrentSkill():GetSkillUseMp(level),"self.m_PlayerSkill.m_Player.m_Attributes[cfg.fight.AttrId.MP_VALUE]",self.m_PlayerSkill.m_Player.m_Attributes[cfg.fight.AttrId.MP_VALUE])
       return false
    end 
end

function PlayerSkillData:PlayNextSkill()
    if Local.LogModuals.Skill then
    printyellow("PlayerSkillData:PlayNextSkill()",self:GetFirstSkill().skillid,self:GetFirstSkill():GetSkillName(),self.m_CurrentSkillIndex)
    end
    self.m_CurrentSkillIndex        = self.m_CurrentSkillIndex +1
end

function PlayerSkillData:ResetToFirstSkill()
    self.m_CurrentSkillIndex        = 1
end


function PlayerSkillData:BeginCD()

    self.m_LeftCD                   = self.m_ExpireSkillCD
    
    if Local.LogModuals.Skill then
		printyellow("PlayerSkillData:BeginCD() index:",self.m_CurrentSkillIndex,"m_LeftCD:",self.m_LeftCD )
    end
end



function PlayerSkillData:ResetData()
    self.m_LeftCD                   = 0
    self.m_CurrentSkillIndex        = 1
end

function PlayerSkillData:Update()
    if self.m_LeftCD > 0 then
        self.m_LeftCD = self.m_LeftCD - Time.deltaTime
        if self.m_LeftCD <0 then
            self.m_LeftCD = 0
        end
    end
end



-------------------------------------------------------------------------------------
--Class PlayerSkill
-------------------------------------------------------------------------------------

local PlayerSkill = Class:new()
function PlayerSkill:__new(character)
    self.m_PlayerSkillMap_Index   = {} --Index,PlayerSkillData
    self.m_PlayerSkillMap_SkillId = {} --skillId,PlayerSkillData
    self.m_Player                 = character
    self.m_LastTalismanCD         = 0
    self.m_LastTalismanSkillId    = 0
end




function PlayerSkill:SetSkills(allskills,equipedskills)

    if self.m_Player == nil then 
        return 
    end

    if self.m_PlayerSkillMap_Index ~= nil and self.m_PlayerSkillMap_Index[-1] ~= nil then
        self.m_LastTalismanCD = self.m_PlayerSkillMap_Index[-1]:GetLeftCDSecond()
    end

    --1)移除已经删除的技能
    local PlayerSkillMap_SkillId = {}
    for skillid,playerskilldata in pairs(self.m_PlayerSkillMap_SkillId) do 
        if allskills[skillid] then 
            PlayerSkillMap_SkillId[skillid] = playerskilldata
        end
    end
    
    --2)更新技能
    for skillid,level in pairs(allskills) do 
        if PlayerSkillMap_SkillId[skillid] == nil then 
            PlayerSkillMap_SkillId[skillid] = PlayerSkillData:new(self,skillid,level)
        end 
        PlayerSkillMap_SkillId[skillid]:UpdateSkill(level,equipedskills[skillid])
    end 
    self.m_PlayerSkillMap_SkillId = PlayerSkillMap_SkillId

    --3)刷新技能槽
    local settedTalismanSkill = false
    self.m_PlayerSkillMap_Index = {} 
    for skillid,index in pairs(equipedskills) do 
        self.m_PlayerSkillMap_Index[index] = self.m_PlayerSkillMap_SkillId[skillid]
        if index == -1 then
            settedTalismanSkill = true
            self.m_LastTalismanSkillId = skillid
            if self.m_NeedResetTalismanCD == true then
                local expireSkillCD = self.m_PlayerSkillMap_Index[index]:GetExpireSkillCD()
                self.m_PlayerSkillMap_Index[index]:SetLeftCDSecond(expireSkillCD)
            else
                if self.m_LastTalismanCD > 0 then
                    self.m_PlayerSkillMap_Index[index]:SetLeftCDSecond(self.m_LastTalismanCD)
                end
            end
        end
    end
    if settedTalismanSkill == false then
        self.m_LastTalismanSkillId = 0
    end

end

function PlayerSkill:ResetTalismanCD()
    self.m_NeedResetTalismanCD = true
end

function PlayerSkill:ClearSkillData()
    self.m_PlayerSkillMap_Index = {}
    self.m_PlayerSkillMap_SkillId = {}
end

function PlayerSkill:ResetData()
    if self.m_PlayerSkillMap_SkillId then
        for _,playerskilldata in pairs(self.m_PlayerSkillMap_SkillId) do
            playerskilldata:ResetData()
        end
    end
end

function PlayerSkill:Update()
    if self.m_PlayerSkillMap_SkillId then
        for _,playerskilldata in pairs(self.m_PlayerSkillMap_SkillId ) do
            playerskilldata:Update()
        end
    end
    if self.m_LastTalismanCD > 0 then
        self.m_LastTalismanCD = self.m_LastTalismanCD - Time.deltaTime
    end
end



function PlayerSkill:GetPlayerSkill(skillid)
    local skill = SkillManager.GetSkill(skillid)
    if skill then 
        return self.m_PlayerSkillMap_SkillId[skillid] or self.m_PlayerSkillMap_SkillId[skill.EvolveSkillId]
    end 
    return nil
end

function PlayerSkill:GetPlayerSkillByIndex(index)
    return self.m_PlayerSkillMap_Index[index]
end

return PlayerSkill
