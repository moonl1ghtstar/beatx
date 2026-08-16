return {
	Name = "Verification",
	Enabled = false,
	Init = function(self, BeatX)
		self.BeatX = BeatX
	end,
	Enable = function(self)
		-- TODO: validate local observations before display.
	end,
	Disable = function(self) end,
	Destroy = function(self)
		self.BeatX = nil
	end,
}
