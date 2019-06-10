--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
collision.lua - loads .obj files as collision object(s) and handles per-point collisions of cuboids in any rotation
--]]

local lib = _3DreamEngine

lib.boneManager = {dream = lib}

function lib.boneManager.launch(self, path)
	for d,s in ipairs({"directorydropped", "displayrotated", "draw", "filedropped", "focus", "gamepadaxis", "gamepadpressed", "gamepadreleased", "joystickadded", "joystickaxis", "joystickhat", "joystickpressed", "joystickreleased", "joystickremoved", "keypressed", "keyreleased", "load", "lowmemory", "mousefocus", "mousemoved", "mousepressed", "mousereleased", "quit", "resize", "run", "textedited", "textinput", "threaderror", "touchmoved", "touchpressed", "touchreleased", "update", "visible", "wheelmoved"}) do
		love[s]	 = self[s]
	end
	_3DreamEngine = self
	
	self.object_cursor = self.dream:loadObject(self.dream.root .. "/objects/cursor")
	self.object_axis = self.dream:loadObject(self.dream.root .. "/objects/axis")
	
	self.font_small = love.graphics.setNewFont(16)
	self.font_big = love.graphics.setNewFont(24)
	self.cam = self.dream:newCam()
	
	self.animationZoomW = 5
	self.animationZoomH = math.pi
	self.animationAxis = 1
	self.animationPlay = 0
	
	self.state = "select"
	self.search = ""
	self.page = 1
	self.projects = { }
	function recSearch(path)
		for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
			if love.filesystem.getInfo(path .. "/" .. s, "directory") then
				recSearch(path .. "/" .. s)
			else
				if s:sub(#s-3) == ".obj" then
					self.projects[#self.projects+1] = {name = s:sub(1, #s-4), path = path:sub(2) .. "/" .. s, bones = love.filesystem.getInfo(path .. "/" .. s:sub(1, #s-4) .. ".bones", "file")}
				end
			end
		end
	end
	recSearch("")
	
	love.graphics.setBackgroundColor(128/255, 218/255, 235/255)
	
	BLOCKNEXTTEXTINPUT = true
	
	self.dream.near = 0.25
	self.dream.far = 50
	self.dream:init()
	
	if path then
		self.state = "manager"
		self.object = self.dream:loadObject(path)
		self.object.path = path
	end
	
	--mouse transformation infuser
	self.mouse = { }
	self.mouse.stack = { }
	self.mouse.mx, self.mouse.my = 0, 0
	self.mouse.x, self.mouse.y = 0, 0

	love.graphics.origin_old = love.graphics.origin
	love.graphics.origin = function()
		self.mouse.mx = self.mouse.x
		self.mouse.my = self.mouse.y
		love.graphics.origin_old()
	end

	love.graphics.push_old = love.graphics.push
	love.graphics.push = function(typ)
		table.insert(self.mouse.stack, {self.mouse.mx, self.mouse.my})
		love.graphics.push_old(typ)
	end

	love.graphics.pop_old = love.graphics.pop
	love.graphics.pop = function()
		self.mouse.mx = self.mouse.stack[#self.mouse.stack][1]
		self.mouse.my = self.mouse.stack[#self.mouse.stack][2]
		table.remove(self.mouse.stack, #self.mouse.stack)
		love.graphics.pop_old()
	end

	love.graphics.translate_old = love.graphics.translate
	love.graphics.translate = function(x, y)
		self.mouse.mx = self.mouse.mx - x
		self.mouse.my = self.mouse.my - y
		love.graphics.translate_old(x, y)
	end

	love.graphics.scale_old = love.graphics.scale
	love.graphics.scale = function(x, y)
		self.mouse.mx = self.mouse.mx / x
		self.mouse.my = self.mouse.my / (y or x)
		love.graphics.scale_old(x, y)
	end
	
	function table.copy(first_table)
		local second_table = { }
		for k,v in pairs(first_table) do
			if type(v) == "table" then
				second_table[k] = table.copy(v)
			else
				second_table[k] = v
			end
		end
		return second_table
	end
end

function lib.boneManager.button(self, text, x, y, w, pressed)
	w = w or 200
	h = 15
	love.graphics.setColor(0, 0, 0.1, 0.5)
	love.graphics.rectangle("line", x, y, w, h)
	
	love.graphics.setColor(0, 0, 0.1)
	love.graphics.print(text, x+3, y, 0, h/20)
	
	if pressed then
		love.graphics.setColor(0, 0, 0.1, 0.25)
		love.graphics.rectangle("fill", x, y, w, h)
	end
	
	if self.mouse.mx > x and self.mouse.mx < x+w and self.mouse.my > y and self.mouse.my < y+h then
		love.graphics.setColor(0, 0, 0.1, 0.25)
		love.graphics.rectangle("fill", x, y, w, h)
		return self.mousepressedEvent, true
	else
		return false, false
	end
end

function lib.boneManager.draw()
	self = _3DreamEngine
	self.mouse.x, self.mouse.y = love.mouse.getPosition()
	self.mouse.mx, self.mouse.my = self.mouse.x, self.mouse.y
	love.graphics.setFont(self.font_small)
	
	if self.state == "select" then
		local tx, ty = (love.graphics.getWidth()-300)/2, (love.graphics.getHeight()-400)/2
		love.graphics.translate(tx, ty)
		love.graphics.setColor(0, 0, 0.1)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", 0, 0, 300, 400)
		love.graphics.rectangle("line", 0, 0, 300, 30)
		love.graphics.rectangle("line", 0, 370, 300, 30)
		
		love.graphics.print(self.search .. (love.timer.getTime() % 1 > 0.5 and "|" or ""), 5, 5, 0, 1)
		local d = (self.page-1)*10+1
		local i = 1
		while self.projects[d] do
			local s = self.projects[d]
			
			if #self.search == 0 or s.name:find(self.search, 0, true) then
				love.graphics.print(s.name .. (s.bones and " (bones)" or ""), 5, 30 + (i-1)*20, 0, 1)
				love.graphics.rectangle("line", 0, 30 + (i-1)*20, 300, 20)
				
				if self.mouse.mx > 0 and self.mouse.mx < 300 and self.mouse.my > 30 + (i-1)*20 and self.mouse.my < 30 + (i-1)*20 + 20 then
					love.graphics.setColor(0, 0, 0.1, 0.25)
					love.graphics.rectangle("fill", 0, 30 + (i-1)*20, 300, 20)
					love.graphics.setColor(0, 0, 0.1)
					
					if self.mousepressedEvent then
						self.state = "manager"
						self.object = self.dream:loadObject(s.path:sub(1, #s.path-4))
						self.object.path = s.path:sub(1, #s.path-4)
					end
				end
				i = i + 1
			end
			
			d = d + 1
			if i > 10 then
				break
			end
		end
	else
		if not self.object.bones then
			self:initBones()
		end
		
		--mount backwards
		for d,s in pairs(self.object.bones) do
			s.mountedBy = { }
			for i,v in pairs(self.object.bones) do
				if v.mount == d then
					s.mountedBy[#s.mountedBy+1] = i
				end
			end
		end
		
		local dist = 0
		local cam = { }
		
		--object
		self.dream:resetLight()
		self.cam:reset()
		self.cam:translate(0, 0, -10)
		self.dream:prepare(self.cam)
		self.object:reset()
		self.object:rotateY(love.keyboard.isDown("space") and love.timer.getTime() or 0)
		self.object:translate(-2, 0, -8)
		
		if self.selectedAnimation then
			self.dream:draw(self.object)
		else
			local bones = self.object.bones
			self.object.bones = nil
			self.dream:draw(self.object)
			self.object.bones = bones
		end
		
		self.dream:present()
		
		--selected objects-part
		if self.selected then
			self.dream:prepare(self.cam, true)
			love.graphics.setColor(0.0, 1.0, 0.0)
			self.dream:draw(self.object.objects[self.selected])
			
			local scale = 0.25
			local transform = matrix{
				{scale, 0, 0, self.object.bones[self.selected].x},
				{0, scale, 0, self.object.bones[self.selected].y},
				{0, 0, scale, self.object.bones[self.selected].z},
				{0, 0, 0, 1},
			}
			
			self.object_axis:reset()
			self.object_axis:rotateY(self.object.bones[self.selected].initRotationY)
			self.object_axis:rotateZ(self.object.bones[self.selected].initRotationZ)
			self.object_axis:rotateX(self.object.bones[self.selected].initRotationX)
			self.object_axis.transform = transform * self.object_axis.transform
			
			self.dream:draw(self.object_axis)
			self.dream:present()
			
			--top
			self.fov = 10
			self.cam:reset()
			self.cam:translate(-10, -150, 14)
			self.cam:rotateX(math.pi*0.5)
			self.dream:prepare(self.cam, true)
			self.dream:draw(self.object.objects[self.selected])
			love.graphics.setColor(0.0, 1.0, 0.0)
			self.dream:draw(self.object_cursor)
			self.dream:present()
			self.cam:reset()
			self.fov = 90
		end
		
		love.graphics.push("all")
		love.graphics.setFont(self.font_small)
		love.graphics.setColor(0, 0, 0)
		
		if self.drag then
			love.graphics.print(self.drag, self.mouse.mx, self.mouse.my)
		end
		
		--object list
		local i = 2.5
		love.graphics.push()
		love.graphics.translate(10, 10)
		love.graphics.setFont(self.font_big)
		love.graphics.print("Objects:", 0, 0)
		love.graphics.setFont(self.font_small)
		for d,s in pairs(self.object.objects) do
			if self:button(s.name, 15, i * 15, 200, d == self.selected) then
				if self.selected == d then
					self.selected = nil
				else
					self.selected = d
					self.drag = d
				end
			end
			i = i + 1
		end
		love.graphics.pop()
		
		
		
		--animation manager
		love.graphics.push()
		love.graphics.translate(10, love.graphics.getHeight()-200)
		love.graphics.setFont(self.font_big)
		love.graphics.setColor(0, 0, 0.1)
		love.graphics.print("animations", 0, 0)
		love.graphics.setFont(self.font_small)
		
		--new or remove
		if self:button("new", 15, 30, 50) then
			self.object.animations[#self.object.animations+1] = {name = "#" .. tostring(#self.object.animations+1)}
		end
		if self.selectedAnimation then
			if self:button("rem", 15+50, 30, 50) then
				table.remove(self.object.animations, self.selectedAnimation)
				self.selectedAnimation = nil
			end
			
			--axis
			if self:button("X-axis", 15, 30+15, 50, self.animationAxis == 1) then
				self.animationAxis = 1
			end
			if self:button("Y-axis", 15+50, 30+15, 50, self.animationAxis == 2) then
				self.animationAxis = 2
			end
			if self:button("Z-axis", 15+100, 30+15, 50, self.animationAxis == 3) then
				self.animationAxis = 3
			end
		end
		
		--animations
		local i = 4.5
		for d,s in ipairs(self.object.animations) do
			if self:button(s.name, 15, i * 15, 150, d == self.selected) then
				if self.selectedAnimation == d then
					self.selectedAnimation = nil
				else
					self.selectedAnimation = d
				end
			end
			i = i + 1
		end
		
		--actual animation window
		if self.selectedAnimation then
			--max time
			local max = 0
			for d,anim in pairs(self.object.animations[self.selectedAnimation]) do
				if type(anim) == "table" then
					max = math.max(max, anim.pointsX[#anim.pointsX] and anim.pointsX[#anim.pointsX][1] or 0, anim.pointsY[#anim.pointsY] and anim.pointsY[#anim.pointsY][1] or 0, anim.pointsZ[#anim.pointsZ] and anim.pointsZ[#anim.pointsZ][1] or 0)
				end
			end
			self.object.animations[self.selectedAnimation].length = max
			self.animationPlay = love.timer.getTime() % max
			
			if not self.selected then
				love.graphics.setColor(0, 0, 0.1)
				love.graphics.print("select bone to animate\npress ctrl+C to copy\nctrl+X to link\nctrl+V to paste animation data\nctrl+K to unlink an animation data, it now won't change linked data anymore", 250, 50)
			else
				self.object.animations[self.selectedAnimation][self.selected] = self.object.animations[self.selectedAnimation][self.selected] or {
					length = 5,
					pointsX = { },
					pointsY = { },
					pointsZ = { },
					points = { },
				}
				local anim = self.object.animations[self.selectedAnimation][self.selected]
				anim.points = self.animationAxis == 1 and anim.pointsX or self.animationAxis == 2 and anim.pointsY or anim.pointsZ
				
				local w = love.graphics.getWidth()-225
				local scaleX = self.animationZoomW / w
				local scaleY = self.animationZoomH / 100
				
				love.graphics.translate(200, -10)
				love.graphics.setColor(0, 0, 0.1, 0.5)
				love.graphics.rectangle("line", 0, 0, w, 200)
				love.graphics.line(0, 100, w, 100)
				love.graphics.line(0, 100 + math.pi / scaleY, w, 100 + math.pi / scaleY)
				love.graphics.line(0, 100 - math.pi / scaleY, w, 100 - math.pi / scaleY)
				
				if love.keyboard.isDown("space") and self.mouse.mx > 0 and self.mouse.my > 0 and self.mouse.mx < w and self.mouse.my < 200 then
					self.animationPlay = self.mouse.mx * scaleX
				end
				
				--max time
				local max = self.object.animations[self.selectedAnimation].length
				love.graphics.line(max/scaleX, 0, max/scaleX, 200)
				
				--player
				love.graphics.line(self.animationPlay/scaleX, 0, self.animationPlay/scaleX, 200)
				
				--draw curve
				love.graphics.setColor(0, 1.0, 0)
				for axis = 1, 3 do
					local lv
					local lx = 0
					local step = 0.02
					for d,s in ipairs(axis == 1 and anim.pointsX or axis == 2 and anim.pointsY or anim.pointsZ) do
						local s2 = (axis == 1 and anim.pointsX or axis == 2 and anim.pointsY or anim.pointsZ)[d+1]
						if s2 then
							for dx = s[1], s2[1]+step, step do
								dx = math.min(dx, s2[1])
								local x = (dx - s[1]) / math.abs(s2[1]-s[1])
								local v = s[2] + (s2[2]-s[2]) * x^2 * (3 - 2*x)
								love.graphics.line(lx/scaleX, 100 + (lv or v)/scaleY, dx/scaleX, 100 + v/scaleY)
								lv = v
								lx = dx
							end
						end
					end
					love.graphics.setColor(1.0, 0, 0)
				end
				
				--draw points
				love.graphics.setColor(0, 0, 0)
				for d,s in ipairs(anim.points) do
					love.graphics.circle("fill", s[1]/scaleX, 100 + s[2]/scaleY, 5)
				end
				
				--add
				if self.mousepressedEvent == 1 and self.mouse.mx > 0 and self.mouse.my > 0 and self.mouse.mx < w and self.mouse.my < 200 then
					table.insert(anim.points, {
						self.mouse.mx * scaleX,
						(self.mouse.my-100) * scaleY,
					})
					
					table.sort(anim.points, function(a, b) return a[1] < b[1] end)
				end
				
				--remove
				if self.mousepressedEvent == 2 then
					for d,s in ipairs(anim.points) do
						if math.sqrt((self.mouse.mx - s[1]/scaleX)^2 + (self.mouse.my - 100 - s[2]/scaleY)^2) < 12 then
							table.remove(anim.points, d)
							break
						end
					end
				end
			end
			
			--animate
			for d,s in pairs(self.object.bones) do
				s.rotationX = 0
				s.rotationY = 0
				s.rotationZ = 0
			end
			for d,a in pairs(self.object.animations[self.selectedAnimation]) do
				if type(a) == "table" then
					for axis = 1, 3 do
						local points = axis == 1 and a.pointsX or axis == 2 and a.pointsY or a.pointsZ
						if #points > 0 then
							local s
							for i = 1, #points+1 do
								local s1 = s
								local s2 = points[i] or points[1]
								s = s2
								
								if s2[1] > self.animationPlay or i == #points+1 then
									local v
									if i == #points+1 then
										v = s1[2]
									elseif s1 then
										local x = (self.animationPlay - s1[1]) / math.abs(s2[1]-s1[1])
										v = s1[2] + (s2[2]-s1[2]) * x^2 * (3 - 2*x)
									else
										s1 = points[#points]
										local x = self.animationPlay / s2[1]
										v = s1[2] + (s2[2]-s1[2]) * x^2 * (3 - 2*x)
									end
									print(i)
									
									self.object.bones[d][axis == 1 and "rotationX" or axis == 2 and "rotationY" or "rotationZ"] = v
									break
								end
							end
						end
					end
				end
			end
		end
		love.graphics.pop()
		
		
		
		--origin and mount position
		love.graphics.push()
		love.graphics.translate(love.graphics.getWidth()-300, 10)
		love.graphics.setFont(self.font_big)
		love.graphics.setColor(0, 0, 0.1)
		love.graphics.print("bones", 0, 0)
		love.graphics.setFont(self.font_small)
		love.graphics.print("drag a bone from the left\non a node to connect.\nRight click on a node to remove.", 0, 35, 0, 0.75)
		
		if self.selected then
			for d,s in ipairs({"initRotationY", "initRotationZ", "initRotationX"}) do
				love.graphics.push()
				love.graphics.translate(240 + (d-1)*10, d == 1 and 50 or d == 2 and 125 or 180)
				love.graphics.circle("line", 0, 0, 40 - (d-1)*10)
				love.graphics.print(s:sub(#s), -20, -20)
				love.graphics.line(0, 0, math.cos(self.object.bones[self.selected][s]+math.pi/2)*(40 - (d-1)*10), math.sin(self.object.bones[self.selected][s]+math.pi/2)*(40 - (d-1)*10))
				if love.mouse.isDown(1) and math.sqrt(self.mouse.mx^2 + self.mouse.my^2) < 40 - (d-1)*10 then
					self.object.bones[self.selected][s] = math.atan2(self.mouse.my, self.mouse.mx)-math.pi/2
				end
				love.graphics.pop()
			end
		end
		
		--bone tree
		local bones = {{"root", false}}
		local layer = 1.0
		love.graphics.setLineWidth(1)
		love.graphics.translate(100, 80)
		while #bones ~= 0 do
			local old = bones
			bones = { }
			for d,s in ipairs(old) do
				local x = (d-1)*75 - (#old-1)/2*75
				love.graphics.circle("line", x, layer*50, 20)
				love.graphics.printf(s[1], -100 + x, layer*50-8-25, 200/0.5, "center", 0.25, 0.5)
				
				if s[2] then
					love.graphics.line(x, layer*50, s[2], (layer-1)*50)
				end
				
				if self.selected == s[1] then
					love.graphics.setLineWidth(2)
					love.graphics.circle("line", x, layer*50, 20)
					love.graphics.setLineWidth(1)
				end
				
				if math.sqrt((self.mouse.mx - x)^2 + (self.mouse.my - layer*50)^2) < 30 then
					love.graphics.setLineWidth(3)
					love.graphics.circle("line", x, layer*50, 20)
					love.graphics.setLineWidth(1)
					
					if self.mousepressedEvent == 2 and s[1] ~= "root" then
						self.object.bones[s[1]].mount = nil
					end
					if self.mousepressedEvent == 1 then
						if self.selected == s[1] or s[1] == "root" then
							self.selected = nil
						else
							self.selected = s[1]
						end
					end
					if not love.mouse.isDown(1) and self.drag and s[1] ~= self.drag then
						self.object.bones[self.drag].mount = s[1]
						self.drag = nil
					end
				end
				
				for i,v in pairs(self.object.bones) do
					if v.mount == s[1] then
						bones[#bones+1] = {i, x}
					end
				end
			end
			layer = layer + 1
		end
		love.graphics.pop()
		
		--release bone drag
		if not love.mouse.isDown(1) then
			self.drag = nil
		end
		
		local dx = ((self.lastMx or self.mouse.x) - self.mouse.x)
		local dy = ((self.lastMy or self.mouse.y) - self.mouse.y)
		local d = (dx-dy) / 50
		if self.selected then
			if love.keyboard.isDown("x") then
				self.object.bones[self.selected].x = self.object.bones[self.selected].x - d
			end
			if love.keyboard.isDown("y") then
				self.object.bones[self.selected].y = self.object.bones[self.selected].y - d
			end
			if love.keyboard.isDown("z") then
				self.object.bones[self.selected].z = self.object.bones[self.selected].z - d
			end
		end
		self.lastMx = self.mouse.mx
		self.lastMy = self.mouse.my
		
		love.graphics.pop()
	end
	
	self.mousepressedEvent = nil
end

function lib.boneManager.mousepressed(x, y, b)
	self = _3DreamEngine
	self.mousepressedEvent = b
end

function lib.boneManager.keypressed(key)
	self = _3DreamEngine
	if self.state == "select" then
		if key == "backspace" then
			self.search = self.search:sub(1, #self.search-1)
		end
	elseif self.state == "manager" then
		if love.keyboard.isDown("lctrl", "rctrl") and key == "s" then
			love.filesystem.createDirectory(self.object.path:match("(.*[/\\])"))
			love.filesystem.write(self.object.path .. ".bones", table.save(self.object.bones, nil, true))
			print(love.filesystem.write(self.object.path .. ".anim", table.save(self.object.animations, nil, true)))
		end
		if self.selectedAnimation and self.selected then
			if love.keyboard.isDown("lctrl", "rctrl") then
				if key == "c" then
					self.copy = table.copy(self.object.animations[self.selectedAnimation][self.selected])
				elseif key == "x" then
					self.copy = self.object.animations[self.selectedAnimation][self.selected]
				elseif key == "v" then
					self.object.animations[self.selectedAnimation][self.selected] = self.copy
					self.copy = nil
				elseif key == "k" then
					self.object.animations[self.selectedAnimation][self.selected] = table.copy(self.object.animations[self.selectedAnimation][self.selected])
				end
			end
		end
	end
end

function lib.boneManager.textinput(text)
	if BLOCKNEXTTEXTINPUT then
		BLOCKNEXTTEXTINPUT = false
		return
	end
	
	self = _3DreamEngine
	if self.state == "select" and #text < 128 then
		self.search = self.search .. text
	end
end

function lib.boneManager.resize()
	self.dream:init()
end

function lib.boneManager.wheelmoved(x, y)
	if self.state == "manager" then
		if self.mouse.x > 200 and self.mouse.y > love.graphics.getHeight()-200 then
			if love.keyboard.isDown("lctrl", "lshift", "rctrl", "rshift") then
				self.animationZoomH = math.max(0.01, self.animationZoomH - y * self.animationZoomH / 10)
			else
				self.animationZoomW = math.max(1, self.animationZoomW - y)
			end
		end
	end
end

function lib.boneManager.initBones(self)
	if love.filesystem.getInfo(self.object.path .. ".bones") then
		self.object.bones = table.load(love.filesystem.read(self.object.path .. ".bones"))
	else
		self.object.bones = {
			root = {
				name = "root",
				x = 0,
				y = 0,
				z = 0,
				
				mount = false,
			},
		}
	end
	
	for d,s in pairs(self.object.objects) do
		self.object.bones[d] = self.object.bones[d] or {
			name = d,
			x = 0,
			y = 0,
			z = 0,
			
			mount = false,
		}
	end
	
	for d,s in pairs(self.object.bones) do
		local b = self.object.bones[d]
		
		--local space transformation
		if b.mount then
			local mb = self.object.bones[b.mount]
			b.initRotationX = b.initRotationX or 0
			b.initRotationY = b.initRotationY or math.sqrt((mb.x-b.x)^2 - (mb.z-b.z)^2) < math.abs(s.y-mb.y) and 0 or math.atan2(mb.y - b.y, (mb.x+mb.z) - (b.x+b.z)) + math.pi/2
			b.initRotationZ = b.initRotationZ or 0
		else
			b.initRotationX = 0
			b.initRotationY = 0
			b.initRotationZ = 0
		end
		
		--used for animations
		b.rotationX = 0
		b.rotationY = 0
		b.rotationZ = 0
	end
	
	if love.filesystem.getInfo(self.object.path .. ".anim") then
		self.object.animations = table.load(love.filesystem.read(self.object.path .. ".anim"))
	else
		self.object.animations = { }
	end
end