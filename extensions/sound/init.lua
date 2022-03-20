local soundManager = {
	paths = { },
	sounds = { },
	maxSounds = 16,
}

--reverb effects
for i = 1, 10 do
	love.audio.setEffect("reverb_" .. i, {
		type = "reverb",
		decaytime = i / 2,
		density = 0.5,
	})
end

--add a directory to the sound library
local supportedFileTypes = table.toSet({"wav", "mp3", "ogg", "oga", "ogv", "flac"})
function soundManager:addLibrary(path, into)
	for d,s in ipairs(love.filesystem.getDirectoryItems(path)) do
		if love.filesystem.getInfo(path .. "/" .. s, "directory") then
			self:addLibrary(path .. "/" .. s, (into and (into .. "/") or "") .. s)
		else
			local ext = (s:match("^.+(%..+)$") or ""):sub(2)
			if supportedFileTypes[ext] then
				soundManager.paths[(into and (into .. "/") or "") .. s:sub(1, #s-#ext-1)] = path .. "/" .. s
			end
		end
	end
end

--TODO remove sorting
local sort = function(n1, n2)
	return n1:tell() < n2:tell()
end

function soundManager:play(name, position, volume, pitch, echo, muffle)
	assert(self.paths[name], "sound not in library")
	if not self.sounds[name] then
		local path = self.paths[name]
		local s = love.audio.newSource(path, "static")
		self.sounds[name] = {s}
		assert(s:getChannelCount() == 1, path .. " is not a mono source!")
	end
	
	--sort sounds
	table.sort(self.sounds[name], sort)
	
	--take the best sound
	local sound
	if self.sounds[name][1] and not self.sounds[name][1]:isPlaying() then
		sound = self.sounds[name][1]
	elseif #self.sounds[name] < self.maxSounds then
		sound = self.sounds[name][1]:clone()
		self.sounds[name][#self.sounds[name]+1] = sound
	else
		sound = self.sounds[name][#self.sounds[name]]
	end
	
	--muffle filter
	local filter = muffle and muffle > 0 and {
		type = "lowpass",
		volume = 1.0,
		highgain =  1.0 - muffle * 0.999,
	} or nil
	
	--deactivate effetcs
	for _,e in ipairs(sound:getActiveEffects()) do
		sound:setEffect(e, false)
	end
	
	--echo
	if echo and echo > 0 then
		local i = math.min(10, math.max(1, math.ceil(echo * 10)))
		sound:setEffect("reverb_" .. i, filter)
	else
		sound:setFilter(filter)
	end
	
	--launch the sound!
	sound:setVolume(volume or 1)
	sound:setPitch(pitch or 1)
	sound:seek(0)
	if position then
		sound:setRelative(false)
		sound:setPosition(position:unpack())
	else
		sound:setRelative(true)
		sound:setPosition(0, 0, 0)
	end
	sound:play()
end

return soundManager