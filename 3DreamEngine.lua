--[[
#3DreamEngine - 3D library by Luke100000
loads simple .obj files
supports obj atlas (see usage)
renders models using flat shading
supports ambient occlusion and fog


#Copyright 2019 Luke100000
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#usage
--load the matrix and the 3D lib
matrix = require("matrix")
l3d = require("3DreamEngine")

--settings
l3d.flat = true				--flat shading or textured? (not implemented yet)
l3d.objectDir = "objects/"	--root directory of objects
lib.pathToNoiseTex = "noise.png"	--path to noise texture

l3d.AO_enabled = true		--ambient occlusion?
l3d.AO_quality = 24			--samples per pixel (8-32 recommended)
l3d.AO_quality_smooth = 1	--smoothing steps, 1 or 2 recommended, lower quality (< 12) usually requires 2 steps
l3d.AO_resolution = 0.5		--resolution factor

--inits (applies settings)
l3d:init()

--loads a object
yourObject = l3d:loadObject("objectName")

--prepare for rendering
--if cam is nil, it uses the default cam (l3d.cam)
--noDepth disables the depth buffer
l3d:prepare(cam, noDepth)

--draw
l3d:draw(model, x, y, z, sx, sy, sz, rot, tilt)

--finish render session, it is possible to render several times per frame
l3d:present()

--update camera postion
lib.cam = {x = 0, y = 0, z = 0, rot = 0, tilt = 0}

--update sun position
lib.sun = {0.3, -0.6, -0.5}

--update sun color
lib.color_ambient = {0.25, 0.25, 0.25}
lib.color_sun = {1.5, 1.5, 1.5}
--]]

local lib = { }

lib.cam = {x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, normal = {0, 0, 0}}
lib.sun = {0.3, -0.6, -0.5}

lib.color_ambient = {0.25, 0.25, 0.25}
lib.color_sun = {1.5, 1.5, 1.5}

--no textures, textures not fully working yet
lib.flat = true

--root directory of objects
lib.objectDir = "objects/"
lib.pathToNoiseTex = "noise.png"

--settings
lib.AO_enabled = true
lib.AO_quality = 24
lib.AO_quality_smooth = 1
lib.AO_resolution = 0.5

function lib.resize(self, w, h)
	local msaa = 4
	self.canvas = love.graphics.newCanvas(w, h, {format = "normal", readable = true, msaa = msaa})
	self.canvas_depth = love.graphics.newCanvas(w, h, {format = "depth16", readable = false, msaa = msaa})
	if self.AO_enabled then
		self.canvas_z = love.graphics.newCanvas(w, h, {format = "r16f", readable = true, msaa = msaa})
		self.canvas_blur_1 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
		self.canvas_blur_2 = love.graphics.newCanvas(w*self.AO_resolution, h*self.AO_resolution, {format = "r8", readable = true, msaa = 0})
	end
end

