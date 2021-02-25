return {
	activateShaderModule = function(self, name)
		if not self.modules then
			self.modules = { }
		end
		self.modules[name] = true
		
		if self.initModules then
			self:initModules()
		end
	end,
	
	deactivateShaderModule = function(self, name)
		if self.modules then
			self.modules[name] = nil
		end
	end,
	
	isShaderModuleActive = function(self, name)
		return self.modules and self.modules[name]
	end
}