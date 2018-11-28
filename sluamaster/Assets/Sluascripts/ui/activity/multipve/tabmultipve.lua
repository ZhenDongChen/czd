local Unpack = unpack
local EventHelper = UIEventListenerHelper
local Define=require("define")
local uimanager = require("uimanager")
local ConfigManager= require("cfg.configmanager")
local ItemManager = require("item.itemmanager")
local ItemIntroduct  = require("item.itemintroduction")
local LimitManager  = require("limittimemanager")
local Monster=require("character.monster")
local TimeUtils=require("common.timeutils")
local BonusManager=require("item.bonusmanager")
local PlayerRole=require("character.playerrole"):Instance()
local guardtowermanager = require "ui.ectype.guardtower.guardtowermanager"
local TeamManager = require "ui.team.teammanager"

local gameObject
local name
local fields

local function destroy()
end

local function show(params)
    fields.UIList_Hard:SetSelectedIndex(guardtowermanager.GetHardState())
end

local function hide()
end

local function refresh()
    fields.UIGroup_Lock.gameObject:SetActive(not guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()))
    viewutil.SetTextureGray(fields.UITexture_Pvp,not guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()))

    if not guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()) then 
        fields.UILabel_UnLockLevel.text = string.format(LocalString.GuardTower.UnLockLevel,guardtowermanager.GetLimitLevel(guardtowermanager.GetHardState()))
    end 
    
    fields.UILabel_OpenTime.text = guardtowermanager.GetOpenTimeInfo()


    fields.UILabel_LastTime.text = guardtowermanager.GetLastTimes(guardtowermanager.GetHardState())
    fields.UILabel_Level.gameObject:SetActive(guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()))
    fields.UILabel_Levels.text = guardtowermanager.GetLevelInfo() 
    fields.UILabel_mode.text = string.format(LocalString.GuardTower.HardInfo,guardtowermanager.GetHardInfo())
    fields.UITexture_Pvp:SetIconTexture(guardtowermanager.GetHardTexture())

    fields.UIList_Icon:Clear()
    for _,itemid in  pairs(guardtowermanager.GetShowBonusId()) do 
        local item = fields.UIList_Icon:AddListItem()
        item.Id = itemid 
        item.Data = ItemManager.CreateItemBaseById(itemid,{},1)
        item:SetIconTexture( item.Data:GetTextureName()) 
        if item.Data:GetQuality() then
            item.Controls["UISprite_Quality"].spriteName = colorutil.GetQualitySprite(item.Data:GetQuality())
        end
    end    

    for i=0,fields.UIList_Hard.Count-1 do 
        local item = fields.UIList_Hard:GetItemByIndex(i)
        item.Controls["UISprite_Warning"].gameObject:SetActive(guardtowermanager.UnRead_HardState(i))
    end 
    if not guardtowermanager.IsMatching() then 
        fields.UILabel_Matching.text = LocalString.GuardTower.MatchStart
    else 
        fields.UILabel_Matching.text = LocalString.GuardTower.MatchEnd
    end 
    UITools.SetButtonEnabled(fields.UIButton_Matching,guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()) and (guardtowermanager.IsReady() or guardtowermanager.IsMatching()))
    UITools.SetButtonEnabled(fields.UIButton_Setting,guardtowermanager.RoleLevelAchieve(guardtowermanager.GetHardState()))
    fields.UILabel_Countdown.gameObject:SetActive(false)
end

local function second_update(now)
    fields.UILabel_Countdown.gameObject:SetActive(not guardtowermanager.IsReady())
    if guardtowermanager.IsReady() then

    elseif guardtowermanager.IsUnReady() then
        fields.UILabel_Countdown.text = timeutils.getDateTimeString(guardtowermanager.GetLastMatchTime(),LocalString.GuardTower.UILabel_LastTime3)

    elseif guardtowermanager.IsMatching() then
        fields.UILabel_Countdown.text = string.format(LocalString.GuardTower.UILabel_LastTime,guardtowermanager.GetLastTime())

    elseif guardtowermanager.IsMatched() then
        fields.UILabel_Countdown.text = string.format(LocalString.GuardTower.UILabel_LastTime2,guardtowermanager.GetLastTime())
    end 
end

local function update()

end

local function init(params)
    
    name, gameObject, fields = Unpack(params)
    fields.UISprite_Add.gameObject:SetActive(false)
    EventHelper.SetClick(fields.UIButton_Matching, function()

        if TeamManager.IsInTeam() and not TeamManager.IsLeader(PlayerRole:Instance().m_Id) then 
            uimanager.show("dlgalert_reminder_singlebutton",{content = LocalString.GuardTower.NotLeader})
        else 
            if not guardtowermanager.IsMatching() then
                guardtowermanager.MatchStart(guardtowermanager.GetHardState())
            else 
                guardtowermanager.MatchCancel()
            end
        end
    end )

    EventHelper.SetListSelect(fields.UIList_Hard, function(selecteditem)
        --printyellow("fields.UIList_TitleSelect selected : index:",selecteditem.Index)
        guardtowermanager.SetHardState(selecteditem.Index)
    end )

    
    -- ��ʾ�����������ĵ�����Ʒ
	EventHelper.SetListClick(fields.UIList_Icon, function(listItem)
		ItemIntroduct.DisplayBriefItem( {
			item = listItem.Data ,
			variableNum = false,
			-- bInCenter = true,
			buttons =
			{
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil },
				{ display = false, text = "", callFunc = nil }
			}
		} )
	end )

    EventHelper.SetClick(fields.UIButton_Setting, function()
        uimanager.show("common.dlgdialogbox_input", {callBackFunc=function(popupfields)
            popupfields.UIGroup_Button_Mid.gameObject:SetActive(false)
            popupfields.UIGroup_Button_Norm.gameObject:SetActive(true)
            popupfields.UIGroup_Resource.gameObject:SetActive(false)
            popupfields.UIGroup_Select.gameObject:SetActive(false)
            popupfields.UIGroup_Describe.gameObject:SetActive(true)
            popupfields.UIGroup_Clan.gameObject:SetActive(false)
            popupfields.UIGroup_Rename.gameObject:SetActive(false)
            popupfields.UIGroup_Slider.gameObject:SetActive(false)
            popupfields.UIGroup_Delete.gameObject:SetActive(false)
            popupfields.UIInput_Input.gameObject:SetActive(true)
            popupfields.UIInput_Input_Large.gameObject:SetActive(false)
            

            popupfields.UILabel_Input.text = LocalString.GuardTower.SettingInputDefault
            popupfields.UILabel_Title.text = LocalString.GuardTower.Setting
            popupfields.UIInput_Input.value = guardtowermanager.GetMinPower()
            popupfields.UILabel_Button_Left.text = LocalString.GuardTower.Confirm
            popupfields.UILabel_Button_Right.text = LocalString.GuardTower.Cancle
            popupfields.UILabel_Describe.text = LocalString.GuardTower.SettingInfo

            EventHelper.SetClick(popupfields.UIButton_Right, function()
                    uimanager.hide("common.dlgdialogbox_input")
            end)
            EventHelper.SetClick(popupfields.UIButton_Left, function()
                    guardtowermanager.SetMinPower(popupfields.UIInput_Input.value, function()
                            uimanager.hide("common.dlgdialogbox_input")
                    end)
            end)
        end})
    end)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  second_update = second_update,
  destroy = destroy,
  refresh = refresh,
}