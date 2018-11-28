local unpack, print = unpack, print

local UIManager 	= require("uimanager")
local MaimaiManager = require("ui.maimai.maimaimanager")
local MaimaiMenu    = require("ui.maimai.pages.menu")
local FriendManager = require("ui.friend.friendmanager")

local MaimaiHelper  = require("ui.maimai.base.maimaihelper")
local EventHelper 	= UIEventListenerHelper

local name, gameObject, fields 


--[[
    设置角色头像信息
]]
local function SetRoleInfo(uiItem, maimaiInfo, mmPosInfo, mode, mainRelationName)
    if uiItem == nil then
        return
    end

    local relation = mmPosInfo.m_Relation
    local num = mmPosInfo.m_Number
    local mmInfo

    for i, rel in pairs(mmPosInfo.m_Relations) do
        local tempMM = maimaiInfo:Get(rel,num)
        if tempMM ~= nil then
            relation = rel
            mmInfo = tempMM
        end
    end



    
    local isHideVip = false
    if mmInfo == nil then
        isHideVip = true
    end
    if mmInfo ~= nil and mode ~= "Other" and mmInfo:GetId() == PlayerRole:Instance().m_Id then
        isHideVip = true
    end
    if mode == "Other" and relation == -1 then
        isHideVip = true
    end
    if shouldHideVip() == true then
        isHideVip = true
    end
                        
    local relationName = (relation == -1) and mainRelationName or MaimaiHelper.GetRelationName(relation)
    uiItem:SetText("UILabel_Relation",relationName)
    -- if mmInfo == nill then return end 
    local addSprite = uiItem.Controls["UISprite_Add"]
    local vipSprite = uiItem.Controls["UISprite_VIP"]
    local texture = uiItem.Controls["UITexture_Head"]
    local clickMe = uiItem.Controls["UIGroup_ClikMe"]

    addSprite.gameObject:SetActive(mmInfo == nil)
    vipSprite.gameObject:SetActive(not isHideVip)
    
    uiItem:SetText("UILabel_VIP",(mmInfo ~= nil and mmInfo.m_Role:GetVipLevel() or ""))
    uiItem:SetText("UILabel_Name",(mmInfo ~= nil and mmInfo.m_Role:GetName() or ""))
    texture:SetIconTexture((mmInfo ~= nil and mmInfo.m_Role:GetIcon() or ""))

    if mmInfo ~= nil then
        EventHelper.SetClick(uiItem,function()
            MaimaiMenu.show(uiItem.gameObject.transform.position, mmInfo, relation, mode,uiItem.Index)
        end)
        --printyellow("mmInfo")
        if clickMe then
            clickMe.gameObject:SetActive(false)
        end
    else
        if mode == "Player" then
            EventHelper.SetClick(uiItem,function()
                --show(position, maimaiInfo,relation)
                if relation ~= cfg.friend.MaimaiRelationshipType.SuDi then
                    MaimaiMenu.hide()
                    UIManager.show("maimai.dlgmaimaicheckfriend",{ listName = "Friend", relationships = mmPosInfo.m_Relations })
                else
                    MaimaiMenu.hide()
                    UIManager.show("maimai.dlgmaimaicheckfriend",{ listName = "Enemy", enemyList = true, relationships = mmPosInfo.m_Relations })
                end
            end)
            if clickMe then
                clickMe.gameObject:SetActive(true)
            end
        else
            if clickMe then
                clickMe.gameObject:SetActive(false)
            end
        end
         
    end
end



--[[
    获取相关格子信息
]]
local MaimaiPosInfo = Class:new()

function MaimaiPosInfo:__new(params)
    self.m_Relations = params.relations
    self.m_Relation = params.relations[1]
    self.m_Number = params.number
end
function MaimaiPosInfo:ContainRelation(relation)
    for _, rel in pairs(self.m_Relations) do
        if rel == relation then
            return true
        end
    end
    return false
end




