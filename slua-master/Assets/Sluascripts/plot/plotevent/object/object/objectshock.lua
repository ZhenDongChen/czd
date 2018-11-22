local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("Plot.plothelper")

local ObjectShock = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.StartFunction = function(self)
    self.CurrentTime = 0;
        
    if self.ObjectName then
        self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName) --PlotHelper.GetObject(self.Cutscene,self.ObjectName)
    end
    
    self.oldPos = self.TargetObject.transform.localPosition;   
    
    
    self.Vec = Vector3(0,0,0)
    self.Vec.x = ((self.Xallow) and 1) or 0
    self.Vec.y = ((self.Yallow) and 1) or 0
    self.Vec.z = ((self.Zallow) and 1) or 0
    self.CurrentState = PlotDefine.ElementState.Started;
    
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.LoopFunction = function(self,deltaTime)
    self.CurrentTime = self.CurrentTime + deltaTime;
    local amx, amy, amz;
    if Mode == "Exp" then 
        amx = self.Amplify.x * (math.exp(-self.Beta.x * self.CurrentTime));
        amy = self.Amplify.y * (math.exp(-self.Beta.y * self.CurrentTime));
        amz = self.Amplify.z * (math.exp(-self.Beta.z * self.CurrentTime));
    else
        amx = self.Amplify.x * (1 - self.Beta.x * self.CurrentTime / self.Duration);
        amy = self.Amplify.y * (1 - self.Beta.y * self.CurrentTime / self.Duration);
        amz = self.Amplify.z * (1 - self.Beta.z * self.CurrentTime / self.Duration);
    end
    local vx = self.Vec.x * math.sin(self.Omega.x * self.CurrentTime - self.Delay.x);
    local vy = self.Vec.y * math.sin(self.Omega.y * self.CurrentTime - self.Delay.y);
    local vz = self.Vec.z * math.sin(self.Omega.z * self.CurrentTime - self.Delay.z);
    if self.TargetObject then
        self.TargetObject.transform.localPosition = self.oldPos + Vector3(vx * amx, vy * amy, vz * amz);
    end     
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.EndFunction = function(self)
    if self.TargetObject then
        self.TargetObject.transform.localPosition=self.oldPos;
    end
    self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ObjectShock.SampleFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
return ObjectShock;