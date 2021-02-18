local soundManager = { }

--supported file types
local supportedFileTypes = { }
for _,typ in ipairs({"wav", "mp3", "ogg", "oga", "ogv", "flac"}) do
	supportedFileTypes[typ] = true
end

local reserved = { }
local reservedIDs = { }

soundManager.sounds = { }
soundManager.maxSounds = 16
soundManager.reserveTime = 1 / 5
soundManager.reserveFadeTime = 1 / 10

local function newSound(path, sound)
	return {
		path = path,
		sounds = {sound},
	}
end

--add a directory to the sound library
function soundManager:addLibrary(path, into)
	local function rec(p, into)
		for d,s in ipairs(love.filesystem.getDirectoryItems(p)) do
			if love.filesystem.getInfo(p .. "/" .. s, "directory") then
				rec(p .. "/" .. s, (#into == "" and "" or (into .. "/")) .. s)
			else
				local ext = (s:match("^.+(%..+)$") or ""):sub(2)
				if supportedFileTypes[ext] then
					soundManager.sounds[into .. "/" .. s:sub(1, #s-#ext-1)] = newSound(p .. "/" .. s)
				end
			end
		end
	end
	rec(path, into or "")
end

--play a sound
--path can be a library path or an actual sound
function soundManager:play(path, x, y, z, volume, pitch, ID)
	assert(type(path) ~= "string" or soundManager.sounds[path], "sound does not exist")
	
	--register new sound
	if not soundManager.sounds[path] then
		assert(path:getChannelCount() == 1, path .. " is not a mono source!")
		soundManager.sounds[path] = newSound(false, path)
	end
	
	local s = soundManager.sounds[path]
	
	--use reserved sound if available
	local sound
	if ID then
		sound = reserved[ID] and reserved[ID].sound
	end
	
	--look for available sound
	if not sound then
		for d,s in ipairs(s.sounds) do
			if not reservedIDs[s] and not s:isPlaying() then
				sound = s
				break
			end
		end
	end
	
	--load or clone new sound
	if not sound then
		if not s.sounds[1] then
			--load new source from disk
			local sound = love.audio.newSource(s.path, "static")
			assert(sound:getChannelCount() == 1, s.path .. " is not a mono source!")
			s.sounds[1] = sound
		elseif #s.sounds < self.maxSounds then
			--clone sound
			s.sounds[#s.sounds+1] = s.sounds[1]:clone()
		end
	end
	
	--play it
	if sound then
		--reserve sound
		if ID then
			reservedIDs[sound] = ID
			reserved[ID] = {ID = ID, time = self.reserveTime, volume = volume, sound = sound}
		end
		
		--play sound
		if ID then
			sound:setLooping(true)
		else
			sound:seek(0)
			sound:setLooping(false)
		end
		sound:setVolume(volume)
		sound:setPitch(pitch)
		sound:setPosition(x, y, z)
		sound:play()
	end
end

--update and remove reserved sounds
function soundManager:update(dt)
	for i,v in pairs(reserved) do
		v.time = v.time - dt
		if v.time < 0 then
			v.sound:stop()
			reserved[i] = nil
			reservedIDs[v.sound] = nil
		elseif v.time < self.reserveFadeTime then
			v.sound:setVolume(v.volume / self.reserveFadeTime * v.time)
		end
	end
end

return soundManager