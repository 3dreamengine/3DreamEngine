local job = { }
local lib = _3DreamEngine

job.cost = 5

function job:init()

end

function job:queue(times, operations)
	for reflection, task in pairs(lib.reflections_last) do
		--render reflections
		for face = 1, 6 do
			if not reflection.static or not reflection.done[face] then
				local id = "reflections_" .. (reflection.id + face)
				operations[#operations+1] = {"reflections", reflection.priority / (task.dist / 10 + 1), id, task.obj, task.pos, face}
			end
		end
		
		--blur mipmaps
		for level = 2, lib.reflections_levels do
			local id_blur = "cubemap_" .. (reflection.id + level)
			if (times[id] or 0) > (times[id_blur] or 0) then
				operations[#operations+1] = {"cubemap", times[id_blur] and (1.0 / level) or 1.0, id_blur, reflection.canvas, level}
				break
			end
		end
	end
end

function job:execute(times, obj, pos, face)
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
	local cam = lib:newCam(transformations[face], lib.cubeMapProjection, pos, lookNormals[face])
	local canvas = obj.reflection.canvas
	depth_buffer = depth_buffer or love.graphics.newCanvas(canvas:getWidth(), canvas:getHeight(), {format = "depth16", readable = false, msaa = canvas:getMSAA()})
	love.graphics.setCanvas({{canvas, face = face}, depthstencil = depth_buffer})
	love.graphics.clear()
	obj.reflection.canvas = nil
	
	--render
	lib:renderFull(cam, lib.canvases_reflections, false, {[obj] = true})
	
	obj.reflection.canvas = canvas
	love.graphics.pop()
	
	obj.reflection.done[face] = true
end

return job