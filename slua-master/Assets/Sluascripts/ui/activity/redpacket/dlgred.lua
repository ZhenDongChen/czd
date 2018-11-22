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

--ui
local fields
local gameObject
local name

local m_RedPacketInfo

local function reset()
    m_RedPacketInfo = nil
end

local function ShowCurrency(msg)
    local currencydata = ItemManager.CreateItemBaseById(msg.moneytype, nil, msg.money)
    if nil==currencydata then
        print("[ERROR][dlgred:ShowCurrency] currencydata nil!")
        fields.UIGroup_Property.gameObject:SetActive(false)  
        return 
    else
        printyellow("[dlgred:ShowCurrency] currencydata:")
        printt(currencydata)
    end

    printyellow(string.format("[dlgred:ShowCurrency] show Currency[%s]!", currencydata:GetName()))

    --icon
    fields.UITexture_Icon:SetIconTexture(currencydata:GetIconPath())
        
    --quality
    fields.UISprite_Quality.color = colorutil.GetQualityColor(currencydata:GetQuality())
        
    --fragment   
    fields.UISprite_Fragment.gameObject:SetActive(currencydata:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        
    --count    
    fields.UILabel_Amount.gameObject:SetActive(true)
    fields.UILabel_Amount.text = currencydata:GetNumber()
end

local function ShowOpenRedPacketFail(msg)
    printyellow("[dlgred:ShowOpenRedPacketFail] msg:", msg)
    fields.UITexture_Red.gameObject:SetActive(false)
    fields.UITexture_RedOpen.gameObject:SetActive(true)
    fields.UISprite_Congratulation.gameObject:SetActive(false)    
    fields.UIGroup_Property.gameObject:SetActive(false)
    fields.UILabel_FailRed.gameObject:SetActive(true)
    fields.UILabel_Name.gameObject:SetActive(false)    

    fields.UITexture_RedOpen:SetIconTexture(redpacketinfo.GetBGOpen())
    local failreason = ""
    if msg.errcode==cfg.error.ErrorCode.GET_MONEY_FAIL then
        failreason = LocalString.Red_Packet_Open_Fail_Empty
    elseif msg.errcode==cfg.error.ErrorCode.EXCEED_MAX_GET_MONEY_TIME then
        failreason = LocalString.Red_Packet_Open_Fail_Exceed
    elseif msg.errcode==cfg.error.ErrorCode.HAS_RECEIVE_THIE_RED_PACKAGE then
        failreason = LocalString.Red_Packet_Open_Fail_Fetched
    end
    fields.UILabel_FailRed.text = failreason
end

local function ShowOpenRedPacketSuccess(msg)
    fields.UITexture_Red.gameObject:SetActive(false)
    fields.UITexture_RedOpen.gameObject:SetActive(true)
    fields.UISprite_Congratulation.gameObject:SetActive(true)    
    fields.UIGroup_Property.gameObject:SetActive(true)
    fields.UILabel_FailRed.gameObject:SetActive(false)
    fields.UILabel_Name.gameObject:SetActive(true)    
    
    fields.UITexture_RedOpen:SetIconTexture(redpacketinfo.GetBGOpen())
    ShowCurrency(msg)
    fields.UILabel_Name.text = string.format(LocalString.Red_Packet_Open_Success, m_RedPacketInfo.sendername)
end

local function ShowFoldRedPacket()
    fields.UITexture_Red.gameObject:SetActive(true)
    fields.UITexture_RedOpen.gameObject:SetActive(false)
    fields.UISprite_Congratulation.gameObject:SetActive(false)    
    fields.UIGroup_Property.gameObject:SetActive(false)
    fields.UILabel_FailRed.gameObject:SetActive(false)
    fields.UILabel_Name.gameObject:SetActive(true)    
    
    fields.UITexture_Red:SetIconTexture(redpacketinfo.GetBGClose())
    fields.UILabel_Name.text = m_RedPacketInfo.sendername
end

local function ShowNoRedPacket()
    fields.UITexture_Red.gameObject:SetActive(false)
    fields.UITexture_RedOpen.gameObject:SetActive(false)
    fields.UISprite_Congratulation.gameObject:SetActive(false)    
    fields.UIGroup_Property.gameObject:SetActive(false)
    fields.UILabel_FailRed.gameObject:SetActive(true)
    fields.UILabel_Name.gameObject:SetActive(false)    
    fields.UIButton_Setting.gameObject:SetActive(false) 
    
    fields.UILabel_FailRed.text = LocalString.Red_Packet_Receive_None_Packet
end

local function show()
    --ResetUI()

    --printyellow("[dlgred:show] show dlgred.")
    m_RedPacketInfo = redpacketinfo.GetUnfetchedPacket()
    if m_RedPacketInfo then
        ShowFoldRedPacket()
    else
        ShowNoRedPacket()
    end
end

local function refresh(msg)
    printyellow("[dlgred:refresh] refresh dlgred.")
    if msg then
        if msg.result==lx.gs.springactivity.msg.SGetMoneyNotify.OK then
            ShowOpenRedPacketSuccess(msg)
        else    
            ShowOpenRedPacketFail(msg)
        end
    end
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

local function OnUIButton_Close()
    UIManager.hidedialog("activity.redpacket.dlgred")
end

local function OnUIButton_Open()
    printyellow("[dlgred:OnUIButton_Open] UIButton_Open clicked.")
    if m_RedPacketInfo then
        redpacketmanager.send_CGetMoney(m_RedPacketInfo.packageid)
    else
        UIManager.hidedialog("activity.redpacket.dlgred")
    end    
end

local function OnUIButton_Detail()
    if m_RedPacketInfo then
        redpacketmanager.send_CGetRoleList(m_RedPacketInfo.packageid)
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)

    reset()

    --ui
    --EventHelper.SetListClick(fields.UIList_Rewards, OnAwardItemClicked)
    EventHelper.SetClick(fields.UIButton_Black, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_Open, OnUIButton_Open)
    EventHelper.SetClick(fields.UITexture_Red, OnUIButton_Open)    
    EventHelper.SetClick(fields.UIButton_Setting, OnUIButton_Detail)        
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
