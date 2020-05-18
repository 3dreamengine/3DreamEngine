--[[
#part of the 3DreamEngine by Luke100000
functions.lua - contains library relevant functions
--]]

local lib = _3DreamEngine

function lib.newCam(self)
	local c = {
		transform = mat4:getIdentity(),
		
		normal = vec3(0, 0, 0),
		
		x = 0,
		y = 0,
		z = 0,
		
		fov = 90,
		near = 0.01,
		far = 1000,
	}
	
	setmetatable(c, self.operations)
	
	return c
end

function lib.newReflection(self, static, priority)
	local canvas = love.graphics.newCanvas(self.reflections_resolution, self.reflections_resolution,
		{format = self.reflections_format, readable = true, msaa = 0, type = "cube", mipmaps = "manual"})
	
	return {
		canvas = canvas,
		static = static or false,
		priority = priority or 1.0,
		lastUpdate = 0,
	}
end

function lib.newShadowCanvas(self, typ, res)
	if typ == "sun" then
		local canvas = love.graphics.newCanvas(res, res,
			{format = "depth16", readable = true, msaa = 0, type = "2d"})
		
		canvas:setDepthSampleMode("greater")
		canvas:setFilter("linear", "linear", 1)
		
		return canvas
	elseif typ == "point" then
		local canvas = love.graphics.newCanvas(res, res,
			{format = "r16f", readable = true, msaa = 0, type = "cube"})
		return canvas
	end
end

function lib.newShadow(self, typ, static, res)
	if typ == "point" then
		res = res or self.shadow_cube_resolution
	else
		res = res or self.shadow_resolution
	end
	
	return {
		typ = typ,
		levels = 3,
		res = res,
		static = static or false,
		priority = 1.0,
		lastUpdate = 0,
		size = 0.1,
		lastPos = vec3(0, 0, 0)
	}
end

local lightMetaTable = {
	setBrightness = function(self, brightness)
		self.brightness = brightness
	end,
	setColor = function(self, r, g, b)
		if type(r) == "table" then
			r, g, b = r[1], r[2], r[3]
		end
		local v = math.sqrt(r^2+g^2+b^2)
		self.r = r / v
		self.g = g / v
		self.b = b / v
	end,
	setPosition = function(self, x, y, z)
		if type(x) == "table" then
			x, y, z = x[1], x[2], x[3]
		end
		self.x = x
		self.y = y
		self.z = z
	end,
	setMeter = function(self, meter)
		self.meter = meter
	end,
}

function lib.newLight(self, posX, posY, posZ, r, g, b, brightness, meter)
	r = r or 1.0
	g = g or 1.0
	b = b or 1.0
	local v = math.sqrt(r^2 + g^2 + b^2)
	
	local l = {
		x = posX or 0,
		y = posY or 0,
		z = posZ or 0,
		r = r / v,
		g = g / v,
		b = b / v,
		brightness = brightness or 1.0,
		meter = meter or 1.0,
	}
	
	return setmetatable(l, {__index = lightMetaTable})
end

function lib.resetLight(self, noDayLight)
	self.lighting = { }
	
	if not noDayLight then
		local l = self.sun:normalize()
		local c = self.sun_color
		
		self.sunObject.x = l[1]
		self.sunObject.y = l[2]
		self.sunObject.z = l[3]
		self.sunObject.r = c[1]
		self.sunObject.g = c[2]
		self.sunObject.b = c[3]
		
		self:addLight(self.sunObject)
	end
end

