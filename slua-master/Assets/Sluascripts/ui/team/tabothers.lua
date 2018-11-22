local unpack = unpack
local EventHelper = UIEventListenerHelper
local Format = string.format
local NetWork = require("network")
local UIManager=require("uimanager")
local TeamManager=require("ui.team.teammanager")
local ConfigManager=require("cfg.configmanager")

local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local gameObject
local name
local fields
local m_TabIndex = 0
local m_FriendList={}
local m_RoleList={}
local m_TeamList={}

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

local function SetFriendDetailInfo(friendListItem,friend)
    if friendListItem and friend then
        local UIGroup_ItemFriend=friendListItem.Controls["UIGroup_ItemFriend"]
        local UIGroup_ItemApplication=friendListItem.Controls["UIGroup_ItemApplication"]
        local UIGroup_ItemFindPeople=friendListItem.Controls["UIGroup_ItemFindPeople"]
        local UIGroup_ItemFindTeam=friendListItem.Controls["UIGroup_ItemFindTeam"]
        local UIGroup_Head=friendListItem.Controls["UIGroup_Head"]
        UIGroup_Head.gameObject:SetActive( true)
        UIGroup_ItemFriend.gameObject:SetActive(true)
        UIGroup_ItemFindPeople.gameObject:SetActive(false)
        UIGroup_ItemFindTeam.gameObject:SetActive(false)
        SetHeadInfo(friendListItem,false,{name=friend.m_Name,level=friend.m_Level,vipLevel=friend.m_VipLevel,icon=TeamManager.GetHeadIcon(friend.m_Profession,friend.m_Gender),power=friend.m_Power})
        local UIButton_Team=friendListItem.Controls["UIButton_FriendTeam"]
        if friend.m_Online == true then
            friendListItem.Controls["UITexture_Head"].shader = activeShader
        else
            friendListItem.Controls["UITexture_Head"].shader = inactiveShader
        end
        EventHelper.SetClick(UIButton_Team,function()
            TeamManager.SendInviteJoinTeam(friend.m_RoleId)
        end)
    end
end

local function SetRoleDetailInfo(roleListItem,roleInfo)
    roleListItem.Id=roleInfo.roleid
    local UIGroup_ItemFriend=roleListItem.Controls["UIGroup_ItemFriend"]
    local UIGroup_ItemFindPeople=roleListItem.Controls["UIGroup_ItemFindPeople"]
    local UIGroup_ItemFindTeam=roleListItem.Controls["UIGroup_ItemFindTeam"]
    local UIGroup_Head=roleListItem.Controls["UIGroup_Head"]
    UIGroup_Head.gameObject:SetActive(true)
    UIGroup_ItemFriend.gameObject:SetActive(false)
    UIGroup_ItemFindPeople.gameObject:SetActive(true)
    UIGroup_ItemFindTeam.gameObject:SetActive(false)              
    SetHeadInfo(roleListItem,false,{name=roleInfo.name,level=roleInfo.level,vipLevel=roleInfo.viplevel,icon=TeamManager.GetHeadIcon(roleInfo.profession,roleInfo.gender),power=roleInfo.combatpower})    
    local UIButton_FindPeople=roleListItem.Controls["UIButton_FindPeople"]
    if (TeamManager.IsTeamMate(roleInfo.roleid)) then
        UIButton_FindPeople.isEnabled=false
    else
        UIButton_FindPeople.isEnabled=true
        EventHelper.SetClick(UIButton_FindPeople,function()
            if TeamManager.IsOwnTeamFull()==true then
                UIManager.ShowSystemFlyText(LocalString.Team_Full)
            else
                TeamManager.SendInviteJoinTeam(roleInfo.roleid)
            end
        end)
    end
end

local function SetTeamDetailInfo(teamListItem,teamInfo)
    local selfTeamInfo=TeamManager.GetTeamInfo()
    teamListItem.Data=teamInfo
    local UIGroup_ItemFriend=teamListItem.Controls["UIGroup_ItemFriend"]
    local UIGroup_ItemFindPeople=teamListItem.Controls["UIGroup_ItemFindPeople"]
    local UIGroup_ItemFindTeam=teamListItem.Controls["UIGroup_ItemFindTeam"]
    local UIGroup_Head=teamListItem.Controls["UIGroup_Head"]
    UIGroup_Head.gameObject:SetActive(true)
    UIGroup_ItemFriend.gameObject:SetActive(false)
    UIGroup_ItemFindPeople.gameObject:SetActive(false)
    UIGroup_ItemFindTeam.gameObject:SetActive(true)      
    local UIButton_FindTeam=teamListItem.Controls["UIButton_FindTeam"]
    EventHelper.SetClick(UIButton_FindTeam,function()
        if TeamManager.IsFull(teamInfo)==true then
            UIManager.ShowSystemFlyText(LocalString.Team_Full)
        else
            TeamManager.SendRequestJoinTeam(teamInfo.teamid)
            UIButton_FindTeam.isEnabled=false
        end
    end)
    local roleInfo=teamInfo.leader
    if roleInfo then                               
        SetHeadInfo(teamListItem,false,{name=roleInfo.name,level=roleInfo.level,vipLevel=roleInfo.viplevel,icon=TeamManager.GetHeadIcon(roleInfo.profession,roleInfo.gender),power=roleInfo.combatpower})  
    end
