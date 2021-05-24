local sh = { }

sh.type = "vertex"

sh.maxJoints = 16

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
			for d,s in ipairs(obj.joints) do
				local w = obj.weights[d]
				obj.boneMesh:setVertex(d, (s[1] or 0) / 255, (s[2] or 0) / 255, (s[3] or 0) / 255, (s[4] or 0) / 255, w[1] or 0, w[2] or 0, w[3] or 0, w[4] or 0)
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
		shaderObject.session.bones = bt
		local matrices = {mat4:getIdentity()}
		if task:getSubObj().jointIDs then
			for i,j in ipairs(task:getSubObj().jointIDs) do
				matrices[i+1] = bt[j]
			end
		end
		shaderObject.shader:send("jointTransforms", unpack(matrices))
	end
end

return sh