--[[
#part of the 3DreamEngine by Luke100000
jobs.lua - processes all kind of side tasks (shadows, blurring ambient lighting, rendering sky dome, ...)
--]]

local lib = _3DreamEngine

--load jobs
lib.jobs = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/jobs")) do
	local name = s:sub(1, #s-4)
	lib.jobs[name] = require(lib.root .. "/jobs/" .. name)
end


local executions, executionsTemp, lastExecutionSwap, optimalSlots, learningRate
function lib:initJobs()
	executions = { }
	executionsTemp = { }
	lastExecutionSwap = 0
	frames = 0
	optimalSlots = 10
	learningRate = 0.1
	
	--init jobs
	for d,s in pairs(self.jobs) do
		if s.init then
			s:init()
		end
	end
end

--cubemap projection
do
	local n = 0.01
	local f = 1000.0
	local fov = 90
	local scale = math.tan(fov/2*math.pi/180)
	local r = scale * n
	local l = -r
	
	lib.cubeMapProjection = mat4(
		2*n / (r-l),   0,              (r+l) / (r-l),     0,
		0,             -2*n / (r - l),  (r+l) / (r-l),     0,
		0,             0,              -(f+n) / (f-n),    -2*f*n / (f-n),
		0,             0,              -1,                0
	)
end

--view normals
lib.lookNormals = {
	vec3(1, 0, 0),
	vec3(-1, 0, 0),
	vec3(0, -1, 0),
	vec3(0, 1, 0),
	vec3(0, 0, 1),
	vec3(0, 0, -1),
}

function lib.executeJobs(self)
	local t = love.timer.getTime()
	local operations = { }
	
	--cache containing last update times
	self.cache.times = self.cache.times or { }
	local times = self.cache.times
	
	--queue jobs
	for d,s in pairs(self.jobs) do
		if s.queue then
			s:queue(times, operations)
		end
	end
	
	--modules
	for d,s in pairs(self.allActiveShaderModules) do
		if s.jobCreator then
			s:jobCreator(self, operations)
		end
	end
	
	--sort operations based on priority and time since last execution
	table.sort(operations, function(a, b) return a[2] * (t - (times[a[3] or a[1]] or 0)) > b[2] * (t - (times[b[3] or b[1]] or 0)) end)
	
	--swap debug buffer
	local i = math.floor(t)
	if i ~= lastExecutionSwap then
		lastExecutionSwap = i
		executions = executionsTemp
		executionsTemp = { }
	end
	
	--learn
	local totalCost = 0
	for _,o in ipairs(operations) do
		if type(o[1]) == "string" then
			local dat = self.jobs[o[1]]
			assert(dat, "job " .. tostring(o[1]) .. " does not exist")
			totalCost = totalCost + dat.cost / (dat.FPS or 1)
		end
	end
	optimalSlots = math.max(5, optimalSlots * (1.0 - learningRate) + totalCost * learningRate)
	
	--debug
	if _DEBUGMODE and love.keyboard.isDown("#") then
		--print approximate time requirement
		print()
		print(string.format("%d slots required, %d available, %d operations in queue", totalCost, math.floor(optimalSlots), #operations))
		
		--print execution per second
		print("executions per sec:")
		for d,s in pairs(executions) do
			print(string.format("\t%s: %d", d, s))
		end
		
		print("queue:")
		for d,s in ipairs(operations) do
			print(string.format("\t%s\tpriority: %.2f\tdelta: %.2f ms", s[1], s[2], (t - (times[s[3] or s[1]] or 0)) * 1000))
		end
		print()
		
		os.exit()
	end
	
	--execute operations
	local slots = optimalSlots
	while operations[1] do
		local o = operations[1]
		table.remove(operations, 1)
		
		--remember time stamp
		local delta = t - (times[o[3] or o[1]] or t)
		times[o[3] or o[1]] = t
		
		--execute
		local cost
		if type(o[1]) == "function" then
			cost = o[1](times, delta, unpack(o, 4))
		else
			cost = self.jobs[o[1]]:execute(times, delta, unpack(o, 4))
		end
		
		--count executions
		executionsTemp[o[1]] = (executionsTemp[o[1]] or 0) + 1
		
		--limit processing time
		slots = slots - (cost or type(o[1]) == "string" and self.jobs[o[1]].cost or 1)
		if slots <= 0 then
			break
		end
	end
end