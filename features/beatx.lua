-- Core/UI-application category. Menu entries like Search, Language, Version,
-- Updates and Discord belong here as menu items, not as separate modules.
return {
	Name = "BeatX",
	Enabled = false,

	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,

	Enable = function(self)
		-- feature implementation
	end,

	Disable = function(self)
	end,

	Destroy = function(self)
		self.BeatX = nil
	end,
}
