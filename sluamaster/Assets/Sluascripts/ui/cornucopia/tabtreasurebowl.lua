local Unpack = unpack
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local NetWork = require("network")
local PlayerRole=require "character.playerrole"
local CfgMgr=require "cfg.configmanager"
local BagMgr=require "character.bagmanager"
local ItemManager=require "item.itemmanager"
local ItemIntroduct=require "item.itemintroduction"
local BonusManager=require "item.bonusmanager"
local m_GameObject
local m_Name
local m_Fields
local m_SelectedEquips={}
local m_PlayParticle=nil
local m_ReceivedLingJing=0
local m_Particle=nil
local m_ListenerId

local function destroy()
    NetWork.remove_listener(m_ListenerId)
end

local function show(params)
end

local function showtab(params)
    UIManager.show("cornucopia.tabtreasurebowl",params)
end

local function hide()
      
end

local function hidetab()
    if m_PlayParticle==true then    
        m_PlayParticle=nil            
        UIManager.StopUIParticleSystem(m_Fields.UIGroup_AnnealEffect_jubaopen.gameObject)           
    end
    UIManager.hide(m_Name)
end

local function CalculateZLingJing(item,add)
    local lingjingCount=m_Fields.UILabel_TotalPrice.text
    if add then
        m_Fields.UILabel_TotalPrice.text=lingjingCount+item:GetDisassembly()
    else
        m_Fields.UILabel_TotalPrice.text=lingjingCount-item:GetDisassembly()
    end
end

local function IsEquipInList(slot)
    local isIn=false
    for _,equipSlot in pairs(m_SelectedEquips) do
        if equipSlot==slot then
            isIn=true
            break
        end
    end
    return isIn
end

local function AddEquipInList(item)
    if not IsEquipInList(item.BagPos) then
        table.insert(m_SelectedEquips,item.BagPos)
        CalculateZLingJing(item,true)
    end
end

local function RemoveEquipFromList(item)
    local i=1
    for _,equipSlot in pairs(m_SelectedEquips) do
        if equipSlot==item.BagPos then
            table.remove(m_SelectedEquips,i)
            CalculateZLingJing(item,false)
            break
        end
        i=i+1
    end
end

local function AddItem(count)
    local itemCount=BagMgr.GetItemSlotsNum(cfg.bag.BagType.EQUIP)
    for i=1,itemCount do
        m_Fields.UIList_DecompositionBag:AddListItem()
    end
end

--local function RefreshLingJing()
--    if PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.LingJing) then
--        m_Fields.UILabel_OwnAmount.text=PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.LingJing)
--    else
--        m_Fields.UILabel_OwnAmount.text=0
--    end
--end

local function CancelAllSelect(quality)
    if quality == cfg.item.EItemColor.GREEN then
        m_Fields.UIToggle_Green:Set(false)
    elseif quality == cfg.item.EItemColor.BLUE then
        m_Fields.UIToggle_Blue:Set(false)
    elseif quality == cfg.item.EItemColor.PURPLE then
        m_Fields.UIToggle_Purple:Set(false)
    end
end

local function SetSlot(listItem,item)
    if item ~= nil then
        listItem.Data=item
        listItem.Controls["UIGroup_Slots"].gameObject:SetActive(true)
        listItem.Controls["UITexture_Icon"].gameObject:SetActive(true)
        if item:GetTextureName() == "" then
            listItem:SetIconTexture("icon_skill02")
        else
            listItem:SetIconTexture(item:GetTextureName())
        end
        listItem.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item:GetQuality())
        listItem.Controls["UISprite_Binding"].gameObject:SetActive(item:IsBound())

        if item.bNewAdded then
            listItem.Controls["UISprite_New"].gameObject:SetActive(true)
        else
            listItem.Controls["UISprite_New"].gameObject:SetActive(false)
        end
        if item:GetProfessionLimit() ~= cfg.Const.NULL and item:GetProfessionLimit() ~= PlayerRole:Instance().m_Profession then
            listItem.Controls["UISprite_RedMask"].gameObject:SetActive(true)
        else
            listItem.Controls["UISprite_RedMask"].gameObject:SetActive(false)
        end
        listItem.Controls["UILabel_AnnealLevel"].gameObject:SetActive(item:GetAnnealLevel() ~= 0)
        listItem.Controls["UISprite_AnnealLevel"].gameObject:SetActive(true)
        listItem:SetText("UILabel_AnnealLevel", "+" .. item:GetAnnealLevel())
        local UIToggle_Select=listItem.gameObject.transform:GetComponent("UIToggle")
        UIToggle_Select:Set(false)
        EventHelper.SetClick(listItem,function()  
            if UIToggle_Select.value then
                AddEquipInList(item)   
            else             
                RemoveEquipFromList(item)
                CancelAllSelect(item:GetQuality())
            end
        end)
     else
        listItem.Controls["UIGroup_Slots"].gameObject:SetActive(false)
        listItem.Controls["UISprite_Lock"].gameObject:SetActive(false)
     end
