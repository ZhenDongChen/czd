local network       = require "network"
local uimanager     = require "uimanager"
local configManager = require "cfg.configmanager"
local BonusManager  = require("item.bonusmanager")
local PlayerRole    = require("character.playerrole")
local LimitManager  = require "limittimemanager"
local login         = require("login")
local error         = error

local isFirstPayUsed 
local totalCharge = 0
local hasBuyProduct = {}
local receivedChargeGifts = {}
local curVipLevel
local vipDotInfo = {}
local dailyMoneyPayTime = 0
local totalDailyMoneyPayTime = 0

local function GetMaxVipLevel()
	local vipdata = configManager.getConfig("vipbonus")
	return #vipdata
end


local function GetCurVipLevel()
	if curVipLevel then
		return curVipLevel
	else
		local PlayerRole = require"character.playerrole"
		return PlayerRole:Instance().m_VipLevel
	end 
end

local function GetFirstPayUsed()
    return isFirstPayUsed
    --return 0
end
local function SetFirstPayUsed(b)
	isFirstPayUsed = b
end

local function GetTotalCharge()
	return totalCharge
end

local function SetTotalCharge(total)
	totalCharge = total
end

local function GetHasBuyProduct()
	return hasBuyProduct
end



local function GetDailyMoneyPayTime()
	return dailyMoneyPayTime
end

local function GetTotalDailyMoneyPayTime()
    return totalDailyMoneyPayTime
end

local function AddHasBuyProduct(id)
	for _,productid in pairs(hasBuyProduct) do
		if productid == id then
			return
		end 
	end 
	table.insert(hasBuyProduct,id)
end

local function ShowVipChargeDialog()
	if isFirstPayUsed == 1 then
		uimanager.showdialog("vipcharge.dlgrecharge")
	else
		uimanager.showdialog("vipcharge.dlgfirstofcharge")
	end
end

local function SendCGetApporder(productid)

	local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
	--[[if channelid == 78 then 
		uimanager.ShowAlertDlg({
                title        = LocalString.Recharge,
                content      = LocalString.Recharge_Invalid_Channel,        
                immediate = true,
            })  
		return 
	end --]]

	local token = login.get_token()
	local msg = lx.gs.pay.CGetAppOrder({productid = productid,token = token})
	network.send(msg)
end 

local function SendCBuyVipPackage(index)
	local msg = lx.gs.pay.CBuyVipPackage({index = index})
	network.send(msg)
end

local function GetPriceByProductId(pid)
	local Recharge = configManager.getConfig("charge")
	for _,product in pairs(Recharge) do
		if product.chargeid == pid then
			return product.price
		end 
	end
	return nil
end

local function GetProductCfgData(pid)
	local Recharge = configManager.getConfig("charge")
	for _,product in pairs(Recharge) do
		if product.chargeid == pid then
			return product
		end 
	end
	return nil
end

local function onmsg_SPaySuccessNotify(d)


--	print("onmsg_SPaySuccessNotify 3",GetPriceByProductId(d.productid))
	AddHasBuyProduct(d.productid)

--	AddTotalCharge(	GetPriceByProductId(d.productid)) 

	uimanager.ShowSystemFlyText(LocalString.VipCharge_PaySuccessfully)
	if uimanager.isshow("vipcharge.tabrecharge") then 
		uimanager.refresh("vipcharge.tabrecharge")
	end
	if uimanager.isshow("dlgdialog") then
		uimanager.call("dlgdialog","RefreshRedDot","vipcharge.dlgrecharge")
	end
	-- 充值1元返还(日进斗金),增加购买次数
	local chargeData = configManager.getConfigData("charge",d.productid)
	if chargeData and chargeData.class == "cfg.pay.ActiveCharge" then
		dailyMoneyPayTime = dailyMoneyPayTime+1
        totalDailyMoneyPayTime = totalDailyMoneyPayTime + 1
		uimanager.refresh("vipcharge.tabdailymoney")
	end

end

