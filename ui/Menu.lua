-- BeatX in-game utility menu.
-- Rendered with raw Roblox GUI primitives (no WindUI internals), so the overlay
-- looks and behaves identically on every executor. Spacing, tabs and dense
-- toggle grid are modeled on the general MegaHack utility-menu UX; no MegaHack
-- code, assets or branding are used.

local Menu = {}
Menu.__index = Menu

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local COLORS = {
	Accent = Color3.fromRGB(136, 84, 255),
	AccentBright = Color3.fromRGB(190, 118, 255),
	AccentSoft = Color3.fromRGB(58, 46, 88),
	Background = Color3.fromRGB(17, 16, 23),
	Panel = Color3.fromRGB(24, 22, 31),
	Element = Color3.fromRGB(33, 31, 44),
	ElementHover = Color3.fromRGB(43, 40, 57),
	Text = Color3.fromRGB(238, 234, 252),
	Muted = Color3.fromRGB(170, 161, 198),
	Dim = Color3.fromRGB(122, 114, 150),
	Outline = Color3.fromRGB(54, 49, 72),
}

local FONT_BOLD = Enum.Font.GothamBold
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_MONO = Enum.Font.Code

local HEADER_HEIGHT = 36
local TAB_STRIP_HEIGHT = 30
local STATUS_HEIGHT = 26
local UTILITY_WIDTH = 172
local TOGGLE_WIDTH = 216
local TOGGLE_HEIGHT = 26
local WINDOW_MIN = Vector2.new(564, 344)
local WINDOW_MAX = Vector2.new(1280, 840)

local CATEGORIES = {
	{ Name = "Main", Items = {
		"Auto-Update", "Language: en-GB", "Theme", "Alt Hotkey", "Interface Scale 1.2x", "Animations 250ms", "Sort Interface",
	} },
	{ Name = "Bypass", Items = {
		"Anti-Kick", "Challenge Level", "Keymaster", "Main Levels", "Music Customiser", "Slider Limit", "Text Length", "Unlock Icons", "Unlock Shops",
	} },
	{ Name = "Creator", Items = {
		"Accurate Save", "Copy Hack", "Custom Object Bypass", "Default Song Bypass", "Editor Extension", "Free Scroll", "Hide UI", "Level Edit", "Verify Hack",
	} },
	{ Name = "Cosmetic", Items = {
		"Accurate Percentage", "Ball Rotation Bug", "Classic Particles", "Classic Pulse", "Coin Shower", "Hide Pause Button", "Icon Randomiser", "No Camera", "No Glow", "No Trail",
	} },
	{ Name = "Level", Items = {
		"0% Practice Complete", "Allow Pause Buffering", "Auto Clicker", "Auto Deafen", "Auto Kill", "Auto Music Sync", "Click Between Frames", "Confirm Exit", "Frame Stepper", "Noclip", "Show Hitboxes",
	} },
	{ Name = "Status", Items = {
		"Field Formatting", "Font: Big Font", "Hide Status", "Message", "Testmode", "FPS Counter", "CPS Counter", "Best Run", "Attempts", "Level Time", "Position",
	} },
	{ Name = "Universal", Items = {
		"Allow Low Volume", "Compact Lists", "Custom Background", "Fast Chests", "Load Audio to Memory", "Lock Cursor", "Main Menu Play", "No Transition", "Transparent Lists",
	} },
	{ Name = "Display", Items = {
		"240 FPS", "360 Hz", "Frame Extrapolation", "Vertical Sync", "Lock Delta", "Borderless Classic", "Fullscreen",
	} },
}

local UTILITY_ACTIONS = {
	"P1 Click", "P2 Click", "Restart Level", "Practice Mode", "Settings", "Resources", "Toggle DevTools", "Diagnostics",
}

local instance = nil

