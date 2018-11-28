local NetWork = require "network"
local UIManager=require "uimanager"
local Utils=require "common.utils"

local m_SoldItems={}
local m_ExchangeLogs={}
local m_PurchseItems={}
local m_NewLogList={}

local function update()
end

local function SendCAddItem(params)
    local msg=lx.gs.exchange.msg.CAddItem({bagtype=params.bagType,pos=params.bagPos,num=params.num,aprice=params.unitPrice})
    NetWork.send(msg)
end

local function SendCQuery(params)
    local msg=lx.gs.exchange.msg.CQuery({name=params.name,category=params.category,orderby=params.orderby,sortorder=params.sortorder,startindex=params.startindex,endindex=params.endindex})
    NetWork.send(msg)
end

local function SendCBuy(params)
    local msg=lx.gs.exchange.msg.CBuy({exchangeid=params.exchangeId,num=params.num})
    NetWork.send(msg)
end

local function SendCDelItem(params)
    local msg=lx.gs.exchange.msg.CDelItem({exchangeid=params.exchangeId})
    NetWork.send(msg)
end

local function OnMsg_SQuery(msg)
    if UIManager.isshow("exchange.tabexchangebuy") then
        UIManager.call("exchange.tabexchangebuy","RefreshQueryResult",msg)
    end
end

local function OnMsg_SInfo(msg)
    m_SoldItems=msg.items
    m_ExchangeLogs=msg.logs
end

local function OnMsg_SAddItem(msg)
    if UIManager.isshow("dlgalert_equipment") then
        UIManager.hide("dlgalert_equipment")
    end
    m_SoldItems[#(m_SoldItems)+1]=msg.item
    if UIManager.isshow("exchange.tabexchangesell") then
        UIManager.call("exchange.tabexchangesell","DisplayShelfGoods")
    end
end

local function OnMsg_SDelItem(msg)
    if UIManager.isshow("dlgalert_equipment") then
        UIManager.hide("dlgalert_equipment")
    end
    for i=1,#m_SoldItems do
        if m_SoldItems[i].id==msg.exchangeid then
            table.remove(m_SoldItems,i)
            break
        end
    end
    if UIManager.isshow("exchange.tabexchangesell") then
        UIManager.call("exchange.tabexchangesell","DisplayShelfGoods")
    end
end

local function OnMsg_SBuy(msg)
    if UIManager.isshow("exchange.tabexchangebuy") then
        UIManager.call("exchange.tabexchangebuy","QueryCurrentItems")
    end
end

local function OnMsg_SBuyByOther(msg)
    for i=1,#m_SoldItems do
        if m_SoldItems[i].id == msg.exchangeid then
            if msg.remainnum == 0 then
                table.remove(m_SoldItems,i)
                break
            else
                m_SoldItems[i] = msg.remainnum
            end
        end
    end
    if UIManager.isshow("exchange.tabexchangesell") then
        UIManager.call("exchange.tabexchangesell","DisplayShelfGoods")
    end
end

local function OnMsg_SNewLog(msg)
    m_ExchangeLogs[#m_ExchangeLogs+1]=msg.log
    --local exchangeDlg=require "ui.dlgexchange"
    --exchangeDlg.DisplayExchangeLogs()
    if UIManager.isshow("exchange.tabexchangerecord") then
        UIManager.call("exchange.tabexchangerecord","refresh")
    end
    table.insert(m_NewLogList,msg.log)
    UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.EXCHANGE)
end

local function OnMsg_SExceedNotify(msg)
    UIManager.ShowSingleAlertDlg({content = msg.notify})
end

local function SortExchangeLog(sortType,sortOrder)
    if sortType==0 then  --购买时间
        if sortOrder==cfg.exchange.SortOrder.ASC then
            Utils.table_sort(m_ExchangeLogs,function(a,b) return a.time>b.time end )
        elseif sortOrder==cfg.exchange.SortOrder.DESC then
            Utils.table_sort(m_ExchangeLogs,function(a,b) return a.time<b.time end )
        end
    elseif sortType==1 then   --交易金额
        if sortOrder==cfg.exchange.SortOrder.ASC then
            Utils.table_sort(m_ExchangeLogs,function(a,b) return (a.item.aprice*a.item.num)>(b.item.aprice*b.item.num) end )
        elseif sortOrder==cfg.exchange.SortOrder.DESC then
            Utils.table_sort(m_ExchangeLogs,function(a,b) return (a.item.aprice*a.item.num)<(b.item.aprice*b.item.num) end )
        end
    end
end

local function GetExchangeLogsList()
    return m_ExchangeLogs
end

local function GetShelfGoodsList()
    return m_SoldItems
end

local function IsShelfGood(exchangeId)
    local isShelf=false
    for _,item in pairs(m_SoldItems) do
        if item.id==exchangeId then
            isShelf=true
            break
        end
    end
    return isShelf
end

local function JudgeOpenLevel()
    local opened=false
    local info=""
    local PlayerRole=require("character.playerrole"):Instance()
    if PlayerRole:GetLevel()>=cfg.exchange.Const.OPEN_LEVEL then
        opened=true
    else
        info=string.format(LocalString.OpenLevelLimit,cfg.exchange.Const.OPEN_LEVEL)
    end
    return opened,info
end

local function CanExchange(selectedItem)
    local validate=true
    if not selectedItem:IsBound() then
        if selectedItem:GetConfigId() then
            local exchangeData = ConfigManager.getConfigData("exchange", selectedItem:GetConfigId())
            if exchangeData==nil then
                validate=false               
            end
        end
    else
        validate=false
    end
    return validate
end

local function init()
    NetWork.add_listeners({
        {"lx.gs.exchange.msg.SAddItem",OnMsg_SAddItem},
        {"lx.gs.exchange.msg.SDelItem",OnMsg_SDelItem},
        {"lx.gs.exchange.msg.SBuy",OnMsg_SBuy},
        {"lx.gs.exchange.msg.SBuyByOther",OnMsg_SBuyByOther},
        {"lx.gs.exchange.msg.SNewLog",OnMsg_SNewLog},
        {"lx.gs.exchange.msg.SInfo",OnMsg_SInfo},
        {"lx.gs.exchange.msg.SQuery",OnMsg_SQuery},
        {"lx.gs.exchange.msg.SExceedNotify",OnMsg_SExceedNotify},
    })
end

local function UnRead()
    return (#m_NewLogList>0)
end

local function ClearNewLog()
    m_NewLogList={}
    UIManager.call("dlgmain_open","RefreshRedDot",cfg.ui.FunctionList.EXCHANGE)
end

return {
    init = init,
    update = update,
    SendCAddItem=SendCAddItem,
    SendCQuery=SendCQuery,
    SendCBuy=SendCBuy,
    SendCDelItem=SendCDelItem,
    GetExchangeLogsList=GetExchangeLogsList,
    GetShelfGoodsList=GetShelfGoodsList,
    SortExchangeLog=SortExchangeLog,
    OnMsg_SInfo=OnMsg_SInfo,
    JudgeOpenLevel=JudgeOpenLevel,
    IsShelfGood=IsShelfGood,
    ClearNewLog=ClearNewLog,
    UnRead=UnRead,
    CanExchange = CanExchange,
}

