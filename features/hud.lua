return {
	Name = "HUD",
	Enabled = false,
	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,
	Enable = function(self)
		-- TODO: render counters and status panels.
	end,
	Disable = function(self) end,
	Destroy = function(self)
		self.BeatX = nil
	end,
}
