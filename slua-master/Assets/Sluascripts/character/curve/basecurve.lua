local MathUtils=require"common.mathutils"

local BaseCurve = Class:new()

function BaseCurve:__new()
    self.m_StartPos=Vector3.zero
    self.m_EndPos=Vector3.zero
    self.m_Rate=1
    self.m_Distance=0
    self.m_Finished=false
end

function BaseCurve:Distance()
    return MathUtils.DistanceOfVector3(self.m_StartPos,self.m_EndPos)
end

function BaseCurve:SetRate(rate)
    self.m_Rate=rate
end

function BaseCurve:GetPos(currentTime)
    return Vector3.zero
end

function BaseCurve:Line(start,finish,t)
    return (1-t)*start+t*finish
end

function BaseCurve:Parabola(start,finish,middle,t)
    return (1 - t) * (1 - t) * start +2 * t * (1 - t) * middle +t * t * finish
end

function BaseCurve:SetEndPos(vector)
    self.m_EndPos=vector
end

return BaseCurve
    
