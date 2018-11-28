local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local PlayerRole            = require "character.playerrole"
local WelfareManager        = require ("ui.welfare.welfaremanager")
local bonusmgr = require("item.bonusmanager")
local network        = require("network")
local ColorUtil             = require("common.colorutil")
local name
local gameObject
local fields
local RewardData = nil
local notReceive = true
local labelTimes = 0

local function refresh()
     if labelTimes > 0 then
        fields.UILabel_Distance.gameObject:SetActive(true)
        fields.UILabel_AwardTime.gameObject:SetActive(true)
        fields.UILabel_AwardTime.text = timeutils.getDateTimeString(labelTimes,"hh:mm:ss")
        fields.UIButton_Get.isEnabled = false
    else
        fields.UILabel_Distance.gameObject:SetActive(false)
        fields.UILabel_AwardTime.gameObject:SetActive(false)
        fields.UIButton_Get.isEnabled = true
    end
end

local function update()

end

local function second_update(now)
    if labelTimes > 0 then
        labelTimes = labelTimes -1
        UIManager.refresh(name)
    end
end

local function getlabelTimes()
    return labelTimes
end

local function hide()

end

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end

local function GetShowData()
    RewardData = WelfareManager.GetNewPlayerGiftData()
    for i=1,#RewardData.ReceivedDays do
        if RewardData.ReceivedDays[i] == 2 then
            notReceive = false
        end
    end
    if notReceive then
        if RewardData.LoginDays < 2  then
            local nowTime = timeutils.TimeNow()
            local nowTimeSecs = nowTime.hour *3600 + nowTime.min *60 + nowTime.sec
            labelTimes = 3600*24 - nowTimeSecs
        end
    end
    return notReceive
end

local function show()
    if notReceive then
        local items = bonusmgr.GetItemsOfBonus( { bonustype = "cfg.bonus.BeginnerBonus", csvid = 2 })
        for i=1,#items do
            local item = fields.UIList_rewards:GetItemByIndex(i-1)
            if item then
                item.gameObject:SetActive(true)
                ColorUtil.SetQualityColorText(item.Controls["UILabel_AwardLable"],items[i].ConfigData.quality,items[i].ConfigData.name)
                ColorUtil.SetQualityColorText(item.Controls["UILabel_AwardName"],items[i].ConfigData.quality,(items[i].ConfigData.displayitemtype or ""))
                bonusmgr.SetRewardItem(item, items[i])
            end
        end
        if labelTimes > 0 then
            fields.UIButton_Get.isEnabled = false
        end
    end
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    RewardData = WelfareManager.GetNewPlayerGiftData()
    GetShowData()
    EventHelper.SetClick(fields.UIButton_Close,function()
        UIManager.showmaincitydlgs()
        UIManager.hide(name)
    end)

    EventHelper.SetClick(fields.UIButton_Get,function()
        local msg = lx.gs.bonus.msg.CNewGift( { newgiftid = 2 })
        network.send(msg)
        notReceive = false
        UIManager.showmaincitydlgs()
        UIManager.hide(name)
    end)

end

return{
    show = show,
    init = init,
	hide = hide,
    update = update,
    second_update = second_update,
    refresh = refresh,
    getlabelTimes = getlabelTimes,
    GetShowData = GetShowData,
	uishowtype = uishowtype,
}