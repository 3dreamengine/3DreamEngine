--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

function lib:renderGodrays(light, canvases, cam)
	local positions = { }
	local colors = { }
	local sizes = { }
	for d,s in ipairs(light.lights) do
		if s.godray then
			local pos
			if s.typ == "sun" then
				pos = cam.transformProjOrigin * vec4(s.direction.x, s.direction.y, s.direction.z, 1.0)
			else
				pos = cam.transformProj * vec4(s.position.x, s.position.y, s.position.z, 1.0)
			end
			pos = vec3(pos.x / pos.w * 0.5 + 0.5, pos.y / pos.w * 0.5 + 0.5, pos.z)
			
			if pos.z > 0 then
				local fade = math.min(1.0, (math.min(pos.x, pos.y, 1-pos.x, 1-pos.y) + s.godraySize) * 32.0)
				if fade > 0 then
					pos.z = s.typ == "sun" and 1000 or pos.z
					
					local length = fade * s.brightness * (s.typ == "sun" and 1.0 or 1.0 / (1.0 + pos.z)) * s.godrayLength
					table.insert(positions, pos)
					table.insert(colors, s.color)
					table.insert(sizes, {s.godraySize, length})
				end
			end
			
			if #colors == 8 then
				break
			end
		end
	end
	
	if #colors > 0 then
		local shader = lib:getBasicShader("godrays")
		love.graphics.setShader(shader)
		
		shader:send("density", 1.0)
		shader:send("decay", 1.25)
		shader:send("noiseStrength", 0.33)
		
		shader:send("noise", self.textures.godray)
		
		shader:send("sampleCount", self.godrays_quality)
		shader:send("scale", {1, canvases.height / canvases.width})
		
		shader:send("positions", unpack(positions))
		shader:send("colors", unpack(colors))
		shader:send("sizes", unpack(sizes))
		shader:send("sourceCount", #colors)
		
		love.graphics.setCanvas(canvases.color)
		love.graphics.setBlendMode("add", "premultiplied")
		love.graphics.draw(canvases.depth)
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader()
	end
end