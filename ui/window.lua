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

 Responsible for the whole menu container: instant Open, Close
 and theme propagation. Thin wrapper around the existing Menu
 instance so width, collapse, drag and RightShift behavior stay
 untouched. RightShift input handling and the GetFocusedTextBox
 guard live in main.lua and are preserved as-is.
 Attached by Main.Start after menu creation with the central
 Theme and Localization systems. No animation is used.
]]

local Window = {}
Window.__index = Window

-- Attaches window behavior to an existing menu instance.
function Window.Attach(menu, ctx)
	assert(menu, "menu missing")
	ctx = ctx or {}
	local theme = ctx.Theme
	local localization = ctx.Localization

	local self = setmetatable({
		Menu = menu,
		_ctx = ctx,
		_destroyed = false,
	}, Window)

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

	-- Returns zero: Open/Close never animate.
	function self:GetDuration()
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

	-- Shows the menu immediately.
	function self:Open()
		if self._destroyed then
			return
		end
		if self.Menu.Visible then
			return
		end
		self.Menu:Open()
	end

	-- Hides the menu immediately.
	function self:Close()
		if self._destroyed then
			return
		end
		if not self.Menu.Visible then
			return
		end
		self.Menu:Close()
	end

	-- Toggles visibility.
	function self:Toggle()
		if self.Menu.Visible then
			self:Close()
		else
			self:Open()
		end
	end

	-- Releases subscriptions. Menu itself stays owned by Main.
	function self:Destroy()
		if self._destroyed then
			return
		end
		self._destroyed = true
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
