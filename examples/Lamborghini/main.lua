require("3DreamEngine")

--load the matrix and the 3D lib
l3d = require("3DreamEngine")

--settings
l3d.flat = false
l3d.pixelPerfect = true
l3d.objectDir = "examples/Lamborghini/"
l3d.pathToNoiseTex = "noise.png"

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_strength = 0.75		--blend strength
l3d.AO_quality = 24			--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 1	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.75	--resolution factor

l3d:init()

l3d.showLightSources = true

car = l3d:loadObject("Lamborghini Aventador")

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

function love.draw()
	l3d:prepare()
	
	--draw the car 
	love.graphics.setColor(1, 1, 1)
	l3d:draw(car, 2.5, -3.5, -10, 0.35, nil, nil, 0, 2.25, 0)
	
	l3d:present()
	
	--instructions
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print("Lamborghini Aventador" ..
		"\nFPS: " .. love.timer.getFPS() ..
		"\n\n(1) toggle textured mode (" .. tostring(l3d.flat == false) .. ")" ..
		"\n(2) toggle ambient occlusion (" .. tostring(l3d.AO_enabled == true) .. ")" ..
		"\n(3) toggle per pixel shading (" .. tostring(l3d.pixelPerfect == true) .. ")" .. 
		"\n(4) toggle lighting (" .. tostring(l3d.lighting_enabled == true) .. ")" ..
		"\n(5) show light sources (" .. tostring(l3d.showLightSources == true) .. ")", 15, 5)
	
	l3d.color_ambient = {0.1, 0.1, 0.1, 1}
	l3d.color_sun = {0.5, 0.5, 0.5, 1}
	
	--clear unused lightning, bad will happen if not
	for i = 1, l3d.lighting_max do
		l3d.lighting[1] = {0, 0, 0, 0, 0, 0, 0}
	end
	
	--set lights
	l3d.lighting[1] = {-1, math.cos(love.timer.getTime()), -5, 1.0, 1.0, 1.0, 5.0}
	l3d.lighting[2] = {math.cos(love.timer.getTime())+4, -1, math.cos(love.timer.getTime())-5, 1.0, 1.0, 1.0, 5.0}
end

function love.keypressed(key)
	if key == "1" then
		l3d.flat = not l3d.flat
		car = l3d:loadObject("Lamborghini Aventador")
		l3d:init()
	elseif key == "2" then
		l3d.AO_enabled = not l3d.AO_enabled
		l3d:init()
	elseif key == "3" then
		l3d.pixelPerfect = not l3d.pixelPerfect
		l3d:init()
	elseif key == "4" then
		l3d.lighting_enabled = not l3d.lighting_enabled
		if not l3d.lighting_enabled then
			l3d.pixelPerfect = false
		end
		l3d:init()
	elseif key == "5" then
		l3d.showLightSources = not l3d.showLightSources
	end
end