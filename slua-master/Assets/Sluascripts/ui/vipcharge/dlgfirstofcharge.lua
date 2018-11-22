local unpack = unpack
local print = print
local VoiceManager = VoiceManager
local EventHelper = UIEventListenerHelper

local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local NPC = require("character.npc")
local Player = require"character.player"
local ConfigManager = require "cfg.configmanager"
local BonusManager = require("item.bonusmanager")
local define = require "define"
local PlayerRole = require "character.playerrole"
local LimitManager = require "limittimemanager"
local VipChargeManager = require "ui.vipcharge.vipchargemanager"
local CgManager = require "ui.cg.cgmanager"
local TalismanModel = require("character.talisman.talisman")
local ItemManager 	= require("item.itemmanager")

local fields
local gameObject
local name
local g_NPC
local g_Weapon
local g_FirstChargeType
local g_durationSet = 0


local function GetLuXueQiCSVId()
	local mallnpc = ConfigManager.getConfig("mallnpc")
	local npcId
	for _,value in pairs (mallnpc) do
		if value.malltype == cfg.mall.MallType.FIRST_CHARGE then
			return value.cornucopianpc
		end
	end
	return nil
end

local function OnNPCLoaded()
	local npcTrans = g_NPC.m_Object.transform
	npcTrans.parent = fields.UITexture_Model.gameObject.transform
	--g_NPC:UIScaleModify()
	--playerTrans.localScale = Vector3.one * 200
	npcTrans.localPosition = Vector3(-50, -260, -100)
	npcTrans.rotation = Quaternion.Euler(-90,0,0)
	g_NPC:SetUIScale(200)

	ExtendedGameObject.SetLayerRecursively(g_NPC.m_Object, define.Layer.LayerUICharacter)
    g_NPC:Show()
	EventHelper.SetDrag(fields.UITexture_Model, function(o, delta)
		if g_NPC then
			local npcObj = g_NPC.m_Object
			if npcObj then
				local vecRotate = Vector3(0, -delta.x, 0)
				npcObj.transform.localEulerAngles = npcObj.transform.localEulerAngles + vecRotate
			end
		end
	end )
end

local function AddNPC()
	if g_NPC == nil then
		g_NPC = NPC:new()
		g_NPC.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
--		local npcCfg = ConfigManager.getConfigData("mallnpc",firstChargeType)
--		local chargebonus = ConfigManager.getConfig("chargebonus")

--        local npcCsvId = cfg.bonus.ChargeBonus.chargeNPC
		local npcCsvId = GetLuXueQiCSVId()
		-- printyellow("npcCsvId",npcCsvId)
		g_NPC:RegisterOnLoaded(OnNPCLoaded)
		g_NPC:init(0, npcCsvId)
	end
end
local function AddWeapon2()
	local talismanId = tonumber(LocalString.Charge_FirstReward_Val1)
	local talisman = ItemManager.CreateItemBaseById(talismanId,nil,1);
	fields.UILabel_EquipAddedPower.text = LocalString.Charge_FirstReward_Val2

	g_Weapon = TalismanModel:new()
	g_Weapon.m_AnimSelectType = cfg.skill.AnimTypeSelectType.UI
	g_Weapon:RegisterOnLoaded(function(asset_obj)
		asset_obj:SetActive(true)
		asset_obj.transform.parent = fields.UITexture_Model2.gameObject.transform
		ExtendedGameObject.SetLayerRecursively(asset_obj, define.Layer.LayerUICharacter)
		asset_obj.transform.localScale = Vector3.one * 150
		asset_obj.transform.localPosition = Vector3(-10, -30, -100)
		asset_obj.transform.rotation = Quaternion.Euler(-90,0,0)
		-- EventHelper.SetDrag(fields.UITexture_Model2.gameObject.transform, function(o,delta)
		-- 	local vecRotate = Vector3(0,-delta.x,0)
		-- 	g_Weapon.m_Object.transform.localEulerAngles = g_Weapon.m_Object.transform.localEulerAngles + vecRotate
		-- end)
	end)
	g_Weapon:init(talisman, PlayerRole:Instance(), -1)
