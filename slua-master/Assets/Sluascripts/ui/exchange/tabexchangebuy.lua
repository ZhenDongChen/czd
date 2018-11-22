local Unpack = unpack
local EventHelper = UIEventListenerHelper
local NetWork = require("network")
local UIManager = require("uimanager")
local CfgMgr = require "cfg.configmanager"
local ItemManager = require "item.itemmanager"
local ItemIntroduct = require("item.itemintroduction")
local ExchangeMgr = require"ui.exchange.exchangemanager"
local PlayerRole = require ("character.playerrole"):Instance()

local gameObject
local name
local fields
local m_NumOfPage  --每页显示数量
local m_PurchasedItems={}
local m_CurPurchasePage=0  --当前购买页码
local m_TotalPage=0   --总页数
local m_Category=nil   --当前目录
local m_KeyWord=""
local m_FirstLoad=true
local m_BuyItemId=-1    --当前购买物品id
local m_SelectEquip=true  --当前选择的装备
local m_SelectFrag=true   --当前选择的碎片
local m_BuySortType
local m_SortOrder  --排序顺序
local m_LogSortType=-1  --交易记录排序方式:1、购买时间 2、获得金额

local function destroy()
end

local function show(params)
    fields.UIInput_ItemName.characterLimit = 15 -- 输入框最大限制 
end

local function hide()
end



local function QueryItems(name,category,orderBy,sortOrder,startIndex,endIndex)
    local params={name=name,category=category,orderby=orderBy,sortorder=sortOrder,startindex=startIndex,endindex=endIndex}
    ExchangeMgr.SendCQuery(params)
end

local function QueryDefalutItems()
    QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,0,m_NumOfPage-1)
end

local function QueryCurrentItems()
    local startIndex=0
    local endIndex=0
    if m_CurPurchasePage==0 then
        startIndex=0
        endIndex=m_NumOfPage-1
    else
        if (m_PurchasedItems) and (#(m_PurchasedItems)==1) then
            startIndex = (m_CurPurchasePage-2)*m_NumOfPage
            endIndex = (m_CurPurchasePage-1)*m_NumOfPage-1
        else
            startIndex=(m_CurPurchasePage-1)*m_NumOfPage
            endIndex= (m_CurPurchasePage)*m_NumOfPage-1
        end
    end
    if startIndex<0 then
        startIndex=0
        endIndex=m_NumOfPage-1
    end
    QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,startIndex,endIndex)
end

local function GetSubCategory(name)
    local subCategorys={}
    local categoryData=CfgMgr.getConfig("exchangeindex")
    for i=1,#categoryData do
        if categoryData[i].parentindex==name then
            table.insert(subCategorys,categoryData[i])
        end
    end
    return subCategorys
end

