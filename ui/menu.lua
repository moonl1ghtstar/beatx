-- BeatX ui/Menu.lua  -- demo layout, 8 categories, sharp corners, no indicators

local Menu = {}
Menu.__index = Menu

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ── Debug ──────────────────────────────────────────────────────────────────────
-- Set true to print collapse hierarchy + apply distinct debug colors per layer.
local DEBUG_UI = false

local function dbgObj(path, obj)
	if not DEBUG_UI then return end
	local r,g,b = obj.BackgroundColor3.R*255, obj.BackgroundColor3.G*255, obj.BackgroundColor3.B*255
	local absSz = pcall(function() return obj.AbsoluteSize end) and obj.AbsoluteSize or Vector2.zero
	local absPos = pcall(function() return obj.AbsolutePosition end) and obj.AbsolutePosition or Vector2.zero
	local autoSz = pcall(function() return tostring(obj.AutomaticSize) end) and tostring(obj.AutomaticSize) or "N/A"
	local clips  = pcall(function() return tostring(obj.ClipsDescendants) end) and tostring(obj.ClipsDescendants) or "N/A"
	local vis    = pcall(function() return tostring(obj.Visible) end) and tostring(obj.Visible) or "N/A"
	local bgT    = pcall(function() return obj.BackgroundTransparency end) and obj.BackgroundTransparency or -1
	print(string.format(
		"[BeatX DEBUG][BG] PATH=%s | Class=%s | Visible=%s | BgTransp=%.2f | BgColor=RGB(%d,%d,%d) | Size=%s | AbsSize=(%.0f,%.0f) | AbsPos=(%.0f,%.0f) | AutoSize=%s | Clips=%s",
		path, obj.ClassName, vis, bgT, r, g, b,
		tostring(obj.Size), absSz.X, absSz.Y, absPos.X, absPos.Y, autoSz, clips
	))
	-- Flag objects rendering a visible dark background
	if bgT < 1 and absSz.Y > 0 and (r < 50 and g < 50 and b < 60) then
		print(string.format(
			"[BeatX DEBUG][SIZE] *** DARK BG RENDERED: %s | AbsHeight=%.0f | BgRGB=(%d,%d,%d) ***",
			path, absSz.Y, r, g, b
		))
	end
end

local function dbgCollapse(catName, canvas, wrap, hdr, content)
	if not DEBUG_UI then return end
	print("[BeatX DEBUG][COLLAPSE] === Category: " .. catName .. " collapsed ===")
	-- Wait one frame so AbsoluteSize reflects the new layout
	task.defer(function()
		dbgObj("Canvas",              canvas)
		dbgObj("Canvas/Wrap_"..catName, wrap)
		dbgObj("Canvas/Wrap_"..catName.."/Header",  hdr)
		dbgObj("Canvas/Wrap_"..catName.."/Content", content)
	end)
end

-- ── Palette ────────────────────────────────────────────────────────────────────
local ACCENT  = Color3.fromRGB(232, 56, 102)
local ACCENTD = Color3.fromRGB(185, 40,  80)

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

-- Debug layer colors — distinct per object type, only when DEBUG_UI = true
local DBG = {
	Canvas  = Color3.fromRGB(0,   0,   200),  -- blue  (canvas bg)
	Wrap    = Color3.fromRGB(0,   200, 0),    -- green (wrap bg)
	Content = Color3.fromRGB(200, 200, 0),    -- yellow (content bg)
	Header  = Color3.fromRGB(200, 0,   200),  -- magenta (header bg)
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

-- ── Helpers ────────────────────────────────────────────────────────────────────
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

-- ── Row ────────────────────────────────────────────────────────────────────────
local function buildRow(parent, label)
	local on  = false
	local hov = false

	local row = Instance.new("TextButton")
	row.AutoButtonColor        = false
	row.BorderSizePixel        = 0
	row.Size                   = UDim2.new(1, 0, 0, ROW_H)
	row.Text                   = ""
	row.BackgroundColor3       = Color3.new(0, 0, 0)
	row.BackgroundTransparency = 0

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, ACCENT)
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.5)
	})
	grad.Rotation = 0
	grad.Enabled  = false
	grad.Parent   = row

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel        = 0
	lbl.Font                   = FG
	lbl.Text                   = label
	lbl.TextColor3             = Color3.new(1, 1, 1)
	lbl.TextSize               = 14
	lbl.TextScaled             = false
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.Position               = UDim2.fromOffset(0, 0)
	lbl.Parent                 = row

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = lbl

	local bar = Instance.new("Frame")
	bar.Name                   = "AccentBar"
	bar.BorderSizePixel        = 0
	bar.BackgroundColor3       = Color3.fromRGB(110, 110, 110)
	bar.Size                   = UDim2.new(0, 2, 1, -4)
	bar.Position               = UDim2.new(1, -2, 0.5, 0)
	bar.AnchorPoint            = Vector2.new(1, 0.5)
	bar.Visible                = true
	bar.Parent                 = row

	local function refresh()
		if on then
			row.BackgroundColor3 = Color3.new(1, 1, 1) -- White so gradient shows accurate colors
			grad.Enabled         = true
			lbl.TextColor3       = ACCENT
			bar.BackgroundColor3 = ACCENT
		else
			row.BackgroundColor3 = hov and Color3.fromRGB(15, 15, 15) or Color3.new(0, 0, 0)
			grad.Enabled         = false
			lbl.TextColor3       = Color3.new(1, 1, 1)
			bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
		end
	end

	row.MouseButton1Click:Connect(function() on = not on; refresh() end)
	row.MouseEnter:Connect(function()        hov = true;  if not on then refresh() end end)
	row.MouseLeave:Connect(function()        hov = false; if not on then refresh() end end)

	row.Parent = parent
	return row
