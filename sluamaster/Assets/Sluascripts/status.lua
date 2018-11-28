local allcpulisteners = {}

local function GetAllStatusListeners()
    return allcpulisteners
end

local function AddStatusListener(name,event,evtid)
    if Local.Status then
        printyellow("AddStatusListener",name,event.name,evtid)
        local listener = StatusListener(string.format("%s:%s",name,event:getname()),evtid)
        event:addstatuslistener(listener)
        table.insert(allcpulisteners,listener)
    end
end

local function second_update(now)
    for _,listener in pairs(allcpulisteners) do
        listener:SecondUpdate()
    end

end



local function init()
    if Local.Status then
        local listeners = StatusListener.RegistStatusListeners()
        for i=1,listeners.Length do
            table.insert(allcpulisteners,listeners[i])
        end
        gameevent.evt_second_update:add(second_update)
    end
end

local function CanSample()
    return Local.Status and StatusListener~=nil and StatusListener.CanSample()
end

local function BeginSample(name)
    if CanSample() then
        if StatusListener.name_hash_map[name] ==nil then
            StatusListener.StringToHash(name)
        end
        StatusListener.Profiler_BeginSample(StatusListener.name_hash_map[name])
    end
end

local function EndSample()
    if CanSample() then
        StatusListener.Profiler_EndSample()
    end
end

local function Cost(name,f,loop)
    local start = Time.realtimeSinceStartup
    for i = 1,loop do 
        f() 
    end 
    local cost = Time.realtimeSinceStartup - start
    printyellow(string.format("%s call %s times cost %.5f ms",name,loop,cost*1000))
end 

return {
    init = init,
    AddStatusListener = AddStatusListener,
    GetAllStatusListeners = GetAllStatusListeners,
    BeginSample = BeginSample,
    EndSample = EndSample,
    Cost = Cost,
}
