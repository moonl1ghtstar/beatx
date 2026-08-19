-- BeatX in-game utility menu  --  ui/Menu.lua
--
-- Visual style: modelled on interface.png (MegaHack-style multi-column layout).
--   - One column per category, laid out horizontally.
--   - Red/pink gradient column headers with collapse (-/+) button.
--   - Compact 20 px toggle rows.
--   - Full-row highlight when a feature is ON (accent colour).
--   - Subtle separate hover tint distinct from the ON state.
--   - 4 px gap between columns so headers never touch.
--   - Minimise hides the canvas entirely - no dark rectangle remains.
--   - Only the 6 registered BeatX feature modules appear as toggles.
--     (All other menu items are UI controls or informational, not gameplay features.)
--
-- Singleton contract:
--   Menu.new()  returns the existing instance on re-call.
--   Close()     hides; never destroys.
--   Destroy()   is the only way to tear down the GUI.
--   Right Shift in main.lua calls Toggle() on the singleton.
--   GameId == 5385674359 guard lives in loader.lua / main.lua, untouched.

local Menu = {}
Menu.__index = Menu

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Colours (interface.png palette)
local C = {
	OverlayBg   = Color3.fromRGB(16, 15, 20),
	ColBg       = Color3.fromRGB(22, 21, 27),
	ColBorder   = Color3.fromRGB(36, 34, 43),
	HdrA        = Color3.fromRGB(214, 30,  82),
	HdrB        = Color3.fromRGB(168, 20,  62),
	RowOff      = Color3.fromRGB(22, 21, 27),
	RowOn       = Color3.fromRGB(130, 18,  50),
	RowOnEdge   = Color3.fromRGB(214, 30,  82),
	RowHov      = Color3.fromRGB(32,  30,  38),
	RowHovOn    = Color3.fromRGB(145, 22,  56),
	IndOn       = Color3.fromRGB(214, 30,  82),
	IndOff      = Color3.fromRGB(50,  47,  58),
	TxtHdr      = Color3.fromRGB(255, 255, 255),
	TxtOn       = Color3.fromRGB(255, 185, 200),
	TxtOff      = Color3.fromRGB(210, 205, 220),
	TxtMuted    = Color3.fromRGB(140, 133, 158),
	ScrollThumb = Color3.fromRGB(214, 30,  82),
	SepLine     = Color3.fromRGB(34,  32,  41),
	SearchBg    = Color3.fromRGB(28,  27,  34),
	SearchPh    = Color3.fromRGB(110, 104, 128),
}

local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local FG = Enum.Font.Gotham

local COL_W   = 148
local COL_GAP = 4
local ROW_H   = 20
local HDR_H   = 24
local IND_SZ  = 8
local EDGE_W  = 3
local SEP_H   = 1

local _instance = nil

-- Feature catalogue.
-- ONLY the 6 modules actually registered via FeatureManager are listed.
-- All have Enable = TODO stubs but are real FeatureManager entries.
-- No MegaHack categories, no fake toggles.
local FEATURE_COLUMN = {
	Name  = "BeatX",
	ShowSearch = false,
	Items = {
		{ "Analysis",       "Analysis",       false },
		{ "Frame Window",   "FrameWindow",    false },
		{ "HUD",            "HUD",            false },
		{ "Perfect Counter","PerfectCounter", false },
		{ "Verification",   "Verification",   false },
		{ "Visual",         "Visual",         false },
	},
}

local INFO_COLUMN = {
	Name     = "Info",
	ReadOnly = true,
	Items    = {
		{ "Version: 0.1.0",      nil, false },
		{ "Game: Beat Bounce",   nil, false },
		{ "Toggle: Right Shift", nil, false },
	},
}

local COLUMNS_DEF = { FEATURE_COLUMN, INFO_COLUMN }

-- Helpers
local function getGuiParent()
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	local lp = game:GetService("Players").LocalPlayer
	if lp then return lp:WaitForChild("PlayerGui", 5) end
	return nil
end

local function addCorner(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 0)
	c.Parent = inst
	return c
end

local function addGradient(inst, colorA, colorB)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, colorA),
		ColorSequenceKeypoint.new(1, colorB),
	})
	g.Rotation = 90
	g.Parent = inst
