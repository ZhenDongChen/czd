local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local DefineEnum = require("defineenum")
local uimanager = require("uimanager")
local citywarinfo 	  = require "ui.citywar.citywarinfo"
local citywarmanager 	  = require "ui.citywar.citywarmanager"
local membermgr = require("family.membermanager")
local PlayerRole=require("character.playerrole"):Instance()

--ui
local fields
local gameObject
local name
local OnAppointBtn = nil
local OnSendInfosBtn = nil

local m_Type
local m_MemberIDList
local m_bHasAdjustPopupList
local m_isCheckOperation = false

local function Clear()
end

local function ShowMembers()
    --printyellow("[tabrewarddistribution:ShowMembers] ShowMembers:")
    --printt(membermgr.Members())

    m_MemberIDList = keys(membermgr.Members())
    local wrapContent = fields.UIList_Member:GetComponent("UIWrapContentList")
    if not m_isCheckOperation then
        if wrapContent then
            wrapContent:SetDataCount(#m_MemberIDList)
            wrapContent:CenterOnIndex(0)
            wrapContent:Refresh()
        end       
    else
        m_isCheckOperation = false
    end 
end

local function show(params)
    --printyellow("[tabrewarddistribution:show] show tabrewarddistribution:")
    --printt(membermgr.Members())
    if params and params.giveBtn_callback and params.logBtn_callback then
        OnAppointBtn   = params.giveBtn_callback
        OnSendInfosBtn = params.logBtn_callback
    end
    if params then
        m_Type = params.type        
    end
    if membermgr.Members() then
        ShowMembers()
    else
        membermgr.GetReady(ShowMembers)
    end
end

local function hide()
    --printyellow("[tabrewarddistribution:hide] hide tabrewarddistribution.")
    if not m_isCheckOperation then
        membermgr.Release()
    end
    OnAppointBtn   = nil
    OnSendInfosBtn = nil
end

local function refresh(params)
    --printyellow("[tabrewarddistribution:refresh] refresh tabrewarddistribution.")

    m_MemberIDList = keys(membermgr.Members())
    utils.table_sort(m_MemberIDList, function(a,b)
        local membera = membermgr.Members()[a]
        local memberb = membermgr.Members()[b]
        local joba = membera.familyjob
        local jobb = memberb.familyjob
        if memberb.roleid == PlayerRole:GetId() then
            return false
        elseif membera.roleid == PlayerRole:GetId() then
            return true
        else
            if joba ~= 0 and jobb ~= 0 then
                if joba > jobb  then
                    return false
                end
            elseif joba == 0 and jobb ~= 0 then
                return false
             elseif joba ~= 0 and jobb == 0 then
                return true
            else
                if membera.pcontribution and memberb.pcontribution then
                    if membera.pcontribution ~= memberb.pcontribution then
                        return membera.pcontribution >= memberb.pcontribution
                    else
                        return membera.level >= memberb.level
                    end
                else
                    if membera.pcontribution then
                        return true
                    else
                        return false
                    end
                end
            end
        end
        return true
    end)
   
    local wrapContent = fields.UIList_Member.gameObject:GetComponent("UIWrapContentList")
    if wrapContent then
        wrapContent:RefreshWithOutSort()
    end   
end

local function destroy()
end

local function update()
end

local function uishowtype()
	return UIShowType.Refresh
end

local function OnUIButton_Close()
    --printyellow("[tabrewarddistribution:OnUIButton_Close] OnUIButton_Close")
    uimanager.hide("citywar.tabrewarddistribution")
end

local function OnUIButton_SendInfos()
    --printyellow("[tabrewarddistribution:OnUIButton_SendInfos] OnUIButton_SendInfos")
    --显示发奖日志界面
    if not OnSendInfosBtn then
        uimanager.show("citywar.tabworldterritoryrewarddistribution",{type = (m_Type or DefineEnum.RewardDistributionType.Territory)})
    else
        OnSendInfosBtn()
    end
end

local function OnUIList_MemberRefresh(item, index, realIndex)
    --printyellow("[tabrewarddistribution:OnUIList_MemberRefresh] OnUIList_MemberRefresh:")
        
    if not m_MemberIDList or realIndex > #m_MemberIDList then return end

    --info
    local roleid = m_MemberIDList[realIndex]
    local member = membermgr.Members()[roleid]
    if not member then return end
    item.Id = member.roleid
    item.Data = member
    --printt(member)

    --icon
    local texture = item.Controls["UITexture_Head"]
    texture:SetIconTexture(ConfigManager.GetHeadIcon(member.professiontype, member.gender))
    
    --me sprite
    item.Controls["UISprite_Me"].gameObject:SetActive(member.roleid == PlayerRole:GetId())

    --vip
    item.Controls["UISprite_VIP"].gameObject:SetActive(member.viplevel > 0)
    item.Controls["UILabel_VIP"].text = member.viplevel > 0 and member.viplevel or ""

    --lv
    item.Controls["UILabel_LV"].text = string.format("%d", member.level)

    --name
    item.Controls["UILabel_Name"].text = member.rolename

    --fight
    item.Controls["UILabel_Fight"].text = member.attackpower

    --job
    local labeljob = item.Controls["UILabel_Job"]
    labeljob.text = membermgr.JobId2Str(member.familyjob)

    --contribution
    item.Controls["UILabel_ContribToday"].text = member.dailybuild
    item.Controls["UILabel_ContribAll"].text = member.pcontribution

    --give
    EventHelper.SetClick(item.Controls["UIButton_Appoint"], function()
        if not OnAppointBtn then
            uimanager.show("citywar.dlgsendawards", {type = m_Type,roleId = member.roleid})
        else
            OnAppointBtn(member.roleid)
        end
    end)
end

local function init(params)
    name, gameObject, fields = unpack(params)
    --buttons
    EventHelper.SetClick(fields.UIButton_Close, OnUIButton_Close)
    EventHelper.SetClick(fields.UIButton_SendInfos, OnUIButton_SendInfos)

    --list
    local UIWrapContentList = fields.UIList_Member:GetComponent("UIWrapContentList")
    if UIWrapContentList then
        --printyellow("[tabrewarddistribution:init] set OnUIList_MemberRefresh!")
        EventHelper.SetWrapListRefresh(UIWrapContentList, OnUIList_MemberRefresh)
    else
        if Local.LogManager then
            print("[ERROR][tabrewarddistribution:init] UIWrapContentList nil!")
        end
    end
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
