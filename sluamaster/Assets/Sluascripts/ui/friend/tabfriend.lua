local unpack 		= unpack
local print 		= print
local UIManager 	= require("uimanager")
local FriendManager = require("ui.friend.friendmanager")
local PlayerRole = require "character.playerrole"
--local TeamBuffInfo  = require("ui.friend.teambuffinfo") 	--20180519注释
local EventHelper 	= UIEventListenerHelper
local gameObject
local fields
local name

local PageSelected = {
    PageFriend  = 1,
    PageIdol    = 2,
    PageBlack   = 3,
    PageEnemy   = 4,
    PageAdd     = 5,
    PageApply   = 6,
}

--[[
local function ChatWith(friendInfo)
    UIManager.showdialog("chat.dlgchat01",{id = friendInfo.m_RoleId, name = friendInfo.m_Name, index = 1})
end
local function TeamWith(friendInfo)
    local TeamManager       = require("ui.team.teammanager")
    TeamManager.SendInviteJoinTeam(friendInfo.m_RoleId)
end
]]
local inactiveShader = UnityEngine.Shader.Find("Unlit/Transparent Colored Gray")
local activeShader = UnityEngine.Shader.Find("Unlit/Transparent Colored")

local CurrentPage = PageSelected.PageFriend

local function SetItemUIControl(friendInfo,item,showOnlineInfo)
	item:SetText("UILabel_Name",friendInfo.m_Name)
	item:SetText("UILabel_VIP",friendInfo.m_VipLevel)
	item:SetText("UILabel_LV","LV."..friendInfo.m_Level)
	item:SetText("UILabel_Power",friendInfo.m_Power)



    local spriteVip = item.Controls["UISprite_VIP"]
    if spriteVip then
        if shouldHideVip() == true then
            spriteVip.gameObject:SetActive(false)
        else
            spriteVip.gameObject:SetActive(true)
        end
    end
    local texture = item.Controls["UITexture_Head"]
    local labelOnline = item.Controls["UILabel_Online"]
    local labelOffline = item.Controls["UILabel_Offlilne"]

    if texture then
        texture:SetIconTexture(friendInfo:GetIcon())
        if friendInfo:IsOnline() == true then
            texture.shader = activeShader
            if showOnlineInfo ~= nil then
                labelOnline.gameObject:SetActive(true)
                labelOffline.gameObject:SetActive(false)
            else
                labelOnline.gameObject:SetActive(false)
                labelOffline.gameObject:SetActive(false)
            end
        else
            texture.shader = inactiveShader
            if showOnlineInfo ~= nil then
                labelOnline.gameObject:SetActive(false)
                labelOffline.gameObject:SetActive(true)
            else
                labelOnline.gameObject:SetActive(false)
                labelOffline.gameObject:SetActive(false)
            end
        end
    end
    local UISprite_Head = item.Controls["UISprite_HeadBG"]
    EventHelper.SetClick(UISprite_Head, function ()
		print("UISprite_Head")
        UIManager.showdialog("otherplayer.dlgotherroledetails", { roleId = friendInfo.m_RoleId })
    end)
	return item
end

local function SetGroupDisplay(uiItem,index)
    local groups = {}
    groups[0] = uiItem.Controls["UIGroup_ItemHead"]
    groups[1] = uiItem.Controls["UIGroup_ItemFriend"]
    groups[2] = uiItem.Controls["UIGroup_ItemIdol"]
    groups[3] = uiItem.Controls["UIGroup_ItemBlacklist"]
    groups[4] = uiItem.Controls["UIGroup_ItemEnemy"]
    groups[5] = uiItem.Controls["UIGroup_ItemAdd"]
    groups[6] = uiItem.Controls["UIGroup_ItemApplication"]
    for i = 1,6 do
        if i ~= index then
            groups[i].gameObject:SetActive(false)
        else
            groups[i].gameObject:SetActive(true)
        end
    end
    if index == 2 then
        groups[0].gameObject:SetActive(false)
    else
        groups[0].gameObject:SetActive(true)
    end
end


