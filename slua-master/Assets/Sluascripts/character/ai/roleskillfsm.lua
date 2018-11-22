local PlayerRole       = require "character.playerrole"
local RoleSkill        = require "character.skill.roleskill"
local AttackActionFsm  = require "character.ai.attackactionfsm"
local DlgUIMain_Combat = require "ui.dlguimain_combat"
local gameevent        = require "gameevent"
local mathutils        = require "common.mathutils"
local Fsm              = require "character.ai.fsm"
local defineenum        = require "defineenum"
local CharacterManager = require "character.charactermanager"
local autoaievents      = defineenum.AutoAIEvent

local RoleSkillFsm = Class:new(Fsm)

RoleSkillFsm.FsmState = enum{
    "None",
    "WalkToTarget",
    "Attacking",
    "WaitForNextSkill",
}

function RoleSkillFsm:__new()
    self:reset()
    self.m_CurrentState       = self.FsmState.None        --当前状态
    self.m_CurrentPlayerSkillData = nil                    --当前按下的技能
end

function RoleSkillFsm:reset()
    if Local.LogModuals.Skill then
    printyellow("RoleSkillFsm:reset()")
    end
    Fsm.reset(self)
    self.m_CurrentPlayerSkillData = nil                    --当前按下的技能
    self:SetState(self.FsmState.None)
end


function RoleSkillFsm:SetState(state)
    if Local.LogModuals.Skill then
    printyellow("RoleSkillFsm SetState" ,utils.getenumname(self.FsmState,state))
    end
    self.m_CurrentState = state
    self:ResetElapsedTime()
end

function RoleSkillFsm:GetState()
    return self.m_CurrentState
end

function RoleSkillFsm:ShowTips()

end


function RoleSkillFsm:Update()
    Fsm.Update(self)
    --WalkToTarget
    if self.m_CurrentState == self.FsmState.WalkToTarget then
        self:UpdateWalkToTargetState()
        --Attacking
    elseif self.m_CurrentState == self.FsmState.Attacking then
        self:UpdateAttackingState()
        --WaitForNextSkill
    elseif self.m_CurrentState == self.FsmState.WaitForNextSkill then
        self:UpdateWaitForNextSkillState()

    end
end


--自动跟随打怪
function RoleSkillFsm:UpdateWalkToTargetState()
    local attackTarget = PlayerRole:Instance():GetTarget()
    if  attackTarget == nil then
        self:reset()
        local autoai = require "character.ai.autoai"
        
        if Local.LogModuals.AutoAI then
            print("+++++++target is nil............")
        end
       
        autoai.OnEvent(autoaievents.nomonster)
        return
    end
    if mathutils.DistanceOfXoY(PlayerRole:Instance():GetRefPos(), attackTarget:GetRefPos()) >
        self.m_CurrentPlayerSkillData:GetCurrentAction().attackrange then
		printyellow("UpdateWalkToTargetState autofight to NavigateTo")
        if not self:NavigateTo(attackTarget.m_Pos) then
            self:reset()
            print("+++++++ can not nav to...........")
            return
        end
    else
        if not CharacterManager.CanAttack(attackTarget) then
            self:reset()
            local autoai = require "character.ai.autoai"
            
            if Local.LogModuals.AutoAI then
                print("+++++++target CanAttack false............")
            end
           
            autoai.OnEvent(autoaievents.nomonster)
            return
        end
    
        if PlayerRole:Instance():IsMoving() then
            PlayerRole:Instance():stop()
        end
		local Angle = mathutils.PosGetAngle(attackTarget.m_Pos, PlayerRole:Instance().m_Pos);
		PlayerRole:Instance():SetEulerAngleImmediate(Angle)

        self:Attack()
    end
end





