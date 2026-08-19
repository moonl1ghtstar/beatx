-- BeatX ui/Menu.lua  -- demo layout, 8 categories, sharp corners, no indicators

local Menu = {}
Menu.__index = Menu

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ─── Palette ──────────────────────────────────────────────────────────────────
-- Accent is exactly RGB(232, 56, 102) throughout.
local ACCENT  = Color3.fromRGB(232, 56, 102)
local ACCENTD = Color3.fromRGB(185, 40,  80)   -- darker shade for gradient end

local C = {
	Bg       = Color3.fromRGB(18,  17,  22),
	ColBg    = Color3.fromRGB(22,  21,  27),
	HdrA     = ACCENT,
	HdrB     = ACCENTD,
	RowOff   = Color3.fromRGB(22,  21,  27),
	RowOn    = Color3.fromRGB(140, 20,  55),
	RowHov   = Color3.fromRGB(32,  30,  38),
	RowHovOn = Color3.fromRGB(158, 28,  65),
	TxtHdr   = Color3.fromRGB(255, 255, 255),
	TxtOn    = Color3.fromRGB(255, 185, 200),
	TxtOff   = Color3.fromRGB(210, 205, 220),
	ScrollT  = ACCENT,
	Sep      = Color3.fromRGB(34,  32,  41),
}

local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium
local FG = Enum.Font.Gotham

local COL_W   = 140
local COL_GAP = 4
local ROW_H   = 22
local HDR_H   = 24
local SEP_H   = 1

-- 8 categories, each with one "Test" demo item
local CATS = {
	{ Name = "BeatX",      Items = { "Test" } },
	{ Name = "Creator",    Items = { "Test" } },
	{ Name = "Cosmetic",   Items = { "Test" } },
	{ Name = "Level",      Items = { "Test" } },
	{ Name = "Status",     Items = { "Test" } },
	{ Name = "Display",    Items = { "Test" } },
	{ Name = "Utility",    Items = { "Test" } },
	{ Name = "Speedhack",  Items = { "Test" } },
}

local _instance = nil

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function getGuiParent()
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg end
	local lp = game:GetService("Players").LocalPlayer
	if lp then return lp:WaitForChild("PlayerGui", 5) end
end

local function addGrad(inst, a, b)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, a),
		ColorSequenceKeypoint.new(1, b),
	})
	g.Rotation = 90
	g.Parent   = inst
end

local function contentHeight(itemCount)
	return SEP_H + itemCount * ROW_H
end

-- ─── Row ──────────────────────────────────────────────────────────────────────
local function buildRow(parent, label)
	local on  = false
	local hov = false

	local row = Instance.new("TextButton")
	row.AutoButtonColor        = false
	row.BorderSizePixel        = 0
	row.Size                   = UDim2.new(1, 0, 0, ROW_H)
	row.Text                   = ""
	row.BackgroundColor3       = C.RowOff
	row.BackgroundTransparency = 0

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel        = 0
	lbl.Font                   = FG
	lbl.Text                   = label
	lbl.TextColor3             = C.TxtOff
	lbl.TextSize               = 14
	lbl.TextScaled             = false
	lbl.TextXAlignment         = Enum.TextXAlignment.Center
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.Position               = UDim2.fromOffset(0, 0)
	lbl.Parent                 = row

	local function refresh()
		if on then
			row.BackgroundColor3 = hov and C.RowHovOn or C.RowOn
			lbl.TextColor3       = C.TxtOn
		else
			row.BackgroundColor3 = hov and C.RowHov or C.RowOff
			lbl.TextColor3       = C.TxtOff
		end
	end

	row.MouseButton1Click:Connect(function() on = not on; refresh() end)
	row.MouseEnter:Connect(function()        hov = true;  refresh() end)
	row.MouseLeave:Connect(function()        hov = false; refresh() end)

	row.Parent = parent
	return row
end

