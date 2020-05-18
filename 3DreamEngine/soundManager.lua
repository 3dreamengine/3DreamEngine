local soundManager = { }

soundManager.supportedFileTypes = {
	["ogg"] = true,
	["oga"] = true,
	["ogv"] = true,
	["mp3"] = true,
	["wav"] = true,
}

soundManager.sounds = { }
soundManager.reserved = { }
soundManager.maxSounds = 16
soundManager.reserveTime = 1 / 5
soundManager.reserveFadeTime = 1 / 30

function soundManager:addLibrary(path, into)
	local function rec(p, into)
		for d,s in ipairs(love.filesystem.getDirectoryItems(p)) do
			if love.filesystem.getInfo(p .. "/" .. s, "directory") then
				rec(p .. "/" .. s, (#into == "" and "" or (into .. "/")) .. s)
			else
				local ext = (s:match("^.+(%..+)$") or ""):sub(2)
				if self.supportedFileTypes[ext] then
					soundManager.sounds[into .. "/" .. s:sub(1, #s-#ext-1)] = {
						path = p .. "/" .. s,
						sounds = { },
						reserved = { },
						index = 1,
					}
				end
			end
		end
	end
	rec(path, into or "")
end

function soundManager:play(sound, x, y, z, volume, pitch, set)
	local s = soundManager.sounds[sound]
	assert(s, "sound does not exist")
	
	--use reserved soound
	local sound
	if set then
		sound = self.reserved[set]
	end
	
	--load new sound or repeat
	if not sound then
		if not s.sounds[s.index] then
			if s.index == 1 or (s.index < self.maxSounds and not s.sounds[math.ceil(s.index / 2)]:isPlaying()) then
				s.sounds[s.index] = love.audio.newSource(s.path, "static")
			else
				s.index = 1
			end
		end
		
		--skip reserved sounds
		for i = 1, #s.sounds do
			sound = s.sounds[s.index]
			s.index = s.index + 1
			if not s.reserved[s.index] then
				break
			end
		end
		
		--reserve sound
		if set and sound then
			self.reserved[set] = sound
			s.reserved[s.index] = {key = set, time = self.reserveTime, volume = volume, sound = sound}
			sound:seek(0)
		end
	end
	
	--play sound
	if sound then
		if not set then
			sound:seek(0)
		end
		sound:setVolume(volume)
		sound:setPitch(pitch)
		sound:setPosition(x, y, z)
		sound:play()
		sound:setLooping(set and true or false)
	end
end

--update and remove reserved sounds
function soundManager:update(dt)
	for d,s in pairs(self.sounds) do
		for i,v in pairs(s.reserved) do
			v.time = v.time - dt
			if v.time < 0 then
				v.sound:stop()
				s.reserved[i] = nil
				self.reserved[v.key] = nil
			elseif v.time < self.reserveFadeTime then
				v.sound:setVolume(v.volume / self.reserveFadeTime * v.time)
			end
		end
	end
end

return soundManager