local TransformSync = require("character.transformsync.transformsync")
local DefineEnum    = require "defineenum"
local TransformMsgSender = require("character.transformsync.transformmsgsender")
local mathutils = require("common.mathutils")

local MountTransformSync = Class:new(TransformSync)

function MountTransformSync:__new(character)
    TransformSync.__new(self, character)
    self.m_MsgSender = TransformMsgSender:new(self)
end

function MountTransformSync:SendMove(targetPos)
    local rolePos = self.m_Character:GetPos()
    self.m_MsgSender:TrySendMove(rolePos, targetPos)
end
function MountTransformSync:SendStop()
    local rolePos = self.m_Character:GetPos()
    local roleDir = self.m_Character:GetEulerAngle()
    ---local roleDir = self.m_Character:GetForward() -- (((self.m_Character.m_Object ~= nil) and self.m_Character.m_Object.transform.forward) or Vector3(0,0,1))
    self:SyncStop({position = rolePos, orient = roleDir, isplayercontrol=-1 })
    self.m_MsgSender:TrySendStop(rolePos, roleDir)
end

function MountTransformSync:SyncStop(msg)
    local msgPos = Vector3(msg.position.x,msg.position.y,msg.position.z)
    local msgOrient = msg.orient--Vector3(msg.orient.x,0,msg.orient.z)
	
    -- if not self.m_Character:IsRole() then
    --     printyellow(string.format( "[%s] => %s",tostring(Time.time), tostring(msg)))
    -- end
    -- Game.CharacterTransformSync.Instance:AddStopMessage(self.m_Character.m_Id, Time.time, msgPos, msgOrient)

    local deviation = mathutils.DistanceOfXoY(self.m_Character:GetPos(), msgPos)
    local dif=4.5
    local baseSpeed=7.5
    if self.m_Character.m_MountState == DefineEnum.MountType.Ride then
        dif=(self.m_Character.m_Attributes[cfg.fight.AttrId.MOVE_SPEED]/baseSpeed)*dif
        if deviation > dif then
            self.m_Character:SetPos(msgPos)
            if msg.isplayercontrol ~= -1 then
                self.m_Character:SetEulerAngle(msgOrient)
            end
        end
        self.m_Character.WorkMgr:StopWork(DefineEnum.WorkType.Move)
    --elseif self.m_Character.m_MountState == DefineEnum.MountType.Fly then
		--[[
        dif=(self.m_Character.m_FlySpeed/baseSpeed)*dif
        if deviation > dif then
            local SceneMgr=require"scenemanager"
            if (SceneMgr.GetHeight1(msgPos)>cfg.map.Scene.HEIGHTMAP_MIN) and msgPos.y>SceneMgr.GetHeight1(msgPos) then
                self.m_Character.m_OffsetY=(msgPos.y-SceneMgr.GetHeight1(msgPos))
            end
            self.m_Character:SetPos(msgPos)
            if msg.isplayercontrol ~= -1 then
                self.m_Character:SetRotation(msgOrient)
            end
        end
        self.m_Character.WorkMgr:StopWork(DefineEnum.WorkType.Fly)
		]]
    end               
end

return MountTransformSync