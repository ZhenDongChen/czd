local Fsm = Class:new()
function Fsm:__new()
  self:reset()
end

function Fsm:reset()
  self:ResetElapsedTime()
end


function Fsm:Start()
  
end

function Fsm:Update()
  self.elapsedTime = self.elapsedTime + Time.deltaTime
end

function Fsm:ResetElapsedTime()
  self.elapsedTime = 0
end


return Fsm