local ObjectPool = require"common.objectpool"

local HeadTalkingEntity = Class:new()

function HeadTalkingEntity:__new()
    self.m_PosStart = Vector3.zero
    self.m_Timeup = 0
end

function HeadTalkingEntity:BuidUIListItem(headTalkingItem)
    self.m_HeadTalkingItem = headTalkingItem
    if headTalkingItem then
        self.m_Label = headTalkingItem.Controls["UILabel_Content"]
        self.m_ItemTransform = headTalkingItem.gameObject.transform
        -- printyellow("item name?",self.m_ItemTransform.gameObject.name)
    end
end

function HeadTalkingEntity:Init(content,target,time)
    if self.m_Label and content then
        self.m_Label.text = content
        -- printyellow("content",content)
    end
    self.m_Target = target
    self.m_Timeup = Time.time + time
    self.m_Label.gameObject.transform.localScale = Vector3.one
    -- printyellow("self.m_ItemTransform.name",self.m_ItemTransform.gameObject.name)
end

function HeadTalkingEntity:Remove()
    if self.m_Label then
        self.m_Label.gameObject.transform.localScale = Vector3.zero
    end
end

function HeadTalkingEntity:Release()
    if self.m_HeadTalkingItem then
        self.m_HeadTalkingItem.Parent:DelListItem(self.m_HeadTalkingItem)
    end
end

function HeadTalkingEntity:Update()
    -- if IsNull(UICamera.currentCamera) then return end
    if self.m_Target and self.m_Target.m_Object then
        local targetPos = self.m_Target:GetPos()
        targetPos.y = targetPos.y + self.m_Target.m_Height * 1.25
        local uiPos = LuaHelper.WorldToUI(targetPos)
        uiPos.z = 0
        self.m_ItemTransform.position = uiPos
    end
end

function HeadTalkingEntity:TimesUp()
    return Time.time > self.m_Timeup
end


-----------------------------------------------------------------------------
-- manager
-----------------------------------------------------------------------------


local HeadTalkingManager = Class:new()

function HeadTalkingManager:__new(uilist)
    self.m_UIList = uilist
    self.m_HeadTalkingList = {}
    self:Init()
end

function HeadTalkingManager:Init()
    self.m_HeadTalkingPool = ObjectPool:new(HeadTalkingEntity,5)
end

function HeadTalkingManager:Add(content,target,time)
    -- printyellow("self.m_HeadTalkingPool",self.m_HeadTalkingPool)
    local entity = self.m_HeadTalkingPool:GetObject()
    if not entity.m_HeadTalkingItem then
        local item = self.m_UIList:AddListItem()
        entity:BuidUIListItem(item)
    end
    self:InitHeadTalking(entity,content,target,time)
    table.insert(self.m_HeadTalkingList,entity)
end

function HeadTalkingManager:InitHeadTalking(entity,content,target,time)
    entity:Init(content,target,time)
    if target then
        local initPosition = cloneVector3(target:GetPos())
        initPosition.y = initPosition.y + target.m_Height * 1.25
        local initUIPosition = LuaHelper.WorldToUI(initPosition)
        initUIPosition.z = 0
        entity.m_ItemTransform.position = initUIPosition
    end
end

function HeadTalkingManager:Update()
    for i = #self.m_HeadTalkingList,1,-1 do
        local entity = self.m_HeadTalkingList[i]
        if entity:TimesUp() then
            table.remove(self.m_HeadTalkingList,i)
            entity:Remove()
            if not self.m_HeadTalkingPool:PushObject(entity) then
                entity:Release()
            end
        else
            entity:Update()
        end
    end
end

return HeadTalkingManager
