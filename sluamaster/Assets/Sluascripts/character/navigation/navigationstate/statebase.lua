
local StateBase = Class:new()

function StateBase:__new(controller,type)
    self.m_State        = "Create"
    self.m_Controller   = controller
    self.m_Type         = type or "StateBase"
    self.m_Player       = controller.m_Player
end

function StateBase:Start()
    self.m_State = "Start"

end

function StateBase:Update()

end

function StateBase:End()
    self.m_State = "End"
    
end
function StateBase:IsEnd()
    return (((self.m_State == "End") and true) or false)
end

return StateBase