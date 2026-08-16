-- Main loads WindUI, core modules, then feature modules from one base URL.

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
	local source = fetch(path, url)
	assert(source, "BeatX module unavailable: " .. path)
	local chunk, compileError = loadstring(source, "@" .. path)
	assert(chunk, compileError)
	return chunk()
end

local function loadModule(path)
	return loadSource(path, MODULE_BASE_URL .. path)
end

local Main = {}
local UserInputService = game:GetService("UserInputService")

local function updateLoading(message, progress)
	local loader = shared.ACTIVE_LOADER
	if loader and type(loader.Update) == "function" then
		loader:Update(message, progress)
	end
end

local function getMenuWindow()
	local ui = BeatX.UI
	return (ui and (ui.Window or ui.Menu or ui.WindowInstance)) or BeatX.Window or BeatX.Menu
end

local function toggleMenuWindow()
	local window = getMenuWindow()
	if not window then
		return
	end

	if type(window.Toggle) == "function" then
		window:Toggle()
	elseif window.Closed == true and type(window.Open) == "function" then
		window:Open()
	elseif window.Closed == false and type(window.Close) == "function" then
		window:Close()
	elseif window.UIElements and window.UIElements.Main then
		window.UIElements.Main.Visible = not window.UIElements.Main.Visible
	end
end

local function installMenuToggle()
	if BeatX.MenuToggleInputConnection then
		BeatX.MenuToggleInputConnection:Disconnect()
	end
	if BeatX.MenuToggleInputEndedConnection then
		BeatX.MenuToggleInputEndedConnection:Disconnect()
	end

	local rightShiftDown = false
	BeatX.MenuToggleInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or input.KeyCode ~= Enum.KeyCode.RightShift or rightShiftDown then
			return
		end

		rightShiftDown = true
		toggleMenuWindow()
	end)

	BeatX.MenuToggleInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.RightShift then
			rightShiftDown = false
		end
	end)
end

function Main.Start()
	if BeatX.Started then
		return BeatX
	end

	updateLoading("Loading configuration...", 60)
	BeatX.Config = loadModule("core/Config.lua")
	updateLoading("Loading WindUI...", 66)
	BeatX.WindUI = loadstring(game:HttpGet(WINDUI_URL, true))()
	updateLoading("Preparing feature manager...", 72)
	local FeatureManager = loadModule("core/FeatureManager.lua")
	BeatX.FeatureManager = FeatureManager.new(BeatX)

	-- UI adapter keeps WindUI replaceable. Features should use this adapter, not WindUI directly.
	BeatX.UI = {
		Library = BeatX.WindUI,
		Theme = BeatX.Config.UI.Theme,
		Initialize = function(self)
			self.Initialized = true
		end,
	}
	BeatX.UI:Initialize()
	updateLoading("Initializing user interface...", 78)

	local featureFiles = {
		"features/Analysis.lua",
		"features/FrameWindow.lua",
		"features/PerfectCounter.lua",
		"features/Verification.lua",
		"features/Visual.lua",
		"features/HUD.lua",
	}
	for _, path in ipairs(featureFiles) do
		BeatX.FeatureManager:Register(loadModule(path))
	end
	updateLoading("Registering features...", 86)

	BeatX.FeatureManager:EnableAll(BeatX.Config.Features)
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
	if self.FeatureManager then
		self.FeatureManager:Destroy()
	end
	self.Started = false
end

shared.BeatX = BeatX
return Main
