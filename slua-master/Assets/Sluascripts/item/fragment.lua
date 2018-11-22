local ItemBase = require("item.itembase")
local ItemEnum = require("item.itemenum")
local ConfigManager = require("cfg.configmanager")

-- 碎片类
local Fragment = { }
setmetatable(Fragment, { __index = ItemBase })

 function Fragment:GetDetailTypeName()
    return LocalString.FragType
 end

-- 兑换物品的Id
function Fragment:GetCompoundItemId()
    return self.ConfigData.equipID or self.ConfigData.petID
end
-- 数量
function Fragment:GetConvertNumber()
    return self.ConfigData.number
end
-- 获取到期时间(值为0表示无时间限制)
function Fragment:GetExpireTime()
    return self.ExpireTime
end
-- 加载服务器数据
function Fragment:LoadFromServerMsg(serverMsg)
    self.ID          = serverMsg.fragmentid
    self.BagPos      = serverMsg.position or 0
    self.ExpireTime  = serverMsg.expiretime
    self.Isbound     = serverMsg.isbind == 1 and true or false
end
-- 实例化
function Fragment:CreateInstance(configId, config, detailType, detailType2, serverMsg, number)
    local fragment = 
    {
        ConfigId     = configId,
        BaseType     = ItemEnum.ItemBaseType.Fragment,
        DetailType   = detailType,
        DetailType2  = detailType2,
        ConfigData   = config,
        Number       = number or 1,
    }

    setmetatable(fragment, { __index = self })

    if serverMsg ~= nil then
        fragment:LoadFromServerMsg(serverMsg)
    end

    return fragment
end

return Fragment