--[[
#part of the 3DreamEngine by Luke100000
--]]

local lib = _3DreamEngine

function lib:renderSky(transformProj, camTransform, transformScale)
	if transformScale then
		transformProj = transformProj * mat4:getScale(transformScale)
	end
	
	love.graphics.push("all")
	if type(self.sky_texture) == "table" then
		love.graphics.clear(self.sky_texture, {255, 255, 255})
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "cube" then
		--cubemap
		local shader = self:getBasicShader("sky_cube")
		love.graphics.setShader(shader)
		shader:send("transformProj", transformProj)
		shader:send("sky", self.sky_texture)
		love.graphics.draw(self.cubeObject.objects.Cube.mesh)
	elseif type(self.sky_texture) == "userdata" and self.sky_texture:getTextureType() == "2d" then
		--HDRI
		local shader = self:getBasicShader("sky_hdri")
		love.graphics.setShader(shader)
		shader:send("exposure", self.sky_hdri_exposure)
		shader:send("transformProj", transformProj)
		local mesh = self.skyObject.meshes.Sphere.mesh
		mesh:setTexture(self.sky_texture)
		love.graphics.draw(mesh)
	elseif type(self.sky_texture) == "function" then
		self:sky_texture(transformProj, camTransform, transformScale)
	end
	love.graphics.pop()
end