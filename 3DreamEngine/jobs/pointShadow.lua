local job = { }
local lib = _3DreamEngine

function job:init()

end

function job:queue()
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "point" then
			if s.shadow.static ~= true or not s.shadow.done then
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
	local usesSmothing = light.shadow.smoothStatic or light.shadow.smoothDynamic
	
	--create new canvases if necessary
	if not light.shadow.canvas then
		light.shadow.canvas = love.graphics.newCanvas(light.shadow.resolution, light.shadow.resolution,
			{format = light.shadow.static and "r16f" or "rg16f",
			readable = true,
			msaa = 0,
			type = "cube",
			mipmaps = (usesSmothing) and "manual" or "none"})
	end
	
	local smoothStatic = false
	local smoothDynamic = false
	
	if not light.shadow.lastPos or (light.pos - light.shadow.lastPos):lengthSquared() > 0.0001 then
		light.shadow.rendered = false
		light.shadow.lastPos = light.pos
	end
	
	--render
	for face = 1, 6 do
		local t = transformations[face]
		t[1][4] = t[2]:dot(light.pos)
		t[1][8] = t[3]:dot(light.pos)
		t[1][12] = t[4]:dot(light.pos)
		
		local shadowCam = lib:newCam(t[1], lib.cubeMapProjection, light.pos, lib.lookNormals[face])
		
		if light.shadow.static then
			--static shadow
			if not light.shadow.rendered then
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, false, nil, usesSmothing)
				smoothStatic = light.shadow.smoothStatic
			end
		else
			if light.shadow.rendered then
				--dynamic part
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, true, nil, usesSmothing)
				smoothDynamic = light.shadow.smoothDynamic
			else
				--both parts
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, true, nil, usesSmothing)
				lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, false, nil, usesSmothing)
				smoothDynamic = light.shadow.smoothDynamic
				smoothStatic = light.shadow.smoothStatic
			end
		end
	end
	
	--prefilter
	if smoothDynamic or smoothStatic then
		lib:blurCubeMap(light.shadow.canvas, 4, light.size, {smoothStatic, smoothDynamic, false, false})
	end
	
	light.shadow.rendered = true
end

return job