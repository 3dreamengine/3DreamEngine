--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Lamborghini Example")

--settings
dream.objectDir = "examples/Lamborghini"

dream.AO_enabled = true      --ambient occlusion?
dream.AO_strength = 0.75     --blend strength
dream.AO_quality = 32        --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2  --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 1.0    --resolution factor

dream.bloom_strength = 5.0

dream.nameDecoder = "none"

dream.shadow_enabled = true
dream.shadow_distance = 10

dream:init()

car = dream:loadObject("Lamborghini Aventador")
socket = dream:loadObject("socket")

--use custom reflections on this model, applies on all materials if not otherwise specified
car.reflections_day = dream.objectDir .. "/sky.jpg"

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

function love.draw()
	dream.resourceLoader:update()
	
	dream.sun = {-1.0, 0.6, 0.7}
	dream.color_ambient = {1, 1, 1, 0.5}
	dream.color_sun = {1, 1, 1, 1.0}
	
	dream:resetLight()
	
	dream:prepare()
	
	--draw the car
	love.graphics.setColor(1, 1, 1)
	car:reset()
	car:rotateY(love.mouse.isDown(1) and (-2.25-(love.mouse.getX()/love.graphics.getWidth()-0.5)*4.0) or love.timer.getTime()*0.5)
	dream:draw(car, 0, -1.1225, -4, 0.1)
	
	if dream.shadow_enabled then
		dream:draw(socket, 0, -1, -4, 3, 0.1)
	end
	
	dream:present()
	
	--stats
	love.graphics.setColor(0.1, 0.1, 0.1)
	love.graphics.print("Stats" ..
		"\ndifferent shaders: " .. dream.stats.shadersInUse ..
		"\ndifferent materials: " .. dream.stats.materialDraws ..
		"\ndraws: " .. dream.stats.draws, 15, 500)
end

function love.keypressed(key)
	--screenshots!
	if key == "f2" then
		if love.keyboard.isDown("lctrl") then
			love.system.openURL(love.filesystem.getSaveDirectory() .. "/screenshots")
		else
			love.filesystem.createDirectory("screenshots")
			if not screenShotThread then
				screenShotThread = love.thread.newThread([[
					require("love.image")
					channel = love.thread.getChannel("screenshots")
					while true do
						local screenshot = channel:demand()
						screenshot:encode("png", "screenshots/screen_" .. tostring(os.time()) .. ".png")
					end
				]]):start()
			end
			love.graphics.captureScreenshot(love.thread.getChannel("screenshots"))
		end
	end

	--fullscreen
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
end

function love.resize()
	dream:init()
end