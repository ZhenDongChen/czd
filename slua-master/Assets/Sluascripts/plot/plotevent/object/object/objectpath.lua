local PlotDefine = require("plot.base.plotdefine");
local PlotHelper = require("plot.plothelper")

local ObjectPath = { }

ObjectPath.LoadFunction = function(self)
    self.CurrentTime = 0
    self.CurrentState = PlotDefine.ElementState.Loaded
end

ObjectPath.SetPath = function(self)
	if self.TargetObject == nil then
		return
	end
	local ltime = self.CurrentTime;
    self.index = 2

	if  self.CurrentTime > self.PathList[#self.PathList].NodeTime then
		ltime = self.PathList[#self.PathList].NodeTime;
	end

	if ltime < self.PathList[1].NodeTime then
		ltime = self.PathList[1].NodeTime;
	end

	while ltime > self.PathList[self.index].NodeTime do
		self.index=self.index+1;
	end

	local t = (ltime-self.PathList[self.index-1].NodeTime)/(self.PathList[self.index].NodeTime-self.PathList[self.index-1].NodeTime);

	local t2  = t * t;
	local t3  = t2 * t;
	local ot  = 1 - t;
	local ot2 = ot * ot;
	local ot3 = ot2 * ot;

	local P0  = self.PathList[self.index-1].Position;
	local P1  = self.PathList[self.index-1].OutTangent;
	local P2  = self.PathList[self.index].InTangent;
	local P3  = self.PathList[self.index].Position;

	local oldPosition =self.TargetObject.transform.position

	if self.ScaleVary==true then
		self.TargetObject.transform.localScale=Vector3.Lerp(self.PathList[self.index-1].LocalScale,self.PathList[self.index].LocalScale,t);
	end
	
	if self.PositionVary == true then
        if self.PathMode and self.PathMode == "Linear" then
            self.TargetObject.transform.position = Vector3.Lerp(self.PathList[self.index-1].Position,self.PathList[self.index].Position,t);
        else
            self.TargetObject.transform.position=P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3;
        end
	end
	if self.RotationVary == true then
		if self.TangentMode == true then
			if self.CurrentTime > 0 then
				self.TargetObject.transform.rotation = Quaternion.LookRotation(self.TargetObject.transform.position - oldPosition, Vector3.up);
			end
		else
			local rotLast = Quaternion.Euler(self.PathList[self.index-1].Rotation.x,self.PathList[self.index-1].Rotation.y,self.PathList[self.index-1].Rotation.z)
			local rotNext = Quaternion.Euler(self.PathList[self.index].Rotation.x,self.PathList[self.index].Rotation.y,self.PathList[self.index].Rotation.z)
			self.TargetObject.transform.rotation = Quaternion.Slerp(rotLast,rotNext,t)
		end
	end
    if self.OnGround then
        PlotHelper.SetObjectOnGround(self.TargetObject,self.OffSetY)
    end

end


ObjectPath.StartFunction = function(self)
    self.TargetObject = self.Cutscene.m_Pool:Get(self.ObjectName) --PlotHelper.GetObject(self.Cutscene, self.ObjectName)
    self.CurrentState = PlotDefine.ElementState.Started
	--printyellow("self.TargetObject => ",self.TargetObject)
end
ObjectPath.EndFunction = function(self)
	self.CurrentTime = self.Duration
    self:SetPath()
    self.CurrentState = PlotDefine.ElementState.Ended
end

ObjectPath.LoopFunction = function(self,deltaTime)
	self.CurrentTime = self.CurrentTime + deltaTime;
	if self.TargetObject==nil then
		return;
	end
	self:SetPath()
end

return ObjectPath
