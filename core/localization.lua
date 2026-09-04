--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Localization (central)

 Responsible for UI strings keyed by feature_search,
 language_settings, theme, animation_duration and
 search_placeholder. Supported languages: Korean and English.
 Components fetch text via Get instead of hardcoding strings.
 Created by Main.Start after SettingsStore; SetLanguage
 persists the choice and notifies subscribers so the menu
 refreshes without restart.
]]

local Localization = {}
Localization.__index = Localization

local STRINGS = {
	["한국어"] = {
		feature_search = "Feature Search",
		language_settings = "Language",
		theme = "Theme",
		animation_duration = "Anim",
		search_placeholder = "Search...",
	},
	English = {
		feature_search = "Feature Search",
		language_settings = "Language",
		theme = "Theme",
		animation_duration = "Anim",
		search_placeholder = "Search...",
	},
}

-- Lists supported language names.
function Localization.List()
	return { "한국어", "English" }
end

-- Builds localization seeded from the settings store when present.
function Localization.new(settings)
	local initial = "한국어"
	if settings and type(settings.Get) == "function" then
		local saved = settings:Get("Language")
		if STRINGS[saved] then
			initial = saved
		end
	end
	local self = setmetatable({
		_settings = settings,
		_language = initial,
		_listeners = {},
	}, Localization)
	return self
end

-- Returns the active language name.
function Localization:GetLanguage()
	return self._language
end

-- Returns the string for a key, falling back to Korean then the key.
function Localization:Get(key)
	local pack = STRINGS[self._language] or STRINGS["한국어"]
	local value = pack[key]
	if value ~= nil then
		return value
	end
	local fallback = STRINGS["한국어"][key]
	if fallback ~= nil then
		return fallback
	end
	return tostring(key)
end

-- Activates a language, persists it and notifies subscribers.
function Localization:SetLanguage(lang)
	if not STRINGS[lang] then
		return false
	end
	if self._language == lang then
		return true
	end
	self._language = lang
	if self._settings and type(self._settings.Set) == "function" then
		self._settings:Set("Language", lang)
	end
	for _, cb in ipairs(self._listeners) do
		pcall(cb, lang)
	end
	return true
end

-- Subscribes to language changes. Returns an unsubscribe closure.
function Localization:Subscribe(callback)
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

return Localization