local function GetMaimaiPosInfo(gender, mode, maimaiInfo)
    local LoversType
    local MmRelation = cfg.friend.MaimaiRelationshipType
    if gender == 1 then
        LoversType = MmRelation.BanLvNan
    else
        LoversType = MmRelation.BanLvNv
    end
    local mapPosInfo = {
        [cfg.role.GenderType.MALE]  = { 
            [1]   = MaimaiPosInfo:new({relations={-1},                  number =1}),
            [2]   = MaimaiPosInfo:new({relations={LoversType},  number =1}),
            [3]   = MaimaiPosInfo:new({relations={MmRelation.YiXiong},  number =1}),
            [4]   = MaimaiPosInfo:new({relations={MmRelation.YiJie},    number =1}),
            [5]   = MaimaiPosInfo:new({relations={MmRelation.YiDi},     number =1}),
            [6]   = MaimaiPosInfo:new({relations={MmRelation.YiMei},    number =1}),
            [7]   = MaimaiPosInfo:new({relations={MmRelation.HongYan},  number =1}),
            [8]   = MaimaiPosInfo:new({relations={MmRelation.XiongDi},  number =1}),
            [9]   = MaimaiPosInfo:new({relations={MmRelation.XiongDi},  number =2}),
            [10]  = MaimaiPosInfo:new({relations={MmRelation.XiongDi},  number =3}), 
            [11]  = MaimaiPosInfo:new({relations={MmRelation.SuDi},     number =1}),
        },
        [cfg.role.GenderType.FEMALE] = {
            [1]  = MaimaiPosInfo:new({relations={-1},                   number =1}),
            [2]  = MaimaiPosInfo:new({relations={LoversType},  number =1}),
            [3]  = MaimaiPosInfo:new({relations={MmRelation.YiXiong},   number =1}),
            [4]  = MaimaiPosInfo:new({relations={MmRelation.YiJie},     number =1}),
            [5]  = MaimaiPosInfo:new({relations={MmRelation.YiDi},      number =1}),
            [6]  = MaimaiPosInfo:new({relations={MmRelation.YiMei},     number =1}),
            [7]  = MaimaiPosInfo:new({relations={MmRelation.LanYan},    number =1}),
            [8]  = MaimaiPosInfo:new({relations={MmRelation.GuiMi},     number =1}),
            [9]  = MaimaiPosInfo:new({relations={MmRelation.GuiMi},     number =2}),
            [10] = MaimaiPosInfo:new({relations={MmRelation.GuiMi},     number =3}),
            [11] = MaimaiPosInfo:new({relations={MmRelation.SuDi},      number =1}),       
        },
    }    
 
    if mode == "Player" then
        local mapPosInfo_Gender = mapPosInfo[gender]
        return mapPosInfo_Gender
    end
    if mode == "Friend" then
        local posInfo = mapPosInfo[gender]
        local relation = maimaiInfo:GetRelation(PlayerRole:Instance().m_Id)
        local index = maimaiInfo:GetIndex(PlayerRole:Instance().m_Id)
        --local realtion2 = MaimaiHelper.GetCorrespondingRelation(relation, PlayerRole:Instance().m_Gender)

        for i, pInfo in pairs(posInfo) do
            if pInfo:ContainRelation(relation) and pInfo.m_Number == index then
                posInfo[2], posInfo[i] = posInfo[i], posInfo[2]
                break
            end
        end
        
        return posInfo
    end
    if mode == "Other" then
        local lastmmInfo = MaimaiManager.GetLastMaimaiInfo()
        local posInfo = mapPosInfo[gender]
        if lastmmInfo then
            local relation = maimaiInfo:GetRelation(lastmmInfo:GetId())
            local index = maimaiInfo:GetIndex(lastmmInfo:GetId())
            if relation then
                for i, pInfo in pairs(posInfo) do
                    if pInfo:ContainRelation(relation) and pInfo.m_Number == index then
                        posInfo[2], posInfo[i] = posInfo[i], posInfo[2]
                        break
                    end
                end
            end
        end
        return posInfo
    end
end
--[[
    设置查看规则
]]

