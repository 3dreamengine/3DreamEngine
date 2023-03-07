--load the 3D lib
local dream = require("3DreamEngine.init")
local vec3 = dream.vec3

love.window.setTitle("Knight Example")

--settings
dream:setAO(false)
dream:setSky(vec3(128/255, 218/255, 235/255) * 0.4)
dream:init()

--load voxel object using a custom mesh type
local knight = dream:loadObject("examples/knight/knight")

--use the simple (non textured) shader which makes use of the simple mesh type chosen by the VOX loader
knight:setPixelShader("simple")

--make a sun
local sun = dream:newLight("sun")

function love.draw()
	dream:prepare()
	dream:addLight(sun)

	knight:resetTransform()
	knight:translate(0, 0, 4)
	knight:rotateY(love.timer.getTime())
	knight:translate(-16, -30, -20)
	
	dream:draw(knight, 0, 0, -8, 0.25)

	dream:present()
end
