local FriendInfo = require("ui.friend.info.friendinfo")


local EnemyInfo = Class:new(FriendInfo)

function EnemyInfo:__new(serverInfo)
    FriendInfo.__new(self, serverInfo)
    local showInfo = serverInfo.roleinfo
    self.m_KillTimes = showInfo.killtime or 0
    self.m_BeKillTimes = showInfo.bekilltime or 0
end

function EnemyInfo:GetSortValueEx()
    return self.m_Time
end

function EnemyInfo:GetSortValue()
    return -self.m_Time
end

function EnemyInfo:IsFriend()
    return false
end

function EnemyInfo:IsEnemy()
    return true
end

function EnemyInfo:IsIdol()
    return false
end


return EnemyInfo