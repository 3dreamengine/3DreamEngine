local delton = { }

local clock = love.timer.getTime
local minArc = 0.01
local borderSize = 0.75

--temporary draw data
local scale
local mx
local my
local selected

local bigFont = love.graphics.newFont(24)

--return a new benchmark
function delton:new(bufferLength)
	local d = { }
	
	d.bufferLength = bufferLength or 60
	d.root = self:newSegment("root")
	d.current = d.root
	
	d.maxAge = 5
	
	return setmetatable(d, {__index = self})
end

--return a new segment
function delton:newSegment(name, parent)
	local r, g, b = math.random(), math.random(), math.random()
	return {
		parent = parent,
		name = name,
		children = { },
		
		time = 0.0,
		calls = 0,
		
		timeMedian = 0.0,
		callsMedian = 0.0,
		
		timeBuffer = { },
		callsBuffer = { },
		bufferIndex = 1,
		
		lastCall = clock(),
		
		color = {r / math.sqrt(r^2+g^2+b^2), g / math.sqrt(r^2+g^2+b^2), b / math.sqrt(r^2+g^2+b^2)}
	}
end

--draw a graph and textual data
function delton:present()
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setLineJoin("bevel")
	
	--center result to a 200x100 canvas
	local w, h = love.graphics.getDimensions()
	scale = math.min(w / 200, h / 100)
	love.graphics.translate((w - 200*scale)/2, (h - 100*scale)/2)
	love.graphics.scale(scale)
	love.graphics.translate(50, 50)
	
	--mouse
	mx, my = love.mouse.getPosition()
	mx = mx - (w - 200*scale)/2
	my = my - (h - 100*scale)/2
	mx = mx / scale
	my = my / scale
	mx = mx - 50
	my = my - 50
	selected = false
	
	--background
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", -50, -50, 200, 100, 5)
	love.graphics.setColor(1, 1, 1)
	
	--prepare data
	self:prepareData(self.root)
	
	--start rendering segment
	self:renderSegment(self.root, 0, 1, 0)
	
	--draw selected segment
	if selected then
		love.graphics.setFont(bigFont)
		love.graphics.setColor(selected.color)
		local t = string.format("%s\n%0.2f ms\n%0.1f%%\n%dx", selected.name, selected.timeMedian * 1000, selected.timeMedian / self.root.timeMedian * 100, selected.callsMedian)
		love.graphics.printf(t, -100, -10, 200 / (1 / scale), "center", 0, 1 / scale)
	end
	
	love.graphics.pop()
end

--render a single segment
local size = 1
function delton:renderSegment(segment, time, depth, height)
	--choose
	local children = { }
	for d,s in pairs(segment.children) do
		if clock() - s.lastCall < self.maxAge then
			children[#children+1] = s
		end
	end
	
	--text
	if depth == 1 then
		size = size * 0.99 + 0.01 * math.min(1, 40 / self.root.count)
	end
	local w = math.min(4, 50 / self.root.depth)
	if segment == self.root then
		local t = string.format("%s: %0.2f ms", segment.name, segment.timeMedian * 1000)
		love.graphics.print(t, 55, -45 + height * 16 / scale, 0, 1 / scale * size)
	else
		love.graphics.setColor(segment.color)
		local t = string.format("%s: %0.2f ms (%0.1f%%) %dx", segment.name, segment.timeMedian * 1000, segment.timeMedian / self.root.timeMedian * 100, segment.callsMedian)
		love.graphics.print(t, 55 + (depth - 1) * w, -45 + height * 16 / scale * size, 0, 1 / scale * size)
		
		--arc
		if segment.timeMedian / self.root.timeMedian * math.pi > minArc and 50 - depth * borderSize * 4 > borderSize then
			local a = time / self.root.timeMedian * math.pi * 2
			local b = (time + segment.timeMedian) / self.root.timeMedian * math.pi * 2
			local c = (a + b) / 2 - math.pi/2
			local r = 50 - depth * borderSize * 4
			
			--select
			local dist = math.sqrt(mx^2 + my^2)
			local angle = math.atan2(-mx, my) + math.pi
			if dist > r - borderSize*2 and dist < r + borderSize*2 and angle > a and angle < b then
				love.graphics.setLineWidth(4 * borderSize)
				selected = segment
			else
				love.graphics.setLineWidth(2.5 * borderSize)
			end
			
			love.graphics.arc("line", "open", 0, 0, r, a + minArc - math.pi/2, b - minArc - math.pi/2)
		end
	end
	
	--sort
	table.sort(children, function(a, b) return a.timeMedian > b.timeMedian end)
	
	--children
	for d,s in ipairs(children) do
		height = self:renderSegment(s, time, depth+1, height + 1)
		time = time + s.timeMedian
	end
	
	return height
end

--get the median of a buffer, or 0 if empty
function delton:getMedian(buffer)
	local c = { }
	for d,s in ipairs(buffer) do
		c[d] = s
	end
	table.sort(c, function(a, b) return a > b end)
	return c[math.ceil(#c/2)] or 0
end

--prepare median data for all changed entries
function delton:prepareData(segment, depth)
	if segment.changed or segment == self.root then
		if segment == self.root then
			self.root.count = 0
			self.root.depth = 0
		else
			self.root.count = self.root.count + 1
			self.root.depth = math.max(self.root.depth, depth or 0)
		end
		
		segment.changed = false
		segment.timeMedian = self:getMedian(segment.timeBuffer)
		segment.callsMedian = self:getMedian(segment.callsBuffer)
		
		--children
		for d,s in pairs(segment.children) do
			self:prepareData(s, (depth or 0) + 1)
		end
		
		--root special treatment
		if segment == self.root then
			--total time
			self.root.timeMedian = 0
			self.root.callsMedian = 1
			for d,s in pairs(self.root.children) do
				self.root.timeMedian = self.root.timeMedian + s.timeMedian
			end
		end
	end
end

--perform a step, add changes to buffer and reset counters
function delton:step(noClear, segment)
	assert(self.current == self.root, "more starts than stops! (" .. tostring(self.current.name) .. ")")
	
	if not segment then
		self:step(noClear, self.root)
	else
		--add to buffer
		segment.timeBuffer[segment.bufferIndex] = segment.time
		segment.callsBuffer[segment.bufferIndex] = segment.calls
		segment.bufferIndex = segment.bufferIndex % self.bufferLength + 1
		
		--reset
		if not noClear then
			segment.time = 0
			segment.calls = 0
		end
		
		--children
		for d,s in pairs(segment.children) do
			self:step(noClear, s)
		end
	end
end

--start a benchmark
function delton:start(name)
	--append a new child
	if not self.current.children[name] then
		self.current.children[name] = self:newSegment(name, self.current, 0)
	end
	
	--set it to the current segment
	self.current = self.current.children[name]
	
	--remember time
	self.current.start = clock()
end

--stop and return to parent
function delton:stop()
	--get delta
	self.current.time = self.current.time + (clock() - self.current.start)
	
	--increase counter
	self.current.calls = self.current.calls + 1
	
	--remember last call
	self.current.lastCall = clock()
	self.current.changed = true
	
	--return to parent
	self.current = self.current.parent
end

return delton