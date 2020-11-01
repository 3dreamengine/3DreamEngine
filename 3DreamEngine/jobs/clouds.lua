local job = { }
local lib = _3DreamEngine

job.cost = 1

--random numbers with seed
local randoms = { }
local function random(i)
	randoms[i] = randoms[i] or math.random()
	return randoms[i]
end

local spritebatch
local quads = { }
for x = 0, 3 do
	for y = 0, 3 do
		quads[#quads+1] = love.graphics.newQuad(x, y, 1, 1, 4, 4)
	end
end

--add a cloud to the spritebatch, performs out of bounds check
local function addCloud(q, x, y, r, sx, ...)
	if x > -sx*0.5 and x < 1+sx*0.5 and y > -sx*0.5 and y < 1+sx*0.5 then
		spritebatch:add(q, x, y, r, sx, ...)
	end
end

function job:init()
	spritebatch = nil
	lib.cloudCanvas = love.graphics.newCanvas(lib.clouds_resolution, lib.clouds_resolution, {format = "r8"})
	lib.cloudCanvas:setWrap("repeat")
end

function job:queue(times)
	if lib.skyInUse then
		spritebatch = spritebatch or love.graphics.newSpriteBatch(lib.textures.clouds)
		lib:addOperation("clouds")
		lib.skyInUse = false
	end
end

function job:execute(times, delta)
	local size = lib.weather_rain^2 + 0.2
	local amount = lib.clouds_amount
	
	lib.clouds_pos = lib.clouds_pos + lib.clouds_wind * delta
	
	--add clouds
	local t = love.timer.getTime() * lib.clouds_anim_size
	spritebatch:clear()
	for i = 1, amount do
		local q = quads[i % 16 + 1]
		local sz = (random(i) + love.math.noise(i, t)) * (1.0 - lib.weather_temperature * i / amount) * 0.5
		local wp = lib.clouds_pos * (random(i + 17)-0.5) * lib.clouds_anim_position
		local x, y = (random(i + 7) + wp.x) % 1, (random(i + 127) + wp.y) % 1
		local r = lib.clouds_rotations and (random(i + 27) * math.pi * 2) or 0
		local brightness = 0.25 + random(i + 47) * 0.5
		
		spritebatch:setColor(brightness, brightness, brightness)
		addCloud(q, x+0.5, y+0.5, r, sz * size, nil, 0.5, 0.5)
		addCloud(q, x-0.5, y+0.5, r, sz * size, nil, 0.5, 0.5)
		addCloud(q, x+0.5, y-0.5, r, sz * size, nil, 0.5, 0.5)
		addCloud(q, x-0.5, y-0.5, r, sz * size, nil, 0.5, 0.5)
	end
	
	--render
	love.graphics.push("all")
	love.graphics.setColor(1, 1, 1)
	love.graphics.setCanvas(lib.cloudCanvas)
	love.graphics.clear(0, 0, 0, 1)
	love.graphics.setBlendMode("screen", "premultiplied")
	love.graphics.scale(lib.cloudCanvas:getWidth(), lib.cloudCanvas:getWidth())
	love.graphics.draw(spritebatch)
	love.graphics.pop()
end

return job