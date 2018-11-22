local ObjectPool      = require "common.objectpool"
local ConfigManager   = require "cfg.configmanager"
local EffectManager   = require "effect.effectmanager"
local Bomb    = require "character.skill.traceweapon.bomb"
local gameevent       = require "gameevent"


local BombPool = ObjectPool:new(Bomb,10)
local Bombs = {}


local function Remove(id)
    if Bombs[id] then 
        local entity = Bombs[id]
        if not BombPool:PushObject(entity) then
            entity:Release()
        end
        entity:Destroy()
        
        Bombs[id] = nil
    end 
end 


local function RemoveAll()
    for id,_ in pairs(Bombs) do
        Remove(id)
    end
end




local function AddBombs(attacker,  targetId,  skill)
    local action = skill:GetAction(attacker)
    if action and action.BombList and #action.BombList>0 then
        local bombs ={}
        for i,bombData in ipairs(action.BombList) do
            if bombData then
                local bomb = BombPool:GetObject()
                bomb:Init(attacker,targetId,skill,bombData)
                bomb:Start()
                Bombs[bomb.m_Id] = bomb
                table.insert(bombs,bomb.m_Id)
            end 
        end
        return bombs
    end 
    return nil
end 

local function OnBreakSkill(bombs)
    if bombs and #bombs>0 then 
        for _,id in ipairs(bombs) do 
            if Bombs[id] then  
                Bombs[id]:OnBreakSkill()
            end  
        end 
    end 
end 


local function GetCount()
    return getn(Bombs)
end 

local function Update()
    for id,weapon in pairs(Bombs) do
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
    AddBombs                     = AddBombs,
    OnBreakSkill                 = OnBreakSkill,
    GetCount                     = GetCount,
    init                         = init,

}
