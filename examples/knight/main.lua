--load the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Knight Example")

--settings
dream.flat = true
dream.objectDir = "examples/knight/"

dream.AO_enabled = true      --ambient occlusion?
dream.AO_strength = 0.75     --blend strength
dream.AO_quality = 24        --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2  --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5    --resolution factor

dream:init()

knight = dream:loadObject("knight")
love.graphics.setBackgroundColor(128/255, 218/255, 235/255)

function love.draw()
	dream:resetLight()
	
	dream:prepare()

	dream:draw(knight, 0, 0, -5, 1/4, nil, nil, math.cos(love.timer.getTime()), love.timer.getTime(), 0)

	dream:present()
end
