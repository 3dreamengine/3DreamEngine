local job = { }
local lib = _3DreamEngine

job.cost = 3

function job:init()

end

function job:queue(times)
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "point" then
			local pos = vec3(s.x, s.y, s.z)
			local dist = (pos - lib.lastUsedCam.pos):length() / 10.0 + 1.0
			
			if s.shadow.static ~= true or not s.shadow.done[1] then
				local id = "shadow_point_" .. tostring(s.shadow)
				lib:addOperation("shadow_point", s.shadow.priority / dist, id, s.frameSkip, s, pos)
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

function job:execute(times, delta, light, pos)
	--create new canvases if necessary
	if not light.shadow.canvas then
		light.shadow.canvas = lib:newShadowCanvas("point", light.shadow.res, light.shadow.static == "dynamic")
	end
	
	--render
	for face = 1, 6 do
		local dynamic
		if light.shadow.static == "dynamic" then
			dynamic = light.shadow.done[1] or false
		end
		
		local t = transformations[face]
		t[1][4] = t[2]:dot(pos)
		t[1][8] = t[3]:dot(pos)
		t[1][12] = t[4]:dot(pos)
		
		local shadowCam = lib:newCam(t[1], lib.cubeMapProjection, pos, lib.lookNormals[face])
		lib:renderShadows(shadowCam, {{light.shadow.canvas, face = face}}, light.blacklist, dynamic)
	end
	
	light.shadow.done[1] = true
end

return job