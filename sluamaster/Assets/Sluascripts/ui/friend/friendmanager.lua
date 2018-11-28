local network        = require "network"
local UIManager      = require "uimanager"
local ConfigManager  = require("cfg.configmanager")
local ItemManager    = require("item.itemmanager")
local FriendInfo     = require("ui.friend.info.friendinfo")
local EnemyInfo      = require("ui.friend.info.enemyinfo")
local IdolInfo       = require("ui.friend.info.idolinfo")
local FlowerInfo     = require("ui.friend.info.flowerinfo")
local RoleList       = require("ui.friend.info.rolelist")
local PlayerRoleInfo = require("ui.friend.info.playerroleinfo")
local MaimaiManager  = require("ui.maimai.maimaimanager")
local InfoManager    = require("assistant.infomanager")
local GameEvent      = require("gameevent")
--=========================================================================================================================
local listenerId = nil


local FRIEND_LIST_TYPE = {
    FRIEND = "friendList",
    IDOL = "idolList",
    BLACK = "blackList",
    ENEMY = "enemyList",
    ADD = "addList",
    APPLY = "applyList",
}

local FriendsInfo = {
    myInfo      = nil,
    showIdolIds = {},
    lastShowTime = 0,

    friendList  = RoleList:new( FriendInfo, {} ),                    --好友列表
    idolList    = RoleList:new( IdolInfo,   {} ),                    --偶像列表
    blackList   = RoleList:new( FriendInfo, {}, "RoleShowInfo" ),    --黑名单列表
    enemyList   = RoleList:new( EnemyInfo, {}, "RoleShowInfo" ),    --仇敌列表
    addList     = RoleList:new( FriendInfo, {}, "RoleShowInfo" ),    --添加列表
    applyList   = RoleList:new( FriendInfo, {}, "RoleShowInfo" ),    --申请列表   

    dlgList = {},

    lastBlackTime = 0,
}


local function RefreshUI()
    if UIManager.isshow("otherplayer.dlgotherroledetails") then
        UIManager.refresh("otherplayer.dlgotherroledetails")
    end
    if UIManager.isshow("friend.tabfriend") then
        UIManager.refresh("friend.tabfriend")
    end
    if UIManager.isshow("team.tabothers") then
        UIManager.refresh("team.tabothers")
    end
end
--=========================================================================================================================
------------------------------------------------------------------------------------------------------------------
--获取朋友、偶像、黑名单、添加、申请列表

local function GetFriendInfo()
    --printyellow("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    local re = lx.gs.friend.msg.CGetFriendInfo({})
    network.send(re)
end

local function OnMsgSGetFriendInfo(msg)
    --printyellow(msg)
    --加载本地偶像信息
	local idolConfig = ConfigManager.getConfig("idol")
    FriendsInfo.friendList     = RoleList:new(FriendInfo, msg.friendinfo)       --好友列表
    FriendsInfo.idolList       = RoleList:new(IdolInfo,   idolConfig)           --偶像列表
    FriendsInfo.blackList      = RoleList:new(FriendInfo, msg.blackinfo,     "RoleShowInfo")        --黑名单列表
    FriendsInfo.enemyList      = RoleList:new(EnemyInfo,  msg.enemyinfo,     "RoleShowInfo")        --仇敌列表
    FriendsInfo.addList        = RoleList:new(FriendInfo, {},                "RoleShowInfo")                   --添加列表
    FriendsInfo.applyList      = RoleList:new(FriendInfo, msg.requestinginfo,"RoleShowInfo")   --申请列表    
    
    FriendsInfo.myInfo         = PlayerRoleInfo:new(msg.myinfo)
    --设置偶像魅力
    --printyellow("===================================")
    --printyellow(msg.idolcharminfo)
    --printt(msg.idolcharminfo)
    --printyellow("===================================")
    for i, idolInfo in pairs(FriendsInfo.idolList:GetList()) do
        local id = idolInfo:GetId()
        local msgIdol = msg.idolcharminfo[id]
        if idolInfo and msgIdol then
            if type(msgIdol) == "number" then
                idolInfo:SetCharm(msg.idolcharminfo[id])
            else
                idolInfo:SetServerInfo(msgIdol)
            end
        end
        idolInfo:SetFriendDegree(msg.myinfo.idolfrienddegree[id])
        idolInfo:SetAwardInfo(msg.myinfo.idolawardclaiminfo[id])
    end
    FriendsInfo.friendList:Sort()
    FriendsInfo.idolList:Sort()
    
    MaimaiManager.InitMaimaiInfo(msg.myinfo)
    
    RefreshUI()
    GameEvent.evt_notify:trigger("friends_refreshall", {})
end



------------------------------------------------------------------------------------------------------------------
--请求加为好友
local function RequestFriendById(roleId)
    local re = lx.gs.friend.msg.CRequestFriend({roleid=roleId})
    network.send(re)
end
local function OnMsgSRequestFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.addList:RemoveById(msg.friend.roleid)
    RefreshUI()
end

------------------------------------------------------------------------------------------------------------------
--接受好友
local function AcceptFriend(roleId)
    local re = lx.gs.friend.msg.CAcceptFriend({roleidlist = {roleId}})
    network.send(re)
end
--接受全部好友
local function AcceptAllFriend()
    local accs = {}
    for i,friendInfo in ipairs(FriendsInfo.applyList:GetList()) do
        table.insert(accs,friendInfo:GetId())
    end
    local re = lx.gs.friend.msg.CAcceptFriend({roleidlist = accs})
    network.send(re)
end

local function OnMsgSAcceptFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    for i, serverInfo in pairs(msg.friendlist) do
        FriendsInfo.friendList:Add(FriendInfo:new(serverInfo))
        --printyellow("serverInfo.roleinfo.roleid",serverInfo.roleinfo.roleid)
        local frdInfo = FriendsInfo.applyList:GetById(serverInfo.roleinfo.roleid)
        if frdInfo then
            FriendsInfo.applyList:RemoveById(serverInfo.roleinfo.roleid)
            if FriendsInfo.dlgList[serverInfo.roleinfo.roleid] then
                InfoManager.DelNormalInfo(FriendsInfo.dlgList[serverInfo.roleinfo.roleid])
                FriendsInfo.dlgList[serverInfo.roleinfo.roleid] = nil
            end            
        end
    end
    RefreshUI()


    GameEvent.evt_notify:trigger("friends_add", { })
end
------------------------------------------------------------------------------------------------------------------
--拒绝加好友
local function RejectFriend(roleId)
    local re = lx.gs.friend.msg.CRejectFriend({roleidlist = {roleId}})
    network.send(re)
end
local function RejectAllFriend()
    local rjts = {}
    for i,friendInfo in ipairs(FriendsInfo.applyList:GetList()) do
        table.insert(rjts,friendInfo:GetId())
    end
    local re = lx.gs.friend.msg.CRejectFriend({roleidlist = rjts})
    network.send(re)
end
local function OnMsgSRejectFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)

    for i, id in pairs(msg.roleidlist) do
        local frdInfo = FriendsInfo.applyList:GetById(id)
        if frdInfo then
            FriendsInfo.applyList:RemoveById(id)
            if FriendsInfo.dlgList[id] then
                InfoManager.DelNormalInfo(FriendsInfo.dlgList[id])
                FriendsInfo.dlgList[id] = nil
            end      
        end
    end
    RefreshUI()
