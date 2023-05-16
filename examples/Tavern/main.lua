--load the 3D lib
local dream = require("3DreamEngine.init")
local vec3 = dream.vec3

local raytrace = require("extensions/raytrace")

love.window.setTitle("PBR Tavern")
love.window.setVSync(true)
love.mouse.setRelativeMode(true)

--settings
local projectDir = "examples/Tavern/"

dream.canvases:setRefractions(true)

dream:setSky(false)
dream:setDefaultReflection(dream.cimg:load(projectDir .. "sky.cimg"))

dream:setFog(0.0025, { 0.6, 0.5, 0.4 }, 0.0)
dream:setFogHeight(0.0, 2.5)

--load materials
dream:loadMaterialLibrary(projectDir .. "materials")

dream:setAutoExposure(true)

--initialize engine
dream:init()

--load scene
local tavern = dream:loadObject(projectDir .. "scene", { cleanup = false })

--a helper class
local cameraController = require("extensions/utils/cameraController")

cameraController.x = 4
cameraController.y = 1.5
cameraController.z = 4
cameraController.ry = -math.pi / 4

local texture_candle = love.graphics.newImage(projectDir .. "candle.png")
local factor = texture_candle:getHeight() / texture_candle:getWidth()
local quads = { }
for y = 1, 5 do
	for x = 1, 5 do
		table.insert(quads, love.graphics.newQuad(x - 1, (y - 1) * factor, 1, factor, 5, 5 * factor))
	end
end

--create new particle batch
local spriteBatch = dream:newSpriteBatch(texture_candle, texture_candle)
spriteBatch:setVertical(0.75)

local particleBatchDust = dream:newSpriteBatch(love.graphics.newImage(projectDir .. "dust.png"))
particleBatchDust:setSorting(false)
particleBatchDust:getMaterial():setRoughness(1)

--setup light sources
local lights = { }
for d, l in pairs(tavern.positions) do
	l.r = math.random()
	if l:getValue() == "light" then
		lights[d] = dream:newLight("point", l:getPosition() + vec3(0, 0.1, 0), vec3(1.0, 0.75, 0.3))
		local shadow = lights[d]:addNewShadow()
		shadow:setStatic(true)
		shadow:setSmooth(true)
		shadow:setRefreshStepSize(1000)
		shadow:setLazy(true)
		lights[d]:setAttenuation(3) --unrealistic but looks better
	elseif l:getValue() == "fire" then
		lights[d] = dream:newLight("point", l:getPosition() + vec3(0, 0.1, 0), vec3(1.0, 0.75, 0.2))
		local shadow = lights[d]:addNewShadow()
		shadow:setStatic(true)
		shadow:setSmooth(true)
		shadow:setRefreshStepSize(1000)
		shadow:setLazy(true)
		lights[d]:setAttenuation(3) --unrealistic but looks better
		lights[d]:setSize(0.1)
	end
end

local hideTooltips = false
local lookingAtCheck = false
local rotateCamera = true

local noise = require(projectDir .. "noise").Simplex2D

local function getFlickerOffset(d, f)
	local t = love.timer.getTime()
	return vec3(
			noise(t, d + 0) * f,
			noise(t, d + 1) * f,
			noise(t, d + 2) * f
	)
end

