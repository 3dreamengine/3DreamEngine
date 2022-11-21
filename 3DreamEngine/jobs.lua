--[[
#part of the 3DreamEngine by Luke100000
jobs.lua - processes all kind of side tasks (shadows, blurring ambient lighting, rendering sky dome, ...)
--]]

local lib = _3DreamEngine

--load jobs
lib.jobs = { }
for _, s in ipairs(love.filesystem.getDirectoryItems(lib.root .. "/jobs")) do
	local name = s:sub(1, #s - 4)
	lib.jobs[name] = require(lib.root .. "/jobs/" .. name)
end

local times
local operations

--resets job handler
function lib:initJobs()
	times = { }
	operations = { }
	
	--init jobs
	for _, s in pairs(self.jobs) do
		if s.init then
			s:init()
		end
	end
end

--enqueues a new operation
function lib:addOperation(...)
	table.insert(operations, { ... })
end

function lib:executeJobs()
	--queue jobs
	for _, s in pairs(self.jobs) do
		if s.queue then
			s:queue(times)
		end
	end
	
	--execute continuous operations
	for _, o in ipairs(operations) do
		self.delton:start(o[1])
		
		if type(o[1]) == "function" then
			o[1](unpack(o, 2))
		else
			self.jobs[o[1]]:execute(unpack(o, 2))
		end
		
		self.delton:stop()
	end
	operations = { }
end