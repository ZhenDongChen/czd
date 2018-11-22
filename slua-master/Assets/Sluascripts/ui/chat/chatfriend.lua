
local EventHelper = UIEventListenerHelper
local UIManager = require("uimanager")
local chatmanager = require("ui.chat.chatmanager")
local fields
local name
local gameObject
local PrivateChatList 
local g_InitPanelLocalPos
local g_InitPanelOffsetY 


local function DisplayOneFriend(friendItem,friend)
	friendItem:SetText("UILabel_Level",friend.level)
    friendItem:SetText("UILabel_Name",friend.name)
	friendItem.Controls["UITexture_IdolHead"]:SetIconTexture(friend.icon)
	friendItem.Controls["UILabel_VIP"].text = friend.viplevel
	friendItem.Controls["UILabel_Power"].text = friend.power	
--	friendItem.Controls[""].text = 
    EventHelper.SetClick(friendItem,function()
        local name = friendItem.Controls["UILabel_Name"]
		--local label_name  = fields.UILabel_SpeakTO.transform:Find("UILabel_Name")--
		chatmanager.SetCurPrivateChatName(name.text)
		local item = {}
		item.channel = cfg.chat.ChannelType.PRIVATE
		item.receiverName = chatmanager.GetCurPrivateChatName() or ""
		chatmanager.UpdateChatMessage(cfg.chat.ChannelType.PRIVATE,fields)
		UIManager.call("chat.dlgchat01","RefreshChatTitle")
--		UIManager.call("chat.dlgchat01","ReSendMessage",item)
    end)

end

local function OnFriendItemInit(go,wrapIndex,realIndex)
	printyellow("OnFriendItemInit go =>",go,"wrapIndex=>",wrapIndex,"realIndex=>",realIndex)
	if go == nil then
		return
	end
--	local PrivateChatList = chatmanager.GetPrivateChatList()
	local num = #PrivateChatList
	local UIListItem=go.gameObject:GetComponent(UIListItem)
	--printyellow("friend item name",UIListItem.name)
	printyellow("#PrivateChatList------- = ",num)
	local UIGroup = UIListItem.Controls["UIGroup_All"]
	printyellow("#realIndex------ = ",realIndex)
--	if (-realIndex+1) > num  or (-realIndex+1)<1 then
	if (realIndex + 1) > num then
        UIGroup.gameObject:SetActive(false)
    else
        UIGroup.gameObject:SetActive(true)
		--printyellow("true UIGroup wrapIndex",wrapIndex)
--        if realIndex<0 then
--            realIndex=-realIndex
--        end
        local infoIndex=realIndex + 1
        local friend=PrivateChatList[infoIndex]
		printyellow("infoIndex = ",infoIndex)
		printt(PrivateChatList)
		printyellow("friend",friend)
		printt(friend)
        if UIListItem then
            DisplayOneFriend(UIListItem,friend,fields)
        end
    end
end



local function RefreshPrivateChatList()  -- InitFriendList
	printyellow("RefreshPrivateChatList")
	PrivateChatList = chatmanager.GetPrivateChatList()
	printyellow("isFriendList = ",isFriendList)
	printt(PrivateChatList)
	fields.UIScrollView_Friend.currentMomentum = Vector3(0,0,0)
    local wrapContent=fields.UIList_Friend.gameObject:GetComponent(UIGridWrapContent)
	wrapContent:ResetAllChildPositions()
	local panel = fields.UIScrollView_Friend.gameObject:GetComponent(UIPanel)
	panel.transform.localPosition = g_InitPanelLocalPos
	panel:SetClipOffsetY(g_InitPanelOffsetY)

	local num = #PrivateChatList
	printyellow("InitFriendList")
    if wrapContent==nil then
        return
    end
--    wrapContent.itemSize=140
    wrapContent.minIndex=-(num-1)
    wrapContent.maxIndex=0
	printyellow("before setwrapcontent item")
    EventHelper.SetWrapContentItemInit(wrapContent,OnFriendItemInit)
	wrapContent.firstTime = true
	wrapContent:WrapContent()
--    wrapContent.enabled=true
    --wrapContent:SortAlphabetically()
    --wrapContent:WrapContent()
end


local function RefreshFriendList()
	PrivateChatList = chatmanager.GetPrivateChatList()
	local wrapContent = fields.UIList_Friend.gameObject:GetComponent(UIGridWrapContent)
	wrapContent.firstTime = true
	wrapContent:WrapContent()
end

local function InitChatFriend(iName,iGameObject,iFields)
	name		= iName
	gameObject = iGameObject
	fields	 = iFields
	local panel         = fields.UIScrollView_Friend.gameObject:GetComponent(UIPanel)
	g_InitPanelLocalPos = panel.transform.localPosition
	g_InitPanelOffsetY  = panel:GetClipOffsetY()

end

return {

	RefreshPrivateChatList = RefreshPrivateChatList,
	InitChatFriend = InitChatFriend,
}