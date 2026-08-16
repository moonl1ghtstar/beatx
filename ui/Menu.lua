-- BeatX in-game utility menu.
-- Layout and visual style modelled on the reference in interface.png:
--   • Multi-column horizontal layout (one column per category + utility column)
--   • Dark background with a bright red/pink header bar per column
--   • Compact toggle rows (~20 px) with a left-side coloured square indicator
--   • Optional right-side arrow (▶) for items that have sub-options
--   • Horizontally scrollable panel so all columns fit on any screen size
--   • No outer window chrome – the overlay is the UI
--   • Single instance / singleton; Right Shift toggles; close hides (never destroys)

local Menu = {}
Menu.__index = Menu

local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

-- ─── Colour palette (matches interface.png) ─────────────────────────────────
local C = {
	Bg          = Color3.fromRGB(18, 17, 22),      -- overall overlay background
	ColBg       = Color3.fromRGB(23, 22, 27),      -- per-column background
	ColBgHov    = Color3.fromRGB(28, 27, 33),      -- row hover
	HeaderA     = Color3.fromRGB(214, 30,  82),    -- header gradient left  (hot-pink/red)
	HeaderB     = Color3.fromRGB(180, 22,  65),    -- header gradient right
	AccentOn    = Color3.fromRGB(214, 30,  82),    -- indicator when ON
	AccentOnTx  = Color3.fromRGB(235, 120, 155),   -- label text when ON (soft pink)
	AccentOff   = Color3.fromRGB(52,  48,  58),    -- indicator when OFF
	Text        = Color3.fromRGB(228, 224, 232),   -- normal label text
	TextMuted   = Color3.fromRGB(148, 142, 162),   -- muted / dim text
	TextHdr     = Color3.fromRGB(255, 255, 255),   -- header text
	SearchBg    = Color3.fromRGB(30,  29,  36),    -- search-box background
	SearchText  = Color3.fromRGB(168, 162, 182),   -- search placeholder
	Arrow       = Color3.fromRGB(110, 105, 125),   -- ▶ sub-option arrow
	Separator   = Color3.fromRGB(38,  36,  45),    -- thin divider under header
	ColBorder   = Color3.fromRGB(35,  33,  42),    -- right border between columns
	ScrollBar   = Color3.fromRGB(214, 30,  82),    -- scrollbar thumb
}

-- ─── Fonts ───────────────────────────────────────────────────────────────────
local FB  = Enum.Font.GothamBold
local FM  = Enum.Font.GothamMedium
local FG  = Enum.Font.Gotham
local FC  = Enum.Font.Code

-- ─── Layout constants (pixels) ───────────────────────────────────────────────
local COL_W         = 142   -- column width
local ROW_H         = 20    -- toggle row height
local HDR_H         = 24    -- column header height
local SEARCH_H      = 28    -- search bar height (first column only)
local COL_PAD_X     = 0     -- horizontal gap between columns
local ROW_INDENT    = 0     -- left indent for rows inside a column
local INDICATOR_SZ  = 9     -- square indicator size
local CORNER_PANEL  = 0     -- column corner radius (flat, like the reference)
local CORNER_ROW    = 0     -- row corner radius  (flat)
local MIN_H         = 340   -- minimum overlay height

