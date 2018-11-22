local unpack = unpack
local print = print
local DefineEnum = require("defineenum")
local EventHelper = UIEventListenerHelper
local uimanager = require("uimanager")
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local ConfigManager 	  = require "cfg.configmanager"
local PlayerRole=require("character.playerrole"):Instance()
local bonusmanager 	  = require "item.bonusmanager"
local FamilyRoundRobinManager = require("family.familyroundrobinmanager")
--ui
local fields
local gameObject
local name

local Max_Item_Per_Page = 4
local m_CurrentPage
local m_Totalpage

--data
--[[
<bean name="AllocLog">
	<variable name="name" type="string"/>
	<variable name="gender" type="int"/>
	<variable name="level" type="int"/>
	<variable name="viplevel" type="int"/>
	<variable name="profession" type="int"/>
	<variable name="bonus" type="map.msg.Bonus"/>
	<variable name="time" type="long"/>
</bean>
--]]
local m_AllocationList --<variable name="logs" type="list" value="AllocLog"/>

local function ShowItem(bonusitem, listitem)
    --printyellow("[tabworldterritoryrewarddistribution:ShowItem] Show bonusitem:")
    --printt(bonusitem)

    if bonusitem and listitem then
        --data
        listitem.Id = bonusitem:GetConfigId()
        listitem.Data = bonusitem

        --icon
        listitem:SetIconTexture(bonusitem:GetIconPath())
        --printyellow(string.format("[tabworldterritoryrewarddistribution:ShowItem] bonusitem:GetIconPath()=[%s]", bonusitem:GetIconPath()))

        --count
        local UILabel_Amount = listitem.Controls["UILabel_Amount"]
        if UILabel_Amount then
            UILabel_Amount.gameObject:SetActive(true)
            UILabel_Amount.text = bonusitem:GetNumber()
        end
    end
end

local function ShowBonus(bonus, uilist)
    if bonus and uilist then
        --printyellow("[tabworldterritoryrewarddistribution:ShowBonus] bonus:")
        --printt(bonus)

        uilist:Clear()
        local bonusitems = bonusmanager.GetItemsOfServerBonus(bonus)
        if bonusitems and table.getn(bonusitems)>0 then
            local listitem
            for _, bonusitem in ipairs(bonusitems) do
                if bonusitem then
                    listitem = uilist:AddListItem()
                    ShowItem(bonusitem, listitem)
                end
            end
        end
    end
end

--[[
<bean name="AllocLog">
	<variable name="name" type="string"/>
	<variable name="gender" type="int"/>
	<variable name="level" type="int"/>
	<variable name="viplevel" type="int"/>
	<variable name="profession" type="int"/>
	<variable name="familyname" type="string"/>
	<variable name="bonus" type="map.msg.Bonus"/>
	<variable name="time" type="long"/>
</bean>
--]]
local function ShowAllocation(listitem, allocation)
    if nil==listitem or nil==allocation then return end

    --info
    listitem.Data = allocation
    --printyellow(string.format("[tabworldterritoryrewarddistribution:OnUIList_MemberRefresh] allocation at realIndex[%s]:", realIndex))
    --printt(allocation)

    --head
    local UITexture_Head = listitem.Controls["UITexture_Head"]
    UITexture_Head:SetIconTexture(ConfigManager.GetHeadIcon(allocation.profession, allocation.gender))

    --me sprite
    listitem.Controls["UISprite_Me"].gameObject:SetActive(allocation.name == PlayerRole:GetName())

    --vip
    listitem.Controls["UISprite_VIP"].gameObject:SetActive(allocation.viplevel > 0)
    listitem.Controls["UILabel_VIP"].text = allocation.viplevel > 0 and allocation.viplevel or ""

    --lv
    listitem.Controls["UILabel_LV"].text = string.format("%d", allocation.level)

    --name
    listitem.Controls["UILabel_Name"].text = allocation.name

    --family
    listitem.Controls["UILabel_Family"].text = allocation.familyname

    --award
    ShowBonus(allocation.bonus, listitem.Controls["UIList_Awards"])
end

local function ShowPage(pageindex)
    if pageindex and pageindex>0 and pageindex<=m_Totalpage then
        --printyellow("[tabworldterritoryrewarddistribution:ShowPage] show page:", pageindex)
        --reset
        m_CurrentPage = pageindex
        fields.UILabel_Page.text = m_CurrentPage.."/"..m_Totalpage
        fields.UIList_Member:Clear()
        
        --show
        if m_AllocationList and table.getn(m_AllocationList)>0 then
            local listitem
            local allocation
            for index=(m_CurrentPage-1)*Max_Item_Per_Page+1, m_CurrentPage*Max_Item_Per_Page do
                allocation = m_AllocationList[index]
                if allocation then
                    listitem = fields.UIList_Member:AddListItem()
                    ShowAllocation(listitem, allocation)                
                end
            end
        end
    end
end

local function CompareAllocLog(log1, log2)
    if log1 and log2 then
        return log1.time >= log2.time
    else
        return true
    end
end

local function refresh(msg)
    --printyellow("[tabworldterritoryrewarddistribution:refresh] refresh tabworldterritoryrewarddistribution:")
    --printt(msg)    
    m_AllocationList = {}
    m_CurrentPage = 1    
    m_Totalpage = 0
    fields.UIList_Member:Clear() 
    fields.UILabel_Page.text = ""    
    if msg and msg.logs then        
        m_AllocationList = msg.logs
        utils.table_sort(m_AllocationList, CompareAllocLog)
        if m_AllocationList and table.getn(m_AllocationList)>0 then
            m_Totalpage = math.ceil(table.getn(m_AllocationList)/Max_Item_Per_Page)
            if m_CurrentPage<1 then
                m_CurrentPage = 1
            end
            if m_CurrentPage>m_Totalpage then
                m_CurrentPage = m_Totalpage
            end
            ShowPage(m_CurrentPage)
        end
    end
end

local function show(params)
    --printyellow("[tabworldterritoryrewarddistribution:show] show tabworldterritoryrewarddistribution.")
    if params.type == DefineEnum.RewardDistributionType.Territory then
        citywarmanager.send_CGetAllocLog()   
    elseif params.type == DefineEnum.RewardDistributionType.RoundRobin then
        FamilyRoundRobinManager.SendCGetAllocLog()
    end
end

local function hide()
end

local function destroy()
end

local function update()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function OnUIButton_Close()
    uimanager.hide("citywar.tabworldterritoryrewarddistribution")
end

local function OnUIButton_ArrowsLeft()
    --printyellow("[tabworldterritoryrewarddistribution:OnUIButton_ArrowsLeft] prepare show page:", m_CurrentPage-1)
    if m_CurrentPage>1 then
        ShowPage(m_CurrentPage-1)
    end
end

local function OnUIButton_ArrowsRight()
    --printyellow("[tabworldterritoryrewarddistribution:OnUIButton_ArrowsRight] prepare show page:", m_CurrentPage+1)
    if m_CurrentPage<m_Totalpage then
        ShowPage(m_CurrentPage+1)
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)

    --buttons
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_ArrowsLeft, OnUIButton_ArrowsLeft)
    EventHelper.SetClick(fields.UIButton_ArrowsRight, OnUIButton_ArrowsRight)  
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
