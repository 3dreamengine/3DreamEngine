--window title
love.window.setTitle("Mesh Builder, Particles, and and Text")

--disable vsync to properly measure FPS
love.window.setVSync(false)

--load the 3D lib
local dream = require("3DreamEngine.init")


--load extensions
local sky = require("extensions/sky")
dream:setSky(sky.render)


--initialize engine
dream:init()

--load an example object
local monkey = dream:loadObject("examples/monkey/object")
local material = monkey.meshes.Suzanne.material
material.color = { 0.4, 0.15, 0.05, 1 }

local glyphAtlas = dream:newGlyphAtlas(nil, 32)

local text = dream:newTextMeshBuilder(glyphAtlas)

text:print("Simple text")

text:printf("This text should be perfectly centered", 200, "originCenter")

--[[
print(dream.inspect({
	glyphAtlas.font:getWrap({ { 1, 2, 3 }, "Carl" }, 50)
}))

print(dream.inspect({
	glyphAtlas:getWrap({ { color = { 1, 2, 3 }, string = "Carl" } }, 50)
}))
--]]


--make a sun
local sun = dream:newLight("sun")

--don't create a new builder each frame, reuse and clear instead
local animatedText = dream:newTextMeshBuilder(glyphAtlas)

function love.draw()
	dream:prepare()
	
	dream:addLight(sun)
	
	animatedText:clear()
	animatedText:printf({
		{
			string = "Look, a ",
		},
		{
			string = "RAINBOW",
			color = {
				love.math.noise(love.timer.getTime(), 1),
				love.math.noise(love.timer.getTime(), 2),
				love.math.noise(love.timer.getTime(), 3),
				1,
			},
			metallic = 1.0,
			emission = 1.0,
		},
		{
			string = "!",
		},
	}, 200, "originCenter")
	
	local t = dream.mat4.getIdentity()
	t = t:translate(-1, 1, -2.25)
	t = t:rotateY(math.cos(love.timer.getTime()) * 0.5)
	t = t:scale(0.01)
	dream:draw(text, t)
	t = dream.mat4.getTranslate(2, 0, 0)  * t
	dream:draw(animatedText, t)
	
	dream:present()
	
	love.graphics.draw(glyphAtlas:getTexture(), 10, 10)
end

function love.resize()
	dream:resize()
end