--load the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Monkey Example")

--settings
dream.objectDir = "examples/monkey"

dream.AO_enabled = true       --ambient occlusion?
dream.AO_strength = 0.75      --blend strength
dream.AO_quality = 24         --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2   --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5     --resolution factor

dream:init()

monkey = dream:loadObject("object")

love.graphics.setBackgroundColor(128/255, 218/255, 235/255)

function love.draw()
	dream:resetLight()
	
	dream:prepare()
	
	monkey:reset()
	monkey:rotateY(love.timer.getTime())
	dream:draw(monkey, 0, 0, -2)

	dream:present()
end
