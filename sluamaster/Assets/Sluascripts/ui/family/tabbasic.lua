local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local network = require("network")
local uimanager = require("uimanager")
local familymgr = require("family.familymanager")
local player = require("character.playerrole"):Instance()
local itemmanager = require"item.itemmanager"
local bagmanager = require"character.bagmanager"

local fields

local function ShowPopup(title, content, maxlen, callback)
    -- printyellow(string.format("on showpopup, title=%s,content=%s,maxlen=%d", title, content, maxlen))
    uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(fields)
        fields.UIGroup_Button_Mid.gameObject:SetActive(false)
        fields.UIGroup_Button_Norm.gameObject:SetActive(true)
        fields.UIGroup_Resource.gameObject:SetActive(false)
        fields.UIGroup_Select.gameObject:SetActive(false)
        fields.UIGroup_Clan.gameObject:SetActive(false)
        fields.UIGroup_Rename.gameObject:SetActive(false)
        fields.UIGroup_Slider.gameObject:SetActive(false)
        fields.UIGroup_Delete.gameObject:SetActive(false)
        fields.UIInput_Input.gameObject:SetActive(false)
        fields.UIInput_Input_Large.gameObject:SetActive(true)

        EventHelper.SetClick(fields.UIButton_Left, function()
                                 if callback then
                                     callback(fields.UIInput_Input_Large.value)
                                 end
                                 uimanager.hide("common.dlgdialogbox_input")
        end)
        EventHelper.SetClick(fields.UIButton_Right, function()
                                 uimanager.hide("common.dlgdialogbox_input")
        end)
        EventHelper.SetClick(fields.UIButton_Close, function()
                                 uimanager.hide("common.dlgdialogbox_input")
        end)

        fields.UILabel_Title.text = title
        fields.UIInput_Input_Large.selectAllTextOnFocus = true
        fields.UIInput_Input_Large.characterLimit = maxlen
        fields.UIInput_Input_Large.value = content
        fields.UIInput_Input_Large.isSelected = true
        fields.UILabel_Input_Large.text = ""
        fields.UILabel_Button_Left.text = LocalString.Family.TagConfirm
        fields.UILabel_Button_Right.text = LocalString.Family.TagCancel
    end})
end

local function showtab(params)
    familymgr.GetReady(function()
        uimanager.show("family.tabbasic", params)
    end)
end

local function show()
    familymgr.CheckAllFamilyDlgHide()
    if familymgr.IsInStation() then
        fields.UILabel_Button_Station.text = LocalString.Family.Party.ButtonExist
    else
        fields.UILabel_Button_Station.text = LocalString.Family.Party.ButtonEnter
    end
end

local function OnChangeName(ofields)
  local familymgr = require("family.familymanager")
  ofields.UIGroup_Button_Mid.gameObject:SetActive(true)
  ofields.UIButton_Mid.gameObject:SetActive(false)
  ofields.UIGroup_Button_Norm.gameObject:SetActive(false)
  ofields.UIGroup_Resource.gameObject:SetActive(false)
  ofields.UIInput_Input.gameObject:SetActive(true)
  ofields.UIInput_Input_Large.gameObject:SetActive(false)
  ofields.UIGroup_Select.gameObject:SetActive(false)
  ofields.UIGroup_Clan.gameObject:SetActive(false)
  ofields.UIGroup_Rename.gameObject:SetActive(false)
  ofields.UIGroup_Slider.gameObject:SetActive(false)
  ofields.UIGroup_Delete.gameObject:SetActive(false)
  ofields.UIGroup_Describe.gameObject:SetActive(false)
  ofields.UIGroup_Button_Norm.gameObject:SetActive(true)
  ofields.UIButton_Close.gameObject:SetActive(true)

  ofields.UILabel_Input_Large.text = LocalString.Family.Create.HintInputFamilyName
  ofields.UILabel_Button_Left.text = LocalString.SureText
  ofields.UILabel_Button_Right.text = LocalString.CancelText
  ofields.UILabel_Input.text = LocalString.Family.ChangeNameContent
  ofields.UILabel_Title.text = LocalString.Family.ChangeNameTitle
  ofields.UILabel_Resource_Mid.text = familymgr.getCost()

--   local roleInfo = ConfigManager.getConfig("roleconfig")
--   local itemid = roleInfo.familyrenamecardid
--   local item = itemmanager.CreateItemBaseById(itemid)
--   local item_cnt = bagmanager.GetItemNumById(itemid)
--   local familyInfo = familymgr.Info()
--   local times = familyInfo.changenametimes
--   if times >= #roleInfo.familyrenamecost then
--     times = #roleInfo.familyrenamecost - 1
--   end
--   local changenamecost = roleInfo.familyrenamecost[times+1]
--   if item_cnt > 0 then
--       ofields.UISprite_Icon_Resource_Mid.spriteName = "ICON_I_Symbol_46_Little"
--       ofields.UILabel_Resource_Mid.text = LocalString.Family.ChangeNameCard
--   else
--       ofields.UISprite_Icon_Resource_Mid.spriteName = "ICON_I_Currency_02"
--       ofields.UILabel_Resource_Mid.text = changenamecost
--   end
  local utils = require"common.utils"
  EventHelper.SetClick(ofields.UIButton_Left,function()
      local currency = PlayerRole.Instance():GetCurrency(cfg.currency.CurrencyType.YuanBao)
      if currency >= familymgr.getCost() then
          local newname = ofields.UIInput_Input.value
          local bLegal,sInfo = utils.CheckName(newname)
          local num = string.len(newname)
          if bLegal then
              if string.find(newname,"%s") ~= nil or num == 0 then 
                uimanager.ShowSingleAlertDlg{content=LocalString.Family.ChangeNameError}
             else
                familymgr.RequestChangeFamilyName(newname)
                uimanager.hide"common.dlgdialogbox_input"
             end
          else
                 uimanager.ShowSingleAlertDlg{content=sInfo}
          end
    else
          uimanager.ShowSingleAlertDlg{content=string.format(LocalString.Family.ChangeNameAlert,familymgr.getCost())}
    end
  end)

    EventHelper.SetClick(ofields.UIButton_Right,function()
       uimanager.hide"common.dlgdialogbox_input"
  end)

  EventHelper.SetClick(ofields.UIButton_Close,function()
      uimanager.hide"common.dlgdialogbox_input"
  end)