local function SetUIList(uiList,num,index,data,func)
    local wrapList = uiList.gameObject:GetComponent("UIWrapContentList")

    EventHelper.SetWrapListRefresh(wrapList,function(uiItem,wrapIndex,realIndex)
        local uiGroup = uiItem.Controls["UIGroup_All"]
        uiGroup.gameObject:SetActive(true)
        SetGroupDisplay(uiItem,index)
        func(realIndex,data[realIndex],uiItem)
    end)
    wrapList:SetDataCount(num)
    wrapList:CenterOnIndex(0)

    if num == 0 then
        fields.UIGroup_Empty.gameObject:SetActive(true)
        if index == PageSelected.PageFriend then
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("friendlist")
        elseif index == PageSelected.PageIdol then
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("idollist")
        elseif index == PageSelected.PageBlack then
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("blacklist")
        elseif index == PageSelected.PageEnemy then
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("enemylist")
        elseif index == PageSelected.PageAdd then
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("addlist")
        else
            fields.UILabel_Empty.text = FriendManager.GetEmptyText("applylist")
        end
    else
        fields.UIGroup_Empty.gameObject:SetActive(false)
    end
end

local function GetTimeStr(time)
    local l_Time = os.date("*t", time)

    return string.format( "%04d/%02d/%02d %02d:%02d",l_Time.year,l_Time.month, l_Time.day, l_Time.hour, l_Time.min )
	--local l_Time = os.date("*t", friendInfo.m_Time/1000)
	--local l_TimeStr = ""
	--if l_Time ~= nil then
	--	l_TimeStr = "" .. l_Time.year .. "/" .. l_Time.month .. "/" .. l_Time.day .. " " .. l_Time.hour .. ":" .. l_Time.min
	--end
  --  return ""
end
------------------------------------------------------------------------------------------------------
--好友
local PageFriend = {}

function PageFriend:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false
end
function PageFriend:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
end
function PageFriend:hide()
    self.isshow = false
end
function PageFriend:refreshitem(num,friendInfo,item)
    SetItemUIControl(friendInfo,item, true)
    --item:SetIconTexture("UITexture_Youhaodu",)

    item:SetText("UILabel_FlowerNum",friendInfo:GetCharm())
    item:SetText("UILabel_FriendlyNum",friendInfo.m_FriendDegree)

    local UIButton_Check            = item.Controls["UIButton_Check"]
    local UIButton_GiveFlower 		= item.Controls["UIButton_GiveFlower"]

    local texture = item.Controls["UITexture_Relation"]
    local MaimaiHelper = require("ui.maimai.base.maimaihelper")
    local iconPath = MaimaiHelper.GetRelationIcon(friendInfo:GetRelation()) or ""

    texture:SetIconTexture(iconPath)

    EventHelper.SetClick(UIButton_Check, function()
		
        UIManager.showdialog("otherplayer.dlgotherroledetails", { roleId = friendInfo.m_RoleId })
		print("UIButton_Check")
    end)

    EventHelper.SetClick(UIButton_GiveFlower, function ()
        UIManager.show("friend.dlgsendflower", {targetType = cfg.item.FlowerType.PLAYER, targetId = friendInfo.m_RoleId})
    end)
end

function PageFriend:refresh()
    FriendManager.FriendsInfo.friendList:SetRedDot(false)
    self.fields.UIGroup_Flowers.gameObject:SetActive(true)
    local buttonSend = self.fields.UIButton_SendInfos
    local buttonReceive = self.fields.UIButton_ReceiveInfos
    local buttonBuffInfo = self.fields.UIButton_TeamBuff
    EventHelper.SetClick(buttonSend, function()
        FriendManager.GetSendFlowerInfo()
    end)
    EventHelper.SetClick(buttonReceive, function()
        FriendManager.GetReceiveFlowerInfo()
    end)
	--20180519注释
--[[    EventHelper.SetClick(buttonBuffInfo, function()
        TeamBuffInfo.ShowBuffInfo()
    end)--]]
	local friendNum = FriendManager.FriendsInfo.friendList:GetCount()
    self.fields.UIGroup_Friend.gameObject:SetActive(true)
    self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[1] .. friendNum .. "/100")
    SetUIList(  self.fields.UIList_Friend,
                friendNum,
                PageSelected.PageFriend,
                FriendManager.FriendsInfo.friendList:GetList(),
                function(num,friendInfo,item)
                    self:refreshitem(num,friendInfo,item)
                end)
