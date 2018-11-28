local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AniamtorSpeed = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorSpeed.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorSpeed.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)

    self.CurrentTime = 0

    if self.Mode == "Instant" then
        self.Cutscene.m_Animator:SetSpeed(self.Animator, self.SpeedValue)
        self.CurrentState = PlotDefine.ElementState.Ended;
    elseif self.Mode == "Event" then
        self.Cutscene.m_Animator:SetSpeed(self.Animator, self.SpeedValue)
        self.CurrentState = PlotDefine.ElementState.Started;
    elseif self.Mode == "Property" then
        self.Curve.Curve = UnityEngine.AnimationCurve()
        for i, key in ipairs(self.Curve.KeyList) do
            self.Curve.Curve:AddKey(key)
        end
        self.CurrentState = PlotDefine.ElementState.Started;
    end
end

-----------------------------------------------------------------------------------------------------------------------------------
AniamtorSpeed.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if self.Mode ~= "Property" or self.Animator == nil then
        return
    end
    local value = self.Curve.Curve:Evaluate(self.CurrentTime)
    self.Cutscene.m_Animator:SetSpeed(self.Animator, value)
end
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorSpeed.EndFunction = function(self)
    if self.Mode == "Event" and self.Animator then
        self.Cutscene.m_Animator:SetSpeed(self.Animator, 1)
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
AniamtorSpeed.DestroyFunction = function(self)
    if self.Animator then
        self.Cutscene.m_Animator:SetSpeed(self.Animator, 1)
        self.CurrentState = PlotDefine.ElementState.Destroyed;
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorSpeed;
