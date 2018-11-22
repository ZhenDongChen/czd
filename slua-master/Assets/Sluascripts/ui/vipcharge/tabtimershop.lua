local BonusManager = require("item.bonusmanager")
local UIManager = require("uimanager")
local ConfigManager  = require("cfg.configmanager")
local WelfareManager = require("ui.welfare.welfaremanager")
local VipChargeManager = require ("ui.vipcharge.vipchargemanager")
local network = require("network")
local TimeUtils = require("common.timeutils")
local EventHelper = UIEventListenerHelper
local BagManager = require("character.bagmanager")

local name, gameObject, fields
local tbGiftItems = {}
local curPageIdx = 1
local isNeedOpen = true --是否需要开启过
local slotMax = 15

local function CalcRemainTime(cfgItem, tsTimeNow)
    local tsTimeBegin = TimeUtils.GetTimestamp(cfgItem.datetime.begintime)
    local tsTimeEnd = TimeUtils.GetTimestamp(cfgItem.datetime.endtime)

    if cfgItem.Intervaltime==0 or cfgItem.Continuedtime==0 then
        --Intervaltime  间隔时间
        --Continuedtime  持续时间
        local remainSec = tsTimeEnd - tsTimeNow
        return remainSec
    end
    local durTime = cfgItem.Continuedtime*3600*24
    local cdTime = cfgItem.Intervaltime*3600*24
    local cycleTime = durTime+cdTime
    local modSecond = (tsTimeNow-tsTimeBegin)%cycleTime
    local remainTime = durTime-modSecond
    if remainTime<0 then remainTime=0 end
    return remainTime
end
local function InitData()
    local timeNow = TimeUtils.TimeNow()
    local vipShopCfg = ConfigManager.getConfig("timelimitgift")
    local TimerShopData = WelfareManager.GetTimerShop()
    local boughtRecords = TimerShopData.BoughtRecords
    local tsTimeNow = TimeUtils.GetServerTime()
    if TimerShopData.tbGiftState==nil then
        --记录礼包状态，cd结束后刷新次数
        TimerShopData.tbGiftState = {}
    end
    local tbGiftState = TimerShopData.tbGiftState
    tbGiftItems = {}
    for k, it in pairs(vipShopCfg) do
        local itRemainTime = CalcRemainTime(it, tsTimeNow)
        if itRemainTime>0 then
            local cdChange = false
            if tbGiftState[it.id]~=nil and tbGiftState[it.id]==0 then
                cdChange = true
            end
            local hasId = 0
            local minID = 1000000000
            local minBoun = nil
            local curTimes = 0
            for m, itBouns in pairs(it.bonus) do
                local tempId = it.id*100+itBouns.id
                local buyTimes = 0
                if boughtRecords[tempId]~=nil then
                    --重置次数
                    if cdChange then boughtRecords[tempId]=0 end
                    hasId = itBouns.id
                    buyTimes = boughtRecords[tempId]
                end
                if itBouns.id<minID and itBouns.id>=hasId then
                    if itBouns.limitnum==-1 then
                        if minID == 1000000000 then
                            minID = itBouns.id
                            minBoun = itBouns
                            curTimes = buyTimes
                        end
                    elseif itBouns.limitnum>0 and itBouns.limitnum>buyTimes then
                        minID = itBouns.id
                        minBoun = itBouns
                        curTimes = buyTimes
                    end
                end
            end
            if minBoun~=nil then
                local newPage = {
                   id=it.id,
                   range=it.range,
                   name=it.name,
                   desc=it.desc,
                   datetime=it.datetime,
                   remainSec=itRemainTime,
                   bonus=minBoun,
                   curTimes=curTimes,
                   maxTimes=minBoun.limitnum
                }
                table.insert(tbGiftItems, newPage)
            end
            tbGiftState[it.id] = 1
        else
            tbGiftState[it.id] = 0
        end
    end
    table.sort(tbGiftItems, function(item1, item2) return(item1.id < item2.id) end)
