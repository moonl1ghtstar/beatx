return {
	Name = "Visual",
	Enabled = false,
	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,
	Enable = function(self)
		-- TODO: add visual overlays.
	end,
	Disable = function(self) end,
	Destroy = function(self)
		self.BeatX = nil
	end,
}