end

------------------------------------------------------------------------------------------------------
--偶像




local PageIdol = {}

function PageIdol:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false
end
function PageIdol:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
	self.fields.UIGroup_Idol.gameObject:SetActive(true)

    self:HideGuard()
end
function PageIdol:hide()
    self.isshow = false
	self.fields.UIGroup_Idol.gameObject:SetActive(false)
    self:HideGuard()
end
function PageIdol:ShowGuard(pos, uiItem,idolInfo)
    local labelName = self.fields.UILabel_GuardianName
    local labelFavor = self.fields.UILabel_Favor
    local spriteBack = self.fields.UISprite_Background
    labelName.text = idolInfo.m_GuardName
    labelFavor.text = tostring(idolInfo.m_GuardDegree)
    self.fields.UIGroup_Pos.gameObject.transform.position = pos
   -- self.fields.UIGroup_Guardian.gameObject:SetActive(true)
    EventHelper.SetClick(spriteBack, function()
        self:HideGuard()
    end)
end
function PageIdol:HideGuard()
   -- self.fields.UIGroup_Guardian.gameObject:SetActive(false)
end

function PageIdol:refreshitem(num, idolInfo, item)

	item:SetText("UILabel_IdolRankNum",num)
	item:SetText("UILabel_IdolName",idolInfo.m_Name)


	local head = item.Controls["UITexture_IdolHead"]

	head:SetIconTexture(idolInfo.m_Icon)

	--item:SetTexture("UITexture_IdolHead",idolInfo.m_Icon)
    -- printyellow("UILabel_IdolYouhaoduNum",idolInfo.m_Name, idolInfo.m_FriendDegree)
    -- printyellow(item.Controls["UILabel_IdolYouhaoduNum"])


	item:SetText("UILabel_IdolYouhaoduNum",idolInfo.m_FriendDegree)
	item:SetText("UILabel_IdolDescription",idolInfo.m_Sign)

	item:SetText("UILabel_CharmNum",idolInfo:GetCharm())
	local button = item.Controls["UIButton_IdolSendFlower"]

	if button then
		EventHelper.SetClick(button, function()
			UIManager.show("friend.dlgsendflower", { targetType = cfg.item.FlowerType.NPC, targetId = idolInfo.m_Id } )
		end)
	end

    local guardIcon = item.Controls["UISprite_GuardIcon"]
    local guardName = item.Controls["UILabel_GuardName"]
    local guardDays = item.Controls["UILabel_GuardDays"]

    local guardId = idolInfo.m_GuardId
    if guardIcon and guardName and guardDays and guardId and guardId ~= 0 then
        guardIcon.gameObject:SetActive(true)
        guardName.text = tostring(idolInfo.m_GuardName)
        guardDays.text = string.format(LocalString.Friend.GuardDay, tostring(idolInfo:GetGuardDay()))
        EventHelper.SetClick(guardIcon, function()
            self:ShowGuard(guardIcon.transform.position, item, idolInfo)

    --        local content_info = string.format(LocalString.Friend.IdolGuardCheck, idolInfo.m_Name, idolInfo.m_GuardName, tostring(idolInfo.m_GuardDegree) )
    --        UIManager.ShowSingleAlertDlg({content=content_info})
        end)
    else
        guardIcon.gameObject:SetActive(false)
    end
end

function PageIdol:refresh()
    FriendManager.FriendsInfo.idolList:SetRedDot(false)
    fields.UISprite_Warning.gameObject:SetActive(FriendManager.ShowRewardsRedDot())
    self.fields.UIGroup_Flowers.gameObject:SetActive(false)
	local idolNum = FriendManager.FriendsInfo.idolList:GetCount()
    self.fields.UIGroup_Friend.gameObject:SetActive(false)
	self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[2] .. idolNum .. "/100")
    SetUIList(  self.fields.UIList_Friend,
                idolNum,
                PageSelected.PageIdol,
                FriendManager.FriendsInfo.idolList:GetList(),
                function(num, idolInfo, item)
                    self:refreshitem(num, idolInfo, item)
                end)

    EventHelper.SetClick(self.fields.UIButton_IdolRewards, function()
		UIManager.show("friend.dlgidolrewards")
	end)

