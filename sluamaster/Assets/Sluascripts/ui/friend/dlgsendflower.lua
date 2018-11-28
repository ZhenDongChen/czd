local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local FriendManager = require("ui.friend.friendmanager")
local EventHelper 	= UIEventListenerHelper
local ConfigManager = require("cfg.configmanager")
local ItemManager   = require("item.itemmanager")
local FlowerInfo	= require("ui.friend.info.flowerinfo")
local NetWork		= require("network")
local ColorUtil	= require("common.colorutil")
------------------------------------------------------------------------------------------------------
local name, gameObject, fields

local NPCFlowerIds = {}
local PlayerFlowerIds = {}
local FlowerInfos = {}
local linstenerId = nil

local function SendFlowerTo(targetType, targetId, flowers)
	local flist = {}
	local totalSendNum = 0
	for i, flower in ipairs(flowers) do
		flist[i] = { FlowerId = flower:GetConfigId() , FlowerNum = flower:GetSendNumber() }
		totalSendNum = totalSendNum + flower:GetSendNumber()
	end
	if totalSendNum == 0 then
		return false
	end
	local sendTargetType = nil
	if targetType == cfg.item.FlowerType.NPC then
		sendTargetType = "Idol"
	else
		sendTargetType = "Friend"
	end
	FriendManager.SendFlower(sendTargetType,targetId,flist)
	return true
end

local function GetTargetFlowers(targetType)
	local flowerIdList = {}
	local flowers = {}

	if targetType == cfg.item.FlowerType.NPC then
		flowerIdList = NPCFlowerIds
	else
		flowerIdList = PlayerFlowerIds
	end

	for i, flowerId in ipairs(flowerIdList) do
		flowers[i] = FlowerInfo:new(flowerId)
	end

	utils.table_sort( flowers, function(flwA, flwB)
		if flwA:GetSortValue() < flwB:GetSortValue() then
			return true
		end
		return false
	end)

	return flowers
end

local function UpdateFlowerNumber(uiItem, flower)
	local inputSend = uiItem.Controls["UIInput_SendFlowerNum"]
	local inputNum = tonumber(inputSend.value)
	if inputNum ~= flower:GetSendNumber() then
		flower:Set(inputNum)
		UIManager.refresh(name)
	end
end

local function RefreshFlowerNumber(uiItem, flower)
	local labelTotal = uiItem.Controls["UILabel_TotalFlowerNum"]
	local inputSend = uiItem.Controls["UIInput_SendFlowerNum"]
	uiItem.Controls["UILabel_ShopItemUnitPrice"].text = flower.m_Item.ConfigData.prize
	--local ShopManager    = require("shopmanager")
	--local shopItems = ShopManager.GetShopItems(cfg.mall.MallType.DIAMOND_MALL, "日常")
    --
	--for _, item in pairs(shopItems) do
	--	if item.itemid.itemid == flower.m_Item.itemid then
	--		local currency = ItemManager.GetCurrencyData(item.cost)
	--		uiItem.Controls["UISprite_Currency_Icon"].spriteName = currency:GetIconName()
	--		uiItem:SetText("UILabel_ShopItemUnitPrice", currency:GetNumber())
	--		uiItem.Controls["UILabel_ShopItemUnitPrice"].text = flower.m_Item.ConfigData.prize
	--	end
	--end



	--printyellow("inputSend",inputSend)
	if labelTotal then
		labelTotal.text =  tostring(flower:GetHandleNumber())
	end
	--string.format(LocalString.SendFlower_Num,)
	if inputSend then
		inputSend.value = flower:GetSendNumber()
	end
end

