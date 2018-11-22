local ConfigManager = require("cfg.configmanager")


local RoleInfo = Class:new()


function RoleInfo:__new(roleInfo)
    self.m_Id           = roleInfo.roleid       or -1
    self.m_Name         = roleInfo.rolename     or ""
    self.m_Level        = roleInfo.level        or 1
    self.m_VipLevel     = roleInfo.viplevel     or 0 
    self.m_Profession   = roleInfo.profession   or 1 
    self.m_Gender       = roleInfo.gender       or cfg.role.GenderType.MALE
    self.m_Power        = roleInfo.attackpower  or 0
    self.m_Online       = (roleInfo.online and roleInfo.online == 1) and true or false
    self.m_Time         = roleInfo.time         or 0
    
end

function RoleInfo:GetId()
    return self.m_Id
end
function RoleInfo:GetName()
    return self.m_Name
end
function RoleInfo:GetVipLevel()
    return self.m_VipLevel
end

function RoleInfo:GetGender()
    return self.m_Gender
end
function RoleInfo:GetIcon()

    local professionData = ConfigManager.getConfigData("profession",self.m_Profession)
    local modelName = (self.m_Gender == cfg.role.GenderType.MALE) and professionData.modelname or professionData.modelname2
    local model = ConfigManager.getConfigData("model",modelName)
    return model.headicon or ""
end

function RoleInfo:CreateFromRole()
    local role = self:new({
        roleid      = PlayerRole:Instance().m_Id,
        rolename    = PlayerRole:Instance().m_Name,
        level       = PlayerRole:Instance().m_Level,
        viplevel    = PlayerRole:Instance().m_VipLevel,
        profession  = PlayerRole:Instance().m_Profession,
        gender      = PlayerRole:Instance().m_Gender,
        attackpower = PlayerRole:Instance().m_Power,
        online      = 1,
        time        = 0,
    })
    return role
end

function RoleInfo:CreateFromFriend()


end


return RoleInfo