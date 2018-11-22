local EventHelper           = UIEventListenerHelper
local UIManager             = require("uimanager")
local TeamManager           = require("ui.team.teammanager")
local FriendManager         = require("ui.friend.friendmanager")
local FamilyManager         = require("family.familymanager")
local MarriageManager = require("marriage.marriagemanager")

local name, gameObject, fields
--==========================================================================================
local function OnTipButtonDown()
    fields.UIGroup_Tips.gameObject:SetActive(false)
end

--聊天
local function Button_Chat(charInfo, params, OnTipButtonDown)
    EventHelper.SetClick(fields.UIButton_PrivateChat, function()
        UIManager.showdialog("chat.dlgchat01",{id = charInfo:GetId(), name = charInfo:GetName(), index = 2})
        OnTipButtonDown()
    end) 
end
--组队
local function Button_Team(charInfo, params, OnTipButtonDown)
    if TeamManager.IsTeamMate(charInfo:GetId()) then
        if params.simple then
            fields.UIButton_Team.isEnabled = false
            fields.UILabel_Team.gameObject:SetActive(true)
            fields.UILabel_KickOut.gameObject:SetActive(false) 
        else
            if TeamManager.IsLeader(PlayerRole:Instance().m_Id) then 
                fields.UIButton_Team.isEnabled = true
                fields.UILabel_Team.gameObject:SetActive(false)
                fields.UILabel_KickOut.text = LocalString.Team_KickOut
                fields.UILabel_KickOut.gameObject:SetActive(true)            
                EventHelper.SetClick(fields.UIButton_Team, function()
                    TeamManager.SendKickOut(charInfo:GetId())
                    OnTipButtonDown()
                end)
            else
                fields.UIButton_Team.isEnabled = true
                fields.UILabel_Team.gameObject:SetActive(true)
                fields.UILabel_KickOut.gameObject:SetActive(false)
                EventHelper.SetClick(fields.UIButton_Team, function()
                    UIManager.ShowSystemFlyText(LocalString.Team_TeamMate)
                    OnTipButtonDown()
                end)
            end 
        end
    else
        fields.UIButton_Team.isEnabled = true
        fields.UILabel_Team.gameObject:SetActive(true)
        fields.UILabel_KickOut.gameObject:SetActive(false)
        EventHelper.SetClick(fields.UIButton_Team, function()
            TeamManager.SendInviteJoinTeam(charInfo:GetId())
            OnTipButtonDown()
        end)
    end
end
--查看详细信息
local function Button_Check(charInfo, params, OnTipButtonDown)
    EventHelper.SetClick(fields.UIButton_Check, function()
        UIManager.showdialog("otherplayer.dlgotherroledetails",{roleId = charInfo:GetId()})
        OnTipButtonDown()
    end)
end
--加好友
local function Button_Friend(charInfo, button, OnTipButtonDown)
    EventHelper.SetClick(fields.UIButton_MakeFriend, function()
        if FriendManager.IsFriend(charInfo:GetId()) then
            UIManager.ShowSystemFlyText(string.format(LocalString.Friend_IsFriend,charInfo:GetName()))
        else
            if charInfo:GetId() ~= PlayerRole.Instance().m_Id then
                FriendManager.RequestFriendById(charInfo:GetId())
            end
        end
        OnTipButtonDown()
    end)
end
--结婚
local function Button_Marriage(charInfo, params, OnTipButtonDown)
    if MarriageManager.IsMarriaged() then
        if params.simple then
            fields.UIButton_Propose.isEnabled = false
            fields.UILabel_Propose.text = LocalString.Marriage.Propose
        else
            if MarriageManager.GetCoupleRoleID() == charInfo:GetId() then
                fields.UILabel_Propose.text = LocalString.Marriage.Divorce
                UITools.SetButtonEnabled(fields.UIButton_Propose,true)
                EventHelper.SetClick(fields.UIButton_Propose, function()
                    MarriageManager.OpenDivorceWithDiscussDlg(charInfo:GetId(),charInfo:GetName())
                    OnTipButtonDown()
                end)
            else
                fields.UILabel_Propose.text = LocalString.Marriage.Propose
                UITools.SetButtonEnabled(fields.UIButton_Propose,false)
            end
        end                      
    else
        if params.simple then
            fields.UIButton_Propose.isEnabled = false
            fields.UILabel_Propose.text = LocalString.Marriage.Propose
        else
            fields.UILabel_Propose.text = LocalString.Marriage.Propose
            UITools.SetButtonEnabled(fields.UIButton_Propose,true)
            EventHelper.SetClick(fields.UIButton_Propose, function()                  
                MarriageManager.CAttemptPropose(charInfo:GetId(),charInfo:GetName())
                OnTipButtonDown()
            end)
        end
    end
end
--邀请入公会
local function Button_InviteFamily(charInfo, params, OnTipButtonDown)
    if FamilyManager.InFamily() and FamilyManager.CanInviteFamily() then
        if charInfo.m_FamilyName == nil or charInfo.m_FamilyName == "" then
            UITools.SetButtonEnabled(fields.UIButton_InviteFamily,true)
            EventHelper.SetClick(fields.UIButton_InviteFamily, function()
                local applymgr = require("family.applymanager")
                applymgr.InviteFamily(charInfo:GetId())               
                OnTipButtonDown()
            end)
        else
            UITools.SetButtonEnabled(fields.UIButton_InviteFamily,false)
        end        
    else
        UITools.SetButtonEnabled(fields.UIButton_InviteFamily,false)
    end
end

--=================================================================================
local showTime = 0
local MaxCoutDownTime = 5
local topMode = true

local function hide()

end

local function update()

end

local function second_update()
    showTime = showTime + 1
    if showTime > MaxCoutDownTime then
        if UIManager.isshow(name) then
            UIManager.hide(name)
            showTime = 0
        end
    end
end

local function OnTipButtonDown()
    UIManager.hide(name)
end

local function refresh(params)
    showTime = 0
    if not (params and params.charInfo) then
        return
    end
    MaxCoutDownTime = params.coutDownTime or 5
    local isSimpleMode = params.simpleMode or false
    if params.sideMode == true then
        topMode = false
    else
        topMode = true
    end
    local charInfo = params.charInfo
    
    fields.UIGroup_Tips.gameObject.transform.position = params.position

    local buttonParam = {simple = isSimpleMode}

    Button_Chat(charInfo, buttonParam, OnTipButtonDown)
    Button_Check(charInfo, buttonParam, OnTipButtonDown)
    Button_Marriage(charInfo, buttonParam, OnTipButtonDown)
    Button_Friend(charInfo, buttonParam, OnTipButtonDown)
    Button_Team(charInfo, buttonParam, OnTipButtonDown)
    Button_InviteFamily(charInfo, buttonParam, OnTipButtonDown)
end

local function HideTopTips()
    if topMode == true then
        UIManager.hide(name)
    end
end
local function HideSideTips()
    if topMode ~= true then
        UIManager.hide(name)
    end
end

local function show(params)
    if not (params and params.charInfo) then
        UIManager.hide(name)
    end
end

local function init(params)
    name, gameObject, fields = unpack(params)
end

return {
    init = init,
    show = show,
    refresh = refresh,
    update = update,
    hide = hide,
    second_update = second_update,
    HideTopTips = HideTopTips,
    HideSideTips = HideSideTips,
}