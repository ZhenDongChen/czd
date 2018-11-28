local unpack = unpack
local print = print
local VoiceManager = VoiceManager
local uimanager = require"uimanager"
local EventHelper = UIEventListenerHelper
local ItemManager = require("item.itemmanager")
local BonusManager = require("item.bonusmanager")
local uimanager = require("uimanager")
local network = require("network")
local login = require("login")
local Player = require"character.player"
local configManager = require "cfg.configmanager"
local define = require "defineenum"
local PlayerRole = require "character.playerrole"
local VipChargeManager = require "ui.vipcharge.vipchargemanager"
local LimitManager = require "limittimemanager"

local gameObject
local name
local curviplevel = 1
local curvipdata
local maxviplevel



local function GetCurVipData()
	local vipdata = configManager.getConfig("vipbonus")
	for _,data in pairs(vipdata) do
		if data.viplevel == curviplevel then
			return data
		end
	end
	return nil
end

local function GetTheMoneyNeedToCharge(curvipdata) --

	local curTotalCharge = VipChargeManager.GetTotalCharge() / 100

	local vipNeedToCharge = curvipdata.needcharge
--	if curTotalCharge >= vipNeedToCharge then
--		return 0,1
--	else
		return (vipNeedToCharge - curTotalCharge),curTotalCharge/vipNeedToCharge
--	end
end



local function RefreshYuanBaoData()
	local roleVipLv = PlayerRole:Instance().m_VipLevel or 0
	if roleVipLv == VipChargeManager.GetMaxVipLevel() then
		fields.UIGroup_Recharge.gameObject:SetActive(false)
		fields.UISlider_Recharge.gameObject:SetActive(false)
	else
		fields.UIGroup_Recharge.gameObject:SetActive(true)
		fields.UISlider_Recharge.gameObject:SetActive(true)
	end
	fields.UILabel_VIPNum.text = roleVipLv
	fields.UILabel_VIP.text = string.format(LocalString.Privilege_VIP_Title,curviplevel)  --vip title
	local moneyneedtocharge
	local value
	local firstcharge = configManager.getConfig("firstcharge")
	local rate = firstcharge.rmbtojifen
	local vipData = curvipdata
	if roleVipLv+1 <= VipChargeManager.GetMaxVipLevel() then
		vipData = VipChargeManager.GetCurVipData(roleVipLv+1)
	end
	moneyneedtocharge,value = GetTheMoneyNeedToCharge(vipData)
	local moneyneedtocharge1 = math.ceil(moneyneedtocharge)
	local restyuanbao = moneyneedtocharge1 * rate
	if restyuanbao < 0 then restyuanbao = 0 end
	fields.UILabel_VIPNext.text = vipData.viplevel
	fields.UILabel_Money.text =  restyuanbao
	fields.UILabel_TheMoneyNeedToCharge.text = (vipData.needcharge * rate - moneyneedtocharge1 * rate) .."/"..vipData.needcharge * rate
	fields.UISlider_Recharge.value = value
	fields.UILabel_Price.text = curvipdata.showprice
	fields.UILabel_PresentPriceNum.text =  curvipdata.price.amount
end

local function RefreshPrivilegeContent()
	fields.UIList_PrivilegeContent:Clear()
	for _,bonustext in pairs (curvipdata.bonustext) do
		local list_item = fields.UIList_PrivilegeContent:AddListItem()
		list_item.Controls["UILabel_PrivilegeContent"].text = bonustext
	end
end

local function RefreshBonusItem()
	fields.UIList_Prize:Clear()
	local gainbonus = BonusManager.GetItemsByBonusConfig(curvipdata.gainbonus)
	for _,bonus in pairs(gainbonus) do
		-- printyellow("RefreshBonusItem vip")
		-- printt(bonus)
		local list_item = fields.UIList_Prize:AddListItem()
        BonusManager.SetRewardItem(list_item,bonus)
	end
end

