local DefineEnum = require "defineenum"
local Define = require "define"
local AnimType=Define.AnimType
local WorkType = DefineEnum.WorkType
local CharState = DefineEnum.CharState
local Work = require "character.work.work"
local MathUtils = require "common.mathutils"
local CharacterType=DefineEnum.CharacterType
local SceneMgr=require "scenemanager"
local SceneManager = Game.SceneMgr
--local AudioManager = require"audiomanager"

local MoveWork = Class:new(Work)

function MoveWork:__new()
    Work.__new(self)
    self:reset()
    self.type = WorkType.Move
end

function MoveWork:reset()
    Work.reset(self)
    self.m_Dir = Vector3.zero
	self.m_Angle = 0;
    self.Target = Vector3.zero
    self.YUpdateEnd = true
    self.Speed = 300
    self.NewSpeed = nil
end

function MoveWork:CanDo()
    if not Work.CanDo(self) then
        return false
    end
    return self.Character:CanMove()
end



function MoveWork:OnStart()
    Work.OnStart(self)
    local charPos = self.Character:GetRefPos()
	self.m_Dir = Vector3(self.Target.x - charPos.x, self.Target.y - charPos.y, 0).normalized
	self.m_Angle = MathUtils.PosGetAngle(self.Target, charPos);
	--printyellow(">>>>>>>>>>>>>>>self.m_Angle",self.Character.m_Name,self.m_Angle)
	self.Character:SetEulerAngle(self.m_Angle)

    if self.NewSpeed ~= nil then

        self.Speed = self.NewSpeed
    else

        self.Speed = self.Character.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]
    end
    self:PlayRunAnimation()
end



function MoveWork:OnEnd()  
    Work.OnEnd(self)
    if (self.Character:IsRole()) or ((self.Character:IsMount()) and (self.Character:PlayerIsRole())) then
        self.Character.m_TransformSync:SendStop()
    end
end

function MoveWork:UpdatePosY()
    
--[[    local RealDisY = self.Target.z - self.Character:GetRefPos().z
    if math.abs(RealDisY) > 0.1 then
        local moveDis = self.Speed * Time.deltaTime
        local offsetZ = MathUtils.TernaryOperation(moveDis >= math.abs(RealDisY), RealDisY, moveDis * RealDisY / math.abs(RealDisY))
        self.Character.m_OffsetY = self.Character.m_OffetY + offsetZ
        --self.Character:GetPos() = self.Character:GetPos() + Vector3(0, offsetY, 0)
        self.YUpdateEnd = false
    else
        self.YUpdateEnd = true
    end--]]
end


function MoveWork:OnUpdate()

    Work.OnUpdate(self)
    if self.Character:HasState(CharState.Air) then
       -- self:UpdatePosY()
    end
    self:UpdatePos()
end 

function MoveWork:NeedPlayRunAnimation() 
    if self.Character:IsAttacking() then
        return false
    end 

    if self.Character:IsMonster() then
        if self.Speed >3 then
            return not self.Character:IsPlayingAction(cfg.skill.AnimType.RunFight)
        else 
            return not self.Character:IsPlayingAction(cfg.skill.AnimType.Walk)
        end
    elseif self.Character:IsPlayer() and self.Character:IsRiding() then
        return false
    end

    return not self.Character:IsPlayingRun()
end 

function MoveWork:PlayRunAnimation()
	
    if not self:NeedPlayRunAnimation() then
        return 
    end 

    if self.Character:IsMonster() then
        if self.Speed >3 then
            self.Character:PlayLoopAction(cfg.skill.AnimType.RunFight)
        else 
            self.Character:PlayLoopAction(cfg.skill.AnimType.Walk)
        end
    elseif self.Character:IsMount() then
        self.Character:PlayRunWithPlayer()
    else
        if not self.Character:IsPlayingRun() then
            self.Character:PlayLoopAction(cfg.skill.AnimType.Run)
        end
    end
    
end

function MoveWork:ResumeWork()
    self:PlayRunAnimation()
end 

function MoveWork:UpdatePos()
    local vecPos = Vector3.zero
    local charPos = self.Character:GetRefPos()
	
    if MathUtils.DistanceOfXoY(charPos, self.Target) < self.Speed * Time.deltaTime then
        vecPos = Vector3(self.Target.x, self.Target.y, 0)
		if (not self.Character:CanMoveTo(vecPos)) then
			vecPos=charPos
		end
        self:End()
    else
        vecPos = charPos + self.m_Dir * self.Speed * Time.deltaTime
    end
    if self.Character:IsRole() or (self.Character:IsMount() and self.Character:PlayerIsRole()) then
        if self.Character:IsNavigating() then
            if (not self.Character:CanReach(vecPos)) then
                self.Character:stop()
                vecPos=charPos
                return
            end
        else
            if (not self.Character:CanMoveTo(vecPos)) then
                vecPos=charPos
                self:End()
            end
        end
    end

    self.Character:SetPos(vecPos)
end



return MoveWork
