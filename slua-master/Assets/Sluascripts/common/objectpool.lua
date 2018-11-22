local Queue = require "common.queue"

local ObjectPool = Class:new()

function ObjectPool:__new(T,maxnum,createObjectWhenPoolIsFull)
    self.T = T
    self.m_Objects = Queue:new()
    if maxnum then
        self.maxnum = maxnum
    else
        self.maxnum = 5
    end
    if createObjectWhenPoolIsFull~=nil then
        self.createObjectWhenPoolIsFull = createObjectWhenPoolIsFull
    else
        self.createObjectWhenPoolIsFull = true
    end

end


function ObjectPool:GetObject(params)
    if self.m_Objects:Count() >0 then
        local object = self.m_Objects:Pop()
        return object
    end
    if self.createObjectWhenPoolIsFull then
        return self.T:new(params)
    else
        return nil
    end
end

function ObjectPool:PushObject(object)
    if object == nil then
        return false
    end
    if self.m_Objects:Count() < self.maxnum then
        self.m_Objects:Push(object)
        return true
    end
    return false
end

return ObjectPool
