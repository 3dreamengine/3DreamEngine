---@type Dream
local lib = _3DreamEngine

local vec3 = lib.vec3

---Creates a text mesh builder
---@param glyphAtlas DreamGlyphAtlas
---@return DreamTextMeshBuilder
function lib:newTextMeshBuilder(glyphAtlas)
	local material = lib:newMaterial("font")
	material:setPixelShader("font")
	material:setCullMode("none")
	material:setAlpha()
	
	---@type DreamTextMeshBuilder
	local mesh = lib:newMeshBuilder(material)
	setmetatable(mesh, self.meta.textMeshBuilder)
	
	mesh.glyphAtlas = glyphAtlas
	
	return mesh
end

---todo
---@class DreamTextMeshBuilder : DreamMeshBuilder
local class = {
	links = { "meshBuilder", "textMeshBuilder" },
}

---Print a simple, single line text
---@param text string
---@param transform DreamMat4
function class:print(text, transform)
	local codepoints = self.glyphAtlas:getNewCodePoints()
	codepoints.cps = self.glyphAtlas:splitCharacters(text)
	self:createVertices({ 0 }, { codepoints }, 0, "left", transform)
end

---Print a formatted text
---@param text DreamMaterializedText | string
---@param wrapLimit number
---@param align string
---@param transform DreamMat4
function class:printf(text, wrapLimit, align, transform)
	local lineWidths, codepoints = self.glyphAtlas:getWrap(type(text) == "string" and { { string = text } } or text, wrapLimit)
	self:createVertices(lineWidths, codepoints, wrapLimit, align or "left", transform)
end

---Creates the vertices
---@param lineWidths number[]
---@param lines DreamMaterializedCodepoints[]
---@param wrapLimit number
---@param align string
---@param transform DreamMat4
---@private
function class:createVertices(lineWidths, lines, wrapLimit, align, transform)
	local top = vec3({ 0, 1, 0 })
	local right = vec3({ 1, 0, 0 })
	local normal = vec3({ 0, 0, -1 })
	local origin = vec3({ 0, 0, 0 })
	
	if transform then
		local subm = transform:subm()
		top = subm * top
		right = subm * right
		normal = subm * normal
		origin = transform:getTranslation()
	end
	
	for lineNr, codepoints in ipairs(lines) do
		---@type DreamCodepointMaterial
		local currentMaterial = { }
		local materialIndex = 0
		local prevGlyph = string.char(0)
		
		local pos = origin
		
		if align == "right" then
			pos = pos + right * (wrapLimit - lineWidths[lineNr])
		elseif align == "center" then
			pos = pos + right * ((wrapLimit - lineWidths[lineNr]) / 2)
		elseif align == "originCenter" then
			pos = pos - right * lineWidths[lineNr] / 2
		end
		
		pos = pos - top * (math.floor(self.glyphAtlas.font:getHeight() * self.glyphAtlas.font:getLineHeight() + 0.5) * lineNr)
		
		for cid, c in ipairs(codepoints.cps) do
			-- Next material
			if materialIndex < #codepoints.materials and cid == codepoints.materials[materialIndex + 1].index then
				currentMaterial = codepoints.materials[materialIndex + 1].material
				materialIndex = materialIndex + 1
			end
			
			pos = pos + right * self.glyphAtlas:getCachedKerning(prevGlyph, c)
			
			local glyph = self.glyphAtlas:getGlyph(c)
			if glyph then
				local pointer = self:addQuad()
				
				pointer[0].VertexPositionX = pos.x + right.x * glyph.offsetX
				pointer[0].VertexPositionY = pos.y + top.y * glyph.offsetY
				pointer[0].VertexPositionZ = pos.z
				pointer[1].VertexPositionX = pos.x + right.x * (glyph.offsetX + glyph.width)
				pointer[1].VertexPositionY = pos.y + top.y * glyph.offsetY
				pointer[1].VertexPositionZ = pos.z
				pointer[2].VertexPositionX = pos.x + right.x * (glyph.offsetX + glyph.width)
				pointer[2].VertexPositionY = pos.y + top.y * (glyph.offsetY - glyph.height)
				pointer[2].VertexPositionZ = pos.z
				pointer[3].VertexPositionX = pos.x + right.x * glyph.offsetX
				pointer[3].VertexPositionY = pos.y + top.y * (glyph.offsetY - glyph.height)
				pointer[3].VertexPositionZ = pos.z
				
				pointer[0].VertexTexCoordX = glyph.x
				pointer[0].VertexTexCoordY = glyph.y
				pointer[1].VertexTexCoordX = glyph.x + glyph.width
				pointer[1].VertexTexCoordY = glyph.y
				pointer[2].VertexTexCoordX = glyph.x + glyph.width
				pointer[2].VertexTexCoordY = glyph.y + glyph.height
				pointer[3].VertexTexCoordX = glyph.x
				pointer[3].VertexTexCoordY = glyph.y + glyph.height
				
				for i = 1, 4 do
					local v = pointer[i - 1]
					
					v.VertexNormalX = normal.x * 127.5 + 127.5
					v.VertexNormalY = normal.y * 127.5 + 127.5
					v.VertexNormalZ = normal.z * 127.5 + 127.5
					
					v.VertexMaterialX = (currentMaterial.roughness or self.material.roughness) * 255
					v.VertexMaterialY = (currentMaterial.metallic or self.material.metallic) * 255
					v.VertexMaterialZ = (currentMaterial.emission or self.material.emission[1]) * 255
					
					local color = currentMaterial.color or self.material.color
					v.VertexColorX = color[1] * 255
					v.VertexColorY = color[2] * 255
					v.VertexColorZ = color[3] * 255
					v.VertexColorW = color[4] * 255
				end
			end
			
			pos = pos + right * self.glyphAtlas:getCachedSpacing(c)
			prevGlyph = c
		end
	end
	
	self:getMaterial():setAlbedoTexture(self.glyphAtlas:getTexture())
end

return class