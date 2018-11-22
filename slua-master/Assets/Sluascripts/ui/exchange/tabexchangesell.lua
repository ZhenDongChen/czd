local Unpack = unpack
local EventHelper = UIEventListenerHelper
local NetWork = require("network")
local UIManager = require("uimanager")
local CfgMgr=require "cfg.configmanager"
local BagMgr = require "character.bagmanager"
local ExchangeMgr = require"ui.exchange.exchangemanager"
local ItemIntroduct = require "item.itemintroduction"
local ItemManager = require "item.itemmanager"
local ItemEnum = require("item.itemenum")

local gameObject
local name
local fields
local m_SelectedBagType
local m_UnShelveId=-1
local m_ShelfItem   --当前出售物品
local m_ShelfGoods={}

local function destroy()
end

local function show(params)
end

local function hide()
end

local function GetItemDetail(itemId)
    local itemData=CfgMgr.getConfigData("equip",itemId)
    if not itemData then
        itemData=CfgMgr.getConfigData("item",itemId)
        if not itemData then
            itemData=CfgMgr.getConfigData("fragment",itemId)
        end
    end
    return itemData
end

--local function PutAway(params)
--    local bagType
--    if m_SelectedBagType==cfg.bag.BagType.EQUIP then
--        bagType=cfg.role.BagType.EQUIP
--    elseif m_SelectedBagType==cfg.bag.BagType.FRAGMENT then
--        bagType=cfg.role.BagType.FRAGMENT
--    elseif m_SelectedBagType==cfg.bag.BagType.ITEM then
--        bagType=cfg.role.BagType.ITEM
--    end
--    local num=1
--    if params.num==nil then
--        num=1
--    else
--        num=params.num
--    end
--    local params={bagType=bagType,bagId=m_ShelfItem.BagId,num=num,unitPrice=params.price}
--    ExchangeMgr.SendCAddItem(params)
--end

local function UnShelve(params)
    local params={exchangeId=m_UnShelveId}
    ExchangeMgr.SendCDelItem(params)
end

local function DisplayOneShelfGood(sellGoodItem,shelfGood)
	if shelfGood.prop then
		shelfGood.accessory=shelfGood.prop
	end
    local displayItem=ItemManager.CreateItemBaseById(shelfGood.itemid,shelfGood,shelfGood.num)
    local UILabel_Price=sellGoodItem.Controls["UILabel_Pricet"]
    UILabel_Price.text=shelfGood.aprice
    local UILabel_Name=sellGoodItem.Controls["UILabel_Name"]
    UILabel_Name.text=displayItem:GetName()
    local UILabel_Amount=sellGoodItem.Controls["UILabel_Amount"]
    UILabel_Amount.text=shelfGood.num
    local UITexture_Icon=sellGoodItem.Controls["UITexture_Icon"]
    UITexture_Icon:SetIconTexture(displayItem:GetTextureName())
    local UISprite_Quality=sellGoodItem.Controls["UISprite_Quality"]
    if UISprite_Quality then
        if displayItem:GetQuality() then
            UISprite_Quality.spriteName = colorutil.GetQualitySprite(displayItem:GetQuality())
        end
    end
    EventHelper.SetClick(sellGoodItem,function()
        m_UnShelveId=shelfGood.id  
        local params={item=displayItem,defaultNum=shelfGood.num,num=shelfGood.num,bShowNum=false,variableNum=false,price=shelfGood.aprice,priceType=cfg.currency.CurrencyType.YuanBao,buttons={{display=true,text=LocalString.Exchange_UnShelve,callFunc=UnShelve},{display=false,text="",callFunc=nil}}}
        ItemIntroduct.DisplayItem(params)         
    end)
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem==nil then
        return
    end
    local log=m_ShelfGoods[realIndex]
    if UIListItem then
        DisplayOneShelfGood(UIListItem,log)
    end
end

local function InitList(num)
    local wrapList=fields.UIList_Goods.gameObject:GetComponent("UIWrapContentList")
    if wrapList==nil then
        return
    end
    if (num==0) then
        fields.UILabel_Empty.text=LocalString.Exchange_BuyGoodsNull
        fields.UILabel_Empty.gameObject:SetActive(true)
    else
        fields.UILabel_Empty.gameObject:SetActive(false)
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-0.2)
end

local function DisplayShelfGoods() 
    m_ShelfGoods=ExchangeMgr.GetShelfGoodsList()
    InitList(#m_ShelfGoods)
    fields.UILabel_Amount.text=((cfg.exchange.Const.MAX_EXCHANGE_ITEM_NUM)-#m_ShelfGoods).."/"..(cfg.exchange.Const.MAX_EXCHANGE_ITEM_NUM)
end

local function update()
end

local function refresh(params)
    DisplayShelfGoods()
    if UIManager.isshow("playerrole.bag.tabbag") then
        UIManager.refresh("playerrole.bag.tabbag",{exchange=true,})
    else
        UIManager.showtab("playerrole.bag.tabbag",{exchange=true,})
    end
end

local function init(params)
    name, gameObject, fields = Unpack(params)             
    m_SelectedBagType = cfg.bag.BagType.EQUIP 
      
    EventHelper.SetClick(fields.UIButton_Detail,function()
        UIManager.show("dlgRule", { title = LocalString.TipText, content = LocalString.Exchange_Sell_Fee })
    end)
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
    DisplayShelfGoods = DisplayShelfGoods,
}