--load the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Monkey Example")
local projectDir = "examples/monkey/"

--use Phong shading
dream.lighting_engine = "Phong"

--initialize engine
dream:init()

--load our object
monkey = dream:loadObject(projectDir .. "object")

love.graphics.setBackgroundColor(128/255, 218/255, 235/255)

function love.draw()
	dream:resetLight()
	
	--prepare scene
	dream:prepare()
	
	--add (draw) objects, apply transformations
	monkey:reset()
	monkey:rotateY(love.timer.getTime())
	dream:draw(monkey, 0, 0, -2.25)
	
	--render
	dream:present()
end