end

------------------------------------------------------------------------------------------------------
--黑名单
local PageBlack = {}

function PageBlack:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false
end
function PageBlack:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
end
function PageBlack:hide()
    self.isshow = false
    --self.fields.UIList_Black.gameObject:SetActive(false)
end
function PageBlack:refreshitem(num,friendInfo,item)
	SetItemUIControl(friendInfo,item)
	--local l_Time = os.date("*t", friendInfo.m_Time/1000)
	local l_TimeStr = GetTimeStr(friendInfo.m_Time)
	--if l_Time ~= nil then
	--	l_TimeStr = "" .. l_Time.year .. "/" .. l_Time.month .. "/" .. l_Time.day .. " " .. l_Time.hour .. ":" .. l_Time.min
	--end
	item:SetText("UILabel_BlackTime",l_TimeStr)

	local buttonDelete = item.Controls["UIButton_BlackDelete"]
	local buttonCheck = item.Controls["UIButton_BlackCheck"]

	EventHelper.SetClick(buttonDelete, function()
		FriendManager.UnBlackFriend(friendInfo.m_RoleId)
	end)

	EventHelper.SetClick(buttonCheck, function()
		UIManager.showdialog("otherplayer.dlgotherroledetails",{roleId = friendInfo.m_RoleId})
	end)
end
function PageBlack:refresh()
    FriendManager.FriendsInfo.blackList:SetRedDot(false)
    self.fields.UIGroup_Flowers.gameObject:SetActive(false)
	local blackNum = FriendManager.FriendsInfo.blackList:GetCount()
    self.fields.UIGroup_Friend.gameObject:SetActive(true)
    self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[3] .. blackNum .. "/100")
    SetUIList(  self.fields.UIList_Friend,
                blackNum,
                PageSelected.PageBlack,
                FriendManager.FriendsInfo.blackList:GetList(),
                function(num, idolInfo, item)
                    self:refreshitem(num, idolInfo, item)
                end)
end
------------------------------------------------------------------------------------------------------
--仇敌
local PageEnemy = {}

function PageEnemy:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false
end
function PageEnemy:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
end
function PageEnemy:hide()
    self.isshow = false
end
function PageEnemy:refreshitem(num,friendInfo,item)
	SetItemUIControl(friendInfo,item,true)
    local l_TimeStr = GetTimeStr(friendInfo.m_Time)
	--local l_Time = os.date("*t", friendInfo.m_Time/1000)
	--local l_TimeStr = ""
	--if l_Time ~= nil then
	--	l_TimeStr = "" .. l_Time.year .. "/" .. l_Time.month .. "/" .. l_Time.day .. " " .. l_Time.hour .. ":" .. l_Time.min
	--end
	item:SetText("UILabel_EnemyTime",l_TimeStr)

    item:SetText("UILabel_KillTimes",tostring(friendInfo.m_KillTimes))
    item:SetText("UILabel_BeKillTimes",tostring(friendInfo.m_BeKillTimes))

	local buttonDelete = item.Controls["UIButton_EnemyDelete"]
	local buttonCheck = item.Controls["UIButton_EnemyCheck"]
    local buttonFollow = item.Controls["UIButton_Follow"]

	EventHelper.SetClick(buttonDelete, function()
		FriendManager.DeleteEnemy(friendInfo.m_RoleId)
	end)

	EventHelper.SetClick(buttonCheck, function()
		UIManager.showdialog("otherplayer.dlgotherroledetails",{roleId = friendInfo.m_RoleId})
	end)
    buttonFollow.isEnabled = friendInfo:IsOnline()
    EventHelper.SetClick(buttonFollow, function()
        FriendManager.CheckTrace(friendInfo.m_RoleId)
    end)
end
function PageEnemy:refresh()
    FriendManager.FriendsInfo.enemyList:SetRedDot(false)
    self.fields.UIGroup_Flowers.gameObject:SetActive(false)
	local enemyNum = FriendManager.FriendsInfo.enemyList:GetCount()
    self.fields.UIGroup_Friend.gameObject:SetActive(true)
    self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[6] .. enemyNum .. "/100")
    SetUIList(  self.fields.UIList_Friend,
                enemyNum,
                PageSelected.PageEnemy,
                FriendManager.FriendsInfo.enemyList:GetList(),
                function(num,friendInfo,item)
                    self:refreshitem(num,friendInfo,item)
                end)
