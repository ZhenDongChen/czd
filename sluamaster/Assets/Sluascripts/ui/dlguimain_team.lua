local TeamManager = require("ui.team.teammanager")
local EventHelper = UIEventListenerHelper
local OtherCharacterHead = require("ui.uimain.othercharacterhead")
local PlayerRole = require("character.playerrole"):Instance()
local CharacterManager = require("character.charactermanager")
local EctypeManager = require("ectype.ectypemanager")
local UIManager = require("uimanager")
local Math = math
local ToString = tostring

local m_Name
local m_GameObject
local m_Fields

local function UpdateTeamInfo()
    local teamInfo = TeamManager.GetTeamInfo()
    if teamInfo then
        m_Fields.UIButton_CreateTeam.gameObject:SetActive(false)
        m_Fields.UIButton_FindTeam.gameObject:SetActive(false)
        if teamInfo.leaderid == PlayerRole.m_Id then
            m_Fields.UISprite_Captain.gameObject:SetActive(true)
        else
            m_Fields.UISprite_Captain.gameObject:SetActive(false)
        end
        m_Fields.UIButton_Leave.gameObject:SetActive(true)
        EventHelper.SetClick(m_Fields.UIButton_Leave, function()
            TeamManager.SendQuitTeam()
        end )
        m_Fields.UIGroup_Team.gameObject:SetActive(true)
        m_Fields.UIList_Team:Clear()
        for _, memberInfo in pairs(teamInfo.members) do
            if memberInfo.roleid ~= PlayerRole.m_Id then
                local item = m_Fields.UIList_Team:AddListItem()
                local roleInfo = memberInfo.roleinfo
                item.Id = memberInfo.roleid
                item.Data = roleInfo
                local UIButton_Head = item.Controls["UIButton_TeamHeadBG"]
                EventHelper.SetClick(UIButton_Head, function()
                    OtherCharacterHead.SetHeadInfoById(memberInfo.roleid)
                end )
                local UITexture_Head = item.Controls["UITexture_TeamHead"]
                if UITexture_Head then
                    local headIcon = TeamManager.GetHeadIcon(roleInfo.profession,roleInfo.gender)
                    UITexture_Head:SetIconTexture(headIcon)
                end
                local UILabel_Name = item.Controls["UILabel_TeamName"]
                if UILabel_Name then
                    UILabel_Name.text = roleInfo.name
                end
                local UILabel_LV = item.Controls["UILabel_TeamLV"]
                if UILabel_LV then
                    UILabel_LV.text = roleInfo.level
                end
                local localCharacter = CharacterManager.GetCharacter(memberInfo.roleid)
                if localCharacter then
                    local value = localCharacter.m_Attributes[cfg.fight.AttrId.HP_VALUE]/localCharacter.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
                    local UIProgressBar_HP = item.Controls["UIProgressBar_HP"]
                    UIProgressBar_HP.value = value
                    local UILabel_HP = item.Controls["UILabel_HP"]
                    UILabel_HP.text = ToString(Math.ceil(value * 100)) .. "%"
                end
                local UISprite_BG = item.Controls["UISprite_BG"]
                    EventHelper.SetClick(UISprite_BG, function()
                        OtherCharacterHead.SetHeadInfoById(memberInfo.roleid)
                end )
                -- IsLeader
                local UISprite_Leader = item.Controls["UISprite_Leader"]
                local UISprite_Follow = item.Controls["UISprite_Follow"]
                local UIButton_Follow = item.Controls["UIButton_Follow"]
                local UISprite_RemoveFollow = item.Controls["UISprite_RemoveFollow"]
                local UISprite_InviteFollow = item.Controls["UISprite_InviteFollow"]
                if memberInfo.roleid == teamInfo.leaderid then
                    -- Leader
                    UISprite_Leader.gameObject:SetActive(true)
                    if PlayerRole:IsFollowing() then
                        UISprite_Follow.gameObject:SetActive(true)
                        UIButton_Follow.gameObject:SetActive(false)
                    else
                        UISprite_Follow.gameObject:SetActive(false)
                        UIButton_Follow.gameObject:SetActive(true)
                        UISprite_RemoveFollow.gameObject:SetActive(true)
                        UISprite_InviteFollow.gameObject:SetActive(false)
                    end
                    EventHelper.SetClick(UIButton_Follow, function()
                        TeamManager.SendFollowLeader(teamInfo.teamid)
                    end )
                else
                    -- Not leader
                    UISprite_Leader.gameObject:SetActive(false)
                    -- Is Follow
                    if memberInfo.follow == 1 then
                        -- Following
                        UISprite_Follow.gameObject:SetActive(true)
                        UIButton_Follow.gameObject:SetActive(false)
                    else
                        UISprite_Follow.gameObject:SetActive(false)
                        if PlayerRole.m_Id == teamInfo.leaderid then
                            -- Current Player Is Leader
                            UIButton_Follow.gameObject:SetActive(true)
                            UISprite_RemoveFollow.gameObject:SetActive(false)
                            UISprite_InviteFollow.gameObject:SetActive(true)
                            EventHelper.SetClick(UIButton_Follow, function()
                                TeamManager.SendInviteFollow(memberInfo.roleid)
                            end )
                        else
                            UIButton_Follow.gameObject:SetActive(false)
                            UISprite_RemoveFollow.gameObject:SetActive(false)
                            UISprite_InviteFollow.gameObject:SetActive(false)
                        end
                    end
                end
            end
        end
    else
        m_Fields.UIButton_Leave.gameObject:SetActive(false)
        m_Fields.UIGroup_Team.gameObject:SetActive(false)
        m_Fields.UISprite_Captain.gameObject:SetActive(false)
        if EctypeManager.IsInEctype() then
            m_Fields.UIButton_CreateTeam.gameObject:SetActive(false)
            m_Fields.UIButton_FindTeam.gameObject:SetActive(false)
        else
            m_Fields.UIButton_CreateTeam.gameObject:SetActive(true)
            m_Fields.UIButton_FindTeam.gameObject:SetActive(true)
            EventHelper.SetClick(m_Fields.UIButton_CreateTeam,function()
                TeamManager.SendCreateTeam()
            end)
            EventHelper.SetClick(m_Fields.UIButton_FindTeam,function()
                UIManager.showdialog("team.dlgteam",nil,3)
            end)
        end
    end