function love.draw()
	--update camera
	cameraController:setCamera(dream.camera)
	
	dream:prepare()
	
	--torches
	spriteBatch:clear()
	
	--dusty atmosphere
	particleBatchDust:clear()
	local c = love.timer.getTime() * 0.0003
	for i = 1, 200 do
		local x = noise(i, 1 + c) * 100 % 10.5 - 5.25
		local y = noise(i, 2 + c) * 100 % 4.5 - 0.25
		local z = noise(i, 3 + c) * 100 % 10.5 - 5.25
		
		particleBatchDust:add(x, y, z, i, (i % 10 + 10) * 0.002)
	end
	
	--make the particles black so it only emits light
	love.graphics.setColor(0, 0, 0, 1)
	for d, l in pairs(tavern.positions) do
		local flicker = love.timer.getTime() / math.sqrt(l:getSize()) * 0.2
		if l:getValue() == "light" then
			local power = (0.5 + 0.2 * noise(flicker, l.r)) * l:getSize() * 500.0
			lights[d]:setBrightness(power)
			lights[d].originalPosition = lights[d].originalPosition or lights[d]:getPosition()
			lights[d]:setPosition(lights[d].originalPosition + getFlickerOffset(l.r, 0.02))
			dream:addLight(lights[d])
		elseif l:getValue() == "candle" then
			local power = (0.5 + 0.2 * noise(flicker, l.r)) * l:getSize() * 4
			spriteBatch:addQuad(quads[math.ceil(l.r + love.timer.getTime() * 24) % 25 + 1], l.position.x, l.position.y + 0.02, l.position.z, 0, power, nil, 2.0)
		elseif l:getValue() == "fire" then
			local power = (0.5 + 0.2 * noise(flicker, l.r)) * l:getSize() * 2000.0
			lights[d]:setBrightness(power)
			lights[d].originalPosition = lights[d].originalPosition or lights[d]:getPosition()
			lights[d]:setPosition(lights[d].originalPosition + getFlickerOffset(l.r, 0.02))
			dream:addLight(lights[d])
			
			for i = -3, 3 do
				local flamePower = (0.5 + 0.15 * noise(flicker, l.r + i)) * l:getSize() / (1 + 0.1 * math.abs(i)) * 4
				spriteBatch:addQuad(quads[math.ceil(i * 17 + l.r + love.timer.getTime() * 24) % 25 + 1], l.position.x + i * 0.1, l.position.y - 0.15, l.position.z - 0.1 - math.abs(i) * 0.025, 0, flamePower, nil, 4.0)
			end
		end
	end
	love.graphics.setColor(1, 1, 1, 1)
	
	--draw the scene
	dream:draw(tavern)
	
	--draw the particles
	dream:draw(spriteBatch)
	dream:draw(particleBatchDust)
	
	--render
	dream:present()
	
	--hints
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(table.concat({
			"U to toggle auto exposure (" .. tostring(dream.autoExposure_enabled) .. ")",
			"F to toggle fog (" .. tostring(dream.fog_enabled) .. ")",
			"8 to enable fast rendering",
			"9 to enable quality rendering",
			"L to toggle looking at check (" .. tostring(lookingAtCheck) .. ")",
			"K to toggle relative mode (" .. tostring(rotateCamera) .. ")",
			math.ceil(love.graphics.getStats().texturememory / 1024 ^ 2) .. " MB VRAM",
			love.timer.getFPS() .. " FPS",
			dream.mainShaderCount .. " shaders loaded"
		}, "\n"), 10, 10)
	end
	
	--check which object you are looking at
	if lookingAtCheck then
		local t = love.timer.getTime()
		local coll = false
		local origin = dream.camera.position
		local direction
		
		if rotateCamera then
			direction = dream.camera.normal * 10
		else
			local x, y = love.mouse.getPosition()
			local point = dream:pixelToPoint(vec3(x, y, 10))
			direction = point - origin
		end
		
		--check
		local result = raytrace:cast(tavern, origin, direction)
		if result then
			coll = result:getMesh().name
		end
		
		--cursor
		if rotateCamera then
			local size = 8
			love.graphics.line(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 - size, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2 + size)
			love.graphics.line(love.graphics.getWidth() / 2 - size, love.graphics.getHeight() / 2, love.graphics.getWidth() / 2 + size, love.graphics.getHeight() / 2)
		end
		
		--debug
		if coll then
			love.graphics.printf("you are looking at " .. coll, 0, love.graphics.getHeight() - 20, love.graphics.getWidth(), "center")
		end
		love.graphics.printf(math.floor((love.timer.getTime() - t) * 1000 * 10) / 10 .. " ms", 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
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
		love.mouse.setRelativeMode(rotateCamera)
	end
	
	if key == "1" then
		dream.canvases:setRefractions(not dream.canvases:getRefractions())
		dream:init()
	end
	
	if key == "f3" then
		dream:take3DScreenshot(vec3(cameraController.x, cameraController.y, cameraController.z), 128)
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
		dream.canvases:setMode("direct")
		dream:init()
	end
	
	if key == "9" then
		dream.canvases:setMode("normal")
		dream:init()
	end
end

function love.resize()
	dream:init()
end