local function LoadCategory()
    fields.UIList_Parent:Clear()
    local categoryData=CfgMgr.getConfig("exchangeindex")
    for i=1,#categoryData do
        if categoryData[i].parentindex==cfg.exchange.Category.NULL then
            --printyellow("i:",i)
            local parentItem=fields.UIList_Parent:AddListItem()
            parentItem.Data=categoryData[i]
            local UILabel_Main=parentItem.Controls["UILabel_Main"]
            UILabel_Main.text=categoryData[i].displayname
            local subCategorys=GetSubCategory(categoryData[i].name)
            --printyellow("subCategory.count:",#subCategorys)
            local UISprite_Add=parentItem.Controls["UISprite_Add"]
            local UISprite_Minus=parentItem.Controls["UISprite_Minus"]
            UISprite_Add.gameObject:SetActive(not(#subCategorys==0))
            UISprite_Minus.gameObject:SetActive(not(#subCategorys==0))
            if #subCategorys==0 then
                EventHelper.SetClick(parentItem,function()
                    local category=categoryData[i].name
                    m_KeyWord=""
                    m_Category=category
                    QueryDefalutItems()
                end)
            else
                parentItem.Id=0
                EventHelper.SetClick(parentItem,function()
--                    parentItem.Id=(1-parentItem.Id)
--                    UISprite_Add.gameObject:SetActive(parentItem.Id==0)
--                    UISprite_Minus.gameObject:SetActive(parentItem.Id==1)
--                    m_KeyWord=""
--                    local category=categoryData[i].name
--                    m_Category=category
--                    QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,0,m_NumOfPage-1)
                end)
                local UIList_Classification=parentItem.Controls["UIList_Classification"]
                for j=1,#subCategorys do
                    local UIListItem_SubCategory=UIList_Classification:AddListItem()
                    local UILabel_SubName=UIListItem_SubCategory.Controls["UILabel_SubName"]
                    UILabel_SubName.text=subCategorys[j].displayname
                    UIListItem_SubCategory.Data=subCategorys[j]
                    EventHelper.SetClick(UIListItem_SubCategory,function()
                        local category=subCategorys[j].name
                        m_KeyWord=""
                        m_Category=category
                        QueryDefalutItems()
                    end)
                end
            end
        end
    end
    -- fields.UIList_Parent:SetSelectedIndex(0)
end

local function SetBuySortWay()
    fields.UISprite_UpLevel.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.LEVEL) and (m_SortOrder==cfg.exchange.SortOrder.ASC))
    fields.UISprite_DownLevel.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.LEVEL) and (m_SortOrder==cfg.exchange.SortOrder.DESC))
    fields.UISprite_UpPrice.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.APRICE) and (m_SortOrder==cfg.exchange.SortOrder.ASC))
    fields.UISprite_DownPrice.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.APRICE) and (m_SortOrder==cfg.exchange.SortOrder.DESC))
    fields.UISprite_UpAllPrice.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.TOTAL_PRICE) and (m_SortOrder==cfg.exchange.SortOrder.ASC))
    fields.UISprite_DownAllPrice.gameObject:SetActive((m_BuySortType==cfg.exchange.OrderByType.TOTAL_PRICE) and (m_SortOrder==cfg.exchange.SortOrder.DESC))
    fields.UISprite_UpLevel:GetComponent("UISprite").alpha = 1
    fields.UISprite_DownLevel:GetComponent("UISprite").alpha = 1
    fields.UISprite_UpPrice:GetComponent("UISprite").alpha = 1
    fields.UISprite_DownPrice:GetComponent("UISprite").alpha = 1
    fields.UISprite_UpAllPrice:GetComponent("UISprite").alpha = 1
    fields.UISprite_DownAllPrice:GetComponent("UISprite").alpha = 1
end

local function LoadPurchaseDlg()
    QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,0,m_NumOfPage-1)
    if m_FirstLoad then
        LoadCategory()
        m_FirstLoad=false
    end
    SetBuySortWay()
end

local function Buy(params)
    local param={exchangeId=m_BuyItemId,num=params.num}
    ExchangeMgr.SendCBuy(param)
end

local function SetSortOrd(isBuy,sortType)
    if (isBuy and m_BuySortType~=sortType) or ((not isBuy) and (m_LogSortType~=sortType)) then
        if isBuy then
            m_BuySortType=sortType
        else
            m_LogSortType=sortType
            m_SortOrder=cfg.exchange.SortOrder.ASC
        end
    else
        if m_SortOrder==cfg.exchange.SortOrder.ASC then
            m_SortOrder=cfg.exchange.SortOrder.DESC
        elseif m_SortOrder==cfg.exchange.SortOrder.DESC then
            m_SortOrder=cfg.exchange.SortOrder.ASC
        else
            m_SortOrder=cfg.exchange.SortOrder.ASC
        end
    end
end

local function IsFragMent(itemId)
    local itemData=CfgMgr.getConfigData("fragment",itemId)
    if itemData then
        return true
    end
    return false
end