end

local function RefreshTeamMemberHp(params)
    if UIManager.isshow("dlguimain") then
        local DlgUIMain = require("ui.dlguimain") 
        local index = DlgUIMain.GetCurTaskTabIndex()
        if index == 2 then
            local roleId = params.id
            if TeamManager.IsTeamMate(roleId) then
                local player = CharacterManager.GetCharacter(roleId)
                if player then
                    local item = m_Fields.UIList_Team:GetItemById(roleId)
                    if item then
                        local value = player.m_Attributes[cfg.fight.AttrId.HP_VALUE] / player.m_Attributes[cfg.fight.AttrId.HP_FULL_VALUE]
                        local UIProgressBar_HP = item.Controls["UIProgressBar_HP"]
                        if (UIProgressBar_HP.value ~= value) then
                            local UILabel_HP = item.Controls["UILabel_HP"]
                            UIProgressBar_HP.value = value
                            UILabel_HP.text = ToString(Math.ceil(value * 100)) .. "%"
                        end
                    end
                end
            end
        end
    end
end

local function RefreshTeamInfo()
    if UIManager.isshow("dlguimain") then
        local DlgUIMain = require("ui.dlguimain") 
        local index = DlgUIMain.GetCurTaskTabIndex()
        if index == 2 then
            UpdateTeamInfo()
        end
    end
end

local function hide()
end

local function destroy()
end

local function show()
end

local function refresh()
    UpdateTeamInfo()
end

local function init(name,gameObject,fields)
    m_Name = name
    m_GameObject = gameObject
    m_Fields = fields
end

return{
    init = init,
    show = show,
    refresh = refresh,
    destroy = destroy,
    hide = hide,
    RefreshTeamInfo = RefreshTeamInfo,
    RefreshTeamMemberHp = RefreshTeamMemberHp,
}
