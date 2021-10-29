local sh = { }

sh.type = "vertex"

sh.maxJoints = 64

function sh:getId(dream, mat, shadow)
	return 0
end

function sh:initObject(dream, obj)
	if obj.mesh then
		--initial prepare bone data
		if not obj.boneMesh and not obj.meshes then
			assert(obj.joints and obj.weights, "GPU bones require a joint and weight buffer")
			obj.boneMesh = love.graphics.newMesh({{"VertexJoint", "byte", 4}, {"VertexWeight", "byte", 4}}, #obj.joints, "triangles", "static")
			
			--create mesh
			for index = 1, #obj.joints do
				local w = obj.weights[index]
				local j = obj.joints[index]
				obj.boneMesh:setVertex(index, (j[1] or 0) / 255, (j[2] or 0) / 255, (j[3] or 0) / 255, (j[4] or 0) / 255, w[1] or 0, w[2] or 0, w[3] or 0, w[4] or 0)
			end
		end
		
		if obj.boneMesh then
			obj:getMesh("mesh"):attachAttribute("VertexJoint", obj:getMesh("boneMesh"))
			obj:getMesh("mesh"):attachAttribute("VertexWeight", obj:getMesh("boneMesh"))
		end
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
	
	VertexPos = (boneTransform * VertexPosition).xyz;
	VertexPos = (transform * vec4(VertexPos.xyz, 1.0)).xyz;
	
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