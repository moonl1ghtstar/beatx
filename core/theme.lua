--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Theme (central)

 Responsible for the shared color palettes (Dark/Light/Midnight)
 keyed by Background/Surface/Text/SecondaryText/Accent/Border/
 Hover/Active. Dark maps the legacy ui/menu.lua C table so the
 existing look stays default.
 Components read colors via Get and repaint through Subscribe.
 Created by Main.Start after SettingsStore; Set persists the
 choice and notifies subscribers for instant repaint.
]]

local Theme = {}
Theme.__index = Theme

local PRESETS = {
	Dark = {
		Background = Color3.fromRGB(18, 17, 22),
		Surface = Color3.fromRGB(22, 21, 27),
		Text = Color3.fromRGB(255, 255, 255),
		SecondaryText = Color3.fromRGB(210, 205, 220),
		Accent = Color3.fromRGB(232, 56, 102),
		Border = Color3.fromRGB(34, 32, 41),
		Hover = Color3.fromRGB(32, 30, 38),
		Active = Color3.fromRGB(140, 20, 55),
	},
	Light = {
		Background = Color3.fromRGB(242, 242, 246),
		Surface = Color3.fromRGB(255, 255, 255),
		Text = Color3.fromRGB(24, 22, 30),
		SecondaryText = Color3.fromRGB(96, 92, 110),
		Accent = Color3.fromRGB(232, 56, 102),
		Border = Color3.fromRGB(222, 220, 230),
		Hover = Color3.fromRGB(234, 232, 240),
		Active = Color3.fromRGB(232, 56, 102),
	},
	Midnight = {
		Background = Color3.fromRGB(8, 8, 16),
		Surface = Color3.fromRGB(14, 12, 26),
		Text = Color3.fromRGB(246, 242, 255),
		SecondaryText = Color3.fromRGB(181, 174, 204),
		Accent = Color3.fromRGB(150, 78, 255),
		Border = Color3.fromRGB(30, 25, 44),
		Hover = Color3.fromRGB(24, 20, 40),
		Active = Color3.fromRGB(108, 62, 220),
	},
}

local ORDER = { "Dark", "Light", "Midnight" }

-- Lists available preset names in cycle order.
function Theme.List()
	return { "Dark", "Light", "Midnight" }
end

-- Returns the preset following the given one, wrapping around.
function Theme.NextName(current)
	for i, name in ipairs(ORDER) do
		if name == current then
			return ORDER[(i % #ORDER) + 1]
		end
	end
	return ORDER[1]
end

-- Builds a theme seeded from the settings store when present.
function Theme.new(settings)
	local initial = "Dark"
	if settings and type(settings.Get) == "function" then
		local saved = settings:Get("Theme")
		if PRESETS[saved] then
			initial = saved
		end
	end
	local self = setmetatable({
		_settings = settings,
		_current = initial,
		_listeners = {},
	}, Theme)
	return self
end

-- Returns the active preset name.
function Theme:CurrentName()
	return self._current
end

-- Returns one color of the active preset, falling back to Dark.
function Theme:Get(key)
	local preset = PRESETS[self._current]
	if preset and preset[key] then
		return preset[key]
	end
	return PRESETS.Dark[key]
end

-- Returns a snapshot of the active preset.
function Theme:GetAll()
	local preset = PRESETS[self._current] or PRESETS.Dark
	return {
		Background = preset.Background,
		Surface = preset.Surface,
		Text = preset.Text,
		SecondaryText = preset.SecondaryText,
		Accent = preset.Accent,
		Border = preset.Border,
		Hover = preset.Hover,
		Active = preset.Active,
	}
end

-- Activates a preset, persists it and notifies subscribers.
function Theme:Set(name)
	if not PRESETS[name] then
		return false
	end
	if self._current == name then
		return true
	end
	self._current = name
	if self._settings and type(self._settings.Set) == "function" then
		self._settings:Set("Theme", name)
	end
	for _, cb in ipairs(self._listeners) do
		pcall(cb, name)
	end
	return true
end

-- Advances to the next preset.
function Theme:Cycle()
	return self:Set(Theme.NextName(self._current))
end

-- Subscribes to preset changes. Returns an unsubscribe closure.
function Theme:Subscribe(callback)
	if type(callback) ~= "function" then
		return function() end
	end
	table.insert(self._listeners, callback)
	return function()
		for i, cb in ipairs(self._listeners) do
			if cb == callback then
				table.remove(self._listeners, i)
				break
			end
		end
	end
end

return Theme
