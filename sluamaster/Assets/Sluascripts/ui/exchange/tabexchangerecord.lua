local Unpack = unpack
local Math = math
local EventHelper = UIEventListenerHelper
local ItemManager = require("item.itemmanager")
local BonusManager = require("item.bonusmanager")
local ExchangeManager = require("ui.exchange.exchangemanager")
local PlayerRole = require("character.playerrole"):Instance()

local LogSortWay = enum
{
    "Time = 0",
    "Money = 1",
}

local m_GameObject
local m_Name
local m_Fields
local m_SortOrder  --排序顺序
local m_LogSortType = LogSortWay.Time  --交易记录排序方式:0、购买时间 1、获得金额
local m_Logs = {}

local function destroy()
end

local function show(params)
end

local function hide()
end

local function update()
end

local function SetSortOrd(sortType)   
    if (m_LogSortType ~= sortType) then
        m_LogSortType = sortType
        m_SortOrder = cfg.exchange.SortOrder.ASC
    else
        if m_SortOrder == cfg.exchange.SortOrder.ASC then
            m_SortOrder = cfg.exchange.SortOrder.DESC    
        elseif m_SortOrder == cfg.exchange.SortOrder.DESC then
            m_SortOrder = cfg.exchange.SortOrder.ASC
        else
            m_SortOrder = cfg.exchange.SortOrder.ASC
        end
    end    
end

local function DisplayOneLog(recordItem,exchangeLog)
    local UILabel_Time = recordItem.Controls["UILabel_Time"]
    local exchangeTime = os.date("%Y-%m-%d %H:%M:%S",(exchangeLog.time/1000))
    UILabel_Time.text = exchangeTime
    local buyerId = exchangeLog.buyer
    local UILabel_PlayerName = recordItem.Controls["UILabel_Buyer"]
    local UILabel_TotalPrice = recordItem.Controls["UILabel_Pricet"]
    local UILabel_Name = recordItem.Controls["UILabel_Name"]
    local totalPrice = (exchangeLog.item.aprice)*(exchangeLog.item.num)
    if PlayerRole:Instance():GetId() == buyerId then
        UILabel_PlayerName.text = LocalString.Exchange_You
        UILabel_TotalPrice.text = "-" .. totalPrice 
    else
        UILabel_PlayerName.text = exchangeLog.buyername
        UILabel_TotalPrice.text = totalPrice    
    end
    local item = ItemManager.CreateItemBaseById(exchangeLog.item.itemid,exchangeLog.item,exchangeLog.item.num)
    if item then
        local UILabel_Name = recordItem.Controls["UILabel_Name"]
        UILabel_Name.text = item:GetName()
        BonusManager.SetRewardItem(recordItem,item)
    end
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem == nil then
        return
    end
    local num = #m_Logs
    local log = m_Logs[realIndex]
    if UIListItem then
        DisplayOneLog(UIListItem,log)
    end
end

local function InitList(num)
    local wrapList = m_Fields.UIList_Records.gameObject:GetComponent("UIWrapContentList")
    if wrapList == nil then
        return
    end
    if (num == 0) then
        m_Fields.UILabel_Empty.text = LocalString.Exchange_RecordNull
        m_Fields.UILabel_Empty.gameObject:SetActive(true)
    else
        m_Fields.UILabel_Empty.gameObject:SetActive(false)
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-0.45)
end

local function DisplayExchangeLogs()
    m_Fields.UISprite_UpTime.gameObject:SetActive((m_LogSortType == LogSortWay.Time) and (m_SortOrder == cfg.exchange.SortOrder.ASC))
    m_Fields.UISprite_DownTime.gameObject:SetActive((m_LogSortType == LogSortWay.Time) and (m_SortOrder == cfg.exchange.SortOrder.DESC))
    m_Fields.UISprite_UpMoney.gameObject:SetActive((m_LogSortType == LogSortWay.Money) and (m_SortOrder == cfg.exchange.SortOrder.ASC))
    m_Fields.UISprite_DownMoney.gameObject:SetActive((m_LogSortType == LogSortWay.Money) and (m_SortOrder == cfg.exchange.SortOrder.DESC))
    m_Logs = ExchangeManager.GetExchangeLogsList()
    local displayNum = Math.min(#(m_Logs),cfg.exchange.Const.MAX_EXCHANGE_SHOW_LOG_NUM)
    InitList(displayNum)
    EventHelper.SetClick(m_Fields.UIButton_Buytime,function()   
        SetSortOrd(LogSortWay.Time)
        ExchangeManager.SortExchangeLog(m_LogSortType,m_SortOrder)        
        DisplayExchangeLogs()    
    end)
    EventHelper.SetClick(m_Fields.UIButton_Money,function()   
        SetSortOrd(LogSortWay.Money)
        ExchangeManager.SortExchangeLog(m_LogSortType,m_SortOrder)        
        DisplayExchangeLogs()    
    end)
end

local function refresh(params)
    DisplayExchangeLogs()
    ExchangeManager.ClearNewLog()
end

local function init(params)
    m_Name, m_GameObject, m_Fields = Unpack(params)   
    m_LogSortType = LogSortWay.Time
    m_SortOrder = cfg.exchange.SortOrder.ASC 
    ExchangeManager.SortExchangeLog(m_LogSortType,m_SortOrder)   
end

local function uishowtype()
    return UIShowType.Refresh
end

return{
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
}