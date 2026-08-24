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
local COMMIT_API_URL = "https://api.github.com/repos/moonl1ghtstar/beatx/commits/main"
local BEATX_GAME_ID = 5385674359

if shared.BeatX and type(shared.BeatX.Destroy) == "function" then
	pcall(function()
		shared.BeatX:Destroy()
	end)
end

-- Game restriction: BeatX runs only in Beat Bounce (GameId 5385674359).
-- This check is the earliest startup gate: before any GUI, WindUI fetch,
-- feature load or input connection can happen. Unsupported games get nothing.
if not game:IsLoaded() then
	game.Loaded:Wait()
end

if game.GameId ~= BEATX_GAME_ID then
	warn("[BeatX] Restricted to game " .. tostring(BEATX_GAME_ID) .. ". Current game: " .. tostring(game.GameId) .. ". Aborting.")
	return
end

local LoaderController = {}
LoaderController.__index = LoaderController
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local function getLatestCommitInfo()
	local ok, body = pcall(function()
		return game:HttpGet(COMMIT_API_URL, true)
	end)

	if not ok or type(body) ~= "string" then
		return nil, "unavailable"
	end

	local decodedOk, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)

	if not decodedOk or type(data) ~= "table" or type(data.sha) ~= "string" then
		return nil, "invalid response"
	end

	local message = "No commit message"
	if type(data.commit) == "table" and type(data.commit.message) == "string" then
		message = data.commit.message:gsub("%s+", " ")
		if #message > 42 then
			message = message:sub(1, 39) .. "..."
		end
	end

	return {
		Sha = data.sha,
		ShortSha = data.sha:sub(1, 7),
		Message = message,
	}
