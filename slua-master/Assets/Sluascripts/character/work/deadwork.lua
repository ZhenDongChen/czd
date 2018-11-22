local defineenum = require "defineenum"
local WorkType = defineenum.WorkType
local Work = require "character.work.work"
local AniStatus = defineenum.AniStatus
local DeadWork = Class:new(Work)
local CharacterType =defineenum.CharacterType
local MonsterAudioType = defineenum.MonsterAudioType
local AudioManager = require"audiomanager"
local ConfigManager = require"cfg.configmanager"

local uimanager     = require"uimanager"
function DeadWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.Dead

end

function DeadWork:OnStart()
    self.Character.m_IsDead = true
    self.Character.WorkMgr:StopWork(WorkType.Move)
    self.Character.WorkMgr:StopWork(WorkType.NormalSkill)
    self.Character.WorkMgr:DelayStopWork(WorkType.BeAttacked)
    self.Character.WorkMgr:StopWork(WorkType.FreeAction)
    Work.OnStart(self)
    self.UpdateNextFrame = true
    if self.Character.m_Type == CharacterType.PlayerRole then
        LuaHelper.CameraGrayEffect(true)
        local EctypeManager = require"ectype.ectypemanager"
        if not EctypeManager.IsInEctype() then
            -- print("DeadWork:OnStart 0");
            local ReviveManager=require"character.revivemanager"
            ReviveManager.SetReviveState(true)
        else
            -- print("DeadWork:OnStart 1");
            EctypeManager.Dead()
        end
    end
    
    if self.Character:IsRole() and uimanager.isshow("dlguimain") then
        uimanager.call("dlguimain","SwitchAutoFight",false)
    end
    if self.Character.m_Type == CharacterType.Monster then
        --AudioManager.PlayMonsterAudio(MonsterAudioType.DEAD,self.Character.m_Data,self.Character:GetPos())
    end
    if self.m_bIsDead then
        self.Character:PlayAction(cfg.skill.AnimType.Death)
    else
        self.Character:PlayAction(cfg.skill.AnimType.Dying)
    end
end

function DeadWork:OnUpdate()
end

function DeadWork:OnEnd()
    Work.OnEnd(self)
end

function DeadWork:ResumeWork() 
    Work.ResumeWork(self)
    if self.m_bIsDead then
        self.Character:PlayAction(cfg.skill.AnimType.Death)
    else
        self.Character:PlayAction(cfg.skill.AnimType.Dying)
    end
end 

return DeadWork