-- ─── Category data ───────────────────────────────────────────────────────────
-- Items that have a small "▶" arrow (indicating sub-options) are marked with
-- a trailing boolean true.  This exactly matches the arrows visible in the
-- reference image.
local CATEGORIES = {
	{
		Name = "BeatX",        -- replaces "Mega Hack" title column
		ShowSearch = true,
		Items = {
			{ "Auto-Select",          false, true  },
			{ "Auto-Update",          false, false },
			{ "Language: en-GB",      false, false },
			{ "Contribute Translations", false, false },
			{ "Theme",                false, true  },
			{ "Rulesets",             false, true  },
			{ "Alt Hotkey",           false, false },
			{ "Icon Hotkey",          false, false },
			{ "Interface Scale 1.2x", false, false },
			{ "Animations 250ms",     false, false },
			{ "Sort Interface",       false, true  },
			{ "Miscellaneous",        false, true  },
		},
		-- Extra sub-sections visible beneath toggles
		SubSections = {
			{
				Name  = "Screenshot",
				Items = {
					{ "Screenshot",        false, false },
					{ "Mode: Save & copy", false, true  },
				},
			},
		},
	},
	{
		Name = "Bypass",
		Items = {
			{ "Anti-Kick",         false, false },
			{ "Challenge Level",   false, false },
			{ "Keymaster",         false, false },
			{ "Main Levels",       false, false },
			{ "Music Customiser",  false, false },
			{ "Slider Limit",      false, false },
			{ "Text Length",       false, false },
			{ "Treasure Room",     false, false },
			{ "Unlock Icons",      false, false },
			{ "Unlock Shops",      false, false },
			{ "Unlock Vaults",     false, false },
		},
		SubSections = {
			{
				Name  = "Speedhack",
				Items = {
					{ "Speed 0.5x",     false, false },
					{ "Enabled",        true,  false },  -- "Enabled" active in reference
					{ "Speedhack Audio",true,  false },  -- highlighted red in reference
					{ "Classic Mode",   false, false },
				},
			},
		},
	},
	{
		Name = "Creator",
		Items = {
			{ "Accurate Save",         false, false },
			{ "Copy Hack",             false, false },
			{ "Custom Object Bypass",  false, false },
			{ "Default Song Bypass",   false, false },
			{ "Editor Extension",      false, false },
			{ "Free Scroll",           false, false },
			{ "Hide UI",               false, false },
			{ "Level Edit",            false, false },
			{ "Multiple Editor Trails",false, false },
			{ "No C Mark",             false, false },
			{ "Place Over",            false, false },
			{ "Smooth Editor Trail",   false, false },
			{ "Toolbox Button Bypass", false, false },
			{ "Trigger Value Bypass",  false, false },
			{ "Verify Hack",           false, false },
		},
	},
	{
		Name = "Cosmetic",
		Items = {
			{ "Accurate Percentage",   false, false },
			{ "Ball Rotation Bug",     false, false },
			{ "Classic Particles",     false, false },
			{ "Classic Pulse",         false, false },
			{ "Classic Wave Trail",    false, false },
			{ "Coin Shower",           false, false },
			{ "Frozen Animations",     false, false },
			{ "Hide Pause Button",     false, false },
			{ "Hide Pause Menu",       false, false },
			{ "Hide Player",           false, false },
			{ "Icon Randomiser",       false, false },
			{ "No Camera",             false, false },
			{ "No Camera Zoom",        false, false },
			{ "No Circle Effect",      false, false },
			{ "No Dash Fire",          false, false },
			{ "No Death Effect",       false, false },
			{ "No Do Not Flip",        false, false },
			{ "No End Shake",          false, false },
			{ "No Ghost Trail",        false, false },
			{ "No Glow",               false, false },
			{ "No Mirror",             false, false },
			{ "No New Best Popup",     false, false },
			{ "No Orb Ring",           false, false },
			{ "No Particles",          false, true  },
			{ "No Particles Classic",  false, true  },
			{ "No Portal Circle",      false, false },
			{ "No Portal Lightning",   false, false },
			{ "No Pulse",              false, false },
			{ "No Respawn Flash",      false, false },
			{ "No Robot Fire",         false, false },
			{ "No Shaders",            false, false },
			{ "No Shake",              false, false },
			{ "No Spider Dash",        false, false },
			{ "No Swing Fire",         false, false },
			{ "No Trail",              false, false },
			{ "No Wave Pulse",         false, false },
			{ "No Wave Trail",         false, false },
			{ "No Trail Behind Wave",  false, false },
			{ "Player 1 on Top",       false, false },
			{ "Player on Top",         false, false },
			{ "Show Total Attempts",   false, false },
			{ "Solid Wave Trail",      false, false },
			{ "StartPos Reset Camera", false, false },
			{ "Stop Triggers on Death",false, false },
			{ "Trail Always On",       false, false },
			{ "Trail Cutting",         false, false },
			{ "Wave Pulse Size",       false, false },
			{ "Wave Trail on Death",   false, false },
		},
	},
	{
		Name = "Level",
		Items = {
			{ "0% Practice Complete",      false, false },
			{ "Allow Pause Buffering",     false, false },
			{ "All Modes Platformer",      false, false },
			{ "Auto Clicker",              false, false },
			{ "Auto Deafen",               false, false },
			{ "Auto Kill",                 false, false },
			{ "Auto Music Sync",           false, false },
			{ "Auto Pickup Coins",         false, false },
			{ "Auto Song Download",        false, false },
			{ "Click Between Frames",      false, false },
			{ "Click Between Steps",       false, false },
			{ "Click on Steps",            false, true  },
			{ "Checkpoint Limit Bypass",   false, false },
			{ "Collect Coins In Practice", false, false },
			{ "Confirm Exit",              false, false },
			{ "Confirm Full Reset",        false, false },
			{ "Confirm Normal",            false, false },
			{ "Confirm Practice",          false, false },
			{ "Confirm Reset",             false, false },
			{ "Force Ice",                 false, true  },
			{ "Force Platformer",          false, false },
			{ "Frame Stepper",             false, true  },
			{ "Hitbox Multiplier",         false, false },
			{ "Instant Complete",          false, false },
			{ "Jumpscare",                 false, false },
			{ "Jump Hack",                 false, false },
			{ "Noclip",                    false, false },
			{ "Noclip Limits",             false, true  },
			{ "No Collision",              false, false },
			{ "Pause During Complete",     false, false },
			{ "Practice Bug Fix",          false, false },
			{ "Practice Music",            false, false },
			{ "Random Seed",               false, false },
			{ "Replay Last Checkpoint",    false, false },
			{ "Respawn Time",              false, true  },
			{ "Shipcooter",                false, false },
			{ "Show Hitboxes",             false, false },
			{ "Show Hitboxes on Death",    false, false },
			{ "Show Hitboxes Trail",       false, false },
			{ "Show Layout",               false, false },
			{ "Show Trajectory",           false, false },
			{ "Show Triggers",             false, false },
			{ "Smart StartPos",            false, false },
			{ "StartPos Switcher",         false, false },
		},
	},
	{
		Name = "Status",
		Items = {
			{ "Field Formatting",   false, false },
			{ "Font: Big Font",     false, false },
			{ "Scale 1x",           false, false },
			{ "Opacity 1x",         false, false },
			{ "Hide Status",        false, false },
			{ "Message",            false, false },
			{ "Testmode",           false, false },
			{ "Cheat Indicator",    false, false },
			{ "FPS Counter",        false, false },
			{ "CPS Counter",        false, false },
			{ "Noclip Accuracy",    false, true  },
			{ "Noclip Deaths",      false, true  },
			{ "Best Run",           false, true  },
			{ "Attempts",           false, true  },
			{ "Jumps",              false, true  },
			{ "Percentage",         false, true  },
			{ "Level Time",         false, true  },
			{ "Session Time",       false, true  },
			{ "Clock",              false, true  },
			{ "Frame Counter",      false, true  },
			{ "Position",           false, true  },
			{ "Velocity",           false, true  },
			{ "Dead",               false, true  },
			{ "Replay State",       false, true  },
		},
	},
	{
		Name = "Universal",
		Items = {
			{ "Allow Low Volume",       false, false },
			{ "Compact Lists",          false, false },
			{ "Custom Background",      false, false },
			{ "Fast Chests",            false, false },
			{ "Load Audio to Memory",   false, false },
			{ "Lock Cursor",            false, false },
			{ "Main Menu Play",         false, false },
			{ "No Music Fade Out",      false, false },
			{ "No Transition",          false, false },
			{ "Pitch Shifter",          false, false },
			{ "Thread Priority",        false, false },
			{ "Transition Customiser",  false, false },
			{ "Transparent Lists",      false, false },
		},
		SubSections = {
			{
				Name  = "Interface",
				Items = {
					{ "Hide Endscreen Cheats",   false, false },
					{ "Hide Endscreen Extras",   false, false },
					{ "Hide Menu Snow",          false, false },
					{ "Hide Iconic on Pause",    false, false },
					{ "Hide RobsVault Shortcut", false, false },
				},
			},
		},
	},
	{
		Name = "Cheat Safety",
		Items = {
			{ "Ruleset: Mega Hack",  false, false },
			{ "Disable Cheats",      false, false },
			{ "Auto Safe Mode",      false, false },
			{ "Safe Mode",           false, false },
			{ "Safe Mode Popup",     false, false },
		},
	},
	{
		Name = "Display",
		Items = {
			{ "240 FPS",            false, false },
			{ "Unlock FPS",         false, false },
			{ "360 Hz",             false, false },
			{ "Physics TPS",        false, false },
			{ "Frame Extrapolation",false, false },
			{ "Vertical Sync",      false, false },
			{ "Lock Delta",         false, false },
			{ "Real Time",          false, false },
			{ "Borderless Classic", false, false },
			{ "Fullscreen",         true,  false },
		},
		SubSections = {
			{
				Name  = "Keybinds",
				Items = {
					{ "Choose Keybind",    false, false },
					{ "Choose Hack to Set",false, false },
					{ "View Keybinds",     false, false },
					{ "Remove Keybinds",   false, false },
					{ "Disable in Editor", true,  false },
				},
			},
		},
	},
	{
		Name = "Utility",
		Items = {
			{ "P1 Click",          false, false },
			{ "P2 Click",          false, false },
			{ "Left",              false, false },
			{ "Right",             false, false },
			{ "Left",              false, false },
			{ "Right",             false, false },
			{ "Uncomplete Level",  false, false },
			{ "Restart Level",     false, false },
			{ "Practice Mode",     false, false },
			{ "Settings",          false, false },
			{ "Resources",         false, false },
			{ "AppData",           false, false },
			{ "Toggle DevTools",   false, false },
			{ "Crash Game",        false, false },
		},
		SubSections = {
			{
				Name  = "Replay",
				Items = {
					{ "Record",           false, false },
					{ "Play",             false, false },
					{ "Filename",         false, false },
					{ "Auto-save",        false, false },
					{ "Save",             false, false },
					{ "Clear & New",      false, false },
					{ "Delete",           false, false },
					{ "Gameplay Options", false, false },
					{ "Convert (.json, .gdr)", false, false },
					{ "Open Folder",      false, false },
				},
			},
		},
	},
}

