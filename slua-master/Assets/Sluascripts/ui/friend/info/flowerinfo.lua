local ItemManager   = require("item.itemmanager")
local BagManager    = require("character.bagmanager")


local FlowerInfo = Class:new()

function FlowerInfo:__new(flowerId)
	self.m_Id = flowerId
	self.m_Item = ItemManager.CreateItemBaseById(self.m_Id, nil, 1)
	self.m_SendNumber = 0
end

function FlowerInfo:Reduce()
	if self.m_SendNumber >= 1 then
		self.m_SendNumber = self.m_SendNumber - 1
	else
		self.m_SendNumber = 0
	end
	return self.m_SendNumber
end

function FlowerInfo:Add()
	local handleNumber = self:GetHandleNumber()
	if self.m_SendNumber + 1 > handleNumber then
		self.m_SendNumber = handleNumber
	else
		self.m_SendNumber = self.m_SendNumber + 1
	end
	return self.m_SendNumber
end

function FlowerInfo:Set(num)
    if num == nil then
        return self.m_SendNumber
    end
	local handleNumber = self:GetHandleNumber()

	if num > handleNumber then
		self.m_SendNumber = handleNumber
	elseif num < 0 then
		self.m_SendNumber = 0
    else
        self.m_SendNumber = num
	end
    return self.m_SendNumber
end

function FlowerInfo:GetSendNumber()
	return self.m_SendNumber
end

function FlowerInfo:GetTextureName()
	return self.m_Item:GetImage()
end

function FlowerInfo:GetConfigId()
	return self.m_Id
end

function FlowerInfo:GetHandleNumber()
	return BagManager.GetItemNumById(self.m_Id)
end

function FlowerInfo:GetName()
    return self.m_Item:GetName()
end

function FlowerInfo:GetSortValue()
	return self.m_Id
end

function FlowerInfo:GetCharm()
	return self.m_Item.ConfigData.charmdegree
end

function FlowerInfo:GetFriendDegree()
	return self.m_Item.ConfigData.frienddegree
end


return FlowerInfo