end
------------------------------------------------------------------------------------------------------------------
--删除好友
local function SendDeleteFriend(roleId)
    local re = lx.gs.friend.msg.CDeleteFriend({roleid=roleId})
    network.send(re)
end

local function DeleteFriend(roleId)
    local frdInfo = FriendsInfo.friendList:GetById(roleId)
    if frdInfo ~= nil then
        local mmrelation = frdInfo:GetRelation()
        local MaimaiHelper = require("ui.maimai.base.maimaihelper")
        if mmrelation == nil then
            UIManager.ShowAlertDlg({immediate = true,content = string.format(LocalString.Friend_IsDelete,frdInfo:GetName()), callBackFunc = function()
                SendDeleteFriend(roleId)
            end})
        else
            if mmrelation ~= cfg.friend.MaimaiRelationshipType.BanLvNv and mmrelation ~= cfg.friend.MaimaiRelationshipType.BanLvNan then
                UIManager.ShowAlertDlg({immediate = true,content = string.format(LocalString.Friend_IsDeleteMaimai,frdInfo:GetName(),MaimaiHelper.GetRelationName(mmrelation)), callBackFunc =  function()
                    SendDeleteFriend(roleId)
                end})
            else
                UIManager.ShowAlertDlg({immediate = true,content = string.format(LocalString.Friend_Delete_Partner,frdInfo:GetName(),MaimaiHelper.GetRelationName(mmrelation)), callBackFunc =  function()
                    local MarriageManager = require("marriage.marriagemanager")
                    MarriageManager.OpenDivorceWithDiscussDlg(roleId, frdInfo:GetName())
                end})
            end
        end
    end
end

local function OnMsgSDeleteFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.friendList:RemoveById(msg.roleid)
    RefreshUI()
    GameEvent.evt_notify:trigger("friends_delete", {})
end

------------------------------------------------------------------------------------------------------------------
--搜索好友
local function SearchFriend(name)
    local re = lx.gs.friend.msg.CSearchFriend({searchkey=name})
    network.send(re)
end
local function OnMsgSSearchFriend(msg)
    printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.addList:Clear()
    for i, serverInfo in pairs(msg.friendlist) do
        local friendInfo = FriendInfo:new({roleinfo = serverInfo,charmdegree = 0,frienddegree = 0,relation = 0})
        FriendsInfo.addList:Add(friendInfo)
    end
    RefreshUI()
    
