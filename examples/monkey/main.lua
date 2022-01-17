--window title
love.window.setTitle("Monkey Example")

--load the 3D lib
local dream = require("3DreamEngine")

--initialize engine
dream:init()

--load our object
local monkey = dream:loadObject("examples/monkey/object")

monkey.meshes.Suzanne.material.color = {0.8, 0.2, 0.085, 1}

--make a sun
local sun = dream:newLight("sun", vec3(1, 1, 1), vec3(1, 1, 1), 5.0)

function love.draw()
	--setup light
	dream:resetLight()
	dream:addLight(sun)
	
	--prepare scene
	dream:prepare()
	
	--add (draw) objects, apply transformations
	monkey:reset()
	monkey:rotateY(love.timer.getTime())
	dream:draw(monkey, 0, 0, -2.25)
	
	--render
	dream:present()
end
