local job = { }

---@type Dream
local lib = _3DreamEngine
local vec3 = lib.vec3

function job:init()

end

function job:queue()
	--shadows
	for d, s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "point" then
			if not s.shadow.static or not s.shadow.done then
				lib:addOperation("pointShadow", s)
			end
		end
	end
end

--slightly modified lookAt to return the axis wise dot product for the position
--this allows re-usage of most of the matrix
local function lookAt(at, up)
	local zaxis = at:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	local c = lib.mat4({
		xaxis.x, xaxis.y, xaxis.z, 0,
		yaxis.x, yaxis.y, yaxis.z, 0,
		-zaxis.x, -zaxis.y, -zaxis.z, 0,
		0, 0, 0, 1
	})
	
	return c, -xaxis, -yaxis, zaxis
end

--view matrices
local transformations = {
	{ lookAt(lib.lookNormals[1], vec3(0, 1, 0)) },
	{ lookAt(lib.lookNormals[2], vec3(0, 1, 0)) },
	{ lookAt(lib.lookNormals[3], vec3(0, 0, 1)) },
	{ lookAt(lib.lookNormals[4], vec3(0, 0, -1)) },
	{ lookAt(lib.lookNormals[5], vec3(0, 1, 0)) },
	{ lookAt(lib.lookNormals[6], vec3(0, 1, 0)) },
}

function job:execute(light)
	--create new canvases if necessary
	if not light.shadow.canvas then
		light.shadow.canvas = love.graphics.newCanvas(light.shadow.resolution, light.shadow.resolution,
				{ format = "r16f",
				  readable = true,
				  msaa = 0,
				  type = "cube",
				  mipmaps = "none"
				})
		
		light.shadow.lastFace = 0
	end
	
	--rerender static
	if not light.shadow.lastPosition or (light.position - light.shadow.lastPosition):lengthSquared() > light.shadow.refreshStepSize then
		light.shadow.rendered = false
		light.shadow.lastPosition = light.position
	end
	
	light.shadow.lastFace = light.shadow.lastFace % 7 + 1
	
	--render
	for face = light.shadow.lazy and light.shadow.lastFace or 1, math.min(6, light.shadow.lazy and light.shadow.lastFace or 6) do
		local t = transformations[face]
		t[1][4] = t[2]:dot(light.position)
		t[1][8] = t[3]:dot(light.position)
		t[1][12] = t[4]:dot(light.position)
		
		local shadowCam = lib:newCamera(t[1], lib.cubeMapProjection, light.position, lib.lookNormals[face])
		
		--static shadow
		if not light.shadow.rendered or not light.shadow.static then
			local dynamic
			if light.shadow.static then
				dynamic = false
			end
			
			lib:render(shadowCam, { { light.shadow.canvas, face = face } }, dynamic, true, light.blacklist)
			light.shouldSmooth = light.shadow.smooth
		end
	end
	
	--prefilter
	if not light.shadow.lazy or light.shadow.lastFace == 7 then
		if light.shouldSmooth then
			lib:blurCubeMap(light.shadow.canvas, 1, light.size, { true, false, false, false }, true)
			light.shouldSmooth = false
		end
		
		light.shadow.rendered = true
	end
end

return job