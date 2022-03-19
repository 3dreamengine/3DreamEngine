--load the 3D lib
local dream = require("3DreamEngine")
local raytrace = require("extensions/raytrace")

love.window.setTitle("PBR Tavern")
love.window.setVSync(false)

--settings
local projectDir = "examples/Tavern/"
dream:setSmoothLoading(false)

dream.renderSet:setRefractions(true)

dream:setSky(false)
--dream:setDefaultReflection(cimg:load(projectDir .. "sky.cimg"))

dream:setFog(0.0025, {0.6, 0.5, 0.4}, 0.0)
dream:setFogHeight(0.0, 2.5)

--load materials
dream:loadMaterialLibrary(projectDir .. "materials")

--initilize engine
dream:init()

--load scene
local tavern = dream:loadObject(projectDir .. "scene", {cleanup = false})
local scene = dream:newScene()
scene:addObject(tavern)

--a helper class
local cameraController = require("examples/firstpersongame/cameraController")

cameraController.x = 4
cameraController.y = 1.5
cameraController.z = 4
cameraController.ry = -math.pi/4

local texture_candle = love.graphics.newImage(projectDir .. "candle.png")
local factor = texture_candle:getHeight() / texture_candle:getWidth()
local quads = { }
for y = 1, 5 do
	for x = 1, 5 do
		table.insert(quads, love.graphics.newQuad(x-1, (y-1)*factor, 1, factor, 5, 5*factor))
	end
end

--create new particle batch
local particleBatch = dream:newParticleBatch(texture_candle)
particleBatch:setVertical(0.75)

local particleBatchDust = dream:newParticleBatch(love.graphics.newImage(projectDir .. "dust.png"))
particleBatchDust:setSorting(false)

local lights = { }
for d,s in ipairs(tavern.positions) do
	if s.name == "light" then
		lights[d] = dream:newLight("point", vec3(s.position.x, s.position.y + 0.1, s.position.z), vec3(1.0, 0.75, 0.3))
		lights[d]:addShadow()
		lights[d].shadow:setStatic(true)
		lights[d].shadow:setSmooth(true)
		lights[d].shadow:setRefreshStepSize(1000)
		lights[d].shadow:setLazy(true)
		lights[d]:setAttenuation(3) --unrealistic but looks better
	elseif s.name == "fire" then
		lights[d] = dream:newLight("point", vec3(s.position.x, s.position.y + 0.1, s.position.z), vec3(1.0, 0.75, 0.2))
		lights[d]:addShadow()
		lights[d].shadow:setStatic(true)
		lights[d].shadow:setSmooth(true)
		lights[d].shadow:setRefreshStepSize(1000)
		lights[d].shadow:setLazy(true)
		lights[d]:setAttenuation(3) --unrealistic but looks better
		lights[d]:setSize(0.1)
	end
end

local hideTooltips = false
local lookingAtCheck = false
local rotateCamera = true

local noise = require(projectDir .. "noise").Simplex2D

local function getFlickerOffset(d, f)
	return vec3(
		noise(love.timer.getTime(), d + 0) * f,
		noise(love.timer.getTime(), d + 1) * f,
		noise(love.timer.getTime(), d + 2) * f
	)
end

function love.draw()
	--update camera
	cameraController:setCamera(dream.cam)
	
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
	
	--make the particles black so it only emits light
	love.graphics.setColor(0, 0, 0, 1)
	for d,s in ipairs(tavern.positions) do
		local flicker = love.timer.getTime() / math.sqrt(s.size) * 0.2
		if s.name == "light" then
			local power = (0.5 + 0.2 * noise(flicker, d)) * s.size * 500.0
			lights[d]:setBrightness(power)
			lights[d].oPos = lights[d].oPos or lights[d].pos
			lights[d]:setPosition(lights[d].oPos + getFlickerOffset(d, 0.02))
			dream:addLight(lights[d])
		elseif s.name == "candle" then
			local power = (0.5 + 0.2 * noise(flicker, d)) * s.size * 4
			particleBatch:addQuad(quads[math.ceil(d + love.timer.getTime() * 24) % 25 + 1], s.position.x, s.position.y + 0.02, s.position.z, 0, power, nil, 2.0)
		elseif s.name == "fire" then
			local power = (0.5 + 0.2 * noise(flicker, d)) * s.size * 2000.0
			lights[d]:setBrightness(power)
			lights[d].oPos = lights[d].oPos or lights[d].pos
			lights[d]:setPosition(lights[d].oPos + getFlickerOffset(d, 0.02))
			dream:addLight(lights[d])
			
			for i = -3, 3 do
				local power = (0.5 + 0.15 * noise(flicker, d + i)) * s.size / (1 + 0.1 * math.abs(i)) * 4
				particleBatch:addQuad(quads[math.ceil(i * 17 + d + love.timer.getTime() * 24) % 25 + 1], s.position.x + i * 0.1, s.position.y - 0.15, s.position.z - 0.1 - math.abs(i) * 0.025, 0, power, nil, 4.0)
			end
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
	
	dream:drawScene(scene)
	
	dream:drawParticleBatch(particleBatch)
	dream:drawParticleBatch(particleBatchDust)

	dream:present()
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(table.concat({
			"U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")",
			"F to toggle fog (" .. tostring(dream.fog_enabled) .. ")",
			"8 to enable fast rendering",
			"9 to enable quality rendering",
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
		if raytrace:raytrace(tavern, origin, direction) then
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
		cameraController:mousemoved(x, y)
	end
end

function love.update(dt)
	cameraController:update(dt)
	
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
		dream:init()
	end
	
	if key == "f1" then
		hideTooltips = not hideTooltips
	end
	
	if key == "u" then
		local enabled = dream:getAutoExposure()
		dream:setAutoExposure(not enabled)
		dream:init()
	end
	
	if key == "f" then
		dream.fog_enabled = not dream.fog_enabled
		dream:init()
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
	
	if key == "f3" then
		dream:take3DScreenshot(vec3(player.x, player.y, player.z), 128)
	end
	
	if key == "g" then
		dream:setGamma(not dream:getGamma())
		dream:init()
	end
	
	if key == "e" then
		dream:setExposure(not dream:getExposure() and 1.0 or false)
		dream:init()
	end
	
	if key == "8" then
		dream.renderSet:setMode("direct")
		dream:init()
	end
	
	if key == "9" then
		dream.renderSet:setMode("normal")
		dream:init()
	end
	
	scene = dream:newScene()
	scene:addObject(tavern)
end

function love.resize()
	dream:init()
end