local require       = require
local unpack        = unpack
local print         = print
local BagManager    = require("character.bagmanager")
local ItemManager   = require("item.itemmanager")
local gameevent	    = require("gameevent")
local EventHelper   = UIEventListenerHelper
local EctypeManager = require("ectype.ectypemanager")
local UIManager     = require("uimanager")

local gameObject
local name
local fields

local g_RecmdedEquips
local g_Seconds
local g_EventId


local function SetEquipBox()
	if #g_RecmdedEquips ~= 0 then
		g_Seconds = 40
		fields.UILabel_NewEquipName.text = g_RecmdedEquips[1]:GetName()
		fields.UISprite_NewEquip_Quality.spriteName = colorutil.GetQualitySprite(g_RecmdedEquips[1]:GetQuality())
		fields.UITexture_NewEquip_Icon:SetIconTexture(g_RecmdedEquips[1]:GetTextureName())
		fields.UISprite_NewEquip_Binding.gameObject:SetActive(g_RecmdedEquips[1]:IsBound())
		if g_RecmdedEquips[1]:IsMainEquip() and g_RecmdedEquips[1]:GetAnnealLevel() ~= 0 then
			fields.UILabel_NewEquip_AnnealLevel.gameObject:SetActive(true)
			fields.UILabel_NewEquip_AnnealLevel.text = "+" .. g_RecmdedEquips[1]:GetAnnealLevel()
		else
			fields.UILabel_NewEquip_AnnealLevel.gameObject:SetActive(false)
			fields.UILabel_NewEquip_AnnealLevel.text = "+0"
		end
	else
		-- ����second_update����
		if g_EventId then 
			gameevent.evt_second_update:remove(g_EventId)
			g_EventId = nil
		end
		fields.UIGroup_NewEquipTips.gameObject:SetActive(false)
	end
end

local function RemoveRecmdedEquips()
	if fields.UIGroup_NewEquipTips.gameObject.activeSelf then
		fields.UIGroup_NewEquipTips.gameObject:SetActive(false)
		-- ����second_update����
		if g_EventId then
			gameevent.evt_second_update:remove(g_EventId)
			g_EventId = nil
		end

		for i = #g_RecmdedEquips,1,-1 do
			table.remove(g_RecmdedEquips,i)
		end
	end
end


local function LoadrRecommendEquip()
	if g_RecmdedEquips == nil  then
		printyellow(">>>>>>>>>>>>g_RecmdedEquips is null")
	end
	--if g_RecmdedEquips[1]:GetBagPos() == cfg.Const.NULL then
	--printyellow(">>>>>>>>>>>>bag is full")
	--	end
	printyellow(">>>>>>>>>>>>>>>g_RecmdedEquips number:",#g_RecmdedEquips)
	printyellow(">>>>>>>>>>>>>>>g_RecmdedEquips number:",g_RecmdedEquips[1]:GetBagPos())
	BagManager.SendCRecommendEquip(g_RecmdedEquips[1]:GetBagPos())
	g_Seconds = -1
end

local function second_update(now)
	if g_Seconds >= 0 then 
		fields.UILabel_LoadEquip_CountDown.text = g_Seconds
	end
	if g_Seconds == 0 then
		LoadrRecommendEquip()
		--table.remove(g_RecmdedEquips, 1)
		--SetEquipBox()
	end
	--  �Ի�������CG��������ʱ��ͣ��ʱ
	if not (UIManager.isshow("plot.dlgplotmain") or UIManager.isshow("dlgtasktalk") or UIManager.isshow("dlgtaskreward")) then
		g_Seconds = g_Seconds - 1
	end
	
end




local function show(params)

	local PlayerRole     = require("character.playerrole")

	if PlayerRole:Instance():GetLevel() < 6 then
		g_RecmdedEquips = BagManager.GetRecommendEquips()
		table.remove(g_RecmdedEquips, 1)
		fields.UIGroup_NewEquipTips.gameObject:SetActive(false)
		return
	end
	
	if fields and fields.UIGroup_NewEquipTips.gameObject.activeSelf == false then 
		
		g_RecmdedEquips = BagManager.GetRecommendEquips()
		--printyellow(">>>>>>>>>>>>>>>g_RecmdedEquips number:",#g_RecmdedEquips)
		--printyellow(">>>>>>>>>>>>>>>g_RecmdedEquips number:",g_RecmdedEquips[1]:GetBagPos())
		if #g_RecmdedEquips ~= 0 then
			fields.UIGroup_NewEquipTips.gameObject:SetActive(true)
			SetEquipBox()
			g_EventId = gameevent.evt_second_update:add(second_update)
		end
	end
	
	EventHelper.SetClick(fields.UIButton_Equip, function()
		LoadrRecommendEquip()

	end )
	EventHelper.SetClick(fields.UIButton_CloseNewEquipTips, function()
		table.remove(g_RecmdedEquips, 1)
		SetEquipBox()
	end )
end



local function hide()
end

local function init(Name, GameObject, Fields)
	name, gameObject, fields = Name, GameObject, Fields
--[[	EventHelper.SetClick(fields.UIButton_NewEquipBox, function()
		if g_RecmdedEquips == nil then
			printyellow("g_RecmdedEquips is null")
		end
		BagManager.SendCRecommendEquip(g_RecmdedEquips[1]:GetBagPos())
		g_Seconds = -1

	end )
	EventHelper.SetClick(fields.UIButton_CloseNewEquipTips, function()
		table.remove(g_RecmdedEquips, 1)
		SetEquipBox()
	end )--]]
end

return {
	init                = init,
	show                = show,
	hide                = hide,
	SetEquipBox         = SetEquipBox,
	RemoveRecmdedEquips = RemoveRecmdedEquips,
}

