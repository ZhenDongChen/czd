local StateBase     = require("character.navigation.navigationstate.statebase")
local DefineEnum    = require("defineenum")

local StateEndSet = Class:new(StateBase)

function StateEndSet:__new(controller,endDir)
    StateBase.__new(self,controller,"StateEndSet")
    self.m_Dir = endDir
    
end

function StateEndSet:Start()

    StateBase.Start(self)
    if self.m_Dir then
        self.m_Player:SetEulerAngle(self.m_Dir)
    end
    self.m_Player.WorkMgr:StopWork(DefineEnum.WorkType.Move)
    if self.m_Player.m_Mount then
        self.m_Player.m_Mount:stop()
    end
    self:End()
end

function StateEndSet:Update()
    StateBase.Update(self)
end

function StateEndSet:End()
    StateBase.End(self)
end 

return StateEndSet
