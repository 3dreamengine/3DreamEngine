--load the 3D lib
dream = require("3DreamEngine")
raytrace = require("3DreamEngine/raytrace")
love.window.setTitle("PBR Tavern")
love.window.setVSync(false)

--settings
local projectDir = "examples/Tavern/"
dream:setNameDecoder()

dream.renderSet:setRefractions(true)

--dream:setDeferredShaderType("PBR")

dream:setSky(false)
dream:setReflection(cimg:load(projectDir .. "sky.cimg"))

dream:setAutoExposure(true)

dream:setFog(0.05, {0.7, 0.6, 0.5}, 0.0)
dream:setFogHeight(0.0, 2.5)

--load materials
dream:loadMaterialLibrary(projectDir .. "materials")

--initilize engine
dream:init()

--load scene
local scene = dream:loadObject(projectDir .. "scene", "PBR")

local player = {
	x = 4,
	y = 1.5,
	z = 4,
	ax = 0,
	ay = 0,
	az = 0,
}

--because it is easier to work with two rotations
dream.cam.rx = 0
dream.cam.ry = math.pi/4

local texture_candle = love.graphics.newImage(projectDir .. "candle.png")
local factor = texture_candle:getHeight() / texture_candle:getWidth()
local quads = { }
for y = 1, 5 do
	for x = 1, 5 do
		quads[#quads+1] = love.graphics.newQuad(x-1, (y-1)*factor, 1, factor, 5, 5*factor)
	end
end

--create new particle batch
local particleBatch = dream:newParticleBatch(texture_candle)
particleBatch:setVertical(0.75)

local particleBatchDust = dream:newParticleBatch(love.graphics.newImage(projectDir .. "dust.png"))
particleBatchDust:setSorting(false)

local lights = { }
for d,s in ipairs(scene.positions) do
	if s.name == "LIGHT" then
		lights[d] = dream:newLight("point", s.x, s.y + 0.1, s.z, 1.0, 0.75, 0.3)
		lights[d].shadow = dream:newShadow("point", true)
	elseif s.name == "FIRE" then
		lights[d] = dream:newLight("point", s.x, s.y + 0.1, s.z, 1.0, 0.75, 0.2)
		lights[d].shadow = dream:newShadow("point", true)
	end
end

local hideTooltips = false
local lookingAtCheck = false
local rotateCamera = true

local noise = require(projectDir .. "noise").Simplex2D

function love.draw()
	--update camera
	dream.cam:reset()
	dream.cam:translate(-player.x, -player.y, -player.z)
	dream.cam:rotateY(dream.cam.ry)
	dream.cam:rotateX(dream.cam.rx)
	
	dream:prepare()
	
	--torches
	particleBatch:clear()
	
	--dusty atmosphere
	particleBatchDust:clear()
	local c = love.timer.getTime() * 0.0003
	for i = 1, 200 do
		local x = noise(i, 1 + c) * 100 % 10.5 - 5.25
		local y = noise(i, 2 + c) * 100 % 4.5 - 0.25
		local z = noise(i, 3 + c) * 100 % 10.5 - 5.25
		particleBatchDust:add(x, y, z, 0, (i % 10 + 10) * 0.002)
	end
	
	--update lights
	dream:resetLight(true)
	
	--make the particles black so it only emits light
	love.graphics.setColor(0, 0, 0, 1)
	for d,s in ipairs(scene.positions) do
		if s.name == "LIGHT" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			lights[d]:setBrightness(power)
			dream:addLight(lights[d])
			particleBatch:addQuad(quads[math.ceil(d + love.timer.getTime() * 24) % 25 + 1], s.x, s.y + 0.02, s.z, 0, power * 0.015, nil, 3.0)
		elseif s.name == "CANDLE" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			particleBatch:addQuad(quads[math.ceil(d + love.timer.getTime() * 24) % 25 + 1], s.x, s.y + 0.02, s.z, 0, power * 0.015, nil, 3.0)
		elseif s.name == "FIRE" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			lights[d]:setBrightness(power)
			dream:addLight(lights[d])
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
	
	scene:reset()
	dream:draw(scene)
	
	dream:drawParticleBatch(particleBatch)
	dream:drawParticleBatch(particleBatchDust)

	dream:present()
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(table.concat({
			"R to toggle rain (" .. tostring(dream:isShaderModuleActive("rain")) .. ")",
			"U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")",
			"B to toggle smooth light (" .. tostring(dream.shadow_smooth) .. ")",
			"F to toggle fog (" .. tostring(dream.fog_enabled) .. ")",
			"L to toggle looking at check (" .. tostring(lookingAtCheck) .. ")",
			"K to toggle relative mode (" .. tostring(rotateCamera) .. ")",
			math.ceil(love.graphics.getStats().texturememory / 1024^2) .. " MB VRAM",
			love.timer.getFPS() .. " FPS",
			dream.mainShaderCount .. " shaders loaded"
			}, "\n"), 10, 10)
	end
	
	--check which object you are looking at
	if lookingAtCheck then
		local t = love.timer.getTime()
		local coll = false
		local origin = vec3(player.x, player.y, player.z)
		local direction
		
		if rotateCamera then
			direction = dream.cam.normal * 10
		else
			local x, y = love.mouse.getPosition()
			local point = dream:pixelToPoint(vec3(x, y, 10))
			direction = point - origin
		end
		
		--check
		if raytrace:raytrace(scene, origin, direction) then
			coll = raytrace:getObject().name
		end
		
		--cursor
		if rotateCamera then
			local size = 8
			love.graphics.line(love.graphics.getWidth()/2, love.graphics.getHeight()/2-size, love.graphics.getWidth()/2, love.graphics.getHeight()/2+size)
			love.graphics.line(love.graphics.getWidth()/2-size, love.graphics.getHeight()/2, love.graphics.getWidth()/2+size, love.graphics.getHeight()/2)
		end
		
		--debug
		if coll then
			love.graphics.printf("you are looking at " .. coll, 0, love.graphics.getHeight() - 20, love.graphics.getWidth(), "center")
		end
		love.graphics.printf(math.floor((love.timer.getTime() - t)*1000*10)/10 .. " ms", 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
	end
end

function love.mousemoved(_, _, x, y)
	if rotateCamera then
		local speedH = 0.005
		local speedV = 0.005
		dream.cam.ry = dream.cam.ry - x * speedH
		dream.cam.rx = math.max(-math.pi/2, math.min(math.pi/2, dream.cam.rx + y * speedV))
	end
end

function love.update(dt)
	local d = love.keyboard.isDown
	local speed = 7.5*dt
	love.mouse.setRelativeMode(rotateCamera)
	
	--collision
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
	dream.cam.y = player.y+0.3
	dream.cam.z = player.z
	
	dream:update()
end

function love.keypressed(key)
	if tonumber(key) then
--		if key == "9" then
--			dream:setBloom(false)
--		else
--			dream:setBloom(tonumber(key))
--		end
	end
	
	--screenshots!
	if key == "f2" then
		dream:takeScreenshot()
	end

	--fullscreen
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen())
		dream:init()
	end
	
	if key == "f1" then
		hideTooltips = not hideTooltips
	end
	
	if key == "r" then
		if dream:isShaderModuleActive("rain") then
			dream:deactivateShaderModule("rain")
		else
			dream:activateShaderModule("rain")
			dream:setWeather(1.0)
		end
	end
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
	
	if key == "b" then
		dream.shadow_smooth = not dream.shadow_smooth
		dream:init()
	end
	
	if key == "f" then
		dream.fog_enabled = not dream.fog_enabled
	end
	
	if key == "l" then
		lookingAtCheck = not lookingAtCheck
	end
	
	if key == "k" then
		rotateCamera = not rotateCamera
	end
	
	if key == "1" then
		dream.renderSet:setRefractions(not dream.renderSet:getRefractions())
		dream:init()
	end
	
	if key == "2" then
		dream.renderSet:setAverageAlpha(not dream.renderSet:getAverageAlpha())
		dream:init()
	end
	
	if key == "3" then
		local cullMode = dream:getAlphaCullMode()
		dream:init()
	end
	
	if key == "f3" then
		dream:take3DScreenshot(vec3(player.x, player.y, player.z), 128)
	end
end

function love.resize()
	dream:init()
end