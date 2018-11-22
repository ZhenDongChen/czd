local StateBase = require("character.navigation.navigationstate.statebase")


local StateDelay = Class:new(StateBase)

function StateDelay:__new(controller, time)
    StateBase.__new(self,controller,"StateDelay")
    self.m_DelayTime = time
    self.m_CurrentTime = 0
end

function StateDelay:Start()
    StateBase.Start(self)
    self.m_CurrentTime = 0
end

function StateDelay:Update()
    StateBase.Update(self)
    self.m_CurrentTime = self.m_CurrentTime + Time.deltaTime
    if self.m_CurrentTime > self.m_DelayTime then
        self:End()
    end
end
function StateDelay:End()
    StateBase.End(self)
end

return StateDelay
