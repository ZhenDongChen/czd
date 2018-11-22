local ConfigManager = require("cfg.configmanager")
local PathNode = require("character.pathfly.info.pathnode")


local PathCurve = Class:new()


function PathCurve:__new(id)
    self.m_Id = id

    self.m_Config = ConfigManager.getConfigData("paths", self.m_Id)
    if self.m_Config == nil then
        logError("找不到飞行路径：", self.m_Id)
        return
    end
   -- printyellow("创建路径",self.m_Config.path.mode)

    self.m_PathConfig = self.m_Config.path

    self.m_Mode = self.m_PathConfig.mode
    self.m_ConstSpeed = self.m_PathConfig.constspeed
    self.m_Speed = self.m_PathConfig.speed
    self.m_PositionVary = self.m_PathConfig.positionvary
    self.m_RotationVary = self.m_PathConfig.rotationvary
    self.m_ScaleVary = self.m_PathConfig.scalevary

    self.m_Nodes = {}

    for i, cfgnode in ipairs(self.m_PathConfig.nodes) do
        self.m_Nodes[i] = PathNode:new(cfgnode)
    end


	self.m_StartPos = nil

	self.m_EndPos = nil

end

function PathCurve:GetFirstPos()
    return self.m_Nodes[1]:GetPos()
end

function PathCurve:GetLastPos()
    return self.m_Nodes[#self.m_Nodes]:GetPos()
end



function PathCurve:GetFirstTime()

end

function PathCurve:GetLastTime()

end

function PathCurve:GetRotation(time)
	if self.m_RotationVary == false then
		return nil
	end
	local rotation = Quaternion.identity
	if time > self.m_Nodes[#self.m_Nodes]:GetTime() then
		rotation = self.m_Nodes[#self.m_Nodes]:GetRotation()
	elseif time < self.m_Nodes[1]:GetTime() then
		rotation = self.m_Nodes[1]:GetRotation()
	else
		local index = 2
		while time > self.m_Nodes[index]:GetTime() do
			index = index + 1;
		end

		local t = ( time - self.m_Nodes[index-1]:GetTime() ) / ( self.m_Nodes[index]:GetTime() - self.m_Nodes[index-1]:GetTime() )

		local rotLast = self.m_Nodes[index-1]:GetRotation()
		local rotNext = self.m_Nodes[index]:GetRotation()
		rotation = Quaternion.Slerp(rotLast,rotNext,t)
	end
	return rotation
end

function PathCurve:IsRotationVary()
	return self.m_RotationVary
end



function PathCurve:SetEndPos(position)
	self.m_EndPos = position
end

function PathCurve:SetStartPos(position)
	self.m_StartPos = position
end


function PathCurve:ReachFirstPos(pos)
	local direction = self:GetFirstPos() - pos
	if direction.magnitude < self.m_Speed * Time.deltaTime then
		return true
	end
	return false
end

function PathCurve:ReachLastPos(pos)
	local direction = self:GetLastPos() - pos
	if direction.magnitude < self.m_Speed * Time.deltaTime then
		return true
	end
	return false
end

function PathCurve:ReachEndPos(pos)
	local direction = self:GetLastPos() - pos
	local dis = direction.magnitude;
	if dis < self.m_Speed * Time.deltaTime then
		return true
	end
	return false
end


function PathCurve:GetPosOfStartPath(time)
	local direction = self:GetFirstPos() - self.m_StartPos
	return self.m_StartPos + direction.normalized * time * self.m_Speed
end

function PathCurve:GetPosOfCurvePath(time)
	if self.m_Mode == "Bessel" then
		return self:PathBezierInterp(time)
	else
		return self:PathLinearInterp(time)
	end
end

function PathCurve:GetPosOfEndPath(time)
	local direction = self.m_EndPos - self:GetLastPos()
	return self:GetLastPos();-- + direction.normalized * time * self.m_Speed
end

function PathCurve:PathLinearInterp(time)
	if time > self.m_Nodes[#self.m_Nodes]:GetTime() then
		return self.m_Nodes[#self.m_Nodes]:GetPos()
	elseif time < self.m_Nodes[1]:GetTime() then
		return self.m_Nodes[1]:GetPos()
	end

	local index = 2
	while time > self.m_Nodes[index]:GetTime() do
		index = index + 2
	end

	local t = ( time - self.m_Nodes[index-1]:GetTime() ) / ( self.m_Nodes[index]:GetTime() - self.m_Nodes[index-1]:GetTime() )
	local direction = self.m_Nodes[index]:GetPos() - self.m_Nodes[index-1]:GetPos()
	return self.m_Nodes[index-1]:GetPos() + direction * t
end

function PathCurve:PathBezierInterp(time)
	if time > self.m_Nodes[#self.m_Nodes]:GetTime() then
		return self.m_Nodes[#self.m_Nodes]:GetPos()
	elseif time < self.m_Nodes[1]:GetTime() then
		return self.m_Nodes[1]:GetPos()
	end

	local index = 2
	while time > self.m_Nodes[index]:GetTime() do
		index = index + 1;
	end

	local t = ( time - self.m_Nodes[index-1]:GetTime() ) / ( self.m_Nodes[index]:GetTime() - self.m_Nodes[index-1]:GetTime() )
	local t2 = t * t
	local t3 = t2 * t
	local ot = 1 - t
	local ot2 = ot * ot
	local ot3 = ot2 * ot

	local P0 = self.m_Nodes[index-1]:GetPos()
	local P1 = self.m_Nodes[index-1]:GetOutTangent()
	local P2 = self.m_Nodes[index]:GetInTangent()
	local P3 = self.m_Nodes[index]:GetPos()

	return P0*ot3 + P1*(3*t*ot2) + P2*(3*t2*ot) + P3*t3
end

return PathCurve