-- ─── Singleton ────────────────────────────────────────────────────────────────
local instance = nil

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getGuiParent()
	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and coreGui then return coreGui end
	local localPlayer = game:GetService("Players").LocalPlayer
	if localPlayer then
		return localPlayer:WaitForChild("PlayerGui", 5)
	end
	return nil
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 0)
	c.Parent = parent
	return c
end

local function addGradient(parent, colorA, colorB)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	g.Rotation = 90
	g.Parent = parent
	return g
end

-- ─── Row builder ──────────────────────────────────────────────────────────────
-- Creates a single toggle row inside a column's item list.
-- Returns the row Frame so the caller can adjust LayoutOrder.
local function buildRow(parent, label, defaultOn, hasArrow)
	local on = defaultOn == true

	local row = Instance.new("TextButton")
	row.AutoButtonColor = false
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.Text = ""
	row.Parent = parent

	-- left colour indicator square
	local ind = Instance.new("Frame")
	ind.Name = "Indicator"
	ind.BackgroundColor3 = on and C.AccentOn or C.AccentOff
	ind.BorderSizePixel = 0
	ind.AnchorPoint = Vector2.new(0, 0.5)
	ind.Position = UDim2.new(0, 8, 0.5, 0)
	ind.Size = UDim2.fromOffset(INDICATOR_SZ, INDICATOR_SZ)
	ind.Parent = row
	addCorner(ind, 1)

	-- label
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Label"
	lbl.BackgroundTransparency = 1
	lbl.Font = FG
	lbl.Text = label
	lbl.TextColor3 = on and C.AccentOnTx or C.Text
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Position = UDim2.fromOffset(22, 0)
	lbl.Size = UDim2.new(1, hasArrow and -34 or -26, 1, 0)
	lbl.Parent = row

	-- optional right-hand sub-option arrow
	if hasArrow then
		local arrow = Instance.new("TextLabel")
		arrow.BackgroundTransparency = 1
		arrow.Font = FG
		arrow.Text = "▶"
		arrow.TextColor3 = C.Arrow
		arrow.TextSize = 8
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -6, 0.5, 0)
		arrow.Size = UDim2.fromOffset(12, ROW_H)
		arrow.TextXAlignment = Enum.TextXAlignment.Right
		arrow.TextYAlignment = Enum.TextYAlignment.Center
		arrow.Parent = row
	end

	-- interaction
	local function refresh()
		ind.BackgroundColor3 = on and C.AccentOn or C.AccentOff
		lbl.TextColor3 = on and C.AccentOnTx or C.Text
	end

	row.MouseButton1Click:Connect(function()
		on = not on
		refresh()
	end)
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.ColBgHov
		row.BackgroundTransparency = 0
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundTransparency = 1
	end)

	return row
