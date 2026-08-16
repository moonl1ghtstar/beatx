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
local TweenService = game:GetService("TweenService")

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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.35
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(430, 215)
	card.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
	card.BorderSizePixel = 0
	card.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 120, 185)
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Parent = card

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 26, 36)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(14, 15, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 18, 35)),
	})
	gradient.Rotation = 25
	gradient.Parent = card

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Position = UDim2.fromOffset(0, 0)
	accent.Size = UDim2.new(1, 0, 0, 3)
	accent.BackgroundColor3 = Color3.fromRGB(255, 96, 170)
	accent.BorderSizePixel = 0
	accent.Parent = card

	local accentGradient = Instance.new("UIGradient")
	accentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 93, 170)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 155, 255)),
	})
	accentGradient.Parent = accent

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(0, 38)
	title.Size = UDim2.new(1, 0, 0, 64)
	title.Font = Enum.Font.GothamBlack
	title.Text = "BeatX"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Parent = card

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 145, 205)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(155, 180, 255)),
	})
	titleGradient.Parent = title

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(34, 104)
	subtitle.Size = UDim2.new(1, -68, 0, 20)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Beat Bounce utility loader"
	subtitle.TextColor3 = Color3.fromRGB(165, 166, 185)
	subtitle.TextSize = 14
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = card

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(34, 137)
	status.Size = UDim2.new(1, -68, 0, 22)
	status.Font = Enum.Font.GothamMedium
	status.Text = "Loading... Waiting"
	status.TextColor3 = Color3.fromRGB(190, 190, 205)
	status.TextSize = 15
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = card

	local percent = Instance.new("TextLabel")
	percent.Name = "Percent"
	percent.BackgroundTransparency = 1
	percent.Position = UDim2.fromOffset(34, 137)
	percent.Size = UDim2.new(1, -68, 0, 22)
	percent.Font = Enum.Font.GothamBold
	percent.Text = "0%"
	percent.TextColor3 = Color3.fromRGB(235, 235, 245)
	percent.TextSize = 15
	percent.TextXAlignment = Enum.TextXAlignment.Right
	percent.Parent = card

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.Position = UDim2.fromOffset(34, 170)
	progressTrack.Size = UDim2.new(1, -68, 0, 8)
	progressTrack.BackgroundColor3 = Color3.fromRGB(35, 36, 48)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = card

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(255, 96, 170)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 93, 170)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(125, 155, 255)),
	})
	fillGradient.Parent = progressFill

	gui.Parent = parent
	return gui, status, percent, progressFill, stroke
end

function LoaderController.new()
	local gui, status, percent, progressFill, stroke = createLoaderGui()
	return setmetatable({
		Progress = 0,
		Gui = gui,
		Status = status,
		Percent = percent,
		ProgressFill = progressFill,
		Stroke = stroke,
	}, LoaderController)
end

function LoaderController:Update(message, progress)
	self.Progress = progress or self.Progress
	if self.Status then
		self.Status.Text = "Loading... " .. tostring(message)
	end
	if self.Percent then
		self.Percent.Text = string.format("%d%%", self.Progress)
	end
	if self.ProgressFill then
		TweenService:Create(
			self.ProgressFill,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = UDim2.fromScale(math.clamp(self.Progress / 100, 0, 1), 1) }
		):Play()
	end
	print(string.format("[BeatX] %s (%d%%)", message, self.Progress))
end

function LoaderController:Abort(message)
	if self.Status then
		self.Status.Text = "Loading... " .. tostring(message)
		self.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
	if self.Stroke then
		self.Stroke.Color = Color3.fromRGB(255, 100, 100)
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
	task.wait(5)
	controller:Destroy()
end
