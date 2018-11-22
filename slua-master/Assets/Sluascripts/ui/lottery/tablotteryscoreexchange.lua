--local tablotteryscoreexchange  = require "ui.lottery.tablotteryscoreexchange"
local unpack         = unpack
local print          = print
local EventHelper    = UIEventListenerHelper
local uimanager      = require("uimanager")
local network        = require("network")
local lotterymanager = require "ui.lottery.lotterymanager"
local PlayerRole     = require "character.playerrole"
local LimitManager   = require("limittimemanager")

local ItemEnum 		 = require("item.itemenum")
local ItemManager    = require("item.itemmanager")

local gameObject
local name
local fields

local dialogname = "lottery.dlglottery"
local tabname = "lottery.tablotteryscoreexchange"

local LotteryTextures = {}
local GradeExchanges = {}
local exchangelist
local exchangetype



--刷新金币、积分
local function RefreshMoney()
    if uimanager.isshow(name) then
        local recievedcurrencytype = fields.UIList_ShopSelect:GetSelectedItem().Id
        fields.UILabel_ShopTitle.text = string.format(LocalString.DlgLottery_Shop ,LotteryTextures[recievedcurrencytype].name,PlayerRole:Instance():GetCurrency(recievedcurrencytype))
    end
end

local function OnItemInit(go, wrapIndex, realIndex)
    --printyellow("OnItemInit go=>",go, "wrapIndex=>", wrapIndex,"realIndex=>", realIndex)
    if go == nil then
        return
    end
    local item = go:GetComponent("UIListItem")
    if realIndex < 0 then
        realIndex = -realIndex
    end
    local infoIndex = realIndex + 1
    local exchange = exchangelist[infoIndex]
    local recievedcurrencytype = fields.UIList_ShopSelect:GetSelectedItem().Id

    if item  then
        if exchange then
			item.Controls["UISprite_Binding"].gameObject:SetActive((exchange.Item.ConfigData.bindtype ~= cfg.item.EItemBindType.NOT_BOUND))
            item.Id    = exchange.Id
            item.Data  = exchange.Data
            local buyNum = exchange.Data.daylimit.num - LimitManager.GetDayLimitTime(lotterymanager.GetLimitType(exchangetype),exchange.Id)
            item:SetText("UILabel_Amount1",string.format(LocalString.DlgLottery_Shop ,LotteryTextures[recievedcurrencytype].name,exchange.Data.requirecurrency.amount))
            item:SetText("UILabel_Description",exchange.Data.desc)
            item.Controls["UITexture_Icon"]:SetIconTexture(exchange.Item:GetIconPath())
            colorutil.SetQualityColorText(item.Controls["UILabel_Name"],exchange.Item:GetQuality(),exchange.Item:GetName())
            item:SetText("UILabel_Amount",string.format("X%s",exchange.Item:GetNumber()))
            item:SetText("UILabel_Amount2",buyNum)
            item.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(exchange.Item:GetQuality())
		    item.Controls["UISprite_Fragment"].gameObject:SetActive(exchange.Item:GetBaseType() == ItemEnum.ItemBaseType.Fragment)
            if buyNum <= 0 then 
                item.Controls["UIButton_Buy"].isEnabled = false
            else
                item.Controls["UIButton_Buy"].isEnabled = true
            end
            local UIButton_Buy = item.Controls["UIButton_Buy"]
            EventHelper.SetClick(UIButton_Buy, function()
                lotterymanager.CScoreExchange(exchangetype,item.Id)
            end )
        end
        go:SetActive(exchange ~= nil)
    end
end



--刷新兑换页面
local function RefreshShopSelect()
    local currencytype = fields.UIList_ShopSelect:GetSelectedItem().Id
    exchangelist =  GradeExchanges[currencytype].exchangelist
    exchangetype = GradeExchanges[currencytype].exchangetype
    if exchangelist then
        UIHelper.ResetItemNumberOfUIList(fields.UIList_Shop, #exchangelist)
        wrapContent = fields.UIList_Shop.gameObject:GetComponent("UIWrapContent")
        if wrapContent == nil then
            -- printyellow("Can't Find")
        end
        wrapContent.enabled = false
        --wrapContent.itemSize = 70
        wrapContent.minIndex = -#exchangelist +1
        wrapContent.maxIndex = 0
        EventHelper.SetWrapContentItemInit(wrapContent,OnItemInit)
        wrapContent.enabled = true
        --wrapContent:SortBasedOnScrollMovement();
--        printyellow("=======================")
--        printyellow(wrapContent)
        --printyellow(wrapContent.WrapContent)
        wrapContent:SortBasedOnScrollMovement()
        wrapContent:WrapContent()
    end
    RefreshMoney()
end



local function destroy()
    -- print(name, "destroy")
end

local function show(params)
    -- print(name, "show")
    fields.UIList_ShopSelect:Clear()
    local orderlotterytextures = {}
    for _,data in pairs(LotteryTextures) do
        orderlotterytextures[data.order] = data
    end

    for _,data in ipairs(orderlotterytextures) do
        local item = fields.UIList_ShopSelect:AddListItem()
        item:SetText("UILabel_Main",data.name)
        item:SetIconTexture(data.exchangeicon)
        item.Id = data.recievedcurrency
    end


    fields.UIList_ShopSelect:SetSelectedIndex(0)
end

local function hide()
    -- print(name, "hide")
end

local function showtab(params)
    -- print(name, "show")
    uimanager.show(tabname,params)
end



local function refresh(params)
    -- print(name, "refresh")
    RefreshShopSelect()
    --RefreshMoney()
end

local function update()
    -- print(name, "update")
end


local function init(params)
    name, gameObject, fields = unpack(params)
    print(name, "init")

    LotteryTextures = lotterymanager.GetLotteryTextures()
    GradeExchanges = lotterymanager.GetGradeExchanges()

    EventHelper.SetListSelect(fields.UIList_ShopSelect, function(item)
        RefreshShopSelect(item.Id)
    end )
end


--不写此函数 默认为 UIShowType.Default
local function uishowtype()
    --return UIShowType.Default
    --return UIShowType.ShowImmediate--强制在showtab页时 不回调showtab
    return UIShowType.Refresh  --强制在切换tab页时回调show
    --return bit.bor(UIShowType.ShowImmediate,UIShowType.Refresh)
end



return {
    init            = init,
    show            = show,
    hide            = hide,
    update          = update,
    destroy         = destroy,
    refresh         = refresh,
    showtab         = showtab,
    RefreshMoney    = RefreshMoney,
    uishowtype      = uishowtype,
}