end
------------------------------------------------------------------------------------------------------
--添加
local PageAdd = {}

function PageAdd:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false

end
function PageAdd:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
    self.fields.UIGroup_Add.gameObject:SetActive(true)
end
function PageAdd:hide()
    self.isshow = false
    --self.fields.UIList_Add.gameObject:SetActive(false)
    self.fields.UIGroup_Add.gameObject:SetActive(false)
end
function PageAdd:refreshitem(num,friendInfo,item)

	SetItemUIControl(friendInfo,item)
	item:SetText("UILabel_AddApplication",((friendInfo.m_Requested and LocalString.Friend.Applied) or LocalString.Friend.Apply))

    local UIButton_AddApplication 		= item.Controls["UIButton_AddApplication"]

	EventHelper.SetClick(UIButton_AddApplication, function ()
        if PlayerRole:Instance().m_Id ~= friendInfo.m_RoleId then
            FriendManager.RequestFriendById(friendInfo.m_RoleId)
        else
            UIManager.ShowSingleAlertDlg{content=LocalString.CanNotFriendSelf}
        end
	end)


end
function PageAdd:refresh()
    FriendManager.FriendsInfo.addList:SetRedDot(false)
    self.fields.UIGroup_Flowers.gameObject:SetActive(false)
	local addNum = FriendManager.FriendsInfo.addList:GetCount()

    self.fields.UIGroup_Friend.gameObject:SetActive(true)
    self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[4] .. addNum .. "/100")

    SetUIList(  self.fields.UIList_Friend,
                addNum,
                PageSelected.PageAdd,
                FriendManager.FriendsInfo.addList:GetList(),
                function(num,friendInfo,item)
                    self:refreshitem(num,friendInfo,item)
                end)

	EventHelper.SetClick(self.fields.UIButton_Find, function()
		FriendManager.SearchFriend(self.fields.UIInput_Friend.value)
	end)

	EventHelper.SetClick(self.fields.UIButton_Refresh, function()
		FriendManager.SearchFriend("")
	end)

end
------------------------------------------------------------------------------------------------------
--被申请
local PageApply = {}

function PageApply:init(name, gameObject, fields)
    self.fields = fields
    self.isshow = false
end
function PageApply:show()
    self.isshow = true
    self.fields.UILabel_FriendAmount.gameObject:SetActive(true)
    self.fields.UIList_Friend.gameObject:SetActive(true)
    self.fields.UIGroup_Apply.gameObject:SetActive(true)
end
function PageApply:hide()
    self.isshow = false
    self.fields.UIGroup_Apply.gameObject:SetActive(false)
end
function PageApply:refreshitem(num,friendInfo,item)
	SetItemUIControl(friendInfo,item)

	local UIButton_ApplicationAddition 		= item.Controls["UIButton_ApplicationAddition"]
	local UIButton_ApplicationReject		= item.Controls["UIButton_ApplicationReject"]

	EventHelper.SetClick(UIButton_ApplicationAddition, function ()
		FriendManager.AcceptFriend(friendInfo.m_RoleId)
	end)
	EventHelper.SetClick(UIButton_ApplicationReject, function ()
		FriendManager.RejectFriend(friendInfo.m_RoleId)
	end)
end
function PageApply:refresh()
    FriendManager.FriendsInfo.applyList:SetRedDot(false)
	local applyNum = FriendManager.FriendsInfo.applyList:GetCount()
    self.fields.UIGroup_Friend.gameObject:SetActive(true)
    self.fields.UIGroup_Flowers.gameObject:SetActive(false)
    self.fields.UILabel_FriendAmount.text = (LocalString.Friend.ListNumberName[5] .. applyNum .. "/100")

    SetUIList(  self.fields.UIList_Friend,
                applyNum,
                PageSelected.PageApply,
                FriendManager.FriendsInfo.applyList:GetList(),
                function(num,friendInfo,item)
                    self:refreshitem(num,friendInfo,item)
                end)

    --UIHelper.ResetItemNumberOfUIList(self.fields.UIList_Apply, applyNum)

	EventHelper.SetClick(self.fields.UIButton_AddAll, function()
		FriendManager.AcceptAllFriend()
	end)
	EventHelper.SetClick(self.fields.UIButton_RejectAll, function()
		FriendManager.RejectAllFriend()
	end)

