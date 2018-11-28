local ObjectPool      = require "common.objectpool"
local ConfigManager   = require "cfg.configmanager"
local EffectManager   = require "effect.effectmanager"
local FlyingWeapon    = require "character.skill.traceweapon.flyingweapon"
local gameevent       = require "gameevent"


local FlyingWeaponPool = ObjectPool:new(FlyingWeapon,10)
local FlyingWeapons = {}


local function Remove(id)
    if FlyingWeapons[id] then 
        local entity = FlyingWeapons[id]
        if not FlyingWeaponPool:PushObject(entity) then
            entity:Release()
        end
        entity:Destroy()
        
        FlyingWeapons[id] = nil
    end 
end 


local function RemoveAll()
    for id,_ in pairs(FlyingWeapons) do
        Remove(id)
    end
end




local function AddWeaponObjects(attacker,  targetId,  skill)
    
    local action = skill:GetAction(attacker)
    if action and action.FlyWeaponList and #action.FlyWeaponList>0 then
        local flyWeapons ={}
        for i,flyWeaponData in ipairs(action.FlyWeaponList) do
            if flyWeaponData then
                local flyweapon = FlyingWeaponPool:GetObject()
                flyweapon:Init(attacker,targetId,skill,flyWeaponData)
                flyweapon:Start()
                FlyingWeapons[flyweapon.m_Id] = flyweapon
                table.insert(flyWeapons,flyweapon.m_Id)
            end 
        end
        return flyWeapons
    end 
    return nil
end 

local function OnBreakSkill(flyWeapons)
    if flyWeapons and #flyWeapons>0 then 
        for _,id in ipairs(flyWeapons) do 
            if FlyingWeapons[id] then  
                FlyingWeapons[id]:OnBreakSkill()
            end  
        end 
    end 
end 

local function OnAttack(attackerid,skillid,objectid)
    if FlyingWeapons[id] then  
        FlyingWeapons[id]:OnAttack()
    end   
    for id,flyWeapon in pairs(FlyingWeapons) do
        if flyWeapon:IsAttacking() and 
           flyWeapon.m_Attacker and 
           flyWeapon.m_Attacker.m_Id == attackerid and 
           flyWeapon.m_Skill.skillid == skillid and 
           flyWeapon.m_Data.id == objectid then 
           flyWeapon:OnAttack()
           break
        end 
    end
end 



local function GetCount()
    return getn(FlyingWeapons)
end 

local function Update()
    for id,weapon in pairs(FlyingWeapons) do
        if weapon:IsDead() then 
            Remove(id)
        else 
            weapon:Update()
        end 
    end 
end 







local function init()
    gameevent.evt_update:add(Update)
end



return 
{
    RemoveAll                    = RemoveAll,
    AddWeaponObjects             = AddWeaponObjects,
    OnAttack                     = OnAttack,
    OnBreakSkill                 = OnBreakSkill,
    GetCount                     = GetCount,
    init                         = init,

}
