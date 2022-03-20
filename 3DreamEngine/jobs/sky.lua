local job = { }
local lib = _3DreamEngine

local lastSide = 0

function job:init()
	self.lastImage = false
end

function job:queue()
	--re-render sky cube
	if lib.defaultReflection == "sky" then
		--request rerender
		if type(lib.sky_texture) == "function" or self.lastImage ~= tostring(lib.sky_texture) then
			if lastSide < 6 then
				lib:addOperation("sky")
			end
			
			local lazy = lib.sky_lazy and type(lib.sky_texture) == "function"
			if lastSide == 6 or not lazy then
				lastSide = 0
				lib:addOperation("cubemap", lib.defaultReflectionCanvas,  lib.reflectionsLevels)
			end
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
	
	lastSide = lastSide + 1
	local lazy = lib.sky_lazy and type(lib.sky_texture) == "function"
	for side = lazy and lastSide or 1, lazy and lastSide or 6 do
		love.graphics.setCanvas(lib.defaultReflectionCanvas, side)
		lib:renderSky(projections[side], transformations[side])
	end

	love.graphics.pop()
end

return job