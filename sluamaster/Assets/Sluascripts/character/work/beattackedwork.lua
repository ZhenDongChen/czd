local defineenum = require "defineenum"
local Work       = require "character.work.work"
local dlgflytext = require "ui.dlgflytext"
local WorkType   = defineenum.WorkType
local AniStatus  = defineenum.AniStatus
local CharState  = defineenum.CharState
local charactermanager
local AttackActionFsm
local defineenum = require"defineenum"
local CharacterType = defineenum.CharacterType
local BeAttackActionFsm
local AudioManager = require"audiomanager"
local MonsterAudioType = defineenum.MonsterAudioType
local bShowFlash = true


local BeAttackedWork = Class:new(Work)

BeAttackedWork.ShowFlash = function(b)
    bShowFlash = b
end

function BeAttackedWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.BeAttacked
    self.m_BeAttackedInfos = { }
    charactermanager = require "character.charactermanager"
    BeAttackActionFsm = require "character.ai.beattackactionfsm"
    AttackActionFsm = require "character.ai.attackactionfsm"

end

function BeAttackedWork:reset()
    Work.reset(self)
    self.m_BeAttackedInfos = { }
end

function BeAttackedWork:OnUpdate()
    for i = #self.m_BeAttackedInfos, 1, -1 do
        repeat
            local info = self.m_BeAttackedInfos[i]
            if info == nil then
                table.remove(self.m_BeAttackedInfos, i)
                break
            end
            self.m_Attacker = charactermanager.GetCharacter(info.AttackerId)
            if not self.Character:IsDead() then
                self:SetBeattackFly(info, self.m_Attacker)
                if self.Character.m_Type == CharacterType.Monster then
                    --AudioManager.PlayMonsterAudio(MonsterAudioType.BEATTACK,self.Character.m_Data,self.Character:GetRefPos())
					self:AddMonsterHurtRender()
                end
                --AudioManager.PlaySoundEffect(cfg.audio.SoundTypes.BEATTACK,self.Character:GetRefPos())
                self:AddHurtImpact(info)
                self:AddSkillImpact(info)

                -- end
            end
            if (self.m_Attacker and self.m_Attacker:HaveRelationshipWithRole()) or self.Character:HaveRelationshipWithRole() then
                dlgflytext.AddInfo(tostring(info.DetailInfo.attack),self.m_Attacker, self.Character, info,1)
            end
            table.remove(self.m_BeAttackedInfos, i)
        until true
    end

    if #self.m_BeAttackedInfos == 0 then
        self:End()
    end


end

function BeAttackedWork:SetBeattackFly(info, attacker)
    local canBeAttack  = self.Character.AttackActionFsm.CurrentState == AttackActionFsm.FsmState.None
    if canBeAttack then
        self.Character.BeAttackActionFsm:SetBeAttackedAction(attacker, info)
    end
end

function BeAttackedWork:AddHurtImpact(info)

end

function BeAttackedWork:AddSkillImpact(info)

end

function BeAttackedWork:AddMonsterHurtRender()
    if self.Character.m_BodyObjectsColor then
        for _,component in pairs(self.Character.m_BodyObjectsColor) do
			if component.enabled == false then
				self:SetBeAttackedColor(component)
			end
        end
    end
end
--50;47;58;178

function BeAttackedWork:SetBeAttackedColor(objColor)
    objColor.fromColor = Color(255/255,0/255,0/255,255/255)
    objColor.toColor = Color(255/255,0/255,0/255,1)
    objColor:SetDuringTime(5)
    objColor:SetRimPower(5)
    objColor:SetRimPowerEnd(5)
    objColor.enabled = true
end

function BeAttackedWork:Add(info)
    table.insert(self.m_BeAttackedInfos, info)
end

function BeAttackedWork:OnEnd()
    Work.OnEnd(self)
end

return BeAttackedWork
