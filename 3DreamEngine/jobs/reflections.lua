local job = { }
local lib = _3DreamEngine

function job:init()

end

function job:queue()
	for reflection, pos in pairs(lib.lastReflections) do
		if not reflection.static or not reflection.done then
			reflection.lastSide = reflection.lastSide or 0
			
			--render reflections
			if reflection.lastSide < 6 then
				lib:addOperation("reflections", reflection, pos)
			end
			
			--blur mipmaps
			if reflection.lastSide == 6 or not reflection.lazy then
				reflection.lastSide = 0
				if reflection.roughness then
					lib:addOperation("cubemap", reflection.canvas, reflection.levels or lib.reflectionsLevels)
				end
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

	local dynamics = nil
	if reflection.static then
		dynamics = false
	end
	
	--render
	reflection.lastSide = reflection.lastSide + 1
	for face = reflection.lazy and reflection.lastSide or 1, reflection.lazy and reflection.lastSide or 6 do
		local cam = lib:newCamera(transformations[face], lib.cubeMapProjection, pos, lookNormals[face])
		love.graphics.setCanvas({{canvas, face = face}, depth = true})
		love.graphics.clear()
		lib:renderFull(cam, lib.canvases_reflections, dynamics)
	end
	
	reflection.rendered = true
	reflection.canvas = canvas
	love.graphics.pop()
end

return job