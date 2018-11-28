

local RoleList = Class:new()


function RoleList:__new(role, serverlist, mode)
    self.m_List = {}
    --self.m_SortFunc = nil
    --printyellow("RoleList")
    --printt(serverlist)
    --printyellow("==============",mode)
    
    if serverlist then
        for i,serverInfo in pairs(serverlist) do
            serverInfo = (((mode == "RoleShowInfo") and {roleinfo = serverInfo,charmdegree = 0,frienddegree = 0,relation = 0}) or serverInfo)
            self:Add(role:new(serverInfo),true)
        end
    end
    self.m_ExistNew = false
    self.m_SortFunc = nil 
    self:Sort()
end

function RoleList:GetList()
    return self.m_List
end

function RoleList:Clear()
    self.m_List = {}
end

function RoleList:IsShowRedDot()
    return self.m_ExistNew
end
function RoleList:SetRedDot(value)
    self.m_ExistNew = value or false
end

function RoleList:UnRead()
    if #self.m_List > 0 then
        return true
    end
    return false
end


function RoleList:GetById(id)
    for i,role in ipairs(self.m_List) do
        if role:GetId() == id then
            return role
        end    
    end
    return nil
end
function RoleList:GetByIndex(index)
    return self.m_List[index]
end

function RoleList:GetCount()
    return #self.m_List
end

function RoleList:Add(role,noresort)
    if self:Contain(role:GetId()) == true then
        self:RemoveById(role:GetId())
    end
    table.insert(self.m_List, role)
    if noresort == nil or noresort == false then
        self:Sort()
    end
    self.m_ExistNew = true
end

function RoleList:Contain(id)
    local pos = nil
    for i, role in ipairs(self.m_List) do
        if role:GetId() == id then
            pos = id
        end
    end   
    if pos then
        return true
    else
        return false
    end
end

function RoleList:RemoveById(id)
    --printyellow("RemoveById",id)
    local pos = nil
    for i, role in ipairs(self.m_List) do
        if role:GetId() == id then
            pos = i
        end
    end
    if pos then
        table.remove(self.m_List, pos)
    end
end

function RoleList:Sort()
    utils.table_sort(self.m_List, function(roleA, roleB)
        if roleA:IsEnemy() ~= true or roleB:IsEnemy() ~= true then
            if roleA:IsOnline() == true and roleB:IsOnline() == false then
                return true
            end
            if roleA:IsOnline() == false and roleB:IsOnline() == true then
                return false
            end
            if roleA:GetFriendDegree() > roleB:GetFriendDegree() then
                return true
            end
            if roleA:GetFriendDegree() <= roleB:GetFriendDegree() then
                return false
            end
            if roleA:GetCharm() > roleB:GetCharm() then
                return true
            end
            if roleA:GetCharm() <= roleB:GetCharm() then
                return false
            end
            if roleA:GetSortValue() < roleB:GetSortValue() then
                return true
            end
            return false
        else
            if roleA.m_Time > roleB.m_Time then
                return true
            end
            return false
        end
    end)
end


return RoleList