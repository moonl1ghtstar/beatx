--[[

 /$$$$$$$                        /$$     /$$   /$$
| $$__  $$                      | $$    | $$  / $$
| $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
| $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/ 
| $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$ 
| $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
| $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
|_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - GUI Menu

]]--
local Menu = {}
Menu.__index = Menu

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local MENU_TOP_Y       = 0

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

local function snapCanvasTop(canvas, targetTop)
	targetTop = targetTop or MENU_TOP_Y
	local deltaY = targetTop - canvas.AbsolutePosition.Y
	if math.abs(deltaY) < 0.5 then
		return
	end
	local pos = canvas.Position
	canvas.Position = UDim2.fromOffset(pos.X.Offset, pos.Y.Offset + deltaY)
	RunService.Heartbeat:Wait()
end
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
local function buildColumn(def, parentRow)
	local expandedContentH = contentHeight(#def.Items)
	local expandedTotalH   = HDR_H + expandedContentH

	local slot = Instance.new("Frame")
	slot.Name                   = "Slot_" .. def.Name
	slot.BackgroundTransparency = 1
	slot.BorderSizePixel        = 0
	slot.Size                   = UDim2.new(0, COL_W, 0, expandedTotalH)
	slot.Parent                 = parentRow

	local container = Instance.new("Frame")
	container.Name                   = "Container_" .. def.Name
	container.BackgroundTransparency = 1
	container.BorderSizePixel        = 0
	container.Size                   = UDim2.new(1, 0, 1, 0)
	container.Parent                 = slot

	local wrap = Instance.new("Frame")
	wrap.Name                   = "Wrap_" .. def.Name
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel        = 0
	wrap.Size                   = UDim2.new(1, 0, 1, 0)
	wrap.ClipsDescendants       = true
	wrap.Parent                 = container

	if DEBUG_UI then
		wrap.BackgroundColor3       = DBG.Wrap
		wrap.BackgroundTransparency = 0.6
	end

	local hdr = Instance.new("Frame")
	hdr.Name             = "Header"
	hdr.BackgroundColor3 = C.HdrA
	hdr.BorderSizePixel  = 0
	hdr.Size             = UDim2.new(1, 0, 0, HDR_H)
	hdr.Position         = UDim2.fromOffset(0, 0)
	hdr.Parent           = wrap

	if DEBUG_UI then hdr.BackgroundColor3 = DBG.Header end

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
	colBtn.Position               = UDim2.fromOffset(0, 0)
	colBtn.TextXAlignment         = Enum.TextXAlignment.Center
	colBtn.TextYAlignment         = Enum.TextYAlignment.Center
	colBtn.ZIndex                 = 3
	colBtn.Parent                 = hdr

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

	local content = Instance.new("Frame")
	content.Name              = "Content"
	content.BackgroundColor3  = C.ColBg
	content.BorderSizePixel   = 0
	content.ClipsDescendants  = true
	content.Position          = UDim2.fromOffset(0, HDR_H)
	content.Size              = UDim2.new(1, 0, 0, expandedContentH)
	content.Parent            = wrap

	if DEBUG_UI then content.BackgroundColor3 = DBG.Content end

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

	local collapsed = false
	colBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		colBtn.Text = collapsed and "+" or "-"
		if collapsed then
			content.Size = UDim2.new(1, 0, 0, 0)
			slot.Size    = UDim2.new(0, COL_W, 0, HDR_H)
		else
			content.Size = UDim2.new(1, 0, 0, expandedContentH)
			slot.Size    = UDim2.new(0, COL_W, 0, expandedTotalH)
		end
	end)

	return { Slot = slot, Container = container, Wrap = wrap }
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

	local blocker = Instance.new("TextButton")
	blocker.Name                   = "InputBlocker"
	blocker.Size                   = UDim2.fromScale(1, 1)
	blocker.BackgroundTransparency = 1
	blocker.Text                   = ""
	blocker.AutoButtonColor        = false
	blocker.Active                 = true
	blocker.Visible                = false
	blocker.ZIndex                 = 0
	blocker.Parent                 = gui

	local totalW = 7 * COL_W + 6 * COL_GAP -- 7 items wide

	local canvas = Instance.new("Frame")
	canvas.Name                  = "Canvas"
	canvas.AnchorPoint           = Vector2.new(0.5, 0)
	canvas.Position              = UDim2.fromScale(0.5, 0)
	canvas.Size                  = UDim2.new(0, totalW, 0, 0)
	canvas.AutomaticSize         = Enum.AutomaticSize.XY
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel       = 0
	canvas.ZIndex                = 1
	canvas.Parent                = gui

	if DEBUG_UI then
		canvas.BackgroundColor3       = DBG.Canvas
		canvas.BackgroundTransparency = 0.7
	end

	local vLayout = Instance.new("UIListLayout")
	vLayout.Name = "VLayout"
	vLayout.FillDirection = Enum.FillDirection.Vertical
	vLayout.Padding = UDim.new(0, 10)
	vLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vLayout.Parent = canvas

	local topRow = Instance.new("Frame")
	topRow.Name = "TopRow"
	topRow.BackgroundTransparency = 1
	topRow.AutomaticSize = Enum.AutomaticSize.XY
	topRow.LayoutOrder = 1
	topRow.Parent = canvas

	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.Padding = UDim.new(0, COL_GAP)
	topLayout.SortOrder = Enum.SortOrder.LayoutOrder
	topLayout.Parent = topRow

	local bottomRow = Instance.new("Frame")
	bottomRow.Name = "BottomRow"
	bottomRow.BackgroundTransparency = 1
	bottomRow.AutomaticSize = Enum.AutomaticSize.XY
	bottomRow.LayoutOrder = 2
	bottomRow.Parent = canvas

	local bottomLayout = Instance.new("UIListLayout")
	bottomLayout.FillDirection = Enum.FillDirection.Horizontal
	bottomLayout.Padding = UDim.new(0, COL_GAP)
	bottomLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bottomLayout.Parent = bottomRow

	local columns = {}
	for i, def in ipairs(CATS) do
		local parentRow = (def.Name == "Speedhack") and bottomRow or topRow
		local col = buildColumn(def, parentRow)
		col.Slot.LayoutOrder = i
		col.Def = def
		columns[i] = col
	end

	local dragging   = false
	local dragOffset = Vector2.zero
	local firstHdr   = columns[1].Wrap:FindFirstChild("Header")

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
		canvas.Position = UDim2.fromOffset(x + cs.X * 0.5, y)
	end)

	local menu = setmetatable({}, Menu)
	menu.Gui          = gui
	menu.Canvas       = canvas
	menu.Blocker      = blocker
	menu.Columns      = columns
	menu.DragConns    = { dEnd, dMove }
	menu.Visible      = false
	menu.Destroyed    = false
	menu.OnUtility    = {}
	menu._tweens      = {}

	_instance = menu
	return menu
