local Unpack            = unpack
local EventHelper       = UIEventListenerHelper
local UIManager         = require("uimanager")
local MaimaiActManager  = require("ui.activity.maimai.maimaiactmanager")
local MaimaiManager     = require("ui.maimai.maimaimanager")
local TeamManager       = require ("ui.team.teammanager")
local FriendManager     = require("ui.friend.friendmanager")
local name
local gameObject
local fields
local wrapList
local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local function destroy()
    
end



local function update()
    
end

local function hide()

end

local function refreshitem(num,friendInfo,item)
    --printyellow("index==",num)
    local friendTimes = MaimaiActManager.getFriendTimes()
    local NameLabel = item.Controls["UILabel_Name"]
    NameLabel.text = friendInfo.playerInfo:GetRole():GetName()
    local LvLabel = item.Controls["UILabel_LV"]
    LvLabel.text = "LV"..friendInfo.playerInfo:GetRole().m_Level
    local PowerLabel = item.Controls["UILabel_Power"]
    PowerLabel.text = friendInfo.playerInfo:GetRole().m_Power
    local textureHead = item.Controls["UITexture_Head"]  
    textureHead:SetIconTexture(friendInfo.playerInfo:GetRole():GetIcon())
    local VipLabel = item.Controls["UILabel_VIP"]
    VipLabel.text = friendInfo.playerInfo:GetRole():GetVipLevel()
    local OnLineSp = item.Controls["UILabel_Online"]
    local OffLineSp = item.Controls["UILabel_Offlilne"]

    local UIButton_AddApplication = item.Controls["UIButton_AddApplication"]
    EventHelper.SetClick(UIButton_AddApplication, function ()
        TeamManager.SendInviteJoinTeam(friendInfo.playerInfo:GetRole():GetId())
    end)
    local frdInfo = FriendManager.GetFriendById(friendInfo.playerInfo:GetRole():GetId())
    local isOnline = true
    if frdInfo then
        isOnline = frdInfo:IsOnline()
    end
    if isOnline then
        textureHead.shader = activeShader
        OnLineSp.gameObject:SetActive(true)
        OffLineSp.gameObject:SetActive(false)
        UIButton_AddApplication.isEnabled = true
    else
        textureHead.shader = inactiveShader
        OnLineSp.gameObject:SetActive(false)
        OffLineSp.gameObject:SetActive(true)
        UIButton_AddApplication.isEnabled = false
    end
    
    local texture = item.Controls["UITexture_Relation"]
    local MaimaiHelper = require("ui.maimai.base.maimaihelper")
    local iconPath = MaimaiHelper.GetRelationIcon(friendInfo.relation) or ""
    texture:SetIconTexture(iconPath)

    

    local UILabel_FlowerNum = item.Controls["UILabel_FlowerNum"]
    if friendTimes then
        UILabel_FlowerNum.text = friendTimes[friendInfo.playerInfo:GetRole():GetId()]
    else
        UILabel_FlowerNum.text = 0
    end
end

local function SetUIList(wrapList,num,data,func)
    
    EventHelper.SetWrapListRefresh(wrapList,function(uiItem,wrapIndex,realIndex)
        local uiGroup = uiItem.Controls["UIGroup_All"]
        uiGroup.gameObject:SetActive(true)
        --SetGroupDisplay(uiItem,index)
        func(realIndex,data[realIndex],uiItem)
    end)  
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(0)
end

local function refresh(params)
    local maimaiList = MaimaiActManager.getMaimaiData()
    SetUIList(wrapList,#maimaiList,maimaiList,
        function(num,friendInfo,item)
            refreshitem(num,friendInfo,item)
        end)
end

local function uishowtype()
	-- 公用弹窗hide直接销毁，防止其他界面使用出现
	-- 公用部分显隐错误
	return UIShowType.DestroyWhenHide
end

local function show(params)
    wrapList = fields.UIList_Friend.gameObject:GetComponent("UIWrapContentList")
end

local function init(params)
    name,gameObject,fields=Unpack(params)
    EventHelper.SetClick(fields.UIButton_Close,function ()
        UIManager.hide(name)
    end)    
end

return{
    show = show,
    init = init,
    update = update,
    refresh = refresh,
    hide = hide,
	uishowtype = uishowtype,
}
