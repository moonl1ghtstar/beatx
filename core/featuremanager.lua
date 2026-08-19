local FeatureManager = {}
FeatureManager.__index = FeatureManager

function FeatureManager.new(context)
	return setmetatable({ Context = context, Features = {} }, FeatureManager)
end

local function invoke(feature, method, ...)
	local callback = feature[method]
	if type(callback) ~= "function" then
		return true
	end
	local ok, errorMessage = pcall(callback, feature, ...)
	if not ok then
		warn(string.format("[BeatX] %s.%s failed: %s", feature.Name, method, errorMessage))
	end
	return ok
end

function FeatureManager:Register(feature)
	assert(type(feature) == "table" and type(feature.Name) == "string", "Invalid feature")
	assert(not self.Features[feature.Name], "Feature already registered: " .. feature.Name)
	feature.Enabled = false
	if invoke(feature, "Init", self.Context) then
		self.Features[feature.Name] = feature
	end
	return feature
end

function FeatureManager:Get(name)
	return self.Features[name]
end

function FeatureManager:IsEnabled(name)
	local feature = self:Get(name)
	return feature ~= nil and feature.Enabled == true
end

function FeatureManager:Enable(name)
	local feature = assert(self:Get(name), "Unknown feature: " .. name)
	if feature.Enabled or not invoke(feature, "Enable") then
		return feature
	end
	feature.Enabled = true
	return feature
end

function FeatureManager:Disable(name)
	local feature = assert(self:Get(name), "Unknown feature: " .. name)
	if feature.Enabled and invoke(feature, "Disable") then
		feature.Enabled = false
	end
	return feature
end

function FeatureManager:EnableAll(settings)
	for name in pairs(self.Features) do
		local enabled = settings == nil or settings[name] or settings[string.lower(name)]
		if enabled then
			self:Enable(name)
		end
	end
end

function FeatureManager:DisableAll()
	for name in pairs(self.Features) do
		self:Disable(name)
	end
end

function FeatureManager:Destroy()
	self:DisableAll()
	for _, feature in pairs(self.Features) do
		invoke(feature, "Destroy")
	end
	self.Features = {}
end

return FeatureManager
