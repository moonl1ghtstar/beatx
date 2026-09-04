--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - SettingsStore

 Responsible for the BeatX namespace settings (Language, Theme)
 with validation, persistence and subscriptions.
 Sanitizes loaded data so corrupt files fall back to defaults.
 Created by Main.Start after Filesystem; Theme and Localization
 observe it instead of touching files themselves.
 Data flow: UI -> SettingsStore -> Filesystem Adapter -> BeatXConfig.json.
]]

local SettingsStore = {}
SettingsStore.__index = SettingsStore

local CONFIG_PATH = "BeatXConfig.json"
local NAMESPACE = "BeatX"

local DEFAULTS = {
	Language = "한국어",
	Theme = "Dark",
}

-- Returns an independent copy of the default values.
local function cloneDefaults()
	return {
		Language = DEFAULTS.Language,
		Theme = DEFAULTS.Theme,
	}
end

-- Merges a decoded file payload over defaults, dropping invalid fields.
local function sanitizeLoaded(loaded)
	local values = cloneDefaults()
	if type(loaded) ~= "table" then
		return values
	end
	local scoped = loaded[NAMESPACE]
	if type(scoped) ~= "table" then
		return values
	end
	if scoped.Language == "한국어" or scoped.Language == "English" then
		values.Language = scoped.Language
	end
	if scoped.Theme == "Dark" or scoped.Theme == "Light" or scoped.Theme == "Midnight" then
		values.Theme = scoped.Theme
	end
	return values
end

-- Builds a store bound to the given filesystem adapter (may be nil).
function SettingsStore.new(filesystem)
	local self = setmetatable({
		_filesystem = filesystem,
		_values = cloneDefaults(),
		_listeners = {},
	}, SettingsStore)
	return self
end

-- Returns the config file path.
function SettingsStore.GetPath()
	return CONFIG_PATH
end

-- Returns a copy of the default values.
function SettingsStore.GetDefaults()
	return cloneDefaults()
end

-- Loads persisted values, keeping defaults on any failure.
function SettingsStore:Load()
	if not self._filesystem then
		return self._values
	end
	local ok, loaded = pcall(function()
		return self._filesystem.readJson(CONFIG_PATH)
	end)
	if not ok then
		return self._values
	end
	self._values = sanitizeLoaded(loaded)
	return self._values
end

-- Persists current values. Returns false when unsupported.
function SettingsStore:Save()
	if not self._filesystem then
		return false
	end
	local payload = {
		[NAMESPACE] = {
			Language = self._values.Language,
			Theme = self._values.Theme,
		},
	}
	local ok, result = pcall(function()
		return self._filesystem.writeJson(CONFIG_PATH, payload)
	end)
	return ok and result == true
end

-- Reads a single namespaced value.
function SettingsStore:Get(key)
	return self._values[key]
end

-- Returns a snapshot of all namespaced values.
function SettingsStore:GetAll()
	return {
		Language = self._values.Language,
		Theme = self._values.Theme,
	}
end

-- Validates, stores, persists and notifies for one key.
function SettingsStore:Set(key, value, skipSave)
	if DEFAULTS[key] == nil then
		return false
	end
	if key == "Language" and value ~= "한국어" and value ~= "English" then
		return false
	end
	if key == "Theme" and value ~= "Dark" and value ~= "Light" and value ~= "Midnight" then
		return false
	end
	if self._values[key] == value then
		return true
	end
	self._values[key] = value
	if not skipSave then
		self:Save()
	end
	local listeners = self._listeners[key]
	if listeners then
		for _, cb in ipairs(listeners) do
			pcall(cb, value)
		end
	end
	return true
end

-- Subscribes to one key. Returns an unsubscribe closure.
function SettingsStore:Subscribe(key, callback)
	if type(callback) ~= "function" then
		return function() end
	end
	self._listeners[key] = self._listeners[key] or {}
	table.insert(self._listeners[key], callback)
	return function()
		local list = self._listeners[key]
		if not list then
			return
		end
		for i, cb in ipairs(list) do
			if cb == callback then
				table.remove(list, i)
				break
			end
		end
	end
end

return SettingsStore