end

-- local function hidetab()
-- end

local function hide()
end

local function destroy()
end

local function refresh(params)
    -- printyellow("on tabbasic refresh")
    local info = familymgr.Info()
    local rolemember = familymgr.RoleMember()
    -- printt(info)
    -- printt(rolemember)
    if not info or not rolemember then
        return
    end

    local leveldata = ConfigManager.getConfigData("familyinfo", info.flevel)
    local roledatajob = ConfigManager.getConfigData("familyjob", rolemember.familyjob)
    fields.UILabel_FamilyName.text      = info.familyname
    fields.UILabel_FamilyLevel.text     = info.flevel
    fields.UILabel_FamilyGold.text      = info.money
    fields.UILabel_Chief.text           = info.chiefname
    fields.UILabel_Size.text            = string.format("%d/%d", info.membernum, leveldata.memberamount)
    fields.UILabel_Contrib.text         = player:GetCurrency(cfg.currency.CurrencyType.BangGong)
    fields.UILabel_Build.text           = string.format("%d/%d", info.curlvlbuilddegree, leveldata.requirebuildrate)
    fields.UISlider_Build.value         = info.curlvlbuilddegree / leveldata.requirebuildrate
    fields.UILabel_Declaration.text     = info.declaration
    fields.UILabel_Announcement.text    = info.publicinfo
    fields.UIButton_Declaration.gameObject:SetActive(roledatajob and roledatajob.caneditdeclaration or false)
    fields.UIButton_Announcement.gameObject:SetActive(roledatajob and roledatajob.caneditannouncement or false)

    local praymgr = require("family.praymanager")
    fields.UISprite_WarningPray.gameObject:SetActive(praymgr.CanJinbiPray())
end

-- local function update()
-- end

local function init(params)
    name, gameObject, fields = unpack(params)

    EventHelper.SetClick(fields.UIButton_Declaration, function()
        ShowPopup(LocalString.Family.TitleEditDeclaration, familymgr.Info().declaration, cfg.family.FamilyInfo.DECLARATION_LENGTH, function(text)
            uimanager.showloading()
            text = string.gsub(text,"\n","")
            familymgr.UpdateDeclaration(text, function(declaration)
                fields.UILabel_Declaration.text = declaration
                uimanager.hideloading()
            end)
        end)
    end)
    EventHelper.SetClick(fields.UIButton_Announcement, function()
        ShowPopup(LocalString.Family.TitleEditPublicInfo, familymgr.Info().publicinfo, cfg.family.FamilyInfo.PUBLICINFO_LENGTH, function(text)
            uimanager.showloading()
            text = string.gsub(text,"\n","")
            familymgr.UpdatePublicinfo(text, function(publicinfo)
                fields.UILabel_Announcement.text = publicinfo
                uimanager.hideloading()
            end)
        end)
    end)
    EventHelper.SetClick(fields.UIButton_FamilyList, function()
        uimanager.showdialog("family.dlgfamily_apply")
    end)
    EventHelper.SetClick(fields.UIButton_Pray, function()
        uimanager.show("family.tabpray")
    end)
    EventHelper.SetClick(fields.UIButton_Station, function()
        if familymgr.IsInStation() then
            familymgr.CLeaveFamilyStation()
        else
            familymgr.CEnterFamilyStation(familymgr.EnterType.OnlyEnter)
        end
    end)
    EventHelper.SetClick(fields.UIButton_FamilyLog, function()
        familymgr.CGetFamilyLog()
    end)
    EventHelper.SetClick(fields.UIButton_DeclareWar, function()
        uimanager.showdialog("family.dlgfamily_apply",{mode="declare_war"})
    end)

    EventHelper.SetClick(fields.UIButton_Rename,function()
    --   uimanager.show("common.dlgdialogbox_input",{callBackFunc = OnChangeName})
         network.send(lx.gs.family.msg.CChangeFamilyNameNeedYuanbao()) --- 请求更换家族名
    end)
end

local function openChange(msg)
    uimanager.show("common.dlgdialogbox_input",{callBackFunc = OnChangeName})
end


local function uishowtype()
    return UIShowType.Refresh
end

return {
    showtab      = showtab,
    show         = show,
    hide         = hide,
    refresh      = refresh,
    destory      = destory,
    init         = init,
    openChange   = openChange,
    uishowtype   = uishowtype,
}
