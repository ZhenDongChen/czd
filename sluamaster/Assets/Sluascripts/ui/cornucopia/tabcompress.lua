local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local CfgMgr=require "cfg.configmanager"
local BagMgr=require "character.bagmanager"
local ItemManager=require "item.itemmanager"
local ItemIntroduct=require "item.itemintroduction"
local BonusManager=require "item.bonusmanager"
local CompressManager = require"ui.cornucopia.compressmanager"

local m_GameObject
local m_Name
local m_Fields

local m_DisplayItemList={}
local m_SelectedType
local m_ComposeItem

local function destroy()  
end

local function show(params)
end

local function showtab(params)
    UIManager.show("cornucopia.tabcompress",params)
end

local function hide()
      
end

local function hidetab()
    UIManager.hide(m_Name)
end

local function SetComposeItem(itemData)
    m_Fields.UILabel_EquipTypeName.text=itemData:GetName()
    m_Fields.UITexture_Icon:SetIconTexture(itemData:GetTextureName())
    local spriteQuality = m_Fields.UISprite_Quality
    if spriteQuality then
        if itemData:GetQuality() then
            spriteQuality.spriteName = colorutil.GetQualitySprite(itemData:GetQuality())
        end
        EventHelper.SetClick(spriteQuality,function()
            local params={item=itemData,buttons={{display=false,text="",callFunc=nil},{display=false,text="",callFunc=nil}}}
            ItemIntroduct.DisplayBriefItem(params)
        end)
    end
    m_Fields.UISprite_Binding.gameObject:SetActive(true)
    
end

local function SetRawMaterials()
    if m_ComposeItem then
        local i=0
        for i=0,(m_Fields.UIList_Gemstones.Count-1) do
            local data=m_ComposeItem.requireitem.items[i+1]
            local listItem=m_Fields.UIList_Gemstones:GetItemByIndex(i)
            local UILabel_Number=listItem.Controls["UILabel_Number"]
            local UISprite_Binding=listItem.Controls["UISprite_Binding"]
            local UISprite_Add = listItem.Controls["UISprite_Add"]
            if data then              
                local itemData=ItemManager.CreateItemBaseById(data.itemid)
                BonusManager.SetRewardItem(listItem,itemData,{notShowAmount=true})
                local ownNum = BagMgr.GetItemNumById(data.itemid)             
                UILabel_Number.text=ownNum.."/"..data.amount
                if ownNum<data.amount then
                    UILabel_Number.color=Color(255 / 255, 0 / 255, 0 / 255, 1)
                else
                    UILabel_Number.color=Color(0 / 255, 255 / 255, 0 / 255, 1)
                end
                UILabel_Number.gameObject:SetActive(true)
                UISprite_Binding.gameObject:SetActive(true)   
                UISprite_Add.gameObject:SetActive(false)             
            else 
                BonusManager.SetEmptyItem(listItem)  
                UISprite_Binding.gameObject:SetActive(false)  
                UILabel_Number.gameObject:SetActive(false)    
                UISprite_Add.gameObject:SetActive(false)   
            end
        end
    else
        local i=0
        for i=0,(m_Fields.UIList_Gemstones.Count-1) do
            local listItem=m_Fields.UIList_Gemstones:GetItemByIndex(i)
            local UILabel_Number=listItem.Controls["UILabel_Number"]
            local UISprite_Binding=listItem.Controls["UISprite_Binding"]
            BonusManager.SetEmptyItem(listItem)  
            UISprite_Binding.gameObject:SetActive(false)  
            UILabel_Number.gameObject:SetActive(false)         
        end
    end
end

local function RefreshRedDot()
    for i=0,m_Fields.UIList_RankType.Count-1 do
        local listItem=m_Fields.UIList_RankType:GetItemByIndex(i)
        local result=CompressManager.IsCanCompose(i)
        local UISprite_Warning=listItem.Controls["UISprite_Warning"]
        if UISprite_Warning then
            UISprite_Warning.gameObject:SetActive(result)
        end
    end
end

