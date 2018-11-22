local TalismanConfig = require("character.talisman.talismanconfig")
local StateType = TalismanConfig.StateType
local SkillManager = require("character.skill.skillmanager")


local TalismanFightState = Class:new()

function TalismanFightState:__new()
    self.m_IsStart = false
    self.m_Controller = nil
    self.m_Ticks = 0
end

function TalismanFightState:Start(controller)
    self.m_IsStart = true
    self.m_IsEnd = false
    self.m_Ticks = 0
    self.m_Controller = controller
    self.m_Controller.m_Model:SetActive(false)
end

function TalismanFightState:IsStart()
    return self.m_IsStart
end

function TalismanFightState:Update(deltaTime)
    self.m_Ticks = self.m_Ticks + deltaTime
    if self.m_Controller.m_PlaySkill == false then
        self:End()
    end
end

function TalismanFightState:End()
    self.m_IsStart = false
    self.m_IsEnd = true
    self.m_Controller.m_Model:SetActive(true)
end

function TalismanFightState:Transitions()
    local result = nil
    if self.m_IsEnd then
        result = StateType.Idle
    else
        result = nil
    end
    return self.m_Controller:GlobalTransitions() or result
end

return TalismanFightState