local function DisplayPurchaseDlg()
    fields.UIList_Goods:Clear()
    if (#(m_PurchasedItems)==0) then
        fields.UILabel_Empty.text=LocalString.Exchange_BuyGoodsNull
        fields.UILabel_Empty.gameObject:SetActive(true)
    else
        fields.UILabel_Empty.gameObject:SetActive(false)
        for i=1,#(m_PurchasedItems) do
            local itemType=IsFragMent(m_PurchasedItems[i].itemid)
            if (itemType and m_SelectFrag) or ((not itemType) and m_SelectEquip) then
                local goodItem=fields.UIList_Goods:AddListItem()
				if m_PurchasedItems[i].prop then
					 m_PurchasedItems[i].accessory=m_PurchasedItems[i].prop
				end
                local displayItem = ItemManager.CreateItemBaseById(m_PurchasedItems[i].itemid,m_PurchasedItems[i],m_PurchasedItems[i].num)
                local BonusManager=require"item.bonusmanager"
                BonusManager.SetRewardItem(goodItem,displayItem,{notSetClick=true})
                local UILabel_Name=goodItem.Controls["UILabel_Name"]
                UILabel_Name.text=displayItem:GetName()
                local UILabel_LV=goodItem.Controls["UILabel_LV"]
                UILabel_LV.text=displayItem:GetLevel()
                local UILabel_Price=goodItem.Controls["UILabel_Pricet"]
                UILabel_Price.text=m_PurchasedItems[i].aprice
                local UILabel_TotalPricet=goodItem.Controls["UILabel_TotalPricet"]
                UILabel_TotalPricet.text=m_PurchasedItems[i].aprice*m_PurchasedItems[i].num               
                EventHelper.SetClick(goodItem,function()
                    m_BuyItemId=m_PurchasedItems[i].id
                    if ExchangeMgr.IsShelfGood(m_BuyItemId) then
                        UIManager.ShowSingleAlertDlg({content=LocalString.Exchange_CantBuySelfGood})
                    else
                        --UIManager.show("dlgalert_fragment",{item=displayItem,num=m_PurchasedItems[i].num,variableNum=true,price=m_PurchasedItems[i].aprice,priceType=cfg.currency.CurrencyType.YuanBao,buttons={{display=true,text=LocalString.Exchange_Buy,callFunc=Buy},{display=false,text="",callFunc=nil}}})               
                        local params={item=displayItem,num=m_PurchasedItems[i].num,variableNum=true,price=m_PurchasedItems[i].aprice,priceType=cfg.currency.CurrencyType.YuanBao,buttons={{display=true,text=LocalString.Exchange_Buy,callFunc=Buy},{display=false,text="",callFunc=nil}}}
                        ItemIntroduct.DisplayItem(params)
                    end
                end)
            end
        end
    end
    fields.UIToggle_equipment.value=m_SelectEquip
    fields.UIToggle_debris.value=m_SelectFrag
    EventHelper.SetClick(fields.UIToggle_equipment,function()
        m_SelectEquip=fields.UIToggle_equipment.value
        m_SelectFrag=fields.UIToggle_debris.value
        DisplayPurchaseDlg()
    end)
    EventHelper.SetClick(fields.UIToggle_debris,function()
        m_SelectEquip=fields.UIToggle_equipment.value
        m_SelectFrag=fields.UIToggle_debris.value
        DisplayPurchaseDlg()
    end)
    fields.UIButton_ArrowsLeft.isEnabled=true
    fields.UIButton_ArrowsRight.isEnabled=true
    if m_CurPurchasePage==0 then
        fields.UIButton_ArrowsLeft.isEnabled=false
        fields.UIButton_ArrowsRight.isEnabled=false
    elseif m_CurPurchasePage==1 then
        fields.UIButton_ArrowsLeft.isEnabled=false
    end
    if m_CurPurchasePage==m_TotalPage then
        fields.UIButton_ArrowsRight.isEnabled=false
    end
    fields.UILabel_Page.text=m_CurPurchasePage.."/"..m_TotalPage
    EventHelper.SetClick(fields.UIButton_ArrowsLeft,function()
        m_SelectEquip=true
        m_SelectFrag=true
        QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,(m_CurPurchasePage-2)*m_NumOfPage,(m_CurPurchasePage-1)*m_NumOfPage-1)
    end)
    EventHelper.SetClick(fields.UIButton_ArrowsRight,function()
        m_SelectEquip=true
        m_SelectFrag=true
        QueryItems(m_KeyWord,m_Category,m_BuySortType,m_SortOrder,(m_CurPurchasePage)*m_NumOfPage,(m_CurPurchasePage+1)*m_NumOfPage-1)
    end)
    local startIndex=0
    local endIndex=0
    if m_CurPurchasePage==0 then
        startIndex=0
        endIndex=m_NumOfPage-1
    else
        startIndex=(m_CurPurchasePage-1)*m_NumOfPage
        endIndex= (m_CurPurchasePage)*m_NumOfPage-1
    end
    EventHelper.SetClick(fields.UIButton_Level,function()
        SetSortOrd(true,cfg.exchange.OrderByType.LEVEL)
        QueryItems(m_KeyWord,m_Category,cfg.exchange.OrderByType.LEVEL,m_SortOrder,startIndex,endIndex)
        SetBuySortWay()
    end)
    EventHelper.SetClick(fields.UIButton_Price,function()
        SetSortOrd(true,cfg.exchange.OrderByType.APRICE)
        QueryItems(m_KeyWord,m_Category,cfg.exchange.OrderByType.APRICE,m_SortOrder,startIndex,endIndex)
        SetBuySortWay()
    end)
    EventHelper.SetClick(fields.UIButton_AllPrice,function()
        SetSortOrd(true,cfg.exchange.OrderByType.TOTAL_PRICE)
        QueryItems(m_KeyWord,m_Category,cfg.exchange.OrderByType.TOTAL_PRICE,m_SortOrder,startIndex,endIndex)
        SetBuySortWay()
    end)