end

-- ─── Sub-section builder ──────────────────────────────────────────────────────
-- Builds the coloured sub-section header + its rows inside a column list.
local function buildSubSection(parent, section)
	-- Sub-header: same style as a main column header but smaller
	local hdr = Instance.new("Frame")
	hdr.Name = "SubHdr_" .. section.Name
	hdr.BackgroundColor3 = C.HeaderA
	hdr.BorderSizePixel = 0
	hdr.Size = UDim2.new(1, 0, 0, HDR_H)
	hdr.Parent = parent
	addGradient(hdr, C.HeaderA, C.HeaderB)

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.AutoButtonColor = false
	collapseBtn.BackgroundTransparency = 1
	collapseBtn.Font = FM
	collapseBtn.Text = "—"
	collapseBtn.TextColor3 = C.TextHdr
	collapseBtn.TextSize = 13
	collapseBtn.Size = UDim2.fromOffset(20, HDR_H)
	collapseBtn.TextXAlignment = Enum.TextXAlignment.Center
	collapseBtn.Parent = hdr

	local hdrLabel = Instance.new("TextLabel")
	hdrLabel.BackgroundTransparency = 1
	hdrLabel.Font = FB
	hdrLabel.Text = section.Name
	hdrLabel.TextColor3 = C.TextHdr
	hdrLabel.TextSize = 12
	hdrLabel.TextXAlignment = Enum.TextXAlignment.Left
	hdrLabel.TextYAlignment = Enum.TextYAlignment.Center
	hdrLabel.Position = UDim2.fromOffset(20, 0)
	hdrLabel.Size = UDim2.new(1, -24, 1, 0)
	hdrLabel.Parent = hdr

	-- Item container
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "SubItems_" .. section.Name
	itemFrame.BackgroundTransparency = 1
	itemFrame.Size = UDim2.new(1, 0, 0, 0)
	itemFrame.AutomaticSize = Enum.AutomaticSize.Y
	itemFrame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 0)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = itemFrame

	for i, item in ipairs(section.Items) do
		local r = buildRow(itemFrame, item[1], item[2], item[3])
		r.LayoutOrder = i
	end

	-- collapse logic
	local collapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		itemFrame.Visible = not collapsed
		collapseBtn.Text = collapsed and "+" or "—"
	end)