local function 	RefreshBuyButton()
--	printyellow("PlayerRole:Instance().m_VipLevel = ",PlayerRole:Instance().m_VipLevel)
--	printyellow("curviplevel =  ",curviplevel)
--	printyellow("LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,curviplevel)=",LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,curviplevel))
	if PlayerRole:Instance().m_VipLevel >= curviplevel and not LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,curviplevel)then --�ȼ�����û�й���
		fields.UISprite_Warning.gameObject:SetActive(true)
	else
		fields.UISprite_Warning.gameObject:SetActive(false)
	end


		if PlayerRole:Instance().m_VipLevel >= curviplevel and LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,curviplevel) then
			fields.UILabel_Buy.text = LocalString.Ride_HavePurchased
			UITools.SetButtonEnabled(fields.UIButton_Buy.gameObject:GetComponent(UIButton),false)
		else
			fields.UILabel_Buy.text = LocalString.Ride_Purchase
			UITools.SetButtonEnabled(fields.UIButton_Buy.gameObject:GetComponent(UIButton),true)
		end



	EventHelper.SetClick(fields.UIButton_Buy,function()

		if PlayerRole:Instance().m_VipLevel >= curviplevel  then
			if  not LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,curviplevel) then

				VipChargeManager.SendCBuyVipPackage(curviplevel)
			else
				uimanager.ShowSystemFlyText(LocalString.VipCharge_HasObtained)
			end
		else

				uimanager.ShowSystemFlyText(LocalString.VipCharge_LevelLessThan)
		end
	end)
end

local function destroy()
  --print(name, "destroy")
end


local function RefreshVIPData()
	RefreshYuanBaoData()
	RefreshPrivilegeContent()
	RefreshBonusItem()
	RefreshBuyButton()
end

local function show()
  --print(name, "show")
	curviplevel = PlayerRole:Instance().m_VipLevel
	if curviplevel > VipChargeManager.GetMaxVipLevel() then
		curviplevel = VipChargeManager.GetMaxVipLevel()
	end
	if curviplevel == 0 then
		curviplevel = 1
	end

	if curviplevel >= 15 then 
		fields.UIButton_ArrowsRight.gameObject:SetActive(false) 
	end 

	curvipdata = GetCurVipData()
	EventHelper.SetClick(fields.UIButton_ArrowsRight,function()
		if curviplevel >= VipChargeManager.GetMaxVipLevel() then
		else
			curviplevel = curviplevel + 1
			curvipdata = GetCurVipData()
			RefreshVIPData()
			if not VipChargeManager.CanCheckNextVip(curviplevel) then
				fields.UIButton_ArrowsRight.gameObject:SetActive(false) 
			else
				fields.UIButton_ArrowsRight.gameObject:SetActive(true) 
			end
		end
	end)

	EventHelper.SetClick(fields.UIButton_ArrowsLeft,function()
		if curviplevel == 1 then
		else
			curviplevel = curviplevel - 1
			curvipdata = GetCurVipData()
			RefreshVIPData()
			if not VipChargeManager.CanCheckNextVip(curviplevel) then 
				fields.UIButton_ArrowsRight.gameObject:SetActive(false) 
			else
				fields.UIButton_ArrowsRight.gameObject:SetActive(true) 
			end 
		end
	end)

	EventHelper.SetClick(fields.UIButton_VIPPrivilege,function()
		--uimanager.showdialog("vipcharge.dlgrecharge")
		uimanager.hidedialog(name, true)
		uimanager.showdialog("vipcharge.dlgrecharge")
	end)



end

local function hide()
  --print(name, "hide")
--	uimanager.closealldialog()
end




local function refresh()
  --print(name, "refresh")
	RefreshVIPData()
	-- printyellow("refresh")


end

local function update()

end


local function init(params)
     name, gameObject, fields = unpack(params)

	fields.UIButton_Return.gameObject:SetActive(false)
--    EventHelper.SetClick(fields.UIButton_Return, function ()
--        --uimanager.show("dlgmain_open")
--        uimanager.hidedialog(name)
----        uimanager.show("dlgrecharge")
--    end)



end

local function uishowtype()
	return UIShowType.Refresh
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
