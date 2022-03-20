local c = {
	x = 0,
	y = 0,
	z = 0,
	ax = 0,
	ay = 0,
	az = 0,
	rx = 0,
	ry = 0,
}

function c:update(dt)
	local d = love.keyboard.isDown
	local speed = 10 * dt
	
	--move
	self.x = self.x + self.ax * dt
	self.y = self.y + self.ay * dt
	self.z = self.z + self.az * dt
	
	--accelerate
	if d("w") then
		self.ax = self.ax + math.cos(self.ry-math.pi/2) * speed
		self.az = self.az + math.sin(self.ry-math.pi/2) * speed
	end
	if d("s") then
		self.ax = self.ax + math.cos(self.ry+math.pi-math.pi/2) * speed
		self.az = self.az + math.sin(self.ry+math.pi-math.pi/2) * speed
	end
	if d("a") then
		self.ax = self.ax + math.cos(self.ry-math.pi/2-math.pi/2) * speed
		self.az = self.az + math.sin(self.ry-math.pi/2-math.pi/2) * speed
	end
	if d("d") then
		self.ax = self.ax + math.cos(self.ry+math.pi/2-math.pi/2) * speed
		self.az = self.az + math.sin(self.ry+math.pi/2-math.pi/2) * speed
	end
	if d("space") then
		self.ay = self.ay + speed
	end
	if d("lshift") then
		self.ay = self.ay - speed
	end
	
	--air resistance
	self.ax = self.ax * (1 - dt * 5)
	self.ay = self.ay * (1 - dt * 5)
	self.az = self.az * (1 - dt * 5)
end

function c:setCamera(cam)
	cam:reset()
	cam:rotateX(self.rx)
	cam:rotateY(self.ry)
	cam:translate(self.x, self.y, self.z)
end

function c:mousemoved(x, y)
	local speedH = 0.005
	local speedV = 0.005
	self.ry = self.ry + x * speedH
	self.rx = math.max(-math.pi/2 + 0.01, math.min(math.pi/2 - 0.01, self.rx - y * speedV))
end

return c