--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Window

 Responsible for the whole menu container: Open, Close,
 animation and theme propagation. Thin wrapper around the
 existing Menu instance so width, collapse, drag and
 RightShift behavior stay untouched.
 Attached by Main.Start after menu creation with the central
 Animation, Theme and Localization systems.
]]

local Window = {}
Window.__index = Window

local MENU_TOP_Y = 5

-- Attaches window behavior to an existing menu instance.
function Window.Attach(menu, ctx)
	assert(menu, "menu missing")
	ctx = ctx or {}
	local animation = ctx.Animation
	local theme = ctx.Theme
	local localization = ctx.Localization

	local tweenService
	pcall(function()
		tweenService = game:GetService("TweenService")
	end)

	local self = setmetatable({
		Menu = menu,
		_ctx = ctx,
		_tweens = {},
		_destroyed = false,
	}, Window)

	local function stopTweens()
		for _, tw in ipairs(self._tweens) do
			pcall(function() tw:Cancel() end)
		end
		self._tweens = {}
	end
	self._stopTweens = stopTweens

	local themeUnsub
	if theme and type(theme.Subscribe) == "function" then
		themeUnsub = theme:Subscribe(function()
			self:ApplyTheme()
		end)
	end
	self._themeUnsub = themeUnsub

	local locUnsub
	if localization and type(localization.Subscribe) == "function" then
		locUnsub = localization:Subscribe(function()
			self:RefreshText()
		end)
	end
	self._locUnsub = locUnsub

	-- Returns the active animation duration, defaulting to instant.
	function self:GetDuration()
		if animation and type(animation.GetDuration) == "function" then
			return animation:GetDuration()
		end
		return 0
	end

	-- Window-level theme hook. BeatX rows repaint via their own
	-- subscriptions; legacy columns keep hardcoded colors by design.
	function self:ApplyTheme()
	end

	-- Propagates label refresh to every declarative category.
	function self:RefreshText()
		local cols = self.Menu and self.Menu.Columns or nil
		if type(cols) == "table" then
			for _, col in ipairs(cols) do
				if col and col.Category and type(col.Category.RefreshText) == "function" then
					pcall(function() col.Category:RefreshText() end)
				end
			end
		end
		if self.Menu and self.Menu.BeatXCategory
			and type(self.Menu.BeatXCategory.RefreshText) == "function" then
			pcall(function() self.Menu.BeatXCategory:RefreshText() end)
		end
	end

	-- Shows the menu with a slide-in of the active duration.
	function self:Open()
		if self._destroyed then
			return
		end
		if self.Menu.Visible then
			return
		end
		stopTweens()
		local duration = self:GetDuration()
		if duration <= 0.0001 or not tweenService then
			self.Menu:Open()
			return
		end
		self.Menu:Open()
		local canvas = self.Menu.Canvas
		if canvas then
			local targetY = MENU_TOP_Y
			pcall(function()
				local guiW = self.Menu.Gui and self.Menu.Gui.AbsoluteSize.X or 0
				canvas.AnchorPoint = Vector2.new(0.5, 0)
				canvas.Position = UDim2.fromOffset(guiW * 0.5, targetY - 12)
				local tw = tweenService:Create(
					canvas,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(guiW * 0.5, targetY) }
				)
				table.insert(self._tweens, tw)
				tw:Play()
			end)
		end
	end

	-- Hides the menu after a slide-out of the active duration.
	function self:Close()
		if self._destroyed then
			return
		end
		if not self.Menu.Visible then
			return
		end
		stopTweens()
		local duration = self:GetDuration()
		if duration <= 0.0001 or not tweenService then
			self.Menu:Close()
			return
		end
		local canvas = self.Menu.Canvas
		if canvas then
			local ok = pcall(function()
				local tw = tweenService:Create(
					canvas,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Position = canvas.Position - UDim2.fromOffset(0, 12) }
				)
				table.insert(self._tweens, tw)
				tw:Play()
				tw.Completed:Connect(function()
					if self._destroyed then
						return
					end
					self.Menu:Close()
				end)
			end)
			if not ok then
				self.Menu:Close()
			end
		else
			self.Menu:Close()
		end
	end

	-- Toggles visibility.
	function self:Toggle()
		if self.Menu.Visible then
			self:Close()
		else
			self:Open()
		end
	end

	-- Stops tweens and releases subscriptions. Menu itself stays owned by Main.
	function self:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
		stopTweens()
		if self._themeUnsub then
			pcall(self._themeUnsub)
		end
		if self._locUnsub then
			pcall(self._locUnsub)
		end
	end

	return self
end

return Window
