return {
	Name = "Level",
	Category = "Level",
	Description = "Level options",
	Keywords = { "level" },
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
