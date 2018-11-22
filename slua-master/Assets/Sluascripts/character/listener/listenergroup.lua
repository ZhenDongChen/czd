

local ListenerGroup = Class:new()


function ListenerGroup:__new(character)
    self.m_Character = character

    self.m_AttrbuteListeners = {}
    self.m_CharacterInfoListeners = {}
    self.m_DeathInfoListeners = {}
    self.m_DestroyListeners = {}
    self.m_DeathOrDestroyListeners = {}
    self.m_EffectListeners = {}
end
--=================================================================================================
function ListenerGroup:AddAttributeListener(key, callback)
    if self.m_AttrbuteListeners[key] == nil then
        self.m_AttrbuteListeners[key] = {func = callback}
    else
        self.m_AttrbuteListeners[key] = {func = callback}
    end
    return key
end

function ListenerGroup:RemoveAttributeListener(key)
    if self.m_AttrbuteListeners[key] ~= nil then
        self.m_AttrbuteListeners[key] = nil
    else
        self.m_AttrbuteListeners[key] = nil
        --logError("移除监听函数错误：" .. key)
    end
end

function ListenerGroup:AddDeathOrDestroyListener(key, callback)
    if self.m_DeathOrDestroyListeners[key] == nil then
        self.m_DeathOrDestroyListeners[key] = {func = callback}
    else
        self.m_DeathOrDestroyListeners[key] = {func = callback}
        --logError("重复注册的监听函数："  .. key)
    end
    return key
end

function ListenerGroup:RemoveDeathOrDestroyListener(key)
    if self.m_DeathOrDestroyListeners[key] ~= nil then
        self.m_DeathOrDestroyListeners[key] = nil
    else
        self.m_DeathOrDestroyListeners[key] = nil
        --logError("移除监听函数错误：" .. key)
    end
end

function ListenerGroup:AddDestroyListener(key, callback)
    if self.m_DestroyListeners[key] == nil then
        self.m_DestroyListeners[key] = {func = callback}
    else
        self.m_DestroyListeners[key] = {func = callback}
        --logError("重复注册的监听函数：" .. key)
    end
    return key
end

function ListenerGroup:RemoveDestroyListener(key)
    if self.m_DestroyListeners[key] ~= nil then
        self.m_DestroyListeners[key] = nil
    else
        self.m_DestroyListeners[key] = nil
        --logError("移除监听函数错误：" .. key)
    end
end
function ListenerGroup:AddEffectListener(key, callback)
    if self.m_EffectListeners[key] == nil then
        self.m_EffectListeners[key] = {func = callback}
    else
        self.m_EffectListeners[key] = {func = callback}
        --logError("重复注册的监听函数：" .. key)
    end
    return key
end

function ListenerGroup:RemoveEffectListener(key)
    if self.m_EffectListeners[key] ~= nil then
        self.m_EffectListeners[key] = nil
    else
        self.m_EffectListeners[key] = nil
        --logError("移除监听函数错误：" .. key)
    end
end
--=================================================================================================

function ListenerGroup:OnAttributeChange()
    for key, listener in pairs(self.m_AttrbuteListeners) do
		assert(listener.func)
        listener.func(self.m_Character)
    end
end

function ListenerGroup:OnCharacterInfoChange()
    for key, listener in pairs(self.m_CharacterInfoListeners) do
        listener.func()
    end
end

function ListenerGroup:OnDeath()
    for key, listener in pairs(self.m_DeathInfoListeners) do
        listener.func()
    end

    for key, listener in pairs(self.m_DeathOrDestroyListeners) do
        listener.func()
    end
end

function ListenerGroup:OnDestroy()
    for key, listener in pairs(self.m_DestroyListeners) do
        listener.func()
    end

    for key, listener in pairs(self.m_DeathOrDestroyListeners) do
        listener.func()
    end
end

function ListenerGroup:OnEffectChange()
    for key, listener in pairs(self.m_EffectListeners) do
        listener.func()
    end
end

return ListenerGroup