local function getGuiParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then
		return coreGui
	end
	local localPlayer = game:GetService("Players").LocalPlayer
	if localPlayer then
		return localPlayer:WaitForChild("PlayerGui", 5)
	end
	return nil
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLORS.Outline
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function createToggleRow(parent, title, defaultValue)
	local row = Instance.new("TextButton")
	row.Name = "Toggle"
	row.AutoButtonColor = false
	row.BackgroundColor3 = COLORS.Element
	row.BorderSizePixel = 0
	row.Size = UDim2.new(0, TOGGLE_WIDTH, 0, TOGGLE_HEIGHT)
	row.Text = ""
	row.Parent = parent
	addCorner(row, 6)

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.BackgroundColor3 = defaultValue and COLORS.Accent or COLORS.Dim
	indicator.BorderSizePixel = 0
	indicator.Position = UDim2.fromOffset(7, 8)
	indicator.Size = UDim2.fromOffset(10, 10)
	indicator.Parent = row
	addCorner(indicator, 3)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Font = FONT_MEDIUM
	label.Text = title
	label.TextColor3 = defaultValue and COLORS.Text or COLORS.Muted
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Position = UDim2.fromOffset(24, 0)
	label.Size = UDim2.new(1, -32, 1, 0)
	label.Parent = row

	local value = defaultValue == true
	row.MouseButton1Click:Connect(function()
		value = not value
		indicator.BackgroundColor3 = value and COLORS.Accent or COLORS.Dim
		label.TextColor3 = value and COLORS.Text or COLORS.Muted
	end)
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = COLORS.ElementHover
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = COLORS.Element
	end)

	return row
end

local function createPanel(category, layoutOrder)
	local panel = Instance.new("Frame")
	panel.Name = "Category_" .. category.Name
	panel.BackgroundTransparency = 1
	panel.Size = UDim2.new(1, 0, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.LayoutOrder = layoutOrder

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Font = FONT_BOLD
	header.Text = category.Name
	header.TextColor3 = COLORS.AccentBright
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Size = UDim2.new(1, 0, 0, 20)
	header.Parent = panel

	local grid = Instance.new("Frame")
	grid.BackgroundTransparency = 1
	grid.Size = UDim2.new(1, 0, 0, 0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.LayoutOrder = 2
	grid.Parent = panel

	local gridList = Instance.new("UIListLayout")
	gridList.FillDirection = Enum.FillDirection.Horizontal
	gridList.Wrap = true
	gridList.Padding = UDim.new(0, 6)
	gridList.SortOrder = Enum.SortOrder.LayoutOrder
	gridList.Parent = grid

	for index, item in ipairs(category.Items) do
		createToggleRow(grid, item, index % 5 == 0)
	end

	return panel
end

local function createUtilityButton(parent, menu, title)
	local button = Instance.new("TextButton")
	button.Name = "Action"
	button.AutoButtonColor = false
	button.BackgroundColor3 = COLORS.Element
	button.BorderSizePixel = 0
	button.Size = UDim2.new(1, 0, 0, 26)
	button.Font = FONT_MEDIUM
	button.Text = title
	button.TextColor3 = COLORS.Muted
	button.TextSize = 12.5
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.TextYAlignment = Enum.TextYAlignment.Center
	button.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = button
	addCorner(button, 6)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = COLORS.ElementHover
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = COLORS.Element
	end)
	button.MouseButton1Click:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.AccentSoft,
		}):Play()
		TweenService:Create(button, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = COLORS.Element,
		}):Play()
		local callback = menu.OnUtility and menu.OnUtility[title]
		if type(callback) == "function" then
			pcall(callback)
		end
	end)

	return button
end

