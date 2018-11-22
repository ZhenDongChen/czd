local StateBase         = require("character.navigation.navigationstate.statebase")
local ConfigManager     = require("cfg.configmanager")
local UIManager         = require("uimanager")
local MapManager        = require("map.mapmanager")
local StateNavToFly = Class:new(StateBase)

function StateNavToFly:__new(controller)
    StateBase.__new(self,controller,"StateNavToFly")
    self.m_CurrentTime = 0
end

function StateNavToFly:Start()
    StateBase.Start(self)
    self.m_CurrentTime = 0
end

function StateNavToFly:Update()
    StateBase.Update(self)
	if self.m_Player:IsPathFlying() == true then
		self.m_CurrentTime = self.m_CurrentTime + Time.deltaTime
	end
	
    if self.m_CurrentTime > 0 and self.m_Player:IsPathFlying() == false then
        self:End()    
    end
end
--[[

]]
function StateNavToFly:End()
    StateBase.End(self)
end

return StateNavToFly
