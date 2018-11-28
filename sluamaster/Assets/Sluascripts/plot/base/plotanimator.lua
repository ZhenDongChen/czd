local SkillManager = require("character.skill.skillmanager")

local PlotAnimator = Class:new()

function PlotAnimator:__new(plotcutscene, config)
    self.m_Cutscene = plotcutscene
end

function PlotAnimator:OnStart()

end

function PlotAnimator:OnEnd()

end

function PlotAnimator:GetAnimator(gameObject)
    local animator = gameObject.transform:GetChild(0):GetComponent("MecanimControl")
    return animator
end

function PlotAnimator:GetStateName(animator, stateName)
    local lowerName = string.lower(stateName)
    local trueName = SkillManager.GetAnimatorStateName(animator.modelName, lowerName, lowerName)
    if trueName == nil or trueName == "" then
        logError("找不到动作配置：" .. tostring(animator.modelName) .. "=>" .. tostring(lowerName))
    end
    if Local.LogModuals.Plot then
        printyellowmodule(Local.LogModuals.Plot,string.format("GetStateName:%s", trueName))
    end
    return trueName
end

function PlotAnimator:PlayBase(animator, stateName)
    local trueName = self:GetStateName(animator,stateName)
    if trueName ~= nil and trueName ~= "" then
        animator:Play(trueName)
    end
end

function PlotAnimator:Play(animator, stateName, layer, normalizedTime)
    local trueName = self:GetStateName(animator,stateName)
    if trueName ~= nil and trueName ~= "" then
        animator:Play(trueName, -1, normalizedTime, false)
    end
end

function PlotAnimator:CrossFadeBase(animator, stateName, transitionDuration, layer, normalizedTime)
    local trueName = self:GetStateName(animator,stateName)
    if trueName ~= nil and trueName ~= "" then
        animator:CrossFade(trueName, transitionDuration)
    end
end

function PlotAnimator:CrossFade(animator, stateName, transitionDuration, layer, normalizedTime)
    local trueName = self:GetStateName(animator,stateName)
    if trueName ~= nil and trueName ~= "" then
        animator:CrossFade(trueName, transitionDuration, normalizedTime, false)
    end
end

function PlotAnimator:SetSpeed(animator, speed)
    animator.speed = speed
end

function PlotAnimator:SetFloat(animator, parameterName, value)
    animator:SetFloat(parameterName, value)
end

function PlotAnimator:SetBoolen(animator, parameterName, value)
    animator:SetBool(parameterName, value)
end

function PlotAnimator:SetInteger(animator, parameterName, value)
    animator:SetInteger(parameterName, value)
end

function PlotAnimator:SetTrigger(animator, parameterName)
    animator:SetInteger(parameterName)
end


return PlotAnimator