end
local function hideReturnButton(sestHide)
	local trfBtnReturn = gameObject.transform.parent:Find("dlgdialog/Z_Depth/AnchorTopLeft/UIButton_Return")
	if trfBtnReturn~=nil then
		local uiWidget = trfBtnReturn.gameObject:GetComponent("UIWidget")
		if sestHide then
			uiWidget.alpha = 0.01;
		else
			uiWidget.alpha = 1.0;
		end
	end
end
local function destroy()
  --print(name, "destroy")
	if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
	if g_Weapon then
		g_Weapon:release()
		g_Weapon = nil
	end
end
local function show()
  --print(name, "show")

	--AddNPC()
	--AddWeapon2()
	g_durationSet = 200
	hideReturnButton(true)
end

local function hide()
  --print(name, "hide")
	if g_NPC then
		g_NPC:release()
		g_NPC = nil
	end
	if g_Weapon then
		g_Weapon:release()
		g_Weapon = nil
	end
	g_durationSet = 0
	hideReturnButton(false)
end

local function RefreshRewardItem()
	local firstcharge = ConfigManager.getConfig("firstcharge")
	local bonuslist = BonusManager.GetItemsByBonusConfig(firstcharge.bonus)
--	printyellow("fields.UIList_Rewards",fields.UIList_Rewards)
	fields.UIList_Rewards:Clear()
	for _,item in pairs(bonuslist) do
        local listItem=fields.UIList_Rewards:AddListItem()
--		local params = {}
--		params.notShowAmount = true
        BonusManager.SetRewardItem(listItem,item)
	end
end

local function refresh()
  --print(name, "refresh")
--	printyellow("wo yuan ba xin fang fei")
	RefreshRewardItem()
	if VipChargeManager.GetTotalCharge() < 600 then  --??1??????
		--UITools.SetButtonEnabled(fields.UIButton_GetRewards.gameObject:GetComponent(UIButton),false)
		fields.UIButton_GetRewards.gameObject:SetActive(false)
		fields.UIButton_Charge.gameObject:SetActive(true);
	else
		if VipChargeManager.GetFirstPayUsed() == 1 then
			--UITools.SetButtonEnabled(fields.UIButton_GetRewards.gameObject:GetComponent(UIButton),false)
			fields.UILabel_GetRewards.text = LocalString.Common_Receive
			fields.UIButton_GetRewards.gameObject:SetActive(false)
			fields.UIButton_Charge.gameObject:SetActive(false);
		else
			--UITools.SetButtonEnabled(fields.UIButton_GetRewards.gameObject:GetComponent(UIButton),true)
			fields.UIButton_GetRewards.gameObject:SetActive(true)
			fields.UIButton_Charge.gameObject:SetActive(false);
		end
	end
	EventHelper.SetClick(fields.UIButton_GetRewards, function () --
		if VipChargeManager.GetFirstPayUsed() == 1 then
			uimanager.hidedialog("vipcharge.dlgfirstofcharge")
		else
			VipChargeManager.SendCBuyVipPackage(-1)
		end
	end)
	-- g_durationSet = 200
	-- hideReturnButton(true)
end

local function update()
	if g_NPC and g_NPC.m_Avatar then
		g_NPC.m_Avatar:Update()
	end
	g_durationSet = g_durationSet-1
	if g_durationSet>0 then
		hideReturnButton(true)
	end
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
     name, gameObject, fields = unpack(params)

	--fields.UIButton_Return.gameObject:SetActive(false)
	fields.UITexture_AD:SetIconTexture("ICON_FirstOfCharge_BG01")

	EventHelper.SetClick(fields.UIButton_Return,function ()
		uimanager.hidedialog("vipcharge.dlgfirstofcharge")
	end)

	EventHelper.SetClick(fields.UIButton_PlayVideo,function ()
--		print("wangliewangliewangliewangliewanglieroleroleroleplayplayplay")
		CgManager.PlayCG("xueqiwangyue.mp4",nil, 2)
	end)

    EventHelper.SetClick(fields.UIButton_Charge, function ()
        --uimanager.show("dlgmain_open")

        uimanager.showdialog("vipcharge.dlgrecharge")
    end)

	-- local curDialogName = uimanager.currentdialogname();
	-- if curDialogName ~= "vipcharge.dlgfirstofcharge" then
	-- 	uimanager.hidecurrentdialog();
	-- end
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
}