-- ─── Column ───────────────────────────────────────────────────────────────────
--
-- Layout explanation (the only correct fix for leftover bg):
--
--   canvas (CanvasGroup, AutomaticSize=Y, bg=C.Bg, horizontal UIListLayout)
--     └─ wrap  (Frame, fixed width=COL_W, height ALWAYS = expandedTotalH)
--              bg = C.Bg  ← matches canvas bg; covers canvas bg below content
--              ClipsDescendants = false (wrap is transparent/Bg-colored filler)
--          ├─ hdr     (Frame, 0..HDR_H)
--          └─ content (Frame, HDR_H..HDR_H+contentH, ClipsDescendants=true)
--                      ↑ shrinks to height=0 on collapse, bg disappears with it
--
-- Why wrap height stays fixed:
--   canvas AutomaticSize=Y = max child height = expandedTotalH (from tallest column).
--   If wrap shrank on collapse, canvas bg (C.Bg, dark) would show in the vacated
--   space. By keeping wrap full-height with bg=C.Bg, the wrap occludes that canvas
--   bg with an identical color — visually the area is always C.Bg, never ColBg.
--   The only colored area is hdr (accent) + content (ColBg). When content height=0
--   there is zero ColBg visible. Wrap bg = C.Bg = same as canvas = invisible seam.
--
local function buildColumn(def)
	local expandedContentH = contentHeight(#def.Items)
	local expandedTotalH   = HDR_H + expandedContentH

	-- wrap: fixed width, ALWAYS full height, bg=C.Bg to occlude canvas bg below content
	local wrap = Instance.new("Frame")
	wrap.Name                   = "Wrap_" .. def.Name
	wrap.BackgroundColor3       = C.Bg       -- matches canvas bg — no seam visible
	wrap.BackgroundTransparency = 0
	wrap.BorderSizePixel        = 0
	wrap.Size                   = UDim2.new(0, COL_W, 0, expandedTotalH)
	-- Height is FIXED, never shrinks. Only content shrinks. This prevents canvas
	-- bg from ever being exposed behind/below this column.

	-- ── Header ──────────────────────────────────────────────────────────────
	local hdr = Instance.new("Frame")
	hdr.Name             = "Header"
	hdr.BackgroundColor3 = C.HdrA
	hdr.BorderSizePixel  = 0
	hdr.Size             = UDim2.new(1, 0, 0, HDR_H)
	hdr.Position         = UDim2.fromOffset(0, 0)
	hdr.Parent           = wrap
	addGrad(hdr, C.HdrA, C.HdrB)

	-- +/- button: LEFT side of header, fixed 20px wide
	local colBtn = Instance.new("TextButton")
	colBtn.AutoButtonColor        = false
	colBtn.BackgroundTransparency = 1
	colBtn.BorderSizePixel        = 0
	colBtn.Font                   = FM
	colBtn.Text                   = "-"
	colBtn.TextColor3             = C.TxtHdr
	colBtn.TextSize               = 14
	colBtn.TextScaled             = false
	colBtn.Size                   = UDim2.fromOffset(20, HDR_H)
	colBtn.Position               = UDim2.fromOffset(0, 0)   -- LEFT edge
	colBtn.TextXAlignment         = Enum.TextXAlignment.Center
	colBtn.TextYAlignment         = Enum.TextYAlignment.Center
	colBtn.ZIndex                 = 3
	colBtn.Parent                 = hdr

	-- Title label: spans FULL header width → TextXAlignment.Center = true center
	-- The +/- button is a sibling rendered above (ZIndex 3 vs label ZIndex 2).
	-- Title visually sits behind the button text, but the button is only 20px wide
	-- so the title text is only obscured at the left edge — title remains legible
	-- and mathematically centered across the full 140px header.
	local hdrLbl = Instance.new("TextLabel")
	hdrLbl.BackgroundTransparency = 1
	hdrLbl.BorderSizePixel        = 0
	hdrLbl.Font                   = FB
	hdrLbl.Text                   = def.Name
	hdrLbl.TextColor3             = C.TxtHdr
	hdrLbl.TextSize               = 14
	hdrLbl.TextScaled             = false
	hdrLbl.TextXAlignment         = Enum.TextXAlignment.Center
	hdrLbl.TextYAlignment         = Enum.TextYAlignment.Center
	hdrLbl.Position               = UDim2.fromOffset(0, 0)   -- full width, from x=0
	hdrLbl.Size                   = UDim2.new(1, 0, 1, 0)    -- 100% header width
	hdrLbl.ZIndex                 = 2
	hdrLbl.Parent                 = hdr

	-- ── Content ─────────────────────────────────────────────────────────────
	-- ClipsDescendants=true: when height=0 nothing inside renders.
	-- BackgroundColor3=ColBg: visible only when height > 0.
	local content = Instance.new("Frame")
	content.Name              = "Content"
	content.BackgroundColor3  = C.ColBg
	content.BorderSizePixel   = 0
	content.ClipsDescendants  = true
	content.Position          = UDim2.fromOffset(0, HDR_H)
	content.Size              = UDim2.new(1, 0, 0, expandedContentH)
	content.Parent            = wrap

	local cList = Instance.new("UIListLayout")
	cList.FillDirection = Enum.FillDirection.Vertical
	cList.Padding       = UDim.new(0, 0)
	cList.SortOrder     = Enum.SortOrder.LayoutOrder
	cList.Parent        = content

	-- Separator
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = C.Sep
	sep.BorderSizePixel  = 0
	sep.Size             = UDim2.new(1, 0, 0, SEP_H)
	sep.LayoutOrder      = 1
	sep.Parent           = content

	for i, name in ipairs(def.Items) do
		local r = buildRow(content, name)
		r.LayoutOrder = i + 1
	end

	-- ── Collapse logic ───────────────────────────────────────────────────────
	-- wrap stays at expandedTotalH always.
	-- Only content.Size changes: 0 when collapsed, expandedContentH when expanded.
	-- Collapsed state: content height=0, ClipsDescendants hides children, bg invisible.
	-- No residual dark area: wrap.Bg = C.Bg covers the space with canvas-matching color.
	local collapsed = false
	colBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		colBtn.Text = collapsed and "+" or "-"
		if collapsed then
			content.Size = UDim2.new(1, 0, 0, 0)
		else
			content.Size = UDim2.new(1, 0, 0, expandedContentH)
		end
	end)

	return wrap
