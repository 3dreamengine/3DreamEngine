--load the 3D lib
dream = require("3DreamEngine")
love.window.setTitle("First Person Game")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/firstpersongame/"
dream:init()

--load all materials
dream:loadMaterialLibrary(projectDir .. "materials")

--load object
local scene = dream:loadObject(projectDir .. "objects/scene", "PBR")

--activate the global rain shader module
dream:activateShaderModule("rain")

player = {
	x = 2,--8,
	y = 2,--10,
	z = 2,--2,
	ax = 0,
	ay = 0,
	az = 0,
	w = 0.4,
	h = 0.4,
	d = 0.6,
}

--because it is easier to work with two rotations
dream.cam.rx = 0
dream.cam.ry = 0

local time = 0
local timeAnimate = true
local hideTooltips = false
local rain = 0.45

function love.draw()
	--update camera
	dream.cam:reset()
	dream.cam:translate(-player.x, -player.y, -player.z)
	dream.cam:rotateY(dream.cam.ry)
	dream.cam:rotateX(dream.cam.rx)
	
	--update light
	dream:resetLight(true)
	if love.mouse.isDown(1) then
		dream:addNewLight(player.x + dream.cam.normal.x, player.y + dream.cam.normal.y, player.z + dream.cam.normal.z, 1.0, 0.75, 0.1, 5.0 + love.math.noise(love.timer.getTime()*2))
	end
	
	dream:prepare()
	
	dream:draw(scene)
	
	dream:present()
	
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("R to toggle rain (" .. tostring(dream:getShaderModule("rain").isRaining) .. ")\nT to toggle daytime animation (" .. tostring(timeAnimate) .. ")\nU to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")" .. "\nheight: " .. player.y, 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	local speedH = 0.005
	local speedV = 0.005
	dream.cam.ry = dream.cam.ry - x * speedH
	dream.cam.rx = math.max(-math.pi/2, math.min(math.pi/2, dream.cam.rx + y * speedV))
end

--collision not implemented yet
function collide(x, y, w, h)
	return false
end

function love.update(dt)
	local d = love.keyboard.isDown
	local speed = 10*dt
	
	--daytime
	if timeAnimate then
		time = time + dt * 0.05
	end
	dream:setDaytime(time)
	
	--weather
	local oldRain = dream:getWeather()
	dream:setWeather(math.clamp(oldRain + (rain > oldRain and 1 or -1) * dt * 0.05, 0.25, 0.85))
	
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
		player.ax = player.ax + math.cos(-dream.cam.ry-math.pi/2) * speed
		player.az = player.az + math.sin(-dream.cam.ry-math.pi/2) * speed
	end
	if d("s") then
		player.ax = player.ax + math.cos(-dream.cam.ry+math.pi-math.pi/2) * speed
		player.az = player.az + math.sin(-dream.cam.ry+math.pi-math.pi/2) * speed
	end
	if d("a") then
		player.ax = player.ax + math.cos(-dream.cam.ry-math.pi/2-math.pi/2) * speed
		player.az = player.az + math.sin(-dream.cam.ry-math.pi/2-math.pi/2) * speed
	end
	if d("d") then
		player.ax = player.ax + math.cos(-dream.cam.ry+math.pi/2-math.pi/2) * speed
		player.az = player.az + math.sin(-dream.cam.ry+math.pi/2-math.pi/2) * speed
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
	dream.cam.x = player.x
	dream.cam.y = player.y+0.3
	dream.cam.z = player.z
	
	--load world, then if done load high res textures
	dream:update()
end

function love.keypressed(key)
	--screenshots!
	if key == "f2" then
		dream:takeScreenshot()
	end

	--fullscreen
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
	end
	
	if key == "f1" then
		hideTooltips = not hideTooltips
	end
	
	if key == "r" then
		if rain > 0.5 then
			rain = 0.25
		else
			rain = 0.9
		end
	end
	
	if key == "t" then
		timeAnimate = not timeAnimate
	end
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
end

function love.resize()
	dream:init()
end