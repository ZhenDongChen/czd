local AttributeHelper   = require("attribute.attributehelper")
local ConfigManager     = require("cfg.configmanager")
local FriendManager     = require("ui.friend.friendmanager")
local TeamManager       = require("ui.team.teammanager")
local EventHelper       = UIEventListenerHelper
--local TitleManager      = require("ui.title.titlemanager")
local UIManager         = require("uimanager")

local name, gameObject, fields

local m_TeamRefreshTime=nil
local m_TeamColdTime=5

local function RefreshRightPlayerInfo(player)
    if shouldHideVip() == true then
        fields.UISprite_VIPBG.gameObject:SetActive(false)
    else
        fields.UISprite_VIPBG.gameObject:SetActive(true)
    end
    
    fields.UILabel_Name.text    = player.m_Name
    fields.UILabel_VIP.text     = player.m_VipLevel
    fields.UILabel_Title.text   = (player.m_Title == nil) and ""-- or TitleManager.GetTitleName(player.m_Title.m_Id)
    

    fields.UILabel_Level.text   = player.m_Level
    local professionCfg = ConfigManager.getConfigData("profession", player.m_Profession)
    fields.UILabel_School.text  = professionCfg.name
    fields.UILabel_Family.text  = player.m_FamilyName
    fields.UILabel_Couples.text = player.m_LoverName

    fields.UILabel_PlayerId.text = tostring(player.m_Id)
end


local function RefreshRightFightInfo(player)
    local attributes = player.m_Attributes

    fields.UILabel_Fight.text   = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.ATTACK_VALUE_MIN, 
                                    attributes[cfg.fight.AttrId.ATTACK_VALUE_MIN])
                                .. "-" 
                                .. AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.ATTACK_VALUE_MAX, 
                                    attributes[cfg.fight.AttrId.ATTACK_VALUE_MAX])

    fields.UILabel_Defense.text = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.DEFENCE, 
                                    attributes[cfg.fight.AttrId.DEFENCE])

    fields.UILabel_Hit.text     = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.HIT_RATE, 
                                    attributes[cfg.fight.AttrId.HIT_RATE])

    fields.UILabel_Hide.text    = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.HIT_RESIST_RATE, 
                                    attributes[cfg.fight.AttrId.HIT_RESIST_RATE])

    fields.UILabel_Crit.text    = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.CRIT_RATE, 
                                    attributes[cfg.fight.AttrId.CRIT_RATE])
                                    
    fields.UILabel_Hurt.text    = AttributeHelper.GetAttributeValueString(
                                    cfg.fight.AttrId.CRIT_VALUE, 
                                    attributes[cfg.fight.AttrId.CRIT_VALUE])
end

local function AddFriend(player)
    FriendManager.RequestFriendById(player.m_Id)
end

local function DeleteFriend(player)
    FriendManager.DeleteFriend(player.m_Id)
end

local function PrivateChat(player)
    UIManager.showdialog("chat.dlgchat01",{id = player.m_Id, name = player.m_Name, index = 2})
end

local function TeamWith(player)
    if m_TeamRefreshTime then
        if (os.time()-m_TeamRefreshTime)>m_TeamColdTime then
            TeamManager.SendInviteJoinTeam(player.m_Id)
            m_TeamRefreshTime=os.time()
        else
            UIManager.ShowSystemFlyText(string.format(LocalString.Team_Cold,m_TeamColdTime))
        end
    else
        TeamManager.SendInviteJoinTeam(player.m_Id)
        m_TeamRefreshTime=os.time()
    end
        
end

local function AddToBlackList(player)
    FriendManager.BlackFriend(player.m_Id)
end

local function InviteFamily(player)
    local applymgr = require("family.applymanager")
    applymgr.InviteFamily(player.m_Id)   
end

local function RemoveFromBlackList(player)
    FriendManager.UnBlackFriend(player.m_Id)
end

local m_Buttons = {
    [1] = {name = LocalString.OtherPlayerDetails_AddFriend, action = AddFriend },
    [2] = {name = LocalString.OtherPlayerDetails_PrivateChat,action = PrivateChat },
    [3] = {name = LocalString.OtherPlayerDetails_TeamWith,action = TeamWith },
    [4] = {name = LocalString.OtherPlayerDetails_AddBlack,action = AddToBlackList },
    [5] = {name = LocalString.OtherPlayerDetails_InviteFamily,action = InviteFamily },
}

local function RefreshButtonsInfo(player,buttons)

    if FriendManager.IsFriend(player.m_Id) then
        m_Buttons[1].name = LocalString.OtherPlayerDetails_DeleteFriend
        m_Buttons[1].action = DeleteFriend
    else
        m_Buttons[1].name = LocalString.OtherPlayerDetails_AddFriend
        m_Buttons[1].action = AddFriend
    end


    if FriendManager.IsBlack(player.m_Id) then
        m_Buttons[4].name = LocalString.OtherPlayerDetails_DeleteBlack
        m_Buttons[4].action = RemoveFromBlackList
    else
        m_Buttons[4].name = LocalString.OtherPlayerDetails_AddBlack
        m_Buttons[4].action = AddToBlackList
    end

    m_Buttons[6] = nil
    local buttonsNum = 0
    if buttons then
        for i, k in ipairs(buttons) do

            m_Buttons[5 + i] = {name = k.name, action = k.action}
            m_Buttons[ 6 + i] = nil
            buttonsNum = buttonsNum + 1
        end
    end


    UIHelper.ResetItemNumberOfUIList(fields.UIList_Buttons,#m_Buttons)
    for i = 1,(5 + buttonsNum) do
        local item = fields.UIList_Buttons:GetItemByIndex(i-1)
        local button = item.gameObject:GetComponent("UIButton")
        if button == nil then
            break
        end


        item:SetText("UILabel_AddFriend",m_Buttons[i].name)

        if player.m_Id == PlayerRole:Instance():GetId() then
            button.isEnabled = false
        else
            button.isEnabled = true
        end

        if i == 5 then 
            local familymgr = require("family.familymanager")
            if familymgr.InFamily() and familymgr.CanInviteFamily() then
                if player.m_FamilyName == nil or player.m_FamilyName == "" then
                    button.isEnabled = true
                else
                    button.isEnabled = false
                end        
            else
                button.isEnabled = false
            end
        end

        EventHelper.SetClick(button, function()
            if m_Buttons[i].action ~= nil then

                m_Buttons[i].action(player)

                UIManager.refresh("otherplayer.dlgotherroledetails",{player = player, param = ParamSave})
            end
        end)
    end

end



local function refresh(roleId, roleInfo, player, buttons)
    RefreshRightPlayerInfo(player)
    RefreshRightFightInfo(player)
    RefreshButtonsInfo(player,buttons)
end


local function show(roleId, roleInfo, player, buttons)
    RefreshRightPlayerInfo(player)
    RefreshRightFightInfo(player)
    RefreshButtonsInfo(player,buttons)
end


local function hide()

end

local function update()

end

local function destroy()

end

local function init(name_in, gameObject_in, fields_in)
    name, gameObject, fields = name_in, gameObject_in, fields_in
    m_TeamRefreshTime=nil
end


return {
    init = init,
    show = show,
    hide = hide,
    update = update,
    destroy = destroy,
    refresh = refresh,
}