end

function Menu.Get() return _instance end

function Menu:Open()
	if self.Visible then return end
	self:_stopAnims()
	self.Visible = true
	for _, colDef in ipairs(self.Columns) do colDef.Container.Visible = false end
	self.Gui.Enabled = true
	self.Canvas.AnchorPoint = Vector2.new(0.5, 0)
	self.Canvas.Position = UDim2.fromOffset(self.Gui.AbsoluteSize.X * 0.5, MENU_TOP_Y)
	self.Blocker.Visible = true
	self.Canvas.Position = UDim2.fromOffset(self.Gui.AbsoluteSize.X * 0.5, MENU_TOP_Y)
	task.defer(function()
		if not self.Visible or self.Destroyed then return end
		self.Canvas.Position = UDim2.fromOffset(self.Gui.AbsoluteSize.X * 0.5, MENU_TOP_Y)
		snapCanvasTop(self.Canvas, MENU_TOP_Y)
		print(string.format('[BeatX][Layout] Open CanvasAbs=(%.0f,%.0f) CanvasPos=%s', self.Canvas.AbsolutePosition.X, self.Canvas.AbsolutePosition.Y, tostring(self.Canvas.Position)))
		for i, colDef in ipairs(self.Columns) do
			local container, slot = colDef.Container, colDef.Slot
			local catHeight = slot.Size.Y.Offset
			local vw, vh = self.Gui.AbsoluteSize.X, self.Gui.AbsoluteSize.Y
			local scaleX, scaleY = vw / 1920, vh / 1080
			local refX, refY
			if i == 1 then refX, refY = 1920, 520 elseif i == 2 then refX, refY = 1920, 560 elseif i == 3 then refX, refY = 950, 0 elseif i == 4 then refX, refY = 1440, catHeight + 1080 elseif i == 5 then refX, refY = 1920, 800 elseif i == 6 then refX, refY = 1920, 850 elseif i == 7 then refX, refY = 620, 0 elseif i == 8 then refX, refY = 930, 0 end
			local screenX = refX * scaleX
						local screenY
			if i == 4 then
				local levelHeight = HDR_H
				if levelHeight <= 0 then levelHeight = HDR_H end
				local levelReferenceY = 1080 + levelHeight
				screenY = vh - (levelReferenceY * scaleY)
			else
				screenY = vh - (refY * scaleY)
			end
			local localX, localY = screenX - slot.AbsolutePosition.X, screenY - slot.AbsolutePosition.Y
			if colDef.Def.Name == "BeatX" or colDef.Def.Name == "Creator" or colDef.Def.Name == "Cosmetic" or colDef.Def.Name == "Level" then
				print(string.format('[BeatX][Anim][Open] %s i=%d screenStart=(%.0f,%.0f) localStart=(%.0f,%.0f)', colDef.Def.Name, i, screenX, screenY, localX, localY))
				container.Position = UDim2.fromOffset(localX, localY)
				container.Visible = true
				local delay = (i - 1) * 0.035
				local tw = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, delay), { Position = UDim2.new(0, 0, 0, 0) })
				table.insert(self._tweens, tw)
				tw:Play()
			else
				container.Position = UDim2.fromOffset(0, 0)
				container.Visible = true
			end
		end
	end)
