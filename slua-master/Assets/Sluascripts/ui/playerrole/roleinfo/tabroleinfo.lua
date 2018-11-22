local unpack = unpack
local print = print
local string = string
local EventHelper = UIEventListenerHelper
local ConfigManager = require"cfg.configmanager"
local PlayerRoleManager = require "ui.playerrole.playerrolemanager"
local ColorUtil = require("common.colorutil")

local uimanager = require("uimanager")
local ItemManager = require"item.itemmanager"
local network = require"network"
local PlayerRole = require "character.playerrole"
local BagManager = require "character.bagmanager"

local gameObject
local name
local fields
local newName

local hasRandomName

local isLeftShow = false
local listenerIds

local function GetRenameCost(changenametimes)
	local roleconfig = ConfigManager.getConfig("roleconfig")

	local listcost = roleconfig.renamecost.amout

	if changenametimes >= #listcost then
		return listcost[#listcost]
	else
		return listcost[changenametimes + 1]
	end
end

local function FilterValidCharacter(s)
	if s == newName and hasRandomName then
		return true
	end

	local k = 1

	while k <= #s do

		local c = string.byte(s,k)


		if not c then break end
		if (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95 then 
		elseif c>=228 and c<=233 then 
				local c1 = string.byte(s,k + 1)
				local c2 = string.byte(s,k + 2)

				if c1 and c2 then
					local a1,a2,a3,a4 = 128,191,128,191
					if c == 228 then a1 = 184 end
					if c == 228 and c1 == 184 then a3 = 128 end
					if c == 233 then a2 = 190 end
					if c == 233 and c1 == 190 then a4 = 165 end

					if c1>=a1 and c1<=a2 and c2 >= a3 and c2 <= a4 then

						k = k + 2
					else

						return false
					end
				else

					return false
				end
		else

			return false
		end
		k = k + 1
	end

	return true
end

local function ShowRename(dlgfields)
--	printyellow("showname",newName)

	dlgfields.UIGroup_Button_Mid.gameObject:SetActive(false)
	dlgfields.UIGroup_Button_Norm.gameObject:SetActive(true)
	dlgfields.UIGroup_Resource.gameObject:SetActive(true)
	dlgfields.UIGroup_Select.gameObject:SetActive(false)
	dlgfields.UIGroup_Clan.gameObject:SetActive(false)
	--dlgfields.UIGroup_Rename.gameObject:SetActive(true)
	dlgfields.UIGroup_Slider.gameObject:SetActive(false)
	dlgfields.UIGroup_Delete.gameObject:SetActive(false)
	--dlgfields.UIInput_Input.gameObject:SetActive(true)
	dlgfields.UIInput_Input_Large.gameObject:SetActive(false)

	--dlgfields.UIGroup_Button_Mid.gameObject:SetActive(false)
	--dlgfields.UIWidget_Resource_2.gameObject:SetActive(false)
	dlgfields.UIGroup_Rename.gameObject:SetActive(true)
	dlgfields.UIInput_Input.gameObject:SetActive(true)
	--dlgfields.UIInput_Input_Large.gameObject:SetActive(false)
	dlgfields.UILabel_Title.text = LocalString.RoleInfo_Rename
	dlgfields.UILabel_Input.text = LocalString.RoleInfo_Typename
	dlgfields.UIInput_Input.value = newName or ""
    dlgfields.UILabel_Button_Right.text = LocalString.CancelText
	dlgfields.UILabel_Button_Left.text  = LocalString.SureText
	dlgfields.UIWidget_Resource_1.gameObject:SetActive(false)
	local roleconfig = ConfigManager.getConfig("roleconfig")
	local renamecardid = roleconfig.renamecardid
	--printyellow("xxxx")
	if renamecardid ~= nil and  BagManager.GetItemNumById(renamecardid) and BagManager.GetItemNumById(renamecardid) ~= 0 then
		local renamecarditem = ItemManager.CreateItemBaseById(renamecardid)
--	printyellow("renamecard icon = ",renamecarditem:GetIconName() )
		dlgfields.UISprite_Icon_Resource_Right.spriteName = renamecarditem:GetIconName() --"ICON_I_Symbol_46_Little"
		dlgfields.UILabel_Resource_Right.text = string.format(LocalString.RoleInfo_RenameCardNum,BagManager.GetItemNumById(renamecardid))
	else
		dlgfields.UISprite_Icon_Resource_Right.spriteName = "ICON_I_Currency_02"
		printyellow("PlayerRoleManager.GetChangeNameTimes() = ",PlayerRoleManager.GetChangeNameTimes())
		dlgfields.UILabel_Resource_Right.text = GetRenameCost(PlayerRoleManager.GetChangeNameTimes())
	end
	EventHelper.SetClick(dlgfields.UIButton_Right,function()
		newName = dlgfields.UIInput_Input.value
		uimanager.hide("common.dlgdialogbox_input")
	end)
	EventHelper.SetClick(dlgfields.UIButton_Left,function()
		local str1 = dlgfields.UIInput_Input.value
		local utils = require"common.utils"

		if (str1 == newName and hasRandomName) then

			network.send(lx.gs.role.msg.CChangeName{newname = str1})
		else

			local bLegal,sInfo = utils.CheckName(str1)
			if bLegal then
	
				network.send(lx.gs.role.msg.CChangeName{newname = sInfo})
			else

				uimanager.ShowSystemFlyText(sInfo)
			end
		end
--
-- 			str1 = string.gsub(str1,"%[%a%]","")
-- 			str1 = string.gsub(str1,"%[%a%a%]","")
-- 			str1 = string.gsub(str1,"%[%x%x%x%x%x%x%]","")
-- 			printyellow("str1 = ",str1)
--
-- 		if str1 then
-- 			if FilterValidCharacter(str1) then
-- 				local re = lx.gs.role.msg.CChangeName({newname = str1})
-- 				network.send(re)
-- --				uimanager.ShowSystemFlyText("absolutely right!!")
-- 			else
-- 				uimanager.ShowSystemFlyText(LocalString.RoleInfo_RenameInvalid)
-- 			end
-- 		end
	end)
	EventHelper.SetClick(dlgfields.UISprite_Random,function()
		local gender = PlayerRole:Instance().m_Gender
		local re = lx.gs.login.CRandomName({gender=gender})
		network.send(re)
	end)
end



local function GetCurrencyIconByType(Type)
	--[[local currencys = ConfigManager.getConfig("currency")
	for key ,currency in pairs (currencys)do
		if currency.type == Type then
			return currency.icon
		end
	end--]]
	return nil
end


local function 	RefreshName()
    fields.UILabel_Name.text = PlayerRole:Instance():GetName()
end


local function RefreshLeftPage(attr)
	local expandAttr = cfg.fight.AttrId
	local currencyType = cfg.currency.CurrencyType

	fields.UILabel_IDName.text = string.format(LocalString.RoleInfo_Id,PlayerRole:Instance().m_Id)

	local currency_xunibi = ItemManager.CreateItemBaseById(currencyType.XuNiBi)
	local currency_yuanbao = ItemManager.CreateItemBaseById(currencyType.YuanBao)
	local currency_bindYuanBao = ItemManager.CreateItemBaseById(currencyType.BindYuanBao)
	local currency_lingJing = ItemManager.CreateItemBaseById(currencyType.LingJing)


	fields.UISprite_Vcoin.gameObject:GetComponent(UISprite).spriteName = currency_xunibi:GetIconName()
	fields.UISprite_VcoinBind.gameObject:GetComponent(UISprite).spriteName = currency_yuanbao:GetIconName()
	fields.UISprite_Coin.gameObject:GetComponent(UISprite).spriteName = currency_bindYuanBao:GetIconName()
	fields.UISprite_Crystal.gameObject:GetComponent(UISprite).spriteName = currency_lingJing:GetIconName()

	local player = PlayerRole:Instance()
	fields.UILabel_Vcoin.text = player.m_Currencys[currencyType.XuNiBi] or 0

	fields.UILabel_VcoinBind.text = player.m_Currencys[currencyType.YuanBao] or 0

    fields.UILabel_VcoinBind.text = player.m_Currencys[currencyType.YuanBao] or 0

	fields.UILabel_Coin.text = player.m_Currencys[currencyType.BindYuanBao] or 0
	fields.UILabel_Crystal.text = player.m_Currencys[currencyType.LingJing] or 0


	fields.UIList_ExpandAttr:Clear()
	local i
	for i = 1, 13 do
		fields.UIList_ExpandAttr:AddListItem()
	end


	 fields.UIList_ExpandAttr:GetItemByIndex(0).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[1] ..":" ..string.format("%.1f",(attr[expandAttr.CRIT_RATE] )*100   		  ) .."%"
 	 fields.UIList_ExpandAttr:GetItemByIndex(1).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[2]..":" .. string.format("%.1f", (attr[expandAttr.CRIT_RESIST_RATE] )*100 	      )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(2).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[3]..":" .. string.format("%.1f",(attr[expandAttr.CRIT_VALUE] )*100 		      )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(3).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[4]..":" .. string.format("%.1f",(attr[expandAttr.CRIT_RESIST_VALUE] )*100       )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(4).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[5] ..":" ..string.format("%.1f",(attr[expandAttr.EXCELLENT_RATE] )*100 		  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(5).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[6] ..":" ..string.format("%.1f",(attr[expandAttr.EXCELLENT_VALUE] )*100 	  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(6).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[7] ..":" ..string.format("%.1f",(attr[expandAttr.EXCELLENT_RESIST_RATE] )*100   )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(7).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[8] ..":" ..string.format("%.1f",(attr[expandAttr.EXCELLENT_RESIST_VALUE] )*100  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(8).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[9]..":" .. string.format("%.1f",(attr[expandAttr.LUCKY_VALUE] )*100 		  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(9).Controls["UILabel_Properties"].text = LocalString.FightExpandProperty[10]..":" ..string.format("%.1f",(attr[expandAttr.ATTACK_MULTI_RATE] )*100 	  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(10).Controls["UILabel_Properties"].text =LocalString.FightExpandProperty[11]..":" ..string.format("%.1f",(attr[expandAttr.DEFENCE_MUTLI_RATE] )*100 	  )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(11).Controls["UILabel_Properties"].text =LocalString.FightExpandProperty[12]..":" ..string.format("%.1f",(attr[expandAttr.ABNORMAL_RESIST_RATE] )*100   )	.."%"
	 fields.UIList_ExpandAttr:GetItemByIndex(12).Controls["UILabel_Properties"].text =LocalString.FightExpandProperty[13]..":" ..string.format("%.1f",(attr[expandAttr.ABNORMAL_HIT_RATE] )*100      ) .."%"
    --fields.UIList_ExpandAttr:GetItemByIndex(13).Controls["UILabel_Properties"].text =LocalString.FightExpandProperty[14]..":" ..string.format("%d",(attr[expandAttr.DEFENCE2]))
    --fields.UIList_ExpandAttr:GetItemByIndex(14).Controls["UILabel_Properties"].text =LocalString.FightExpandProperty[15]..":" ..string.format("%d",(attr[expandAttr.ATTACK2]))


end

local function RefreshRightPage(attr,offsetattr)
    local attrMap = cfg.fight.AttrId

	local expTable = ConfigManager.getConfig("exptable")
	if fields.UIButton_Up.gameObject.activeSelf then
		fields.UIButton_Up.gameObject:SetActive(false)
	end
    fields.UILabel_Power.text = PlayerRole:Instance().m_Power
	if shouldHideVip() then fields.UISprite_VIP.gameObject:SetActive(false) end
    fields.UISprite_VIP.transform:Find("UILabel_VIP").gameObject:GetComponent(UILabel).text = PlayerRole:Instance():GetVipLevel()

  --称号
    fields.UILabel_Title.text = (((PlayerRole:Instance().m_Title == nil) and "") or PlayerRole:Instance().m_Title:GetName())
	
	--TODO判断当前是否有浮动的属性
	if offsetattr ~= nil and #offsetattr >0 then 
		
		--攻击力
		fields.UILabel_Fight.text = math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) .. "-" .. math.floor(attr[attrMap.ATTACK_VALUE_MAX])
		
		if math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) <  math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN]) then
				fields.UILabel_Fight.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen, tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN])).."-"..tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MAX])))
			else if math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) >  math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN])  then
				fields.UILabel_Fight.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed, tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN])).."-"..tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MAX])))
			end
			if math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) ==  math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN])  then
				fields.UILabel_Fight.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MIN])).."-"..tostring( math.floor(offsetattr[attrMap.ATTACK_VALUE_MAX])))
			end
		end
		
		
		--防御值
		if math.floor(attr[attrMap.DEFENCE] ) <  math.floor(offsetattr[attrMap.DEFENCE]) then
				fields.UILabel_Defence.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen, tostring( math.floor(offsetattr[attrMap.DEFENCE])))
			else if math.floor(attr[attrMap.DEFENCE] ) >  math.floor(offsetattr[attrMap.DEFENCE])  then
				fields.UILabel_Defence.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed, tostring( math.floor(offsetattr[attrMap.DEFENCE])))
			end
			if math.floor(attr[attrMap.DEFENCE] ) ==  math.floor(offsetattr[attrMap.DEFENCE])  then
				fields.UILabel_Defence.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, tostring( math.floor(offsetattr[attrMap.DEFENCE])))
			end
		end
		
		--命中值
		if math.floor(attr[attrMap.HIT_RATE] ) <  math.floor(offsetattr[attrMap.HIT_RATE]) then
				--fields.UILabel_Hit.text  = math.floor(attr[attrMap.HIT_RATE] )
				fields.UILabel_Hit.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen, tostring( math.floor(offsetattr[attrMap.HIT_RATE])))
			else if math.floor(attr[attrMap.HIT_RATE] ) >  math.floor(offsetattr[attrMap.HIT_RATE])  then
				fields.UILabel_Hit.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed, tostring( math.floor(offsetattr[attrMap.HIT_RATE])))
			end
			if math.floor(attr[attrMap.HIT_RATE] ) ==  math.floor(offsetattr[attrMap.HIT_RATE])  then
				fields.UILabel_Hit.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, tostring( math.floor(offsetattr[attrMap.HIT_RATE])))
			end
		end
		
		--闪躲值
		if math.floor(attr[attrMap.HIT_RESIST_RATE] ) <  math.floor(offsetattr[attrMap.HIT_RESIST_RATE]) then
				fields.UILabel_Hide.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen, tostring( math.floor(offsetattr[attrMap.HIT_RESIST_RATE])))
			else if math.floor(attr[attrMap.HIT_RESIST_RATE] ) >  math.floor(offsetattr[attrMap.HIT_RESIST_RATE])  then
				fields.UILabel_Hide.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed, tostring( math.floor(offsetattr[attrMap.HIT_RESIST_RATE])))
			end
			if math.floor(attr[attrMap.HIT_RESIST_RATE] ) ==  math.floor(offsetattr[attrMap.HIT_RESIST_RATE])  then
				fields.UILabel_Hide.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, tostring( math.floor(offsetattr[attrMap.HIT_RESIST_RATE])))
			end
		end
		
		--暴击值
		if math.floor(attr[attrMap.CRIT_RATE] ) <  math.floor(offsetattr[attrMap.CRIT_RATE]) then
				fields.UILabel_Crit.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen,string.format("%.1f",(offsetattr[attrMap.CRIT_RATE] )*100 ) .."%")
			else if math.floor(attr[attrMap.CRIT_RATE] ) >  math.floor(offsetattr[attrMap.CRIT_RATE])  then
				fields.UILabel_Crit.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed, string.format("%.1f",(offsetattr[attrMap.CRIT_RATE] )*100 ) .."%")
			end
			if math.floor(attr[attrMap.CRIT_RATE] ) ==  math.floor(offsetattr[attrMap.CRIT_RATE])  then
				fields.UILabel_Crit.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, string.format("%.1f",(offsetattr[attrMap.CRIT_RATE] )*100 ) .."%")
			end
		end
		
		--爆伤值
		if math.floor(attr[attrMap.CRIT_VALUE] ) <  math.floor(offsetattr[attrMap.CRIT_VALUE]) then
				fields.UILabel_Hurt.text = ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoGreen, string.format("%.1f",(offsetattr[attrMap.CRIT_VALUE] )*100 ).."%")
			else if math.floor(attr[attrMap.CRIT_VALUE] ) >  math.floor(offsetattr[attrMap.CRIT_VALUE])  then
				fields.UILabel_Hurt.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoRed,  string.format("%.1f",(offsetattr[attrMap.CRIT_VALUE] )*100 ).."%")
			end
			if math.floor(attr[attrMap.CRIT_VALUE] ) ==  math.floor(offsetattr[attrMap.CRIT_VALUE])  then
				fields.UILabel_Hurt.text =  ColorUtil.GetColorStr(ColorUtil.ColorType.RoleinfoOrange, string.format("%.1f",(offsetattr[attrMap.CRIT_VALUE] )*100 ).."%")
			end
		end
		
		
	else
		fields.UILabel_Fight.text = math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) .. "-" .. math.floor(attr[attrMap.ATTACK_VALUE_MAX])
		fields.UILabel_Defence.text = math.floor(attr[attrMap.DEFENCE] )
		fields.UILabel_Hit.text  = math.floor(attr[attrMap.HIT_RATE] )
		fields.UILabel_Hide.text = math.floor(attr[attrMap.HIT_RESIST_RATE] )
		fields.UILabel_Crit.text = string.format("%.1f",(attr[attrMap.CRIT_RATE] )*100 ) .."%"
		fields.UILabel_Hurt.text = string.format("%.1f",(attr[attrMap.CRIT_VALUE] )*100 ).."%"
	end
