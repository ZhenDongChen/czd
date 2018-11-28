local defineenum = require "defineenum"
local WorkType = defineenum.WorkType

local Work = Class:new()
function Work:__new()
    self.type = WorkType.None
    self:reset()
end

function Work:reset()
    self.Character = nil --�����������︳ֵ��
    self.m_Finished = true
end



function Work:GetFinished()
    return self.m_Finished
end

function Work:SetFinished(value)
    if self.m_Finished ~= value then
        self.m_Finished = value
        if value then
            self:OnEnd()
        end
    end
end

function Work:GetWorkType()
    return self.type
end

function Work:Start()
    if Local.LogModuals.WorkManager then 
        printyellow("Work:Start()",utils.getenumname(WorkType,self:GetWorkType()))
    end
    if self:CheckStatement() then
        self:SetFinished(false)
        self:OnStart()
    end
end

function Work:End()
    if Local.LogModuals.WorkManager then 
        printyellow("Work:End()" ,utils.getenumname(WorkType,self:GetWorkType()))
    end
    self:SetFinished(true)
end

function Work:CheckStatement()
    if not self:CanDo() then
        self:SetFinished(true)
        return false
    end
    return true
end

function Work:CanDo()
    if self.Character ==nil then
        return false
    end
    return true
end

function Work:OnStart()
    self.Character.WorkMgr:SetJudgeNeedIdle(false)
    if self:GetWorkType() ~= WorkType.Idle and self:GetWorkType() ~= WorkType.BeAttacked then 
        if self.Character:IsIdle() then
            self.Character.WorkMgr:StopWork(WorkType.Idle)
        end
    end 
end

function Work:OnEnd()
    self:ResetData()
    if self.Character:IsMoving() then 
        self.Character.WorkMgr:SetJudgeNeedIdle(false)
        self.Character.WorkMgr:GetWork(WorkType.Move):PlayRunAnimation() 
    else
        self.Character.WorkMgr:SetJudgeNeedIdle(true)
    end
    
end

function Work:ResetData()

end 

function Work:OnUpdate()

end

function Work:Update()
    if self:GetFinished() then
        return
    end
    local check = self:CheckStatement()
   
    if check then
        self:OnUpdate()
    end
    
end

function Work:Release()
    self:SetFinished(true)
    self:reset()
end

function Work:ResumeWork() 
    
end 

return Work
