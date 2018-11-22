local PlayerRole = require "character.playerrole"
local BagManager = require "character.bagmanager"
local UIManager = require("uimanager")
local StoryEctypeManager = require "ui.ectype.storyectype.storyectypemanager"
local EventHelper = UIEventListenerHelper
local ConfigManager = require "cfg.configmanager"
local network = require "network"
local EctypeDataManager = require "ui.ectype.storyectype.ectypedatamanager"
local VipChargeManager = require"ui.vipcharge.vipchargemanager"
local m_SectionData = {}


local function ShowResetTime1(dlgfields)  --提示重置页面
	dlgfields.UIGroup_Content_Three.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp.gameObject:SetActive(false)
	dlgfields.UIGroup_Compare.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp2.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(true)
	dlgfields.UILabel_Button_1.text = LocalString.Ectype_Reset
	dlgfields.UILabel_Title.text = LocalString.Ectype_ResetOpenTimes
	local money = EctypeDataManager.GetRequireYuanBaoReset(m_SectionData)
	dlgfields.UILabel_TitleIconName.gameObject:SetActive(false)
--	dlgfields.UITexture_TitleIconName:SetIconTexture("ICON_I_Exp_16")
	dlgfields.UILabel_ItemUse_Name.text = string.format(LocalString.Ectype_ResetTimeBuyYuanBao,money)
	local usedtime = EctypeDataManager.GetUsedResetTimes(m_SectionData)
	local maxtime  = EctypeDataManager.GetMaxResetTimes()
--	local dsc1 = "今日剩余重置次数".."[E9090D]("..(maxtime - usedtime).."/"..maxtime..")[-]"
	local dsc1 = string.format(LocalString.Ectype_TodayRestResetTime, maxtime - usedtime, maxtime)
	local dsc2
	if shouldHideVip() then dsc2 = "" else dsc2 =  LocalString.Ectype_UpgradeVipLevelToGetResetTime end

	dlgfields.UILabel_ItemUse_Describe.text = dsc1 .."\n".. dsc2
	EventHelper.SetClick(dlgfields.UIButton_1,function ()
		StoryEctypeManager.SendCResetStoryEctypeOpenCount(m_SectionData.id)

		UIManager.hide("common.dlgdialogbox_common")

	end)


end

local function ShowResetTime2(dlgfields) --重置次数用完，提示VIP升级
	dlgfields.UIGroup_Content_Three.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp.gameObject:SetActive(false)
	dlgfields.UIGroup_Compare.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp2.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Revive.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.Ectype_CurResetTimeUsedUp
	local str1
	if  shouldHideVip() then str1 = ""  dlgfields.UIButton_1.gameObject:SetActive(false) else str1 = string.format(LocalString.Ectype_UpgradeVIP_Tip, PlayerRole:Instance().m_VipLevel + 1, EctypeDataManager.GetMaxResetTimes() ) end
	dlgfields.UILabel_Content_Single1.text =LocalString.Ectype_UpgradeVIP .."\n".. str1
	dlgfields.UILabel_Button_1.text          = LocalString.ImmediateRecharge

	EventHelper.SetClick(dlgfields.UIButton_1,function ()
		UIManager.hide("common.dlgdialogbox_common")
	    if shouldHideVip()~=true then
		   VipChargeManager.ShowVipChargeDialog()
		end

	end)




end

local function ShowResetTime3(dlgfields) --重置次数用完并且满级（极端情况)
	dlgfields.UIGroup_Content_Three.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp.gameObject:SetActive(false)
	dlgfields.UIGroup_Compare.gameObject:SetActive(false)
	dlgfields.UIGroup_TextWarp2.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(true)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.TipText
	dlgfields.UILabel_Content_Single1.text = LocalString.Ectype_ResetOpenTimesUsedUp
	dlgfields.UILabel_Return.text          =  LocalString.CancelText
	dlgfields.UILabel_Sure.text            = LocalString.SureText
	EventHelper.SetClick(dlgfields.UIButton_Return,function ()
		UIManager.hide("common.dlgdialogbox_common")

	end)

	EventHelper.SetClick(dlgfields.UIButton_Sure,function ()
		UIManager.hide("common.dlgdialogbox_common")
	end)

end

local function ShowReminder(m_SectionDataIn)
	m_SectionData = m_SectionDataIn
	if EctypeDataManager.GetMaxResetTimes() ==  EctypeDataManager.GetUsedResetTimes(m_SectionData) and PlayerRole:Instance().m_VipLevel == EctypeDataManager.GetMaxVIPLevel()then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowResetTime3})

		return
	end

	if EctypeDataManager.GetMaxResetTimes() == 0 or EctypeDataManager.GetMaxResetTimes() ==  EctypeDataManager.GetUsedResetTimes(m_SectionData) then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowResetTime2})

		return
	end

	if EctypeDataManager.GetUsedResetTimes(m_SectionData) < EctypeDataManager.GetMaxResetTimes() then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowResetTime1})

		return
	end

end



