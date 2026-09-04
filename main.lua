--[[

 /$$$$$$$                        /$$     /$$   /$$
| $$__  $$                      | $$    | $$  / $$
| $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
| $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/ 
| $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$ 
| $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
| $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
|_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Main

]]--

local BEATX_GAME_ID = 5385674359

local function isSupportedGame()
	return game.GameId == BEATX_GAME_ID
end

-- Restriction gate: BeatX may run only in Beat Bounce (GameId 5385674359).
-- Kept in loader.lua/main.lua so no future UI change can bypass it. Runs
-- before any WindUI fetch, GUI, feature load or input connection can start.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

if not isSupportedGame() then
	warn("[BeatX] Restricted to game " .. tostring(BEATX_GAME_ID) .. ". Current game: " .. tostring(game.GameId) .. ". Aborting.")
	return {}
end

local BeatX = shared.BeatX or {}
BeatX.Name = "BeatX"
BeatX.Version = "0.1.0"
BeatX.Environment = shared.BeatXEnvironment

local MODULE_BASE_URL = shared.BeatXModuleBase or "https://raw.githubusercontent.com/moonl1ghtstar/beatx/main/"
local WINDUI_URL = shared.BeatXWindUIUrl
	or "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
local CACHE_FOLDER = "BeatXCache"

local function cachePath(path)
	return CACHE_FOLDER .. "/" .. path:gsub("/", "_")
end

local function readCached(path)
	local cached = cachePath(path)
	if type(isfile) == "function" and type(readfile) == "function" and isfile(cached) then
		return readfile(cached)
	end
	return nil
end

local function writeCached(path, source)
	if type(writefile) ~= "function" then
		return
	end
	if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(CACHE_FOLDER) then
		makefolder(CACHE_FOLDER)
	end
	writefile(cachePath(path), source)
end

local function fetch(path, url)
	local ok, source = pcall(function()
		local content = game:HttpGet(url, true)
		if content and content ~= "nil" then
			writeCached(path, content)
		end
		return content
	end)
	if ok and source and source ~= "nil" then
		return source
	end

	return readCached(path)
end

local function loadSource(path, url)
	print(string.format('[BeatX][Loader] Loading %s from %s', path, url))
	local source = fetch(path, url)
	assert(source, "BeatX module unavailable: " .. path)
	local chunk, compileError = loadstring(source, "@" .. path)
	assert(chunk, compileError)
	return chunk()
end

local function loadModule(path)
	local cacheBust = tostring(os.time())
	local url = MODULE_BASE_URL .. path .. "?v=" .. cacheBust
	return loadSource(path, url)
end

local Main = {}
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local BeatXMenu = nil

local function updateLoading(message, progress)
	local loader = shared.ACTIVE_LOADER
	if loader and type(loader.Update) == "function" then
		loader:Update(message, progress)
	end
end

local function toggleMenu()
	if not BeatXMenu then
		warn("[BeatX] Right Shift menu toggle unavailable: BeatXMenu has not been created.")
		return
	end
	-- Animated toggle when Window is attached, legacy instant toggle otherwise.
	if BeatX.Window and type(BeatX.Window.Toggle) == "function" then
		print(string.format('[BeatX][RightShift] Toggle requested; visibleBefore=%s', tostring(BeatXMenu.Visible)))
		BeatX.Window:Toggle()
		print(string.format('[BeatX][RightShift] Toggle completed; visibleAfter=%s', tostring(BeatXMenu.Visible)))
		return
	end
	print(string.format('[BeatX][RightShift] Toggle requested; visibleBefore=%s', tostring(BeatXMenu.Visible)))
	BeatXMenu:Toggle()
	print(string.format('[BeatX][RightShift] Toggle completed; visibleAfter=%s', tostring(BeatXMenu.Visible)))
end

local function installMenuToggle()
	if BeatX.MenuToggleInputConnection then
		BeatX.MenuToggleInputConnection:Disconnect()
	end
	if BeatX.MenuToggleInputEndedConnection then
		BeatX.MenuToggleInputEndedConnection:Disconnect()
	end

	local rightShiftDown = false
	BeatX.MenuToggleInputConnection = UserInputService.InputBegan:Connect(function(input)
		if rightShiftDown then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.RightShift then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end

		rightShiftDown = true
		print('[BeatX][RightShift] InputBegan detected')
		toggleMenu()
	end)

	BeatX.MenuToggleInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.RightShift then
			print('[BeatX][RightShift] InputEnded detected')
			rightShiftDown = false
		end
	end)
end

