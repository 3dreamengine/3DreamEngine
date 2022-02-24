local sh = { }

sh.type = "vertex"

sh.maxJoints = 64

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:initMesh(dream, mesh)
	if mesh:getMesh("mesh") then
		if not mesh:getMesh("boneMesh") then
			assert(mesh.joints and mesh.weights, "GPU bones require a joint and weight buffer")
			mesh.boneMesh = love.graphics.newMesh({{"VertexJoint", "float", 4}, {"VertexWeight", "float", 4}}, #mesh.joints, "triangles", "static")
			
			--create mesh
			for index = 1, #mesh.joints do
				local w = mesh.weights[index]
				local j = mesh.joints[index]
				local sum = (w[1] or 0) + (w[2] or 0) + (w[3] or 0) + (w[4] or 0)
				mesh.boneMesh:setVertex(index, (j[1] or 0) / 255, (j[2] or 0) / 255, (j[3] or 0) / 255, (j[4] or 0) / 255, (w[1] or 0) / sum, (w[2] or 0) / sum, (w[3] or 0) / sum, (w[4] or 0) / sum)
			end
		end
		
		mesh:getMesh("mesh"):attachAttribute("VertexJoint", mesh:getMesh("boneMesh"))
		mesh:getMesh("mesh"):attachAttribute("VertexWeight", mesh:getMesh("boneMesh"))
	end
end

function sh:buildDefines(dream, mat)
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

function sh:buildPixel(dream, mat)
	return ""
end

function sh:buildVertex(dream, mat)
	return [[
	mat4 boneTransform = (
		jointTransforms[int(VertexJoint[0]*255.0)] * VertexWeight[0] +
		jointTransforms[int(VertexJoint[1]*255.0)] * VertexWeight[1] +
		jointTransforms[int(VertexJoint[2]*255.0)] * VertexWeight[2] +
		jointTransforms[int(VertexJoint[3]*255.0)] * VertexWeight[3]
	);
	
	vertexPos = (boneTransform * VertexPosition).xyz;
	vertexPos = (transform * vec4(vertexPos.xyz, 1.0)).xyz;
	
	normalTransform = mat3(boneTransform) * normalTransform;
	]]
end

function sh:perShader(dream, shaderObject)
	
end

function sh:perMaterial(dream, shaderObject, material)
	
end

function sh:perTask(dream, shaderObject, task)
	local bt = task:getBoneTransforms()
	assert(bt, "missing bone transforms")
	
	if shaderObject.session.bones ~= bt then
		local mesh = task:getMesh()
		local matrices = { }
		for i = 1, self.maxJoints do
			matrices[i] = bt[i - 1] or mat4:getIdentity()
		end
		if #matrices > self.maxJoints and not mesh._jointExceededWarning then
			mesh._jointExceededWarning = true
			print(string.format("mesh %s has %d joints, but the shader is limited to %d", mesh.name, #matrices, self.maxJoints))
		end
		shaderObject.shader:send("jointTransforms", unpack(matrices))
	end
end

return sh