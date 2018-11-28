local StateBase         = require("character.navigation.navigationstate.statebase")
local ConfigManager     = require("cfg.configmanager")
local UIManager         = require("uimanager")
local MapManager        = require("map.mapmanager")
local StateNavToMap = Class:new(StateBase)

function StateNavToMap:__new(controller, isDirectEnter, mapId, lineId, portalId)
    StateBase.__new(self,controller,"StateNavToMap")
    self.m_MapId            = mapId
    self.m_LineId           = lineId
    self.m_PortalId         = portalId
    self.m_IsDirectEnter    = isDirectEnter
	self.StartTime 		    = 0;
end

function StateNavToMap:Start()
    StateBase.Start(self)
	self.StartTime 		    = 3;
    if self.m_IsDirectEnter == false then
        MapManager.TransferMapWithoutStop(self.m_PortalId)
    else
        MapManager.EnterMapWithoutStop(self.m_MapId, self.m_LineId)
    end
end

function StateNavToMap:Update()
    StateBase.Update(self)
    if self.m_Player:GetMapId() == self.m_MapId and self.m_Player.m_MapInfo:IsChangingScene() == false then
        self:End()    
	else
		if self.StartTime > 0 then
			self.StartTime = self.StartTime - Time.deltaTime
			if self.StartTime <= 0 then
				self.StartTime = 0;
				if self.m_IsDirectEnter == false then
					MapManager.TransferMapWithoutStop(self.m_PortalId)
				else
					MapManager.EnterMapWithoutStop(self.m_MapId, self.m_LineId)
				end
			end
		end
    end
end
--[[

]]
function StateNavToMap:End()
    StateBase.End(self)
	self.StartTime = 0;
end

return StateNavToMap