end

local function OnItemInit(UIListItem,wrapIndex,realIndex)
    if UIListItem==nil then
        return
    end
    if m_TabIndex == 2 then 
        local role=m_RoleList[realIndex]
        if UIListItem then
            SetRoleDetailInfo(UIListItem,role)
        end
    elseif m_TabIndex == 3 or m_TabIndex == 5 then
        local team=m_TeamList[realIndex]
        if UIListItem then
            SetTeamDetailInfo(UIListItem,team)
        end
    elseif m_TabIndex == 4 then
        local friend=m_FriendList[realIndex]
        if UIListItem then
            SetFriendDetailInfo(UIListItem,friend)
        end
    end
end

local function InitList(num)
    local wrapList=fields.UIList_Friend.gameObject:GetComponent("UIWrapContentList")
    if wrapList==nil then
        return
    end
    EventHelper.SetWrapListRefresh(wrapList,OnItemInit)
    if num==nil then
        num=0
    end
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(-0.5)
end

local function RefreshPlayers(msg)
    fields.UIGroup_Friend.gameObject:SetActive(false)
    fields.UIGroup_Find.gameObject:SetActive(true)
    fields.UILabel_DeleteAll.gameObject:SetActive(false)
    fields.UILabel_Refresh.gameObject:SetActive(true)
	
    m_RoleList=msg.rolelist
	printyellow("findpeople number:"..tostring(#(m_RoleList)))
    EventHelper.SetClick(fields.UIButton_DeleteAll,function()
        TeamManager.SendFindNearByRole()
    end)
    if #(m_RoleList) and (#(m_RoleList)==0) then       
        UIManager.ShowSingleAlertDlg({title=LocalString.Exchange_Tip,content=LocalString.Team_NotHaveNearbyPlayer})
    end  
    InitList(#(m_RoleList))
end
 
local function RefreshNormalTeams(msg)
    fields.UIGroup_Friend.gameObject:SetActive(false)
    fields.UIGroup_Find.gameObject:SetActive(true)
    fields.UILabel_DeleteAll.gameObject:SetActive(false)
    fields.UILabel_Refresh.gameObject:SetActive(true)
    EventHelper.SetClick(fields.UIButton_DeleteAll,function()
        TeamManager.SendFindNearByTeam()
    end)   
    m_TeamList={}  
    if msg then             
        local selfTeamInfo=TeamManager.GetTeamInfo()
        local HeroChallengeManager = require("ui.activity.herochallenge.herochallengemanager")
        local openLevel,stage,stageLevel = HeroChallengeManager.GetStageByLevel()
        for _,teamInfo in pairs(msg.teamlist) do
            if not (selfTeamInfo and (teamInfo.teamid == selfTeamInfo.teamid)) then
                table.insert(m_TeamList,teamInfo)
            end
        end       
    end
    if #(m_TeamList)==0 then            
        UIManager.ShowSingleAlertDlg({title=LocalString.Exchange_Tip,content=LocalString.Team_NotHaveNearbyTeam})
    end
    InitList(#m_TeamList)
end

local function LoadFriends()
    fields.UIGroup_Friend.gameObject:SetActive(true)
    fields.UIGroup_Find.gameObject:SetActive(false)
    local FriendManager = require("ui.friend.friendmanager")
    m_FriendList = FriendManager.GetFriends()
    local friendNum = #m_FriendList
    local text = Format(LocalString.Team_FriendNum,friendNum,100)
    fields.UILabel_FriendAmount.text=text
    if friendNum == 0 then
        UIManager.ShowSingleAlertDlg({title = LocalString.Exchange_Tip,content = LocalString.Team_NotHaveFriend})
    end
    InitList(friendNum)          
end

local function RefreshFriendInfo()
    if m_TabIndex == 4 then
        LoadFriends()
    end
end

local function update()
end

local function refresh()   
    m_TabIndex=UIManager.gettabindex("team.dlgteam")
    if m_TabIndex == 2 then
        TeamManager.SendFindNearByRole()
    elseif m_TabIndex == 3 then
        TeamManager.SendFindNearByTeam() 
    elseif m_TabIndex == 4 then
        LoadFriends()
    elseif m_TabIndex == 5 then
        --星宿队伍
        TeamManager.SendFindNearByTeam()
    end
end

local function uishowtype()
    return UIShowType.Refresh
end

local function init(params)
    name, gameObject, fields = unpack(params)          
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  uishowtype = uishowtype,
  RefreshFriendInfo = RefreshFriendInfo,
  RefreshNormalTeams = RefreshNormalTeams,
  RefreshPlayers = RefreshPlayers,
}