function RoleSkillFsm:UpdateAttackingState()
    if self.m_CurrentPlayerSkillData then
        local currentaction = self.m_CurrentPlayerSkillData:GetCurrentAction()
        if currentaction == nil or
           self.elapsedTime > currentaction.endattackingtime +self.m_CurrentPlayerSkillData:GetNextExpireSkillCD() then
            --self.m_CurrentPlayerSkillData:BeginCD()
            self.m_CurrentPlayerSkillData:ResetToFirstSkill()
            self:reset()

            local autoai = require "character.ai.autoai"
            if Local.LogModuals.AutoAI then
                print("+++++++action is nil or time > ............currentaction", currentaction)
            end
            autoai.OnEvent(autoaievents.skillover)
        end
    else
        self:reset()
    end

end

function RoleSkillFsm:UpdateWaitForNextSkillState()
    if self.m_CurrentPlayerSkillData then
        if self.m_CurrentPlayerSkillData:GetNextSkill() == nil or
           self.elapsedTime > self.m_CurrentPlayerSkillData:GetNextExpireSkillCD() then
            self.m_CurrentPlayerSkillData:ResetToFirstSkill()
            self:reset()

        end
    else
        self:reset()
    end
end


function RoleSkillFsm:CanAttack(playerskilldata)
    if playerskilldata == nil then
        return false
    end
    if Local.LogModuals.Skill then
    printyellow("playerskilldata.m_LeftCD",tostring(playerskilldata.m_LeftCD))
    end
    if self.m_CurrentState  == self.FsmState.Attacking then
        if playerskilldata:CanAttack() then
            return not playerskilldata:GetCurrentSkill():IsNormal() and self.m_CurrentPlayerSkillData:GetCurrentSkill():IsNormal()
        end
    elseif self.m_CurrentState  == self.FsmState.WaitForNextSkill then
        if self.m_CurrentPlayerSkillData.m_SkillSlotIndex == playerskilldata.m_SkillSlotIndex then
            return playerskilldata:CanAttackNext()
        else
            return playerskilldata:CanAttack()
        end
    elseif self.m_CurrentState  == self.FsmState.WalkToTarget then
        if self.m_CurrentPlayerSkillData.m_SkillSlotIndex == playerskilldata.m_SkillSlotIndex then
            return false
        else
            return self.m_CurrentPlayerSkillData:GetCurrentSkill():IsNormal() and not playerskilldata:GetCurrentSkill():IsNormal() and playerskilldata:CanAttack()
        end
    else
        return playerskilldata:CanAttack()
    end

    return false
end

function RoleSkillFsm:TryToAttack(playerskilldata)
    if self.m_CurrentPlayerSkillData then
        if self.m_CurrentPlayerSkillData.m_SkillSlotIndex == playerskilldata.m_SkillSlotIndex then
            self.m_CurrentPlayerSkillData:PlayNextSkill()
        else
            self.m_CurrentPlayerSkillData:ResetToFirstSkill()
        end
    end
    self.m_CurrentPlayerSkillData = playerskilldata
    local relation =  self.m_CurrentPlayerSkillData:GetCurrentSkill():GetRelation()
    if(self.m_CurrentPlayerSkillData:GetCurrentAction().needtarget) then
        local target = PlayerRole:Instance():GetTargetToAttack4AI(relation)
        if target == nil then
            self:reset()
            print("+++++++target is nil now............")
            local UIManager = require("uimanager")
            UIManager.ShowSystemFlyText(LocalString.FlyText_NoTarget)
            return
        end
        PlayerRole:Instance():SetTarget(target)
        self:SetState(self.FsmState.WalkToTarget)
    else
        if cfg.role.Const.SMART_ATTACK>0 then
            --智能施法
            local target = PlayerRole:Instance():GetTargetToAttack4AI(relation)
            if target == nil then
                self:Attack()
            else
                PlayerRole:Instance():SetTarget(target)
                self:SetState(self.FsmState.WalkToTarget)
            end
        else
            --非智能施法，技能可能打空
            self:Attack()
        end
    end

end

function RoleSkillFsm:Attack()
    if self.m_CurrentPlayerSkillData == nil or self.m_CurrentPlayerSkillData:GetCurrentSkill() == nil then
        self:reset()
        return
    end
    if Local.LogModuals.Skill then
    printyellow("RoleSkillFsm:Attack()",self.m_CurrentPlayerSkillData:GetCurrentSkill().skillid)
    end
    PlayerRole:Instance():SendAttack(self.m_CurrentPlayerSkillData:GetCurrentSkill().skillid)
    if self.m_CurrentPlayerSkillData:IsFirstSkill() then
        self.m_CurrentPlayerSkillData:BeginCD()
    end
    self:SetState(self.FsmState.Attacking)
