local basecurve=require"character.curve.basecurve"


local CublicBezierCurve=Class:new(basecurve)

function CublicBezierCurve:__new()
    self.m_SecondControlVec=Vector3.zero
    self.m_ThirdControlVec = Vector3.zero
    self.m_Matrix=UnityEngine.Matrix4x4.zero
    self.m_UseTime=10
end

function CublicBezierCurve:CreateMatrix()
    self.m_Matrix:SetRow(0,Vector4(-1,3,-3,1))
    self.m_Matrix:SetRow(1, Vector4(3, -6, 3, 0))
    self.m_Matrix:SetRow(2, Vector4(-3, 3, 0, 0))
    self.m_Matrix:SetRow(3, Vector4(1, 0, 0, 0))
end

function CublicBezierCurve:init(params)
    self:CreateMatrix()
    self.m_StartPos=params.controlVec[1]
    self.m_SecondControlVec=params.controlVec[2]
    self.m_ThirdControlVec = params.controlVec[3]
    self.m_EndPos=params.controlVec[4]
    self.m_Rate=params.rate
    self.m_Distance=self:Distance()   
end

function CublicBezierCurve:Cublic(t)
    return (self.m_StartPos * (math.pow(1 - t, 3))) + self.m_SecondControlVec * (3 * t * math.pow(1 - t, 2)) + self.m_ThirdControlVec * (3 * t * t * (1 - t)) + self.m_EndPos * math.pow(t, 3)
end
      
function CublicBezierCurve:Bezier(currentTime)
    local result=Vector3.zero
    local t=self.m_Rate*currentTime/self.m_UseTime
    if t>=1 then
        result=self.m_EndPos
        self.m_Finished=true
    else
        result=self:Cublic(t)
    end
    return result
end

function CublicBezierCurve:GetPos(currentTime)
    return self:Bezier(currentTime)
end

return CublicBezierCurve