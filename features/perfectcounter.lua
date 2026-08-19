return {
	Name = "PerfectCounter",
	Enabled = false,
	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,
	Enable = function(self)
		-- TODO: count perfect inputs.
	end,
	Disable = function(self) end,
	Destroy = function(self)
		self.BeatX = nil
	end,
}