function lib.split(self, text, sep)
	local sep, fields = sep or ":", { }
	local pattern = string.format("([^%s]+)", sep)
	text:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function lib.init(self)
	self:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function lib.loadObject(self, name, splitMargin)
	local obj = {objects = splitMargin and { } or nil}
	
	--store vertices, normals and texture coordinates
	local vertices = { }
	local normals = { }
	local texVertices = { }
	
	--store final vertices (vertex, normal and texCoord index)
	obj.final = { }
	
	--store final faces, 3 final indices
	obj.faces = { }
	
	--materials
	local materials = { }
	local mat
	for l in love.filesystem.lines(self.objectDir .. name .. ".mtl") do
		local v = self:split(l, " ")
		if v[1] == "newmtl" then
			materials[v[2]] = {
				color = {1.0, 1.0, 1.0, 1.0},
				specular = 0.5,
			}
			mat = materials[v[2]]
		elseif v[1] == "Ks" then
			mat.specular = tonumber(v[2])
		elseif v[1] == "Kd" then
			mat.color[1] = tonumber(v[2])
			mat.color[2] = tonumber(v[3])
			mat.color[3] = tonumber(v[4])
		elseif v[1] == "d" then
			mat.color[4] = tonumber(v[2])
		end
	end
	
	--load object
	local material
	local blocked = false
	for l in love.filesystem.lines(self.objectDir .. name .. ".obj") do
		local v = self:split(l, " ")
		if not blocked then
			if v[1] == "v" then
				vertices[#vertices+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vn" then
				normals[#normals+1] = {tonumber(v[2]), tonumber(v[3]), -tonumber(v[4])}
			elseif v[1] == "vt" then
				texVertices[#texVertices+1] = {tonumber(v[2]), tonumber(v[3])}
			elseif v[1] == "usemtl" then
				material = v[2]
			elseif v[1] == "f" then
				local o
				if splitMargin then
					--split object, where 0|0|0 is the left-front-lower corner of the first object and every splitMargin is a new object with size 1.
					--So each object must be within -margin to splitMargin-margin, a perfect cube will be 0|0|0 to 1|1|1
					local objSize = 1
					local margin = (splitMargin-objSize)/2
					local v2 = self:split(v[2], "/")
					local x, y, z = vertices[tonumber(v2[1])][1], vertices[tonumber(v2[1])][2], vertices[tonumber(v2[1])][3]
					local tx, ty, tz = math.floor((x+margin)/splitMargin)+1, math.floor((z+margin)/splitMargin)+1, math.floor((-y-margin)/splitMargin)+2
					if not obj.objects[tx] then obj.objects[tx] = { } end
					if not obj.objects[tx][ty] then obj.objects[tx][ty] = { } end
					if not obj.objects[tx][ty][tz] then obj.objects[tx][ty][tz] = {faces = { }, final = { }} end
					o = obj.objects[tx][ty][tz]
					o.tx = math.floor((x+margin)/splitMargin)*splitMargin + objSize/2
					o.ty = math.floor((y+margin)/splitMargin)*splitMargin + objSize/2
					o.tz = math.floor((z+margin)/splitMargin)*splitMargin + objSize/2
					--print(tx, ty, tz, "|" .. x, y, z, "|" .. x - o.tx, y - o.ty, z - o.tz)
				else
					o = obj
				end
				
				--combine vertex and data into one
				for i = 1, #v-1 do
					local v2 = self:split(v[i+1], "/")
					o.final[#o.final+1] = {vertices[tonumber(v2[1])], texVertices[tonumber(v2[2])], normals[tonumber(v2[3])], materials[material]}
				end
				
				if #v-1 == 3 then
					--tris
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-2}
				elseif #v-1 == 4 then
					--quad
					o.faces[#o.faces+1] = {#o.final-1, #o.final-2, #o.final-3}
					o.faces[#o.faces+1] = {#o.final-0, #o.final-1, #o.final-3}
				else
					error("only tris and quads supported (got " .. (#v-1) .. " vertices)")
				end
			end
		end
		
		if v[1] == "o" then
			if l:find("frame") then
				blocked = true
			else
				blocked = false
			end
		end
	end
	
	--fill mesh
	if splitMargin then
		for x, dx in pairs(obj.objects) do
			for y, dy in pairs(dx) do
				for z, dz in pairs(dy) do
					--move sub objects
					for i,v in ipairs(dz.final) do
						if not v[1][4] then
							v[1][1] = v[1][1] - (dz.tx or 0)
							v[1][2] = v[1][2] - (dz.ty or 0)
							v[1][3] = v[1][3] - (dz.tz or 0)
							v[1][4] = true
						end
					end
					for i,v in ipairs(dz.final) do
						v[1][4] = nil
					end
					self:createMesh(dz, obj)
				end
			end
		end
	else
		self:createMesh(obj, obj)
	end
	
	return obj
end

--takes an final and face object and a base object and generates the mesh and vertexMap
function lib.createMesh(self, o, obj, faceMap)
	local atypes
	if self.flat then
		atypes = {
		  {"VertexPosition", "float", 3},	-- x, y, z
		  {"VertexTexCoord", "float", 4},	-- normal, specular
		  {"VertexColor", "float", 4},		-- color
		}
	else
		atypes = {
		  {"VertexPosition", "float", 3},	-- x, y, z
		  {"VertexTexCoord", "float", 2},	-- UV
		  {"VertexColor", "float", 3},		-- normal
		}
	end
	
	--compress finals (not all used)
	local vertexMap = { }
	local final = { }
	local finalIDs = { }
	if faceMap then
		for d,f in ipairs(faceMap) do
			finalIDs = { }
			for i = 1, 3 do
				if not finalIDs[f[1][i]] then
					local fc = f[2][f[1][i]]
					local x, z = self:rotatePoint(fc[1][1], fc[1][3], -f[6])
					local nx, nz = self:rotatePoint(fc[3][1], fc[3][3], -f[6])
					final[#final+1] = {{x + f[3], fc[1][2] + f[4], z + f[5]}, fc[2], {nx, fc[3][2], nz}, fc[4]}
					finalIDs[f[1][i]] = #final
				end
				vertexMap[#vertexMap+1] = finalIDs[f[1][i]]
			end
		end
	else
		for d,f in ipairs(o.faces) do
			for i = 1, 3 do
				if not finalIDs[f[i]] then
					final[#final+1] = o.final[f[i]]
					finalIDs[f[i]] = #final
				end
				vertexMap[#vertexMap+1] = finalIDs[f[i]]
			end
		end
	end
	
	--create mesh
	o.mesh = love.graphics.newMesh(atypes, #final, "triangles", "static")
	for d,s in ipairs(final) do
		vertexMap[#vertexMap+1] = s[i]
		local p = s[1]
		local t = s[2]
		local n = s[3]
		local m = s[4]
		if self.flat then
			o.mesh:setVertex(d,
				p[1], p[2], p[3],
				n[1]*0.5+0.5, n[2]*0.5+0.5, n[3]*0.5+0.5,
				m.specular,
				m.color[1], m.color[2], m.color[3], m.color[4]
			)
		else
			--not working yet
			--o.mesh:setVertex(d, p[1], p[2], p[3], t[1], t[2], n[1]*0.5+0.5, n[3]*0.5+0.5, -n[2]*0.5+0.5)
		end
	end
	
	--vertex map
	o.mesh:setVertexMap(vertexMap)
end

function lib.rotatePoint(self, x, y, rot)
	local c = math.cos(rot)
	local s = math.sin(rot)
	return x * c - y * s, x * s + y * c
end

--creates a triangle mesh based on position/color/specular (x, y, z, [r, g, b, spec]) points
function lib.loadCustomObject(self, vertices)
	local o = { }
	
	o.vertices = vertices
	for i = 1, #vertices/3 do
		local v1 = vertices[(i-1)*3 + 1]
		local v2 = vertices[(i-1)*3 + 2]
		local v3 = vertices[(i-1)*3 + 3]
		
		local a = {v1[1] - v2[1], v1[2] - v2[2], v1[3] - v2[3]}
		local b = {v1[1] - v3[1], v1[2] - v3[2], v1[3] - v3[3]}
		
		local n = {
			(a[2]*b[3] - a[3]*b[2]),
			(a[3]*b[1] - a[1]*b[3]),
			(a[1]*b[2] - a[2]*b[1]),
		}
		
		local l = math.sqrt(n[1]^2+n[2]^2+n[3]^2)
		n[1] = n[1] / l
		n[2] = n[2] / l
		n[3] = n[3] / l
		
		v1[8] = n[1]
		v1[9] = n[2]
		v1[10] = n[3]
		
		v2[8] = n[1]
		v2[9] = n[2]
		v2[10] = n[3]
		
		v3[8] = n[1]
		v3[9] = n[2]
		v3[10] = n[3]
	end
	
	local atypes = {
		{"VertexPosition", "float", 3},	-- x, y, z
		{"VertexTexCoord", "float", 4},	-- normal, specular
		{"VertexColor", "float", 4},	-- color
	}
	
	--fill mesh
	local lastMaterial
	o.mesh = love.graphics.newMesh(atypes, #vertices, "triangles", "static")
	for d,s in ipairs(vertices) do
		o.mesh:setVertex(d,
			s[1], s[2], s[3],
			s[8]*0.5+0.5, s[9]*0.5+0.5, s[10]*0.5+0.5,
			s[7] or 0.5,
			s[4], s[5], s[6], 1.0
		)
	end
	
	return o
end

--default shader
lib.shader = love.graphics.newShader([[
    varying float depth;
	
	#ifdef PIXEL
	void effect() {
		love_Canvases[0] = VaryingColor;
		love_Canvases[1] = vec4(depth, 0.0, 0.0, 1.0);
	}
	#endif
	
    #ifdef VERTEX
	extern mat4 cam;
	extern vec3 camV;
	extern mat4 transform;
	extern vec3 sun;
	extern vec4 sunColor;
	extern vec4 ambient;
	extern mat3 rotate;
	
    vec4 position(mat4 transform_projection, vec4 vertex_position) {
		vec4 pos = (vertex_position * transform);
		
		vec3 normal = (VertexTexCoord.rgb - vec3(0.5)) * 2.0 * rotate;
		float dotSunNormal = dot(sun, normal);
		float angle = max(0, dotSunNormal);
		
		vec3 reflection = normalize(sun - 2 * dotSunNormal * normal);
		float reflectionAngle = max(0, dot(normalize(pos.xyz - camV), reflection) * VertexTexCoord.a * 4.0 - VertexTexCoord.a * 2.0) * VertexTexCoord.a * 2.0;
		
		float power = (angle * (1.0 - VertexTexCoord.a * 0.5) + reflectionAngle * VertexTexCoord.a) * 1.0;
		
		VaryingColor = VertexColor * (ambient + sunColor * power);
		
		if (angle > -100.0) {
			//VaryingColor = vec4(normal*0.5+0.5, 1.0);
		}
		
		vec4 vPos = cam * pos * vec4(1, -1, 1, 1);
		depth = vPos.z;
		return vPos + vec4(0, 0, 0.75, 0);
    }
    #endif
]])

--blur
lib.blur = love.graphics.newShader([[
	extern vec2 size;
	extern float hstep;
	extern float vstep;

	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		vec4 sum = vec4(0.0);
		
		sum += Texel(texture, tc - vec2(4.0*hstep, 4.0*vstep) * size) * 0.0162162162;
		sum += Texel(texture, tc - vec2(3.0*hstep, 3.0*vstep) * size) * 0.0540540541;
		sum += Texel(texture, tc - vec2(2.0*hstep, 2.0*vstep) * size) * 0.1216216216;
		sum += Texel(texture, tc - vec2(1.0*hstep, 1.0*vstep) * size) * 0.1945945946;
		
		sum += Texel(texture, tc) * 0.2270270270;
		
		sum += Texel(texture, tc + vec2(1.0*hstep, tc.y + 1.0*vstep) * size) * 0.1945945946;
		sum += Texel(texture, tc + vec2(2.0*hstep, tc.y + 2.0*vstep) * size) * 0.1216216216;
		sum += Texel(texture, tc + vec2(3.0*hstep, tc.y + 3.0*vstep) * size) * 0.0540540541;
		sum += Texel(texture, tc + vec2(4.0*hstep, tc.y + 4.0*vstep) * size) * 0.0162162162;
		
		return sum;
	}
]])

lib.post = love.graphics.newShader([[
	extern Image depth;
	extern Image AO;
	extern float fog;
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float AOv = 0.6 + Texel(AO, tc).r * 0.4;
		float depth = min(1.0, Texel(depth, tc).r * fog);
		return (Texel(texture, tc) * vec4(AOv, AOv, AOv, 1.0)) * (1.0-depth) + vec4(0.5, 0.5, 0.5, 1.0) * depth;
	}
]])

--AO shader
lib.AO = love.graphics.newShader([[
	extern vec2 size;
	extern vec3 samples[]] .. lib.AO_quality .. [[];
	extern Image noise;
	extern vec2 noiseOffset;
	int sampleCount = ]] .. lib.AO_quality .. [[;
	
	vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
		float sum = 0;
		
		float z = Texel(texture, tc).r;
		vec2 offset = (Texel(noise, tc * 64.0 + noiseOffset).xy - vec2(0.5)) * 0.01;
		for (int i = 0; i < sampleCount; i++) {
			float r = Texel(texture, tc + samples[i].xy / (0.25+z*0.05) + offset).r;
			if (z - r > samples[i].z) {
				sum ++;
			}
		}
		
		sum = 1.0 - min(1, sum / sampleCount * 2.0 - 1.0);
		return vec4(sum, sum, sum, 1.0);
	}
]])

local t = love.graphics.newImage(lib.pathToNoiseTex)
t:setWrap("repeat", "repeat")
lib.AO:send("noise", t)

local f = { }
for i = 1, lib.AO_quality do
	f[#f+1] = {(math.random()-0.5) * 32 / love.graphics.getWidth(), (math.random()-0.5) * 32 / love.graphics.getHeight(), (math.random()-0.5) * 0.25}
end
lib.AO:send("samples", unpack(f))

function lib.prepare(self, c, noDepth)
	if self.AO_enabled then
		love.graphics.setCanvas({self.canvas, self.canvas_z, depthstencil = self.canvas_depth})
	else
		love.graphics.setCanvas({self.canvas, depthstencil = self.canvas_depth})
	end
	love.graphics.clear()
	
	love.graphics.setShader(self.shader)
	if not noDepth then
		love.graphics.setDepthMode("less", true)
	end
	
	self.shader:send("ambient", {self.color_ambient[1], self.color_ambient[2], self.color_ambient[3], 1.0})
	self.shader:send("sunColor", {self.color_sun[1], self.color_sun[2], self.color_sun[3], 1.0})
	
	local cam = c == false and {x = 0, y = 0, z = 0, tilt = 0, rot = 0} or c or self.cam
	
	local sun = {math.cos(love.timer.getTime()), 0.3, math.sin(love.timer.getTime())}
	local sun = {-self.sun[1], -self.sun[2], -self.sun[3]}
	local l = math.sqrt(sun[1]^2 + sun[2]^2 + sun[3]^2)
	sun[1] = sun[1] / l
	sun[2] = sun[2] / l
	sun[3] = sun[3] / l
	self.shader:send("sun", sun)
	
	self.shader:send("camV", {cam.x, cam.y, cam.z})
	
	local c = math.cos(cam.rz or 0)
	local s = math.sin(cam.rz or 0)
	local rotZ = matrix{
		{c, s, 0, 0},
		{-s, c, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(cam.ry or 0)
	local s = math.sin(cam.ry or 0)
	local rotY = matrix{
		{c, 0, -s, 0},
		{0, 1, 0, 0},
		{s, 0, c, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(cam.rx or 0)
	local s = math.sin(cam.rx or 0)
	local rotX = matrix{
		{1, 0, 0, 0},
		{0, c, -s, 0},
		{0, s, c, 0},
		{0, 0, 0, 1},
	}
	
	local n = 1
	local f = 10
	local fov = 90
	local S = 1 / (math.tan(fov/2*math.pi/180))
	
	local projection = matrix{
		{S,	0,	0,	0},
		{0,	S/600*800,	0,	0},
		{0,	0,	-(f/(f-n)),	-1},
		{0,	0,	-(f*n)/(f-n),	0},
	}
	
	local translate = matrix{
		{1, 0, 0, -cam.x},
		{0, 1, 0, -cam.y},
		{0, 0, 1, -cam.z},
		{0, 0, 0, 1},
	}
	
	local res = projection * rotZ * rotX * rotY * translate
	self.shader:send("cam", res)
	
	--camera normal
	local normal = rotY * rotX * (matrix{{0, 0, 1, 0}}^"T")
	cam.normal = {normal[1][1], normal[2][1], -normal[3][1]}
end

function lib.draw(self, obj, x, y, z, sx, sy, sz, rx, ry, rz)
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	local rotZ = matrix{
		{c, s, 0, 0},
		{-s, c, 0, 0},
		{0, 0, 1, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	local rotY = matrix{
		{c, 0, -s, 0},
		{0, 1, 0, 0},
		{s, 0, c, 0},
		{0, 0, 0, 1},
	}
	
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	local rotX = matrix{
		{1, 0, 0, 0},
		{0, c, -s, 0},
		{0, s, c, 0},
		{0, 0, 0, 1},
	}
	
	local translate = matrix{
		{sx or 1, 0, 0, 0},
		{0, sy or sx or 1, 0, 0},
		{0, 0, sz or sx or 1, 0},
		{x, y, z, 1},
	}
	
	--self.shader:send("rot", rotX)
	self.shader:send("transform", rotZ*rotY*rotX*translate)
	
	local c = math.cos(rz or 0)
	local s = math.sin(rz or 0)
	local rotZ3 = matrix{
		{c, s, 0},
		{-s, c, 0},
		{0, 0, 1},
	}
	
	local c = math.cos(ry or 0)
	local s = math.sin(ry or 0)
	local rotY3 = matrix{
		{c, 0, -s},
		{0, 1, 0},
		{s, 0, c},
	}
	
	local c = math.cos(rx or 0)
	local s = math.sin(rx or 0)
	local rotX3 = matrix{
		{1, 0, 0},
		{0, c, -s},
		{0, s, c},
	}
	self.shader:send("rotate", rotZ3*rotY3*rotX3)
	
	love.graphics.draw(obj.mesh)
end

function lib.present(self)
	love.graphics.setDepthMode()
	love.graphics.origin()
	
	if self.AO_enabled then
		love.graphics.setBlendMode("replace", "premultiplied")
		love.graphics.setCanvas(self.canvas_blur_1)
		love.graphics.clear()
		love.graphics.setShader(lib.AO)
		lib.AO:send("noiseOffset", {self.cam.ry, self.cam.rz})
		love.graphics.draw(self.canvas_z, 0, 0, 0, self.AO_resolution)
		love.graphics.setShader(self.blur)
		self.blur:send("size", {1/self.canvas_blur_1:getWidth(), 1/self.canvas_blur_1:getHeight()})
		
		for i = 1, self.AO_quality_smooth do
			self.blur:send("vstep", 1.0)
			self.blur:send("hstep", 0.0)
			love.graphics.setCanvas(self.canvas_blur_2)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_1)
			
			self.blur:send("vstep", 0.0)
			self.blur:send("hstep", 1.0)
			love.graphics.setCanvas(self.canvas_blur_1)
			love.graphics.clear()
			love.graphics.draw(self.canvas_blur_2)
		end
		
		love.graphics.setCanvas()
		love.graphics.setBlendMode("alpha")
		love.graphics.setShader(self.post)
		self.post:send("AO", self.canvas_blur_1)
		self.post:send("depth", self.canvas_z)
		self.post:send("fog", 0.001)
		love.graphics.draw(self.canvas)
		love.graphics.setShader()
	else
		love.graphics.setShader()
		love.graphics.setCanvas()
		love.graphics.draw(self.canvas)
	end
end

return lib