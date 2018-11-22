local print = print
local require = require
local gameevent = require "gameevent"
local network = require "network"

----------------------------------------------------------------------
--CharacterInst
----------------------------------------------------------------------
local CharacterInst = Class:new() 
function CharacterInst:__new(modelname,object)
    self.m_ModelName = modelname
    self.m_Object = object
    self.m_Object.name = "cachedinst_" .. modelname
    self.m_LastUseTime = Time.time
end 

function CharacterInst:release()
    GameObject.Destroy(self.m_Object)
    self.m_Object = nil
end 

----------------------------------------------------------------------
--CharacterInstPool
----------------------------------------------------------------------
local MaxPoolCount = 30 --最大缓存个数，如果多了，就删除掉最早的
local MaxCacheTime = 20 --缓存时间 ，时间到了没有被复用 就删除

local CharacterInstPool = {}

local function Release(i)
    if CharacterInstPool[i] then 
        CharacterInstPool[i]:release()
        table.remove(CharacterInstPool,i)
    end 
end 

local function GetCharacter(modelname) 
    for i,character in ipairs(CharacterInstPool) do 
        if character.m_ModelName == modelname then 
            table.remove(CharacterInstPool,i)
            character.m_Object:SetActive(true)
            return character.m_Object
        end 
    end
    return nil 
end 

local function PutCharacter(modelname,object)
    if modelname ~=nil and object~=nil then 
        if #CharacterInstPool > MaxPoolCount then 
            Release(1)
        end
        object:SetActive(false)
        local managerObject = CharacterManager.GetCharacterManagerObject()
        object.transform:SetParent(managerObject.transform)
        table.insert(CharacterInstPool,CharacterInst:new(modelname,object))
    end 
end 

local function second_update(now)
    local count = #CharacterInstPool
    if count >0 then 
        for i=count,1,-1 do 
            if Time.time - CharacterInstPool[i].m_LastUseTime > MaxCacheTime then 
                Release(i)
            end 
        end
    end 
end 


local function init() 
    gameevent.evt_second_update:add(second_update)
end 

return {
    init = init,
    GetCharacter = GetCharacter,
    PutCharacter = PutCharacter,
}
