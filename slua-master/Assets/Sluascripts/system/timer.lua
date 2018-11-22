--------------------------------------------------------------------------------
--      Copyright (c) 2015 , 蒙占志(topameng) topameng@gmail.com
--      All rights reserved.
--
--      Use, modification and distribution are subject to the "New BSD License"
--      as listed at <url: http://www.opensource.org/licenses/bsd-license.php >.
--------------------------------------------------------------------------------

Timer = 
{
	time	 = 0,
	duration = 1,
	loop	 = 1,
	running	 = false,
	scale	 = false,
	func	 = nil,	
    eid      = 0,
}

local mt = {}
mt.__index = Timer

--scale false 采用deltaTime计时，true 采用 unscaledDeltaTime计时
function Timer.New(func, duration, loop, scale)
	local timer = {}
	scale = scale or true
	setmetatable(timer, mt)	
	timer:Reset(func, duration, loop, scale)
	return timer
end



function Timer:Reset(func, duration, loop, scale)
	self.duration 	= duration
	self.loop		= loop or 1
	self.scale		= scale
	self.func		= func
	self.time		= duration
	self.running	= false
	self.count		= Time.frameCount + 1
end

function Timer:Update()
	if not self.running then
		return
	end
	
	local delta = self.scale and Time.deltaTime or Time.unscaledDeltaTime	
	self.time = self.time - delta
	
	if self.time <= 0 and Time.frameCount > self.count then
		self.func()
		
		if self.loop > 0 then
			self.loop = self.loop - 1
			self.time = self.time + self.duration
		end
		
		if self.loop == 0 then
			self:Stop()
		elseif self.loop < 0 then
			self.time = self.time + self.duration
		end
	end
end

function Timer:Start()
	self.running = true
    local f = function()
      self:Update()
    end
    if self.eid == 0 then
        self.eid = gameevent.evt_update:add(f)
    else
        self.eid = gameevent.evt_update:addwitheid(f, self.eid)
    end
	--UpdateBeat:Add(self.Update, self)
end

function Timer:Stop()
	self.running = false
    gameevent.evt_update:remove(self.eid)
	--UpdateBeat:Remove(self.Update, self)
end

--给协同使用的帧计数timer
FrameTimer = 
{	
	count  		= 1,		
	duration	= 1,
	loop		= 1,
	func		= nil,	
	running	 	= false,
    eid         = 0,
}

local mt2 = {}
mt2.__index = FrameTimer

function FrameTimer.New(func, count, loop)
	print("FrameTimer.New")
	local timer = {}
	setmetatable(timer, mt2)	
	timer.count = Time.frameCount + count
	timer.duration = count
	timer.loop	= loop
	timer.func	= func
    timer.eid   = 0
	return timer
end



function FrameTimer:Update()	
	if not self.running then
		return
	end	
	print(Time.frameCount)
	if Time.frameCount >= self.count then
		self.func()	
		
		if self.loop > 0 then
			self.loop = self.loop - 1
		end
		
		if self.loop == 0 then
			self:Stop()
		else
			self.count = Time.frameCount + self.duration
		end
	end
end

function FrameTimer:Start()	
	self.running = true  
    local f = function()
        self:Update()
    end 
    self.eid = gameevent.evt_late_update:add(f) 
	--CoUpdateBeat:Add(self.Update, self)
end

function FrameTimer:Stop()	
	self.running = false
    gameevent.evt_late_update:remove(self.eid)
	--CoUpdateBeat:Remove(self.Update, self)
end

CoTimer = 
{
	time	 = 0,
	duration = 1,
	loop	 = 1,
	running	 = false,	
	func	 = nil,	
    eid      = 0,
}

local mt3 = {}
mt3.__index = CoTimer

function CoTimer.New(func, duration, loop)
	local timer = {}
	setmetatable(timer, mt3)	
	timer:Reset(func, duration, loop)
	return timer
end

function CoTimer:Start()
	self.running = true
	self.count = Time.frameCount + 1
    local f = function()
        self:Update()
    end 
    self.eid = gameevent.evt_late_update:add(f)
	--CoUpdateBeat:Add(self.Update, self)
end

function CoTimer:Reset(func, duration, loop)
	self.duration 	= duration
	self.loop		= loop or 1	
	self.func		= func
	self.time		= duration
	self.running	= false
	self.count		= Time.frameCount + 1
end

function CoTimer:Stop()
	self.running = false
    gameevent.evt_late_update:remove(self.eid)
	--CoUpdateBeat:Remove(self.Update, self)
end

function CoTimer:Update()
	if not self.running then
		return
	end		
	
	if self.time <= 0 and Time.frameCount > self.count then
		self.func()		
		
		if self.loop > 0 then
			self.loop = self.loop - 1
			self.time = self.time + self.duration
		end
		
		if self.loop == 0 then
			self:Stop()
		elseif self.loop < 0 then
			self.time = self.time + self.duration
		end
	end
	
	self.time = self.time - Time.deltaTime
end