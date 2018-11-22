local unpack = unpack
local print = print
local VoiceManager = VoiceManager
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local network = require("network")
local Player = require"character.player"
local configManager = require "cfg.configmanager"
local define = require "defineenum"
local PlayerRole = require "character.playerrole"
local BonusManager = require "item.bonusmanager"
local VipChargeManager = require "ui.vipcharge.vipchargemanager"
local EctypeDataManager = require "ui.ectype.storyectype.ectypedatamanager"
local LimitManager = require "limittimemanager"
local Server
local gameObject
local name
local fields

local cur_cash = 0
local cur_desc = ""

local function destroy()
  --print(name, "destroy")
end

local function show(params)
  	--print(name, "show")
  	local msg = lx.gs.bonus.msg.CGrowplanBuyNum({})
  	network.send(msg)
end

local function hide()
  --print(name, "hide")
end


local function GetMaxVipLevel()
	local vipdata = configManager.getConfig("vipbonus")
--	printyellow("GetMaxVipLevel")
--	printt(vipdata)
	return #vipdata
end

local function GetCurVipData()
	local vipdata = configManager.getConfig("vipbonus")
	for _,data in pairs(vipdata) do
		if data.viplevel == PlayerRole:Instance().m_VipLevel + 1 then
			return data
		end
	end
	return nil
end

local function GetTheMoneyNeedToCharge(curvipdata) --所需要的钱和比例

	local curTotalCharge = VipChargeManager.GetTotalCharge()/ 100 --这个地方还要改回来

	local vipNeedToCharge = curvipdata.needcharge
--	if curTotalCharge >= vipNeedToCharge then
--		return 0,1
--	else
		return (vipNeedToCharge - curTotalCharge),curTotalCharge/vipNeedToCharge
--	end
end


local function RefreshYuanBaoData()  --包括VIP等级，原价现价等
--	printyellow("PlayerRole:Instance().m_VipLevel",PlayerRole:Instance().m_VipLevel)
--	printyellow("EctypeDataManager.GetMaxVIPLevel()",GetMaxVipLevel())
	if PlayerRole:Instance().m_VipLevel == GetMaxVipLevel() then
--		printyellow("RefreshYuanBaoData1")
        fields.UILabel_VIPNum.text = PlayerRole:Instance().m_VipLevel or 0	
		fields.UIGroup_Recharge.gameObject:SetActive(false)
		fields.UISlider_Recharge.gameObject:SetActive(false)
		if shouldHideVip() then
			fields.UISlider_Recharge.gameObject:SetActive(false)
			fields.UIGroup_Recharge.gameObject:SetActive(false)
			fields.UIButton_VIPPrivilege.gameObject:SetActive(false)
			fields.UISprite_VIP.gameObject:SetActive(false)
		end
	else
		fields.UIGroup_Recharge.gameObject:SetActive(true)
		fields.UISlider_Recharge.gameObject:SetActive(true)
		local curvipdata = GetCurVipData()
		fields.UILabel_VIPNum.text = PlayerRole:Instance().m_VipLevel or 0						--角色当前vip值
		if shouldHideVip() then
			fields.UISlider_Recharge.gameObject:SetActive(false)
			fields.UIGroup_Recharge.gameObject:SetActive(false)
			fields.UIButton_VIPPrivilege.gameObject:SetActive(false)
			fields.UISprite_VIP.gameObject:SetActive(false)
		end
		fields.UILabel_VIPNext.text = curvipdata.viplevel										--下一个VIP等级
		local moneyneedtocharge
		local value
		local firstcharge = configManager.getConfig("firstcharge")
		local rate = firstcharge.rmbtojifen

		moneyneedtocharge,value = GetTheMoneyNeedToCharge(curvipdata)
		local moneyneedtocharge1 = math.ceil(moneyneedtocharge)
		fields.UILabel_Money.text =  moneyneedtocharge1 * rate    --还需要充多少元宝
		fields.UILabel_TheMoneyNeedToCharge.text = (curvipdata.needcharge * rate - moneyneedtocharge1 * rate) .."/"..curvipdata.needcharge * rate
		fields.UISlider_Recharge.value = value                         -- 黄条比例
	end


end

local function IsMonthCard(product)
	return product.class == "cfg.pay.MonthCard"
end

local function IsNormalProduct(product)
	return product.class == "cfg.pay.NormalCharge"
