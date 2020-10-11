local job = { }
local lib = _3DreamEngine

job.cost = 1

function job:init()

end

function job:queue(times)
	local t = love.timer.getTime()
	
	--re render sky cube
	if lib.sky_reflection == true then
		--request rerender
		lib:addOperation("sky", 1.0, false, lib.sky_frameSkip)
		
		--blur sky reflection cubemap
		for level = 2, lib.reflections_levels do
			local id = "cubemap_sky" .. level
			local time = times[id]
			if (times["sky"] or 0) > (time or 0) then
				lib:addOperation("cubemap", time and (1.0 / level) or 1.0, id, false, lib.sky_reflectionCanvas, level)
			end
		end
	end
end

function job:execute(times, delta, id)
	local lookNormals = lib.lookNormals
	if id then
		lib.cache["sky_tex"] = id
	end

	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setDepthMode()

	local pos = vec3(0.0, 0.0, 0.0)
	local transformations = {
		lib:lookAt(pos, lookNormals[1], vec3(0, -1, 0)),
		lib:lookAt(pos, lookNormals[2], vec3(0, -1, 0)),
		lib:lookAt(pos, lookNormals[3], vec3(0, 0, -1)),
		lib:lookAt(pos, lookNormals[4], vec3(0, 0, 1)),
		lib:lookAt(pos, lookNormals[5], vec3(0, -1, 0)),
		lib:lookAt(pos, lookNormals[6], vec3(0, -1, 0)),
	}

	for side = 1, 6 do
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(lib.sky_reflectionCanvas, side)
		love.graphics.clear(1.0, 1.0, 1.0)
		love.graphics.setDepthMode()
		
		lib:renderSky(lib.cubeMapProjection * transformations[side], transformations[side])
	end

	love.graphics.pop()
end

return job