--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Component: Button

 Responsible for the generalized menu row extracted from the
 legacy category "Test" row. Preserves its look (dark row,
 gradient wash when active, right accent bar) and toggle feel.
 Shows a left label with an optional right value, so one module
 serves plain clicks, value settings and toggle-style features.
 Runs under RowFactory or legacy columns; destroyed with its row.
]]

local Button = {}

-- Builds a row button. Active=nil means plain click without toggle state.
function Button.Create(parent, props, ctx)
	props = props or {}
	local theme = ctx and ctx.Theme or nil
	local localization = ctx and ctx.Localization or nil

	local labelKey = props.LabelKey
	local labelText = props.Label or props.Text or ""
	if labelKey and localization and type(localization.Get) == "function" then
		labelText = localization:Get(labelKey)
	end

	local hasToggle = props.Active ~= nil
	local active = props.Active == true
	local hov = false

	local function accent()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Accent")
		end
		return Color3.fromRGB(232, 56, 102)
	end
	local function fg()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Text")
		end
		return Color3.fromRGB(255, 255, 255)
	end

	local row = Instance.new("TextButton")
	row.AutoButtonColor = false
	row.BorderSizePixel = 0
	row.Size = props.Size or UDim2.new(1, 0, 0, 22)
	row.Text = ""
	row.BackgroundColor3 = Color3.new(0, 0, 0)
	row.Parent = parent

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
		ColorSequenceKeypoint.new(1, accent()),
	})
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0.5),
	})
	grad.Rotation = 0
	grad.Enabled = active
	grad.Parent = row

	local hasValue = props.Value ~= nil
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.BorderSizePixel = 0
	lbl.Font = Enum.Font.Gotham
	lbl.Text = labelText
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.TextColor3 = fg()
	if hasValue then
		lbl.Size = UDim2.new(0.55, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(8, 0)
	else
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(8, 0)
	end
	lbl.Parent = row

	local valLbl = nil
	if hasValue then
		valLbl = Instance.new("TextLabel")
		valLbl.BackgroundTransparency = 1
		valLbl.BorderSizePixel = 0
		valLbl.Font = Enum.Font.GothamMedium
		valLbl.Text = tostring(props.Value)
		valLbl.TextSize = 14
		valLbl.TextXAlignment = Enum.TextXAlignment.Right
		valLbl.TextYAlignment = Enum.TextYAlignment.Center
		valLbl.TextColor3 = fg()
		valLbl.Size = UDim2.new(0.45, -12, 1, 0)
		valLbl.Position = UDim2.new(0.55, 0, 0, 0)
		valLbl.Parent = row
	end

	local bar = Instance.new("Frame")
	bar.Name = "AccentBar"
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = active and accent() or Color3.fromRGB(110, 110, 110)
	bar.Size = UDim2.new(0, 2, 1, -4)
	bar.Position = UDim2.new(1, -2, 0.5, 0)
	bar.AnchorPoint = Vector2.new(1, 0.5)
	bar.Parent = row

	local function paint()
		if active then
			row.BackgroundColor3 = Color3.new(1, 1, 1)
			grad.Enabled = true
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
				ColorSequenceKeypoint.new(1, accent()),
			})
			lbl.TextColor3 = accent()
			if valLbl then
				valLbl.TextColor3 = accent()
			end
			bar.BackgroundColor3 = accent()
		else
			row.BackgroundColor3 = hov and Color3.fromRGB(15, 15, 15) or Color3.new(0, 0, 0)
			grad.Enabled = false
			lbl.TextColor3 = fg()
			if valLbl then
				valLbl.TextColor3 = fg()
			end
			bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
		end
	end

	local conns = {}
	table.insert(conns, row.MouseButton1Click:Connect(function()
		if hasToggle then
			active = not active
			paint()
		end
		if type(props.OnClick) == "function" then
			if hasToggle then
				props.OnClick(active)
			else
				props.OnClick()
			end
		end
	end))
	table.insert(conns, row.MouseEnter:Connect(function()
		hov = true
		if hasToggle and not active then
			paint()
		elseif not hasToggle then
			row.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
			if valLbl then
				valLbl.TextColor3 = accent()
			end
		end
	end))
	table.insert(conns, row.MouseLeave:Connect(function()
		hov = false
		if hasToggle and not active then
			paint()
		elseif not hasToggle then
			row.BackgroundColor3 = Color3.new(0, 0, 0)
			if valLbl then
				valLbl.TextColor3 = fg()
			end
		end
	end))

	local unsubs = {}
	if theme and type(theme.Subscribe) == "function" then
		table.insert(unsubs, theme:Subscribe(paint))
	end
	if labelKey and localization and type(localization.Subscribe) == "function" then
		table.insert(unsubs, localization:Subscribe(function()
			lbl.Text = localization:Get(labelKey)
		end))
	end
	paint()

	return {
		Instance = row,
		Label = lbl,
		ValueLabel = valLbl,
		AccentBar = bar,
		GetActive = function()
			return active
		end,
		SetActive = function(_, v)
			active = v == true
			paint()
		end,
		SetValue = function(_, v)
			if valLbl then
				valLbl.Text = tostring(v)
			end
		end,
		SetLabel = function(_, text)
			lbl.Text = tostring(text)
		end,
		RefreshText = function()
			if labelKey and localization and type(localization.Get) == "function" then
				lbl.Text = localization:Get(labelKey)
			end
		end,
		Destroy = function()
			for _, c in ipairs(conns) do
				pcall(function() c:Disconnect() end)
			end
			for _, u in ipairs(unsubs) do
				pcall(u)
			end
			row:Destroy()
		end,
	}
end

return Button