end
------------------------------------------------------------------------------------------------------------------
--加黑名单
local function SendBlackFriend(roleId)
    if timeutils.GetServerTime() - FriendsInfo.lastBlackTime <= 30 then
        UIManager.ShowSystemFlyText(LocalString.Friend_BlackTime)
        return
    end
    FriendsInfo.lastBlackTime = timeutils.GetServerTime()
    local re = lx.gs.friend.msg.CBlackFriend({roleidlist={roleId}})
    network.send(re)
end

local function BlackFriend(roleId)
    local frdInfo = FriendsInfo.friendList:GetById(roleId)
    if frdInfo ~= nil then
        local mmrelation = frdInfo:GetRelation()
        local MaimaiHelper = require("ui.maimai.base.maimaihelper")
        if mmrelation == nil then
            UIManager.ShowAlertDlg({immediate = true,content = LocalString.Freind_IsBlackFriend, callBackFunc = function()
                SendBlackFriend(roleId)
            end})
        else
            if mmrelation ~= cfg.friend.MaimaiRelationshipType.BanLvNv and mmrelation ~= cfg.friend.MaimaiRelationshipType.BanLvNan then
                UIManager.ShowAlertDlg({immediate = true,content = string.format(LocalString.Friend_IsBlackMaimai,frdInfo:GetName()), callBackFunc =  function()
                    SendBlackFriend(roleId)
                end})
            else
                UIManager.ShowAlertDlg({immediate = true,content = string.format(LocalString.Friend_Black_Partner,frdInfo:GetName(),MaimaiHelper.GetRelationName(mmrelation)), callBackFunc =  function()
                    local MarriageManager = require("marriage.marriagemanager")
                    MarriageManager.OpenDivorceWithDiscussDlg(roleId, frdInfo:GetName())
                end})
            end
        end
    else
        SendBlackFriend(roleId)
    end
end
local function OnMsgSBlackFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    for i, serverInfo in pairs(msg.okroleidlist) do
        local friendInfo = FriendInfo:new({roleinfo = serverInfo,charmdegree = 0,frienddegree = 0,relation = 0})
        FriendsInfo.blackList:Add(friendInfo)
        FriendsInfo.friendList:RemoveById(friendInfo:GetId())
    end
    RefreshUI()  
    GameEvent.evt_notify:trigger("friends_delete", {})
end
------------------------------------------------------------------------------------------------------------------
--取消黑名单
local function UnBlackFriend(roleId)
    local re = lx.gs.friend.msg.CUnBlackFriend({roleidlist={roleId}})
    network.send(re)
end
local function OnMsgSUnBlackFriend(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    for i, id in pairs(msg.okroleidlist) do
        FriendsInfo.blackList:RemoveById(id)     
    end
    RefreshUI()
end
------------------------------------------------------------------------------------------------------------------
--仇敌
local function OnMsgSAddEnemyNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    local enemyInfo = FriendsInfo.enemyList:GetById(msg.enemy.roleid)
    if enemyInfo then
        FriendsInfo.enemyList:RemoveById(msg.enemy.roleid)
    end
    local friendInfo = EnemyInfo:new({roleinfo = msg.enemy,charmdegree = 0,frienddegree = 0,relation = 0})
    FriendsInfo.enemyList:Add(friendInfo)
    RefreshUI()
end
local function DeleteEnemy(roleId)
    local re = lx.gs.friend.msg.CDeleteEnemy({roleidlist={roleId}})
    network.send(re)
end
local function OnMsgSDeleteEnemy(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    for i, id in pairs(msg.okroleidlist) do
        FriendsInfo.enemyList:RemoveById(id)
    end
    RefreshUI()
end
------------------------------------------------------------------------------------------------------------------
--别人的好友请求
local function OnMsgSRequestFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    if FriendsInfo.applyList:Contain(msg.friend.roleid) then
        FriendsInfo.applyList:Add(FriendInfo:new({roleinfo = msg.friend,charmdegree = 0,frienddegree = 0,relation = 0}))
    else 
        local friendInfo = FriendInfo:new({roleinfo = msg.friend,charmdegree = 0,frienddegree = 0,relation = 0})
        local alertDlgId = UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
                                                   content      = (msg.friend.rolename .. LocalString.Friend_RequestFriend1),
                                                   callBackFunc = function()
                                                        AcceptFriend(msg.friend.roleid)
                                                   end,
                                                   callBackFunc1 = function()
                                                        RejectFriend(msg.friend.roleid)
                                                   end,
                                                   sureText     = LocalString.Friend.Accept,
                                                   cancelText   = LocalString.Friend.Cancel })
        
        FriendsInfo.applyList:Add(friendInfo)
        local frdInfo = FriendsInfo.applyList:GetById(msg.friend.roleid)
        --frdInfo.m_AlertDlgId = friendInfo.m_AlertDlgId
        --frdInfo:SetAlertDlgId(alertDlgId)
        if FriendsInfo.dlgList[msg.friend.roleid] == nil then
            FriendsInfo.dlgList[msg.friend.roleid] = alertDlgId
        end
        
      --  printyellow("SQ friendInfo.m_AlertDlgId: ",frdInfo.m_AlertDlgId)
    end
    RefreshUI()
