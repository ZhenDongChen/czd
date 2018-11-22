local LinkedListNode = Class:new()
function LinkedListNode:__new(value, prev, next)
    self.value = value
    self.prev = prev
    self.next = next
    self.type = "LinkedListNode"
end


local LinkedListIterator = Class:new()

function LinkedListIterator:__new(a)
    if a.type == "LinkedList" then
        self.pos = a.head.next
    elseif a.type == "LinkedListNode" then
        self.pos = a
    end
end

function LinkedListIterator:IsEnd()
    return not self.pos.value
end

function LinkedListIterator:Cur()
    return self.pos
end

function LinkedListIterator:MoveNext()
    self.pos = self.pos.next
    return self
end

function LinkedListIterator:MovePrev()
    self.pos = self.pos.prev
    return self
end

local LinkedList = Class:new()

function LinkedList:__new()
    self.head = LinkedListNode:new()
    self.head.prev = self.head
    self.head.next = self.head
    self.count = 0
    self.type = "LinkedList"
end


function LinkedList:CreateIterator()
    return LinkedListIterator:new(self)
end



function LinkedList:Insert(it, value)
    local node = LinkedListNode:new(value, it.pos.prev, it.pos)
    it.pos.prev.next = node
    it.pos.prev = node
    self.count = self.count + 1
    return node
end

function LinkedList:Begin()
    return self:CreateIterator()
end

function LinkedList:End()
    return LinkedListIterator:new(self.head)
end


function LinkedList:AddFirst(value)
    return self:Insert(self:Begin(), value)
end

function LinkedList:AddLast(value)
    return self:Insert(self:End(), value)
end

function LinkedList:IsEmpty()
    return self:Begin().pos == self:End().pos
end

function LinkedList:Erase(it)
    assert(not it.value, "you can't erase the head")
    it.pos.prev.next = it.pos.next
    it.pos.next.prev = it.pos.prev
    local curnode = it:Cur()
    it = nil
    self.count = self.count - 1
    return curnode
end

function LinkedList:RemoveFirst()
    assert(not self:IsEmpty(), "Can't PopFront to a Empty list")
    return self:Erase(self:Begin())
end

function LinkedList:RemoveLast()
    assert(not self:IsEmpty(), "Can't PopBack to a Empty list")
    return self:Erase(self:End():MovePrev())
end

function LinkedList:First()
    if not self:IsEmpty() then
        return self.head.next
    end
    return nil
end

function LinkedList:Last()
    if not self:IsEmpty() then
        return self.head.prev
    end
    return nil
end

function LinkedList:Count()
    return self.count
end

function LinkedList:Clear()
    while not self:IsEmpty() do
        self:Erase(self:Begin())
    end
end

function LinkedList:Print()
    local it = self:CreateIterator()
    if type(it:Cur().value) == "table" then
        while not it:IsEnd() do
            if it:Cur().value then
            end
            it:MoveNext()
        end
    else
        local buffer = ""
        while not it:IsEnd() do
            if it:Cur().value then
                buffer = buffer .. tostring(it:Cur().value) .. " "
            end
            it:MoveNext()
        end
    end
end

 return {
 LinkedListNode = LinkedListNode,
 LinkedListIterator =LinkedListIterator,
 LinkedList =LinkedList,
 }
