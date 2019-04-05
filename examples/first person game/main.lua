--load the 3D lib
l3d = require("3DreamEngine")
love.window.setTitle("Castle")

--settings
l3d.pixelPerfect = true
l3d.objectDir = "examples/first person game/"

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_strength = 0.75		--blend strength
l3d.AO_quality = 24		--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 2	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

l3d.lighting_enabled = false

l3d.cloudDensity = 0.6
l3d.clouds = love.graphics.newImage(l3d.objectDir .. "clouds.jpg")
l3d.sky = love.graphics.newImage(l3d.objectDir .. "sky.jpg")
l3d.night = love.graphics.newImage(l3d.objectDir .. "night.jpg")

l3d:init()

castle = l3d:loadObject("objects/scene", true)
love.graphics.setBackgroundColor(128/255, 218/255, 235/255)

math.randomseed(os.time())
io.stdout:setvbuf("no")

love.mouse.setRelativeMode(true)

player = {
	x = 0,
	y = 5,
	z = 0,
	ax = 0,
	ay = 0,
	az = 0,
	w = 0.4,
	h = 0.4,
	d = 0.6,
}

function love.draw()
	l3d.color_sun, l3d.color_ambient = l3d:getDayLight()
	l3d.dayTime = love.timer.getTime() * 0.05
	
	l3d:prepare()

	l3d:draw(castle, 0, 0, 0)

	l3d:present()
	
	if love.keyboard.isDown(".") then
		local shadersInUse = ""
		for d,s in pairs(l3d.stats.perShader) do
			shadersInUse = shadersInUse .. d .. ": " .. s .. "x  "
		end
		love.graphics.print("Stats" ..
			"\ndifferent shaders: " .. l3d.stats.shadersInUse ..
			"\ndifferent materials: " .. l3d.stats.materialDraws ..
			"\ndraws: " .. l3d.stats.draws ..
			"\nshaders: " .. shadersInUse, 15, 500)
		end
end

function love.mousemoved(_, _, x, y)
	local speedH = 0.005
	local speedV = 0.005
	l3d.cam.ry = l3d.cam.ry - x * speedH
	l3d.cam.rx = math.max(-math.pi/2, math.min(math.pi/2, l3d.cam.rx + y * speedV))
end

--collision not implemented yet
function collide(x, y, w, h)
	return false
end

function love.update(dt)
	local d = love.keyboard.isDown
	local speed = 10*dt
	
	--gravity
	--player.ay = player.ay - dt * 15
	
	--collision
	local oldX = player.x
	player.x = player.x + player.ax * dt
	local b = collide(player.x-player.w/2, player.y-player.h/2, player.z-player.d/2, player.w, player.h, player.d)
	if b then
		player.x = oldX
		player.ax = 0
	end
	
	local oldY = player.y
	player.y = player.y + player.ay * dt
	local b = collide(player.x-player.w/2, player.y-player.h/2, player.z-player.d/2, player.w, player.h, player.d)
	if b then
		player.y = oldY
		
		if love.keyboard.isDown("space") and player.ay < 0 then
			player.ay = 8
		else
			speed = 40*dt
			player.ay = 0
		end
		
		player.ax = player.ax * (1 - dt*10)
		player.az = player.az * (1 - dt*10)
	end
	
	local oldZ = player.z
	player.z = player.z + player.az * dt
	local b = collide(player.x-player.w/2, player.y-player.h/2, player.z-player.d/2, player.w, player.h, player.d)
	if b then
		player.z = oldZ
		player.az = 0
	end
	
	if d("w") then
		player.ax = player.ax + math.cos(-l3d.cam.ry-math.pi/2) * speed
		player.az = player.az + math.sin(-l3d.cam.ry-math.pi/2) * speed
	end
	if d("s") then
		player.ax = player.ax + math.cos(-l3d.cam.ry+math.pi-math.pi/2) * speed
		player.az = player.az + math.sin(-l3d.cam.ry+math.pi-math.pi/2) * speed
	end
	if d("a") then
		player.ax = player.ax + math.cos(-l3d.cam.ry-math.pi/2-math.pi/2) * speed
		player.az = player.az + math.sin(-l3d.cam.ry-math.pi/2-math.pi/2) * speed
	end
	if d("d") then
		player.ax = player.ax + math.cos(-l3d.cam.ry+math.pi/2-math.pi/2) * speed
		player.az = player.az + math.sin(-l3d.cam.ry+math.pi/2-math.pi/2) * speed
	end
	if d("space") then
		player.ay = player.ay + speed
	end
	if d("lshift") then
		player.ay = player.ay - speed
	end
	
	--air resistance
	player.ax = player.ax * (1 - dt*3)
	player.ay = player.ay * (1 - dt*3)
	player.az = player.az * (1 - dt*3)
	
	--mount cam
	l3d.cam.x = player.x
	l3d.cam.y = player.y+0.3
	l3d.cam.z = player.z
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
	l3d:init()
end