end

-- Row builder
local function buildRow(parent, label, defaultOn, readOnly)
	local on = defaultOn == true

	local row = Instance.new("TextButton")
	row.AutoButtonColor       = false
	row.BorderSizePixel       = 0
	row.Size                  = UDim2.new(1, 0, 0, ROW_H)
	row.Text                  = ""
	row.BackgroundColor3      = on and C.RowOn or C.RowOff
	row.BackgroundTransparency = 0
	row.Parent = parent

	local edge = Instance.new("Frame")
	edge.Name                    = "Edge"
	edge.BackgroundColor3        = C.RowOnEdge
	edge.BorderSizePixel         = 0
	edge.Size                    = UDim2.new(0, EDGE_W, 1, 0)
	edge.BackgroundTransparency  = on and 0 or 1
	edge.Parent = row

	local ind = Instance.new("Frame")
	ind.Name             = "Indicator"
	ind.BackgroundColor3 = on and C.IndOn or C.IndOff
	ind.BorderSizePixel  = 0
	ind.AnchorPoint      = Vector2.new(0, 0.5)
	ind.Position         = UDim2.new(0, EDGE_W + 6, 0.5, 0)
	ind.Size             = UDim2.fromOffset(IND_SZ, IND_SZ)
	ind.Parent = row
	addCorner(ind, 1)

	local lbl = Instance.new("TextLabel")
	lbl.Name                  = "Label"
	lbl.BackgroundTransparency = 1
	lbl.Font                  = FG
	lbl.Text                  = label
	lbl.TextColor3            = on and C.TxtOn or C.TxtOff
	lbl.TextSize              = 12
	lbl.TextXAlignment        = Enum.TextXAlignment.Left
	lbl.TextYAlignment        = Enum.TextYAlignment.Center
	lbl.TextTruncate          = Enum.TextTruncate.AtEnd
	lbl.Position              = UDim2.fromOffset(EDGE_W + 18, 0)
	lbl.Size                  = UDim2.new(1, -(EDGE_W + 24), 1, 0)
	lbl.Parent = row

	if readOnly then
		lbl.TextColor3 = C.TxtMuted
		row.Active = false
		return row
	end

	local hovering = false

	local function applyState()
		if on then
			row.BackgroundColor3       = hovering and C.RowHovOn or C.RowOn
			edge.BackgroundTransparency = 0
			ind.BackgroundColor3       = C.IndOn
			lbl.TextColor3             = C.TxtOn
		else
			row.BackgroundColor3       = hovering and C.RowHov or C.RowOff
			edge.BackgroundTransparency = 1
			ind.BackgroundColor3       = C.IndOff
			lbl.TextColor3             = C.TxtOff
		end
	end

	row.MouseButton1Click:Connect(function()
		on = not on
		applyState()
	end)
	row.MouseEnter:Connect(function()
		hovering = true
		applyState()
	end)
	row.MouseLeave:Connect(function()
		hovering = false
		applyState()
	end)

	return row
end