end
--别人接受了你的好友请求
local function OnMsgSAcceptFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.blackList:RemoveById(msg.friend.roleinfo.roleid)
    FriendsInfo.friendList:Add(FriendInfo:new(msg.friend))
    UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
                                    content     = msg.friend.roleinfo.rolename .. LocalString.Friend_AcceptFriend1, 
                                    buttonText  = LocalString.KnowText})

   -- UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
   --                         content      = (msg.friend.roleinfo.rolename .. LocalString.Friend_AcceptFriend1), 
   --                         callBackFunc = nil ,
   --                         sureText     = LocalString.Friend.Sure,
   --                         cancelText   = LocalString.Friend.Cancel })
    RefreshUI()
    GameEvent.evt_notify:trigger("friends_add", {})
end
--别人拒绝了你的好友请求
local function OnMsgSRejectFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    -- UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
    --                                 content     = msg.friend.rolename .. LocalString.Friend_Reject, 
    --                                 buttonText  = LocalString.KnowText})
    UIManager.ShowSystemFlyText(msg.friend.rolename .. LocalString.Friend_Reject)
  --  UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
  --                          content      = (msg.friend.rolename .. LocalString.Friend_Reject), 
  --                          callBackFunc = nil ,
  --                          sureText     = LocalString.Friend.Sure,
  --                          cancelText   = LocalString.Friend.Cancel })
end
--别人从好友中删除了你
local function OnMsgSDeleteFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.friendList:RemoveById(msg.friend.roleid)
   -- UIManager.ShowSystemFlyText(msg.friend.rolename .. LocalString.Friend_Delete)
    -- UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
    --                                 content     = msg.friend.rolename .. LocalString.Friend_Delete, 
    --                                 buttonText  = LocalString.KnowText})
  --  UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
  --                          content      = (msg.friend.rolename .. LocalString.Friend_Delete), 
  --                          callBackFunc = nil ,
  --                          sureText     = LocalString.Friend.Sure,
  --                          cancelText   = LocalString.Friend.Cancel })
    RefreshUI()
    GameEvent.evt_notify:trigger("friends_delete", {})
end
--别人将你加黑名单
local function OnMsgSBlackFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    FriendsInfo.friendList:RemoveById(msg.friend.roleid)

    -- UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
    --                                 content     = msg.friend.rolename .. LocalString.Friend_Block, 
    --                                 buttonText  = LocalString.KnowText})
    UIManager.ShowSystemFlyText(tostring(msg.friend.rolename .. LocalString.Friend_Block))
  --  UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
  --                          content      = (msg.friend.rolename .. LocalString.Friend_Block), 
  --                          callBackFunc = nil,
  --                          sureText     = LocalString.Friend.Sure,
  --                          cancelText   = LocalString.Friend.Cancel })

    RefreshUI()
    GameEvent.evt_notify:trigger("friends_delete", {})
end
--别人取消黑名单
local function OnMsgSUnBlackFriendNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)

    -- UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
    --                                 content     = msg.friend.rolename .. LocalString.Friend_UnBlock, 
    --                                 buttonText  = LocalString.KnowText})
    UIManager.ShowSystemFlyText(tostring(msg.friend.rolename .. LocalString.Friend_UnBlock))
--    UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
--                            content      = (msg.friend.rolename .. LocalString.Friend_UnBlock), 
--                            callBackFunc = nil ,
--                            sureText     = LocalString.Friend.Sure,
--                            cancelText   = LocalString.Friend.Cancel })
    RefreshUI()
end
------------------------------------------------------------------------------------------------------------------
--友好度变更
local function OnMsgSFriendDegreeNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg) 
    if msg.notifytype == cfg.item.FlowerType.NPC then
        local role = FriendsInfo.idolList:GetById(msg.roleid)
        if role ~= nil then
            role:SetFriendDegree(msg.frienddegree)
        end
        if role.m_GuardId == PlayerRole:Instance().m_Id then
            role.m_GuardDegree = msg.frienddegree
        end
        FriendsInfo.idolList:Sort()
    elseif msg.notifytype == cfg.item.FlowerType.PLAYER then
        local role = FriendsInfo.friendList:GetById(msg.roleid)
        if role ~= nil then
            role:SetFriendDegree(msg.frienddegree)
        end
        FriendsInfo.friendList:Sort()
    end
    RefreshUI()