local function PayProduct(item)
    local roleid = PlayerRole:Instance().m_Id
    local rolename = PlayerRole:Instance().m_Name
    local level = PlayerRole:Instance().m_Level
    local vip = PlayerRole:Instance().m_VipLevel
    local serverid = login.get_serverid()
    local Server = GetServerList()
    local servername = Server[UserConfig["DefaultServer"]].name
	local chargeData = GetProductCfgData(item.productid)
	--local chargeData = configManager.getConfigData("charge", item.productid)

    printyellow("before orderid:".. item.orderid .. " productid:" .. item.productid.." price:"..chargeData.price)

	local channelid = Game.Platform.Interface.Instance:GetSDKPlatform()
    if channelid ~= 0 then
        if chargeData.platform[channelid] ~= nil then
            item.productid = chargeData.platform[channelid]
        end
    end

    printyellow("after productid = " .. item.productid .. " serverid = " .. serverid)

    local desc = chargeData.notetext
	-- if Application.platform == UnityEngine.RuntimePlatform.Android then
	-- end
	if IsBSReview() then
		uimanager.ShowSystemFlyText(LocalString.RechargeClose)
	else
		Game.Platform.Interface.Instance:Pay(roleid, rolename, level, vip, item.orderid, serverid, servername, chargeData.price, item.productid, desc)
	end
end

local function onmsg_SGetAppOrder(d)
	if d.err == lx.gs.pay.SGetAppOrder.OK then
        PayProduct({productid = d.productid,orderid = d.orderid})
	else
		error("The product does not exit")
	end 
end

local function GetCurVipData(curviplevel)
	local vipdata = configManager.getConfig("vipbonus")
	for _,data in pairs(vipdata) do
		if data.viplevel == curviplevel then
			return data
		end
	end
	return nil
end

local function ShowBonusEffect(index)
	local curvipdata
	local items 
	if index == -1 then
		curvipdata = ConfigManager.getConfig("firstcharge")
		items = BonusManager.GetItemsByBonusConfig(curvipdata.bonus)
	else
		curvipdata = GetCurVipData(index)
		items = BonusManager.GetItemsByBonusConfig(curvipdata.gainbonus)
	end

	uimanager.show("common.dlgdialogbox_itemshow", {itemList = items})
end

local function CanCheckNextVip(curviplevel)
	if curviplevel == GetMaxVipLevel() and PlayerRole:Instance().m_VipLevel == GetMaxVipLevel() then
		return false
	elseif PlayerRole:Instance().m_VipLevel <= 14 and  curviplevel >= 15  then
		return false 
	elseif  PlayerRole:Instance().m_VipLevel >= 15 and curviplevel ==  PlayerRole:Instance().m_VipLevel + 1 then
		return false
	else
		return true 
	end
				
end


local function onmsg_SBuyVipPackage(d)
	uimanager.ShowSystemFlyText(LocalString.VipCharge_ObtainedSuccessfully)
	ShowBonusEffect(d.index) --显示特效
	if uimanager.isshow("vipcharge.dlgprivilege_vip") then		
		uimanager.refresh("vipcharge.dlgprivilege_vip")
	end
	if d.index == -1 then
		isFirstPayUsed = 1
		if uimanager.isshow("vipcharge.dlgfirstofcharge") then
			uimanager.refresh("vipcharge.dlgfirstofcharge")
		end
	end 

    --lottery
	if uimanager.isshow("lottery.lotteryfragment.dlglotteryfragment") then
		uimanager.call("lottery.lotteryfragment.dlglotteryfragment", "RefreshTurnCount")
	end
end

local function onmsg_SBuySupremeCardNotify(msg)
	local supremeCard = require("ui.welfare.welfaremanager").GetSupremeCardData()
	supremeCard.HasCard = true
	uimanager.refresh("vipcharge.tabmonthcard")
end

local function onmsg_SGetSupremeCardGift(msg)
	local supremeCard = require("ui.welfare.welfaremanager").GetSupremeCardData()
	supremeCard.TodayRecv = true
	if uimanager.isshow("vipcharge.tabmonthcard") then
		uimanager.call("vipcharge.tabmonthcard", "OnMsgSupremeCardGift", msg)
	end
	uimanager.refresh("vipcharge.tabmonthcard")
end

local function onmsg_SVipLevelNotify(d)
	local PlayerRole = require"character.playerrole"
	PlayerRole.Instance():ChangeVipLevel(d.newlevel)
	totalCharge = d.totalcharge
end

local function onmsg_SBonusInfo(d)
	isFirstPayUsed 		= d.isfirstpayused		--是否领取
	totalCharge 		= d.totalcharge			--RMB
	hasBuyProduct		= d.hasbuyproduct		--已经购买过的商品
	dailyMoneyPayTime	= d.isactivechargepay or 0	--今日已购买“日进斗金”次数
    totalDailyMoneyPayTime = d.isactivepay or 0   --累计已购买“日进斗金”次数，领完所有奖励之后会重置