end

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

	-- WindUI is loaded by Main later, so the boot screen stays independent and immediate.
	-- It uses the same Roblox GUI primitives WindUI can coexist with without theme coupling.
	local gui = Instance.new("ScreenGui")
	gui.Name = "BeatXLoader"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
	background.BackgroundTransparency = 1
	background.BorderSizePixel = 0
	background.ZIndex = 1
	background.Parent = gui

	local function createGlow(name, position, size, rotation)
		local glow = Instance.new("Frame")
		glow.Name = name
		glow.Position = position
		glow.Size = size
		glow.BackgroundColor3 = Color3.fromRGB(125, 65, 255)
		glow.BackgroundTransparency = 1
		glow.BorderSizePixel = 0
		glow.ZIndex = 2
		glow.Parent = gui

		local gradient = Instance.new("UIGradient")
		gradient.Rotation = rotation
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.72, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		})
		gradient.Parent = glow
		return glow
	end

	local glows = {
		createGlow("GlowTop", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.22), 90),
		createGlow("GlowBottom", UDim2.fromScale(0, 0.78), UDim2.fromScale(1, 0.22), 270),
		createGlow("GlowLeft", UDim2.fromScale(0, 0), UDim2.fromScale(0.22, 1), 0),
		createGlow("GlowRight", UDim2.fromScale(0.78, 0), UDim2.fromScale(0.22, 1), 180),
	}

	local group = Instance.new("Frame")
	group.Name = "CenterGroup"
	group.AnchorPoint = Vector2.new(0.5, 0.5)
	group.Position = UDim2.fromScale(0.5, 0.5)
	group.Size = UDim2.fromScale(0.46, 0.25)
	group.BackgroundTransparency = 1
	group.ZIndex = 10
	group.Parent = gui

	local scale = Instance.new("UIScale")
	scale.Scale = 0.92
	scale.Parent = group

	local title = Instance.new("TextLabel")
	title.Name = "Logo"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.05)
	title.Size = UDim2.fromScale(1, 0.38)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "BeatX"
	title.TextColor3 = Color3.fromRGB(246, 242, 255)
	title.TextScaled = true
	title.TextTransparency = 1
	title.ZIndex = 11
	title.Parent = group

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MinTextSize = 32
	titleConstraint.MaxTextSize = 72
	titleConstraint.Parent = title

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.AnchorPoint = Vector2.new(0.5, 0)
	subtitle.Position = UDim2.fromScale(0.5, 0.49)
	subtitle.Size = UDim2.fromScale(1, 0.16)
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.Text = "Loading main.lua...."
	subtitle.TextColor3 = Color3.fromRGB(181, 174, 204)
	subtitle.TextScaled = true
	subtitle.TextTransparency = 1
	subtitle.ZIndex = 11
	subtitle.Parent = group

	local subtitleConstraint = Instance.new("UITextSizeConstraint")
	subtitleConstraint.MinTextSize = 12
	subtitleConstraint.MaxTextSize = 18
	subtitleConstraint.Parent = subtitle

	local detail = Instance.new("TextLabel")
	detail.Name = "Detail"
	detail.AnchorPoint = Vector2.new(0.5, 0)
	detail.Position = UDim2.fromScale(0.5, 0.66)
	detail.Size = UDim2.fromScale(1, 0.1)
	detail.BackgroundTransparency = 1
	detail.Font = Enum.Font.Code
	detail.Text = "Preparing..."
	detail.TextColor3 = Color3.fromRGB(128, 119, 153)
	detail.TextScaled = true
	detail.TextTransparency = 1
	detail.ZIndex = 11
	detail.Parent = group

	local detailConstraint = Instance.new("UITextSizeConstraint")
	detailConstraint.MinTextSize = 10
	detailConstraint.MaxTextSize = 14
	detailConstraint.Parent = detail

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.AnchorPoint = Vector2.new(0.5, 0)
	progressTrack.Position = UDim2.fromScale(0.5, 0.82)
	progressTrack.Size = UDim2.fromScale(0.82, 0.055)
	progressTrack.BackgroundColor3 = Color3.fromRGB(30, 25, 44)
	progressTrack.BackgroundTransparency = 0.15
	progressTrack.BorderSizePixel = 0
	progressTrack.ZIndex = 11
	progressTrack.Parent = group

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.fromScale(0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(150, 78, 255)
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 12
	progressFill.Parent = progressTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = progressFill

	local fillGradient = Instance.new("UIGradient")
	fillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(108, 62, 220)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(188, 105, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(126, 83, 255)),
	})
	fillGradient.Parent = progressFill

	local percent = Instance.new("TextLabel")
	percent.Name = "Percent"
	percent.AnchorPoint = Vector2.new(0.5, 0)
	percent.Position = UDim2.fromScale(0.5, 0.9)
	percent.Size = UDim2.fromScale(0.82, 0.08)
	percent.BackgroundTransparency = 1
	percent.Font = Enum.Font.GothamMedium
	percent.Text = "0%"
	percent.TextColor3 = Color3.fromRGB(143, 132, 176)
	percent.TextScaled = true
	percent.TextTransparency = 1
	percent.ZIndex = 11
	percent.Parent = group

	local percentConstraint = Instance.new("UITextSizeConstraint")
	percentConstraint.MinTextSize = 10
	percentConstraint.MaxTextSize = 13
	percentConstraint.Parent = percent

	local commit = Instance.new("TextLabel")
	commit.Name = "Commit"
	commit.AnchorPoint = Vector2.new(1, 1)
	commit.Position = UDim2.fromScale(0.985, 0.975)
	commit.Size = UDim2.fromOffset(430, 24)
	commit.BackgroundTransparency = 1
	commit.Font = Enum.Font.Code
	commit.Text = "commit: fetching..."
	commit.TextColor3 = Color3.fromRGB(128, 119, 153)
	commit.TextSize = 12
	commit.TextXAlignment = Enum.TextXAlignment.Right
	commit.TextYAlignment = Enum.TextYAlignment.Center
	commit.TextTransparency = 1
	commit.ZIndex = 20
	commit.Parent = gui

	gui.Parent = parent

	return gui, detail, percent, progressFill, subtitle, title, scale, background, glows, progressTrack, commit
end

