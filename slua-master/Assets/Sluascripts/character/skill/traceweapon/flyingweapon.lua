local FlyingWeaponManager
local TraceObject = require "character.skill.traceweapon.traceobject"


------------------------------------------------------------------------------
--FlyingWeapon
------------------------------------------------------------------------------
local FlyingWeapon = Class:new(TraceObject)


function FlyingWeapon:__new()
    TraceObject.__new(self)
    
    FlyingWeaponManager = require "character.skill.traceweapon.flyingweaponmanager"
    
end

function FlyingWeapon:reset()
    TraceObject.reset(self)
end 
    
function FlyingWeapon:Init(attacker,targetId,skill,flyWeaponData)
    TraceObject.InitData(self,attacker,targetId,skill,flyWeaponData)
end 

function FlyingWeapon:GetTraceObjType()
    return self.TraceType.FlyWeapon
end


function FlyingWeapon:CanAttack(character)
    if character == nil then
        return false
    end 
    if self.m_Attacker~=nil and self.m_Attacker.m_Id == character.m_Id then 
        return false
    end 
    for _,beattacker in pairs(self.m_BeAttackerList) do
        if beattacker.m_Id == character.m_Id then
            return false
        end 
    end 
    table.insert(self.m_BeAttackerList,character)
    return true
end

function FlyingWeapon:InitBornTransform(effectobj)
    TraceObject.InitBornTransform(self,effectobj)
end 
function FlyingWeapon:Release()
    TraceObject.Release(self)
end


function FlyingWeapon:OnAttack()
    if not self.m_Data.passbody and 
        self.m_CurrentState ~= self.FsmState.None  then 
        self:SetState(TraceObject.FsmState.Dead)
    end 
end




return FlyingWeapon
