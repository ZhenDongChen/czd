local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper

local ConfigManager = require "cfg.configmanager"
local BonusManager = require("item.bonusmanager")
local define = require "define"
local PlayerRole = require "character.playerrole"
local Pet                   = require"character.pet.pet"
local springfestivalinfo = require"ui.activity.springfestival.springfestivalinfo"
local springfestivalmanager = require"ui.activity.springfestival.springfestivalmanager"
local UIManager       = require("uimanager")
local ItemManager = require("item.itemmanager")
local colorutil = colorutil
local VipChargeManager=require"ui.vipcharge.vipchargemanager"
local ItemIntroduct=require"item.itemintroduction"
local ItemEnum = require"item.itemenum"

--ui
local fields
local gameObject
local name

local m_CurrentDailyBonus

local function reset()
    m_CurrentDailyBonus = nil
end

local function ShowBonus(listitem, bonusitem)
    if nil==listitem then
        print("[ERROR][dlgspringfestivalgifts:ShowTurnTableBonus] listitem nil at index[%s]!")
    end
    if nil==bonusitem then
        print("[ERROR][dlgspringfestivalgifts:ShowTurnTableBonus] bonusitem nil at index[%s]!")
    end

    if listitem and bonusitem then
        printyellow(string.format("[dlgspringfestivalgifts:ShowBonus] show award[%s] on listitem[%s]!", bonusitem:GetName(), listitem.gameObject.name))
        listitem.Data = bonusitem

        --icon
        local UITexture_Icon = listitem.Controls["UITexture_Icon"]
        if UITexture_Icon then
            UITexture_Icon:SetIconTexture(bonusitem:GetIconPath())
        end
        
        --quality
        local spriteQuality = listitem.Controls["UISprite_Quality"]
        if spriteQuality then
            spriteQuality.color = colorutil.GetQualityColor(bonusitem:GetQuality())
        end
        
        --fragment        
        local UISprite_Fragment=listitem.Controls["UISprite_Fragment"]
        if UISprite_Fragment then
            UISprite_Fragment.gameObject:SetActive(bonusitem:GetBaseType()==ItemEnum.ItemBaseType.Fragment)
        end
        
        --count
        local UILabel_Amount = listitem.Controls["UILabel_Amount"]
        if UILabel_Amount then
            UILabel_Amount.gameObject:SetActive(true)
            UILabel_Amount.text = bonusitem:GetNumber()
        end
    end
end

local function ShowCurrentDailyBonus()
    fields.UIList_Rewards:Clear()

    if m_CurrentDailyBonus then
        local bonusList = BonusManager.GetMultiBonusItems(m_CurrentDailyBonus.bonus)
        if bonusList and #bonusList>0 then   
            --printyellow(string.format("[ERROR][dlgspringfestivalgifts:ShowTurnTable] #bonusList = [%s]!", #bonusList))
            local listitem
            for _,bonusitem in ipairs(bonusList) do
                listitem = fields.UIList_Rewards:AddListItem()
                ShowBonus(listitem, bonusitem)
            end
        end    
    end
end

local function ShowCurrentBonusState()
    local stringbutton = LocalString.Spring_Festival_Award_Fetched_Button
    local stringlabel = LocalString.Spring_Festival_Award_Fetched
    if m_CurrentDailyBonus then
        if springfestivalinfo.IsDailyBonusFetched(m_CurrentDailyBonus) then
            stringbutton = LocalString.Spring_Festival_Award_Fetched_Button
            stringlabel = LocalString.Spring_Festival_Award_Fetched
            fields.UIButton_GetRewards.isEnabled = false
        else
            if springfestivalinfo.GetLoginTime()>=m_CurrentDailyBonus.time then
                stringbutton = LocalString.Spring_Festival_Award_Fetch_Button
                stringlabel = LocalString.Spring_Festival_Award_Ready
                fields.UIButton_GetRewards.isEnabled = true
            else
                stringbutton = LocalString.Spring_Festival_Award_Fetch_Button
                stringlabel = timeutils.getDateTimeString(springfestivalinfo.GetFetchCountdown(), LocalString.Spring_Festival_Award_Wait)
                fields.UIButton_GetRewards.isEnabled = false
            end
        end    
    end
    
    fields.UILabel_GetRewards.text = stringbutton
    fields.UILabel_Hurt.text = stringlabel
end

local function RefreshBonus()
    ShowCurrentDailyBonus()
    ShowCurrentBonusState()
end

local function refresh()
    printyellow("[dlgspringfestivalgifts:refresh] refresh dlgspringfestivalgifts.")
    m_CurrentDailyBonus = springfestivalinfo.GetCurrentDailyBonus()

    RefreshBonus()
end

local function show()
    --printyellow("[dlgspringfestivalgifts:show] show dlgspringfestivalgifts.")
    fields.UITexture_Background:SetIconTexture(springfestivalinfo.GetBG()) --"ICON_FirstOfCharge_BG01")
    fields.UILabel_itemname.text = springfestivalinfo.GetDesc()
    fields.UILabel_title.text = springfestivalinfo.GetTitle()

    local loginday = springfestivalinfo.GetLoginDay()
    local currentdailybonusinfo = springfestivalinfo.GetCurrentDayBonusInfo()
    local stringday = loginday and loginday or 0
    local stringmultiple = 0
    local fontmultiple = 24
    if currentdailybonusinfo then
        stringmultiple = currentdailybonusinfo.showday
        fontmultiple = currentdailybonusinfo.parabig

        printyellow(string.format("[dlgspringfestivalgifts:show] stringmultiple=[%s], fontmultiple=[%s].", stringmultiple, fontmultiple))
        printyellow("[dlgspringfestivalgifts:show] currentdailybonusinfo:")
        printt(currentdailybonusinfo)
    end
    fields.UILabel_State.text = string.format(LocalString.Spring_Festival_Login_Day, stringday)
    fields.UILabel_GiftsState.text = stringmultiple
    fields.UILabel_GiftsState.fontSize = fontmultiple
end

local function destroy()
end

local function hide()
    reset()
end

local function update()
end

local function second_update()       
    ShowCurrentBonusState()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function OnUIButton_GetRewards()
    springfestivalmanager.send_CGetBonus()
end

local function OnAwardItemClicked(listitem)
    if listitem and listitem.Data then
        --printyellow(string.format("[dlgspringfestivalgifts:OnTurntableItemClicked] [%s] clicked!", listitem.gameObject.name))
        local params={item=listitem.Data, buttons={{display=false,text="",callFunc=nil}, {display=false,text="",callFunc=nil}}}
        ItemIntroduct.DisplayBriefItem(params) 
    end
end

local function OnUIButton_Close()
    UIManager.hidedialog("activity.springfestival.dlgspringfestivalgifts")
end

local function OnUIButton_Details()
    UIManager.show( "common.dlgdialogbox_complex", { 
                    type = Dlg_Complex_Type.UIGROUP_BILLIONOFWORDS,
                    callBackFunc = function(params,fields)
                        fields.UILabel_Title.text = LocalString.Spring_Festival_Detail_Title
                        fields.UILabel_Content_Single.text = springfestivalinfo.GetDetail()
                    end })
end

local function init(params)
    name, gameObject, fields = unpack(params)

    reset()

    --ui
    EventHelper.SetListClick(fields.UIList_Rewards, OnAwardItemClicked)
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_Details, OnUIButton_Details)
    EventHelper.SetClick(fields.UIButton_GetRewards, OnUIButton_GetRewards)
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
