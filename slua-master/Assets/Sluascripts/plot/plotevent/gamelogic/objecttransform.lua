local PlotDefine = require("plot.base.plotdefine");

local ObjectTransform = {};
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.StartFunction = function(self,container,cutscene)
	local go = PlotDirector.Instance:FindGameObject(self.ObjectName);
	if go ~= nil then
		self.Trans = go.transform;
		self.CurrentState = PlotDefine.ElementState.Started;
	else
		self.CurrentState = PlotDefine.ElementState.Ended;
	end
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.LoopFunction = function(self,container,cutscene,deltaTime)
	self.CurrentTime = self.CurrentTime + deltaTime;
	if self.Trans==nil then
		return;
	end
	local ltime = self.CurrentTime;
	if  self.CurrentTime > self.Paths[#self.Paths].Time then
		ltime = self.Paths[#self.Paths].Time;
	end
	if ltime < self.Paths[1].Time then
		ltime = self.Paths[1].Time;
	end
	while ltime > self.Paths[self.index].Time do
		self.index=self.index+1;
	end
	local t = (ltime-self.Paths[self.index-1].Time)/(self.Paths[self.index].Time-self.Paths[self.index-1].Time);

	local t2  = t*t;
	local t3  = t2*t;
	local ot  = 1-t;
	local ot2 = ot*ot;
	local ot3 = ot2*ot;

	local P0  = self.Paths[self.index-1].Pos;
	local P1  = self.Paths[self.index-1].Out;
	local P2  = self.Paths[self.index].In;
	local P3  = self.Paths[self.index].Pos;
	
	if self.ScaleVary==true then
		self.Trans.localScale=Vector3.Lerp(self.Paths[self.index-1].Scl,self.Paths[self.index].Scl,t);
	end
	
	if self.PositionVary == true then
		self.Trans.position=P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3;
	end
	if self.RotationVary == true then
		local rotLast = Quaternion.Euler(self.Paths[self.index-1].Rot.x,self.Paths[self.index-1].Rot.y,self.Paths[self.index-1].Rot.z)
		local rotNext = Quaternion.Euler(self.Paths[self.index].Rot.x,self.Paths[self.index].Rot.y,self.Paths[self.index].Rot.z)
		self.Trans.rotation = Quaternion.Slerp(rotLast,rotNext,t)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.EndFunction  = function(self,container,cutscene)
	self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
ObjectTransform.SampleFunction = function(self,container,cutscene,time)
	self.CurrentTime = time;
	local ltime = self.CurrentTime;
	if  self.CurrentTime > self.Paths[#self.Paths].Time then
		ltime = self.Paths[#self.Paths].Time;
	end
	if ltime < self.Paths[1].Time then
		ltime = self.Paths[1].Time;
	end
	while ltime > self.Paths[self.index].Time do
		self.index=self.index+1;
	end
	local t = (ltime-self.Paths[self.index-1].Time)/(self.Paths[self.index].Time-self.Paths[self.index-1].Time);

	local t2  = t*t;
	local t3  = t2*t;
	local ot  = 1-t;
	local ot2 = ot*ot;
	local ot3 = ot2*ot;

	local P0  = self.Paths[self.index-1].Pos;
	local P1  = self.Paths[self.index-1].Out;
	local P2  = self.Paths[self.index].In;
	local P3  = self.Paths[self.index].Pos;
	
	if self.ScaleVary==true then
		self.Trans.localScale=Vector3.Lerp(self.Paths[self.index-1].Scl,self.Paths[self.index].Scl,t);
	end
	
	if self.PositionVary == true then
		self.Trans.position=P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3;
	end
	if self.RotationVary == true then
		local rotLast = Quaternion.Euler(self.Paths[self.index-1].Rot.x,self.Paths[self.index-1].Rot.y,self.Paths[self.index-1].Rot.z)
		local rotNext = Quaternion.Euler(self.Paths[self.index].Rot.x,self.Paths[self.index].Rot.y,self.Paths[self.index].Rot.z)
		self.Trans.rotation = Quaternion.Slerp(rotLast,rotNext,t)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------
return ObjectTransform;
