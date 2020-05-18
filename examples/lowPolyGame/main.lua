local projectDir = "examples/lowPolyGame/"

--load the 3D lib
dream = require("3DreamEngine")
collision = require("3DreamEngine/collision")
dream.lighting_engine = "Phong"
dream:init()

--setup sounds
local dir = (...):match("(.*/)")
local soundManager = require("3DreamEngine/soundManager")
soundManager:addLibrary("3DreamEngine/res/sounds", "collision")

--settings
love.window.setTitle("Low Poly Game")
love.mouse.setRelativeMode(true)

--load assets
local map = require(projectDir .. "map")
local objects = { }
local collisions = { }
for d,s in pairs(map.loader) do
	if not objects[d] then
		s.noCleanup = true
		s.skip3do = true
		objects[d] = dream:loadObject(d, s)
	end
end

--reconstruct matrices
for d,s in pairs(map.objects) do
	if s.transform then
		s.transform = mat4(s.transform)
	end
end

--bullet
objects.sphere = dream:loadObject(projectDir .. "models/sphere")
collisions.sphere = collision:newPoint()

--prepare lights
for d,s in pairs(map.lights) do
	s.light = dream:newLight(s.pos[1], s.pos[2], s.pos[3], s.color[1], s.color[2], s.color[3], s.brightness, s.meter)
	s.light.shadow = dream:newShadow(s.meter == 0 and "sun" or "point")
end

--player
player = {
	position = vec3(0, 10, 0),
	velocity = vec3(0, 0, 0),
	collision = {collision:newSphere(1, vec3(0, -1, 0))},
	rot = vec2(0, 0);
}

--bullets
bullets = { }

--setup collision and world
world = collision:newGroup()
for d,s in ipairs(map.objects) do
	--world:add(collision:newMesh(objects[s.path], s.subObject, s.transform * vec3(0, 0, 0)))
	world:add(collision:newMesh(objects[s.path], s.subObject, s.transform))
end

collision:print(world)

function love.draw()
	--update camera
	dream.cam:reset()
	dream.cam:translate(-player.position.x, -player.position.y, -player.position.z)
	dream.cam:rotateY(player.rot.y)
	dream.cam:rotateX(player.rot.x)
	
	--update listener
	love.audio.setPosition(player.position.x, player.position.y, player.position.z)
	
	--update lighting
	dream:resetLight()
	for d,s in ipairs(map.lights) do
		dream:addLight(s.light)
	end
	
	dream:prepare()
	
	--render map
	love.graphics.setColor(1, 1, 1)
	for d,s in ipairs(map.objects) do
		if s.subObject then
			objects[s.path].objects[s.subObject].transform = s.transform
			dream:draw(objects[s.path].objects[s.subObject])
		else
			objects[s.path].transform = s.transform
			dream:draw(objects[s.path])
		end
	end
	
	--render bullets
	for d,s in ipairs(bullets) do
		dream:draw(objects.sphere, s.position.x, s.position.y, s.position.z, 0.2)
	end
	
	dream:present()
end

function love.mousemoved(_, _, x, y)
	local speedH = 0.005
	local speedV = 0.005
	player.rot.y = player.rot.y - x * speedH
	player.rot.x = math.max(-math.pi/2, math.min(math.pi/2, player.rot.x + y * speedV))
end

