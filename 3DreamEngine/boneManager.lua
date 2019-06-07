--[[
#part of the 3DreamEngine by Luke100000
#see init.lua for license and documentation
collision.lua - loads .obj files as collision object(s) and handles per-point collisions of cuboids in any rotation
--]]

local lib = _3DreamEngine

function lib.boneManager(self, object)
	if not self.object_cursor then
		self.object_cursor = self:loadObject(self.root .. "/objects/cursor")
	end
	local mx, my = love.mouse.getPosition()
	self["boneManagerEnv_" .. object.name] = self["boneManagerEnv_" .. object.name] or { }
	local env = self["boneManagerEnv_" .. object.name]
	
	if not object.bones then
		object.bones = {
			root = {
				name = "root",
				x = 0,
				y = 0,
				z = 0,
				
				mount = false,
				joint = "root",
				
				transform = matrix{
					{1, 0, 0, 0},
					{0, 1, 0, 0},
					{0, 0, 1, 0},
					{0, 0, 0, 1},
				},
			},
		}
		
		for d,s in pairs(object.objects) do
			object.bones[d] = {
				name = d,
				x = 0,
				y = 0,
				z = 0,
				
				mount = false,
				joint = "full",
				
				transform = matrix{
					{1, 0, 0, 0},
					{0, 1, 0, 0},
					{0, 0, 1, 0},
					{0, 0, 0, 1},
				},
			}
		end
	end
	
	local dist = 0
	local cam = { }
	
	--object
	self:resetLight()
	self:prepare()
	object:reset()
	object:rotateY(love.timer.getTime())
	self:draw(object, 0, -3, -8)
	self:present()
	
	--selected objects-part
	if env.selected then
		self:prepare(nil, true)
		love.graphics.setColor(0.0, 1.0, 0.0)
		object.objects[env.selected].transform = object.transform
		self:draw(object.objects[env.selected], 0, -3, -8)
		self:draw(self.object_cursor, -0 + object.bones[env.selected].x, -3 + object.bones[env.selected].y, -8 + object.bones[env.selected].z, 0.25)
		self:present()
	end
	
	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0)
	
	if env.drag then
		love.graphics.print(env.drag, mx, my)
	end
	
	local i = 1
	love.graphics.print("Objects:", 10, 10, 0, 1.25)
	for d,s in pairs(object.objects) do
		love.graphics.print((env.selected == d and "[" or "") .. s.name .. (env.selected == d and "]" or ""), 20, 10 + i * 20)
		if mx > 5 and mx < 100 and my > 10 + i * 20 - 3  and my < 10 + i * 20 + 20 - 3 then
			love.graphics.print(">", 5, 10 + i * 20)
			if love.mouse.isDown(1) then
				env.selected = d
				env.drag = d
			end
		end
		i = i + 1
	end
	
	if env.selected then
		love.graphics.push()
		love.graphics.translate(love.graphics.getWidth()-200, love.graphics.getHeight()-200)
		love.graphics.print("> " .. env.selected, 0, 0, 0, 1.25)
		love.graphics.print("hold Y, X or Z and move\nmouse to move selected origin", 0, 20)
		love.graphics.pop()
	end
	
	love.graphics.push()
	love.graphics.translate(love.graphics.getWidth()-300, 10)
	love.graphics.print("bone tree", 0, 0, 0, 1.25)
	love.graphics.print("drag a bone from the left on a node to connect.\nRight click on a node to remove.", 0, 20)
	
	local bones = {{"root", false}}
	local layer = 0
	love.graphics.setLineWidth(1)
	love.graphics.translate(100, 80)
	while #bones ~= 0 do
		local old = bones
		bones = { }
		for d,s in ipairs(old) do
			local x = (d-1)*75 - (#old-1)/2*75
			love.graphics.circle("line", x, layer*50, 20)
			love.graphics.printf(s[1], -100 + x, layer*50-8-25, 200, "center", 0.25)
			
			if s[2] then
				love.graphics.line(x, layer*50, s[2], (layer-1)*50)
			end
			
			if math.sqrt((mx - 100 - x - (love.graphics.getWidth()-300))^2 + (my - 80-layer*50 - 10)^2) < 30 then
				love.graphics.setLineWidth(2)
				love.graphics.circle("line", x, layer*50, 20)
				love.graphics.setLineWidth(1)
				
				if love.mouse.isDown(2) and s[1] ~= "root" then
					table.remove(object.bones, s[1])
				end
				if not love.mouse.isDown(1) and env.drag then
					object.bones[env.drag].mount = s[1]
					env.drag = nil
				end
			end
			
			for i,v in pairs(object.bones) do
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
		env.drag = nil
	end
	
	local dx = ((env.lastMx or mx) - mx) / 10
	local dy = ((env.lastMy or my) - my) / 10
	if env.selected then
		if love.keyboard.isDown("x") then
			object.bones[env.selected].x = object.bones[env.selected].x + dx
		end
	end
	env.lastMx = mx
	env.lastMy = my
	
	love.graphics.pop()
end