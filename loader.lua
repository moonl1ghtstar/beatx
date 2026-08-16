-- BeatX entry point. Replace URL with your hosted main.lua.

local MAIN_URL = "https://raw.githubusercontent.com/moonl1ghtstar/beatx/main/main.lua"

if shared.BeatX and type(shared.BeatX.Destroy) == "function" then
	pcall(function()
		shared.BeatX:Destroy()
	end)
end

local LoaderController = {}
LoaderController.__index = LoaderController

function LoaderController.new()
	return setmetatable({ Progress = 0 }, LoaderController)
end

function LoaderController:Update(message, progress)
	self.Progress = progress or self.Progress
	print(string.format("[BeatX] %s (%d%%)", message, self.Progress))
end

function LoaderController:Abort(message)
	warn("[BeatX] " .. tostring(message))
	self.Aborted = true
end

function LoaderController:Destroy()
	self.Destroyed = true
end

local function detectEnvironment()
	local meta = {
		[0] = { Title = "Universal", Supported = false },
		[5385674359] = { Title = "Beat Bounce", Supported = true },
	}

	local environment = meta[game.GameId]
	if not environment then
		for _, candidate in pairs(meta) do
			if candidate.Places and candidate.Places[game.PlaceId] then
				environment = candidate
				break
			end
		end
	end
	return environment or meta[0]
end

local controller = LoaderController.new()
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local ok, errorMessage = pcall(function()
	controller:Update("Booting BeatX...", 5)
	controller:Update("Detecting Game...", 20)
	shared.BeatXEnvironment = detectEnvironment()
	controller:Update("Preparing BeatX...", 35)

	-- Main owns all remaining remote module loading.
	local Main = loadstring(game:HttpGet(MAIN_URL, true))()
	assert(Main and type(Main.Start) == "function", "main.lua must expose Main.Start()")

	controller:Update("Loading Main...", 55)
	Main.Start()
	controller:Update("Initializing Features...", 80)
	controller:Update("BeatX Loaded", 100)
end)

if not ok then
	controller:Abort("Startup failed: " .. tostring(errorMessage))
else
	controller:Destroy()
end
