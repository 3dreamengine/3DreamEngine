--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Lamborghini Example")

--settings
dream.objectDir = "examples/Lamborghini/"

dream.AO_enabled = true      --ambient occlusion?
dream.AO_strength = 0.75     --blend strength
dream.AO_quality = 32        --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2  --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.75   --resolution factor

dream:init()

dream.showLightSources = false

car = dream:loadObject("Lamborghini Aventador")

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

function love.draw()
	dream.color_ambient = {0.1, 0.1, 0.1, 1}
	dream.color_sun = {1, 1, 1, 2.0}
	
	dream:resetLight()
	if dream.lighting_enabled then
		dream:addLight(-1, math.cos(love.timer.getTime()) + 0.5, -5, 1.0, 1.0, 1.0, 10.0)
		dream:addLight(math.cos(love.timer.getTime())+4, -1, math.cos(love.timer.getTime())-5, 1.0, 1.0, 1.0, 10.0)
	end
	
	dream:prepare()
	
	--draw the car 
	love.graphics.setColor(1, 1, 1)
	dream:draw(car, 2.5, -3.5, -10, 0.35, nil, nil, 0, 2.25+(love.mouse.getX()/love.graphics.getWidth()-0.5), 0)
	
	dream:present()
	
	--instructions
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print("Lamborghini Aventador" ..
		"\nFPS: " .. love.timer.getFPS() ..
		"\n(1) toggle ambient occlusion (" .. tostring(dream.AO_enabled == true) .. ")" ..
		"\n(2) toggle per pixel shading (" .. tostring(dream.pixelPerfect == true) .. ")" .. 
		"\n(3) toggle lighting (" .. tostring(dream.lighting_enabled == true) .. ")" ..
		"\n(4) show light sources (" .. tostring(dream.showLightSources == true) .. ")", 15, 5)
	
	local shadersInUse = ""
	for d,s in pairs(dream.stats.perShader) do
		shadersInUse = shadersInUse .. d.name .. ": " .. s .. "x  "
	end
	love.graphics.print("Stats" ..
		"\ndifferent shaders: " .. dream.stats.shadersInUse ..
		"\ndifferent materials: " .. dream.stats.materialDraws ..
		"\ndraws: " .. dream.stats.draws ..
		"\nshaders: " .. shadersInUse, 15, 500)
end

function love.keypressed(key)
	if key == "1" then
		dream.AO_enabled = not dream.AO_enabled
		dream:init()
	elseif key == "2" then
		dream.pixelPerfect = not dream.pixelPerfect
		dream:init()
	elseif key == "3" then
		dream.lighting_enabled = not dream.lighting_enabled
		dream:init()
	elseif key == "4" then
		dream.showLightSources = not dream.showLightSources
	end
	dream:init()
end
