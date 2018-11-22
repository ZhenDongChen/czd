-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成



-- endregion
-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成



-- endregion
local defineenum = require "defineenum"
local WorkType = defineenum.WorkType
local Work = require "character.work.work"
local AniStatus = defineenum.AniStatus
local WorkManager = "character.work.workmanager"
local ReviveWork = Class:new(Work)
local uimanager     = require"uimanager"
function ReviveWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.Relive
end

function ReviveWork:OnStart()
    Work.OnStart(self)
    self.m_IsDead = false
    self.m_IsRevive = true
    self.m_UpdateNextFrame = true
    self.Character:PlayAction(cfg.skill.AnimType.GetUp)
    if self.Character:IsRole() then
        LuaHelper.CameraGrayEffect(false)
        local EctypeManager = require"ectype.ectypemanager"
        if EctypeManager.IsInEctype() then
            local ectypeid = EctypeManager.GetEctype().m_ID
            local ectypeInfo = ConfigManager.getConfigData("ectypebasic",ectypeid)
            if ectypeInfo and ectypeInfo.rebornfight then
                uimanager.call("dlguimain","SwitchAutoFight",true)
            end
        end
    end
end

function ReviveWork:OnUpdate()
    if self.m_UpdateNextFrame then self.m_UpdateNextFrame = false return end
    if not self.Character:IsPlayingAction(cfg.skill.AnimType.GetUp) then
        self:OnEnd()
    end
end

function ReviveWork:OnEnd()
    self.m_IsRevive = false
    self.Character.WorkMgr:ReStartWorks()
    self.Character.WorkMgr:Revive()
    local EctypeManager = require"ectype.ectypemanager"
    if EctypeManager.IsBattleEctype() then
        self.Character.m_HeadInfo:ShowHpProgress(true)
    end
    Work.OnEnd(self)
end

return ReviveWork
