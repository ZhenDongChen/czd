--------------------------------------------------------
-- 描述：
-- bag抽象基类
-- 玩家身上装备包、真正背包等都可以抽象为背包类
-- 背包的操作基于槽位，包括玩家身上装备包也基于槽位获取
--------------------------------------------------------

local Bag = Class:new()
-- bagType在csv/bag.xml中定义
function Bag:__new(bagType, unLockedSize, totalSize, items)
    self.m_BagType       = bagType
    self.m_nTotalSize    = totalSize or 1
    self.m_nUnLockedSize = unLockedSize or self.m_nTotalSize
    self.m_Items         = items or { }
end
-- 根据BagPos升序排序
function Sort(item1,item2)
	return (item1.BagPos < item2.BagPos)
end
-- 背包总格子数
function Bag:GetTotalSize()
    return self.m_nTotalSize
end

function Bag:SetTotalSize(size)
    if type(size) ~= "number" or size < 0 then
        logError("func->SetTotalSize,params->size: not 'number' or out of range")
        return false
    end
    self.m_nTotalSize = size
    return true
end
-- 背包开启的格子数
function Bag:GetUnLockedSize()
    return self.m_nUnLockedSize
end

function Bag:GetLockedSize()
    return(self.m_nTotalSize - self.m_nUnLockedSize)
end

function Bag:SetUnLockedSize(size)
    if type(size) ~= "number" or size < 0 or size > self.m_nTotalSize then
        logError("func->SetUnLockedSize,params->size: not 'number' or out of range")
        return false
    end
    self.m_nUnLockedSize = size
    return true
end

function Bag:IsEmpty()
    if getn(self.m_Items) == 0 then
        return true
    else
        return false
    end
end

function Bag:GetType()
    return self.m_BagType
end
-- 若没有找到指定slot则返回nil
function Bag:GetItemBySlot(slot)
    if type(slot) ~= "number" or slot < 1 or slot > self.m_nTotalSize then
        logError("func->GetItemBySlot,params->slot: not 'number' or out of range")
        return nil
    end
    return self.m_Items[slot]
end
-- 若没有找到指定id则返回空表
function Bag:GetItemById(configId)
    if type(configId) ~= "number" then
        logError("func->GetItemById,params->configId: not 'number'")
        return nil
    end
    local items = { }
    for _, item in pairs(self.m_Items) do
        if item:GetConfigId() == configId then
            items[#items + 1] = item
        end
    end

	-- 根据BagPos升序排序
	table.sort(items,Sort)
    return items

end
-- 根据配置文件里的ID获取物品总数(包括绑定和非绑定类型)
function Bag:GetItemNumById(configId)
    if type(configId) ~= "number" then
        logError("func->GetItemNumById,params->slot: not 'number'")
        return 0
    end

    local itemNum = 0
    for _, item in pairs(self.m_Items) do
        if item:GetConfigId() == configId then
            itemNum = itemNum + item:GetNumber()
        end
    end
    return itemNum
end

function Bag:GetItems()
    local items = { }
    for _, item in pairs(self.m_Items) do
        items[#items + 1] = item
    end
	-- 根据BagPos升序排序
	table.sort(items,Sort)
    return items
end

-- 此函数只返回格子不为空的格子数量
-- 不是全部物品的总数量(eg. 支持堆叠的物品)
function Bag:GetItemSlotsNum()
    local items = self:GetItems()
    return #items
end
-- 返回被删除的item,删除指定个数
function Bag:RemoveItem(slot, num)

    local item = self:GetItemBySlot(slot)
    if type(num) ~= "number" or num < 0 or (item and num > item:GetNumber()) then
        logError("func->RemoveItem,params->num: not 'number' or out of range")
        return nil
    end

    if item then
        item:AddNumber(- num)
        if item:GetNumber() <= 0 then
			item:AddNumber(-item:GetNumber())
            self.m_Items[slot] = nil
        end
        return item
    else
        return nil
    end
end
-- 删除指定slot的全部item
function Bag:DeleteItem(slot)

    local item = self:GetItemBySlot(slot)
    if item then
		item:AddNumber(-item:GetNumber())
        self.m_Items[slot] = nil
        return item
    else
        return nil
    end
end
-- 仅删除引用，item数量不变化
function Bag:DeleteItem2(slot)
    local item = self:GetItemBySlot(slot)
    if item then
        self.m_Items[slot] = nil
        return item
    else
        return nil
    end
end
-- 返回true或者false
function Bag:AddItem(slot, item)
    if type(slot) ~= "number" or slot < 1 or slot > self.m_nTotalSize then
        logError("func->AddItem,params->slot: not 'number' or out of range")
        return false
    end
    item.BagType = self.m_BagType
	item.BagPos = slot
    self.m_Items[slot] = item
    return true
end


return Bag