end

-- ─── Menu.new ─────────────────────────────────────────────────────────────────
function Menu.new(BeatX)
	if _instance then return _instance end

	local parent = getGuiParent()
	assert(parent, "[BeatX] no GUI parent")

	do
		local old = parent:FindFirstChild("BeatXMenu")
		if old then old:Destroy() end
	end

	-- ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name            = "BeatXMenu"
	gui.ResetOnSpawn    = false
	gui.IgnoreGuiInset  = true
	gui.DisplayOrder    = 950
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	gui.Enabled         = false
	gui.Parent          = parent

	-- Canvas dimensions
	local totalW = #CATS * COL_W + (#CATS - 1) * COL_GAP

	-- CanvasGroup: horizontal container for all columns.
	-- AutomaticSize=Y: height = tallest column = expandedTotalH (all same here).
	-- BackgroundColor3 = C.Bg: provides the outer menu background.
	-- No UIScale, no UICorner, no UIStroke.
	local canvas = Instance.new("CanvasGroup")
	canvas.Name              = "Canvas"
	canvas.AnchorPoint       = Vector2.new(0.5, 0.5)
	canvas.Position          = UDim2.fromScale(0.5, 0.5)
	canvas.Size              = UDim2.new(0, totalW, 0, 0)
	canvas.AutomaticSize     = Enum.AutomaticSize.Y
	canvas.BackgroundColor3  = C.Bg
	canvas.GroupTransparency = 1
	canvas.BorderSizePixel   = 0
	canvas.Parent            = gui

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection       = Enum.FillDirection.Horizontal
	hLayout.Padding             = UDim.new(0, COL_GAP)
	hLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	hLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	hLayout.Parent              = canvas

	local columns = {}
	for i, def in ipairs(CATS) do
		local col       = buildColumn(def)
		col.LayoutOrder = i
		col.Parent      = canvas
		columns[i]      = col
	end

	-- ── Drag via first header ──────────────────────────────────────────────
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
	menu.Columns   = columns
	menu.DragConns = { dEnd, dMove }
	menu.Visible   = false
	menu.Destroyed = false
	menu.OnUtility = {}

	_instance = menu
	return menu
end

function Menu.Get() return _instance end

function Menu:Open()
	if self.Visible then return end
	self:_stopAnims()
	self.Visible                  = true
	self.Gui.Enabled              = true
	self.Canvas.GroupTransparency = 1
	self._ft = TweenService:Create(
		self.Canvas,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ GroupTransparency = 0 }
	)
	self._ft:Play()
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
	self._ft:Play()
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