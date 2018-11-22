-- local ObjectPool = require "common.objectpool"

local Queue = require "common.queue"

local GameObjectPool = Class:new()

function GameObjectPool:__new(T, maxnum,createObjectWhenPoolIsFull,hangTransform)
    self.m_Template     = T
    self.m_Objects      = Queue:new()
    self.m_MaxCount     = maxnum or 5
    self.m_HangTransform= hangTransform
    if createObjectWhenPoolIsFull~=nil then
        self.createObjectWhenPoolIsFull = createObjectWhenPoolIsFull
    else
        self.createObjectWhenPoolIsFull = true
    end
end


function GameObjectPool:GetObject()
    if self.m_Objects:Count() >0 then
        local object = self.m_Objects:Pop()
        object:SetActive(true)
        -- object.name = "usedObj"
        return object
    end
    if self.createObjectWhenPoolIsFull then
        local object = Util.Copy(self.m_Template)
        object:SetActive(true)
        -- object.name = "usedObj"
        return object
    else
        return nil
    end
end

function GameObjectPool:PushObject(object)
    if object == nil then
        return false
    end
    if self.m_Objects:Count() < self.m_MaxCount then
        object.transform:SetParent(self.m_HangTransform)
        object:SetActive(false)
        -- object.name = "free obj"
        self.m_Objects:Push(object)
        return true
    end
    return false
end

return GameObjectPool