end

local function SortEquipByQuality()
    local Utils = require("common.utils")
    local items=BagMgr.GetItems(cfg.bag.BagType.EQUIP)
    local newItems={}
    local i=0
    for _,item in pairs(items) do
        if item:GetQuality()~=cfg.item.EItemColor.RED then
            local filtedItem = Utils.copy_table(item)
            table.insert(newItems,filtedItem)
            i=i+1
        end
    end
    local sortFunc = function(item1,item2) 
        if item1:GetQuality() == item2:GetQuality() then
            return false
        else
            return (item1:GetQuality() >= item2:GetQuality())
        end
    end
    
    Utils.table_sort(newItems,sortFunc)
    return newItems,i   
end

local function SetItem()
    local sortItems,count=SortEquipByQuality()  
    local i=0
    local curListCount=m_Fields.UIList_DecompositionBag.Count
    if curListCount>count then
        for i=(curListCount-1),count,-1 do
            local listItem=m_Fields.UIList_DecompositionBag:GetItemByIndex(i)
            m_Fields.UIList_DecompositionBag:DelListItem(listItem)
        end
    elseif curListCount<count then
        for i=1,(count-curListCount) do
            m_Fields.UIList_DecompositionBag:AddListItem()
        end
    end
    i=0
    for _, item in pairs(sortItems) do
        if item ~= nil then
            local listItem = m_Fields.UIList_DecompositionBag:GetItemByIndex(i)
            if listItem then
                SetSlot(listItem, item)
            end
        end
        i=i+1
    end
end

local function Clear()
    m_SelectedEquips={}
    m_Fields.UIList_DecompositionBag:Clear()
end

local function RefreshSlots()
    m_SelectedEquips={}
    --RefreshLingJing()
    m_Fields.UILabel_TotalPrice.text=0
    m_Fields.UIToggle_Purple.value=false
    m_Fields.UIToggle_Blue.value=false
    m_Fields.UIToggle_Green.value=false
    SetItem()
end

local function SetItemSelectedByColor(quality,checked)
    local count=m_Fields.UIList_DecompositionBag.Count
    for i=0,count-1 do
        local listItem=m_Fields.UIList_DecompositionBag:GetItemByIndex(i)
        if listItem then
            local itemData=listItem.Data
            if itemData and itemData:GetQuality()==quality then
                local UIToggle_Item=listItem.gameObject.transform:GetComponent("UIToggle")
                UIToggle_Item:Set(checked)
                if checked then
                    AddEquipInList(itemData)
                else
                    RemoveEquipFromList(itemData)
                end
            end
        end            
    end       
end

local function DisplayLingJing()
    UIManager.show("common.dlgdialogbox_common",{callBackFunc=function(commonFields)
        commonFields.UIGroup_ItemUse.gameObject:SetActive(true)
        commonFields.UIGroup_Button_2.gameObject:SetActive(false)
        commonFields.UIGroup_Button_1.gameObject:SetActive(true)
        commonFields.UIGroup_IconTitle.gameObject:SetActive(false)
        commonFields.UIButton_ItemUseBox.gameObject:SetActive(true)
        local currency = ItemManager.CreateItemBaseById(cfg.currency.CurrencyType.LingJing)
        commonFields.UITexture_ItemSellICON:SetIconTexture(currency:GetTextureName())
        commonFields.UILabel_Title.text=LocalString.Cornucopia_Return
        commonFields.UILabel_ItemUse_Name.text=""
        commonFields.UILabel_ItemUse_Describe.text=(LocalString.Cornucopia_LingJing)..(m_ReceivedLingJing)
        EventHelper.SetClick(commonFields.UIButton_Close,function()
            RefreshSlots()
            UIManager.hide("common.dlgdialogbox_common")
        end)
        EventHelper.SetClick(commonFields.UIButton_1,function()
            RefreshSlots()
            UIManager.hide("common.dlgdialogbox_common")
        end)
    end
    })
