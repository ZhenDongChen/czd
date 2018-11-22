local network        = require "network"

local TransformMsgSender = Class:new()


function TransformMsgSender:__new(transformsync)
    self.m_Character            = transformsync.m_Character

    self.m_LastMoveTime         = 0
    self.m_LastMoveDir          = Vector3.forward
    self.m_LastMovePos          = Vector3(0,0,0)
    self.m_MoveMessageCache     = {}
end

function TransformMsgSender:SendMoveMsgToServer(rolePos, targetPos)
    self.m_LastMoveTime = Time.time
    self.m_LastMovePos = targetPos
    self.m_LastMoveDir = targetPos - rolePos
	local msgpos = Vector2(rolePos.x, rolePos.y);
	local msgtarget = Vector2(targetPos.x, targetPos.y);
    if #self.m_MoveMessageCache == 0 then
        local re = map.msg.CMove({position = msgpos, target = msgtarget})
        network.send(re)
    else
        local re = map.msg.CMove({position = msgpos, target = msgtarget})
        network.send(re)
        self.m_MoveMessageCache = {}
    end
end

function TransformMsgSender:TrySendMove(rolePos, targetPos)
    local dir = targetPos - rolePos
    local deltaAngle = math.abs(mathutils.AngleOfXoY(dir, self.m_LastMoveDir))
    if Time.time - self.m_LastMoveTime < 0.8
            and mathutils.DistanceOfXoY(self.m_LastMovePos, targetPos) < 3
            and deltaAngle < 0.1 then
        table.insert(self.m_MoveMessageCache, { position = rolePos, target = targetPos })
    else
        self:SendMoveMsgToServer(rolePos, targetPos)
    end
end

function TransformMsgSender:MoveMsgUpdate()
    if #self.m_MoveMessageCache > 0 then
        if self.m_Character:IsMoving() and Time.time -self.m_LastMoveTime > 0.8 then
            local cacheMsg = self.m_MoveMessageCache[#self.m_MoveMessageCache]
            self:SendMoveMsgToServer(cacheMsg.position, cacheMsg.target)
        elseif (not self.m_Character:IsMoving()) and Time.time -self.m_LastMoveTime > 0.2 then
            local cacheMsg = self.m_MoveMessageCache[#self.m_MoveMessageCache]
            self:SendMoveMsgToServer(cacheMsg.position, cacheMsg.target)
        end
    end
end

function TransformMsgSender:TrySendStop(rolePos, roleDir)
    if #self.m_MoveMessageCache > 0 then
        local cacheMsg = self.m_MoveMessageCache[#self.m_MoveMessageCache]
        local re = map.msg.CMove({position = cacheMsg.position, target = rolePos})
        network.send(re)
        self.m_MoveMessageCache = {}
    else
        local re = map.msg.CStop( { position = rolePos, orient = roleDir })
        network.send(re)
    end
end

return TransformMsgSender