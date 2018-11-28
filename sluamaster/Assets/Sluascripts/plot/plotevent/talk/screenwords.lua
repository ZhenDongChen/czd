local PlotDefine    = require("plot.base.plotdefine");
local ScreenWords = {};
-----------------------------------------------------------------------------------------------------------------------------------
ScreenWords.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------

ScreenWords.StartFunction = function(self)
    if self.EffectType == "QTE" then
        self.Cutscene.m_UI:ShowQTE({
            effectType  = self.EffectType,
            cutscene    = {},
            index       = self.IndexName,
            position    = self.Position,
            duration    = self.Duration,
        })
    else
        self.Cutscene.m_UI:ShowEffect({
            effectType  = self.EffectType, 
            cutscene    = {}, 
            index       = self.IndexName, 
            position    = self.Position,
            duration    = self.Duration,
        })
    end

    self.CurrentState = PlotDefine.ElementState.Started;
end

-----------------------------------------------------------------------------------------------------------------------------------
ScreenWords.EndFunction = function(self,container,cutscene)
    if self.EffectType == "QTE" then
    --    self.Cutscene.m_UI:HideQTE({
    --        effectType  = self.EffectType,
    --        cutscene    = {},
   --         index       = self.IndexName,
    --        position    = self.Position,
   --         duration    = self.Duration,
   --     })
    else
        self.Cutscene.m_UI:HideEffect({
            effectType  = self.EffectType, 
            cutscene    = {}, 
            index       = self.IndexName, 
            position    = self.Position,
            duration    = self.Duration,
        })
    end
	self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
ScreenWords.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ScreenWords.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return ScreenWords;
