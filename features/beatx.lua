-- Core/UI-application category. First declarative CategoryDef.
-- The BeatX category holds exactly 4 items and nothing else.
-- Feature Search / Language Settings / Theme / Animation Duration.
local CATEGORY_DEF = {
	Name = "BeatX",
	Items = {
		{
			type = "search",
			key = "feature_search",
		},
		{
			type = "dropdown",
			key = "language",
			labelKey = "language_settings",
			options = { "한국어", "English" },
			default = "한국어",
		},
		{
			type = "button",
			key = "theme",
			labelKey = "theme",
			default = "Dark",
		},
		{
			type = "button",
			key = "animation_duration",
			labelKey = "animation_duration",
			default = 0.25,
			min = 0,
			max = 1,
			step = 0.05,
		},
	},
}

return {
	Name = "BeatX",
	Category = "BeatX",
	Description = "BeatX core settings",
	Keywords = { "search", "language", "theme", "animation" },
	Enabled = false,
	CategoryDef = CATEGORY_DEF,

	Init = function(self, BeatX)
		self.BeatX = BeatX
		self._conns = self._conns or {}
	end,

	Enable = function(self)
		-- Menu owns the UI instances via the Category module.
		-- Guard keeps repeated Enable calls from duplicating UI.
		if self._uiWired then
			return
		end
		self._uiWired = true
	end,

	Disable = function(self)
		self._uiWired = false
		if type(self._conns) == "table" then
			for _, c in ipairs(self._conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			self._conns = {}
		end
	end,

	Destroy = function(self)
		if type(self._conns) == "table" then
			for _, c in ipairs(self._conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			self._conns = nil
		end
		self._uiWired = false
		self.BeatX = nil
	end,
}