function Menu.new(BeatX)
	if instance then
		return instance
	end

	local parent = getGuiParent()
	assert(parent, "No GUI parent available for the BeatX menu.")

	local oldGui = parent:FindFirstChild("BeatXMenu")
	if oldGui then
		oldGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BeatXMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 950
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = parent

	local overlay = Instance.new("CanvasGroup")
	overlay.Name = "Overlay"
	overlay.AnchorPoint = Vector2.new(0.5, 0.5)
	overlay.Position = UDim2.fromScale(0.5, 0.5)
	overlay.Size = UDim2.fromScale(0.92, 0.9)
	overlay.BackgroundTransparency = 1
	overlay.GroupTransparency = 1
	overlay.Parent = gui

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = WINDOW_MIN
	sizeConstraint.MaxSize = WINDOW_MAX
	sizeConstraint.Parent = overlay

	local scale = Instance.new("UIScale")
	scale.Scale = 0.955
	scale.Parent = overlay

	local frame = Instance.new("Frame")
	frame.Name = "Container"
	frame.BackgroundColor3 = COLORS.Background
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Parent = overlay
	addCorner(frame, 12)
	addStroke(frame, 1)

	local accentStrip = Instance.new("Frame")
	accentStrip.BackgroundTransparency = 1
	accentStrip.Size = UDim2.new(1, 0, 0, 3)
	accentStrip.Parent = frame

	local accentGradient = Instance.new("UIGradient")
	accentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.Accent),
		ColorSequenceKeypoint.new(0.5, COLORS.AccentBright),
		ColorSequenceKeypoint.new(1, COLORS.Accent),
	})
	accentGradient.Parent = accentStrip

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
	header.Parent = frame

	local logo = Instance.new("Frame")
	logo.BackgroundColor3 = COLORS.Accent
	logo.BorderSizePixel = 0
	logo.Position = UDim2.fromOffset(10, 6)
	logo.Size = UDim2.fromOffset(24, 24)
	logo.Parent = header
	addCorner(logo, 7)

	local logoText = Instance.new("TextLabel")
	logoText.BackgroundTransparency = 1
	logoText.Font = FONT_BOLD
	logoText.Text = "B"
	logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
	logoText.TextSize = 15
	logoText.Size = UDim2.new(1, 0, 1, 0)
	logoText.Parent = logo

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Font = FONT_BOLD
	title.Text = "BeatX"
	title.TextColor3 = COLORS.Text
	title.TextSize = 17
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Position = UDim2.fromOffset(42, 0)
	title.Size = UDim2.new(0, 220, 1, 0)
	title.Parent = header

	local closeButton = Instance.new("TextButton")
	closeButton.AutoButtonColor = false
	closeButton.BackgroundTransparency = 1
	closeButton.Font = FONT_MEDIUM
	closeButton.Text = "×"
	closeButton.TextColor3 = COLORS.Muted
	closeButton.TextSize = 17
	closeButton.Position = UDim2.new(1, -32, 0, 6)
	closeButton.Size = UDim2.fromOffset(24, 24)
	closeButton.Parent = header
	addCorner(closeButton, 6)

	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = COLORS.ElementHover
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundTransparency = 1
	end)
	closeButton.MouseButton1Click:Connect(function()
		menu:Close()
	end)

	local hint = Instance.new("TextLabel")
	hint.BackgroundColor3 = COLORS.Panel
	hint.Font = FONT_MONO
	hint.Text = "Right Shift"
	hint.TextColor3 = COLORS.Muted
	hint.TextSize = 11
	hint.Position = UDim2.new(1, -108, 0, 8)
	hint.Size = UDim2.fromOffset(70, 20)
	hint.Parent = header
	addCorner(hint, 5)

	local tabStrip = Instance.new("ScrollingFrame")
	tabStrip.BackgroundTransparency = 1
	tabStrip.BorderSizePixel = 0
	tabStrip.Position = UDim2.fromOffset(0, HEADER_HEIGHT)
	tabStrip.Size = UDim2.new(1, 0, 0, TAB_STRIP_HEIGHT)
	tabStrip.CanvasSize = UDim2.fromOffset(0, 0)
	tabStrip.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabStrip.ScrollBarThickness = 0
	tabStrip.ElasticBehavior = Enum.ElasticBehavior.Never
	tabStrip.Parent = frame

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.Padding = UDim.new(0, 8)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabStrip

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingTop = UDim.new(0, 4)
	tabPadding.PaddingLeft = UDim.new(0, 8)
	tabPadding.PaddingRight = UDim.new(0, 8)
	tabPadding.Parent = tabStrip

	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, HEADER_HEIGHT + TAB_STRIP_HEIGHT)
	body.Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + TAB_STRIP_HEIGHT + STATUS_HEIGHT))
	body.Parent = frame

	local utilityColumn = Instance.new("Frame")
	utilityColumn.BackgroundColor3 = COLORS.Panel
	utilityColumn.BorderSizePixel = 0
	utilityColumn.AnchorPoint = Vector2.new(1, 0)
	utilityColumn.Position = UDim2.new(1, -8, 0, 0)
	utilityColumn.Size = UDim2.new(0, UTILITY_WIDTH, 1, 0)
	utilityColumn.Parent = body
	addCorner(utilityColumn, 10)

	local utilityLayout = Instance.new("UIListLayout")
	utilityLayout.Padding = UDim.new(0, 6)
	utilityLayout.SortOrder = Enum.SortOrder.LayoutOrder
	utilityLayout.Parent = utilityColumn
	utilityLayout.PaddingTop = UDim.new(0, 8)

	local utilityHeader = Instance.new("TextLabel")
	utilityHeader.BackgroundTransparency = 1
	utilityHeader.Font = FONT_BOLD
	utilityHeader.Text = "Utility"
	utilityHeader.TextColor3 = COLORS.AccentBright
	utilityHeader.TextSize = 12
	utilityHeader.TextXAlignment = Enum.TextXAlignment.Left
	utilityHeader.Name = "Header"
	utilityHeader.Parent = utilityColumn

	local utilityPadding = Instance.new("UIPadding")
	utilityPadding.PaddingLeft = UDim.new(0, 8)
	utilityPadding.PaddingRight = UDim.new(0, 8)
	utilityPadding.PaddingBottom = UDim.new(0, 8)
	utilityPadding.Parent = utilityColumn

	local menu = setmetatable({}, Menu)

	for _, action in ipairs(UTILITY_ACTIONS) do
		createUtilityButton(utilityColumn, menu, action)
	end

	local scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Content"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.new(1, -(UTILITY_WIDTH + 14), 1, 0)
	scroller.CanvasSize = UDim2.fromOffset(0, 0)
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageColor3 = COLORS.Accent
	scroller.ElasticBehavior = Enum.ElasticBehavior.Never
	scroller.Parent = body

	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingTop = UDim.new(0, 6)
	contentPadding.PaddingLeft = UDim.new(0, 8)
	contentPadding.PaddingRight = UDim.new(0, 8)
	contentPadding.PaddingBottom = UDim.new(0, 8)
	contentPadding.Parent = scroller

	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 12)
	contentList.SortOrder = Enum.SortOrder.LayoutOrder
	contentList.Parent = scroller

	local panels = {}
	for index, category in ipairs(CATEGORIES) do
		panels[index] = createPanel(category, index)
		panels[index].Parent = scroller
	end

	local statusBar = Instance.new("Frame")
	statusBar.BackgroundColor3 = COLORS.Panel
	statusBar.BorderSizePixel = 0
	statusBar.Position = UDim2.new(0, 0, 1, -STATUS_HEIGHT)
	statusBar.Size = UDim2.new(1, 0, 0, STATUS_HEIGHT)
	statusBar.Parent = frame

	local statusDot = Instance.new("Frame")
	statusDot.BackgroundColor3 = COLORS.Accent
	statusDot.BorderSizePixel = 0
	statusDot.Position = UDim2.fromOffset(10, 8)
	statusDot.Size = UDim2.fromOffset(10, 10)
	statusDot.Parent = statusBar
	addCorner(statusDot, 5)

	local statusText = Instance.new("TextLabel")
	statusText.BackgroundTransparency = 1
	statusText.Font = FONT_MONO
	statusText.Text = "BeatX v" .. tostring(BeatX.Version or "0.1.0")
	statusText.TextColor3 = COLORS.Dim
	statusText.TextSize = 11
	statusText.TextXAlignment = Enum.TextXAlignment.Left
	statusText.Position = UDim2.fromOffset(28, 0)
	statusText.Size = UDim2.new(0.6, -28, 1, 0)
	statusText.Parent = statusBar

	local statusHint = Instance.new("TextLabel")
	statusHint.BackgroundTransparency = 1
	statusHint.Font = FONT_MONO
	statusHint.Text = "Right Shift toggles · Close hides the menu"
	statusHint.TextColor3 = COLORS.Dim
	statusHint.TextSize = 11
	statusHint.TextXAlignment = Enum.TextXAlignment.Right
	statusHint.Position = UDim2.new(0.6, 0, 0, 0)
	statusHint.Size = UDim2.new(0.4, -12, 1, 0)
	statusHint.Parent = statusBar

	local tabsData = {}
	for index, category in ipairs(CATEGORIES) do
		local tab = Instance.new("TextButton")
		tab.Name = "Tab_" .. category.Name
		tab.AutoButtonColor = false
		tab.BackgroundTransparency = 1
		tab.BorderSizePixel = 0
		tab.Font = FONT_MEDIUM
		tab.Text = category.Name
		tab.TextColor3 = COLORS.Muted
		tab.TextSize = 13
		tab.Size = UDim2.new(0, 118, 0, 22)
		tab.Parent = tabStrip
		addCorner(tab, 6)

		local underline = Instance.new("Frame")
		underline.BackgroundColor3 = COLORS.Accent
		underline.BorderSizePixel = 0
		underline.AnchorPoint = Vector2.new(0.5, 1)
		underline.Position = UDim2.new(0.5, 0, 1, 0)
		underline.Size = UDim2.new(1, -12, 0, 3)
		underline.BackgroundTransparency = 1
		underline.Parent = tab
		addCorner(underline, 2)

		tabsData[index] = { Button = tab, Underline = underline }
		tab.MouseButton1Click:Connect(function()
			selectCategory(index)
		end)
	end

	local function selectCategory(index)
		menu.ActiveIndex = index
		for tabIndex, tabData in ipairs(tabsData) do
			local active = tabIndex == index
			tabData.Button.BackgroundTransparency = active and 0 or 1
			tabData.Button.BackgroundColor3 = COLORS.Element
			tabData.Button.TextColor3 = active and COLORS.Text or COLORS.Muted
			tabData.Underline.BackgroundTransparency = active and 0 or 1
		end
		for panelIndex, panel in ipairs(panels) do
			panel.Visible = panelIndex == index
		end
		scroller.CanvasPosition = Vector2.zero
	end

	local dragging = false
	local dragOffset = Vector2.zero

	local dragStart = header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			local mouse = UserInputService:GetMouseLocation()
			dragOffset = overlay.AbsolutePosition - Vector2.new(mouse.X, mouse.Y)
		end
	end)

	local dragEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local dragMove = UserInputService.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local mouse = UserInputService:GetMouseLocation()
		local overlaySize = overlay.AbsoluteSize
		local screenSize = gui.AbsoluteSize
		local x = math.clamp(mouse.X + dragOffset.X, 84 - overlaySize.X, screenSize.X - 84)
		local y = math.clamp(mouse.Y + dragOffset.Y, 84 - overlaySize.Y, screenSize.Y - 84)
		overlay.Position = UDim2.fromOffset(x, y)
	end)

	menu.Gui = gui
	menu.Overlay = overlay
	menu.Scale = scale
	menu.Frame = frame
	menu.Scroller = scroller
	menu.Tabs = tabsData
	menu.Panels = panels
	menu.DragConnections = { dragStart, dragEnd, dragMove }
	menu.OnUtility = {}
	menu.Visible = false
	menu.ActiveIndex = 1
	menu.Destroyed = false

	selectCategory(1)

	instance = menu
	return menu