end

-- ─── Column builder ───────────────────────────────────────────────────────────
-- Returns the column Frame (fixed width, auto-height) for one category.
local function buildColumn(category)
	local col = Instance.new("Frame")
	col.Name = "Col_" .. category.Name
	col.BackgroundColor3 = C.ColBg
	col.BorderSizePixel = 0
	col.Size = UDim2.new(0, COL_W, 1, 0)  -- height is set by the parent to fill
	col.ClipsDescendants = true

	-- thin right border (separator between columns)
	local border = Instance.new("Frame")
	border.Name = "Border"
	border.BackgroundColor3 = C.ColBorder
	border.BorderSizePixel = 0
	border.AnchorPoint = Vector2.new(1, 0)
	border.Position = UDim2.new(1, 0, 0, 0)
	border.Size = UDim2.new(0, 1, 1, 0)
	border.Parent = col

	-- ── Column header ─────────────────────────────────────────────────────────
	local hdr = Instance.new("Frame")
	hdr.Name = "Header"
	hdr.BackgroundColor3 = C.HeaderA
	hdr.BorderSizePixel = 0
	hdr.Size = UDim2.new(1, 0, 0, HDR_H)
	hdr.Parent = col
	addGradient(hdr, C.HeaderA, C.HeaderB)

	-- "—" collapse button on far left of header
	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Name = "CollapseBtn"
	collapseBtn.AutoButtonColor = false
	collapseBtn.BackgroundTransparency = 1
	collapseBtn.Font = FM
	collapseBtn.Text = "—"
	collapseBtn.TextColor3 = C.TextHdr
	collapseBtn.TextSize = 14
	collapseBtn.Size = UDim2.fromOffset(20, HDR_H)
	collapseBtn.Position = UDim2.fromOffset(0, 0)
	collapseBtn.TextXAlignment = Enum.TextXAlignment.Center
	collapseBtn.Parent = hdr

	local hdrLabel = Instance.new("TextLabel")
	hdrLabel.Name = "Title"
	hdrLabel.BackgroundTransparency = 1
	hdrLabel.Font = FB
	hdrLabel.Text = category.Name
	hdrLabel.TextColor3 = C.TextHdr
	hdrLabel.TextSize = 12
	hdrLabel.TextXAlignment = Enum.TextXAlignment.Left
	hdrLabel.TextYAlignment = Enum.TextYAlignment.Center
	hdrLabel.Position = UDim2.fromOffset(20, 0)
	hdrLabel.Size = UDim2.new(1, -24, 1, 0)
	hdrLabel.Parent = hdr

	-- thin separator line below header
	local sep = Instance.new("Frame")
	sep.Name = "Separator"
	sep.BackgroundColor3 = C.Separator
	sep.BorderSizePixel = 0
	sep.Position = UDim2.fromOffset(0, HDR_H)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = col

	-- ── Scrollable item area ──────────────────────────────────────────────────
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, HDR_H + 1)
	scroll.Size = UDim2.new(1, 0, 1, -(HDR_H + 1))
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = C.ScrollBar
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior = Enum.ElasticBehavior.Never
	scroll.Parent = col

	local itemList = Instance.new("UIListLayout")
	itemList.Padding = UDim.new(0, 0)
	itemList.SortOrder = Enum.SortOrder.LayoutOrder
	itemList.Parent = scroll

	local layoutOrder = 1

	-- optional search box (first column / BeatX column)
	if category.ShowSearch then
		local searchFrame = Instance.new("Frame")
		searchFrame.BackgroundColor3 = C.SearchBg
		searchFrame.BorderSizePixel = 0
		searchFrame.Size = UDim2.new(1, 0, 0, SEARCH_H)
		searchFrame.LayoutOrder = layoutOrder
		searchFrame.Parent = scroll
		layoutOrder += 1
		addCorner(searchFrame, 0)

		local searchBox = Instance.new("TextBox")
		searchBox.BackgroundTransparency = 1
		searchBox.Font = FG
		searchBox.PlaceholderText = "Search"
		searchBox.Text = ""
		searchBox.PlaceholderColor3 = C.SearchText
		searchBox.TextColor3 = C.Text
		searchBox.TextSize = 12
		searchBox.TextXAlignment = Enum.TextXAlignment.Left
		searchBox.ClearTextOnFocus = false
		searchBox.Position = UDim2.fromOffset(8, 0)
		searchBox.Size = UDim2.new(1, -16, 1, 0)
		searchBox.Parent = searchFrame
	end

	-- main toggle items
	if category.Items then
		for _, item in ipairs(category.Items) do
			local r = buildRow(scroll, item[1], item[2], item[3])
			r.LayoutOrder = layoutOrder
			layoutOrder += 1
		end
	end

	-- sub-sections
	if category.SubSections then
		for _, section in ipairs(category.SubSections) do
			-- wrapper frame for the sub-section (header + items together)
			local wrapper = Instance.new("Frame")
			wrapper.Name = "Sub_" .. section.Name
			wrapper.BackgroundTransparency = 1
			wrapper.Size = UDim2.new(1, 0, 0, 0)
			wrapper.AutomaticSize = Enum.AutomaticSize.Y
			wrapper.LayoutOrder = layoutOrder
			wrapper.Parent = scroll
			layoutOrder += 1

			local wLayout = Instance.new("UIListLayout")
			wLayout.Padding = UDim.new(0, 0)
			wLayout.SortOrder = Enum.SortOrder.LayoutOrder
			wLayout.Parent = wrapper

			buildSubSection(wrapper, section)
		end
	end

	-- collapse behaviour for entire column
	local bodyCollapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		bodyCollapsed = not bodyCollapsed
		scroll.Visible = not bodyCollapsed
		sep.Visible  = not bodyCollapsed
		collapseBtn.Text = bodyCollapsed and "+" or "—"
	end)

	return col