end
local function RefreshPage(pageIdx)
    local giftCount = #tbGiftItems
    if giftCount > 0 then
        curPageIdx = pageIdx
        print("RefreshPage "..pageIdx)
        if pageIdx == 1 then
            fields.UIButton_ArrowsLeft.gameObject:SetActive(false)
        else
            fields.UIButton_ArrowsLeft.gameObject:SetActive(true)
        end
        if pageIdx >= giftCount then
            fields.UIButton_ArrowsRight.gameObject:SetActive(false)
        else
            fields.UIButton_ArrowsRight.gameObject:SetActive(true)
        end
        fields.UITexture_BGLeft1.gameObject:SetActive(true)
        -- fields.UITexture_BGLeft2.gameObject:SetActive(true)
        fields.UIGroup_GiftBagBG.gameObject:SetActive(true)
        fields.UILabel_Empty.gameObject:SetActive(false)

        local gift = tbGiftItems[pageIdx].bonus
        if IsEditor then
            fields.UILabel_Title2.text = tbGiftItems[pageIdx].name.."_"..tostring(tbGiftItems[pageIdx].id*100+gift.id)
        else
            fields.UILabel_Title2.text = tbGiftItems[pageIdx].name
        end
        fields.UILabel_Desc.text = tbGiftItems[pageIdx].desc
        if gift.price < 10000 then
            -- xxx购买
            fields.UILabel_Price.text = gift.price..LocalString.TimerShop_BuyNum
        else
            fields.UILabel_Price.text = gift.price
        end
        local remainSec = tbGiftItems[pageIdx].remainSec
        local strRemain = TimeUtils.GetRemainTimeStr(remainSec, 1)
        fields.UILabel_LeftTime.text = LocalString.TimerShop_RemainTime..strRemain
        local strTestTimes = ""
        if IsEditor then
            strTestTimes = "("..tbGiftItems[pageIdx].curTimes.."/"..tbGiftItems[pageIdx].maxTimes..")"
        end
        if gift.limitnum==-1 then
            --"不限次数"
            fields.UILabel_LimitTime.text = LocalString.TimerShop_LimitTimes2..strTestTimes
        else
            fields.UILabel_LimitTime.text = string.format(LocalString.TimerShop_LimitTimes1, gift.limitnum)..strTestTimes
        end
        if remainSec>0 then
            if gift.limitnum>0 and tbGiftItems[pageIdx].curTimes>=tbGiftItems[pageIdx].maxTimes then
                fields.UIButton_Buy.isEnabled = false
            else
                fields.UIButton_Buy.isEnabled = true
            end
        else
            fields.UIButton_Buy.isEnabled = false
        end

        local gainbonus = BonusManager.GetItemsByBonusConfig(gift.bonus)
        local baseCount = slotMax
        if fields.UIList_Bag.Count == 0 then
            for i=1, baseCount do
                local list_item = fields.UIList_Bag:AddListItem()
                --BonusManager.SetRewardItem(list_item,bonus)
            end
        end
		local bagWrapContent = fields.UIList_Bag.gameObject:GetComponent("UIGridWrapContent")
        --SortAlphabetically  SortBasedOnScrollMovement WrapContent
        -- bagWrapContent:SortBasedOnScrollMovement()
        bagWrapContent.minIndex = -(baseCount / 4) + 1
        bagWrapContent.maxIndex = 0
		EventHelper.SetWrapContentItemInit(bagWrapContent, function(go, index, realIndex)
            local uiItem = go:GetComponent("UIListItem")
            if gainbonus[index+1]~=nil then
                BonusManager.SetRewardItem(uiItem, gainbonus[index+1])
                uiItem.Controls["UIGroup_Slots"].gameObject:SetActive(true);
                uiItem.Controls["UISprite_BoxBG"].gameObject:SetActive(true);
                --print("setItem:"..go.name.."  hasbonus idx:"..index.." realidx:"..realIndex)
            else
                --print("setItem:"..go.name.."  nil idx:"..index.." realidx:"..realIndex)
                BagManager.ResetBagSlot(uiItem)
                uiItem.Controls["UIGroup_Slots"].gameObject:SetActive(false);
                uiItem.Controls["UISprite_BoxBG"].gameObject:SetActive(false);
            end
            --uiItem:SetText("UILabel_Amount", tostring(pageIdx*1000+index))
        end)
        bagWrapContent.firstTime = true
        bagWrapContent:WrapContent()
    else
        fields.UIButton_ArrowsLeft.gameObject:SetActive(false)
        fields.UIButton_ArrowsRight.gameObject:SetActive(false)
        fields.UITexture_BGLeft1.gameObject:SetActive(false)
        -- fields.UITexture_BGLeft2.gameObject:SetActive(false)
        fields.UIGroup_GiftBagBG.gameObject:SetActive(false)
        fields.UILabel_Empty.gameObject:SetActive(true)
    end
end
local function OnGetTimeLimitBonus(msg)
    print("OnGetTimeLimitBonus id:"..msg.giftid.." type"..msg.gifttype)
    for k, it in pairs(tbGiftItems) do
        if it.id==msg.giftid then
            it.curTimes = it.curTimes+1
            if it.maxTimes>0 and it.curTimes>=it.maxTimes then
                InitData()
            end
            if curPageIdx==k then
                RefreshPage(curPageIdx)
            end
            break
        end
    end
end

local function refresh(params)
end

local function hide()
end

local function update()
end

local function destroy()
end

local function show(params)
    if #tbGiftItems==0 then
        InitData()
    end
    RefreshPage(1)
    fields.UITexture_LeftDisCount.gameObject:SetActive(false)
    isNeedOpen = false
    if UIManager.needrefresh("dlgdialog") then
        UIManager.call("dlgdialog","RefreshRedDot","operationactivity.dlgoperationactivity")
    end
end

local function uishowtype()
	return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)
    if #tbGiftItems==0 then
        InitData()
    end

    EventHelper.SetClick(fields.UIButton_Buy, function()
        if curPageIdx>0 and curPageIdx<=#tbGiftItems then
            local giftId = tbGiftItems[curPageIdx].id
            local giftTypeId = tbGiftItems[curPageIdx].bonus.id
            local giftPrice = tbGiftItems[curPageIdx].bonus.price
            UIManager.ShowAlertDlg({
                immediate    = true,
                content      = string.format(LocalString.TimerShop_BuyConfirm, giftPrice),
                callBackFunc = function()
                    local msg = lx.gs.bonus.msg.CGetTimeLimitBonus( { giftid=giftId, gifttype=giftTypeId })
                    network.send(msg)
                end,
                callBackFunc1 = function()
                end,   
            })
        end
    end)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, function()
        local timeNow = TimeUtils.TimeNow()
        local str1 = string.format("curTime:%04d%02d%02d_%02d%02d%02d", timeNow.year, timeNow.month, timeNow.day, timeNow.hour, timeNow.min, timeNow.sec)
        print(str1)

        if curPageIdx>1 then
            RefreshPage(curPageIdx-1)
        else
        end
    end)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, function()
        if curPageIdx<#tbGiftItems then
            RefreshPage(curPageIdx+1)
        else
        end
    end)
end

local function UnRead()
    return isNeedOpen
end

return {
    init = init,
    show = show,
    refresh = refresh,
    update = update,
    hide = hide,
    uishowtype = uishowtype,
    destroy = destroy,
    OnGetTimeLimitBonus = OnGetTimeLimitBonus,
    UnRead = UnRead,
}
