--window title
love.window.setTitle("Monkey Example")

--load the 3D lib
local dream = require("3DreamEngine.init")

--initialize engine
dream:init()

--load our object
local monkey = dream:loadObject("examples/monkey/object")

monkey.meshes.Suzanne.material.color = {0.4, 0.15, 0.05, 1}

--make a sun
local sun = dream:newLight("sun")

function love.draw()
	dream:prepare()
	
	dream:addLight(sun)
	
	--add (draw) objects, apply transformations
	monkey:resetTransform()
	monkey:rotateY(love.timer.getTime())
	dream:draw(monkey, 0, 0, -2.25)
	
	--render
	dream:present()
end