function love.update(dt)
	dt = math.min(dt, 1/20)
	local d = love.keyboard.isDown
	
	--gravity
	player.velocity.y = player.velocity.y - 10 * dt
	
	--remember old position
	local onGround = false
	local oldVel = player.velocity:length()
	
	local old = player.position
	player.position = player.position + player.velocity * dt
	
	--collision check
	local normal
	for _,c in ipairs(player.collision) do
		c.initPos = c.initPos or c.transform:clone()
		c:moveTo(player.position + c.initPos)
		normal = collision:collide(c, world)
	end
	
	if normal then
		local final, impact = collision:calculateImpact(player.velocity, normal, 0.0, 0.0)
		if normal.y > 0.5 and player.velocity.y < 0.0 then
			onGround  = true
		end
		
		--retry with adjusted vectors
		player.position = old
		player.velocity = final
		
		local stepSize = 0.5
		for i = 0, 1, stepSize do
			old = player.position:clone()
			player.position = old + final * stepSize * dt
			
			local normal
			for _,c in ipairs(player.collision) do
				c.initPos = c.initPos or c.transform:clone()
				c:moveTo(player.position + c.initPos)
				normal = collision:collide(c, world)
				if normal then
					break
				end
			end
			
			if normal then
				player.position = old
				break
			else
				impact = 0
			end
		end
		
		--foot step sound
		if impact > 1 then
			soundManager:play("collision/glass_impact/" .. math.random(1, 7), player.position.x, player.position.y, player.position.z, math.sqrt(impact) / 10, 1)
		end
	end
	
	--jump
	if onGround then
		if d("space") then
			player.velocity = player.velocity + vec3(0, 8, 0)
		end
	end
	
	--movement
	local speed = 5
	local accel = (onGround and 10 or 2) * dt
	local curr = math.sqrt(player.velocity.x^2 + player.velocity.z^2)
	local old = player.velocity:clone()
	if d("w") then
		player.velocity.x = player.velocity.x + math.cos(-player.rot.y-math.pi/2) * speed
		player.velocity.z = player.velocity.z + math.sin(-player.rot.y-math.pi/2) * speed
	end
	if d("s") then
		player.velocity.x = player.velocity.x + math.cos(-player.rot.y+math.pi-math.pi/2) * speed
		player.velocity.z = player.velocity.z + math.sin(-player.rot.y+math.pi-math.pi/2) * speed
	end
	if d("a") then
		player.velocity.x = player.velocity.x + math.cos(-player.rot.y-math.pi/2-math.pi/2) * speed
		player.velocity.z = player.velocity.z + math.sin(-player.rot.y-math.pi/2-math.pi/2) * speed
	end
	if d("d") then
		player.velocity.x = player.velocity.x + math.cos(-player.rot.y+math.pi/2-math.pi/2) * speed
		player.velocity.z = player.velocity.z + math.sin(-player.rot.y+math.pi/2-math.pi/2) * speed
	end
	
	--max speed
	local f = math.min(1.0, math.max(speed, curr) / math.sqrt(player.velocity.x^2 + player.velocity.z^2))
	player.velocity.x = player.velocity.x * f
	player.velocity.z = player.velocity.z * f
	
	--friction
	if not d("w", "d", "a", "d") then
		local speed = player.velocity:length()
		local f = math.min(1, (5 + speed) * dt) * (onGround and 1.0 or 0.2)
		player.velocity.x = player.velocity.x - player.velocity.x * f
		player.velocity.z = player.velocity.z - player.velocity.z * f
	end
	
	--bullets
	for d,s in ipairs(bullets) do
		if not s.sleep or s.sleep < 3.0 then
			s.velocity.y = s.velocity.y - 10 * dt
			
			local old = s.position:clone()
			s.position = s.position + s.velocity * dt
			
			--collision
			local normal
			for _,c in ipairs(s.collision) do
				c.initPos = c.initPos or c.transform:clone()
				c:moveTo(s.position + c.initPos)
				normal = collision:collide(c, world)
			end
			
			if normal then
				local final, impact = collision:calculateImpact(s.velocity, normal, 0.75, 0.0)
				s.position = old
				s.velocity = final
				if impact > 1 then
					soundManager:play("collision/glass_impact/" .. math.random(1, 7), s.position.x, s.position.y, s.position.z, math.sqrt(impact) / 10, 1)
				end
			end
		end
		
		--start sleeping
		if s.velocity:lengthSquared() < 0.5 then
			s.sleep = (s.sleep or 0) + dt
		else
			s.sleep = false
		end
	end
	
	dream:update()
end

function love.mousepressed(x, y, b)
	bullets[#bullets+1] = {
		position = player.position:clone(),
		velocity = dream.cam.normal:clone() * 10,
		collision = {collision:newSphere(0.2)},
	}
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