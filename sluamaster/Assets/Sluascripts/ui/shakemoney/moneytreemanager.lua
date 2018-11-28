local unpack = unpack
local string = string
local math = math
local EventHelper = UIEventListenerHelper
local ConfigManager = require("cfg.configmanager")
local PlayerRole = require "character.playerrole"
local LimitManager = require "limittimemanager"
local VipChargeManager = require"ui.vipcharge.vipchargemanager"
local UIManager = require "uimanager"
local NetWork = require "network"

local function GetShakeTime()
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.SHAKE_MONEY_TREE,1) --购买次数
    local m_Num = limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
	return m_Num
end

local function GetJinBi(times)
	local shakemoney = ConfigManager.getConfig("shakemoneytree")
	local shakeinfo = shakemoney.shakeinfo
	if times >= #shakeinfo then
		times = times 
	else
		times = times + 1
	end
	return shakeinfo[times].getmoney.amount
end

local function GetYuanBao(times)
	local shakemoney = ConfigManager.getConfig("shakemoneytree")
	local shakeinfo = shakemoney.shakeinfo
	if times >= #shakeinfo then
		times = times 
	else
		times = times + 1
	end
	return shakeinfo[times].cost.amount
end

local function GetMaxBuyTime()
	local shakemoney = ConfigManager.getConfig("shakemoneytree")
	local entertimes = shakemoney.viplimit.entertimes
	local index 
	if PlayerRole:Instance().m_VipLevel >= #entertimes then
		index = #entertimes
	else	
		index = PlayerRole:Instance().m_VipLevel + 1
	end

	return entertimes[index]
end

local function GetMaxVIPLevel() --得到最大VIP等级
	local storyconfig = ConfigManager.getConfig("ectypesingle")
--	printyellow("GetMaxVIPLevel()")
--	printt(storyconfig)

	local levels = #storyconfig.resetopencountlimit.entertimes
	return levels - 1
end

local function onmsg_SShakeMoneyTree(d)
	
	UIManager.refresh("shakemoney.dlgmoneytree",{receinexunibi = d.receinexunibi,criticalnum = math.floor(d.criticalnum)})
end

local function init(params)

	NetWork.add_listeners( {

       { "lx.gs.bonus.msg.SShakeMoneyTree", onmsg_SShakeMoneyTree },

    } )
end



return {
	init = init,
	GetShakeTime = GetShakeTime,
	GetJinBi = GetJinBi,
	GetYuanBao = GetYuanBao,
	GetMaxBuyTime = GetMaxBuyTime,
	GetMaxVIPLevel = GetMaxVIPLevel,
}
