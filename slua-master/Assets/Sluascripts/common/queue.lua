
local linkedlist         = require "common.linkedlist"
local LinkedListNode     = linkedlist.LinkedListNode
local LinkedListIterator = linkedlist.LinkedListIterator
local LinkedList         = linkedlist.LinkedList

local Queue = Class:new(LinkedList)

function Queue:Push(a)
    self:AddFirst(a)
end
 
function Queue:Pop()
    if not self:IsEmpty() then
        return self:RemoveLast().value
    end
    return nil
end


return Queue
 