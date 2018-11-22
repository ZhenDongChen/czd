local Fsm              = require "character.ai.fsm"

------------------------------------------------------------------------------
--TraceObject
------------------------------------------------------------------------------
local ErrorEffectId = -1
local Id = 0
local function GetId()
    Id= Id+1
    return Id
end 
local TraceObject = Class:new(Fsm)

function TraceObject:__new()
    self:reset()
end

TraceObject.FsmState = enum
{
    "None",
    "Start",
    "Born",
    "Fly",
    "Dead",
}

TraceObject.TraceType = enum
{
    "FlyWeapon",
    "Bomb",
    "Unkwon",
}



function TraceObject:reset()
    if Local.LogModuals.TraceObject then
        printyellow("TraceObject:reset()",self.m_Id)
    end
    self.m_Id              = 0
    self.m_fStartTime      = 0
    self.m_TargetId        = 0 
    self.m_BornPos         = Vector3.zero
    self.m_TargetPos       = Vector3.zero
    self.m_Pos             = Vector3.zero
    self.m_Forward         = nil
    
    self.m_Attacker        = nil
    self.m_EffectId        = ErrorEffectId
    self.m_Data            = nil
    self.m_TraceCurveData  = nil
    self.m_Skill           = nil
    self:SetState(TraceObject.FsmState.None)
    

end



function TraceObject:SetState(state)
    if Local.LogModuals.TraceObject then
        printyellow("TraceObject SetState",self.m_Id,Time.time, utils.getenumname(self.FsmState,state))
    end
    self.m_CurrentState = state
    self:ResetElapsedTime()
end

function TraceObject:InitData(attacker,targetId,skill,data)
    
    self.m_Id = GetId()
    self.m_Attacker    = attacker
    self.m_Skill       = skill
    self.m_TargetId    = targetId
    self.m_Data        = data
    if Local.LogModuals.TraceObject then
        printyellow("TraceObject:InitData",self.m_Id,self.m_Attacker.m_ModelData.modelname,self.m_ObjectId)
        printt(self.m_Data)
    end 
    self.m_TraceCurveData = ConfigManager.getConfigData("tracecurve",self.m_Data.tracecurveid)
    
    self.m_Forward       =self.m_Attacker.m_Object.transform.forward
    self:InitBornPos(self.m_Attacker.m_Object.transform.position)
    
    

end

function TraceObject:Start()
    self.m_fStartTime = Time.time
    self:SetState(TraceObject.FsmState.Start)
end

function TraceObject:IsAttacking()
    return self.m_CurrentState == self.FsmState.Born or self.m_CurrentState == self.FsmState.Fly
end


function TraceObject:IsDead()
    return self.m_CurrentState == self.FsmState.Dead
end

function TraceObject:GetTraceObjType()
    return TraceObject.TraceType.Unkwon
end

function TraceObject:InitBornPos(pos)
    self.m_BornPos       = pos
    self.m_Pos           = pos
end

function TraceObject:IsFixed()
    if Local.LogModuals.TraceObject then
        printt(self.m_Data)
    end
    return self.m_Data.tracetype == cfg.skill.TraceObject.TRACETYPE_FIXED and self:GetTraceObjType() ~= TraceObject.TraceType.FlyWeapon
end 


function TraceObject:StartFly(effectobj) --代表特效已经生成了
    self:InitBornPos(effectobj.transform.position)
    self:SetState(TraceObject.FsmState.Fly)
end

function TraceObject:Update()
    Fsm.Update(self)
    --Start
    if self.m_CurrentState == self.FsmState.Start then
        self:UpdateStartState()
        --Born
    elseif self.m_CurrentState == self.FsmState.Born then
        self:UpdateBornState()
        --Fly
    elseif self.m_CurrentState == self.FsmState.Fly then
        self:UpdateFlyState()

        --Dead
    elseif self.m_CurrentState == self.FsmState.Dead then
        self:UpdateDeadState()

    end
    
end


function TraceObject:UpdateStartState()
    if Time.time - self.m_fStartTime >= self.m_Data.timeline then 
        if self:IsFixed() then
            local character = CharacterManager.GetCharacter(mathutils.TernaryOperation(self.m_Data.totarget,self.m_TargetId,self.m_Attacker.m_Id))
            if character then
                local targetpos = character.m_Pos + Quaternion.Euler(0,180,character.m_Object.transform.localEulerAngles.z) * Vector3(self.m_Data.offsetx,self.m_Data.offsety,self.m_Data.offsetz)
				targetpos = targetpos * SCALE_XY_FRACTION;
				targetpos.z = -20;
                self.m_EffectId =SkillManager.PlayTargetPosEffect(self.m_Skill:GetAction(self.m_Attacker),
                                                                 self.m_Data.effectid,
                                                                 self.m_Attacker.m_Id,
                                                                 self.m_TargetId,
                                                                 targetpos)
                
                self:InitBornPos(targetpos)
            end

        elseif self.m_Data.tracetype == cfg.skill.TraceObject.TRACETYPE_FLY then
            self.m_EffectId =  SkillManager.PlayTraceObjEffect(self.m_Skill:GetAction(self.m_Attacker),
                                                                self.m_Data.effectid,
                                                                self.m_Attacker.m_Id,
                                                                self.m_TargetId,
                                                                self)
        end

        self:SetState(TraceObject.FsmState.Born)
       
    end
end

function TraceObject:UpdateBornState()
    if Time.time - self.m_fStartTime >= self.m_Data.timeline + self.m_Data.life then 
        self:SetState(TraceObject.FsmState.Dead)
    end
end

function TraceObject:UpdateFlyState()
    local elapsedTime = Time.time - self.m_fStartTime - self.m_Data.timeline
    if elapsedTime >= self.m_Data.life then 
        self:SetState(TraceObject.FsmState.Dead)
        return
    end
        
        local theta = self.m_TraceCurveData.angle/180 * math.pi 
        local hspeed = self.m_TraceCurveData.velocity * math.cos(theta)
        local vspeed = self.m_TraceCurveData.velocity * math.sin(theta)
        

        local hdistance = hspeed * elapsedTime --暂时去掉了加速度 + 0.5 * self.m_TraceCurveData.hacc * elapsedTime * elapsedTime
        local vdistance = vspeed * elapsedTime + 0.5 * self.m_TraceCurveData.vacc * elapsedTime * elapsedTime

        
        self.m_Pos = self.m_BornPos + self.m_Forward * hdistance + Vector3.up * vdistance
end

function TraceObject:UpdateDeadState()
end


function TraceObject:Release()

end


function TraceObject:Destroy() 
    EffectManager.StopEffect(self.m_EffectId)
    self:reset()
end 

function TraceObject:GetPos()
    return self.m_Pos
end 


function TraceObject:OnBreakSkill()
    if self.m_CurrentState == self.FsmState.Start then 
        self:SetState(TraceObject.FsmState.Dead)
    end 
end 

 

return TraceObject