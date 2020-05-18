--load the matrix and the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("Particle System Example")

--settings
local projectDir = "examples/particlesystem/"

dream.secondPass = false
dream.lighting_engine = "Phong"

dream:init()

ground = dream:loadObject(projectDir .. "ground", {splitMaterials = true})

function love.draw()
	dream:resetLight()
	
	dream:prepare()
	
	love.graphics.setColor(1, 1, 1)
	dream:draw(ground)
	
	dream:present()
end

function love.update(dt)
	local time = love.timer.getTime() * 0.01
	
	if not love.keyboard.isDown("space") then
		dream.cam:reset()
		dream.cam:translate(math.cos(time) * 2.0, -0.5, math.sin(time) * 2.0)
		dream.cam:rotateY(-math.pi/2-time)
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

function love.resize()
	dream:init()
end