end

local function IsSupremeCard(product)
	return product.class == "cfg.pay.SupremeCard"
end

local function IshasBeenCharged(product)
	local hasBuyProduct = VipChargeManager.GetHasBuyProduct()
--	hasBuyProduct = {}
--	table.insert(hasBuyProduct,1)
--	table.insert(hasBuyProduct,3)
--	table.insert(hasBuyProduct,5)
	for _,has_buy_product_id in pairs (hasBuyProduct)do
		if product.chargeid == has_buy_product_id then
			return true
		end
	end
	return false
end

local function DisplayOneProduct(list_item, product)

	list_item.Controls["UILabel_Cost"].text = (product.price/100)..LocalString.VipCharge_Yuan--RMB(价格)
	local showBindRedpack = false
	if product.bindredpackagetype~=nil and product.bindredpackagetype>0 then
		showBindRedpack = true
	end
	list_item.Controls["UIButton_RedPack"].gameObject:SetActive(showBindRedpack)
	if IsMonthCard(product) then            --月卡
		if IshasBeenCharged(product) then			--是否曾经购买过
			list_item.Controls["UISprite_Recommend"].gameObject:SetActive(false)
		end
		if shouldHideVip() then list_item.Controls["UILabel_Description_VIP"].gameObject:SetActive(false) end
		list_item.Controls["UITexture_GiftBag"]:SetIconTexture(product.backgourndimage)
		list_item.Controls["UIGroup_BGLow"].gameObject:SetActive(false)
		list_item.Controls["UIGroup_BGHigh"].gameObject:SetActive(true)
		list_item.Controls["UILabel_Type"].gameObject:SetActive(false)
		list_item.Controls["UISprite_Icon_Type"].gameObject:SetActive(false)
		list_item.Controls["UILabel_Month"].gameObject:SetActive(true)
--		printt(product.getyuanbao)
		local money1 = BonusManager.GetItemsOfSingleBonus(product.getyuanbao)-- printyellow("money") printt(money1)
		local money2 = BonusManager.GetItemsOfSingleBonus(product.getbindyuanbao)
		list_item.Controls["UILabel_Number_High"].text = money1[1]:GetNumber()
		list_item.Controls["UILabel_Number1"].text = money2[1]:GetNumber()
		--隐藏至尊卡
		list_item.Controls["UILabel_Description2"].gameObject:SetActive(false)
		list_item.Controls["UISprite_Money2"].gameObject:SetActive(false)
		list_item.Controls["UILabel_Number2"].gameObject:SetActive(false)
		--显示月卡
		list_item.Controls["UILabel_Description1"].gameObject:SetActive(true)
		list_item.Controls["UISprite_Money1"].gameObject:SetActive(true)
		list_item.Controls["UILabel_Number1"].gameObject:SetActive(true)
	elseif IsNormalProduct(product)	then								--普通商品
		list_item.Controls["UIGroup_BGHigh"].gameObject:SetActive(false)
		if IshasBeenCharged(product) then			--是否曾经购买过
