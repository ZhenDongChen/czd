local unpack = unpack
local print = print
local EventHelper = UIEventListenerHelper
local NetWork = require("network")
local UIManager=require("uimanager")
local TeamManager=require("ui.team.teammanager")
local ConfigManager=require("cfg.configmanager")
local PlayerRole=require("character.playerrole")
local playerRole=PlayerRole:Instance()
local gameObject
local name
local fields

local function destroy()
end

local function show(params)
end

local function hide()
end

local function SetHeadInfo(UIListItem_Team,isCaptain,baseInfo)
    local UILabel_Name=UIListItem_Team.Controls["UILabel_Name"]
    if UILabel_Name then
        UILabel_Name.text=baseInfo.name
    end
    local UILabel_CombatPower=UIListItem_Team.Controls["UILabel_CombatPower"]
    if UILabel_CombatPower then
        UILabel_CombatPower.text=baseInfo.power
    end
    local UILabel_VIPLevel=UIListItem_Team.Controls["UILabel_VIP"]
    if UILabel_VIPLevel then
        UILabel_VIPLevel.text=baseInfo.vipLevel
    end
    local UILabel_LV=UIListItem_Team.Controls["UILabel_LV"]
    if UILabel_LV then
        UILabel_LV.text=baseInfo.level
    end
    local UISprite_Captain=UIListItem_Team.Controls["UISprite_Captain"]
    if UISprite_Captain then
        UISprite_Captain.gameObject:SetActive(isCaptain)
    end
    local UITexture_Head=UIListItem_Team.Controls["UITexture_Head"]
    if UITexture_Head then
        UITexture_Head:SetIconTexture(baseInfo.icon)
    end
end

local function OnMsg_LoadTeamInfo()
    local UIToggle_Checkbox01=fields.UIButton_Checkbox01.transform:GetComponent("UIToggle")
    local UIToggle_Checkbox02=fields.UIButton_Checkbox02.transform:GetComponent("UIToggle")
	
	UIToggle_Checkbox01:Set(gTeamManagerListState.autoAcceptInvite ~= 0)
    UIToggle_Checkbox02:Set(gTeamManagerListState.autoAcceptRequest ~= 0)
   -- UIToggle_Checkbox01:Set(TeamManager.ListState.autoAcceptInvite ~= 0)
   -- UIToggle_Checkbox02:Set(TeamManager.ListState.autoAcceptRequest ~= 0)
    EventHelper.SetClick(fields.UIButton_Checkbox01,function()
        local value=0
        if UIToggle_Checkbox01.value then
            value=1
        else
            value=0
        end
		--printyellow("TeamManager.ListState.AUTO_ACCEPT_INVITE"..tostring(value) )
        TeamManager.SendAutoSetting(lx.gs.team.msg.CSetAutoSetting.AUTO_ACCEPT_INVITE,value)
    end)
    EventHelper.SetClick(fields.UIButton_Checkbox02,function()
        local value=0
        if UIToggle_Checkbox02.value then
            value=1
        else
            value=0
        end
		printyellow("TeamManager.ListState.AUTO_ACCEPT_REQUEST"..tostring(value) )
        TeamManager.SendAutoSetting(lx.gs.team.msg.CSetAutoSetting.AUTO_ACCEPT_REQUEST,value)
    end)
    local UIGroup_List=fields.UIGroup_List
    UIGroup_List.gameObject:SetActive(true)
    fields.UIList_Friend:Clear()
    local teamInfo=TeamManager.GetTeamInfo()
    if teamInfo then
        local members=teamInfo.members
        local ownInfo=members[playerRole.m_Id]
        local UIListItem_Team=fields.UIList_Friend:AddListItem()
        local UIGroup_ItemCreate=UIListItem_Team.Controls["UIGroup_ItemCreate"]
        local UIGroup_Head=UIListItem_Team.Controls["UIGroup_Head"]
        UIGroup_Head.gameObject:SetActive(true)
        UIGroup_ItemCreate.gameObject:SetActive(true)
        local UIButton_Create=UIListItem_Team.Controls["UIButton_Create"]
        local UIButton_PrivateChat=UIListItem_Team.Controls["UIButton_PrivateChat"]
        local UIButton_PromotedCaptain=UIListItem_Team.Controls["UIButton_PromotedCaptain"]
        local UIButton_KickOut=UIListItem_Team.Controls["UIButton_KickOut"]
        UIButton_Create.gameObject:SetActive(true)
        UIButton_KickOut.gameObject:SetActive(false)
        UIButton_PromotedCaptain.gameObject:SetActive(false)
        UIButton_PrivateChat.gameObject:SetActive(false)
        local UILabel_Create=UIListItem_Team.Controls["UILabel_Create"]
        local UILabel_Leave= UIListItem_Team.Controls["UILabel_Leave"]
        local UILabel_MakeFriend=UIListItem_Team.Controls["UILabel_MakeFriend"]
        UILabel_Create.gameObject:SetActive(false)
        UILabel_Leave.gameObject:SetActive(true)
        UILabel_MakeFriend.gameObject:SetActive(false)
        SetHeadInfo(UIListItem_Team,(teamInfo.leaderid==playerRole.m_Id),{name=playerRole.m_Name,level=playerRole.m_Level,vipLevel=playerRole.m_VipLevel,icon=TeamManager.GetHeadIcon(playerRole.m_Profession,playerRole.m_Gender),power=playerRole.m_Power})
        EventHelper.SetClick(UIButton_Create,function()
            TeamManager.SendQuitTeam()
        end)
        for _, memberInfo in pairs(teamInfo.members) do
            if playerRole.m_Id~=memberInfo.roleid then
                local UIListItem_Team=fields.UIList_Friend:AddListItem()
                local UIGroup_ItemCreate=UIListItem_Team.Controls["UIGroup_ItemCreate"]

                local UIGroup_Head=UIListItem_Team.Controls["UIGroup_Head"]
                UIGroup_Head.gameObject:SetActive(true)
                UIGroup_ItemCreate.gameObject:SetActive(true)

                local UIButton_Create=UIListItem_Team.Controls["UIButton_Create"]
                local UIButton_PrivateChat=UIListItem_Team.Controls["UIButton_PrivateChat"]
                local UIButton_PromotedCaptain=UIListItem_Team.Controls["UIButton_PromotedCaptain"]
                local UIButton_KickOut=UIListItem_Team.Controls["UIButton_KickOut"]
                UIButton_PrivateChat.gameObject:SetActive(true)
                EventHelper.SetClick(UIButton_PrivateChat,function()
                    --私聊
                    UIManager.showdialog("chat.dlgchat01",{id = memberInfo.roleid, name = memberInfo.roleinfo.name, index = 2})                  
                end)
                UIButton_Create.gameObject:SetActive(true)
                local UILabel_Create=UIListItem_Team.Controls["UILabel_Create"]
                local UILabel_Leave= UIListItem_Team.Controls["UILabel_Leave"]
                local UILabel_MakeFriend=UIListItem_Team.Controls["UILabel_MakeFriend"]
                UILabel_Create.gameObject:SetActive(false)
                UILabel_Leave.gameObject:SetActive(false)
                UILabel_MakeFriend.gameObject:SetActive(true)
                local friendMgr=require"ui.friend.friendmanager"
                if friendMgr.IsFriend(memberInfo.roleid) then
                    UIButton_Create.isEnabled=false
                else
                    EventHelper.SetClick(UIButton_Create,function()
                        friendMgr.RequestFriendById(memberInfo.roleid)
                    end)
                end
                local isCaptain=false
                if teamInfo.leaderid== memberInfo.roleid then
                    UIButton_KickOut.isEnabled=false
                    UIButton_PromotedCaptain.isEnabled=false
                    isCaptain=true
                else
                    --闁告帇鍊栭弻鍥亹閹惧啿顤呴柣婧炬櫅椤斿秹寮伴姘剨闂傚啰鍠栭弳锟�
                    local PlayerRole=require "character.playerrole"
                    if PlayerRole:Instance().m_Id==teamInfo.leaderid then
                        UIButton_KickOut.isEnabled=true
                        UIButton_PromotedCaptain.isEnabled=true
                        EventHelper.SetClick(UIButton_KickOut,function()
                            TeamManager.SendKickOut(memberInfo.roleid)
                        end)
                        EventHelper.SetClick(UIButton_PromotedCaptain,function()
                            TeamManager.SendTransferLeader(memberInfo.roleid)
                        end)
                    else
                        UIButton_KickOut.isEnabled=false
                        UIButton_PromotedCaptain.isEnabled=false
                    end
                    isCaptain=false
                end
                local roleInfo=memberInfo.roleinfo
                SetHeadInfo(UIListItem_Team,isCaptain,{name=roleInfo.name,level=roleInfo.level,vipLevel=roleInfo.viplevel,icon=TeamManager.GetHeadIcon(roleInfo.profession,roleInfo.gender),power=roleInfo.combatpower})
            end
        end
    else
        local UIListItem_Team=fields.UIList_Friend:AddListItem()
        local UIGroup_ItemCreate=UIListItem_Team.Controls["UIGroup_ItemCreate"]
