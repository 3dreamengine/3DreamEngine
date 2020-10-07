return {
	activateShaderModule = function(obj, name)
		if not obj.modules then
			obj.modules = { }
		end
		obj.modules[name] = true
	end,
	
	deactivateShaderModule = function(obj, name)
		obj.modules[name] = nil
	end,
	
	isShaderModuleActive = function(obj, name)
		return obj.modules and obj.modules[name]
	end
}