local function ShowFlowerItem(uiItem, flower)

	local labelName 	= uiItem.Controls["UILabel_FlowerName"]
	local texture 		= uiItem.Controls["UITexture_FlowerType"]
	local buttonBuy 	= uiItem.Controls["UIButton_BuyFlower"]
	local buttonReduce 	= uiItem.Controls["UIButton_Reduce"]
	local buttonAdd 	= uiItem.Controls["UIButton_Add"]
	local inputSend 	= uiItem.Controls["UIInput_SendFlowerNum"]
	local spriteQuality = uiItem.Controls["UISprite_Quility"]
	if texture then
		texture:SetIconTexture(flower:GetTextureName())
	end
	if labelName then
		labelName.text = flower:GetName()
	end
	if spriteQuality and flower.m_Item then
		spriteQuality.spriteName = ColorUtil.GetQualitySprite(flower.m_Item:GetQuality())
	end
	if buttonBuy then
		EventHelper.SetClick(buttonBuy, function()
			ItemManager.GetSource(flower:GetConfigId(), name)

		end)
	end
	if buttonReduce then
		EventHelper.SetClick(buttonReduce, function()
			flower:Reduce()
			inputSend.value = flower:GetSendNumber()
			UIManager.refresh(name)
		end)
	end
	if buttonAdd then
		EventHelper.SetClick(buttonAdd, function()
			flower:Add()
			inputSend.value = flower:GetSendNumber()
			UIManager.refresh(name)
		end)
	end
end

local function refresh(params)
	-- printyellow("flower refresh")
	for i = 1, #FlowerInfos do
		local uiItem = fields.UIList_Flowers:GetItemByIndex(i-1)
		local flower = FlowerInfos[i]
		RefreshFlowerNumber(uiItem, flower)
	end
end

local function destroy()

end

local function OnMsgItemChange()
	if UIManager.isshow(name) then
		local ftimer = FrameTimer.New(function()
			UIManager.refresh(name)
		end, 1, 1)
		ftimer:Start()
	end
end

local function show(params)
	EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide(name)
    end)
	EventHelper.SetClick(fields.UIButton_Cancel, function()
		UIManager.hide(name)
	end)
	FlowerInfos = GetTargetFlowers(params.targetType)
	--printyellow("#====", #FlowerInfos)
	UIHelper.ResetItemNumberOfUIList(fields.UIList_Flowers, #FlowerInfos)
	for i = 1, #FlowerInfos do
		local uiItem = fields.UIList_Flowers:GetItemByIndex(i-1)
		local flower = FlowerInfos[i]
		ShowFlowerItem(uiItem, flower)
	end
	EventHelper.SetClick(fields.UIButton_Sure, function()
		local re = SendFlowerTo(params.targetType, params.targetId, FlowerInfos)
		if re == true then
			UIManager.hide(name)
		end
	end)

	linstenerId = NetWork.add_listeners({
        {"lx.gs.cmd.msg.SCommand", OnMsgItemChange},
    })
end

local function hide()
	if linstenerId then
		-- printyellow("linstenerId", linstenerId)
		NetWork.remove_listeners(linstenerId)
	end
end

local function update()
	for i = 1, #FlowerInfos do
		local uiItem = fields.UIList_Flowers:GetItemByIndex(i-1)
		local flower = FlowerInfos[i]
		UpdateFlowerNumber(uiItem, flower)
	end
end

local function LoadFlowerItemsConfig()
	NPCFlowerIds = {}
	PlayerFlowerIds = {}
	local items = ConfigManager.getConfig("itembasic")
	for i,item in pairs(items) do
		if item.itemtype == cfg.item.EItemType.FLOWER then
			if item.flowertype == cfg.item.FlowerType.NPC then
				table.insert(NPCFlowerIds,item.id)
			elseif item.flowertype == cfg.item.FlowerType.PLAYER then
				table.insert(PlayerFlowerIds,item.id)
			end
		end
	end
end

local function init(params)
	name, gameObject, fields = unpack(params)
	LoadFlowerItemsConfig()
end

local function uishowtype()
    return UIShowType.Refresh
end
--[[
	lx.gs.cmd.msg.SCommand#{bonus={bindtype=1,items={10800006=1,},},moduleid=1,num=1,errcode=0,errparam=0,cmdid=29,}
]]
return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
}
