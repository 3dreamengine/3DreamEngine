--load the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Blacksmith")
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/blacksmith/"

--set reflection cubemap with local corrections
local r = dream:newReflection(cimg:load(projectDir .. "sky.cimg"))
r:setLocal(vec3(0, 0, 0), vec3(-2, -1, -2), vec3(2, 1, 2))
dream:setReflection(r)

dream:init()

local scene = dream:loadObject(projectDir .. "scene")
local torch = dream:loadObject(projectDir .. "torch")

--particle texture
local texture_candle = love.graphics.newImage(projectDir .. "textures/candle.png")
local factor = texture_candle:getHeight() / texture_candle:getWidth()
local quads = { }
for y = 1, 5 do
	for x = 1, 5 do
		table.insert(quads, love.graphics.newQuad(x-1, (y-1)*factor, 1, factor, 5, 5*factor))
	end
end

local particles = { }
local lastParticleID = 0

--create new particle batch
local particleBatch = dream:newParticleBatch(texture_candle)
particleBatch:setVertical(0.75)

local player = {
	x = 0,
	y = 0,
	z = 0,
	ax = 0,
	ay = 0,
	az = 0,
}

--because it is easier to work with two rotations
dream.cam.rx = 0
dream.cam.ry = 0

--create three light sources and assign shadows
local lights = { }
for i = 1, 3 do
	lights[i] = dream:newLight("point", 0, 0, 0, 1.0, 0.75, 0.5)
	lights[i]:addShadow(true)
	lights[i].shadow:setSmooth(true)
end

local hideTooltips = false

function love.draw()
	--update camera
	dream.cam:reset()
	dream.cam:translate(-player.x, -player.y, -player.z)
	dream.cam:rotateY(dream.cam.ry)
	dream.cam:rotateX(dream.cam.rx)
	
	--update lights
	dream:resetLight()
	
	--torches, lights and particles
	for d,s in ipairs({
		{0, 0.3, -1.85},
		{1.25, 0.3, 1.85},
		{-1.25, 0.3, 1.85},
	}) do
		lights[d]:setPosition(s[1], s[2], s[3])
		lights[d]:setBrightness(8.0 + 4.0 * love.math.noise(love.timer.getTime()*2))
		dream:addLight(lights[d])
		
		if math.random() < love.timer.getDelta()*8.0 then
			particles[lastParticleID] = {s[1] + (math.random()-0.5)*0.1, s[2] + (math.random()-0.5)*0.1, s[3] + (math.random()-0.5)*0.1, math.random()+1.0}
			lastParticleID = lastParticleID + 1
		end
	end
	
	--particles
	particleBatch:clear()
	love.graphics.setColor(0, 0, 0, 1)
	for d,s in pairs(particles) do
		particleBatch:addQuad(quads[math.ceil(d + s[4]*25) % 25 + 1], s[1], s[2], s[3], 0, s[4]*0.075, nil, 2.0)
	end
	love.graphics.setColor(1, 1, 1)
	
	dream:prepare()
	dream:draw(scene)
	
	dream:drawParticleBatch(particleBatch)
	
	--torches
	torch:reset()
	torch:rotateY(-math.pi/2)
	dream:draw(torch, 0, 0, -1.9, 0.075)
	torch:rotateY(-math.pi)
	dream:draw(torch, 1.25, 0, 1.9, 0.075)
	dream:draw(torch, -1.25, 0, 1.9, 0.075)

	dream:present()
	
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")\nB to toggle smooth shadows", 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	local speedH = 0.005
	local speedV = 0.005
	dream.cam.ry = dream.cam.ry - x * speedH
	dream.cam.rx = math.max(-math.pi/2, math.min(math.pi/2, dream.cam.rx + y * speedV))
end

function love.update(dt)
	local d = love.keyboard.isDown
	local speed = 10*dt
	
	--particles
	for d,s in pairs(particles) do
		s[2] = s[2] + dt*0.25
		s[4] = s[4] - dt
		if s[4] < 0 then
			particles[d] = nil
		end
	end
	
	--movement
	player.x = player.x + player.ax * dt
	player.y = player.y + player.ay * dt
	player.z = player.z + player.az * dt
	
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
	dream.cam.y = player.y
	dream.cam.z = player.z
	
	--update resource loader
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
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
	
	if key == "b" then
		for d,s in pairs(lights) do
			s.shadow:setSmooth(not s.shadow:getSmooth())
		end
	end
	
	if key == "f3" then
		dream:take3DScreenshot(vec3(player.x, player.y, player.z), 256)
	end
end

function love.resize()
	dream:init()
end