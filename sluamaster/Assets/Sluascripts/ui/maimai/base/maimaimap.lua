


local MaimaiMap = Class:new()

function MaimaiMap:__new(info, serverInfo)
    self.m_MaimaiInfos  = {}
    self.m_Info         = info
    if serverInfo ~= nil then
        self:SetServerInfo(serverInfo)
    end 
end

function MaimaiMap:SetServerInfo(serverInfo)
    local MaimaiInfo    = require("ui.maimai.base.maimaiinfo")
    local RoleInfo      = require("ui.maimai.base.roleinfo")

    for key, value in pairs(serverInfo) do
        self.m_MaimaiInfos[key] = {}
        for i, roleShowInfo in pairs(value.mmlist) do
                   
            local mmInfo = MaimaiInfo:new(RoleInfo:new(roleShowInfo),nil)
            table.insert( self.m_MaimaiInfos[key], mmInfo )
        end
    end
end

function MaimaiMap:Exist(id)
    for key, value in pairs(self.m_MaimaiInfos) do
        for i, mmInfo in pairs(value) do
            if mmInfo.m_Role and mmInfo.m_Role:GetId() == id then
                return true
            end
        end
    end
    return false
end

function MaimaiMap:GetRelation(id)
    for key, value in pairs(self.m_MaimaiInfos) do
        for i, mmInfo in pairs(value) do
            if mmInfo:GetId() == id then
                return key
            end
        end
    end
    return nil
end

function MaimaiMap:GetIndex(id)
    for key, value in pairs(self.m_MaimaiInfos) do
        for i, mmInfo in pairs(value) do
            if mmInfo:GetId() == id then
                return i
            end
        end
    end
    return nil
end

function MaimaiMap:Get(relation,num)    
    if self.m_MaimaiInfos[relation] then
        if num == nil then
            return self.m_MaimaiInfos[relation][1]
        end
        return self.m_MaimaiInfos[relation][num]
    end
    return nil
end

function MaimaiMap:Add(relation,mmInfo)
    if self.m_MaimaiInfos[relation] == nil then
        self.m_MaimaiInfos[relation] = {}
    end
    for i, info in pairs(self.m_MaimaiInfos[relation]) do
        if info:GetId() == mmInfo:GetId() then
            self.m_MaimaiInfos[relation][i] = mmInfo
            return
        end
    end
    table.insert(self.m_MaimaiInfos[relation], mmInfo)
end

function MaimaiMap:Remove(relation, id)
    if id ~= nil then
        if self.m_MaimaiInfos[relation] ~= nil then
            local pos = nil
            for i, mmInfo in pairs(self.m_MaimaiInfos[relation]) do
                if mmInfo:GetId() == id then
                    pos = i
                    break
                end
            end
            if pos then
                table.remove( self.m_MaimaiInfos[relation], pos )
            end
        end
    else
        self.m_MaimaiInfos[relation] = {}
    end
end


function MaimaiMap:GetById(id)
    for key, value in pairs(self.m_MaimaiInfos) do
        for i, mmInfo in pairs(value) do
            if mmInfo:GetId() == id then
                return mmInfo
            end
        end
    end
    return nil
end


return MaimaiMap

