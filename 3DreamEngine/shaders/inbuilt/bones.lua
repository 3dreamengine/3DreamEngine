local sh = { }

sh.type = "vertex"

sh.maxJoints = 64

function sh:getId(mat, shadow)
	return 0
end

local meshFormat = {
	{ "VertexJoint", "float", 4 },
	{ "VertexWeight", "float", 4 }
}

function sh:initMesh(mesh)
	if not mesh:getMesh("boneMesh") then
		assert(mesh.joints and mesh.weights, "GPU bones require a joint and weight buffer")
		mesh.boneMesh = love.graphics.newMesh(meshFormat, mesh.joints:getSize(), "triangles", "static")
		
		--create mesh
		for index = 1, mesh.joints:getSize() do
			local w = mesh.weights:get(index)
			local j = mesh.joints:get(index)
			local sum = (w.x or 0) + (w.y or 0) + (w.z or 0) + (w.w or 0)
			mesh.boneMesh:setVertex(index,
					(j.x or 0) / 255, (j.y or 0) / 255, (j.z or 0) / 255, (j.w or 0) / 255,
					(w.x or 0) / sum, (w.y or 0) / sum, (w.z or 0) / sum, (w.w or 0) / sum)
		end
	end
	
	mesh:getMesh():attachAttribute("VertexJoint", mesh:getMesh("boneMesh"))
	mesh:getMesh():attachAttribute("VertexWeight", mesh:getMesh("boneMesh"))
end

function sh:buildDefines(mat)
	return [[
		#ifdef VERTEX
		#define BONE
		
		const int MAX_JOINTS = ]] .. self.maxJoints .. [[;
		
		extern mat4 jointTransforms[MAX_JOINTS];
		
		attribute vec4 VertexJoint;
		attribute vec4 VertexWeight;
		#endif
	]]
end

function sh:buildPixel(mat)
	return ""
end

function sh:buildVertex(mat)
	return [[
	mat4 boneTransform = (
		jointTransforms[int(VertexJoint[0]*255.0)] * VertexWeight[0] +
		jointTransforms[int(VertexJoint[1]*255.0)] * VertexWeight[1] +
		jointTransforms[int(VertexJoint[2]*255.0)] * VertexWeight[2] +
		jointTransforms[int(VertexJoint[3]*255.0)] * VertexWeight[3]
	);
	
	vertexPos = (transform * (boneTransform * vec4(VertexPosition.xyz, 1.0))).xyz;
	
	normalTransform = normalTransform * mat3(boneTransform);
	]]
end

function sh:perShader(shaderObject)

end

function sh:perMaterial(shaderObject, material)

end

local ID = mat4.getIdentity()
function sh:perTask(shaderObject, task)
	local bt = task:getBoneTransforms()
	assert(bt, "Missing bone transforms")
	
	if shaderObject.session.bones ~= bt then
		local mesh = task:getMesh()
		local matrices = { }
		for i = 1, #mesh.jointNames do
			local tr = bt[mesh.jointNames[i]]
			if tr then
				matrices[i] = tr * mesh.inverseBindMatrices[i]
			else
				matrices[i] = mesh.inverseBindMatrices[i]
			end
		end
		for i = #mesh.jointNames + 1, self.maxJoints do
			matrices[i] = ID
		end
		if #matrices > self.maxJoints and not mesh._jointExceededWarning then
			mesh._jointExceededWarning = true
			print(string.format("Mesh %s has %d joints, but the shader is limited to %d", mesh.name, #matrices, self.maxJoints))
		end
		shaderObject.shader:send("jointTransforms", table.unpack(matrices))
	end
end

return sh