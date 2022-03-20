local job = { }
local lib = _3DreamEngine

function job:init()

end

function job:queue()

end

function job:execute(cubemap, levels)
	lib:blurCubeMap(cubemap, levels)
end

return job