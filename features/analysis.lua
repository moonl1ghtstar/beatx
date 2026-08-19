return {
	Name = "Analysis",
	Enabled = false,
	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,
	Enable = function(self)
		-- TODO: collect gameplay timing data.
	end,
	Disable = function(self) end,
	Destroy = function(self)
		self.BeatX = nil
	end,
}
