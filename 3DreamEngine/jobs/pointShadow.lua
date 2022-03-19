local job = { }
local lib = _3DreamEngine

function job:init()

end

function job:queue()
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "point" then
			if not s.shadow.static or not s.shadow.done then
				lib:addOperation("pointShadow", s)
			end
		end
	end
end

--slightly modified lookAt to return the axis wise dot product for the position
--this allows reusage of most of the matrix
local function lookAt(at, up)
	local zaxis = at:normalize()
	local xaxis = zaxis:cross(up):normalize()
	local yaxis = xaxis:cross(zaxis)
	
	return mat4(
		xaxis.x, xaxis.y, xaxis.z, 0,
		yaxis.x, yaxis.y, yaxis.z, 0,
		-zaxis.x, -zaxis.y, -zaxis.z, 0,
		0, 0, 0, 1
	), -xaxis, -yaxis, zaxis
end

--view matrices
local transformations = {
	{lookAt(lib.lookNormals[1], vec3(0, -1, 0))},
	{lookAt(lib.lookNormals[2], vec3(0, -1, 0))},
	{lookAt(lib.lookNormals[3], vec3(0, 0, -1))},
	{lookAt(lib.lookNormals[4], vec3(0, 0, 1))},
	{lookAt(lib.lookNormals[5], vec3(0, -1, 0))},
	{lookAt(lib.lookNormals[6], vec3(0, -1, 0))},
}

function job:execute(light)
	assert(not light.shadow.static or not light.shadow.dynamic, "Shadow can not be both static and dynamic")
	
	--create new canvases if necessary
	if not light.shadow.canvas then
		light.shadow.canvas = love.graphics.newCanvas(light.shadow.resolution, light.shadow.resolution,
			{format = light.shadow.dynamic and "rg16f" or "r16f",
			readable = true,
			msaa = 0,
			type = "cube",
			mipmaps = "none"
		})
		
		light.shadow.lastFace = 0
	end
	
	--rerender static
	if not light.shadow.lastPos or (light.pos - light.shadow.lastPos):lengthSquared() > light.shadow.refreshStepSize then
		light.shadow.rendered = false
		light.shadow.lastPos = light.pos
	end
	
	light.shadow.lastFace = light.shadow.lastFace % 7 + 1
	
	--render
	for face = light.shadow.lazy and light.shadow.lastFace or 1, math.min(6, light.shadow.lazy and light.shadow.lastFace or 6) do
		local t = transformations[face]
		t[1][4] = t[2]:dot(light.pos)
		t[1][8] = t[3]:dot(light.pos)
		t[1][12] = t[4]:dot(light.pos)
		
		local shadowCam = lib:newCamera(t[1], lib.cubeMapProjection, light.pos, lib.lookNormals[face])
		
		if light.shadow.dynamic then
			if light.shadow.rendered then
				--dynamic part
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, true, nil, false)
			else
				--both parts
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, false, nil, light.shadow.smooth)
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, true, nil, false)
				light.shouldSmooth = light.shadow.smooth
			end
		else
			--static shadow
			if not light.shadow.rendered or not light.shadow.static then
				local pass = nil
				if light.shadow.static  then
					pass = false
				end
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, pass, nil, light.shadow.smooth)
				light.shouldSmooth = light.shadow.smooth
			end
		end
	end
	
	--prefilter
	if not light.shadow.lazy or light.shadow.lastFace == 7 then
		if light.shouldSmooth then
			lib:blurCubeMap(light.shadow.canvas, 1, light.size, {true, false, false, false}, true)
			light.shouldSmooth = false
		end
		
		light.shadow.rendered = true
	end
end

return job