local function RefreshItem(params)
    for _,item in pairs(params.items) do
        local UIListItem = m_Fields.UIList_Equip:GetItemById(item.ConfigId)
        local UISprite_Warning=UIListItem.Controls["UISprite_Warning"]
        local result = CompressManager.IsCanComposeOneItem(UIListItem.Data.requireitem.items)
        if UISprite_Warning then
            UISprite_Warning.gameObject:SetActive(result)
        end
        if  m_SelectedType == 0 then
            local nextListItem = m_Fields.UIList_Equip:GetItemByIndex(UIListItem.Index + 1)
            if nextListItem then
                local UISprite_Warning = nextListItem.Controls["UISprite_Warning"]
                local result = CompressManager.IsCanComposeOneItem(nextListItem.Data.requireitem.items)
                if UISprite_Warning then
                    UISprite_Warning.gameObject:SetActive(result)
                end
            end
        end
    end
    RefreshRedDot()
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    local data=m_DisplayItemList[realIndex]
    UIListItem.Id = data.targetid
    UIListItem.Data = data
    local UIToggle_Item=UIListItem.gameObject.transform:GetComponent("UIToggle")
    if (m_ComposeItem==nil) or(m_ComposeItem and m_ComposeItem.id~=data.id) then       
        UIToggle_Item:Set(false)
    else
        UIToggle_Item:Set(true)
    end
    local itemData=ItemManager.CreateItemBaseById(data.targetid)
    BonusManager.SetRewardItem(UIListItem,itemData,{notShowAmount=true,notSetClick=true})
    local UILabel_EquipName=UIListItem.Controls["UILabel_EquipName"]
    UILabel_EquipName.text=itemData:GetName()
    local UISprite_Warning=UIListItem.Controls["UISprite_Warning"]
    local result=CompressManager.IsCanComposeOneItem(data.requireitem.items)
    if UISprite_Warning then
        UISprite_Warning.gameObject:SetActive(result)
    end
    local UISprite_Binding=UIListItem.Controls["UISprite_Binding"]
    if UISprite_Binding then
        UISprite_Binding.gameObject:SetActive(true)
    end
    EventHelper.SetClick(UIListItem,function()
        m_ComposeItem=data
        SetComposeItem(itemData)
        SetRawMaterials()
    end)
end

local function InitList(num)
    local wrapList=m_Fields.UIList_Equip.gameObject:GetComponent("UIWrapContentList")
    if wrapList==nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(0)
end

local function SetItemListByType()
    m_DisplayItemList=CompressManager.GetItemListByType(m_SelectedType)
    InitList(#m_DisplayItemList)
end

local function ClearSelectedTargetItem()
    m_Fields.UILabel_EquipTypeName.text=""
    m_Fields.UITexture_Icon:SetIconTexture("")
    local spriteQuality = m_Fields.UISprite_Quality
    if spriteQuality then
        spriteQuality.color = colorutil.GetQualityColor()
    end
    m_Fields.UISprite_Binding.gameObject:SetActive(false)
    m_ComposeItem=nil
    SetRawMaterials()
end

local function refresh(params)
    RefreshRedDot()
    if m_SelectedType==nil then
        m_SelectedType=0
    end
    SetItemListByType()
end

local function init(params) 
    m_Name, m_GameObject, m_Fields = Unpack(params)  
    ClearSelectedTargetItem()
    EventHelper.SetListClick(m_Fields.UIList_RankType,function(listItem)
        if m_SelectedType~=listItem.Index then
            m_SelectedType=listItem.Index
            SetItemListByType()
            ClearSelectedTargetItem()
        end
    end)
    EventHelper.SetClick(m_Fields.UIButton_GemstoneIntro,function()
        if m_ComposeItem then
            if CompressManager.IsCanComposeOneItem(m_ComposeItem.requireitem.items)==true then
                local isBind=m_Fields.UIToggle_Anneal_OnlyUseNotBoundProps.value
                CompressManager.Compress(m_SelectedType,m_ComposeItem.id,1,isBind)             
            else
                UIManager.ShowSystemFlyText(LocalString.CornuCopia_NotEnough)
            end
        else
            UIManager.ShowSystemFlyText(LocalString.CornuCopia_SelectTarget)
        end
    end)
    EventHelper.SetClick(m_Fields.UIButton_GemstoneCompose,function()
        if m_ComposeItem then
            if CompressManager.IsCanComposeOneItem(m_ComposeItem.requireitem.items)==true then 
                local isBind=m_Fields.UIToggle_Anneal_OnlyUseNotBoundProps.value
                CompressManager.Compress(m_SelectedType,m_ComposeItem.id,0,isBind)
            else
                UIManager.ShowSystemFlyText(LocalString.CornuCopia_NotEnough)
            end
        else
            UIManager.ShowSystemFlyText(LocalString.CornuCopia_SelectTarget)
        end
    end)
end

local function update()
    
end

local function uishowtype()
    return UIShowType.Refresh
end

return{
    init = init,
    show = show,
    showtab = showtab,
    hide = hide,
    hidetab = hidetab,
    uishowtype = uishowtype,
    update = update,
    destroy = destroy,
    refresh = refresh,
    SetRawMaterials = SetRawMaterials,
    RefreshItem = RefreshItem,
}