function lib.addLight(self, light)
	self.lighting[#self.lighting+1] = light
end

function lib.addNewLight(self, ...)
	self:addLight(self:newLight(...))
end

lib.operations = { }
lib.operations.__index = lib.operations

function lib.operations.reset(obj)
	obj.transform = mat4:getIdentity()
	return obj
end

function lib.operations.translate(obj, x, y, z)
	obj.transform = obj.transform:translate(x, y, z)
	return obj
end

function lib.operations.scale(obj, x, y, z)
	obj.transform = obj.transform:scale(x, y, z)
	return obj
end

function lib.operations.rotateX(obj, rx)
	obj.transform = obj.transform:rotateX(rx)
	return obj
end

function lib.operations.rotateY(obj, ry)
	obj.transform = obj.transform:rotateY(ry)
	return obj
end

function lib.operations.rotateZ(obj, rz)
	obj.transform = obj.transform:rotateZ(rz)
	return obj
end

function lib.split(self, text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function lib.rotatePoint(self, x, y, rot)
	local c = math.cos(rot)
	local s = math.sin(rot)
	return x * c - y * s, x * s + y * c
end

function lib.lookAt(self, eye, at, up)
	up = up or vec3(0.0, 1.0, 0.0)
	
	zaxis = (at - eye):normalize()
	xaxis = zaxis:cross(up):normalize()
	yaxis = xaxis:cross(zaxis)

	zaxis = -zaxis
	
	return mat4(
		xaxis.x, xaxis.y, xaxis.z, -xaxis:dot(eye),
		yaxis.x, yaxis.y, yaxis.z, -yaxis:dot(eye),
		zaxis.x, zaxis.y, zaxis.z, -zaxis:dot(eye),
		0, 0, 0, 1
	)
end

--add tangents to a 3Dream vertex format
--x, y, z, shaderData, nx, ny, nz, materialID, u, v, tx, ty, tz, btx, bty, btz
function lib.calcTangents(self, finals, vertexMap)
	--expand uv if missing
	for d,f in ipairs(finals) do
		f[9] = f[9] or 0
		f[10] = f[10] or 0
		
		f[11] = 0
		f[12] = 0
		f[13] = 0
		f[14] = 0
		f[15] = 0
		f[16] = 0
	end
	
	--9-10 UV
	--5-7 Normal
	
	for f = 1, #vertexMap, 3 do
		local P1 = finals[vertexMap[f+0]]
		local P2 = finals[vertexMap[f+1]]
		local P3 = finals[vertexMap[f+2]]
		
		local tangent = { }
		local bitangent = { }
		
		local edge1 = {P2[1] - P1[1], P2[2] - P1[2], P2[3] - P1[3]}
		local edge2 = {P3[1] - P1[1], P3[2] - P1[2], P3[3] - P1[3]}
		local edge1uv = {P2[9] - P1[9], P2[10] - P1[10]}
		local edge2uv = {P3[9] - P1[9], P3[10] - P1[10]}
		
		local cp = edge1uv[1] * edge2uv[2] - edge1uv[2] * edge2uv[1]
		
		if cp ~= 0.0 then
			for i = 1, 3 do
				tangent[i] = (edge1[i] * edge2uv[2] - edge2[i] * edge1uv[2]) / cp
				bitangent[i] = (edge1[i] * edge2uv[1] - edge2[i] * edge1uv[1]) / cp
			end
			
			for i = 1, 3 do
				finals[vertexMap[f+i-1]][11] = finals[vertexMap[f+i-1]][11] + tangent[1]
				finals[vertexMap[f+i-1]][12] = finals[vertexMap[f+i-1]][12] + tangent[2]
				finals[vertexMap[f+i-1]][13] = finals[vertexMap[f+i-1]][13] + tangent[3]
				
				finals[vertexMap[f+i-1]][14] = finals[vertexMap[f+i-1]][14] + bitangent[1]
				finals[vertexMap[f+i-1]][15] = finals[vertexMap[f+i-1]][15] + bitangent[2]
				finals[vertexMap[f+i-1]][16] = finals[vertexMap[f+i-1]][16] + bitangent[3]
			end
		end
	end
	
	--normalize
	for d,f in ipairs(finals) do
		local o = 10
		local l = math.sqrt(f[1+o]^2 + f[2+o]^2 + f[3+o]^2)
		f[1+o] = f[1+o] / l
		f[2+o] = f[2+o] / l
		f[3+o] = f[3+o] / l
		
		local o = 13
		local l = math.sqrt(f[1+o]^2 + f[2+o]^2 + f[3+o]^2)
		f[1+o] = f[1+o] / l
		f[2+o] = f[2+o] / l
		f[3+o] = f[3+o] / l
	end	
	
	--complete smoothing step
	for d,f in ipairs(finals) do
		--Gram-Schmidt orthogonalization
		local dot = (f[11] * f[5] + f[12] * f[6] + f[13] * f[7])
		f[11] = f[11] - f[5] * dot
		f[12] = f[12] - f[6] * dot
		f[13] = f[13] - f[7] * dot
		
		local l = math.sqrt(f[11]^2 + f[12]^2 + f[13]^2)
		f[11] = f[11] / l
		f[12] = f[12] / l
		f[13] = f[13] / l
	end
end

function lib.HSVtoRGB(self, h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	
	if i % 6 == 0 then
		return v, t, p
	elseif i % 6 == 1 then
		return q, v, p
	elseif i % 6 == 2 then
		return p, v, t
	elseif i % 6 == 3 then
		return p, q, v
	elseif i % 6 == 4 then
		return t, p, v
	else
		return v, p, q
	end
end

function lib.RGBtoHSV(self, r, g, b)
	local h, s, v
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)

	local v = max
	local delta = max - min
	if max ~= 0 then
		s = delta / max
	else
		r, g, b = 0, 0, 0
		s = 0
		h = -1
		return h, s, 0.0
	end
	
	if r == max then
		h = (g - b) / delta
	elseif g == max then
		h = 2 + (b - r) / delta
	else
		h = 4 + (r - g) / delta
	end
	
	h = h * 60 / 360
	if h < 0 then
		h = h + 1
	elseif delta == 0 then
		h = 0
	end
	
	return h, s, v
end

function lib.decodeObjectName(self, name)
	if self.nameDecoder == "blender" then
		local last, f = 0, false
		while last and string.find(name, "_", last+1) do
			f, last = string.find(name, "_", last+1)
		end
		return name:sub(1, f and (f-1) or #name)
	else
		return name
	end
end

function lib.transformPoint(self, p, cam, canvases)
	cam = cam or self.cam
	canvases = canvases or self.canvases
	
	local transformProj = cam.transformProj
	
	local p = transformProj * vec4(p[1], p[2], p[3], 1.0)
	p = p / vec4(math.max(self.cam.near, p[4]), math.max(self.cam.near, p[4]), 1.0, 1.0)
	
	return vec2((p[1]+1) * canvases.width/2, (p[2]+1) * canvases.height/2), p
end

function lib.setDaytime(self, time)
	--time, 0.0 is sunrise, 0.5 is sunset
	self.sky_time = time % 1.0
	self.sky_day = math.floor(time % 30.0)
	
	--position
	self.sun = mat4:getRotateZ(self.sun_offset) * vec3(
		0,
		math.sin(self.sky_time * math.pi * 2),
		-math.cos(self.sky_time * math.pi * 2)
	):normalize()
	
	local c = #self.sunlight
	local p = self.sky_time * c
	self.sun_color = (
		self.sunlight[math.max(1, math.min(c, math.ceil(p)))] * (1.0 - p % 1) +
		self.sunlight[math.max(1, math.min(c, math.ceil(p+1)))] * (p % 1)
	)
end

--0 is the happiest day ever and 1 the end of the world
function lib.setWeather(self, rain, temp)
	rain = rain or 0.0
	temp = temp or (1.0 - rain)
	
	--blue-darken ambient and sun color
	local color = rain * 0.75
	self.sun_color = vec3(0, 50/255, 80/255) * color + self.sun_color * (1.0 - color)
	self.sun_ambient = vec3(0, 50/255, 80/255) * color + self.sun_ambient * (1.0 - color)
	self.sky_color = vec3(0, 50/255, 80/255) * color + vec3(1.0, 1.0, 1.0) * (1.0 - color)
	
	self.clouds_scale = 4.0
	self.clouds_threshold = math.mix(0.6, 0.2, rain * (1.0 - temp * 0.5))
	self.clouds_thresholdPackets = math.mix(0.6, 0.1, temp)
	self.clouds_sharpness = math.mix(0.1, 0.2, temp)
	self.clouds_detail = 0.0
	self.clouds_packets = math.mix(0.1, 0.6, temp * (1.0 - rain))
	self.clouds_weight = math.mix(math.mix(1.0, 1.5, temp), 0.75, rain)
	self.clouds_thickness = math.mix(0.0, 0.4, rain^2)
	
	self.rain_isRaining = rain > 0.4
	self.rain_strength = math.ceil(math.clamp((rain-0.4) / 0.6 * 5.0, 0.001, 5.0))
end