local function ShowTiLi1(dlgfields)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(true)
	dlgfields.UILabel_Button_1.text = LocalString.Ectype_Purchase --"购买"
	dlgfields.UILabel_Title.text = LocalString.Ectype_PurchaseHuoLi --"购买活力"
	local money = EctypeDataManager.GetRequireYuanBaoTiLi(m_SectionData)

	dlgfields.UILabel_TitleIconName.gameObject:SetActive(false)
--	dlgfields.UITexture_TitleIconName:SetIconTexture("ICON_I_Symbol_40")
	dlgfields.UILabel_ItemUse_Name.text = string.format(LocalString.Ectype_CostYuanBaoToGetHuoLi,money,EctypeDataManager.GetTiLiRetrieve())--"花费"..money .."元宝购买"..EctypeDataManager.GetTiLiRetrieve().."活力"
	local usedtime = EctypeDataManager.GetUsedBuyTimes(m_SectionData)
	local maxtime  = EctypeDataManager.GetMaxBuyTimes()
	local dsc1 = string.format(LocalString.Ectype_TodayRestPurchaseTime,maxtime - usedtime,maxtime)--"今日剩余购买次数".."[E9090D]("..(maxtime - usedtime).."/"..maxtime..")[-]"
	local dsc2
	if shouldHideVip() then dsc2 = "" else dsc2 =  LocalString.Ectype_UpgradeVipLevelToGetPurchaseTime end
	dlgfields.UILabel_ItemUse_Describe.text = dsc1 .."\n".. dsc2
	EventHelper.SetClick(dlgfields.UIButton_1,function ()
		local msg = lx.gs.role.msg.CBuyTili()
		network.send(msg)
		UIManager.hide("common.dlgdialogbox_common")

	end)


end

local function ShowTiLi2(dlgfields)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(true)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.Ectype_CurResetTimeUsedUp --"当前次数用尽"
	local str1
	if shouldHideVip() then str1 = ""  dlgfields.UIButton_1.gameObject:SetActive(false) else str1 = LocalString.Ectype_UpgradeVIPTiLi_Tip end
	dlgfields.UILabel_Content_Single1.text =  LocalString.Ectype_UpgradeVIPTiLi .."\n" .. str1
	dlgfields.UILabel_Button_1.text          = LocalString.ImmediateRecharge

	EventHelper.SetClick(dlgfields.UIButton_1,function () --充值
	   UIManager.hide("common.dlgdialogbox_common")
	   if shouldHideVip()~=true then
			VipChargeManager.ShowVipChargeDialog()
       end
	end)
end

local function ShowTiLi3(dlgfields)
	dlgfields.UIGroup_Button_1.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_2.gameObject:SetActive(true)
	dlgfields.UIGroup_Resource.gameObject:SetActive(false)
	dlgfields.UIGroup_Reminder_Full.gameObject:SetActive(true)
	dlgfields.UIGroup_ItemUse.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single2.gameObject:SetActive(false)
	dlgfields.UILabel_Content_Single3.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text           = LocalString.PersonalBoss_AlertTitle --"提示"
	dlgfields.UILabel_Content_Single1.text = LocalString.Ectype_TodayPurchaseHuoLiTimeUsedup -- "您今日的购买活力次数已用尽"
	dlgfields.UILabel_Return.text          = LocalString.SureText --"确定"
	dlgfields.UILabel_Sure.text            = LocalString.CancelText --"取消"
	EventHelper.SetClick(dlgfields.UIButton_Return,function ()
		UIManager.hide("common.dlgdialogbox_common")

	end)

	EventHelper.SetClick(dlgfields.UIButton_Sure,function ()
		UIManager.hide("common.dlgdialogbox_common")
	end)
end

local function ShowReminderTiLi()

	if EctypeDataManager.GetMaxBuyTimes() ==  EctypeDataManager.GetUsedBuyTimes() and PlayerRole:Instance().m_VipLevel == EctypeDataManager.GetMaxVIPLevel()then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowTiLi3})

		return
	end

	if EctypeDataManager.GetMaxBuyTimes() == 0 or EctypeDataManager.GetMaxBuyTimes() ==  EctypeDataManager.GetUsedBuyTimes() then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowTiLi2})

		return
	end
	if EctypeDataManager.GetUsedBuyTimes() < EctypeDataManager.GetMaxBuyTimes() then
		UIManager.show("common.dlgdialogbox_common",{callBackFunc = ShowTiLi1})

		return
	end

end



local function onmsg_SResetDailyEctypeOpenCount(d)
		if UIManager.isshow("ectype.dlgstorydungeonsub") then
			UIManager.call("ectype.dlgstorydungeonsub","RefreshTimes",m_SectionData)
			UIManager.call("ectype.dlgstorydungeonsub","RefreshRightButton",m_SectionData)
		end
end

local function onmsg_SResetStoryEctypeOpenCount(d)
		if UIManager.isshow("ectype.dlgstorydungeonsub") then
			UIManager.call("ectype.dlgstorydungeonsub","RefreshTimes",m_SectionData)
			UIManager.call("ectype.dlgstorydungeonsub","RefreshRightButton",m_SectionData)
		end
end

local function init()

end

return {

	ShowReminderTiLi = ShowReminderTiLi,
	ShowReminder   = ShowReminder,
	init  = init,

}
