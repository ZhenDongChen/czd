local require = require
local pairs = pairs
local print = print
local logError = logError

local Class = require "common.class"
local utils = require "common.utils"


local event = Class:new()

function event:__new(name)
	self.name = name or "__unknown__"
    self.next_id = 0
    self.id_listener_set_map = {}
    self.name_listener_set_map = {}
    self.id_status_map = {}
end

function event:add(target, func)
    local eid = self.next_id + 1
    self.next_id = eid
    local target_events = self.name_listener_set_map[target]
    if not target_events then
        target_events = {[eid] = func}
        self.name_listener_set_map[target] = target_events
    else
        target_events[eid] = func
    end 
    self.id_listener_set_map[eid] = target_events
    return eid
end


function event:addwitheid(target, func, eid)
    local target_events = self.name_listener_set_map[target]
    if not target_events then
        target_events = {[eid] = func}
        self.name_listener_set_map[target] = target_events
    else
        target_events[eid] = func
    end 
    self.id_listener_set_map[eid] = target_events
    return eid
end

function event:addstatuslistener(listener)
    self.id_status_map[listener.evtid] = listener
end

function event:remove(eid)
    local sets = self.id_listener_set_map[eid]
    if sets then 
        self.id_listener_set_map[eid] = nil
        sets[eid] = nil
    else
        logError("event.remove %s .can'find eid:%d" , self.name, eid)
    end
end

function event:trigger(target, data)
    local target_events = self.name_listener_set_map[target]
    if not target_events then     
		printyellow("[event:trigger]event no listeners:", target)
        return false;
    end
    for evtid, func in pairs(target_events) do
        if self.id_status_map[evtid] then 
            self.id_status_map[evtid]:BeginSample()
        end 
        utils.xpcall(func, data)
        if self.id_status_map[evtid] then 
            self.id_status_map[evtid]:EndSample()
        end 
    end    
	return true;
end

local global_event = event:new("__global")
-- 如果不指定事件名,则创建一个匿名事件
function event.new_simple(name)
    name = name or {}
    return {
        add = function (self, func)
            local evtid = global_event:add(name, func)
            return evtid
        end,
        addwitheid = function (self, func, eid)
            global_event:addwitheid(name, func, eid)
            return eid
        end,
        remove = function (self, eid)
            global_event:remove(eid)
        end,
        trigger = function (self, data)
            global_event:trigger(name, data)
        end,

        addstatuslistener = function (self, listener)
            return global_event:addstatuslistener(listener)
        end,

        getname = function(self)
            return name
        end 
    }
end

return event