--[[    fields.UILabel_Fight.text = math.floor(attr[attrMap.ATTACK_VALUE_MIN] ) .. "-" .. math.floor(attr[attrMap.ATTACK_VALUE_MAX])
    fields.UILabel_Defence.text = math.floor(attr[attrMap.DEFENCE] )
    fields.UILabel_Hit.text  = math.floor(attr[attrMap.HIT_RATE] )
    fields.UILabel_Hide.text = math.floor(attr[attrMap.HIT_RESIST_RATE] )
    fields.UILabel_Crit.text = string.format("%.1f",(attr[attrMap.CRIT_RATE] )*100 ) .."%"
    fields.UILabel_Hurt.text = string.format("%.1f",(attr[attrMap.CRIT_VALUE] )*100 ).."%"--]]

    fields.UISlider_HP.value = PlayerRole:Instance().m_Attributes[attrMap.HP_VALUE]/attr[attrMap.HP_FULL_VALUE]
    fields.UISlider_MP.value = PlayerRole:Instance().m_Attributes[attrMap.MP_VALUE] / attr[attrMap.MP_FULL_VALUE]
    fields.UISlider_EXP.value = PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.JingYan) / expTable[PlayerRole:Instance().m_Level].exp --?????

    fields.UILabel_ValueHP.text = math.floor(PlayerRole:Instance().m_Attributes[attrMap.HP_VALUE]) .. "/" .. math.floor(attr[attrMap.HP_FULL_VALUE])
    fields.UILabel_ValueMP.text = math.floor(PlayerRole:Instance().m_Attributes[attrMap.MP_VALUE]) .. "/" .. math.floor(attr[attrMap.MP_FULL_VALUE])
    fields.UILabel_ValueEXP.text = math.floor(PlayerRole:Instance():GetCurrency(cfg.currency.CurrencyType.JingYan)) ..
										"/" .. math.floor(expTable[PlayerRole:Instance().m_Level].exp)

    if isLeftShow == false then
        EventHelper.SetClick(fields.UIButton_Information, function()
            isLeftShow = true
            fields.UILabel_Information.text = LocalString.RoleInfo.HideDetail
            uimanager.refresh("playerrole.roleinfo.tabroleinfo")
        end)
    else
        EventHelper.SetClick(fields.UIButton_Information, function()
            isLeftShow = false
            fields.UILabel_Information.text = LocalString.RoleInfo.DetailInfo
            uimanager.refresh("playerrole.roleinfo.tabroleinfo")
        end)
    end

	EventHelper.SetClick(fields.UIButton_Copy,function()

--		local te = UnityEngine.TextEditor()
--		te.text = fields.UILabel_IDName.text
--		te:SelectAll()
--		te:Copy()
--		uimanager.ShowSystemFlyText(LocalString.RoleInfo_copyidsuccessed)

	end)

	EventHelper.SetClick(fields.UIButton_ChangeName,function()
		uimanager.show("common.dlgdialogbox_input",{callBackFunc = ShowRename})
	end)
	if shouldHideVip() then fields.UIButton_VIP.gameObject:SetActive(false) end
	EventHelper.SetClick(fields.UIButton_VIP,function()
		uimanager.showdialog("vipcharge.dlgprivilege_vip")
	end)

	EventHelper.SetClick(fields.UIButton_ChangeTitle,function()

		uimanager.showdialog("title.dlgtitle")
	end)

