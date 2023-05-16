---@type Dream
local lib = _3DreamEngine

local ffi = require("ffi")

---Creates new glyph atlas
---@param margin number @ Size of margin around each character. You need at least 2^mipmapping levels of margin for no bleeding artifacts.
---@return DreamGlyphAtlas
function lib:newGlyphAtlas(fontFile, fontSize, margin)
	---@type DreamGlyphAtlas
	local atlas = setmetatable({ }, self.meta.glyphAtlas)
	
	atlas.font = fontFile and love.graphics.newFont(fontFile, fontSize, "normal", 1) or love.graphics.newFont(fontSize, "normal", 1)
	atlas.rasterizer = fontFile and love.font.newRasterizer(fontFile, fontSize, "normal", 1) or love.font.newRasterizer(fontSize, "normal", 1)
	atlas.packer = self.packer(64, 64)
	atlas.glyphs = { }
	atlas.dirty = true
	
	--todo custom mipmapping on different font sizes may increase quality and locks required margin to 1
	atlas.margin = margin or 1
	
	atlas:allocate()
	
	atlas.cache = { }
	
	return atlas
end

---A glyph atlas to be used in text rendering
---@class DreamGlyphAtlas
local class = {
	links = { "glyphAtlas" },
}

---Render the characters to the atlas
---@param characters string[]
function class:renderCharacters(characters)
	for _, c in ipairs(characters) do
		self:getGlyph(c)
	end
end

---Get all characters contained in the font
function class:getAllCharacters()
	local characters = { }
	for i = 1, 1112064 do
		if self.rasterizer:hasGlyphs(i) then
			local glyph = self.rasterizer:getGlyphData(i)
			local name = glyph:getGlyphString()
			table.insert(characters, name)
		end
	end
	return characters
end

---@private
function class.charIter(str)
	return str:gmatch("([%z\1-\127\194-\244][\128-\191]*)")
end

---Split the utf-8 string into characters
---@param str string
function class:splitCharacters(str)
	local characters = { }
	for c in class.charIter(str) do
		table.insert(characters, c)
	end
	return characters
end

---Renders that glyph if not already rendered and returns it
---@param character string
---@return DreamGlyph
function class:getGlyph(character)
	if self.glyphs[character] == nil and self.rasterizer:hasGlyphs(character) then
		local glyph = self.rasterizer:getGlyphData(character)
		local w, h = glyph:getDimensions()
		
		if w > 0 and h > 0 then
			--look for atlas position, or increase the atlas size
			local x, y = self.packer(w + self.margin, h + self.margin)
			if not x then
				self:extend()
				return self:getGlyph(character)
			end
			
			local advance = glyph:getAdvance()
			local bx, by = glyph:getBearing()
			
			--remember glyph position and characteristics
			---@class DreamGlyph
			local g = {
				x = x,
				y = y,
				width = w,
				height = h,
				advance = advance,
				offsetX = bx,
				offsetY = by
			}
			self.glyphs[character] = g
			
			--copy glyph into atlas
			local ptr = ffi.cast('uint8_t*', glyph:getFFIPointer())
			for px = 0, w - 1 do
				for py = 0, h - 1 do
					local index = ((py + y) * self.packer.width + (px + x)) * 4
					local gi = (py * w + px) * 2
					local v = ptr[gi + 0]
					local alpha = ptr[gi + 1]
					self.atlas[index + 0] = v
					self.atlas[index + 1] = v
					self.atlas[index + 2] = v
					self.atlas[index + 3] = alpha
				end
			end
			
			self.dirty = true
		else
			self.glyphs[character] = false
		end
	end
	
	return self.glyphs[character]
end

---Extends the atlas size
---@private
function class:extend()
	local wide = self.packer.width > self.packer.height
	self.packer:extend(wide and 0 or self.packer.width, wide and self.packer.height or 0)
	self:allocate()
end