end

local function RefreshQueryResult(msg)
    m_PurchasedItems = msg.queryresult.items
    if msg.queryresult.totalnum==0 then
        m_TotalPage=0
        m_CurPurchasePage=0
    else
        m_TotalPage = math.ceil((msg.queryresult.totalnum)/m_NumOfPage)
        local startIndex=msg.startindex
        m_CurPurchasePage = math.floor(startIndex/m_NumOfPage)+1
    end
    DisplayPurchaseDlg()
end

local function refresh(params)
    LoadPurchaseDlg()
end

local function update()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = Unpack(params)
    m_FirstLoad=true
    m_KeyWord=""
    m_Category=cfg.exchange.Category.WEAPON
    m_BuySortType=cfg.exchange.Const.DEFAULT_SORT_TYPE
    m_SortOrder=cfg.exchange.Const.DEFAULT_SORT_ORDER
    m_NumOfPage=cfg.exchange.Const.NUM_OF_PAGE
    m_SelectEquip=true
    m_SelectFrag=true
    EventHelper.SetClick(fields.UIButton_Med_Classification,function()
        local keyWord=fields.UILabel_InputItemName.text
        if string.len(keyWord)==0 or (keyWord==LocalString.Exchange_DefaultTip) then
            UIManager.ShowSingleAlertDlg({content=LocalString.Exchange_KeyIsNull})
        else
            m_KeyWord=keyWord
            QueryItems(keyWord,m_Category,m_BuySortType,m_SortOrder,0,m_NumOfPage-1)
        end
    end)
end

return{
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    RefreshQueryResult = RefreshQueryResult,
    QueryDefalutItems = QueryDefalutItems,
    QueryCurrentItems = QueryCurrentItems,
}