end
--魅力值变更
local function OnMsgSRoleCharmNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    if msg.notifytype == cfg.item.FlowerType.NPC then
        local role = FriendsInfo.idolList:GetById(msg.roleid)
        if role ~= nil then
            role:SetCharm(msg.charm)
        end
        
        if UIManager.isshow("friend.tabfriend") then
        --    UIManager.refresh("friend.tabfriend")
        else
            FriendsInfo.idolList:Sort()
        end
    elseif msg.notifytype == cfg.item.FlowerType.PLAYER then
        local role = FriendsInfo.friendList:GetById(msg.roleid)
        if role ~= nil then
            role:SetCharm(msg.charm)
        end
        if UIManager.isshow("friend.tabfriend") then
        --    UIManager.refresh("friend.tabfriend")
        else
            FriendsInfo.friendList:Sort()
        end
    end
    --RefreshUI()
    
end
------------------------------------------------------------------------------------------------------------------
--送花
local function SendFlower(targetType,targetId,flowerlist)
    local fv = {}
    for i,k in ipairs(flowerlist) do
        if k.FlowerNum > 0 then
            table.insert(fv,{flowerid = k.FlowerId, flowernum = k.FlowerNum })
        end
    end
    if targetType == "Friend" then
        local re = lx.gs.friend.msg.CSendFlower({ sendtype = cfg.item.FlowerType.PLAYER, reveiverid=targetId, flowers=fv })
        network.send(re)
    elseif targetType == "Idol" then
        local re = lx.gs.friend.msg.CSendFlower({ sendtype = cfg.item.FlowerType.NPC, reveiverid=targetId, flowers=fv })
        network.send(re)
    end
end