--	EventHelper.SetClick(fields.UIButton_Up,function()
--		uimanager.showdialog("welfare.dlgwelfaremain",nil,2)
--	end)

end

local function refresh(params)
	RefreshName()
	local UpdateAttrManager = require("ui.updateattr.updateattrmanager") --????????????????
    if isLeftShow == false then
        fields.UIGroup_Details.gameObject:SetActive(false)
        RefreshRightPage(UpdateAttrManager.GetFightAttributes(),UpdateAttrManager.GetOffsetAttributes()) --????????????
    else
        fields.UIGroup_Details.gameObject:SetActive(true)
        RefreshLeftPage(UpdateAttrManager.GetFightAttributes())
        RefreshRightPage(UpdateAttrManager.GetFightAttributes(),UpdateAttrManager.GetOffsetAttributes())
    end

end
local function update()
  --print(name, "update")
end
local function destroy()
  --print(name, "destroy")
	network.remove_listeners(listenerIds)
end
local function show(params)
    fields.UIGroup_RoleInfo.gameObject:SetActive(true)
end
local function hide()
--	newName = dlgfields.UIInput_Input.value
end
local function hidetab()
    uimanager.hide("playerrole.roleinfo.tabroleinfo")
end
local function showtab(params)
    uimanager.show("playerrole.roleinfo.tabroleinfo",params)
