local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local redpacketinfo = require"ui.activity.redpacket.redpacketinfo"
local redpacketmanager = require"ui.activity.redpacket.redpacketmanager"
local UIManager       = require("uimanager")
local ItemManager = require("item.itemmanager")
local colorutil = colorutil
local ItemIntroduct=require"item.itemintroduction"
local ItemEnum = require"item.itemenum"
local FamilyManager = require("family.familymanager")

--ui
local fields
local gameObject
local name

local function reset()
end

local function ShowPacket(listitem, packetitem, packetinfo)
    if nil==listitem then
        print("[ERROR][dlgsendred:ShowPacket] listitem nil at index[%s]!")
    end
    if nil==packetitem then
        print("[ERROR][dlgsendred:ShowPacket] packetitem nil at index[%s]!")
    end

    if listitem and packetitem then
        --printyellow(string.format("[dlgsendred:ShowBonus] show award[%s] on listitem[%s]!", packetitem:GetName(), listitem.gameObject.name))
        listitem.Data = packetinfo

        --icon
        local UITexture_Icon = listitem.Controls["UITexture_RedType"]
        if UITexture_Icon then
            UITexture_Icon:SetIconTexture(packetitem:GetIconPath())
        end
        
        --quality
        local spriteQuality = listitem.Controls["UISprite_Quality"]
        if spriteQuality then
            spriteQuality.color = colorutil.GetQualityColor(packetitem:GetQuality())
        end
                
        --name
        local labelName = listitem.Controls["UILabel_RedName"]
        if labelName then
            --labelName.text = packetitem:GetName()
            colorutil.SetQualityColorText(labelName, packetitem:GetQuality(), packetitem:GetName())
        end
        
        --count
        local UILabel_Amount = listitem.Controls["UILabel_TotalRedNum"]
        if UILabel_Amount then
            UILabel_Amount.gameObject:SetActive(true)
            UILabel_Amount.text = redpacketinfo.GetRedPacketCountById(packetitem:GetConfigId()) --packetitem:GetNumber()
        end
        
        --[[
        --choose
        local UIButton_Choose = listitem.Controls["UIButton_ChooseFlower"]
        if UIButton_Choose then
             EventHelper.SetClick(UIButton_Choose, function()
                m_ChoosenPacketInfo = packetinfo
            end)
        end
        --]]
    end
end

local function ShowRedPackets()
    fields.UIList_Red:Clear()

    local allredpacketinfo = redpacketinfo.GetAllRedPacketInfo()
    if allredpacketinfo then
        local packetitem
        local listitem
        for _,packetinfo in ipairs(allredpacketinfo) do
            packetitem=ItemManager.CreateItemBaseById(packetinfo.needitemid)
            if packetitem then
                listitem = fields.UIList_Red:AddListItem()
                ShowPacket(listitem, packetitem, packetinfo)
            end
        end
    end
end

local function ShowChatChannels()
end

local function ShowSendLimit()
    fields.UILabel_Num.text = string.format(LocalString.Red_Packet_Send_Statistic, redpacketinfo.GetSendCount(), redpacketinfo.GetSendLimit())
end

local function refresh()
    printyellow("[dlgsendred:refresh] refresh dlgsendred.")
    ShowRedPackets()
    ShowChatChannels()
    ShowSendLimit()
end

local function show()
    printyellow("[dlgsendred:show] show dlgsendred.")
end

local function destroy()
end

local function hide()
    reset()
end

local function update()
end

local function second_update()  
end

local function uishowtype()
	return UIShowType.Refresh
end

local function IsSendChoosen(listitem)
    local result = false
    if listitem then
        local UIButton_Send = listitem.Controls["UIButton_ChooseFlower"]
        if UIButton_Send then
            local UIToggle_Select= UIButton_Send.gameObject.transform:GetComponent("UIToggle")
            if UIToggle_Select then
                result = UIToggle_Select.value
                --printyellow(string.format("[dlgsendred:IsSendChoosen] listitem[%s].UIToggle.value=[%s]", listitem.gameObject.name, result))
            else
                printyellow("[dlgsendred:IsSendChoosen] UIToggle nil!")
            end   
        else
            printyellow("[dlgsendred:IsSendChoosen] UIButton_ChooseFlower nil!")
        end
    end
	return result
