return {
	activateShaderModule = function(obj, name)
		if not obj.modules then
			obj.modules = { }
		end
		obj.modules[name] = true
		
		if obj.initModules then
			obj:initModules()
		end
	end,
	
	deactivateShaderModule = function(obj, name)
		if obj.modules then
			obj.modules[name] = nil
		end
	end,
	
	isShaderModuleActive = function(obj, name)
		return obj.modules and obj.modules[name]
	end
}