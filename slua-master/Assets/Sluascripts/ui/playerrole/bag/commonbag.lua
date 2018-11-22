-- 普通背包类定义，区别于玩家装备包等
local Bag = require("ui.playerrole.bag.bag")
local CommonBag = Class:new(Bag)


function CommonBag:__new(bagType, unLockedSize, totalSize, items)
	Bag.__new(self,bagType, unLockedSize, totalSize, items)
    self.m_Ids = { }
end
-- 重写基类bag的AddItem
-- 加入bNewAdded状态变量
-- 返回true或者false
function CommonBag:AddItem(slot, item)
    if type(slot) ~= "number" or slot < 1 or slot > self.m_nTotalSize then
        logError("CommonBag:func->AddItem,params->slot: not 'number' or out of range")
        return false
    end
    -- m_Ids用存储唯一Id,区分New状态(整理功能)
    if self.m_Ids[item:GetId()] then
        item.bNewAdded = false
    else
        item.bNewAdded = true
        self.m_Ids[item:GetId()] = true
    end
    item.BagType = self.m_BagType
	item.BagPos = slot
    self.m_Items[slot] = item
    return true
end
-- 增加唯一id(注意：不是配置id)，处理New状态
function CommonBag:AddId(id)
	self.m_Ids[id] = true
end
-- 清理所有id
function CommonBag:ClearIds()
	self.m_Ids = { }
end

function CommonBag:ResetNewStatus()
    local items = self:GetItems()
    for _,item in pairs(items) do
        item.bNewAdded = false
    end
end

return CommonBag