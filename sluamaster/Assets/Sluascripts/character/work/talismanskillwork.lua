local defineenum          = require "defineenum"
local WorkType            = defineenum.WorkType
local Work                = require "character.work.work"
local SkillWork           = require "character.work.skillwork"
local mathutils           = require "common.mathutils"



---------------------------------------------------------------------
--TalismanSkillWork
---------------------------------------------------------------------
local TalismanSkillWork = Class:new(SkillWork)

function TalismanSkillWork:__new()
    SkillWork.__new(self)
    self:reset()
    self.type = WorkType.TalismanSkill
end

function TalismanSkillWork:ResetData()
    SkillWork.ResetData(self)
    self.TalismanSkillEffectId = -1
    self.AnimSkillData = nil --对于法宝类型技能，self.Skill为法宝技能配置 self.AnimSkill 为动作技能配置
end

function TalismanSkillWork:PlaySkillEffect()
    -- printyellow("TalismanSkillWork:PlaySkillEffect()",
    --                   "AnimSkillData",self.AnimSkillData.actionname,self.AnimSkillData.effectid,
    --                   "TalismanSkillData",self.Action.actionname,self.Action.effectid)
    self.SkillEffectId = SkillManager.PlaySkillEffect(self.AnimSkillData,
                                                            self.Character.m_Id,
                                                            self.Character:GetTargetId(),
                                                            self.Character:GetPos(),
                                                            defineenum.AudioPriority.Attack)
    self.TalismanSkillEffectId = SkillManager.PlaySkillEffect(self.Action,
                                                            self.Character.m_Id,
                                                            self.Character:GetTargetId(),
                                                            self.Character:GetPos(),
                                                            defineenum.AudioPriority.Attack)
end

function TalismanSkillWork:InitSkillMove()
    --法宝技能没有位移
end

function TalismanSkillWork:OnStart()
    if self.Character.m_Profession then
        self.AnimSkillData = self.Character:GetTalismanAction()
    end
    if self.AnimSkillData == nil then
        return
    end

    SkillWork.OnStart(self)
end


function TalismanSkillWork:IsPlayingSkill()
    return self.Character:IsPlayingSkill(self.AnimSkillData.actionname)
end

function TalismanSkillWork:PlaySkillAction()
    self.Character:PlayActionWithOutEffect(self.AnimSkillData.actionname)
end

function TalismanSkillWork:IsPlayingForeAction()
    return self.Character:IsPlayingForeAction(self.AnimSkillData.actionname)
end

function TalismanSkillWork:PlayForeAction() --前摇
    return self.Character:PlayForeAction(self.AnimSkillData.actionname)
end

function TalismanSkillWork:IsPlayingSuccAction()
    return self.Character:IsPlayingSuccAction(self.AnimSkillData.actionname)
end

function TalismanSkillWork:PlaySuccAction() --后摇
    return self.Character:PlaySuccAction(self.AnimSkillData.actionname)
end

function TalismanSkillWork:OnBreakSkillWork()
    SkillWork.OnBreakSkillWork(self)
    if self.TalismanSkillEffectId > 0 then
        EffectManager.StopEffect(self.TalismanSkillEffectId)
    end
end

return TalismanSkillWork
