local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local reclaimmgr = require("guide.reclaimmanager")
local player = require("character.playerrole"):Instance()
local itemmgr = require("item.itemmanager")

local fields
local m_UndoEventIDList

local function GetJingYanInItems(items)
    if items[cfg.currency.CurrencyType.JingYan] then
        return items[cfg.currency.CurrencyType.JingYan]
    else
        return 0
    end
end

local function GetXuNiBiInItems(items)
    if items[cfg.currency.CurrencyType.XuNiBi] then
        return items[cfg.currency.CurrencyType.XuNiBi]
    else
        return 0
    end
end

local function showtab(params)
    -- printyellow("on show tabbasic")
	--TODO 
    reclaimmgr.GetReady(function()
        uimanager.show("guide.tabreclaim", params)
    end)

end

local function RefreshReclaimList()
	if not m_UndoEventIDList then return end
    fields.UIList_Reclaim:Clear()
    local keylv = 0 --math.huge
    for lv,_ in pairs(ConfigManager.getConfig("findback")) do
        if lv <= player:GetLevel() and lv > keylv then
            keylv = lv
        end
    end
    for i = 1, #m_UndoEventIDList do		       
        local dataeventList = ConfigManager.getConfigData("findback", keylv).findsystemlist   --[m_UndoEventIDList[i]]
        local dataevent = nil
        for j = 1, #dataeventList do
            if dataeventList[j].eventtype == m_UndoEventIDList[i] then
                dataevent = dataeventList[j]
            end
        end       

        if dataevent then
            local dataeventserver = reclaimmgr.UndoEvent(dataevent.eventtype)
            if not dataeventserver then return end
            local item = fields.UIList_Reclaim:AddListItem()    
            --printt(dataevent)
            --printt(dataeventserver)
            item.Id = dataevent.eventtype
            item.Data = dataeventserver
            item.Controls["UILabel_Event"].text = dataevent.name
            item.Controls["UILabel_Count"].text = dataeventserver and dataeventserver.undotimes or 0
            item.Controls["UIButton_GoldReclaim"].isEnabled = dataeventserver.undotimes > 0   -- and player:Gold() > dataeventserver.costjinbi
            item.Controls["UIButton_MoneyReclaim"].isEnabled = dataeventserver.undotimes > 0  -- and player:Ingot() > dataeventserver.costyuanbao
            item.Controls["UILabel_Descrip2"].text = "*"..GetJingYanInItems(dataeventserver.yuanbaofindbackbonus.items)
            item.Controls["UILabel_Descrip3"].text = "*"..GetXuNiBiInItems(dataeventserver.yuanbaofindbackbonus.items)

            EventHelper.SetClick(item.Controls["UIButton_GoldReclaim"], function()
                uimanager.show("guide.dlgreclaimreward", { Data = item.Data, findType = reclaimmgr.FindType.JinBi})
            end)
            EventHelper.SetClick(item.Controls["UIButton_MoneyReclaim"], function()
                uimanager.show("guide.dlgreclaimreward", { Data = item.Data, findType = reclaimmgr.FindType.YuanBao })
            end)
        end         
	end
	fields.UIList_Reclaim.gameObject:GetComponent("UITable").repositionNow = true
end

local function show()
end

-- local function hidetab()
-- end

local function hide()
end

local function destroy()
end

local function refresh(params)
    --printyellow("on refresh tab")
    m_UndoEventIDList = reclaimmgr.UndoEventIDs()
    RefreshReclaimList()
    --printt(m_UndoEventIDList)
    fields.UIButton_GoldAll.isEnabled = (reclaimmgr.UnRead() and not reclaimmgr.IsFristDay() )
    fields.UIButton_MoneyAll.isEnabled = (reclaimmgr.UnRead() and not reclaimmgr.IsFristDay() )

    fields.UIList_Reclaim.gameObject:SetActive(not reclaimmgr.IsFristDay())
    fields.UIGroup_Empty.gameObject:SetActive( (#m_UndoEventIDList) == 0 or reclaimmgr.IsFristDay())

    require("ui.dlgdialog").RefreshRedDot("welfare.dlgwelfaremain")
end

local function GetAllBouns()
    local allJinbiItems = {}
    local allJinbiCost = 0
    local allYuanbaoItems = {}
    local allYuanbaoCost = 0
	printyellow("#m_UndoEventIDList",#m_UndoEventIDList)
    for i = 1,#m_UndoEventIDList do
        local item = fields.UIList_Reclaim:GetItemByIndex(i-1)
        if not item and not item.Data then return end
        if item and item.Data then
            for id,num in pairs(item.Data.jinbifindbackbonus.items) do
            if allJinbiItems[id] == nil  then
                allJinbiItems[id] = num
            else
                allJinbiItems[id] = num + allJinbiItems[id]
            end           
        end
        allJinbiCost = allJinbiCost + item.Data.costjinbi

        for id,num in pairs(item.Data.yuanbaofindbackbonus.items) do
            if allYuanbaoItems[id] == nil  then
                allYuanbaoItems[id] = num
            else
                allYuanbaoItems[id] = num + allYuanbaoItems[id]
            end           
        end
        allYuanbaoCost = allYuanbaoCost + item.Data.costyuanbao
        end       
    end

    local Data = {}
    Data.jinbifindbackbonus = {}
    Data.jinbifindbackbonus.items = allJinbiItems
    Data.costjinbi = allJinbiCost
    Data.costyuanbao = allYuanbaoCost
    Data.yuanbaofindbackbonus = {}
    Data.yuanbaofindbackbonus.items = allYuanbaoItems

    --printt(Data)
    return Data
end

local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_GoldAll, function()
        uimanager.show("guide.dlgreclaimreward", { Data = GetAllBouns(), findType = reclaimmgr.FindType.JinBiAll })
    end)
    EventHelper.SetClick(fields.UIButton_MoneyAll, function()
        uimanager.show("guide.dlgreclaimreward", { Data = GetAllBouns(), findType = reclaimmgr.FindType.YuanBaoAll })
    end)
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    uishowtype   = uishowtype,
}
