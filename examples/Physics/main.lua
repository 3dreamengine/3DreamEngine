--load the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Physics Demo")
love.mouse.setRelativeMode(true)

--sun
local sun = dream:newLight("sun")
sun:addShadow()

--load extensions
local sky = require("extensions/sky")
dream:setSky(sky.render)
sky:setDaytime(sun, 0.4)

--settings
local projectDir = "examples/Physics/"

dream:init()

dream:loadMaterialLibrary(projectDir .. "materials")

local scene = dream:loadScene(projectDir .. "objects/scene")
scene:print()

--a helper class
--todo
local cameraController = require("examples/firstpersongame/cameraController")

local hideTooltips = false

local utils = require("extensions/utils")

---@type PhysicsExtension
local physics = require("extensions/physics/init")
local world = physics:newWorld()

scene:rotateX(-math.pi / 2)
world:add(physics:newObject(scene))

--our objects, a composition of a model and a collider
local objects = {  }
local function addObject(model, x, y, z, collider)
	local o = {
		model = model,
		collider = world:add(collider or physics:newObject(model), "dynamic", x, y, z)
	}
	table.insert(objects, o)
	return o
end

local chicken = dream:loadObject(projectDir .. "objects/chicken", { callback = function(model)
	model:setVertexShader("bones")
end })
local player = addObject(chicken, 0, 10, 0, physics:newCapsule(0.175, 0.5))

local crate = dream:loadObject(projectDir .. "objects/crate")
crate:resetTransform()
crate:print()

for i = 1, 30 do
	addObject(crate, (math.random() - 0.5) * 10, 15, (math.random() - 0.5) * 10)
end

local mapMesh = utils.map.createFromWorld(world)

function love.draw()
	--update camera
	cameraController:lookAt(dream.cam, player.collider:getPosition() + vec3(0, 0.4, 0), 1)
	
	dream:prepare()
	
	dream:addLight(sun)
	
	dream:draw(scene)
	
	for _, o in ipairs(objects) do
		o.model:resetTransform()
		local c = (o.collider[1] or o.collider)
		o.model:translate(c:getPosition()) --TODO
		if o.model == chicken then
			local v = o.collider:getVelocity()
			o.walkingAnim = (o.walkingAnim or 0) + love.timer.getDelta() * vec3(v.x, 0, v.z):length()
			o.avgVelocity = (o.avgVelocity or v) * (1 - love.timer.getDelta() * 5) + v * love.timer.getDelta() * 5
			chicken:applyPose(chicken.animations.Armature:getPose(o.walkingAnim))
			chicken:rotateY(math.atan2(o.avgVelocity.z, o.avgVelocity.x) - math.pi / 2)
			chicken:rotateX(-math.pi / 2)
			chicken:scale(1 / 20)
		else
			o.model:rotateY(c:getBody():getAngle())
		end
		dream:draw(o.model)
	end
	
	dream:present()
	
	--map
	utils.map.draw(vec3(cameraController.x, cameraController.y, cameraController.z), mapMesh, love.graphics.getWidth() - 10 - 200, 10, 200, 200, 10)
	
	--stats
	if not hideTooltips then
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(love.timer.getFPS(), 10, 10)
	end
end

function love.mousemoved(_, _, x, y)
	cameraController:mousemoved(x, y)
end

function love.update(dt)
	cameraController:update(dt)
	
	--update resource loader
	dream:update()
	
	--update the physics
	world:update(dt)
	
	--accelerate
	local d = love.keyboard.isDown
	local ax, az = 0, 0
	if d("w") then
		ax = ax + math.cos(cameraController.ry - math.pi / 2)
		az = az + math.sin(cameraController.ry - math.pi / 2)
	end
	if d("s") then
		ax = ax + math.cos(cameraController.ry + math.pi - math.pi / 2)
		az = az + math.sin(cameraController.ry + math.pi - math.pi / 2)
	end
	if d("a") then
		ax = ax + math.cos(cameraController.ry - math.pi / 2 - math.pi / 2)
		az = az + math.sin(cameraController.ry - math.pi / 2 - math.pi / 2)
	end
	if d("d") then
		ax = ax + math.cos(cameraController.ry + math.pi / 2 - math.pi / 2)
		az = az + math.sin(cameraController.ry + math.pi / 2 - math.pi / 2)
	end
	local a = math.sqrt(ax ^ 2 + az ^ 2)
	if a > 0 then
		local v = player.collider:getVelocity()
		local maxSpeed = love.keyboard.isDown("lshift") and 15 or 3
		local accel = 10 * math.max(0, 1 - vec3(v.x, 0, v.z):length() / maxSpeed) / a
		player.collider:applyForce(ax * accel, az * accel)
	end
	
	if player.collider.touchedFloor and love.keyboard.isDown("space") then
		player.collider.ay = 5
	end
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
	
	if key == "m" then
		mapMesh = utils.map.createFromWorld(world)
	end
end

function love.resize()
	dream:init()
end