--		if true then
			list_item.Controls["UISprite_Recommend"].gameObject:SetActive(false)
			list_item.Controls["UIGroup_BGLow"].gameObject:SetActive(false)
		else
			list_item.Controls["UISprite_Recommend"].gameObject:SetActive(true)
			list_item.Controls["UIGroup_BGLow"].gameObject:SetActive(true)
			local money1 = BonusManager.GetItemsOfSingleBonus(product.firstgetbindyuanbao)

			list_item.Controls["UILabel_Number_Low"].text = money1[1]:GetNumber()

		end
		list_item.Controls["UILabel_Description_VIP"].gameObject:SetActive(false)
		list_item.Controls["UITexture_GiftBag"]:SetIconTexture(product.backgourndimage)
		local money2 = BonusManager.GetItemsOfSingleBonus(product.getyuanbao)
		list_item.Controls["UILabel_Type"].text = money2[1]:GetNumber()
	elseif IsSupremeCard(product) then
		if IshasBeenCharged(product) then			--是否曾经购买过
			list_item.Controls["UISprite_Recommend"].gameObject:SetActive(false)
		end
		if shouldHideVip() then list_item.Controls["UILabel_Description_VIP"].gameObject:SetActive(false) end
		list_item.Controls["UITexture_GiftBag"]:SetIconTexture(product.backgourndimage)
		list_item.Controls["UIGroup_BGLow"].gameObject:SetActive(false)
		list_item.Controls["UIGroup_BGHigh"].gameObject:SetActive(true)
		list_item.Controls["UILabel_Type"].gameObject:SetActive(false)
		list_item.Controls["UISprite_Icon_Type"].gameObject:SetActive(false)
		list_item.Controls["UILabel_Month"].gameObject:SetActive(true)
		list_item.Controls["UILabel_Month"].text = product.notetext
		local money1 = BonusManager.GetItemsOfSingleBonus(product.getyuanbao)-- printyellow("money") printt(money1)
		local money2 = BonusManager.GetItemsOfSingleBonus(product.getbindyuanbao)
		list_item.Controls["UILabel_Number_High"].text = money1[1]:GetNumber()
		list_item.Controls["UILabel_Number2"].text = money2[1]:GetNumber()

		--隐藏月卡
		list_item.Controls["UILabel_Description1"].gameObject:SetActive(false)
		list_item.Controls["UISprite_Money1"].gameObject:SetActive(false)
		list_item.Controls["UILabel_Number1"].gameObject:SetActive(false)
		--显示至尊卡
		list_item.Controls["UILabel_Description2"].gameObject:SetActive(true)
		list_item.Controls["UISprite_Money2"].gameObject:SetActive(true)
		list_item.Controls["UILabel_Number2"].gameObject:SetActive(true)
	else
			--其它商品
	end

--	EventHelper.SetClick(list_item.Controls["UIButton_Buy"],function() --购买
--	end )

end

local function RefreshProduct()
	local productdata = configManager.getConfig("charge")
	local sortProductData = {}
	for _,product in pairs(productdata) do
		table.insert(sortProductData,product)
	end

	table.sort(sortProductData, function(item1, item2) return(item1.displayorder < item2.displayorder) end)
	fields.UIList_GigtBag:Clear()
	for _,product in pairs (sortProductData) do

		if IsMonthCard(product) or IsNormalProduct(product) or IsSupremeCard(product) then

			local list_item = fields.UIList_GigtBag:AddListItem()
			DisplayOneProduct(list_item,product)

			EventHelper.SetClick(list_item,function()
                print("recharge.RefreshProduct:"..product.price.." text:"..product.notetext);
				cur_cash = product.price
				cur_desc = product.notetext
				VipChargeManager.SendCGetApporder(product.chargeid)
			end)
			local btnRedPack = list_item.Controls["UIButton_RedPack"];

			EventHelper.SetClick(btnRedPack, function()
				if product.bindredpackagetype~=nil and product.bindredpackagetype>0 then
					fields.UIGroup_RedpackDesc.gameObject:SetActive(true)
				end
		    end)
		end
	end
end

local function 	RefreshRedDot()
	if VipChargeManager.UnRead() then
		fields.UISprite_Warning.gameObject:SetActive(true)
	else
		fields.UISprite_Warning.gameObject:SetActive(false)
	end
end

local function uishowtype()
	return UIShowType.Refresh
end

local function refresh()
  -- printyellow(name, "refresh")
	RefreshRedDot()
	RefreshYuanBaoData()
	RefreshProduct()
end

local function update()

end


local function init(params)
     name, gameObject, fields = unpack(params)

	fields.UIButton_Return.gameObject:SetActive(false)
--    EventHelper.SetClick(fields.UIButton_Return, function ()
--        --uimanager.show("dlgmain_open")
--        uimanager.hidedialog(name)
--        --if (首次充值)
--        uimanager.showdialog("vipcharge.dlgfirstofcharge")
--    end)
	if shouldHideVip() then fields.UIButton_VIPPrivilege.gameObject:SetActive(false) end

    EventHelper.SetClick(fields.UIButton_VIPPrivilege, function ()
        uimanager.hidedialog("vipcharge.dlgrecharge")
        uimanager.showdialog("vipcharge.dlgprivilege_vip")
   	end)

	EventHelper.SetClick(fields.UIButton_RedpackClose, function()
		fields.UIGroup_RedpackDesc.gameObject:SetActive(false)
	end)

	EventHelper.SetClick(fields.UIButton_RedpackBG, function()
		fields.UIGroup_RedpackDesc.gameObject:SetActive(false)
	end)
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