end

-- ── Column ─────────────────────────────────────────────────────────────────────
--
-- DEFINITIVE FIX — analysis of every rendering layer:
--
--  Previous attempt (wrap stays fixed height + wrap.Bg = C.Bg):
--    wrap bg = C.Bg = RGB(18,17,22) — that IS dark / nearly black.
--    Below the collapsed header (24px), the wrap bg fills (expandedTotalH - HDR_H)
--    = ~23px with a dark rectangle. THAT is the black background the user sees.
--    Making wrap.Bg match canvas.Bg does not fix it — C.Bg is dark regardless.
--
--  Root cause objects responsible for the dark area (in order):
--    1. canvas (CanvasGroup) — BackgroundColor3=C.Bg, always full height via AutomaticSize=Y
--       → renders dark behind all columns including the gap below a collapsed wrap
--    2. wrap (Frame) — BackgroundColor3=C.Bg, fixed full height
--       → renders dark ABOVE the canvas bg; same dark color; doubly dark
--
--  Correct fix:
--    • canvas.BackgroundTransparency = 1  — canvas provides GroupTransparency fade
--      but does NOT need to render its own background rectangle.
--    • wrap.BackgroundTransparency = 1  — wrapper is structural only, no bg.
--    • wrap DOES shrink to HDR_H on collapse — canvas AutomaticSize=Y then
--      equals the tallest remaining column.
--    • content shrinks to 0 on collapse — ColBg disappears.
--    • Result: collapsed column = accent header only. Nothing below it renders.
--      The area behind/below the collapsed column is fully transparent (shows game).
--    • Each column's content (ColBg) and header (accent) provide all visible color.
--      No outer "menu background" rectangle — each column is self-contained.
--
local function buildColumn(def, canvas)
	local expandedContentH = contentHeight(#def.Items)
	local expandedTotalH   = HDR_H + expandedContentH

	-- wrap: structural only.
	-- BackgroundTransparency=1 — wrap renders NO background.
	-- Height is controlled manually: expandedTotalH when open, HDR_H when collapsed.
	-- canvas AutomaticSize=Y will track the tallest wrap automatically.
	local wrap = Instance.new("Frame")
	wrap.Name                   = "Wrap_" .. def.Name
	wrap.BackgroundTransparency = 1      -- ← TRANSPARENT: zero dark bg from wrap
	wrap.BorderSizePixel        = 0
	wrap.Size                   = UDim2.new(0, COL_W, 0, expandedTotalH)
	wrap.ClipsDescendants       = true   -- content can't bleed outside wrap bounds

	-- Debug: give wrap a visible color to confirm it's the right object
	if DEBUG_UI then
		wrap.BackgroundColor3       = DBG.Wrap
		wrap.BackgroundTransparency = 0.6  -- semi-transparent green in debug mode
	end

	-- ── Header ────────────────────────────────────────────────────────────────
	local hdr = Instance.new("Frame")
	hdr.Name             = "Header"
	hdr.BackgroundColor3 = C.HdrA
	hdr.BorderSizePixel  = 0
	hdr.Size             = UDim2.new(1, 0, 0, HDR_H)
	hdr.Position         = UDim2.fromOffset(0, 0)
	hdr.Parent           = wrap
	-- No gradient: solid Color3.fromRGB(232, 56, 102) throughout

	if DEBUG_UI then
		hdr.BackgroundColor3 = DBG.Header   -- magenta in debug
	end

	-- +/- button: LEFT side, fixed 20px
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
	colBtn.Position               = UDim2.fromOffset(0, 0)  -- LEFT edge
	colBtn.TextXAlignment         = Enum.TextXAlignment.Center
	colBtn.TextYAlignment         = Enum.TextYAlignment.Center
	colBtn.ZIndex                 = 3
	colBtn.Parent                 = hdr

	-- Title: full header width → Center alignment = true mathematical center
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
	hdrLbl.Position               = UDim2.fromOffset(0, 0)
	hdrLbl.Size                   = UDim2.new(1, 0, 1, 0)
	hdrLbl.ZIndex                 = 2
	hdrLbl.Parent                 = hdr

	-- ── Content ───────────────────────────────────────────────────────────────
	-- ClipsDescendants=true: height=0 → nothing renders, bg invisible.
	local content = Instance.new("Frame")
	content.Name              = "Content"
	content.BackgroundColor3  = C.ColBg
	content.BorderSizePixel   = 0
	content.ClipsDescendants  = true
	content.Position          = UDim2.fromOffset(0, HDR_H)
	content.Size              = UDim2.new(1, 0, 0, expandedContentH)
	content.Parent            = wrap

	if DEBUG_UI then
		content.BackgroundColor3 = DBG.Content   -- yellow in debug
	end

	local cList = Instance.new("UIListLayout")
	cList.FillDirection = Enum.FillDirection.Vertical
	cList.Padding       = UDim.new(0, 0)
	cList.SortOrder     = Enum.SortOrder.LayoutOrder
	cList.Parent        = content

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

	-- ── Collapse logic ─────────────────────────────────────────────────────────
	-- wrap shrinks to HDR_H: no remaining wrap area exists below header.
	-- content shrinks to 0: its ColBg bg disappears entirely.
	-- canvas.AutomaticSize=Y updates to tallest remaining wrap.
	-- canvas.BackgroundTransparency=1: canvas renders no bg → nothing dark behind wrap.
	local collapsed = false
	colBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		colBtn.Text = collapsed and "+" or "-"
		if collapsed then
			content.Size = UDim2.new(1, 0, 0, 0)
			wrap.Size    = UDim2.new(0, COL_W, 0, HDR_H)
		else
			content.Size = UDim2.new(1, 0, 0, expandedContentH)
			wrap.Size    = UDim2.new(0, COL_W, 0, expandedTotalH)
		end
		-- Debug: print full hierarchy state after layout settles
		dbgCollapse(def.Name, canvas, wrap, hdr, content)
	end)

	return wrap
