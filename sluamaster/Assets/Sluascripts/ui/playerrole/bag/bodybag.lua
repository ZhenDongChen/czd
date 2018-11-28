-- 玩家身上的装备包、身上的装备伙伴包和身上的装备法宝包等，区别于普通包裹
-- 槽位不可堆叠
local Bag = require("ui.playerrole.bag.bag")
local BodyBag = Class:new(Bag)

function BodyBag:IsFull()
    if getn(self.m_Items) == self.m_nTotalSize then
        return true
    else
        return false
    end 
end

function BodyBag:Load()
end

function BodyBag:UnLoad()
end

return BodyBag 