-- Column builder
local function buildColumn(def)
	local col = Instance.new("Frame")
	col.Name             = "Col_" .. def.Name
	col.BackgroundColor3 = C.ColBg
	col.BorderSizePixel  = 0
	col.Size             = UDim2.new(0, COL_W, 1, 0)
	col.ClipsDescendants = true

	local bord = Instance.new("Frame")
	bord.Name             = "ColBorder"
	bord.BackgroundColor3 = C.ColBorder
	bord.BorderSizePixel  = 0
	bord.AnchorPoint      = Vector2.new(1, 0)
	bord.Position         = UDim2.new(1, 0, 0, 0)
	bord.Size             = UDim2.new(0, 1, 1, 0)
	bord.Parent = col

	local hdr = Instance.new("Frame")
	hdr.Name             = "Header"
	hdr.BackgroundColor3 = C.HdrA
	hdr.BorderSizePixel  = 0
	hdr.Size             = UDim2.new(1, 0, 0, HDR_H)
	hdr.Parent = col
	addGradient(hdr, C.HdrA, C.HdrB)

	local colBtn = Instance.new("TextButton")
	colBtn.Name                    = "CollapseBtn"
	colBtn.AutoButtonColor         = false
	colBtn.BackgroundTransparency  = 1
	colBtn.Font                    = FM
	colBtn.Text                    = "-"
	colBtn.TextColor3              = C.TxtHdr
	colBtn.TextSize                = 13
	colBtn.Size                    = UDim2.fromOffset(22, HDR_H)
	colBtn.TextXAlignment          = Enum.TextXAlignment.Center
	colBtn.TextYAlignment          = Enum.TextYAlignment.Center
	colBtn.Parent = hdr

	local hdrLbl = Instance.new("TextLabel")
	hdrLbl.Name                  = "Title"
	hdrLbl.BackgroundTransparency = 1
	hdrLbl.Font                  = FB
	hdrLbl.Text                  = def.Name
	hdrLbl.TextColor3            = C.TxtHdr
	hdrLbl.TextSize              = 12
	hdrLbl.TextXAlignment        = Enum.TextXAlignment.Left
	hdrLbl.TextYAlignment        = Enum.TextYAlignment.Center
	hdrLbl.Position              = UDim2.fromOffset(22, 0)
	hdrLbl.Size                  = UDim2.new(1, -26, 1, 0)
	hdrLbl.Parent = hdr

	local sep = Instance.new("Frame")
	sep.Name             = "Sep"
	sep.BackgroundColor3 = C.SepLine
	sep.BorderSizePixel  = 0
	sep.Position         = UDim2.fromOffset(0, HDR_H)
	sep.Size             = UDim2.new(1, 0, 0, SEP_H)
	sep.Parent = col

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                  = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel       = 0
	scroll.Position              = UDim2.fromOffset(0, HDR_H + SEP_H)
	scroll.Size                  = UDim2.new(1, 0, 1, -(HDR_H + SEP_H))
	scroll.CanvasSize            = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness    = 3
	scroll.ScrollBarImageColor3  = C.ScrollThumb
	scroll.ScrollingDirection    = Enum.ScrollingDirection.Y
	scroll.ElasticBehavior       = Enum.ElasticBehavior.Never
	scroll.Parent = col

	local itemList = Instance.new("UIListLayout")
	itemList.Padding   = UDim.new(0, 0)
	itemList.SortOrder = Enum.SortOrder.LayoutOrder
	itemList.Parent    = scroll

	if def.ShowSearch then
		local sf = Instance.new("Frame")
		sf.BackgroundColor3 = C.SearchBg
		sf.BorderSizePixel  = 0
		sf.Size             = UDim2.new(1, 0, 0, 28)
		sf.LayoutOrder      = 0
		sf.Parent = scroll

		local sb = Instance.new("TextBox")
		sb.BackgroundTransparency = 1
		sb.Font                   = FG
		sb.PlaceholderText        = "Search"
		sb.Text                   = ""
		sb.PlaceholderColor3      = C.SearchPh
		sb.TextColor3             = C.TxtOff
		sb.TextSize               = 12
		sb.TextXAlignment         = Enum.TextXAlignment.Left
		sb.ClearTextOnFocus       = false
		sb.Position               = UDim2.fromOffset(8, 0)
		sb.Size                   = UDim2.new(1, -16, 1, 0)
		sb.Parent = sf
	end

	for i, item in ipairs(def.Items) do
		local r = buildRow(scroll, item[1], item[3], def.ReadOnly)
		r.LayoutOrder = i
	end

	-- Collapse: hide scroll + sep and shrink the column Frame height
	-- so no dark background remains.
	local collapsed = false
	colBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		scroll.Visible = not collapsed
		sep.Visible    = not collapsed
		colBtn.Text    = collapsed and "+" or "-"
		col.Size = UDim2.new(
			0, COL_W,
			collapsed and 0 or 1,
			collapsed and HDR_H or 0
		)
	end)

	return col
end