---Allocate memory
---@private
function class:allocate()
	local old = self.image
	self.image = love.image.newImageData(self:getDimensions())
	self.atlas = ffi.cast('uint8_t*', self.image:getFFIPointer())
	self.dirty = false
	
	--sets everything to white
	for i = 0, self.image:getWidth() * self.image:getHeight() * 4 - 1 do
		self.atlas[i] = (i % 4 == 3 and 0 or 1)
	end
	
	if old then
		self.image:paste(old, 0, 0, 0, 0, old:getWidth(), old:getHeight())
	end
	
	self.texture = love.graphics.newImage(self.image)
end

---Returns the current atlas dimensions in pixels
---@return number, number
function class:getDimensions()
	return self.packer.width, self.packer.height
end

---Gets the texture, updates it if the atlas was dirty
---@return Texture
function class:getTexture()
	if self.dirty then
		self.dirty = false
		self.texture:replacePixels(self.image)
	end
	return self.texture
end

function class:getCachedSpacing(glyph)
	if not self.cache[glyph] then
		self.cache[glyph] = math.floor(self.rasterizer:getGlyphData(glyph):getAdvance() + 0.5)
	end
	return self.cache[glyph]
end

function class:getCachedKerning(prevGlyph, glyph)
	local id = prevGlyph .. glyph
	if not self.cache[id] then
		self.cache[id] = self.font:getKerning(prevGlyph, glyph)
	end
	return self.cache[id]
end

---@return DreamMaterializedCodepoints
function class:getNewCodePoints()
	---@class DreamMaterializedCodepoints
	---@type DreamMaterializedCodepoints
	local cps = {
		---@type string[]
		cps = { },
		---@type DreamIndexedCodepointMaterial[]
		materials = { },
	}
	return cps
end

---A more human readable representation of materialized text, built from text segments
---@class DreamMaterializedText
---@type DreamMaterializedText
local _ = {
	string = "",
	color = { 1, 1, 1, 1 },
	roughness = 0.5,
	metallic = 0.0,
	emission = 0.0,
}

---Wraps a materialized text into lines
---@param text DreamMaterializedText
---@param wrapLimit number
function class:getWrap(text, wrapLimit)
	local codepoints = class:getNewCodePoints()
	
	for _, v in ipairs(text) do
		local index = #codepoints.cps + 1
		for c in class.charIter(v.string) do
			table.insert(codepoints.cps, c)
		end
		
		---@class DreamCodepointMaterial
		---@type DreamCodepointMaterial
		local m = {
			color = v.color,
			roughness = v.roughness,
			metallic = v.metallic,
			emission = v.emission
		}
		
		---@class DreamIndexedCodepointMaterial
		---@type DreamIndexedCodepointMaterial
		local cp = {
			index = index,
			material = m,
		}
		
		table.insert(codepoints.materials, cp)
	end
	
	return self:getCodepointWrap(codepoints, wrapLimit)
end