end

function Menu:Close()
	if not self.Visible then return end
	self:_stopAnims()
	self.Visible = false
	local maxDuration = 0
	for i, colDef in ipairs(self.Columns) do
		local container, slot = colDef.Container, colDef.Slot
		local catHeight = slot.Size.Y.Offset
		local vw, vh = self.Gui.AbsoluteSize.X, self.Gui.AbsoluteSize.Y
		local scaleX, scaleY = vw / 1920, vh / 1080
		local refX, refY
		if i == 1 then refX, refY = 1920, 520 elseif i == 2 then refX, refY = 1920, 560 elseif i == 3 then refX, refY = 950, 0 elseif i == 4 then refX, refY = 1440, catHeight + 1080 elseif i == 5 then refX, refY = 1920, 800 elseif i == 6 then refX, refY = 1920, 850 elseif i == 7 then refX, refY = 620, 0 elseif i == 8 then refX, refY = 930, 0 end
		local screenX = refX * scaleX
					local screenY
			if i == 4 then
				local levelHeight = HDR_H
				if levelHeight <= 0 then levelHeight = HDR_H end
				local levelReferenceY = 1080 + levelHeight
				screenY = vh - (levelReferenceY * scaleY)
			else
				screenY = vh - (refY * scaleY)
			end
		local localX, localY = screenX - slot.AbsolutePosition.X, screenY - slot.AbsolutePosition.Y
		if colDef.Def.Name == "BeatX" or colDef.Def.Name == "Creator" or colDef.Def.Name == "Cosmetic" or colDef.Def.Name == "Level" then
			print(string.format('[BeatX][Anim][Close] %s i=%d screenExit=(%.0f,%.0f) localExit=(%.0f,%.0f)', colDef.Def.Name, i, screenX, screenY, localX, localY))
			local delay, duration = (i - 1) * 0.035, 0.23
			maxDuration = math.max(maxDuration, duration + delay)
			local tw = TweenService:Create(container, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, delay), { Position = UDim2.fromOffset(localX, localY) })
			table.insert(self._tweens, tw)
			tw:Play()
		else
			container.Position = UDim2.fromOffset(0, 0)
		end
	end
	task.delay(maxDuration, function()
		if self.Destroyed or self.Visible then return end
		self.Blocker.Visible = false
		self.Gui.Enabled = false
	end)
end
function Menu:Toggle()
	if self.Visible then self:Close() else self:Open() end
end

function Menu:_stopAnims()
	if self._tweens then
		for _, tw in ipairs(self._tweens) do
			tw:Cancel()
		end
		self._tweens = {}
	end
end
Menu.StopAnims = Menu._stopAnims

function Menu:Center()
	self.Canvas.Position = UDim2.fromScale(0.5, 0)
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