function Main.Start()
	if BeatX.Started then
		return BeatX
	end

	if not isSupportedGame() then
		warn("[BeatX] Restricted to game " .. tostring(BEATX_GAME_ID) .. ". Aborting.")
		return nil
	end

	updateLoading("Loading configuration...", 60)
	BeatX.Config = loadModule("core/config.lua")

	-- Core systems: Settings -> Theme / Localization / Animation.
	-- Optional modules stay silent on failure so the legacy menu still loads.
	local function tryLoad(path)
		local ok, mod = pcall(loadModule, path)
		if ok then
			return mod
		end
		warn("[BeatX] optional module unavailable: " .. path)
		return nil
	end
	local FilesystemMod = tryLoad("core/filesystem.lua")
	BeatX.Filesystem = FilesystemMod
	local SettingsMod = tryLoad("core/settingsstore.lua")
	if SettingsMod then
		BeatX.Settings = SettingsMod.new(FilesystemMod)
		pcall(function()
			BeatX.Settings:Load()
		end)
		-- Mirror persisted values into the Config.BeatX view.
		BeatX.Config.BeatX = BeatX.Settings:GetAll()
		BeatX.Config.UI.Theme = BeatX.Settings:Get("Theme")
	else
		BeatX.Config.BeatX = BeatX.Config.BeatX or {
			Language = "한국어",
			Theme = "Dark",
			AnimationDuration = 0.25,
		}
	end
	local ThemeMod = tryLoad("core/theme.lua")
	if ThemeMod then
		BeatX.Theme = ThemeMod.new(BeatX.Settings)
	end
	local LocalizationMod = tryLoad("core/localization.lua")
	if LocalizationMod then
		BeatX.Localization = LocalizationMod.new(BeatX.Settings)
	end
	local AnimationMod = tryLoad("core/animation.lua")
	if AnimationMod then
		BeatX.Animation = AnimationMod.new(BeatX.Settings)
	end
	-- Preload UI modules. menu.lua reaches them only via BeatX.Modules.
	BeatX.Modules = BeatX.Modules or {}
	BeatX.Modules.RowFactory = tryLoad("ui/rowfactory.lua")
	BeatX.Modules.Category = tryLoad("ui/category.lua")
	BeatX.Modules.Window = tryLoad("ui/window.lua")
	BeatX.Modules.SearchIndex = tryLoad("core/searchindex.lua")
	local Components = {}
	Components.Button = tryLoad("ui/components/button.lua")
	Components.Input = tryLoad("ui/components/input.lua")
	Components.Dropdown = tryLoad("ui/components/dropdown.lua")
	BeatX.Modules.Components = Components

	updateLoading("Loading WindUI...", 66)
	BeatX.WindUI = loadstring(game:HttpGet(WINDUI_URL, true))()
	updateLoading("Preparing feature manager...", 72)
	local FeatureManager = loadModule("core/featuremanager.lua")
	BeatX.FeatureManager = FeatureManager.new(BeatX)

	-- UI adapter keeps WindUI replaceable. Features should use this adapter, not WindUI directly.
	-- The menu itself is built from raw Roblox GUI primitives so it renders
	-- identically on every executor and never touches WindUI internals.
	BeatX.UI = {
		Library = BeatX.WindUI,
		Theme = BeatX.Config.UI.Theme,
		Initialize = function(self)
			self.Initialized = true
		end,
		CreateMenu = function(self)
			if self.Menu then
				return self.Menu
			end
			local MenuModule = loadModule("ui/menu.lua")
			local menu = MenuModule.new(BeatX)
			BeatXMenu = menu
			self.Menu = menu
			BeatX.Menu = menu
			return menu
		end,
	}
	BeatX.UI:Initialize()
	local featureFiles = {
		"features/beatx.lua",
		"features/creator.lua",
		"features/cosmetic.lua",
		"features/level.lua",
		"features/status.lua",
		"features/display.lua",
		"features/utility.lua",
		"features/speedhack.lua",
	}
	-- Register first so the menu can read the BeatX CategoryDef.
	-- Register only invokes Init, so it has no menu dependency.
	for _, path in ipairs(featureFiles) do
		BeatX.FeatureManager:Register(loadModule(path))
	end
	BeatX.UI:CreateMenu()
	updateLoading("Initializing user interface...", 78)

	updateLoading("Registering features...", 86)

	BeatX.FeatureManager:EnableAll(BeatX.Config.Features)
	-- SearchIndex needs completed registration.
	if BeatX.Modules.SearchIndex then
		local ok, idx = pcall(function()
			return BeatX.Modules.SearchIndex.new(BeatX.FeatureManager)
		end)
		if ok then
			BeatX.SearchIndex = idx
		end
	end
	-- Attach the Window wrapper. Legacy Menu toggle survives failure.
	if BeatX.Modules.Window then
		pcall(function()
			BeatX.Window = BeatX.Modules.Window.Attach(BeatX.Menu, {
				Animation = BeatX.Animation,
				Theme = BeatX.Theme,
				Localization = BeatX.Localization,
			})
		end)
	end
	-- Keep the Config.BeatX view in sync with Settings changes.
	if BeatX.Settings and type(BeatX.Settings.Subscribe) == "function" then
		for _, key in ipairs({ "Language", "Theme", "AnimationDuration" }) do
			BeatX.Settings:Subscribe(key, function(value)
				if BeatX.Config.BeatX then
					BeatX.Config.BeatX[key] = value
				end
				if key == "Theme" then
					BeatX.Config.UI.Theme = value
				end
			end)
		end
	end
	installMenuToggle()
	updateLoading("Enabling features...", 94)
	BeatX.Started = true
	shared.BeatX = BeatX
	return BeatX
end

function BeatX:Destroy()
	if self.MenuToggleInputConnection then
		self.MenuToggleInputConnection:Disconnect()
		self.MenuToggleInputConnection = nil
	end
	if self.MenuToggleInputEndedConnection then
		self.MenuToggleInputEndedConnection:Disconnect()
		self.MenuToggleInputEndedConnection = nil
	end
	if self.Menu and type(self.Menu.Destroy) == "function" then
		pcall(function()
			self.Menu:Destroy()
		end)
	end
	if self.Window and type(self.Window.Destroy) == "function" then
		pcall(function()
			self.Window:Destroy()
		end)
	end
	self.Window = nil
	self.SearchIndex = nil
	self.Theme = nil
	self.Localization = nil
	self.Animation = nil
	self.Settings = nil
	self.Modules = nil
	self.Menu = nil
	if self.UI then
		self.UI.Menu = nil
	end
	BeatXMenu = nil
	if self.FeatureManager then
		self.FeatureManager:Destroy()
	end
	self.Started = false
end

shared.BeatX = BeatX
return Main
