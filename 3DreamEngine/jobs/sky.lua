local job = { }
local lib = _3DreamEngine

function job:init()
	self.lastImage = false
end

function job:queue()
	--re render sky cube
	if lib.sky_reflection == true then
		--request rerender
		if type(lib.sky_texture) == "boolean" or self.lastImage ~= tostring(lib.sky_texture) then
			lib:addOperation("sky")
			lib:addOperation("cubemap", lib.sky_reflectionCanvas,  lib.reflections_levels)
		end
	end
end

local pos = vec3(0.0, 0.0, 0.0)
local lookNormals = lib.lookNormals
local transformations = {
	lib:lookAt(pos, lookNormals[1], vec3(0, -1, 0)),
	lib:lookAt(pos, lookNormals[2], vec3(0, -1, 0)),
	lib:lookAt(pos, lookNormals[3], vec3(0, 0, -1)),
	lib:lookAt(pos, lookNormals[4], vec3(0, 0, 1)),
	lib:lookAt(pos, lookNormals[5], vec3(0, -1, 0)),
	lib:lookAt(pos, lookNormals[6], vec3(0, -1, 0)),
}

local projections = { }
for side = 1, 6 do
	projections[side] = lib.cubeMapProjection * transformations[side]
end

function job:execute()
	self.lastImage = tostring(lib.sky_texture)
	
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setDepthMode()
	love.graphics.setBlendMode("replace", "premultiplied")

	for side = 1, 6 do
		love.graphics.setCanvas(lib.sky_reflectionCanvas, side)
		lib:renderSky(projections[side], transformations[side])
	end

	love.graphics.pop()
end

return job