end

-- ─── Menu.new ─────────────────────────────────────────────────────────────────
function Menu.new(BeatX)
	if instance then
		return instance
	end

	local parent = getGuiParent()
	assert(parent, "[BeatX] No GUI parent available for the BeatX menu.")

	-- Remove any stale GUI from a previous session
	local oldGui = parent:FindFirstChild("BeatXMenu")
	if oldGui then oldGui:Destroy() end

	-- ── ScreenGui ─────────────────────────────────────────────────────────────
	local gui = Instance.new("ScreenGui")
	gui.Name             = "BeatXMenu"
	gui.ResetOnSpawn     = false
	gui.IgnoreGuiInset   = true
	gui.DisplayOrder     = 950
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	gui.Enabled          = false   -- starts hidden
	gui.Parent           = parent

	-- ── Outer canvas (for fade animation) ────────────────────────────────────
	local canvas = Instance.new("CanvasGroup")
	canvas.Name             = "Canvas"
	canvas.AnchorPoint      = Vector2.new(0.5, 0.5)
	canvas.Position         = UDim2.fromScale(0.5, 0.5)
	-- Width = all columns side by side; height fills most of screen
	canvas.Size             = UDim2.new(0, #CATEGORIES * (COL_W + COL_PAD_X), 0.88, 0)
	canvas.BackgroundColor3 = C.Bg
	canvas.GroupTransparency = 1   -- starts transparent
	canvas.Parent           = gui
	addCorner(canvas, 3)

	local sizeConstraint = Instance.new("UISizeConstraint")
	sizeConstraint.MinSize = Vector2.new(300, MIN_H)
	sizeConstraint.MaxSize = Vector2.new(math.huge, 900)
	sizeConstraint.Parent  = canvas

	-- UIScale for the open/close pop animation
	local uiScale = Instance.new("UIScale")
	uiScale.Scale  = 0.97
	uiScale.Parent = canvas

	-- ── Horizontal scroll that holds all columns ───────────────────────────────
	-- Using a ScrollingFrame so on smaller screens the user can pan left/right.
	local hScroll = Instance.new("ScrollingFrame")
	hScroll.Name                  = "HScroll"
	hScroll.BackgroundTransparency = 1
	hScroll.BorderSizePixel        = 0
	hScroll.Size                   = UDim2.fromScale(1, 1)
	hScroll.CanvasSize             = UDim2.fromOffset(0, 0)
	hScroll.AutomaticCanvasSize   = Enum.AutomaticSize.X
	hScroll.ScrollingDirection     = Enum.ScrollingDirection.X
	hScroll.ScrollBarThickness     = 4
	hScroll.ScrollBarImageColor3   = C.ScrollBar
	hScroll.ElasticBehavior        = Enum.ElasticBehavior.Never
	hScroll.Parent                 = canvas

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection = Enum.FillDirection.Horizontal
	hLayout.Padding       = UDim.new(0, COL_PAD_X)
	hLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	hLayout.Parent        = hScroll

	-- Build one column per category
	local columns = {}
	for i, category in ipairs(CATEGORIES) do
		local col = buildColumn(category)
		col.LayoutOrder = i
		col.Parent = hScroll
		columns[i] = col
	end

	-- ── Drag support (drag the whole overlay by clicking anywhere on header) ──
	-- We repurpose the top of the first column header as the drag handle.
	local dragging   = false
	local dragOffset = Vector2.zero

	local firstHeader = columns[1]:FindFirstChild("Header")
	if firstHeader then
		firstHeader.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging   = true
				local m    = UserInputService:GetMouseLocation()
				dragOffset = canvas.AbsolutePosition - Vector2.new(m.X, m.Y)
			end
		end)
	end

	local dragEndConn  = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local dragMoveConn = UserInputService.InputChanged:Connect(function(input)
		if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local m = UserInputService:GetMouseLocation()
		local cs = canvas.AbsoluteSize
		local ss = gui.AbsoluteSize
		local x  = math.clamp(m.X + dragOffset.X, 0, ss.X - cs.X)
		local y  = math.clamp(m.Y + dragOffset.Y, 0, ss.Y - cs.Y)
		canvas.Position = UDim2.fromOffset(x + cs.X * 0.5, y + cs.Y * 0.5)
	end)

	-- ── Build the menu table ──────────────────────────────────────────────────
	local menu = setmetatable({}, Menu)
	menu.Gui             = gui
	menu.Canvas          = canvas
	menu.Scale           = uiScale
	menu.Columns         = columns
	menu.DragConnections = { dragEndConn, dragMoveConn }
	menu.Visible         = false
	menu.Destroyed       = false
	menu.OnUtility       = {}

	instance = menu
	return menu
