
local StateBase         = require("character.navigation.navigationstate.statebase")
local NavigationHelper  = require("character.navigation.navigationhelper.navigationhelper")
local SceneManager = Game.SceneMgr
local Network           = require("network")

local StateNavToPos = Class:new(StateBase)

function StateNavToPos:__new(controller, targetPos, newStopLength, isAdjustByRideState, lengthCallback)
    StateBase.__new(self,controller,"StateNavToPos")
    self.m_TargetPos = targetPos
	self.m_Path = {}
    self.m_MoveMsg = {}
	self.m_CalculatedPath = false
	self.m_NodeStopLength = NavigationHelper.Config.DefaultStopLength * 0.5
	self.m_EndStopLength = newStopLength or NavigationHelper.Config.DefaultStopLength

    self.m_IsAdjustByRideState = isAdjustByRideState
	self.m_ReceiveCountDown = -1
	self.m_LengthCallback = lengthCallback or nil
    self.m_LastSendTime = 0
	self.TargetBlockPos = Vector2(0,0);
	self.SelfBlockPos = Vector2(0,0);
end

function StateNavToPos:CalculatePathByNavMesh()
	
	NavigationHelper.LogError("开始寻路位置: " .. tostring(self.m_Player:GetPos()))
	self.TargetBlockPos = SceneManager.Instance:GetBlockByPiexl(Vector3(self.m_TargetPos.x * SCALE_XY_FRACTION, self.m_TargetPos.y * SCALE_XY_FRACTION, 0));
	self.SelfBlockPos = SceneManager.Instance:GetBlockByPiexl(Vector3(self.m_Player:GetPos().x * SCALE_XY_FRACTION, self.m_Player:GetPos().y * SCALE_XY_FRACTION, 0));
	
	local result = SceneManager.Instance:PathFind(self.SelfBlockPos,self.TargetBlockPos)
	return result;
end


function StateNavToPos:CalculatePathLocal()

    local result = self:CalculatePathByNavMesh()
	
    if result == false then
        NavigationHelper.LogError("导航计算失败，请检查导航图是否存在 或者 人物是否位于导航图上")
        return nil, nil
    end
	
    local allWayPoints = {}

	local pathlenth = SceneManager.Instance:PathFindListLength();
    for i = 0, pathlenth-1 do
        allWayPoints[i] = SceneManager.Instance:PathFindListIndex(i);
    end

    return allWayPoints

end

function StateNavToPos:GetPathInfo()
    self.m_Path = self:CalculatePathLocal()
    self.m_CalculatedPath = true
    if self.m_Path == nil then
        self:End()
		if self.TargetBlockPos.x ~= self.SelfBlockPos.x or self.TargetBlockPos.y ~= self.SelfBlockPos.y then
			self.m_Controller:StopNavigate()
			return
		end
    end
end


function StateNavToPos:Start()
  --  printyellow("Nav To Pos Start")
    StateBase.Start(self)
    self.m_ListenerId = Network.add_listeners( {
		{   "map.msg.SFindPath",
            function(msg)
                self.m_Path, self.m_Length = self:OnMsgCalculatePathServer(msg)
                self.m_CalculatedPath = true
                if self.m_Path == nil or self.m_Length == nil then
                    self:End()

                    self.m_Controller:StopNavigate()
                    return
                end
            end},
	} ,"statenavtopos")
    self.m_CalculatedPath = false
    self.m_ReceiveCountDown = -1
    self:GetPathInfo()

end
--检测停止距离
function StateNavToPos:CheckStopLength(currentLength)

    if not self.m_Player:IsRiding() then
        if currentLength <= self.m_EndStopLength then
            self:End()
            return true
        end
    else
        local mountStopLength = self.m_EndStopLength + self.m_Player.m_Mount:GetNavStopLength()
        local rideStopLength = (((self.m_IsAdjustByRideState == true) and mountStopLength) or self.m_EndStopLength)
        if currentLength <= rideStopLength then
            self:End()
            return true
        end
    end
    return false
end
--检测一定距离回调
function StateNavToPos:CheckLengthCallback(currentLength)
    if self.m_LengthCallback then
        for i, tb in pairs(self.m_LengthCallback) do
            if tb.callback then
                if currentLength < tb.length then
                    local re = tb.callback()
                    tb.callback = nil
                    return re
                end
            end
        end
    end
end

function StateNavToPos:MsgUpdate()
    if #self.m_MoveMsg > 0 then
        local deltaTime = Time.time - self.m_LastSendTime
        if deltaTime > 0.2 then
            self.m_LastSendTime = Time.time
            self.m_Player.m_TransformSync:SendMove(self.m_MoveMsg[#self.m_MoveMsg])
            self.m_MoveMsg = {}
        end
    end
end

function StateNavToPos:Update()
    StateBase.Update(self)
    if self.m_ReceiveCountDown >= 0 then
        self.m_ReceiveCountDown = self.m_ReceiveCountDown - Time.unscaleDeltaTime
        if self.m_ReceiveCountDown < 0 then
            if self.m_CalculatedPath == false then
                self:GetPathInfo(true)
            end
        end
    end

    if self.m_CalculatedPath == false then
        return
    end

    local currentLength = mathutils.DistanceOfXoY(self.m_Player:GetRefPos(), self.m_TargetPos)
   
    --检测一定距离回调
    if self:CheckLengthCallback(currentLength) == true then
        return
    end
	 --检测停止距离
    if self:CheckStopLength(currentLength) == true then
        return
    end
    --======================================================================================================
    if #self.m_Path == 0 then
		local tempdistance = mathutils.DistanceOfXoY(self.m_Player:GetRefPos(), self.m_TargetPos)
		print(tempdistance)
        if mathutils.DistanceOfXoY(self.m_Player:GetRefPos(), self.m_TargetPos) > self.m_EndStopLength then
			print(self.m_EndStopLength)
            NavigationHelper.LogError("无法到达终点位置: " .. tostring(self.m_TargetPos))
            self.m_Controller:StopNavigate()
            return
        end
    end
    if mathutils.DistanceOfXoY(self.m_Player:GetRefPos(), self.m_Path[1]) <= self.m_NodeStopLength then
        table.remove(self.m_Path, 1)
        if #self.m_Path >= 1 then
            self.m_Player.m_TransformSync:SendMove(self.m_Path[1])
        end
    else
        if (self.m_Player:IsIdle() and not self.m_Player:IsMoving()) or (self.m_Player:IsRiding() and not self.m_Player:IsMoving()) then
            self.m_Player.m_TransformSync:SendMove(self.m_Path[1])
        end
    end
end

function StateNavToPos:End()
    StateBase.End(self)
    if self.m_ListenerId ~= nil then
        Network.remove_listeners(self.m_ListenerId)
    end
end

return StateNavToPos
