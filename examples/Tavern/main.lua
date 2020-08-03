--load the 3D lib
dream = require("3DreamEngine")
collision = require("3DreamEngine/collision")
love.window.setTitle("PBR Tavern")
love.window.setVSync(false)

--settings
local projectDir = "examples/Tavern/"
dream.nameDecoder = false
dream.sky_enabled = true
dream.autoExposure_enabled = true
dream.sun_ambient = {0.1, 0.1, 0.1}
dream.lighting_engine = "Phong"

dream.fog_enabled = true
dream.fog_distance = 10.0
dream.fog_density = 0.1
dream.fog_color = {0.7, 0.6, 0.5}

--load materials
dream:loadMaterialLibrary(projectDir .. "materials")

--initilize engine
dream:init()

--load scene
local scene = dream:loadObject(projectDir .. "scene", {shaderType = "PBR", noCleanup = true})

--create mesh collisions for all sub objects
local colls = collision:newGroup()
for d,s in pairs(scene.objects) do
	local c = collision:newMesh(s)
	
	--the first children is the actual mesh data which will be returned in the collider, we give it a name so we can recognise it later
	c.children[1].name = d
	
	colls:add(c)
end

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
local particleBatch = dream:newParticleBatch(texture_candle, 2)
particleBatch.vertical = true

local particleBatchDust = dream:newParticleBatch(love.graphics.newImage(projectDir .. "smoke.png"), 1)
particleBatchDust.sort = false

local lights = { }
for d,s in ipairs(scene.positions) do
	if s.name == "LIGHT" then
		lights[d] = dream:newLight(s.x, s.y + 0.1, s.z, 1.0, 0.75, 0.2)
		lights[d].shadow = dream:newShadow("point", true)
		lights[d].shadow.size = 0.1
	elseif s.name == "FIRE" then
		lights[d] = dream:newLight(s.x, s.y + 0.1, s.z, 1.0, 0.75, 0.2)
		lights[d].shadow = dream:newShadow("point", true)
		lights[d].shadow.size = 0.1
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
	for i = 1, 300 do
		local x = noise(i, 1 + c) * 100 % 10 - 5
		local y = noise(i, 2 + c) * 100 % 4
		local z = noise(i, 3 + c) * 100 % 10 - 5
		particleBatchDust:add(x, y, z, (i % 10 + 10) * 0.0025)
	end
	
	--update lights
	dream:resetLight(true)
	for d,s in ipairs(scene.positions) do
		if s.name == "LIGHT" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			lights[d]:setBrightness(power)
			dream:addLight(lights[d])
			particleBatch:add(s.x, s.y + 0.02, s.z, power * 0.015, 2.0, quads[math.ceil(d + love.timer.getTime() * 24) % 25 + 1])
		elseif s.name == "CANDLE" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			particleBatch:add(s.x, s.y + 0.02, s.z, power * 0.015, 2.0, quads[math.ceil(d + love.timer.getTime() * 24) % 25 + 1])
		elseif s.name == "FIRE" then
			local power = (0.5 + 0.3 * love.math.noise(love.timer.getTime() / math.sqrt(s.size) * 0.25, d)) * s.size * 200.0
			lights[d]:setBrightness(power)
			dream:addLight(lights[d])
		end
	end
	
	scene:reset()
	dream:draw(scene)
	
	dream:drawParticleBatch(particleBatch)
	dream:drawParticleBatch(particleBatchDust)

	dream:present()
	
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(table.concat({
			"R to toggle rain (" .. tostring(dream:isShaderModuleActive("rain")) .. ")",
			"U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled),
			"B to toggle smooth light (" .. tostring(dream.shadow_smooth) .. ")",
			"F to toggle fog (" .. tostring(dream.fog_enabled) .. ")",
			"L to toggle looking at check (" .. tostring(lookingAtCheck) .. ")",
			"K to toggle relative mode (" .. tostring(rotateCamera) .. ")",
			love.timer.getFPS() .. " FPS"
			}, "\n"), 10, 10)
	end
	
	--check which object you are looking at
	if lookingAtCheck then
		local t = love.timer.getTime()
		local coll = false
		local pos = vec3(player.x, player.y, player.z)
		
		local segment
		if rotateCamera then
			segment = collision:newSegment(pos, pos + dream.cam.normal * 10)
		else
			local x, y = love.mouse.getPosition()
			local point = dream:pixelToPoint(vec3(x, y, 10))
			segment = collision:newSegment(pos, point)
		end
		
		--check
		if collision:collide(segment, colls) then
			--fetch the collision of the last check
			local best = math.huge
			for d,s in ipairs(collision:getCollisions()) do
				local dist = (s[2] - pos):lengthSquared()
				if dist < best then
					best = dist
					coll = s[3].name or "?"
				end
			end
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
		end
	end
	
	if key == "u" then
		dream.autoExposure_enabled = not dream.autoExposure_enabled
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
end

function love.resize()
	dream:init()
end