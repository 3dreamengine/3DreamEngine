---@type Dream
local lib = _3DreamEngine

---Creates a new shadow
---@param typ string @ "sun" or "point"
---@param resolution number
---@return DreamShadow
function lib:newShadow(typ, resolution)
	return setmetatable({
		typ = typ,
		
		resolution = resolution or (typ == "sun" and 1024 or 512),
		done = false,
		target = false,
		refreshStepSize = typ == "sun" and 1.0 or 0.0001,
		
		cascadeDistance = 8,
		cascadeFactor = 4,
		
		static = false,
		smooth = false,
		lazy = false,
	}, self.meta.shadow)
end

---@class DreamShadow
local class = {
	links = { "shadow" },
}

---The step size defines at what difference in position a shadow should be recalculated
---@param refreshStepSize number
function class:setRefreshStepSize(refreshStepSize)
	self.refreshStepSize = refreshStepSize
end

---@return number
function class:getRefreshStepSize()
	return self.refreshStepSize
end

---The cascade distance is the range of the sun shadow, higher range allows a higher shadow range, but decreases resolution
---@param cascadeDistance number
function class:setCascadeDistance(cascadeDistance)
	self.cascadeDistance = cascadeDistance
end

---@return number
function class:getCascadeDistance()
	return self.cascadeDistance
end

---The cascade factor defines the factor at which each cascade is larger than the one before
---@param cascadeFactor number
function class:setCascadeFactor(cascadeFactor)
	self.cascadeFactor = cascadeFactor
end

---@return number
function class:getCascadeFactor()
	return self.cascadeFactor
end

---Refresh (static) shadows
function class:refresh()
	self.rendered = false
end

---Forces textures to be regenerated
function class:clear()
	self.canvases = nil
	self.canvas = nil
	self.lastFace = nil
	self:refresh()
end

function class:setResolution(resolution)
	self.resolution = resolution
	self:clear()
end

---@return number
function class:getResolution()
	return self.resolution
end

---Static lights wont capture moving objects
---@param static boolean
function class:setStatic(static)
	self.static = static
	self:clear()
end

---@return boolean
function class:isStatic()
	return self.static
end

---Smoothing is slow and is therefore only available for static shadows
---@param smooth boolean
function class:setSmooth(smooth)
	self.smooth = smooth
	self:clear()
end

---@return boolean
function class:isSmooth()
	return self.smooth
end

---Lazy rendering spreads the load on several frames at the cost of visible artifacts
---@param lazy boolean
function class:setLazy(lazy)
	self.lazy = lazy
end

---@return boolean
function class:isLazy()
	return self.lazy
end

return class