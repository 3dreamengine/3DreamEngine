local job = { }
local lib = _3DreamEngine

job.cost = 3

function job:init()

end

function job:queue(times, operations)
	--shadows
	for d,s in ipairs(lib.lighting) do
		if s.shadow and s.active and s.shadow.typ == "point" then
			local pos = vec3(s.x, s.y, s.z)
			local dist = (pos - lib.lastUsedCam.pos):length() / 10.0 + 1.0
			
			if not s.shadow.static or not s.shadow.done[1] then
				local id = "shadow_point_" .. tostring(s.shadow)
				operations[#operations+1] = {"shadow_point", s.shadow.priority / dist, id, s, pos}
			end
		end
	end
end

function job:execute(times, delta, light, pos)
	local lookNormals = lib.lookNormals
	light.shadow.lastPos = pos
	
	local transformations = {
		lib:lookAt(pos, pos + lookNormals[1], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[2], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[3], vec3(0, 0, -1)),
		lib:lookAt(pos, pos + lookNormals[4], vec3(0, 0, 1)),
		lib:lookAt(pos, pos + lookNormals[5], vec3(0, -1, 0)),
		lib:lookAt(pos, pos + lookNormals[6], vec3(0, -1, 0)),
	}
	
	--create new canvases if necessary
	if not light.shadow.canvas then
		time = love.timer.getTime()
		light.shadow.canvas = lib:newShadowCanvas("point", light.shadow.res)
	end
	
	--render
	for face = 1, 6 do
		local shadowCam = lib:newCam(transformations[face], lib.cubeMapProjection, pos, lookNormals[face])
		local sceneSolid = lib:buildScene(shadowCam, "shadows", light.blacklist)
		lib:renderShadows(sceneSolid, shadowCam, {{light.shadow.canvas, face = face}})
	end
	
	light.shadow.done[1] = true
end

return job