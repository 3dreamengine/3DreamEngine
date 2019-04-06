--load the matrix and the 3D lib
l3d = require("3DreamEngine")
love.window.setTitle("Particle System Example")

--settings
l3d.flat = true
l3d.pixelPerfect = true
l3d.objectDir = "examples/particlesystem/"

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_strength = 0.75		--blend strength
l3d.AO_quality = 24			--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 2	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

l3d.lighting_enabled = false

l3d:init()

ground = l3d:loadObject("ground")

love.graphics.setBackgroundColor(0.8, 0.8, 0.8)

function love.draw()
	l3d:prepare()
	
	love.graphics.setColor(1, 1, 1)
	l3d:draw(ground, 0, 0, 0)
	
	l3d:present()
end

function love.update(dt)
	local time = love.timer.getTime()
	
	if not love.keyboard.isDown("space") then
		l3d.cam.x = math.cos(time) * 1.5
		l3d.cam.z = math.sin(time) * 1.5
		l3d.cam.y = 0.5
		
		l3d.cam.ry = math.pi/2-time
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