end

local function onmsg_RandomName(msg)
	printyellow("onmsg_RandomName",msg.name)
	hasRandomName = true
	newName = msg.name
    uimanager.refresh("common.dlgdialogbox_input",{callBackFunc = ShowRename})
end

--local function onmsg_SRoleLogin(msg)
--	changenametimes = msg.roledetail.changetimes or 0
--end

local function onmsg_SChangeName(msg)
--	changenametimes = msg.changetimes
--	printyellow("onmsg_Schangename time ",msg.changetimes)
	PlayerRoleManager.SetChangeNameTimes(msg.changetimes)
	PlayerRole:Instance().m_Name = msg.newname
	newName = msg.newname
	hasRandomName = false
	uimanager.hide("common.dlgdialogbox_input")
	uimanager.refresh("playerrole.equip.tabequip")
	uimanager.refresh("playerrole.roleinfo.tabroleinfo")
end

local function init(params)
    name, gameObject, fields    = unpack(params)
	printyellow("init lx.gs.login.SRandomName")
--	changenametimes = PlayerRoleManager.GetChangeNameTimes()
	listenerIds = network.add_listeners({
		{"lx.gs.login.SRandomName",onmsg_RandomName},
		{"lx.gs.role.msg.SChangeName",onmsg_SChangeName},
	})
end

local function uishowtype()
    return UIShowType.Refresh
end

return {
  uishowtype = uishowtype,
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  showtab = showtab,
  hidetab = hidetab,
RefreshLeftPage = RefreshLeftPage,
RefreshRightPage = RefreshRightPage,
}