--        local UIGroup_ItemFriend=UIListItem_Team.Controls["UIGroup_ItemFriend"]
--        local UIGroup_ItemFindPeople=UIListItem_Team.Controls["UIGroup_ItemFindPeople"]
--        local UIGroup_ItemFindTeam=UIListItem_Team.Controls["UIGroup_ItemFindTeam"]
        local UIGroup_Head=UIListItem_Team.Controls["UIGroup_Head"]
        UIGroup_Head.gameObject:SetActive(true)
        SetHeadInfo(UIListItem_Team,false,{name=playerRole:GetName(),level=playerRole:GetLevel(),vipLevel=playerRole.m_VipLevel,icon=TeamManager.GetHeadIcon(playerRole.m_Profession,playerRole.m_Gender),power=playerRole.m_Power})
        local UIButton_Create=UIListItem_Team.Controls["UIButton_Create"]
        local UIButton_PrivateChat=UIListItem_Team.Controls["UIButton_PrivateChat"]
        local UIButton_PromotedCaptain=UIListItem_Team.Controls["UIButton_PromotedCaptain"]
        local UIButton_KickOut=UIListItem_Team.Controls["UIButton_KickOut"]
        UIButton_Create.gameObject:SetActive(true)
        UIButton_PrivateChat.gameObject:SetActive(false)
        UIButton_PromotedCaptain.gameObject:SetActive(false)
        UIButton_KickOut.gameObject:SetActive(false)
        local UILabel_Create=UIListItem_Team.Controls["UILabel_Create"]
        local UILabel_Leave= UIListItem_Team.Controls["UILabel_Leave"]
        local UILabel_MakeFriend=UIListItem_Team.Controls["UILabel_MakeFriend"]
        UILabel_Create.gameObject:SetActive(true)
        UILabel_Leave.gameObject:SetActive(false)
        UILabel_MakeFriend.gameObject:SetActive(false)
        EventHelper.SetClick(UIButton_Create,function()
            TeamManager.SendCreateTeam()
        end)
    end
end

local function update()
	
end

local function refresh(params)
   OnMsg_LoadTeamInfo()
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name,gameObject,fields=unpack(params)
end

return{
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
    uishowtype = uishowtype,
    OnMsg_LoadTeamInfo = OnMsg_LoadTeamInfo,
}
