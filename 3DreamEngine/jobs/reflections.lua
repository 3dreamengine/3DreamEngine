local job = { }
local lib = _3DreamEngine

function job:init()

end

function job:queue()
	for reflection, pos in pairs(lib.lastReflections) do
		if not reflection.static or not reflection.done then
			--render reflections
			lib:addOperation("reflections", reflection, pos)
			
			--blur mipmaps
			if reflection.roughness then
				lib:addOperation("cubemap", reflection.canvas, reflection.levels or lib.reflections_levels)
			end
		end
	end
end

function job:execute(reflection, pos)
	local lookNormals = lib.lookNormals
	local transformations = {
		lib:lookAt(pos, pos + lookNormals[1], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[2], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[3], vec3(0, 0, -1)),
		lib:lookAt(pos, pos + lookNormals[4], vec3(0, 0, 1)),
		lib:lookAt(pos, pos + lookNormals[5], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[6], vec3(0, -1, 0)),
	}
	
	--prepare
	love.graphics.push("all")
	love.graphics.reset()
	
	local canvas = reflection.canvas
	reflection.canvas = nil
	
	--render
	for face = 1, 6 do
		local cam = lib:newCam(transformations[face], lib.cubeMapProjection, pos, lookNormals[face])
		love.graphics.setCanvas({{canvas, face = face}, depth = true})
		love.graphics.clear()
		lib:renderFull(cam, lib.canvases_reflections)
	end
	
	reflection.rendered = true
	reflection.canvas = canvas
	love.graphics.pop()
end

return job