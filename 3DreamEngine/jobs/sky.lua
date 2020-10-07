local job = { }
local lib = _3DreamEngine

job.cost = 1

function job:init()

end

function job:queue(times, operations)
	local t = love.timer.getTime()
	
	--re render sky cube
	if lib.sky_as_reflection then
		local changes = false
		local tex = lib.sky_cube or lib.sky_hdri
		if tex then
			--HDRI texture
			if lib.sky_refreshRateTexture > 0 and t - (times["sky"] or 0) > lib.sky_refreshRateTexture or tostring(tex) ~= lib.cache["sky_tex"] then
				changes = true
			end
		else
			--sky dome
			if lib.sky_refreshRate > 0 and t - (times["sky"] or 0) > lib.sky_refreshRate or lib.sky_refreshRate == 0 and not times["sky"] then
				changes = true
			end
		end
		
		--request rerender
		if changes then
			operations[#operations+1] = {"sky", 1.0, false, tostring(tex)}
		end
		
		--blur sky reflection cubemap
		for level = 2, lib.reflections_levels do
			local id = "cubemap_sky" .. level
			local time = times[id]
			if (times["sky"] or 0) > (time or 0) then
				operations[#operations+1] = {"cubemap", time and (1.0 / level) or 1.0, id, lib.defaultReflection.canvas, level}
				break
			end
		end
	end
end

function job:execute(times, id)
	local lookNormals = lib.lookNormals
	if id then
		lib.cache["sky_tex"] = id
	end

	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setDepthMode()

	local pos = vec3(0.0, 0.0, 0.0)
	local transformations = {
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[1], vec3(0, -1, 0)),
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[2], vec3(0, -1, 0)),
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[3], vec3(0, 0, -1)),
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[4], vec3(0, 0, 1)),
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[5], vec3(0, -1, 0)),
		lib.cubeMapProjection * lib:lookAt(pos, lookNormals[6], vec3(0, -1, 0)),
	}

	for side = 1, 6 do
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(lib.defaultReflection.canvas, side)
		love.graphics.clear(1.0, 1.0, 1.0)
		love.graphics.setDepthMode()
		
		lib:renderSky(transformations[side])
	end

	love.graphics.pop()
end

return job