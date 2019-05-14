--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Particle System Example")

--settings
dream.flat = true
dream.pixelPerfect = true
dream.objectDir = "examples/particlesystem/"

dream.AO_enabled = true       --ambient occlusion?
dream.AO_strength = 0.75      --blend strength
dream.AO_quality = 24         --samples per pixel (8-32 recommended)
dream.AO_quality_smooth = 2   --smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
dream.AO_resolution = 0.5     --resolution factor

dream.lighting_enabled = false

dream:init()

ground = dream:loadObjectLazy("ground")

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

function love.draw()
	dream:resetLight()
	
	dream:prepare()
	
	love.graphics.setColor(1, 1, 1)
	dream:draw(ground, 0, 0, 0)
	
	dream:present()
end

function love.update(dt)
	if not ground.loaded then
		ground:resume()
	end
	
	local time = love.timer.getTime() * 0.5
	
	if not love.keyboard.isDown("space") then
		dream.cam.x = math.cos(time) * 1.5
		dream.cam.z = math.sin(time) * 1.5
		dream.cam.y = 0.5
		
		dream.cam.ry = math.pi/2-time
	end
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