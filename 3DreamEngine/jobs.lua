--[[
#part of the 3DreamEngine by Luke100000
jobs.lua - processes all kind of side tasks (shadows, blurring ambient lighting, rendering sky dome, ...)
--]]

local lib = _3DreamEngine

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

--load jobs
lib.jobs = { }
for d,s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/jobs")) do
	local name = s:sub(1, #s-4)
	lib.jobs[name] = require(lib.root .. "/jobs/" .. name)
end

local times
local operationsContinous
local operationsQueue

--resets job handler
function lib:initJobs()
	times = { }
	operationsContinous = { }
	operationsQueue = { }
	
	--init jobs
	for d,s in pairs(self.jobs) do
		if s.init then
			s:init()
		end
	end
end

--enqueues a new operation
function lib:addSingleOperation(...)
	operationsQueue[#operationsQueue+1] = {...}
end
function lib:addOperation(...)
	operationsContinous[#operationsContinous+1] = {...}
end

function lib:executeJobs()
	--queue jobs
	for d,s in pairs(self.jobs) do
		if s.queue then
			s:queue(times)
		end
	end
	
	--modules
	for d,_ in pairs(self.activeShaderModules) do
		local m = self:getShaderModule(d)
		if m.jobCreator then
			m:jobCreator(self)
		end
	end
	
	--execute continous operations
	for _,o in ipairs(operationsContinous) do
		self.delton:start(o[1])
		
		if type(o[1]) == "function" then
			o[1](unpack(o, 2))
		else
			self.jobs[o[1]]:execute(unpack(o, 2))
		end
		
		self.delton:stop()
	end
	operationsContinous = { }
	
	--execute operations
	local slots = self.job_slots
	while operationsQueue[1] do
		local o = operationsQueue[1]
		table.remove(operationsQueue, 1)
		self.delton:start(o[1])
		
		--execute
		local cost
		if type(o[1]) == "function" then
			cost = o[1](unpack(o, 2))
		else
			cost = self.jobs[o[1]]:execute(unpack(o, 2))
		end
		
		self.delton:stop()
		
		--limit processing time
		slots = slots - (cost or 1)
		if slots <= 0 then
			break
		end
	end
end