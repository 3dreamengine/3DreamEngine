--load the 3D lib
local dream = require("3DreamEngine")
love.window.setTitle("Physics Demo")
love.mouse.setRelativeMode(true)

--sun and environment
local sun = dream:newLight("sun")
sun:addShadow()

local sky = require("extensions/sky")
dream:setSky(sky.render)
sky:setDaytime(sun, 0.4)

dream:init()

--load materials
require("examples/Physics/materials")

--load objects
local objects = {
	scene = dream:loadScene("examples/Physics/objects/scene"),
	chicken = dream:loadObject("examples/Physics/objects/chicken", {
		callback = function(object)
			--we set the shader in the callback so it is initialized before cleanup
			--alternatively you could disable cleanup, then apply the shader
			object:setVertexShader("bones")
		end
	}),
	crate = dream:loadObject("examples/Physics/objects/crate")
}

--a helper class
local cameraController = require("extensions/utils/cameraController")

--some additional utils
local utils = require("extensions/utils")

---@type PhysicsExtension
local physics = require("extensions/physics/init")

--create a new world
local world = physics:newWorld()

--rotate into our space (blender is YZ flipped), create an object shape and add to the world
objects.scene:rotateX(-math.pi / 2)
world:add(physics:newObject(objects.scene))

--we use this util to render the map
local mapMesh = utils.map.createFromWorld(world)

--our objects, a composition of a object, a collider and it's initial transform
local gameObject = {  }
local function addObject(object, x, y, z, shape)
	local o = {
		object = object,
		collider = world:add(shape or physics:newObject(object), "dynamic", x, y, z), --newObject is slow, but required since our crates are random in size
		transform = object:getTransform()
	}
	table.insert(gameObject, o)
	return o
end

--create a chicken as our player
local player = addObject(objects.chicken, 0, 10, 0, physics:newCapsule(0.175, 0.5))

--add some crates
for _ = 1, 30 do
	objects.crate:resetTransform()
	objects.crate:scale(math.random() * 0.5 + 0.5)
	local collider = addObject(objects.crate, (math.random() - 0.5) * 10, 15, (math.random() - 0.5) * 10)
	collider.collider:setDensity(10)
end

function love.draw()
	--update camera
	cameraController:lookAt(dream.cam, player.collider:getPosition() + vec3(0, 0.4, 0), 1)
	
	dream:prepare()
	
	dream:addLight(sun)
	
	dream:draw(objects.scene)
	
	for _, o in ipairs(gameObject) do
		o.object:setTransform(o.transform)
		o.object:translateWorld(o.collider:getPosition())
		
		--if this is a chicken, animate it
		if o.object == objects.chicken then
			local v = o.collider:getVelocity()
			o.walkingAnim = (o.walkingAnim or 0) + love.timer.getDelta() * vec3(v.x, 0, v.z):length()
			o.avgVelocity = (o.avgVelocity or v) * (1 - love.timer.getDelta() * 5) + v * love.timer.getDelta() * 5
			o.object:applyPose(o.object.animations.Armature:getPose(o.walkingAnim))
			o.object:rotateY(math.atan2(o.avgVelocity.z, o.avgVelocity.x) - math.pi / 2)
			o.object:rotateX(-math.pi / 2) --blender space
			o.object:scale(1 / 20)
		else
			o.object:rotateY(o.collider:getBody():getAngle())
		end
		
		dream:draw(o.object)
	end
	
	dream:present()
	
	--map
	utils.map.draw(vec3(cameraController.x, cameraController.y, cameraController.z), mapMesh, love.graphics.getWidth() - 10 - 200, 10, 200, 200, 10)
	
	--stats
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(love.timer.getFPS(), 10, 10)
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
		--accelerate, but gradually slows down when reaching max speed
		local v = player.collider:getVelocity()
		ax = ax / a
		az = az / a
		local speed = vec3(v.x, 0, v.z):length()
		local maxSpeed = love.keyboard.isDown("lshift") and 6 or 3
		local dot = speed > 0 and (ax * v.x / speed + az * v.z / speed) or 0
		local accel = 1000 * math.max(0, 1 - speed / maxSpeed * math.abs(dot))
		player.collider:applyForce(ax * accel, 0, az * accel)
	end
	
	--jump
	if player.collider.touchedFloor and love.keyboard.isDown("space") then
		player.collider.ay = 5
	end
	
	--update map (slow)
	if love.keyboard.isDown("m") then
		mapMesh = utils.map.createFromWorld(world)
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
end

function love.resize()
	dream:init()
end