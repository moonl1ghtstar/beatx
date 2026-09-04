--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Animation (central)

 Responsible for the shared menu animation duration in the
 0.00-1.00 range with 0.05 steps. Zero means instant display.
 No component hardcodes its own duration.
 Created by Main.Start after SettingsStore; Window reads the
 duration for Open/Close tweens and the Animation Button writes it.
]]

local Animation = {}
Animation.__index = Animation

local MIN_D = 0
local MAX_D = 1
local STEP = 0.05

-- Clamps a raw value into range and snaps it to the step grid.
local function quantize(v)
	v = math.clamp(tonumber(v) or 0.25, MIN_D, MAX_D)
	v = math.floor(v / STEP + 0.5) * STEP
	return math.clamp(v, MIN_D, MAX_D)
end

-- Builds animation state seeded from the settings store when present.
function Animation.new(settings)
	local initial = 0.25
	if settings and type(settings.Get) == "function" then
		local saved = settings:Get("AnimationDuration")
		if type(saved) == "number" then
			initial = quantize(saved)
		end
	end
	local self = setmetatable({
		_settings = settings,
		_duration = initial,
		_listeners = {},
	}, Animation)
	return self
end

-- Returns the active duration in seconds.
function Animation:GetDuration()
	return self._duration
end

-- Reports whether Open/Close must skip tweens.
function Animation:ShouldInstant()
	return self._duration <= 0.0001
end

-- Stores a quantized duration, persists it and notifies subscribers.
function Animation:SetDuration(v)
	local q = quantize(v)
	if self._duration == q then
		return true
	end
	self._duration = q
	if self._settings and type(self._settings.Set) == "function" then
		self._settings:Set("AnimationDuration", q)
	end
	for _, cb in ipairs(self._listeners) do
		pcall(cb, q)
	end
	return true
end

-- Builds a TweenInfo using the active duration.
function Animation:MakeTweenInfo(style, direction)
	return TweenInfo.new(
		self._duration,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
end

-- Subscribes to duration changes. Returns an unsubscribe closure.
function Animation:Subscribe(callback)
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

return Animation
