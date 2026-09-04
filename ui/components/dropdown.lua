--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Component: Dropdown

 Responsible for settings picked from multiple values, starting
 with Language Settings and Theme. Closed state matches the menu
 row look with label and current value and no accent bar.
 Opening renders an option-only overlay panel immediately right
 of its own row, top-aligned, inside ctx.OverlayParent, so it never appears
 at an arbitrary screen position and Canvas autosize is unaffected.
 Outside click closes without choosing. Generic enough for
 future categories. Destroyed with its parent row.
]]

local Dropdown = {}

-- Builds a dropdown row bound to an option list.
function Dropdown.Create(parent, props, ctx)
	props = props or {}
	local theme = ctx and ctx.Theme or nil
	local localization = ctx and ctx.Localization or nil
	local overlayParent = ctx and ctx.OverlayParent or nil

	local options = props.Options or {}
	local selected = props.Selected
	if selected == nil then
		selected = options[1]
	end

	local labelKey = props.LabelKey
	local labelText = props.Label or ""
	if labelKey and localization and type(localization.Get) == "function" then
		labelText = localization:Get(labelKey)
	end

	local function fg()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Text")
		end
		return Color3.fromRGB(255, 255, 255)
	end
	local function accent()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Accent")
		end
		return Color3.fromRGB(232, 56, 102)
	end
	local function surface()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Surface")
		end
		return Color3.fromRGB(22, 21, 27)
	end
	local function border()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Border")
		end
		return Color3.fromRGB(34, 32, 41)
	end

	local destroyed = false
	local opened = false
	local popupConns = {}
	local popupObjs = {}

	local root = Instance.new("TextButton")
	root.AutoButtonColor = false
	root.BackgroundColor3 = Color3.new(0, 0, 0)
	root.BorderSizePixel = 0
	root.Text = ""
	root.Size = props.Size or UDim2.new(1, 0, 0, 22)
	root.Parent = parent

	local left = Instance.new("TextLabel")
	left.BackgroundTransparency = 1
	left.BorderSizePixel = 0
	left.Font = Enum.Font.Gotham
	left.Text = labelText
	left.TextSize = 14
	left.TextXAlignment = Enum.TextXAlignment.Left
	left.TextYAlignment = Enum.TextYAlignment.Center
	left.TextColor3 = fg()
	left.Size = UDim2.new(0.55, -8, 1, 0)
	left.Position = UDim2.fromOffset(8, 0)
	left.Parent = root

	local right = Instance.new("TextLabel")
	right.BackgroundTransparency = 1
	right.BorderSizePixel = 0
	right.Font = Enum.Font.GothamMedium
	right.Text = tostring(selected or "")
	right.TextSize = 14
	right.TextXAlignment = Enum.TextXAlignment.Right
	right.TextYAlignment = Enum.TextYAlignment.Center
	right.TextColor3 = fg()
	right.Size = UDim2.new(0.45, -8, 1, 0)
	right.Position = UDim2.new(0.55, 0, 0, 0)
	right.Parent = root

	local handle = {}

	-- Destroys overlay objects and disconnects popup listeners.
	local function closePopup(cancelled)
		for _, c in ipairs(popupConns) do
			pcall(function() c:Disconnect() end)
		end
		popupConns = {}
		for _, o in ipairs(popupObjs) do
			pcall(function() o:Destroy() end)
		end
		popupObjs = {}
		if not opened then
			return
		end
		opened = false
		if ctx and ctx.ActiveDropdown == handle then
			ctx.ActiveDropdown = nil
		end
		if cancelled and type(props.OnCancel) == "function" then
			props.OnCancel()
		end
	end

	-- Opens the option list immediately right of the row, top-aligned.
	local function openPopup()
		if opened or destroyed then
			return
		end
		local layer = overlayParent
		if not layer then
			return
		end
		opened = true
		if ctx then
			local current = ctx.ActiveDropdown
			if current and current ~= handle and type(current.Close) == "function" then
				pcall(function()
					current:Close()
				end)
			end
			ctx.ActiveDropdown = handle
		end

	-- Anchor to the clicked row: panel X = row X + row width,
	-- panel Y = row Y. Read at click time so menu moves stay correct.
	-- Y is converted through the menu Canvas, a GuiObject sharing the
	-- row's own coordinate space: canvas offset plus the row position
	-- relative to the canvas. X keeps its verified behavior.
	local anchorX, anchorY = nil, nil
	pcall(function()
		local parentPos = layer.AbsolutePosition
		anchorX = root.AbsolutePosition.X + root.AbsoluteSize.X - parentPos.X
		local canvas = ctx and ctx.Canvas or nil
		if canvas
			and type(canvas.AbsolutePosition) == "Vector2"
			and type(canvas.Position) == "UDim2" then
			anchorY = canvas.Position.Y.Offset
				+ (root.AbsolutePosition.Y - canvas.AbsolutePosition.Y)
		else
			anchorY = root.AbsolutePosition.Y - parentPos.Y
		end
	end)

		local blocker = Instance.new("TextButton")
		blocker.Name = "BeatXDropdownBlocker"
		blocker.AutoButtonColor = false
		blocker.BackgroundTransparency = 1
		blocker.Text = ""
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.ZIndex = 900
		blocker.Parent = layer
		table.insert(popupObjs, blocker)

		local panel = Instance.new("Frame")
		panel.Name = "BeatXDropdownPanel"
		panel.BorderSizePixel = 1
		panel.BorderColor3 = border()
		panel.BackgroundColor3 = surface()
		if type(anchorX) == "number" then
			panel.Position = UDim2.fromOffset(anchorX, anchorY)
			panel.Size = UDim2.fromOffset(140, #options * 22)
		elseif type(props.Position) == "UDim2" then
			panel.Position = props.Position
			panel.Size = UDim2.fromOffset(140, #options * 22)
		else
			panel.AnchorPoint = Vector2.new(0.5, 0)
			panel.Position = UDim2.fromScale(0.5, 0.2)
			panel.Size = UDim2.fromOffset(140, #options * 22)
		end
		panel.ZIndex = 901
		panel.Parent = layer
		table.insert(popupObjs, panel)

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Padding = UDim.new(0, 0)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = panel

		for i, opt in ipairs(options) do
			local item = Instance.new("TextButton")
			item.AutoButtonColor = false
			item.BackgroundTransparency = 1
			item.BorderSizePixel = 0
			item.Font = Enum.Font.Gotham
			item.TextSize = 14
			item.Text = tostring(opt)
			item.TextXAlignment = Enum.TextXAlignment.Left
			item.LayoutOrder = i
			item.Size = UDim2.new(1, 0, 0, 22)
			item.ZIndex = 902
			item.TextColor3 = (opt == selected) and accent() or fg()
			item.Parent = panel
			local itemPad = Instance.new("UIPadding")
			itemPad.PaddingLeft = UDim.new(0, 8)
			itemPad.Parent = item
			table.insert(popupConns, item.MouseEnter:Connect(function()
				item.TextColor3 = accent()
			end))
			table.insert(popupConns, item.MouseLeave:Connect(function()
				item.TextColor3 = (opt == selected) and accent() or fg()
			end))
			table.insert(popupConns, item.MouseButton1Click:Connect(function()
				selected = opt
				right.Text = tostring(opt)
				closePopup(false)
				if type(props.OnSelect) == "function" then
					props.OnSelect(opt)
				end
			end))
		end
		table.insert(popupConns, blocker.MouseButton1Click:Connect(function(x, y)
			-- The fullscreen blocker owns this click, so the row beneath
			-- never sees it. Hit-test sibling dropdown rows here: a click
			-- on another dropdown switches to it from the same click
			-- instead of requiring a second click.
			local target = nil
			if ctx and type(ctx.Dropdowns) == "table" then
				if x == nil or y == nil then
					pcall(function()
						local m = game:GetService("UserInputService"):GetMouseLocation()
						x, y = m.X, m.Y
					end)
				end
				if type(x) == "number" and type(y) == "number" then
					for _, d in ipairs(ctx.Dropdowns) do
						if type(d) == "table" and d.Root ~= nil and d.Root ~= root then
							local ok, hit = pcall(function()
								local p = d.Root.AbsolutePosition
								local s = d.Root.AbsoluteSize
								return x >= p.X and x <= p.X + s.X
									and y >= p.Y and y <= p.Y + s.Y
							end)
							if ok and hit then
								target = d
								break
							end
						end
					end
				end
			end
			closePopup(true)
			if target and type(target.OpenFn) == "function" then
				pcall(target.OpenFn)
			end
		end))
	end

	local conns = {}
	table.insert(conns, root.MouseButton1Click:Connect(function()
		if opened then
			closePopup(true)
		else
			openPopup()
		end
	end))
	table.insert(conns, root.MouseEnter:Connect(function()
		root.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		right.TextColor3 = accent()
	end))
	table.insert(conns, root.MouseLeave:Connect(function()
		root.BackgroundColor3 = Color3.new(0, 0, 0)
		right.TextColor3 = fg()
	end))

	local unsubs = {}
	if theme and type(theme.Subscribe) == "function" then
		table.insert(unsubs, theme:Subscribe(function()
			left.TextColor3 = fg()
			right.TextColor3 = fg()
		end))
	end
	if labelKey and localization and type(localization.Subscribe) == "function" then
		table.insert(unsubs, localization:Subscribe(function()
			left.Text = localization:Get(labelKey)
		end))
	end

	handle.Instance = root
	handle.Get = function()
		return selected
	end
	handle.Set = function(_, v)
		selected = v
		right.Text = tostring(v)
	end
	handle.SetValue = handle.Set
	handle.RefreshText = function()
		if labelKey and localization and type(localization.Get) == "function" then
			left.Text = localization:Get(labelKey)
		end
	end
	handle.Close = function()
		closePopup(true)
	end
	handle.IsOpen = function()
		return opened
	end
	handle._registryEntry = { Root = root }
	handle._registryEntry.OpenFn = function()
		if not opened and not destroyed then
			openPopup()
		end
	end
	if ctx then
		ctx.Dropdowns = ctx.Dropdowns or {}
		table.insert(ctx.Dropdowns, handle._registryEntry)
	end
	handle.Destroy = function()
		destroyed = true
		closePopup(false)
		if ctx and type(ctx.Dropdowns) == "table" then
			for i, d in ipairs(ctx.Dropdowns) do
				if d == handle._registryEntry then
					table.remove(ctx.Dropdowns, i)
					break
				end
			end
		end
		if ctx and ctx.ActiveDropdown == handle then
			ctx.ActiveDropdown = nil
		end
		for _, c in ipairs(conns) do
			pcall(function() c:Disconnect() end)
		end
		for _, u in ipairs(unsubs) do
			pcall(u)
		end
		root:Destroy()
	end
	return handle
end

return Dropdown
