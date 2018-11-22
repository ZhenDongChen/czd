local BaseCurve=require"character.curve.basecurve"

local LineCurve=Class:new(BaseCurve)

local HeightData=4
local MaxFlyTime=2

function LineCurve:__new()
    self.m_Coeff=0.5
    self.m_MaxTimeUse = 2
end


function LineCurve:UseTime()
    return self.m_MaxTimeUse
end

function LineCurve:init(params)
    self.m_StartPos = params.startPos
    self.m_EndPos = params.endPos
    self.m_Distance = self:Distance()
end

function  LineCurve:SetUseTime(useTime)
    self.m_MaxTimeUse = useTime
end

function LineCurve:Bezier(currentTime)
    local result = Vector3.zero
    local t = (self.m_Rate * currentTime) / self.m_MaxTimeUse
    if (t <= 1) and (currentTime<MaxFlyTime) then
        result.y =self:Line(self.m_StartPos.y,self.m_EndPos.y,t)
        result.x = self:Line(self.m_StartPos.x, self.m_EndPos.x, t)
        result.z = self:Line(self.m_StartPos.z, self.m_EndPos.z, t)
    else
        result = self.m_EndPos
        self.m_Finished = true
    end
    return result
end

function LineCurve:SetPos(startPos, endPos)
    self.m_StartPos = startPos
    self.m_EndPos = endPos
end

function LineCurve:GetPos(currentTime)
    return self:Bezier(currentTime) 
end

return LineCurve