-- Menu.new
function Menu.new(BeatX)
	if _instance then return _instance end

	local parent = getGuiParent()
	assert(parent, "[BeatX] No GUI parent found for BeatX menu.")

	do
		local old = parent:FindFirstChild("BeatXMenu")
		if old then old:Destroy() end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name           = "BeatXMenu"
	gui.ResetOnSpawn   = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder   = 950
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled        = false
	gui.Parent         = parent

	local totalW = #COLUMNS_DEF * COL_W + (#COLUMNS_DEF - 1) * COL_GAP

	local canvas = Instance.new("CanvasGroup")
	canvas.Name              = "Canvas"
	canvas.AnchorPoint       = Vector2.new(0.5, 0.5)
	canvas.Position          = UDim2.fromScale(0.5, 0.5)
	canvas.Size              = UDim2.new(0, totalW, 0.88, 0)
	canvas.BackgroundColor3  = C.OverlayBg
	canvas.GroupTransparency = 1
	canvas.BorderSizePixel   = 0
	canvas.Parent = gui
	addCorner(canvas, 3)

	local sc = Instance.new("UISizeConstraint")
	sc.MinSize = Vector2.new(totalW, 240)
	sc.MaxSize = Vector2.new(totalW, 880)
	sc.Parent  = canvas

	local uiScale = Instance.new("UIScale")
	uiScale.Scale  = 0.97
	uiScale.Parent = canvas

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection     = Enum.FillDirection.Horizontal
	hLayout.Padding           = UDim.new(0, COL_GAP)
	hLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	hLayout.Parent = canvas

	local columns = {}
	for i, def in ipairs(COLUMNS_DEF) do
		local col = buildColumn(def)
		col.LayoutOrder = i
		col.Parent      = canvas
		columns[i]      = col
	end

	local dragging   = false
	local dragOffset = Vector2.zero
	local firstHdr   = columns[1] and columns[1]:FindFirstChild("Header")

	if firstHdr then
		firstHdr.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging   = true
				local m    = UserInputService:GetMouseLocation()
				dragOffset = canvas.AbsolutePosition - Vector2.new(m.X, m.Y)
			end
		end)
	end

	local dEnd = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local dMove = UserInputService.InputChanged:Connect(function(inp)
		if not dragging or inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local m  = UserInputService:GetMouseLocation()
		local cs = canvas.AbsoluteSize
		local ss = gui.AbsoluteSize
		local x  = math.clamp(m.X + dragOffset.X, 0, math.max(0, ss.X - cs.X))
		local y  = math.clamp(m.Y + dragOffset.Y, 0, math.max(0, ss.Y - cs.Y))
		canvas.Position = UDim2.fromOffset(x + cs.X * 0.5, y + cs.Y * 0.5)
	end)

	local menu = setmetatable({}, Menu)
	menu.Gui       = gui
	menu.Canvas    = canvas
	menu.Scale     = uiScale
	menu.Columns   = columns
	menu.DragConns = { dEnd, dMove }
	menu.Visible   = false
	menu.Destroyed = false
	menu.OnUtility = {}

	_instance = menu
	return menu
end

function Menu.Get()
	return _instance
end

function Menu:Open()
	if self.Visible then return end
	self:_stopAnims()
	self.Visible                  = true
	self.Gui.Enabled              = true
	self.Canvas.GroupTransparency = 1
	self.Scale.Scale              = 0.97

	self._ft = TweenService:Create(
		self.Canvas,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	self._st = TweenService:Create(
		self.Scale,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	self._ft:Play()
	self._st:Play()
end

function Menu:Close()
	if not self.Visible then return end
	self:_stopAnims()
	self.Visible = false

	self._ft = TweenService:Create(
		self.Canvas,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ GroupTransparency = 1 }
	)
	self._st = TweenService:Create(
		self.Scale,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Scale = 0.97 }
	)
	self._ft:Play()
	self._st:Play()

	task.delay(0.18, function()
		if self.Destroyed or self.Visible then return end
		self.Gui.Enabled = false
	end)
end

function Menu:Toggle()
	if self.Visible then self:Close() else self:Open() end
end

function Menu:_stopAnims()
	if self._ft then self._ft:Cancel() end
	if self._st then self._st:Cancel() end
end
Menu.StopAnims = Menu._stopAnims

function Menu:Center()
	self.Canvas.Position = UDim2.fromScale(0.5, 0.5)
end

function Menu:Destroy()
	if self.Destroyed then return end
	self.Destroyed = true
	self:_stopAnims()
	for _, c in ipairs(self.DragConns) do c:Disconnect() end
	if self.Gui then self.Gui:Destroy() end
	if _instance == self then _instance = nil end
end

return Menu