end

function Menu.Get()
	return instance
end

function Menu:Open()
	if self.Visible then
		return
	end
	self:StopAnims()
	self.Visible = true
	self.Gui.Enabled = true
	self.Overlay.GroupTransparency = 1
	self.Scale.Scale = 0.955
	self.OverlayTween = TweenService:Create(self.Overlay, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
	})
	self.ScaleTween = TweenService:Create(self.Scale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	self.OverlayTween:Play()
	self.ScaleTween:Play()
end

function Menu:Close()
	if not self.Visible then
		return
	end
	self:StopAnims()
	self.Visible = false
	self.OverlayTween = TweenService:Create(self.Overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		GroupTransparency = 1,
	})
	self.ScaleTween = TweenService:Create(self.Scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Scale = 0.97,
	})
	self.OverlayTween:Play()
	self.ScaleTween:Play()
	task.delay(0.22, function()
		if self.Destroyed then
			return
		end
		if not self.Visible then
			self.Gui.Enabled = false
		end
	end)
end

function Menu:Toggle()
	if self.Visible then
		self:Close()
	else
		self:Open()
	end
end

function Menu:StopAnims()
	if self.OverlayTween then
		self.OverlayTween:Cancel()
	end
	if self.ScaleTween then
		self.ScaleTween:Cancel()
	end
end

function Menu:Center()
	self.Overlay.Position = UDim2.fromScale(0.5, 0.5)
end

function Menu:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	self:StopAnims()
	for _, connection in ipairs(self.DragConnections) do
		connection:Disconnect()
	end
	if self.Gui then
		self.Gui:Destroy()
	end
	if instance == self then
		instance = nil
	end
end

return Menu