function LoaderController.new()
	if shared.ACTIVE_LOADER and not shared.ACTIVE_LOADER.Destroyed then
		return shared.ACTIVE_LOADER
	end

	local gui, detail, percent, progressFill, subtitle, title, scale, background, glows, progressTrack, commit = createLoaderGui()
	local self = setmetatable({
		Progress = 0,
		Gui = gui,
		Detail = detail,
		Percent = percent,
		ProgressFill = progressFill,
		Subtitle = subtitle,
		Title = title,
		Scale = scale,
		Background = background,
		Glows = glows,
		ProgressTrack = progressTrack,
		Commit = commit,
	}, LoaderController)
	shared.ACTIVE_LOADER = self

	if gui then
		TweenService:Create(background, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08,
		}):Play()
		for _, glow in ipairs(glows) do
			local glowTween = TweenService:Create(
				glow,
				TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ BackgroundTransparency = 0.62 }
			)
			glowTween:Play()
		end
		TweenService:Create(scale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1,
		}):Play()
		for _, object in ipairs({ title, subtitle, detail, percent, commit }) do
			TweenService:Create(object, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
			}):Play()
		end
	end

	task.spawn(function()
		local info, reason = getLatestCommitInfo()
		if self.Destroyed or not self.Commit then
			return
		end

		if info then
			self.Commit.Text = string.format("commit %s  •  %s", info.ShortSha, info.Message)
		else
			self.Commit.Text = "commit: " .. tostring(reason)
		end
	end)

	return self
end

function LoaderController:Update(message, progress)
	self.Progress = progress or self.Progress
	if self.Detail then
		self.Detail.Text = tostring(message)
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
	if self.Detail then
		self.Detail.Text = tostring(message)
		self.Detail.TextColor3 = Color3.fromRGB(255, 130, 150)
	end
	warn("[BeatX] " .. tostring(message))
	self.Aborted = true
end

function LoaderController:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	if self.Gui then
		local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(self.Background, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(self.Scale, fadeInfo, { Scale = 1.04 }):Play()
		TweenService:Create(self.ProgressTrack, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(self.ProgressFill, fadeInfo, { BackgroundTransparency = 1 }):Play()
		for _, glow in ipairs(self.Glows) do
			TweenService:Create(glow, fadeInfo, { BackgroundTransparency = 1 }):Play()
		end
		for _, object in ipairs({ self.Title, self.Subtitle, self.Detail, self.Percent, self.Commit }) do
			TweenService:Create(object, fadeInfo, { TextTransparency = 1 }):Play()
		end
		task.delay(0.5, function()
			if self.Gui then
				self.Gui:Destroy()
			end
			if shared.ACTIVE_LOADER == self then
				shared.ACTIVE_LOADER = nil
			end
		end)
	end
end

local GAME_ENVIRONMENTS = {
	[BEATX_GAME_ID] = { Title = "Beat Bounce", Supported = true },
}

local function detectEnvironment()
	return GAME_ENVIRONMENTS[game.GameId]
end

local controller = LoaderController.new()

local ok, errorMessage = pcall(function()
	controller:Update("Booting BeatX...", 5)
	controller:Update("Detecting Game...", 20)
	local environment = detectEnvironment()
	if not environment or not environment.Supported then
		error("Unsupported game: " .. tostring(game.GameId))
	end
	shared.BeatXEnvironment = environment
	controller:Update("Preparing BeatX...", 35)

	-- Main owns all remaining remote module loading.
	local mainUrl = MAIN_URL .. "?v=" .. tostring(os.time())
print(string.format('[BeatX][Loader] Loading main.lua from %s', mainUrl))
local Main = loadstring(game:HttpGet(mainUrl, true))()
	assert(Main and type(Main.Start) == "function", "main.lua must expose Main.Start()")

	controller:Update("Loading Main...", 55)
	Main.Start()
	controller:Update("BeatX Loaded", 100)
end)

if not ok then
	controller:Abort("Startup failed: " .. tostring(errorMessage))
else
	task.wait(3)
	controller:Destroy()
end
