local PlayerRole = require "character.playerrole"
local ConfigManager = require "cfg.configmanager"
local LimitManager = require "limittimemanager"

local function isNotEnoughTiLi(m_SectionData)
	

	return PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.TiLi] < m_SectionData.costtili.amount
end

local function isNotEnoughMultiTiLi(resNum,m_SectionData)
--	printyellow("isNotEnoughMultiTiLi")
--	printt(m_SectionData)

	return PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.TiLi] < m_SectionData.costtili.amount * resNum
end

local function GetMaxResNumCanSweep(section)
	local RestNum_CanSweep
	local index
	for index = 1 , section.daylimit.num do
		if PlayerRole:Instance().m_Currencys[cfg.currency.CurrencyType.TiLi] < section.costtili.amount * index then
			break
		end
		RestNum_CanSweep = index
		index = index + 1
	end

	return RestNum_CanSweep
end

local function GetMaxVIPLevel() --得到最大VIP等级
	local storyconfig = ConfigManager.getConfig("ectypesingle")
	-- printyellow("GetMaxVIPLevel()")
	-- printt(storyconfig)

	local levels = #storyconfig.resetopencountlimit.entertimes
	return levels - 1
end

local function GetUsedTimes(m_SectionData)		--得到已使用的挑战次数
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE,m_SectionData.id)
	return limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
end

local function GetUsedResetTimes(m_SectionData) --得到已使用的重置次数
	-- printyellow("GetUsedResetTimes(m_SectionData)")
	-- printyellow("m_SectionData",m_SectionData.id)
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.STORY_ECTYPE_RESET_OPEN_COUNT,m_SectionData.id)
	return limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
end

local function GetMaxResetTimes()				--得到当前等级最大的重置次数
	local m_ResetData   = ConfigManager.getConfig("ectypesingle")
	if PlayerRole:Instance().m_VipLevel >= GetMaxVIPLevel() then
		return m_ResetData.resetopencountlimit.entertimes[#m_ResetData.resetopencountlimit.entertimes]
	else
		return m_ResetData.resetopencountlimit.entertimes[PlayerRole:Instance().m_VipLevel+1] or 0
	end
end

local function GetUsedBuyTimes()    --得到已使用的购买次数
	local limit_time =  LimitManager.GetLimitTime(cfg.cmd.ConfigId.ROLE,cfg.cmd.CmdId.BUYTILI)
	return limit_time and limit_time[cfg.cmd.condition.LimitType.DAY] or 0
end

local function GetMaxBuyTimes() --得到当前等级最大的购买次数
	local m_BuyData   = ConfigManager.getConfig("roleconfig")
	if not m_BuyData.buytilicost then
		printyellow("m_BuyData.buytilicost is nil!")
	end
	-- printyellow("GetMaxBuyTimes",m_BuyData)
	-- printt(m_BuyData)
	if PlayerRole:Instance().m_VipLevel >= GetMaxVIPLevel() then
		--return m_BuyData.buytilicost.entertimes[GetMaxVIPLevel() + 1]
			return m_BuyData.buytilicost.entertimes[#m_BuyData.buytilicost.entertimes]
	else
		return m_BuyData.buytilicost.entertimes[PlayerRole:Instance().m_VipLevel + 1] or 0
	end
end

local function GetTiLiRetrieve()
	local roleconfig = ConfigManager.getConfig("roleconfig")
	return roleconfig.buyaddtili.amount
end

local function GetMaxBuyTime()
	local roleconfig = ConfigManager.getConfig("roleconfig")
	local index = PlayerRole:Instance().m_VipLevel + 1
	if index > #roleconfig.buytilicost.entertimes then
		index = #roleconfig.buytilicost.entertimes
	end
	return roleconfig.buytilicost.entertimes[index]

end

local function GetRequireYuanBaoReset(m_SectionData)
	local EctypeSingle   = ConfigManager.getConfig("ectypesingle")
		-- printyellow("GetRequireYuanBaoReset")
		-- printt(m_SectionData)
	local time = GetUsedResetTimes(m_SectionData) + 1
	--printyellow("reset time",time)
	--printyellow("n----",#EctypeSingle.resetopencountlimit.amout)
	if time > #EctypeSingle.resetopencountlimit.amout then
		time = #EctypeSingle.resetopencountlimit.amout
	end

	return EctypeSingle.resetopencountlimit.amout[time]
end

local function GetRequireYuanBaoTiLi(m_SectionData)
	local roleconfig = ConfigManager.getConfig("roleconfig")
	-- printyellow("GetRequireYuanBaoTiLi")
	-- printt(roleconfig)
	local index = GetUsedBuyTimes(m_SectionData) + 1
	if index > #roleconfig.buytilicost.amout then
		index = #roleconfig.buytilicost.amout
	end

		return roleconfig.buytilicost.amout[index]

end

local function init()
end

return {
	GetMaxVIPLevel = GetMaxVIPLevel,
	GetUsedTimes = GetUsedTimes,
	GetMaxBuyTimes = GetMaxBuyTimes,
	GetUsedBuyTimes = GetUsedBuyTimes,
	GetUsedResetTimes = GetUsedResetTimes,
	GetMaxResetTimes = GetMaxResetTimes,
	isNotEnoughTiLi = isNotEnoughTiLi,
	isNotEnoughMultiTiLi = isNotEnoughMultiTiLi,
	GetTiLiRetrieve = GetTiLiRetrieve,
	GetRequireYuanBaoTiLi = GetRequireYuanBaoTiLi,
	GetRequireYuanBaoReset = GetRequireYuanBaoReset,
	GetMaxResNumCanSweep = GetMaxResNumCanSweep,

}