end



local Pages ={
    [PageSelected.PageFriend]   = PageFriend,
    [PageSelected.PageIdol]     = PageIdol,
    [PageSelected.PageBlack]    = PageBlack,
    [PageSelected.PageAdd]      = PageAdd,
    [PageSelected.PageApply]    = PageApply,
    [PageSelected.PageEnemy]    = PageEnemy,
}

local function GetFriendInfoList(num)
    local lists = {
        [1] = FriendManager.FriendsInfo.friendList,
        [2] = FriendManager.FriendsInfo.idolList,
        [3] = FriendManager.FriendsInfo.blackList,
        [4] = FriendManager.FriendsInfo.enemyList,
        [5] = FriendManager.FriendsInfo.addList,
        [6] = FriendManager.FriendsInfo.applyList,
    }
    return lists[num]
end



local function RefreshRedDot()
    for i = 1, #Pages do
        local uiItem = fields.UIList_RadioButtonFriend:GetItemByIndex(i-1)
        if uiItem then
            local sprite = uiItem.Controls["UISprite_Warning"]
            local list = GetFriendInfoList(i)
            if sprite and list then
                local showDot = list:IsShowRedDot()
                if i == PageSelected.PageIdol and FriendManager.ShowRewardsRedDot() then
                    sprite.gameObject:SetActive(true)
                elseif i == PageSelected.PageApply and list:UnRead() then
                    sprite.gameObject:SetActive(true)
                else
                    sprite.gameObject:SetActive(false)
                end

            end
        end
    end
end

--===========================================================================
local function refresh(params)
    --local CurrentPage = fields.UIList_RadioButtonFriend:GetSelectedIndex() + 1
    if CurrentPage <= 0 then
        CurrentPage = 1
		FriendManager.GetFriendInfo()
        fields.UIList_RadioButtonFriend:SetSelectedIndex(CurrentPage-1)
    end
 --   local CurrentPage = UIManager.gettabindex("friend.dlgfriend")
    local page = Pages[CurrentPage]
    if page.isshow then
        page:refresh()
    else
        page:show()
        page:refresh()
        for i,k in pairs(Pages) do
            if CurrentPage ~= i then
                k:hide()
            end
        end
    end

    RefreshRedDot()

end

local function destroy()
  --print(name, "destroy")
end

local function show(params)
    if params and params.listIndex then
        CurrentPage = params.listIndex

        local selectIndex = fields.UIList_RadioButtonFriend:GetSelectedIndex()
        if CurrentPage-1 ~= selectIndex then
            fields.UIList_RadioButtonFriend:SetUnSelectedIndex(selectIndex)
            fields.UIList_RadioButtonFriend:SetSelectedIndex(CurrentPage-1)
        end
    end
--listIndex
    EventHelper.SetListClick(fields.UIList_RadioButtonFriend,function(uiItem)
        CurrentPage = uiItem.Index + 1
        UIManager.refresh(name)
        --Item.Index
    end)
end

local function hide()

end

local function update()
    --if FriendManager.ListGroup.listState.Refresh or FriendManager.ListGroup.listState.Reset then
    --    FriendManager.ListGroup.listState.Refresh = false
    --    FriendManager.ListGroup.listState.Reset = false
    --    UIManager.refresh("friend.tabfriend")
    --end
end

local function showtab(params)
    FriendManager.GetFriendInfo()
    UIManager.show("friend.tabfriend",params)
end
local function uishowtype()
    return UIShowType.Refresh
end
local function init(params)
   	name, gameObject, fields = unpack(params)

    for _, page in pairs(Pages) do
        page:init(name, gameObject, fields)
        page:hide()
    end
end
local function UnRead()
    return FriendManager.UnRead()
end

return {
  init = init,
  show = show,
  hide = hide,
  update = update,
  destroy = destroy,
  refresh = refresh,
  showtab = showtab,
  uishowtype = uishowtype,
  UnRead=UnRead,
}
