local PlotDefine = require("plot.base.plotdefine");
local SceneManager = require("scenemanager")
local CharacterMove = {};
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.LoadFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.StartFunction= function(self,container,cutscene)
	local go = PlotDirector.Instance:FindGameObject(self.ObjectName);
	if go ~= nil then
		self.Trans = go.transform;
		self.CurrentState = PlotDefine.ElementState.Started;
	else
		self.CurrentState = PlotDefine.ElementState.Ended;
	end
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.LoopFunction = function(self,container,cutscene,deltaTime)
	self.CurrentTime = self.CurrentTime + deltaTime;
	if self.Trans == nil then
		return;
	end
	local ltime = self.CurrentTime;
	if self.CurrentTime > self.Paths[#self.Paths].Time then
		ltime = self.Paths[#self.Paths].Time;
	end
	if ltime < self.Paths[1].Time then
		ltime = self.Paths[1].Time;
	end
	while ltime > self.Paths[self.index].Time do
		self.index = self.index + 1;
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

	local vecPos = P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3;
	local terrianY = SceneManager.GetHeight(vecPos);
	self.Trans.position = Vector3(vecPos.x,terrianY+self.OffsetY,vecPos.z);

	if self.LastPos ~= nil then
		local lookDir = self.Trans.position - self.LastPos;

		if lookDir ~= Vector3.zero then
			self.Trans.rotation = Quaternion.LookRotation(lookDir);
			if self.SetDefRotation == true then
				local eulerAngles = self.Trans.rotation:ToEulerAngles();
				eulerAngles = eulerAngles + self.DefRotation;
				self.Trans.rotation = Quaternion.Euler(eulerAngles.x,eulerAngles.y,eulerAngles.z);
			end
		end
	end
	self.LastPos = self.Trans.position
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.EndFunction  = function(self,container,cutscene)
	if self.SetEndRotation == true and self.EndRotation ~= nil then
		self.Trans.rotation = Quaternion.Euler(self.EndRotation.x,self.EndRotation.y,self.EndRotation.z)
	end
	self.CurrentState = PlotDefine.ElementState.Ended;
end
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.DestroyFunction = nil;
-----------------------------------------------------------------------------------------------------------------------------------
CharacterMove.SampleFunction = function(self,container,cutscene,time)
	self.CurrentTime = time;
	local ltime = self.CurrentTime;
	if  self.CurrentTime > self.Paths[#self.Paths].Time then
		ltime = self.Paths[#self.Paths].Time;
	end
	if ltime < self.Paths[1].Time then
		ltime = self.Paths[1].Time;
	end
	while ltime > self.Paths[self.index].Time do
		self.index = self.index + 1;
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

	local vecPos = P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3;
	local terrianY = SceneManager.GetHeight(vecPos);
	self.Trans.position = Vector3(vecPos.x,terrianY + self.OffsetY,vecPos.z);

	if self.LastPos ~= nil then
		local lookDir = self.Trans.position - self.LastPos;
		self.Trans.rotation = Quaternion.LookRotation(lookDir);
		if self.SetDefRotation == true then
			local eulerAngles = self.Trans.rotation:ToEulerAngles()
			eulerAngles = eulerAngles + self.DefRotation;
			self.Trans.rotation = Quaternion.Euler(eulerAngles.x,eulerAngles.y,eulerAngles.z);
		end
	end
	self.LastPos = self.Trans.position
end
-----------------------------------------------------------------------------------------------------------------------------------
return CharacterMove;
