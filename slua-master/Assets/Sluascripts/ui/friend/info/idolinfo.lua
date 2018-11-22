local ConfigManager = require("cfg.configmanager")
local ItemManager = require("item.itemmanager")
--偶像信息



local IdolInfo = Class:new()

function IdolInfo:__new(config,mode)
    self.m_Id   = config.id or 0
    self.m_Name = config.name or ""
    self.m_Sign = config.sign or ""
    self.m_Icon = config.icon or ""
    self.m_BonusList = {}
    
	self.m_FriendDegree = 0
	self.m_CharmNum = 0
    
    self:SetConfigInfo(config)
    
    self.m_GuardId = 0
    self.m_GuardName = ""
    self.m_GuardTime = 0
    self.m_GuardDegree = 0
    self.m_Time = 0
end
function IdolInfo:GetId()
    return self.m_Id
end

function IdolInfo:IsOnline()
    return true
end

function IdolInfo:GetCharm()
    return self.m_CharmNum
end


function IdolInfo:GetFriendDegree()
    return self.m_FriendDegree
end

function IdolInfo:SetCharm(value)
    self.m_CharmNum = value or 0
end

function IdolInfo:SetServerInfo(msginfo)
    self:SetCharm(msginfo.charm)
    self.m_GuardId = msginfo.guardid
    self.m_GuardName = msginfo.guardname
    self.m_GuardTime = msginfo.guardtime/1000
    self.m_GuardDegree = msginfo.guarddegree
end

function IdolInfo:SetGuard(guardid, guardname, guardtime, guarddegree)
    self.m_GuardId = guardid or self.m_GuardId
    self.m_GuardName = guardname or self.m_GuardName
    self.m_GuardTime = guardtime or self.m_GuardTime
    self.m_GuardDegree = guarddegree or self.m_GuardDegree
end


function IdolInfo:SetFriendDegree(value)
    self.m_FriendDegree = value or 0
end

function IdolInfo:SetAwardInfo(awardInfo)
    if awardInfo == nil then
        return
    end

    for id, k in pairs(awardInfo.claiminfo) do
        if self.m_BonusList[k] then
            self.m_BonusList[k].m_Received = true
        end
      --  if k == 1 then
      --      self.m_BonusList[id].m_Received = true
     --   else
     --       self.m_BonusList[id].m_Received = false
     --   end
    end
end

function IdolInfo:SetConfigInfo(config)
    for ki,bonus in ipairs(config.bonuslist) do
        local l_Bonus = {}
		l_Bonus.m_Received = false
        l_Bonus.m_FriendDgree = bonus.frienddegree
        l_Bonus.Items = {}
        l_Bonus.m_Introduction = bonus.introduction or ""
        for num,item in ipairs(bonus.bonus.items) do
            table.insert(l_Bonus.Items, num, ItemManager.CreateItemBaseById(item.itemid,{},item.amount))
        end
        table.insert(self.m_BonusList, #self.m_BonusList+1, l_Bonus)
    end
end

function IdolInfo:ShowRedDot()
    for i, bonus in pairs(self.m_BonusList) do
        if bonus.m_Received == false and self.m_FriendDegree >= bonus.m_FriendDgree then
            return true
        end
    end
    return false
end

function IdolInfo:ReceivedRewards(rewardsId)
    self.m_BonusList[rewardsId].m_Received = true
end
function IdolInfo:CanReceiveRewards(rewardsId)
    if self.m_FriendDegree > self.m_BonusList[rewardsId].m_FriendDgree then
        return true
    end
    return false
end

function IdolInfo:GetGuardDay()
    local currentTime = timeutils.GetServerTime()
    local deltaTime = currentTime - self.m_GuardTime
    local days = deltaTime / 3600 / 24
    local ceilDay = math.ceil(days) 
    if ceilDay < 1 then
        return 1
    end
    return ceilDay
end


function IdolInfo:GetSortValue()
    return self.m_Id
end

function IdolInfo:GetSortValueEx()
    return -1
end


function IdolInfo:IsFriend()
    return false
end

function IdolInfo:IsEnemy()
    return false
end

function IdolInfo:IsIdol()
    return true
end

return IdolInfo