end

local function OnMsg_STreasureBowlBreak(msg)
    m_ReceivedLingJing=msg.receivedlingjing   
    UIManager.PlayUIParticleSystem(m_Fields.UIGroup_AnnealEffect_jubaopen.gameObject)  
    m_PlayParticle=true    
end

local function refresh(params)
    RefreshSlots()
end

local function SetDialogVisible(visible)
    m_Fields.UIGroup_Right.gameObject:SetActive(visible)
    m_Fields.UITexture_Stove.gameObject:SetActive(visible)
    m_Fields.UISprite_RightBG.gameObject:SetActive(visible)
    m_Fields.UISprite_LeftBG.gameObject:SetActive(visible)
end

local function IsEnhanced()
    local result=false
    for _,pos in pairs(m_SelectedEquips) do
        local item=BagMgr.GetItemBySlot(cfg.bag.BagType.EQUIP,pos)
        if (item:GetAnnealLevel() > 0) or (item:GetPerfuseLevel() > 0) then
            result=true
            break
        end
    end
    return result
end

local function IsHasRed()
    local result=false
    for _,pos in pairs(m_SelectedEquips) do
        local item=BagMgr.GetItemBySlot(cfg.bag.BagType.EQUIP,pos)
        if (item:GetQuality()==cfg.item.EItemColor.RED) then
            result=true
            break
        end
    end
    return result
end

local function init(params)
   
    m_Name, m_GameObject, m_Fields = Unpack(params)  
    m_Fields.UILabel_TotalPrice.text=0
    
    EventHelper.SetClick(m_Fields.UIToggle_Green,function()
        if m_Fields.UIToggle_Green.value then
            SetItemSelectedByColor(cfg.item.EItemColor.GREEN,true)
        else
            SetItemSelectedByColor(cfg.item.EItemColor.GREEN,false)
        end
    end)
    EventHelper.SetClick(m_Fields.UIToggle_Blue,function()
        if m_Fields.UIToggle_Blue.value then
            SetItemSelectedByColor(cfg.item.EItemColor.BLUE,true)
        else
            SetItemSelectedByColor(cfg.item.EItemColor.BLUE,false)
        end
    end)
    EventHelper.SetClick(m_Fields.UIToggle_Purple,function()
        if m_Fields.UIToggle_Purple.value then
            SetItemSelectedByColor(cfg.item.EItemColor.PURPLE,true)
        else
            SetItemSelectedByColor(cfg.item.EItemColor.PURPLE,false)
        end
    end)
    EventHelper.SetClick(m_Fields.UIButton_Decomposition,function()
        if #m_SelectedEquips>0 then
            if IsHasRed()~=true then
                if IsEnhanced()==true then
                    UIManager.ShowAlertDlg({content=LocalString.CornuCopia_Enhanced,immediate=true,callBackFunc=function()
                        local msg = lx.gs.treasurebowl.CTreasureBowlBreak({ poslist=m_SelectedEquips})
                        NetWork.send(msg)
                    end})
                else
                    local msg = lx.gs.treasurebowl.CTreasureBowlBreak({ poslist=m_SelectedEquips})
                    NetWork.send(msg)
                end
            else
                UIManager.ShowSingleAlertDlg({content=LocalString.CornuCopia_HasRed})
            end
        else
            UIManager.ShowSingleAlertDlg({content=LocalString.CornuCopia_NoEquip})
        end
    end)
    m_ListenerId=NetWork.add_listener( 
         "lx.gs.treasurebowl.STreasureBowlBreak", OnMsg_STreasureBowlBreak
    )
end

local function update()
    if m_PlayParticle==true then     
        if not UIManager.IsPlaying(m_Fields.UIGroup_AnnealEffect_jubaopen.gameObject) then
			      DisplayLingJing()
            m_PlayParticle=nil            
            UIManager.StopUIParticleSystem(m_Fields.UIGroup_AnnealEffect_jubaopen.gameObject)           
        end
    end
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
}