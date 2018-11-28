local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local FriendManager = require("ui.friend.friendmanager")
local ConfigManager = require("cfg.configmanager")
local EventHelper 	= UIEventListenerHelper
local ItemManager   = require("item.itemmanager")
local BonusManager  = require("item.bonusmanager")

local name, gameObject, fields
local m_RedPacketInfos

--[[
<protocol name="SGetRoleList">
	<variable name="packageid" type="long"/>
	<variable name="moneytype" type="int"/>
	<variable name="roles" type="map" key="string" value="int"/>
</protocol>
--]]
local function GetInfoContent(info)
    local labelstring = ""
    if info then
        --local currencydata = ItemManager.CreateItemBaseById(info.moneytype, nil, info.number)
        local items = BonusManager.GetItemsOfServerBonus(info.bonus)
        if #items > 0 then
            --labelName.text = items[1]:GetName()
            --labelCount.text = string.format("X%s", tostring(items[1]:GetNumber()))
            labelstring = string.format(LocalString.Red_Packet_Fetch_Info, items[1]:GetNumber(), items[1]:GetName())
        end    
    end
    return labelstring
end
local function CoverBonus(records)
    m_RedPacketInfos = {}
    for i, itInfo in pairs(records) do
        local bonusTmp = {}
        bonusTmp.bindtype = itInfo.bonus.bindtype
        bonusTmp.items = {}
        for j, itBonus in pairs(itInfo.bonus.items) do
            table.insert(bonusTmp.items, itBonus)
        end
        for k, itCurrency in pairs(itInfo.currency) do
            table.insert(bonusTmp.items, k, itCurrency)
        end
        table.insert(m_RedPacketInfos, {name=itInfo.rolename, bonus=bonusTmp})
    end
end

local function InitInfos(params)
    local wrapList = fields.UIList_BattlefieldReport.gameObject:GetComponent("UIWrapContentList")

    if params then
        fields.UIGroup_Empty.gameObject:SetActive(false)
        wrapList.gameObject:SetActive(true)
        CoverBonus(params.records)

        --title
        fields.UILabel_Title.text = params.sendername..LocalString.Red_Packet_Fetch_Title

        --list
        if wrapList then
            EventHelper.SetWrapListRefresh(wrapList,function(uiItem,index,realIndex)
                local uiLabel = uiItem.Controls["UILabel_ReportInfo"]
                if uiLabel then
                    uiLabel.text = m_RedPacketInfos[realIndex].name
                end
                uiLabel = uiItem.Controls["UILabel_ItemInfo"]
                if uiLabel and m_RedPacketInfos[realIndex]~=nil then
                    uiLabel.text = GetInfoContent(m_RedPacketInfos[realIndex])
                end
            end)
            wrapList:SetDataCount(#params.records)
        end
    else
        --is empty
        fields.UIGroup_Empty.gameObject:SetActive(true)
        wrapList.gameObject:SetActive(false)
        fields.UILabel_Empty.text = LocalString.Red_Packet_Fetch_None
    end
end

local function show(params)
    fields.UITexture_BG1:SetIconTexture("Texture_Hongbao_open")
    --info
    InitInfos(params)
end

local function destroy()
end

local function refresh(params)
    InitInfos(params)
end

local function hide()
end

local function update()
end


local function init(params)
	name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_CloseReport, function()
        UIManager.hide(name)
    end)
    EventHelper.SetClick(fields.UIButton_OK, function()
        UIManager.hide(name)
    end)
    EventHelper.SetClick(fields.UIButton_Desc, function()
        fields.UIGroup_Desc.gameObject:SetActive(true)
    end)
    EventHelper.SetClick(fields.UIButton_DescBG, function()
        fields.UIGroup_Desc.gameObject:SetActive(false)
    end)
end

local function uishowtype()
    return UIShowType.Refresh
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