end

-- ─── Singleton accessor ───────────────────────────────────────────────────────
function Menu.Get()
	return instance
end

-- ─── Open / Close / Toggle ────────────────────────────────────────────────────
function Menu:Open()
	if self.Visible then return end
	self:_stopAnims()
	self.Visible        = true
	self.Gui.Enabled    = true
	self.Canvas.GroupTransparency = 1
	self.Scale.Scale    = 0.97

	self._fadeTween = TweenService:Create(
		self.Canvas,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	self._scaleTween = TweenService:Create(
		self.Scale,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	self._fadeTween:Play()
	self._scaleTween:Play()
end

function Menu:Close()
	if not self.Visible then return end
	self:_stopAnims()
	self.Visible = false

	self._fadeTween = TweenService:Create(
		self.Canvas,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ GroupTransparency = 1 }
	)
	self._scaleTween = TweenService:Create(
		self.Scale,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0.97 }
	)
	self._fadeTween:Play()
	self._scaleTween:Play()

	task.delay(0.18, function()
		if self.Destroyed then return end
		if not self.Visible then
			self.Gui.Enabled = false
		end
	end)
end

function Menu:Toggle()
	if self.Visible then self:Close() else self:Open() end
end

function Menu:_stopAnims()
	if self._fadeTween  then self._fadeTween:Cancel()  end
	if self._scaleTween then self._scaleTween:Cancel() end
end

-- Keep legacy name in case anything calls it
Menu.StopAnims = Menu._stopAnims

function Menu:Center()
	self.Canvas.Position = UDim2.fromScale(0.5, 0.5)
end

-- ─── Destroy ─────────────────────────────────────────────────────────────────
function Menu:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	self:_stopAnims()
	for _, conn in ipairs(self.DragConnections) do
		conn:Disconnect()
	end
	if self.Gui then
		self.Gui:Destroy()
	end
	if instance == self then
		instance = nil
	end
end

return Menu