end

local function onmsg_SActivePayBonus(d)
    uimanager.ShowSystemFlyText(string.format(LocalString.Charge_DailyMoney_Bonus,d.bonustype))
end

local function 	UnRead()
	for i= 1,PlayerRole:Instance().m_VipLevel do
		if  not LimitManager.GetLimitTime(cfg.cmd.ConfigId.VIP_PACKAGE_BUY,i) then
			return true
		end 
	end
	return false
end

local function UnReadFirstCharge()
	if GetTotalCharge() >= 600 and GetFirstPayUsed() ~= 1 then
		return true
	else
		return false
	end
end
local function GetSupremeDailyGitfNum()
	local chargeData = configManager.getConfigData("charge",12)
	if chargeData~=nil then
		local money2 = BonusManager.GetItemsOfSingleBonus(chargeData.getbindyuanbao)
		return money2[1]:GetNumber()
	end
	return 0
end
-- 日进斗金红点
local function UnReadDailyMoney()
	local dailyMoneyData = nil
	local chargeData = configManager.getConfig("charge")
	for chargeId, data in pairs(chargeData) do
		if data.class == "cfg.pay.ActiveCharge" then
			dailyMoneyData = data
			break
		end
	end
	if dailyMoneyData then 
		return (dailyMoneyPayTime < dailyMoneyData.daylimit.num)
	end
	return false
end

local function UnReadReCharge()
	local unread1 = require("ui.welfare.welfaremanager").UnRead_MonthCard
	local unread2 = require("ui.welfare.welfaremanager").UnRead_GrowPlan
	local unread3 = require("ui.vipcharge.tabdaycharge").UnRead
	local unread4 = UnReadDailyMoney
	if unread1() or unread2() or unread3() or unread4() then
		return true
	else
		return false
	end
end

local function Release()
	isFirstPayUsed = nil
	totalCharge = 0
	hasBuyProduct = {}
	receivedChargeGifts = {}
	curVipLevel = nil
	dailyMoneyPayTime = 0
    totalDailyMoneyPayTime = 0
end

local function OnLogout()
	Release()
end

local function init()
	gameevent.evt_system_message:add("logout", OnLogout)
    network.add_listeners( {

       --{ "lx.gs.chat.msg.SChat", onmsg_SChat },
       { "lx.gs.pay.SPaySuccessNotify", onmsg_SPaySuccessNotify },
       { "lx.gs.pay.SGetAppOrder", onmsg_SGetAppOrder },
	   { "lx.gs.pay.SBuyVipPackage",onmsg_SBuyVipPackage,},
	   { "lx.gs.pay.SBuySupremeCardNotify",onmsg_SBuySupremeCardNotify,},
	   { "lx.gs.pay.SVipLevelNotify",onmsg_SVipLevelNotify},
	   { "lx.gs.bonus.msg.SBonusInfo",onmsg_SBonusInfo},
	   { "lx.gs.pay.SActivePayBonus",onmsg_SActivePayBonus},
	   { "lx.gs.bonus.msg.SGetSupremeCardGift",onmsg_SGetSupremeCardGift}

    } )
end

return {
	init                      = init,
	SendCGetApporder          = SendCGetApporder,
	SendCBuyVipPackage        = SendCBuyVipPackage,
	GetFirstPayUsed           = GetFirstPayUsed,
	SetFirstPayUsed           = SetFirstPayUsed,
	GetTotalCharge            = GetTotalCharge,
	GetHasBuyProduct          = GetHasBuyProduct,
	GetCurVipLevel            = GetCurVipLevel,
	GetMaxVipLevel            = GetMaxVipLevel,
	CanCheckNextVip           = CanCheckNextVip,
	ShowVipChargeDialog       = ShowVipChargeDialog,
	SetTotalCharge            = SetTotalCharge,
	UnRead                    = UnRead,
	GetDailyMoneyPayTime      = GetDailyMoneyPayTime,
    GetTotalDailyMoneyPayTime = GetTotalDailyMoneyPayTime,
	UnReadDailyMoney	      = UnReadDailyMoney,
	UnReadFirstCharge	      = UnReadFirstCharge,
	UnReadReCharge		      = UnReadReCharge,
	PayProduct                = PayProduct,
	GetSupremeDailyGitfNum    = GetSupremeDailyGitfNum,
	GetProductCfgData		  = GetProductCfgData,
	GetCurVipData			  = GetCurVipData,
}
