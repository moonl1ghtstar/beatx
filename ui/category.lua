--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Category

 Responsible for one menu column in the Window -> Category ->
 Row -> Component chain. Mirrors the legacy menu.lua geometry
 (COL_W/HDR_H/ROW_H/SEP_H) and collapse behavior so existing
 columns keep working unchanged.
 Built by Menu.new from a declarative CategoryDef; BeatX is the
 first definition. Owns its rows and theme subscription, and
 releases both on Destroy.
]]

local Category = {}
Category.__index = Category

local DEFAULT_CONSTS = {
	COL_W = 140,
	HDR_H = 24,
	ROW_H = 22,
	SEP_H = 1,
}

-- Computes content height for a row count.
local function contentHeight(itemCount, consts)
	return consts.SEP_H + itemCount * consts.ROW_H
end

-- Builds the column frames and one row per CategoryDef item.
function Category.new(def, parentRow, ctx, consts)
	assert(type(def) == "table" and type(def.Name) == "string", "Invalid CategoryDef")
	assert(type(def.Items) == "table", "CategoryDef.Items missing")
	ctx = ctx or {}
	consts = consts or DEFAULT_CONSTS
	local rowFactory = ctx.RowFactory
	assert(rowFactory, "RowFactory missing in ctx")

	local itemCount = #def.Items
	local expandedContentH = contentHeight(itemCount, consts)
	local expandedTotalH = consts.HDR_H + expandedContentH

	local headerBg
	if ctx.Theme and type(ctx.Theme.Get) == "function" then
		headerBg = ctx.Theme:Get("Accent")
	else
		headerBg = Color3.fromRGB(232, 56, 102)
	end

	local slot = Instance.new("Frame")
	slot.Name = "Slot_" .. def.Name
	slot.BackgroundTransparency = 1
	slot.BorderSizePixel = 0
	slot.Size = UDim2.new(0, consts.COL_W, 0, expandedTotalH)
	slot.Parent = parentRow

	local container = Instance.new("Frame")
	container.Name = "Container_" .. def.Name
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.Size = UDim2.new(1, 0, 1, 0)
	container.Parent = slot

	local wrap = Instance.new("Frame")
	wrap.Name = "Wrap_" .. def.Name
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel = 0
	wrap.Size = UDim2.new(1, 0, 1, 0)
	wrap.ClipsDescendants = true
	wrap.Parent = container

	local hdr = Instance.new("Frame")
	hdr.Name = "Header"
	hdr.BackgroundColor3 = headerBg
	hdr.BorderSizePixel = 0
	hdr.Size = UDim2.new(1, 0, 0, consts.HDR_H)
	hdr.Position = UDim2.fromOffset(0, 0)
	hdr.Parent = wrap

	local colBtn = Instance.new("TextButton")
	colBtn.AutoButtonColor = false
	colBtn.BackgroundTransparency = 1
	colBtn.BorderSizePixel = 0
	colBtn.Font = Enum.Font.GothamMedium
	colBtn.Text = "-"
	colBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	colBtn.TextSize = 14
	colBtn.Size = UDim2.fromOffset(20, consts.HDR_H)
	colBtn.Position = UDim2.fromOffset(0, 0)
	colBtn.TextXAlignment = Enum.TextXAlignment.Center
	colBtn.TextYAlignment = Enum.TextYAlignment.Center
	colBtn.ZIndex = 3
	colBtn.Parent = hdr

	local hdrLbl = Instance.new("TextLabel")
	hdrLbl.BackgroundTransparency = 1
	hdrLbl.BorderSizePixel = 0
	hdrLbl.Font = Enum.Font.GothamBold
	hdrLbl.Text = def.Name
	hdrLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	hdrLbl.TextSize = 14
	hdrLbl.TextXAlignment = Enum.TextXAlignment.Center
	hdrLbl.TextYAlignment = Enum.TextYAlignment.Center
	hdrLbl.Position = UDim2.fromOffset(0, 0)
	hdrLbl.Size = UDim2.new(1, 0, 1, 0)
	hdrLbl.ZIndex = 2
	hdrLbl.Parent = hdr

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BorderSizePixel = 0
	if ctx.Theme and type(ctx.Theme.Get) == "function" then
		content.BackgroundColor3 = ctx.Theme:Get("Surface")
	else
		content.BackgroundColor3 = Color3.fromRGB(22, 21, 27)
	end
	content.ClipsDescendants = true
	content.Position = UDim2.fromOffset(0, consts.HDR_H)
	content.Size = UDim2.new(1, 0, 0, expandedContentH)
	content.Parent = wrap

	local cList = Instance.new("UIListLayout")
	cList.FillDirection = Enum.FillDirection.Vertical
	cList.Padding = UDim.new(0, 0)
	cList.SortOrder = Enum.SortOrder.LayoutOrder
	cList.Parent = content

	local sep = Instance.new("Frame")
	sep.BorderSizePixel = 0
	if ctx.Theme and type(ctx.Theme.Get) == "function" then
		sep.BackgroundColor3 = ctx.Theme:Get("Border")
	else
		sep.BackgroundColor3 = Color3.fromRGB(34, 32, 41)
	end
	sep.Size = UDim2.new(1, 0, 0, consts.SEP_H)
	sep.LayoutOrder = 0
	sep.Parent = content

	local rows = {}
	for i, itemDef in ipairs(def.Items) do
		local item = {}
		for k, v in pairs(itemDef) do
			item[k] = v
		end
		item.order = i
		local row = rowFactory.Create(item, content, ctx)
		if row and row.Instance then
			row.Instance.LayoutOrder = i
		end
		rows[i] = row
	end

	local collapsed = false
	local collapseConn = colBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		colBtn.Text = collapsed and "+" or "-"
		if collapsed then
			content.Size = UDim2.new(1, 0, 0, 0)
			slot.Size = UDim2.new(0, consts.COL_W, 0, consts.HDR_H)
		else
			content.Size = UDim2.new(1, 0, 0, expandedContentH)
			slot.Size = UDim2.new(0, consts.COL_W, 0, expandedTotalH)
		end
	end)

	local themeUnsub
	if ctx.Theme and type(ctx.Theme.Subscribe) == "function" then
		themeUnsub = ctx.Theme:Subscribe(function()
			hdr.BackgroundColor3 = ctx.Theme:Get("Accent")
			content.BackgroundColor3 = ctx.Theme:Get("Surface")
			sep.BackgroundColor3 = ctx.Theme:Get("Border")
		end)
	end

	local self = setmetatable({
		Def = def,
		Slot = slot,
		Container = container,
		Wrap = wrap,
		Header = hdr,
		Content = content,
		Rows = rows,
		_collapsed = function()
			return collapsed
		end,
		_conns = { collapseConn },
		_themeUnsub = themeUnsub,
		_destroyed = false,
	}, Category)
	return self
end

-- Reports the collapse state.
function Category:IsCollapsed()
	return self._collapsed()
end

-- Finds a row handle by its definition key.
function Category:GetRow(key)
	for _, row in ipairs(self.Rows) do
		if row and row.Key == key then
			return row
		end
	end
	return nil
end

-- Re-reads localized labels on every row.
function Category:RefreshText()
	for _, row in ipairs(self.Rows) do
		if row and type(row.RefreshText) == "function" then
			pcall(function() row:RefreshText() end)
		end
	end
end

-- Disconnects, destroys rows and removes the column frames.
function Category:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for _, c in ipairs(self._conns) do
		pcall(function() c:Disconnect() end)
	end
	if self._themeUnsub then
		pcall(self._themeUnsub)
	end
	for _, row in ipairs(self.Rows) do
		if row and type(row.Destroy) == "function" then
			pcall(function() row:Destroy() end)
		end
	end
	pcall(function() self.Slot:Destroy() end)
end

return Category