end

-- ── Menu.new ───────────────────────────────────────────────────────────────────
function Menu.new(BeatX)
	if _instance then return _instance end

	local parent = getGuiParent()
	assert(parent, "[BeatX] no GUI parent")

	do
		local old = parent:FindFirstChild("BeatXMenu")
		if old then old:Destroy() end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name            = "BeatXMenu"
	gui.ResetOnSpawn    = false
	gui.IgnoreGuiInset  = true
	gui.DisplayOrder    = 950
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	gui.Enabled         = false
	gui.Parent          = parent

	local totalW = #CATS * COL_W + (#CATS - 1) * COL_GAP

	-- CanvasGroup: used only for GroupTransparency fade.
	-- BackgroundTransparency = 1 — canvas renders NO dark background rectangle.
	-- Without this, canvas bg (C.Bg = nearly black) always fills the full
	-- AutomaticSize height behind all columns, causing a dark band below
	-- any collapsed column that is shorter than the tallest column.
	local canvas = Instance.new("CanvasGroup")
	canvas.Name                  = "Canvas"
	canvas.AnchorPoint           = Vector2.new(0.5, 0.5)
	canvas.Position              = UDim2.fromScale(0.5, 0.5)
	canvas.Size                  = UDim2.new(0, totalW, 0, 0)
	canvas.AutomaticSize         = Enum.AutomaticSize.Y
	canvas.BackgroundTransparency = 1    -- ← KEY: no canvas dark bg rectangle
	canvas.GroupTransparency     = 1
	canvas.BorderSizePixel       = 0
	canvas.Parent                = gui

	-- Debug: show canvas bg to confirm its bounds
	if DEBUG_UI then
		canvas.BackgroundColor3       = DBG.Canvas
		canvas.BackgroundTransparency = 0.7  -- semi-transparent blue in debug
	end

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection       = Enum.FillDirection.Horizontal
	hLayout.Padding             = UDim.new(0, COL_GAP)
	hLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	hLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	hLayout.Parent              = canvas

	local columns = {}
	for i, def in ipairs(CATS) do
		local col       = buildColumn(def, canvas)
		col.LayoutOrder = i
		col.Parent      = canvas
		columns[i]      = col
	end

	-- Debug: print initial state
	if DEBUG_UI then
		task.defer(function()
			print("[BeatX DEBUG][COLLAPSE] === INITIAL STATE ===")
			dbgObj("Canvas", canvas)
			for i, col in ipairs(columns) do
				local catName = CATS[i].Name
				dbgObj("Canvas/Wrap_"..catName, col)
				local hdr = col:FindFirstChild("Header")
				local cnt = col:FindFirstChild("Content")
				if hdr then dbgObj("Canvas/Wrap_"..catName.."/Header", hdr) end
				if cnt then dbgObj("Canvas/Wrap_"..catName.."/Content", cnt) end
			end
		end)
	end

	-- Drag via first header
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