local function OnMsgSSendFlower(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    if msg.sendtype == cfg.item.FlowerType.PLAYER then
    elseif msg.sendtype == cfg.item.FlowerType.NPC then
        FriendsInfo.idolList:Sort()
        local idolInfo = FriendsInfo.idolList:GetById(msg.reveiverid)
        if idolInfo then
            local charm = 0
            local frienddegree = 0
            for i, flower in pairs(msg.flowers) do
                local flwInfo = FlowerInfo:new(flower.flowerid)
                charm = charm + flwInfo:GetCharm() * flower.flowernum
                frienddegree = frienddegree + flwInfo:GetFriendDegree() * flower.flowernum
            end
            if charm > 0 then
                UIManager.ShowSystemFlyText(string.format( LocalString.Friend.SendFlowerCharm,idolInfo.m_Name,tostring(charm) ))
            end
            if frienddegree > 0 then
                UIManager.ShowSystemFlyText(string.format( LocalString.Friend.SendFlowerFriendDegree,idolInfo.m_Name,tostring(frienddegree)))
            end
        end
    end

end

local function OnMsgSSendFlowerNotify(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)

    local  noticeContent = "" .. msg.senderinfo.roleinfo.rolename .. LocalString.Friend.SendFlower01
    for i,flower in ipairs(msg.flowers) do
        if flower.flowernum > 0  then
            local itemflower = ItemManager.CreateItemBaseById( flower.flowerid,nil, flower.flowernum)
            noticeContent = noticeContent + string.format( LocalString.Friend.SendFlower02, itemflower:GetName(), flower.flowernum)
        end
    end
    UIManager.ShowSystemFlyText(noticeContent)
    -- UIManager.ShowSingleAlertDlg({  title       = LocalString.Friend.Tip, 
    --                                 content     = noticeContent, 
    --                                 buttonText  = LocalString.KnowText})

 --   UIManager.ShowAlertDlg({title        = LocalString.Friend.Tip, 
 --                           content      = noticeContent, 
 --                           callBackFunc = nil,
 --                           sureText     = LocalString.Friend.Sure,
--                            cancelText   = LocalString.Friend.Cancel })
    --RefreshUI()
end
------------------------------------------------------------------------------------------------------------------
--领取偶像奖励
local function ClaimIdolAward(idolId,rewardsId)
    local re = lx.gs.friend.msg.CClaimIdolAward({idolid=idolId, awardid=rewardsId})
    network.send(re)
end
local function OnMsgSClaimIdolAward(msg)
    --printyellowmodule(Local.LogModuals.Friend,msg)
    local idol = FriendsInfo.idolList:GetById(msg.idolid)
    if idol then
        idol:ReceivedRewards(msg.awardid)
    end
    RefreshUI()
    if UIManager.isshow("friend.dlgidolrewards") then
        UIManager.refresh("friend.dlgidolrewards")
    end
end
--=========================================================================================================================
--好友过多通知
local function CheckFriendCount()
    local num = FriendsInfo.friendList:GetCount()
    if num >= 90 then
        UIManager.ShowAlertDlg({immediate = true,
                                title        = LocalString.Friend.Tip, 
                                content      = noticeContent, 
                                callBackFunc = nil ,
                                sureText     = LocalString.Friend.Sure,
                                cancelText   = LocalString.Friend.Cancel })
        return true
    elseif num >= 100 then
        UIManager.ShowAlertDlg({immediate = true,
                                title        = LocalString.Friend.Tip, 
                                content      = noticeContent, 
                                callBackFunc = nil,
                                sureText     = LocalString.Friend.Sure,
                                cancelText   = LocalString.Friend.Cancel })
        return false
    end
end
--=========================================================================================================================
local function OnMsgSFriendOnlineNotify(msg)
    local frdInfo = FriendsInfo.friendList:GetById(msg.roleid)
    if frdInfo and msg.online then
        frdInfo:SetOnline(msg.online == 1)
        if msg.online == 1 then
            local relation = frdInfo:GetRelation()
            if relation ~= nil then
                --脉脉好友上线了
                GameEvent.evt_notify:trigger("maimaifriend_login",{ m_Id = msg.roleid, m_Relation = relation, m_Name = frdInfo:GetName() })
            end
        end
    end
    local enmInfo = FriendsInfo.enemyList:GetById(msg.roleid)
    if enmInfo and msg.online then
        enmInfo:SetOnline(msg.online == 1)
        if msg.online == 1 then
            local relation = enmInfo:GetRelation()
            if relation ~= nil then
                --脉脉好友上线了
                GameEvent.evt_notify:trigger("maimaifriend_login",{ m_Id = msg.roleid, m_Relation = relation, m_Name = enmInfo:GetName() })
            end
        end
    end
    RefreshUI()
end

local function OnMsgSIdolGuardNotify(msg)
    -- local PaoMaDengManager = require("paomadeng.paomadengmanager")

    local idolInfo = FriendsInfo.idolList:GetById(msg.idolid)
    if idolInfo then
        idolInfo:SetGuard(msg.guardid, msg.guardname, msg.guardtime/1000, msg.guarddegree)
    end
    if msg.guardid == PlayerRole:Instance().m_Id then
        RefreshUI()
        local timer = FrameTimer.New(function()
            UIManager.showdialog("friend.dlgguardian",{idolId =  msg.idolid})
        end, 5, 1)
        timer:Start()
        
    else
        RefreshUI()
    end
    GameEvent.evt_notify:trigger("idolguard_new",{ m_IdolId = msg.idolid, m_IdolName = idolInfo.m_Name, m_GuardName = msg.guardname, })
    
    -- PaoMaDengManager.Client_SPaomadengShow({
    --     operatetype = PaoMaDengManager.PMD_TYPE.IDOL_GUARDNEW,
    --     rolename = msg.guardname,
    --     idolname = idolInfo.m_Name,
    -- })

    

end

local function OnMsgSGuardLoginNotify(msg)
 --   printyellow("==============================================")
    -- local PaoMaDengManager = require("paomadeng.paomadengmanager")
    local idolInfo = FriendsInfo.idolList:GetById(msg.idolid)
    if msg.guardid == PlayerRole:Instance().m_Id then
        table.insert( FriendsInfo.showIdolIds, msg.idolid )
    else
        if idolInfo then
            GameEvent.evt_notify:trigger("idolguard_login",{ m_IdolId = msg.idolid, m_IdolName = idolInfo.m_Name, m_GuardName = msg.guardname, })

            -- PaoMaDengManager.Client_SPaomadengShow({
            --     operatetype = PaoMaDengManager.PMD_TYPE.IDOL_GUARDONLINE,
            --     rolename = msg.guardname,
            --     idolname = idolInfo.m_Name,
            -- })
        end
    end

    RefreshUI()

end

local function OnMsgChangeMapReady()
   -- printyellow("----------------------------------")
    if FriendsInfo.showIdolIds ~= nil and #FriendsInfo.showIdolIds > 0 then
        local idolInfo = nil
        for _,id in pairs(FriendsInfo.showIdolIds) do
            local curIdol = FriendsInfo.idolList:GetById(id)
            if curIdol then
                if idolInfo == nil then
                    idolInfo = curIdol
                else
                    if curIdol:GetFriendDegree() > idolInfo:GetFriendDegree() then
                        idolInfo = curIdol
                    end
                end
            end
        end
        if idolInfo ~= nil then
            if timeutils.GetServerTime() > FriendsInfo.lastShowTime + 300 then
                UIManager.showdialog("friend.dlgguardian",{idolId = idolInfo:GetId()})
                FriendsInfo.lastShowTime = timeutils.GetServerTime()
            end
            FriendsInfo.showIdolIds = {}
        end
    end
end
--=========================================================================================================================


local function GetSendFlowerInfo()
    local re = lx.gs.friend.msg.CGetSendFlowerInfo({})
    --local re = lx.gs.friend.msg.CSendFlower({})
    network.send(re)
end

local function OnMsgSGetSendFlowerInfo(msg)
    UIManager.show("friend.dlgfriendflowerinfo",{type = "Send", infos = msg.info})
end

local function GetReceiveFlowerInfo()
    local re = lx.gs.friend.msg.CGetReceiveFlowerInfo({})
    network.send(re)
end

local function OnMsgSGetReceiveFlowerInfo(msg)
    UIManager.show("friend.dlgfriendflowerinfo",{type = "Receive",infos = msg.info})
end

--=========================================================================================================================
local function CheckTrace(id)
    local re = lx.gs.map.msg.CCheckTrace({totracerole = id})
    network.send(re)
end

local function StartFollow(id)
    local teamManager = require("ui.team.teammanager")
    teamManager.SendGetPlayerLocation(id, 1)
   -- if UIManager.isshow("friend.tabfriend") then
        UIManager.hidecurrentdialog()
 --   end
end

local function OnMsgSCheckTrace(msg)
    printyellow(msg)
    
    local followCfg = ConfigManager.getConfig("followsetting")
    if followCfg then
        if msg.isindigong ~= 1 then
            UIManager.ShowSingleAlertDlg({
                immediate   = true,
                content     = followCfg.descriptioncannot,
            })
        else
            local remainTime = followCfg.followduration - (timeutils.GetServerTime() - msg.lasttracetime/1000)
            if remainTime > 0 and remainTime < followCfg.followduration then
                UIManager.ShowAlertDlg({
                    immediate       = true,
                    content         = string.format( followCfg.descriptioncontinue, tostring(math.floor(remainTime)) ) ,
                    callBackFunc    = function()
                        StartFollow(msg.totracerole, 1)
                    end,
                })
            else
                UIManager.ShowAlertDlg({
                    immediate       = true,
                    content         = string.format( followCfg.descriptioncan, tostring(followCfg.followduration) ,tostring(followCfg.followcost.amount) ) ,
                    callBackFunc    = function()
                        StartFollow(msg.totracerole, 1)
                    end,
                })
            end
        end
    end
end

--=========================================================================================================================
local function Start()
    if listenerId then
        network.remove_listeners(listenerId)
        listenerId = nil
    end
    listenerId = network.add_listeners( {
        --获取所有列表
        { "lx.gs.friend.msg.SGetFriendInfo",        OnMsgSGetFriendInfo        },
        { "lx.gs.friend.msg.SRequestFriend",        OnMsgSRequestFriend        },
        --接受、拒绝
        { "lx.gs.friend.msg.SAcceptFriend",         OnMsgSAcceptFriend         },
        { "lx.gs.friend.msg.SRejectFriend",         OnMsgSRejectFriend         },
        --删除
        { "lx.gs.friend.msg.SDeleteFriend",         OnMsgSDeleteFriend         },
        --关注、取消关注
        { "lx.gs.friend.msg.SFollowFriend",         OnMsgSFollowFriend         },
        { "lx.gs.friend.msg.SUnFollowFriend",       OnMsgSUnFollowFriend       },
        --搜索
        { "lx.gs.friend.msg.SSearchFriend",         OnMsgSSearchFriend         },
        --黑名单
        { "lx.gs.friend.msg.SBlackFriend",          OnMsgSBlackFriend          },
        { "lx.gs.friend.msg.SUnBlackFriend",        OnMsgSUnBlackFriend        },
        --仇敌相关
        { "lx.gs.friend.msg.SDeleteEnemy",          OnMsgSDeleteEnemy          },
        { "lx.gs.friend.msg.SAddEnemyNotify",       OnMsgSAddEnemyNotify       },

        --服务器通知
        { "lx.gs.friend.msg.SRequestFriendNotify",  OnMsgSRequestFriendNotify  },
        { "lx.gs.friend.msg.SAcceptFriendNotify",   OnMsgSAcceptFriendNotify   },
        { "lx.gs.friend.msg.SRejectFriendNotify",   OnMsgSRejectFriendNotify   },
        { "lx.gs.friend.msg.SDeleteFriendNotify",   OnMsgSDeleteFriendNotify   },
        { "lx.gs.friend.msg.SBlackFriendNotify",    OnMsgSBlackFriendNotify    },
        { "lx.gs.friend.msg.SUnBlackFriendNotify",  OnMsgSUnBlackFriendNotify  },
        --魅力值及友好度变化通知
        { "lx.gs.friend.msg.SFriendDegreeNotify",   OnMsgSFriendDegreeNotify   },
        { "lx.gs.friend.msg.SRoleCharmNotify",      OnMsgSRoleCharmNotify      },   
                
        --送花
        { "lx.gs.friend.msg.SSendFlower",           OnMsgSSendFlower           },
        { "lx.gs.friend.msg.SSendFlowerNotify",     OnMsgSSendFlowerNotify     },
        --奖励
        { "lx.gs.friend.msg.SClaimIdolAward",       OnMsgSClaimIdolAward       },

        { "lx.gs.friend.msg.SFriendOnlineNotify",   OnMsgSFriendOnlineNotify   },
        { "lx.gs.friend.msg.SIdolGuardNotify",      OnMsgSIdolGuardNotify      },
        { "lx.gs.friend.msg.SGuardLoginNotify",     OnMsgSGuardLoginNotify     },

        { "map.msg.SReady",                         OnMsgChangeMapReady        },

        { "lx.gs.friend.msg.SGetSendFlowerInfo",    OnMsgSGetSendFlowerInfo   },
        { "lx.gs.friend.msg.SGetReceiveFlowerInfo", OnMsgSGetReceiveFlowerInfo},

        { "lx.gs.map.msg.SCheckTrace",              OnMsgSCheckTrace          },
        --{ "" }

    } )


    GetFriendInfo()
end
--[[
    			<protocol name="SIdolGuardNotify" maxsize="1024" comment="通知偶像守护者变化">
				<variable name="idolid" type="int"/>
				<variable name="oldguardid" type="int"/>
				<variable name="guardid" type="int"/>
				<variable name="guardname" type="string"/>
            	<variable name="guardtime" type="long"/>
            </protocol>
			
			<protocol name="SFriendOnlineNotify" maxsize="1024" comment="通知好友状态变化">
				<variable name="roleid" type="long"/>
				<variable name="online" type="int"/>
            </protocol>
			
			<protocol name="SGuardLoginNotify" maxsize="1024" comment="偶像守护者上线通知">
				<variable name="idolid" type="int"/>
				<variable name="guardid" type="int"/>
				<variable name="guardname" type="string"/>
            </protocol>
			
]]


local function init()

end
--显示奖励红点
local function ShowRewardsRedDot()
    for i, idolInfo in pairs(FriendsInfo.idolList:GetList()) do
        if idolInfo:ShowRedDot() ==true then
            return true
        end
    end
    return false
end

--是否是好友
local function IsFriend(roleId)
    if roleId == PlayerRole.Instance().m_Id then
        return false
    end
    return FriendsInfo.friendList:Contain(roleId)
end

--是否在黑名单上
local function IsBlack(roleId)
    if roleId == PlayerRole.Instance().m_Id then
        return false
    end
    return FriendsInfo.blackList:Contain(roleId)
end
local function GetRole(type, id)
    local list = FriendsInfo[type]
    if list == nil then
        if Local.LogModuals.Friend == true then
            logError("好友表不存在："..type)
        end
        return nil
    end
    return list:GetById(id)
end

local function GetList(type)
	printyellow("GetList")
    local list = FriendsInfo[type]
    if list == nil then
        if Local.LogModuals.Friend == true then
            logError("好友表不存在："..type)
        end
        --printyellow("好友表不存在："..type)
        return nil
    end
    return FriendsInfo[type]
end
local function GetFriendById(id)
    return FriendsInfo.friendList:GetById(id)
end
local function GetIdolById(id)
    return FriendsInfo.idolList:GetById(id)
end
local function GetFriends()
    if FriendsInfo.friendList == nil then
        if Local.LogModuals.Friend == true then
            logError("好友表不存在："..type)
        end
        return nil
    end
    local list = {}
    for i, role in pairs(FriendsInfo.friendList:GetList()) do
        list[i] = role
    end
    return list
end
local function GetEnemys()
    if FriendsInfo.enemyList == nil then
        if Local.LogModuals.Friend == true then
            logError("好友表不存在："..type)
        end
        return nil
    end
    local list = {}
    for i, role in pairs(FriendsInfo.enemyList:GetList()) do
        list[i] = role
    end
    return list
end

local function GetEmptyText(index)
    local cfg = ConfigManager.getConfigData("friendhelpinfo", index)
    if cfg and cfg.content then
        return cfg.content
    end
    return ""
end

local function UnRead()
    local result = FriendsInfo.applyList:UnRead() or ShowRewardsRedDot()
    --printyellow("Friend Unread: ", result)
    return result
end


return {
    --初始化
    init                = init,
    Start               = Start,
    FRIEND_LIST_TYPE    = FRIEND_LIST_TYPE,
    FriendsInfo         = FriendsInfo,
    GetFriendInfo       = GetFriendInfo,

    RequestFriendById   = RequestFriendById,
    AcceptFriend        = AcceptFriend,
    AcceptAllFriend     = AcceptAllFriend,
    RejectFriend        = RejectFriend,
    RejectAllFriend     = RejectAllFriend,
    DeleteFriend        = DeleteFriend,
    SearchFriend        = SearchFriend,
    BlackFriend         = BlackFriend,
    UnBlackFriend       = UnBlackFriend,
    SendFlower          = SendFlower,
    ClaimIdolAward      = ClaimIdolAward,
    DeleteEnemy         = DeleteEnemy,
    CheckTrace          = CheckTrace,
    
    
    ShowRewardsRedDot   = ShowRewardsRedDot,
    
  --  DialogInit          = DialogInit,
    GetRole             = GetRole,
    GetList             = GetList,
    GetFriendById       = GetFriendById,
    GetIdolById         = GetIdolById,
    IsFriend            = IsFriend,
    IsBlack             = IsBlack,
    GetFriends          = GetFriends,
    GetEnemys           = GetEnemys,
    GetEmptyText        = GetEmptyText,
    UnRead              = UnRead,

    GetSendFlowerInfo   = GetSendFlowerInfo,
    GetReceiveFlowerInfo= GetReceiveFlowerInfo,
}