local function ResetAllowToggle(info)

    fields.UIToggle_FriendCheck.value = info.allowFriend
    fields.UIToggle_StrangerCheck.value = info.allowStrange
end

--[[
    设置显示组别：玩家、好友、其他
]]
local function SetGroup(maimaiInfo)
    local isPlayer = maimaiInfo:IsPlayer()
    local isFriend = maimaiInfo:IsFriend()
    local isOther = not (isPlayer or isFriend)    
    local mode = (isPlayer and "Player" or (isFriend and "Friend" or  "Other"))
    local uiList = (isPlayer and fields.UIList_PlayerMaimaiMap or (isFriend and fields.UIList_FriendMaimaiMap or fields.UIList_OtherMaimaiMap))
    fields.UIGroup_Self.gameObject:SetActive(isPlayer)
    fields.UIGroup_Friend.gameObject:SetActive(isFriend)
    fields.UIGroup_Other.gameObject:SetActive(isOther)
    return mode, uiList
end

--===================================================================================================================================================

local function refresh(params)
    local maimaiInfo

    if params == nil or params.maimaiInfo == nil then
        maimaiInfo = MaimaiManager.GetMaimaiInfo()
    else
        maimaiInfo = params.maimaiInfo
    end
    if maimaiInfo == nil then
        UIManager.hide(name)
        return
    end
   -- local maimaiInfo = () and MaimaiManager.GetMaimaiInfo() or params.maimaiInfo

    MaimaiManager.SetCurrentMaimaiInfo(maimaiInfo)
    --设置查看权限
    local friendallow, strangeallow = MaimaiManager.GetMMAuthorization()
    ResetAllowToggle({allowFriend = friendallow, allowStrange = strangeallow})
    --设置显示组别：玩家、好友、其他
    local mode, uiList = SetGroup(maimaiInfo)
    --获取每个位置显示的信息
    local mapPosInfos = GetMaimaiPosInfo(maimaiInfo.m_Role.m_Gender, mode, maimaiInfo)
    for i = 1, #mapPosInfos do
        local uiItem = uiList:GetItemByIndex(i-1)

        local mainRelationName
        if mode == "Player" then
            mainRelationName = ""
        elseif mode == "Friend" then
            local relationTmp = maimaiInfo:GetRelation(PlayerRole:Instance().m_Id)
            local relationTmp2 = MaimaiHelper.GetCorrespondingRelation(relationTmp, maimaiInfo.m_Role.m_Gender) 
            
            mainRelationName = MaimaiHelper.GetRelationName(relationTmp2)
        end
        SetRoleInfo(uiItem, maimaiInfo, mapPosInfos[i], mode, mainRelationName)
    end
    if mode == "Other" then
        fields.UITexture_MainHead:SetIconTexture(PlayerRole:Instance():GetHeadIcon())
    end
end

local function show(params)

   -- local maimaiInfo = (params == nil or params.maimaiInfo == nil) and MaimaiManager.GetMaimaiInfo() or params.maimaiInfo
    MaimaiMenu.hide()
    FriendManager.GetFriendInfo()
    
end

local function hide()
    fields.UIGroup_Menu.gameObject:SetActive(false)
    MaimaiMenu.hide()
end

local function update()

end

local function init(params)
   	name, gameObject, fields = unpack(params)
    MaimaiMenu.init(name, gameObject, fields)
    EventHelper.SetClick(fields.UIToggle_FriendCheck, function()
        MaimaiManager.SetMMAuthorization(fields.UIToggle_FriendCheck.value,fields.UIToggle_StrangerCheck.value)
    end)
    EventHelper.SetClick(fields.UIToggle_StrangerCheck, function()
        MaimaiManager.SetMMAuthorization(fields.UIToggle_FriendCheck.value,fields.UIToggle_StrangerCheck.value)
    end)
end
local function destroy()

end


return {
  init              = init,
  show              = show,
  hide              = hide,
  update            = update,
  destroy           = destroy,
  refresh           = refresh,
  ResetAllowToggle  = ResetAllowToggle,
}

