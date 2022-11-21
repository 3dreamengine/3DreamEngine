--[[
Tools for visualizing an entire physics world as lines
--]]

local utils = { }

local meshFormat = {
	{ "VertexPosition", "float", 2 },
	{ "VertexHeight", "float", 2 },
}

local pixelCode = [[
	varying vec2 VaryingHeight;
	
	extern float cameraHeight;
	extern float inverseCameraSpan;
	
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    	float shade;
    	if (cameraHeight > VaryingHeight.x && cameraHeight < VaryingHeight.y) {
    		shade = 1.0;
    	} else {
    		shade = max(1.0 - min(abs(cameraHeight - VaryingHeight.x), abs(cameraHeight - VaryingHeight.y)) * inverseCameraSpan, 0.0) * 0.5;
    	}
    	
        return color * vec4(1.0, 1.0, 1.0, shade);
    }
]]

local vertexCode = [[
	varying vec2 VaryingHeight;
	attribute vec2 VertexHeight;
	
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
    	VaryingHeight = VertexHeight;
        return transform_projection * vertex_position;
    }
]]

utils.shader = love.graphics.newShader(pixelCode, vertexCode)

function utils.createFromWorld(world)
	local vertices = { }
	for _, body in ipairs(world.world:getBodies()) do
		local collider = body:getUserData()
		for fixtureIndex, fixture in ipairs(collider.body:getFixtures()) do
			local shape = fixture:getShape()
			if shape.getPoints then
				local x1, y1, x2, y2, x3, y3 = collider.body:getWorldPoints(shape:getPoints())
				table.insert(vertices, { x1, y1, collider.shape.lowest[fixtureIndex][1], collider.shape.highest[fixtureIndex][1] })
				table.insert(vertices, { x2, y2, collider.shape.lowest[fixtureIndex][2], collider.shape.highest[fixtureIndex][2] })
				table.insert(vertices, { x3, y3, collider.shape.lowest[fixtureIndex][3], collider.shape.highest[fixtureIndex][3] })
			end
		end
	end
	assert(#vertices > 0, "Map empty!")
	return love.graphics.newMesh(meshFormat, vertices, "triangles", "dynamic")
end

function utils.draw(position, mapMesh, x, y, w, h, zoom)
	love.graphics.push("all")
	love.graphics.setScissor(x, y, w, h)
	love.graphics.setShader(utils.shader)
	utils.shader:send("cameraHeight", position.y)
	utils.shader:send("inverseCameraSpan", 1 / 8)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.push()
	love.graphics.translate(x + w / 2, y + h / 2)
	love.graphics.scale(zoom)
	love.graphics.translate(-position.x, -position.z)
	love.graphics.draw(mapMesh)
	love.graphics.setScissor()
	love.graphics.setShader()
	love.graphics.pop()
	love.graphics.rectangle("line", x, y, w, h)
	love.graphics.pop()
end

return utils