---Wraps the given materialized code points and returns a list of line widths and a list of materialized code points.
---This implementation is translated from love2d internal code and adapted to support materials instead of colors
---@param codepoints DreamMaterializedCodepoints
---@param wrapLimit number
---@return number[], DreamMaterializedCodepoints[]
function class:getCodepointWrap(codepoints, wrapLimit)
	local lineWidths = { }
	local lines = { }
	
	-- Per-line info.
	local width = 0.0
	local widthBeforeLastSpace = 0.0
	local widthOfTrailingSPace = 0.0
	local previousGlyph = string.char(0)
	local lastSpaceIndex = 0
	
	-- Keeping the indexed materials "in sync" is a bit tricky, since we split
	-- things up and we might skip some glyphs but we don't want to skip any
	-- color which starts at those indices.
	local currentMaterial = codepoints.materials[1]
	local addCurrentMaterial = false
	local currentMaterialIndex = 0
	local endMaterialIndex = #codepoints.materials
	
	-- A wrapped line of text.
	---@class ColoredCodepoints
	---@type ColoredCodepoints
	local currentLine = class:getNewCodePoints()
	
	local i = 1
	while i <= #codepoints.cps do
		local c = codepoints.cps[i]
		
		-- Determine the current color before doing anything else, to make sure
		-- it's still applied to future glyphs even if this one is skipped.
		if currentMaterialIndex < endMaterialIndex and codepoints.materials[currentMaterialIndex + 1].index == i then
			currentMaterial = codepoints.materials[currentMaterialIndex + 1].material
			currentMaterialIndex = currentMaterialIndex + 1
			addCurrentMaterial = true
		end
		
		-- Split text at newlines.
		if c == '\n' then
			table.insert(lines, currentLine)
			
			-- Ignore the width of any trailing spaces, for individual lines.
			table.insert(lineWidths, width - widthOfTrailingSPace)
			
			-- Make sure the new line keeps any color that was set previously.
			addCurrentMaterial = true
			
			width = 0.0
			widthBeforeLastSpace = 0.0
			widthOfTrailingSPace = 0.0
			previousGlyph = string.char(0)
			lastSpaceIndex = 0
			currentLine = class:getNewCodePoints()
			i = i + 1
			
			goto continue
		end
		
		-- Ignore carriage returns
		if c == '\r' then
			i = i + 1
			goto continue
		end
		
		local g = self:getCachedSpacing(c)
		local charWidth = g + self:getCachedKerning(previousGlyph, c)
		local newWidth = width + charWidth
		
		-- Wrap the line if it exceeds the wrap limit. Don't wrap yet if we're
		-- processing a newline character, though.
		if c ~= ' ' and newWidth > wrapLimit then
			-- If this is the first character in the line and it exceeds the
			-- limit, skip it completely.
			if (#currentLine.cps == 0) then
				i = i + 1
			elseif lastSpaceIndex ~= 0 then
				-- 'Rewind' to the last seen space, if the line has one.
				while #currentLine.cps > 0 and currentLine.cps[#currentLine.cps] ~= ' ' do
					table.remove(currentLine.cps)
				end
				
				while #currentLine.materials > 0 and currentLine.materials[#currentLine.materials].index >= #currentLine.cps do
					table.remove(currentLine.materials)
				end
				
				-- Also 'rewind' to the color that the last character is using.
				for materialIndex = currentMaterialIndex, 1, -1 do
					if codepoints.materials[materialIndex].index <= lastSpaceIndex + 1 then
						currentMaterial = codepoints.materials[materialIndex].material
						currentMaterialIndex = materialIndex
						break
					end
				end
				
				-- Ignore the width of trailing spaces in wrapped lines.
				width = widthBeforeLastSpace
				
				-- Start the next line after the space.
				i = lastSpaceIndex + 1
			end
			
			table.insert(lines, currentLine)
			table.insert(lineWidths, width)
			
			addCurrentMaterial = true
			
			previousGlyph = string.char(0)
			width = 0.0
			widthBeforeLastSpace = 0.0
			widthOfTrailingSPace = 0.0
			currentLine = class:getNewCodePoints()
			lastSpaceIndex = 0
			
			goto continue
		end
		
		if previousGlyph ~= ' ' and c == ' ' then
			widthBeforeLastSpace = width
		end
		
		width = newWidth
		previousGlyph = c
		
		if addCurrentMaterial then
			table.insert(currentLine.materials, { index = #currentLine.cps + 1, material = currentMaterial })
			addCurrentMaterial = false
		end
		
		table.insert(currentLine.cps, c)
		
		-- Keep track of the last seen space, so we can "rewind" to it when
		-- wrapping.
		if c == ' ' then
			lastSpaceIndex = i
			widthOfTrailingSPace = widthOfTrailingSPace + charWidth
		elseif c ~= '\n' then
			widthOfTrailingSPace = 0.0
		end
		i = i + 1
		
		:: continue ::
	end
	
	-- Push the last line.
	table.insert(lines, currentLine)
	
	-- Ignore the width of any trailing spaces, for individual lines.
	if lineWidths then
		table.insert(lineWidths, width - widthOfTrailingSPace)
	end
	
	return lineWidths, lines
end

return class