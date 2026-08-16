--[[

 /$$$$$$$                        /$$     /$$   /$$
| $$__  $$                      | $$    | $$  / $$
| $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
| $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/ 
| $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$ 
| $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
| $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
|_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - loader

]]--

local MAIN_URL = "https://raw.githubusercontent.com/moonl1ghtstar/beatx/main/main.lua"

if shared.BeatX and type(shared.BeatX.Destroy) == "function" then
	pcall(function()
		shared.BeatX:Destroy()
	end)
end

local LoaderController = {}
LoaderController.__index = LoaderController

local function getGuiParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		return coreGui
	end

	local players = game:GetService("Players")
	local localPlayer = players.LocalPlayer
	if localPlayer then
		return localPlayer:WaitForChild("PlayerGui", 5)
	end

	return nil
end

local function createLoaderGui()
	local parent = getGuiParent()
	if not parent then
		return nil
	end

	pcall(function()
		local oldGui = parent:FindFirstChild("BeatXLoader")
		if oldGui then
			oldGui:Destroy()
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "BeatXLoader"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.AnchorPoint = Vector2.new(0.5, 0.5)
	background.Position = UDim2.fromScale(0.5, 0.5)
	background.Size = UDim2.fromOffset(360, 170)
	background.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	background.BackgroundTransparency = 0.08
	background.BorderSizePixel = 0
	background.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = background

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(0, 32)
	title.Size = UDim2.new(1, 0, 0, 58)
	title.Font = Enum.Font.GothamBlack
	title.Text = "BeatX"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = background

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(20, 104)
	status.Size = UDim2.new(1, -40, 0, 32)
	status.Font = Enum.Font.GothamMedium
	status.Text = "Loading..."
	status.TextColor3 = Color3.fromRGB(190, 190, 205)
	status.TextScaled = true
	status.Parent = background

	gui.Parent = parent
	return gui, status
end

function LoaderController.new()
	local gui, status = createLoaderGui()
	return setmetatable({ Progress = 0, Gui = gui, Status = status }, LoaderController)
end

function LoaderController:Update(message, progress)
	self.Progress = progress or self.Progress
	if self.Status then
		self.Status.Text = string.format("Loading... %s (%d%%)", tostring(message), self.Progress)
	end
	print(string.format("[BeatX] %s (%d%%)", message, self.Progress))
end

function LoaderController:Abort(message)
	if self.Status then
		self.Status.Text = "Loading... " .. tostring(message)
		self.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
	warn("[BeatX] " .. tostring(message))
	self.Aborted = true
end

function LoaderController:Destroy()
	if self.Gui then
		self.Gui:Destroy()
	end
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
	task.wait(3)
	controller:Destroy()
end
