local TransformSync = require("character.transformsync.transformsync")
local DefineEnum    = require "defineenum"

local PlayerTransformSync = Class:new(TransformSync)

function PlayerTransformSync:SyncMoveTo(msg)
    if self.m_Character.m_MountType ~= cfg.equip.RideType.NONE then
        if self.m_Character.m_Mount then
            if self.m_Character:IsRole() then
                if msg.isplayercontrol ~= -1 then
                    --local msgPos=Vector3(msg.position.x,0,msg.position.z)
                    --if mathutils.DistanceOfXoY(self.m_Character.m_Mount:GetPos(), msgPos) < 3 then
                        return
                    --end
                end
            end
            self.m_Character.m_Mount:move(Vector3(msg.target.x,msg.target.y,msg.target.z))
        end
    else
        TransformSync.SyncMoveTo(self, msg)
    end
end

function PlayerTransformSync:SyncStop(msg)
    if self.m_Character.m_MountType ~= cfg.equip.RideType.NONE then
        if self.m_Character.m_Mount then	    
				    self.m_Character.m_Mount.m_TransformSync:SyncStop(msg)			  
		    end
    else
        TransformSync.SyncStop(self, msg)
    end
end



return PlayerTransformSync
