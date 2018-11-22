local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AniamtorAdd = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorAdd.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AniamtorAdd.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)--PlotHelper.GetObject(self.Cutscene,self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)
    if self.Animator == nil then
        self.Animator = self.TargetObject.transform:GetChild(0):AddComponent(Animator)
    end
    if self.Animator then
        PlotHelper.LoadAnimator(self.IndexName,function(ant)
            self.Animator.runtimeAnimatorController = ant
        end)
    end

    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
AniamtorAdd.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorAdd;
