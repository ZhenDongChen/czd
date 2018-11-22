local unpack = unpack
local print = print
local format = string.format
local ItemIntroduct = require("item.itemintroduction")
local ItemEnum = require("item.itemenum")
local WelfareManager = require("ui.welfare.welfaremanager")
local BonusManager = require("item.bonusmanager")
local EventHelper = UIEventListenerHelper
local uimanager = require "uimanager"
local network = require "network"
local os = require 'cfg.structs'
local create_datastream = create_datastream
local charactermanager = require "character.charactermanager"
local configmanager = require "cfg.configmanager"
local PlayerRole = require "character.playerrole"
local defineenum = require "defineenum"
local itemmanager = require "item.itemmanager"
local scenemanager = require "scenemanager"
local timeutils      = require("common.timeutils")
local gameObject
local name
local fields


local function pairsByTimeType(list)
    local key = { }
    local map = { }

    for timeType, bonusData in pairs(list) do
        key[#key + 1] = timeType
        map[timeType] = BonusManager.GetItemsOfSingleBonus(bonusData.bonuslist)
    end
    -- 默认升序
    table.sort(key)
    local i = 0
    return function()
        i = i + 1
        return key[i], map[key[i]]
    end
end
local function ShowDailyOnlinePage()
    local dailyOnlineData = WelfareManager.GetDailyOnlineData()
    local onlineBonus = ConfigManager.getConfig("onlinetimebonus")
    local listIndex = 0
	local bonusItems = { }
	
	local bCanGet = false
    for timeType, bonusItemList in pairsByTimeType(onlineBonus) do
        bonusItems[#bonusItems + 1] = bonusItemList

        local listItem = fields.UIList_Online:GetItemByIndex(listIndex)
        listItem:SetText("UILabel_Minute", format(LocalString.Welfare_Online_Minute, timeType / 60))
        listItem:SetIconTexture(bonusItemList[1]:GetTextureName())
		listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(bonusItemList[1]:GetQuality())
		listItem.Controls["UISprite_Fragment"].gameObject:SetActive(bonusItemList[1]:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
		listItem.Controls["UISprite_Binding"].gameObject:SetActive(bonusItemList[1]:IsBound())
		listItem.Controls["UILabel_Amount"].text = bonusItemList[1]:GetNumber()
        if not dailyOnlineData.bReceivedGift[timeType] then
            listItem:SetText("UILabel_ReceiveStatus", LocalString.Welfare_Online_NotReceived)
            listItem.Controls["UISprite_Select"].gameObject:SetActive(false)
            if dailyOnlineData.DailyOnlineSeconds >= timeType then
                bCanGet = true
            end
        else
            listItem:SetText("UILabel_ReceiveStatus", LocalString.Welfare_Online_HasReceived)
            listItem.Controls["UISprite_Select"].gameObject:SetActive(true)
        end
        listIndex = listIndex + 1
    end
	fields.UIButton_Receive02.isEnabled = bCanGet

    EventHelper.SetClick(fields.UIButton_Receive02, function()
        local times = { }
        local timeTypeList = dailyOnlineData.TimeTypeList
        for i = 1, #timeTypeList do
            if not dailyOnlineData.bReceivedGift[timeTypeList[i]] and dailyOnlineData.DailyOnlineSeconds >= timeTypeList[i] then
                times[#times + 1] = timeTypeList[i]
            end
        end

        if #times ~= 0 then
            local msg = lx.gs.bonus.msg.CGetOnlineGift( { gifttimetype = times })
            network.send(msg)
        end
    end)
	EventHelper.SetListClick(fields.UIList_Online, function(listItem)
		ItemIntroduct.DisplayBriefItem( {item = bonusItems[listItem.Index + 1][1]} )
	end)
	EventHelper.SetClick(fields.UIButton_Close, function()
		uimanager.hidedialog("welfare.dlgdailyonline")
	end)
end
local function second_update(now)
    -- print(name, "second_update")
    -- 判断每日在线是否可以领取奖励
    local dailyOnlineData = WelfareManager.GetDailyOnlineData()
    local timeTypeList = dailyOnlineData.TimeTypeList
    for i = 1, #timeTypeList do
        if not dailyOnlineData.bReceivedGift[timeTypeList[i]] and dailyOnlineData.DailyOnlineSeconds >= timeTypeList[i] then
            -- UITools.SetButtonEnabled(fields.UIButton_Receive02,true)
			fields.UIButton_Receive02.isEnabled = true
			break
        end
    end
    -- 显示每日在线数据
    local dateTime = timeutils.getDateTime(dailyOnlineData.DailyOnlineSeconds)
    fields.UILabel_OnlineTime.text = format(LocalString.Welfare_OnlineTime, dateTime.hours, dateTime.minutes, dateTime.seconds)
end


local function destroy()
end

local function show(params)
end

local function hide()
end

local function refresh(params)
	ShowDailyOnlinePage()
end

local function update()
end

local function init(params)
	name, gameObject, fields = unpack(params)
end

return {
    init = init,
    show = show,
    hide = hide,
	update = update,
	second_update = second_update,
    destroy = destroy,
    refresh = refresh,
    ShowDailyOnlinePage = ShowDailyOnlinePage,
}