end

function RoleSkillFsm:OnButtonCastSkill(index)
    local playerskilldata = RoleSkill.GetRoleSkillByIndex(index)
    if Local.LogModuals.Skill then
        printyellow("RoleSkillFsm:OnButtonCastSkill(index)",index,"skillid:",playerskilldata:GetCurrentSkill().skillid)
        printyellow("self:CanAttack(playerskilldata)",self:CanAttack(playerskilldata))
    end

    if self:CanAttack(playerskilldata) then
        self:TryToAttack(playerskilldata)
    else
        if playerskilldata==nil or playerskilldata:GetCurrentSkill() == nil then 
            logError("playerskilldata is nil")
        elseif  not PlayerRole:Instance():CanPlaySkill(playerskilldata:GetCurrentSkill().skillid) then 
            DlgUIMain_Combat.ShowSkillTips(LocalString.DlgUIMain_CannotAttack)
        elseif index ~= 0 then
            playerskilldata:ShowTips()
        end
    end
end

function RoleSkillFsm:OnJoyStickMove(delta)
    if self.m_CurrentState == self.FsmState.WalkToTarget then
        self:reset()
        return
    elseif self.m_CurrentState == self.FsmState.Attacking then
        if not PlayerRole:Instance():CanMove() and PlayerRole:Instance():CanRotate() then
            local angle = mathutils.PosGetAngle(delta)
            PlayerRole:Instance():SetEulerAngle(angle)
            PlayerRole:Instance():SendOrient(angle)        end
    end
end


function RoleSkillFsm:NotifyAttackComplete(bCastCallBackSkill)
    if self.m_CurrentPlayerSkillData == nil then
        return
    end
    if self.m_CurrentPlayerSkillData:GetNextSkill() then
        self:SetState(self.FsmState.WaitForNextSkill)
    else
        self.m_CurrentPlayerSkillData:ResetToFirstSkill()
        self:reset()
    end

    DlgUIMain_Combat.NotifyAttackComplete(self.m_CurrentPlayerSkillData)

    local autoai = require "character.ai.autoai"
    autoai.OnEvent(autoaievents.skillover)

end


function RoleSkillFsm:NotifyAttackBeBroken(skillid)
    if self.m_CurrentPlayerSkillData~=nil and self.m_CurrentPlayerSkillData:HasSkill(skillid) then
        self.m_CurrentPlayerSkillData:ResetToFirstSkill()
        self:reset()


        local autoai = require "character.ai.autoai"
        if Local.LogModuals.AutoAI then
            print("+++++++skill be broken now............")
        end
        autoai.OnEvent(autoaievents.skillover)

    end
end


function RoleSkillFsm:NavigateTo(targetpos)
	printyellow()
    local mapid, currenttargetpos = PlayerRole:Instance():GetNavigateTarget()
    if currenttargetpos == nil or mathutils.DistanceOfXoY(targetpos, currenttargetpos)>180 then
        if not PlayerRole:Instance():CanReach(targetpos) then
            return false
        end
        PlayerRole:Instance():navigateTo({targetPos = targetpos,notStopAutoFight = true})
    end
    return true
end



-----------------------------------------
---------自动挂机 Begin
-----------------------------------------
function RoleSkillFsm:TryToAttackBySkillId(skillid)
    local playerskilldata = RoleSkill.GetRoleSkill(skillid)
    if self:CanAttack(playerskilldata) then
        self:TryToAttack(playerskilldata)
        return true
    end
    return false
end


function RoleSkillFsm:CanAttackNext(skillid)
    local playerskilldata = RoleSkill.GetRoleSkill(skillid)
    if playerskilldata == nil then
        return false
    end
    return playerskilldata:CanAttackNext()
end

-----------------------------------------
---------自动挂机 End
-----------------------------------------






return RoleSkillFsm