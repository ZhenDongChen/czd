local Title = require("ui.title.info.titleinfo")

local TitleGroup = Class:new()

function TitleGroup:__new(num,name)
    self.m_GroupType  = num    --组类型
    self.m_GroupName  = name   --组名称
    self.m_ExistNew   = false
    self.m_List       = {}
end

function TitleGroup:GetNumber()
    return #(self.m_List)
end

function TitleGroup:GetNumberOfShow()
    local num = 0
    for i, title in pairs(self.m_List) do
        if title:IsShow() then
            num = num +1
        end
    end
    return num
end

function TitleGroup:GetAvailableNumber()
    local num = 0
    for i,k in pairs(self.m_List) do
        if k.m_IsActive == true then
            num = num + 1
        end
    end
    return num
end

function TitleGroup:Add(config)
    table.insert( self.m_List, Title:new(config.id, false ) )
end

function TitleGroup:GetTitle(index)
    return self.m_List[index]
end

--当前称号
function TitleGroup:GetCurrentTitle()
    for i = #self.m_List,1,-1 do
        if self.m_List[i].m_IsActive then
            return self.m_List[i]
        end
     end
    return nil
end

--下一个称号
function TitleGroup:GetNextTitle()
    for i = 1,#self.m_List do
        if not self.m_List[i].m_IsActive then
            return self.m_List[i]
        end
     end
    return nil
end

function TitleGroup:GetTitleList(index)
    return self.m_List
end

function TitleGroup:GetTitleById(id)
    for i,k in pairs(self.m_List) do
        if k.m_Id == id then
            return k
        end
    end
end

function TitleGroup:Check()
    for i,k in pairs(self.m_List) do
        k:Check()
    end
end

function TitleGroup:Sort()
    table.sort(self.m_List,function (a,b) return a.m_Id < b.m_Id end )
end

return TitleGroup