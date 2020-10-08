local job = { }
local lib = _3DreamEngine

job.cost = 2

function job:init()

end

function job:queue(times, operations)

end

function job:execute(times, delta, cubemap, level)
	lib:blurCubeMap(cubemap, level)
end

return job