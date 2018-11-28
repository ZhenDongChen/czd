local require = require
local unpack = unpack
local print = print
local format = string.format
local timeutils = require("common.timeutils")
local UIManager = require("uimanager")
local network = require("network")
local BonusManager = require("item.bonusmanager")
local ItemManager = require("item.itemmanager")
local CheckCmd = require("common.checkcmd")
local AttackCityManager = require("ui.activity.attackcity.attackcitymanager")
local EventHelper = UIEventListenerHelper

local gameObject
local name
local fields

-- 初始化奖励列表
local function InitRewardList()
	if fields.UIList_Rewards.Count == 0 then
		local data = ConfigManager.getConfig("attackcity")
		local roleLevel = PlayerRole:Instance():GetLevel()
		local rewardItems = nil
		for secIdx, section in ipairs(data.sections) do
			if roleLevel <= section.requirelevel.level then
				rewardItems = BonusManager.GetItemsOfSingleBonus(section.bonusids)
				break
			end
		end
		if not rewardItems then
			rewardItems = BonusManager.GetItemsOfSingleBonus(data.sections[1].bonusids)
		end
		for _, bonusItem in ipairs(rewardItems) do
			local listItem = fields.UIList_Rewards:AddListItem()
			BonusManager.SetRewardItem(listItem, bonusItem)
		end
	end
end

local function destroy()
	-- print(name, "destroy")
end

--local function showtab(params)
--	-- print(name,"showtab")
--	network.create_and_send("lx.gs.map.msg.CGetAttackCityInfo")
--end

local function show(params)
	-- print(name, "show")
	local data = ConfigManager.getConfig("attackcity")
	local validate, info = CheckCmd.CheckData( { data = data.requirelevel, num = 1, showsysteminfo = true })
	if not validate then
		fields.UISprite_Lock.gameObject:SetActive(true)
	else
		fields.UISprite_Lock.gameObject:SetActive(false)
	end
end

local function hide()
	-- print(name, "hide")
end

local function refresh(params)
	-- print(name, "refresh")
	local data = ConfigManager.getConfig("attackcity")
	fields.UITexture_ActivityBG:SetIconTexture(data.bgpic)
	local actOpenTime	= AttackCityManager.GetActOpenTime()
	local actEndTime	= AttackCityManager.GetActEndTime()
	local regBeginTime	= AttackCityManager.GetRegBeginTime()
	local regEndTime	= AttackCityManager.GetRegEndTime()
	
	-- 是否报名中
	local actStatus = AttackCityManager.GetActStatus()
	printyellow(">>>>>>>>>>actStatus,cfg.ectype.AttackCityStage.OPEN",actStatus,cfg.ectype.AttackCityStage.OPEN)
	local bHasRegistered = AttackCityManager.HasRegistered()

	local bIsRegisterTime = (actStatus == cfg.ectype.AttackCityStage.SIGNUP) and true or false
	fields.UILabel_ActivityInRegisterStatus.gameObject:SetActive(bIsRegisterTime)
	UITools.SetButtonEnabled(fields.UIButton_RegisterOrJoinIn,bIsRegisterTime and not bHasRegistered)
	if bHasRegistered then 
		fields.UILabel_ActivityStatus.text = LocalString.Activity_AttackCity_HasRegistered
	else
		fields.UILabel_ActivityStatus.text = LocalString.Activity_AttackCity_Register
	end

	-- 是否活动中
	local bIsOpenTime = (actStatus == cfg.ectype.AttackCityStage.OPEN) and true or false
	fields.UILabel_ActivityInOpenStatus.gameObject:SetActive(bIsOpenTime)
	if bIsOpenTime then
		UITools.SetButtonEnabled(fields.UIButton_RegisterOrJoinIn,bHasRegistered)
		fields.UILabel_ActivityStatus.text = bHasRegistered and LocalString.Activity_AttackCity_JoinIn or LocalString.Activity_AttackCity_NotRegister
	end

	-- 设定时间
	fields.UILabel_OpenTime.text = format(LocalString.Activity_AttackCity_Time, LocalString.WeekCapitalForm[actOpenTime.days], actOpenTime.hours, actOpenTime.minutes)
	fields.UILabel_EndTime.text = format(LocalString.Activity_AttackCity_Time, LocalString.WeekCapitalForm[actEndTime.days], actEndTime.hours, actEndTime.minutes)
	fields.UILabel_RegisterTime.text = format(LocalString.Activity_AttackCity_RegisterTime, LocalString.WeekCapitalForm[regBeginTime.days], regBeginTime.hours, regBeginTime.minutes,regEndTime.hours, regEndTime.minutes)
	-- 奖励列表
	InitRewardList()
end

local function update()
	-- print(name, "update")
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
	name, gameObject, fields = unpack(params)

	EventHelper.SetClick(fields.UIButton_RegisterOrJoinIn, function()
		local data = ConfigManager.getConfig("attackcity")
		local validate, info = CheckCmd.CheckData( { data = data.requirelevel, num = 1, showsysteminfo = true })
		if not validate then
			return 
		end
		if AttackCityManager.CanRegister() then
			-- 报名
			network.create_and_send("lx.gs.map.msg.CEnrollAttackCity")
		else
			-- 参加
			network.create_and_send("lx.gs.map.msg.CEnterAttackCity")
		end

	end )
	
	
	EventHelper.SetClick(fields.UIButton_Detail,function()
		
	    UIManager.show( "common.dlgdialogbox_complex", { 
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        fields.UILabel_Title.text = LocalString.City_War_Rule_Title
                        fields.UILabel_Content_Single.text = ConfigManager.getConfig("attackcity").Playintroduce
         end })

	end)

end

return {
	init			= init,
	show			= show,
	hide			= hide,
	update			= update,
	destroy			= destroy,
	refresh			= refresh,
	uishowtype		= uishowtype,
	--showtab			= showtab,
}

