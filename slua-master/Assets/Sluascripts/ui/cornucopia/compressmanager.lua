local NetWork = require("network")
local UIManager = require("uimanager")
local ConfigManager =require("cfg.configmanager")
local BagManager = require("character.bagmanager")
local ItemManager=require("item.itemmanager")
local BonusManager = require("item.bonusmanager")
local Utils = require("common.utils")

local TypeNum=10

local function GetRawMaterials(targetId)
    local item=ConfigManager.getConfigData("itembasic",targetId)
    local requireitem={}
    local sourceItems={}
    if item then
       local rawItem={itemid=item.previd,amount=item.composecost}
       table.insert(sourceItems,rawItem)
    end
    requireitem.items=sourceItems
    return requireitem
end

local function GetItemListByType(type)
    local itemList={}
    if type==0 then
        itemList=ConfigManager.getConfig("itemcompose")
    else
        local items=ConfigManager.getConfig("itembasic")
        for _,item in pairs(items) do
            if (item.itemtype==cfg.item.EItemType.JEWELRY) and (item.level==(type+1)) then       
                local composeItem={}
                composeItem.id=item.id
                composeItem.targetid=item.id
                composeItem.requireitem=GetRawMaterials(item.id)
                table.insert(itemList,composeItem)
            end
        end
    end
    Utils.table_sort(itemList,function(a,b) return a.id<b.id end)
    return itemList
end

local function IsCanComposeOneItem(items)
    local result=true
    if items and (#items>0) then
        for _,oneItem in pairs(items) do
            local ownNum=BagManager.GetItemNumById(oneItem.itemid)
            if ownNum<oneItem.amount then
                result=false
                break
            end
        end
    else
        result=false
    end
    return result
end

local function IsCanCompose(type)
    local result=false
    local itemList={}
    if type==0 then
        itemList=ConfigManager.getConfig("itemcompose")
    else
        local items=ConfigManager.getConfig("itembasic")
        for _,item in pairs(items) do
            if (item.itemtype==cfg.item.EItemType.JEWELRY) and (item.level==(type+1)) then       
                local composeItem={}
                composeItem.targetid=item.id
                composeItem.requireitem=GetRawMaterials(item.id)
                table.insert(itemList,composeItem)
            end
        end
    end
    for _,item in pairs(itemList) do
        if IsCanComposeOneItem(item.requireitem.items)==true then
            result=true
            break
        end
    end
    return result
end

local function UnRead()
    local result=false
    local i=0
    for i=0,(TypeNum-1) do
        if IsCanCompose(i)==true then
            result=true
            break
        end
    end
    return result
end

local function Compress(itemType,itemId,composeType,isBind)
    local msg=nil
    local onlyUnbind=0
    local isGemstone
    if isBind==true then
        onlyUnbind=1
    else
        onlyUnbind=0
    end
    if itemType==0 then
        isGemstone=0
    else
        isGemstone=1
    end
    if composeType==0 then
        msg=lx.gs.treasurebowl.CTreasureBowlComposite({isgemstone=isGemstone,index=itemId,unbind=onlyUnbind})
    elseif composeType==1 then
        msg=lx.gs.treasurebowl.CTreasureBowlCompositeAll({isgemstone=isGemstone,index=itemId,unbind=onlyUnbind})
    end
    NetWork.send(msg)
end

local function GetBonusByIndex(index,num)
    local data=ConfigManager.getConfigData("itemcompose",index)
    local items=BonusManager.GetItemsOfSingleBonus(data.getbonus)
    for _,item in pairs(items) do
        item:AddNumber(num-1)
    end
    return items
end

local function Refresh(items)
    UIManager.show("common.dlgdialogbox_itemshow", {itemList = items})
    for _,item in pairs(items) do
		UIManager.ShowSyncItem(item)
      --  UIManager.ShowSystemFlyText(string.format(LocalString.FlyText_Reward, item:GetNumber(),colorutil.GetQualityColorText(item:GetQuality(),item:GetName())))
    end
    if UIManager.isshow("cornucopia.tabcompress") then
        UIManager.call("cornucopia.tabcompress","SetRawMaterials")
        UIManager.call("cornucopia.tabcompress","RefreshItem",{items = items})
        UIManager.call("cornucopia.tabcompress","refresh")
        UIManager.call("dlgdialog","RefreshRedDot","cornucopia.dlgcornucopia")
    end
end

local function OnMsg_STreasureBowlComposite(msg)
    local items={}
    if msg.isgemstone==1 then   --宝石
        local item=ItemManager.CreateItemBaseById(msg.index)
        table.insert(items,item)
    elseif msg.isgemstone==0 then   
        items=GetBonusByIndex(msg.index,1)
    end
    Refresh(items)
end

local function OnMsg_STreasureBowlCompositeAll(msg)
    local items={}
    if msg.isgemstone==1 then   --宝石
        local item=ItemManager.CreateItemBaseById(msg.index,msg,msg.num)
        table.insert(items,item)
    else
        items=GetBonusByIndex(msg.index,msg.num)
    end
    Refresh(items)
end

local function Decompose(equipList)
    local msg = lx.gs.treasurebowl.CTreasureBowlBreak({ poslist = equipList})
    NetWork.send(msg)
end

local function init()
    NetWork.add_listeners({
         {"lx.gs.treasurebowl.STreasureBowlCompositeAll", OnMsg_STreasureBowlCompositeAll},
         {"lx.gs.treasurebowl.STreasureBowlComposite", OnMsg_STreasureBowlComposite}
    })
end

return{
    init = init,
    Compress = Compress,
    Decompose = Decompose,
    GetRawMaterials = GetRawMaterials,
    GetItemListByType = GetItemListByType,
    IsCanCompose = IsCanCompose,
    IsCanComposeOneItem = IsCanComposeOneItem,
    UnRead = UnRead,
}