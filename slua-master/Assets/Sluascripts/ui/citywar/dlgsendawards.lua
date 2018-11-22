local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local define = require "define"
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local FamilyRoundRobinManager = require("family.familyroundrobinmanager")
local bonusmanager 	  = require "item.bonusmanager"
local colorutil		   = require "common.colorutil"
local ItemEnum = require"item.itemenum"
local DefineEnum = require("defineenum")

--ui
local fields
local gameObject
local name

--data
local m_Type
local m_TargetRoleId
local m_BindType

local function ShowItem(bonusitem, listitem)
    --printyellow("[dlgsendawards:ShowItem] Show bonusitem:")
    --printt(bonusitem)

    if bonusitem and listitem then
        --data
        listitem.Id = bonusitem:GetConfigId()
        listitem.Data = bonusitem

        --icon
        listitem:SetIconTexture(bonusitem:GetIconPath())

        local UILabel_FlowerName = listitem.Controls["UILabel_FlowerName"]
        if UILabel_FlowerName then
            UILabel_FlowerName.text = bonusitem:GetName()
            colorutil.SetQualityColorText(UILabel_FlowerName, bonusitem:GetQuality(), bonusitem:GetName())
        end

        --count
        local UILabel_Amount = listitem.Controls["UILabel_Amount"]
        if UILabel_Amount then
            UILabel_Amount.gameObject:SetActive(true)
            UILabel_Amount.text = bonusitem:GetNumber()
        end

        --quality
        local UISprite_Quality = listitem.Controls["UISprite_Quality"]
        if UISprite_Quality then
            UISprite_Quality.spriteName = colorutil.GetQualitySprite(bonusitem:GetQuality())
        end

        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(bonusitem:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end

        --add reduce
        local UIButton_Reduce = listitem.Controls["UIButton_Reduce"]
        local UIButton_Add = listitem.Controls["UIButton_Add"]
        local UILabel_SendFlowerNum = listitem.Controls["UILabel_SendFlowerNum"]
        if UIButton_Reduce and UIButton_Add and UILabel_SendFlowerNum then
            UILabel_SendFlowerNum.text = 0
            --reduce
            EventHelper.SetClick(UIButton_Reduce, function()
                local currentnum = tonumber(UILabel_SendFlowerNum.text)
                if currentnum and currentnum>0 then
                    UILabel_SendFlowerNum.text = currentnum-1
                else
                    UILabel_SendFlowerNum.text = 0
                end
            end)
            --add
            EventHelper.SetClick(UIButton_Add, function()
                local currentnum = tonumber(UILabel_SendFlowerNum.text)
                if currentnum and currentnum<bonusitem:GetNumber() then
                    UILabel_SendFlowerNum.text = currentnum+1
                else
                    UILabel_SendFlowerNum.text = bonusitem:GetNumber()
                end
            end)
        end
    end
end

local function ShowLuckyBonus()    
    fields.UIList_Flowers:Clear()
    local familybonus
    if m_Type and m_Type == DefineEnum.RewardDistributionType.RoundRobin then
        familybonus = FamilyRoundRobinManager.GetRemainBonus()
    else
        familybonus = citywarinfo.GetFamilyLuckyBonus()
    end
    if familybonus then   
        m_BindType = familybonus.bindtype
        local bonusitems = bonusmanager.GetItemsOfServerBonus(familybonus)

        if bonusitems and table.getn(bonusitems)>0 then
            local listitem
            for _, bonusitem in ipairs(bonusitems) do
                if bonusitem then
                    listitem = fields.UIList_Flowers:AddListItem()      
                    ShowItem(bonusitem, listitem)                
                end
            end        
        end    
    end
	fields.UIList_Flowers.gameObject:GetComponent(UIGrid).enabled = true
end 

local function refresh()
    ShowLuckyBonus()
	
	
end

local function show(params)
    m_Type = params.type
    m_TargetRoleId = params.roleId
end

local function destroy()
end

local function hide()
end

local function update()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function OnUIButton_Close()
    uimanager.hide("citywar.dlgsendawards")
end

local function OnUIButton_Cancel()
    uimanager.hide("citywar.dlgsendawards")
end

--[[
<bean name="Bonus">
	<variable name="bindtype" type="int"/>
	<variable name="items" type="map" key="int" value="int"/> 物品，包含装备,碎片和消耗性物品
</bean>
--]]
local function SendBonus(sendbonus)
    if sendbonus and sendbonus.items then   
        for allocateid,allocatecount in pairs(sendbonus.items) do
            if allocateid and allocateid>0 and allocatecount and allocatecount>0 then
                if m_Type and m_Type == DefineEnum.RewardDistributionType.RoundRobin then
                    FamilyRoundRobinManager.SendCAllocBonus(m_TargetRoleId,sendbonus)
                else
                    citywarmanager.send_CAllocBonus(m_TargetRoleId, sendbonus)
                end
                return
            end
        end
    end
    if Local.LogManager then  
        print("[ERROR][dlgsendawards:SendBonus] send failed, nothing selected!")
    end    
end

local function OnUIButton_Sure()
    if nil==m_TargetRoleId then
        if Local.LogManager then
            print("[ERROR][dlgsendawards:OnUIButton_Sure] m_TargetRoleId nil!")
        end    
    end    

    local sendbonus = {}
    sendbonus.bindtype = m_BindType
    sendbonus.items = {}

    local listitem
    local UILabel_SendFlowerNum
    local allocatecount
    local allocateid
    for index=0, (fields.UIList_Flowers.Count-1) do
        listitem = fields.UIList_Flowers:GetItemByIndex(index)
        UILabel_SendFlowerNum = listitem and listitem.Controls["UILabel_SendFlowerNum"] or nil
        allocatecount = UILabel_SendFlowerNum and tonumber(UILabel_SendFlowerNum.text) or 0
        allocateid = listitem and listitem.Id or nil
        if allocateid and allocateid>0 and allocatecount and allocatecount>0 then
            table.insert(sendbonus.items, allocateid, allocatecount)
        end
    end
    SendBonus(sendbonus)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    
    --ui
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_Cancel, OnUIButton_Cancel)
    EventHelper.SetClick(fields.UIButton_Sure, OnUIButton_Sure)
    
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
}