end

local function GetChoosenPacket()
    local choosenpacket = nil
    local listitem = nil
    for i=0, fields.UIList_Red.Count-1 do
        listitem = fields.UIList_Red:GetItemByIndex(i)        
        if true==IsSendChoosen(listitem) then
            choosenpacket = listitem.Data
            --printyellow("[dlgsendred:GetChoosenPacket] :")
            --printt(choosenpacket)
            break
        end
    end
    return choosenpacket 
end

local function IsListitemChoosen(listitem)
    local result = false
    if listitem then
        local UIToggle_Select= listitem.gameObject.transform:GetComponent("UIToggle")
        if UIToggle_Select then
            result = UIToggle_Select.value
        end
    end
	return result
end

local function GetChoosenChannel()
    local choosenchannel = nil
    --[[
    if fields.UIToggle_CheckBox01 and true==fields.UIToggle_CheckBox01.value then
        choosenchannel = cfg.chat.ChannelType.WORLD
    elseif fields.UIToggle_CheckBox02 and true==fields.UIToggle_CheckBox02.value then
        choosenchannel = cfg.chat.ChannelType.FAMILY
    end    
    --]]

    local listitem = fields.UIList_Channel:GetItemByIndex(0)
    if nil==listitem then
        printyellow("[dlgsendred:GetChoosenChannel] listitem nil at 0")
    end
    if IsListitemChoosen(listitem) then
        choosenchannel = cfg.chat.ChannelType.WORLD
    else
        listitem = fields.UIList_Channel:GetItemByIndex(1)
        if nil==listitem then
            printyellow("[dlgsendred:GetChoosenChannel] listitem nil at 1")
        end
        if IsListitemChoosen(listitem) then
            choosenchannel = cfg.chat.ChannelType.FAMILY
        end
    end
    --printyellow("[dlgsendred:GetChoosenChannel] choosenchannel=", choosenchannel)
    return choosenchannel
end

local function OnUIButton_Send()
    local choosenpacketinfo = GetChoosenPacket()
    if nil==choosenpacketinfo then
        UIManager.ShowSingleAlertDlg({content=LocalString.Red_Packet_Choose_Packet})
        return
    end

    local choosenchannel = GetChoosenChannel()
    if nil==choosenchannel then
        UIManager.ShowSingleAlertDlg({content=LocalString.Red_Packet_Choose_Channel})
        return
    end

    if redpacketinfo.GetSendCount()>=redpacketinfo.GetSendLimit() then
        UIManager.ShowSingleAlertDlg({content=LocalString.Red_Packet_Send_Limit})
        return    
    end
    
    if redpacketinfo.GetRedPacketCountById(choosenpacketinfo.needitemid)<=0 then
        --UIManager.ShowSingleAlertDlg({content=LocalString.Red_Packet_No_Packet})
        UIManager.ShowAlertDlg({immediate = true,content = LocalString.Red_Packet_Go_Shop,sureText = LocalString.Ride_GoTo,callBackFunc = function()
                            UIManager.showdialog("dlgshop_common", nil, 1)
                        end})
        return    
    end
    
    local familyid = FamilyManager.GetFamilyId()
    if (nil==familyid or familyid<1) and choosenchannel==cfg.chat.ChannelType.FAMILY then
        UIManager.ShowSingleAlertDlg({content=LocalString.Red_Packet_No_Family})
        return  
    end

    redpacketmanager.send_CSendMoneyPackage(choosenpacketinfo.id, "", choosenchannel)
end

local function OnRedItemClicked(listitem)
    if listitem and listitem.Data then
        --printyellow(string.format("[dlgsendred:OnTurntableItemClicked] [%s] clicked!", listitem.gameObject.name))
        local params={item=listitem.Data, buttons={{display=false,text="",callFunc=nil}, {display=false,text="",callFunc=nil}}}
        ItemIntroduct.DisplayBriefItem(params) 
    end
end

local function OnUIButton_Close()
    UIManager.hidedialog("activity.redpacket.dlgsendred")
end

local function init(params)
    name, gameObject, fields = unpack(params)

    reset()

    --ui
    EventHelper.SetListClick(fields.UIList_Red, OnRedItemClicked)
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_Send, OnUIButton_Send)    
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  second_update = second_update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
}
