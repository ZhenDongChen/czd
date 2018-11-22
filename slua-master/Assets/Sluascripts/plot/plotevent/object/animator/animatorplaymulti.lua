local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local AniamtorPlayMulti = {};
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorPlayMulti.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

AniamtorPlayMulti.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName)--PlotHelper.GetObject(self.Cutscene,self.ObjectName)
    self.Animator = self.Cutscene.m_Animator:GetAnimator(self.TargetObject)

    if not self.Animator then
        self.CurrentState = PlotDefine.ElementState.Ended
        return;
    end

    if self.Animator and self.States[1] then
        self.Animator:Play(self.States[1].StateName)
        self.LastAnimationStateName = self.States[1].StateName
        table.remove( self.States, 1 )
        if #self.States <= 0 then
            self.CurrentState = PlotDefine.ElementState.Ended;
            return
        end
    end
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Started;
end
------------------------------------------------------------
AniamtorPlayMulti.IsPlaying = function(self,name)
    if name == nil then
        return false
    end
    local playing = LuaHelper.IsPlaying(self.Animator,Animator.StringToHash(name))
    return playing
    -- local statInfo = self.Animator:GetCurrentAnimatorStateInfo(0)
    -- local layerName = self.Animator:GetLayerName(0)

    -- if statInfo.fullPathHash == Animator.StringToHash(string.format("%s.%s",layerName,name)) then
    --     return statInfo.normalizedTime < 1 or statInfo.loop
    -- end
end
AniamtorPlayMulti.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime
    if not self.Animator then
       return
    end
    if self.States[1] == nil then
        self.CurrentState = PlotDefine.ElementState.Ended;
        return
    end
    if not self.Count then
        self.Count = 1
        return
    else
        self.Count = self.Count + 1
    end

    if not self:IsPlaying(self.LastAnimationStateName) then
        if #self.States > 0 then
            self.Animator:Play(self.States[1].StateName)
            self.LastAnimationStateName = self.States[1].StateName
            table.remove( self.States, 1 )
        else
            self.CurrentState = PlotDefine.ElementState.Ended;
        end
    end
end
-----------------------------------------------------------------------------------------------------------------------------------
AniamtorPlayMulti.EndFunction = function(self)
    self.CurrentState = PlotDefine.ElementState.Ended;
end

-----------------------------------------------------------------------------------------------------------------------------------
return AniamtorPlayMulti;
