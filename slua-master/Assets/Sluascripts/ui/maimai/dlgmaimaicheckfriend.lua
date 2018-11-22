local unpack, print     = unpack, print
local UIManager         = require("uimanager")
local FriendManager     = require("ui.friend.friendmanager")
local MaimaiManager     = require("ui.maimai.maimaimanager")
local MaimaiHelper      = require("ui.maimai.base.maimaihelper")
local MarriageManager   = require("marriage.marriagemanager")
local ColorUtil         = require("common.colorutil")

local EventHelper 	= UIEventListenerHelper
local name, gameObject, fields
local friendList = nil
local relationship


local function CheckCondition(friendInfo,condition)
    if condition.limitGender ~= nil and condition.limitGender ~= -1 and condition.limitGender ~= friendInfo.m_Gender then
        return false
    end
    local mmInfo = MaimaiManager.GetMaimaiInfo()
    if mmInfo == nil or mmInfo:GetById(friendInfo:GetId()) ~= nil then
        return false
    end
    return true
end

local function FriendSort(friendA, friendB)
    if friendA:IsOnline() == true and friendB:IsOnline() == false then
        return true
    end
    if friendA:IsOnline() == false and friendB:IsOnline() == true then
        return false
    end
    if friendA.m_FriendDegree > friendB.m_FriendDegree then
        return true
    end
    return false
end

local function GetAllowFriendList(relationships,allFriendList)
    local reqGender = nil
    for _, relationship in pairs(relationships) do
        local rel_gender = MaimaiHelper.GetRelationGender(relationship)
        if rel_gender ~= reqGender then
            if reqGender == nil then
                reqGender = rel_gender
            else
                reqGender = nil 
                break
            end
        end
    end

    printyellow("reqGender",reqGender)
    local list = {}
    for i, frdInfo in ipairs(allFriendList) do
        if CheckCondition(frdInfo, {limitGender = reqGender}) == true then
            
            table.insert(list, frdInfo)
        end
    end
    utils.table_sort(list, FriendSort)
    return list
end

local function ShowFriendInfo(uiItem,index,realIndex)

    if friendList == nil or friendList[realIndex] == nil then
        return
    end
    local frdInfo = friendList[realIndex]
    
    uiItem:SetText("UILabel_VIP",frdInfo.m_VipLevel)
    uiItem:SetText("UILabel_Level", string.format(LocalString.Marriage.DivorceLv ,frdInfo.m_Level ))
    uiItem:SetText("UILabel_Name",frdInfo.m_Name)
    uiItem:SetText("UILabel_Amount",frdInfo.m_FriendDegree)
    local spriteVip = uiItem.Controls["UISprite_VIP"]
    if spriteVip then
        if shouldHideVip() == true then
            spriteVip.gameObject:SetActive(false)
        else
            spriteVip.gameObject:SetActive(true)
        end
    end
    local texture = uiItem.Controls["UITexture_Head"]
    texture:SetIconTexture(frdInfo:GetIcon())
    if frdInfo:IsOnline() then
        uiItem.Controls["UILabel_Online"].gameObject:SetActive(true)
        ColorUtil.SetTextureColorGray(texture, false)
    else
        uiItem.Controls["UILabel_Online"].gameObject:SetActive(false)
        ColorUtil.SetTextureColorGray(texture, true)
    end

    local button = uiItem.Controls["UIButton_Add"]
    
    if relationship == cfg.friend.MaimaiRelationshipType.BanLvNan or relationship == cfg.friend.MaimaiRelationshipType.BanLvNv then
        uiItem:SetText("UILabel_Add", LocalString.Marriage.Propose)
        EventHelper.SetClick(button, function()
            MarriageManager.CAttemptPropose(frdInfo.m_RoleId, frdInfo.m_Name)
            UIManager.hide(name)
        end)
    else
        uiItem:SetText("UILabel_Add", LocalString.Maimai.AddMaimai)
        EventHelper.SetClick(button, function()
            MaimaiManager.RequestMaimai(frdInfo.m_RoleId, relationship)
            UIManager.hide(name)
        end)
    end
    

end


local function refresh(params)
    if params == nil or params.listName == nil or params.relationships == nil then
        return
    end
    relationship = params.relationships[1]
    local allFriendList
    if params.listName ~= "Enemy" then
        fields.UILabel_FriendsAmount1.text = LocalString.Friend.FriendTypeName
        fields.UILabel_DlgTitle.text = LocalString.Friend.ListNumberName[1]
        allFriendList = FriendManager.GetFriends()
    else
        fields.UILabel_FriendsAmount1.text = LocalString.Friend.EnemyTypeName
        fields.UILabel_DlgTitle.text = LocalString.Friend.ListNumberName[6]
        allFriendList = FriendManager.GetEnemys()
    end

    friendList = GetAllowFriendList(params.relationships,allFriendList)
    
    
    fields.UILabel_FriendsAmount.text = tostring(#friendList) .. "/" .. tostring(#allFriendList)
    
    local wrapList = fields.UIList_Friend.gameObject:GetComponent("UIWrapContentList")
    
    EventHelper.SetWrapListRefresh(wrapList,ShowFriendInfo)
    wrapList:SetDataCount(#friendList)
    wrapList:CenterOnIndex(1.5)

end

local function destroy()

end



local function show(params)
    if params == nil or params.relationship == nil then
        UIManager.hide(name)
        return
    end
    
  --  friendList = GetFriendList(params)
  --  relationship = params.relationship
end

local function hide()

end

local function update()

end

local function init(params)
   	name, gameObject, fields = unpack(params)
    EventHelper.SetClick(fields.UIButton_Close, function()
        UIManager.hide(name)
    end)
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
}
