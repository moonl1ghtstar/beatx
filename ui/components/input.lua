--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Component: Input

 Responsible for the Roblox TextBox search row fixed at ROW_H 22.
 Supports placeholder text, change callbacks, focus and clear.
 Never steals focus on its own, so the existing GetFocusedTextBox
 and RightShift guard in main.lua keeps working. Feature Search
 is its first use. Destroyed with its parent row.
]]

local Input = {}

-- Builds a full-width input row with accent bar.
function Input.Create(parent, props, ctx)
	props = props or {}
	local theme = ctx and ctx.Theme or nil
	local localization = ctx and ctx.Localization or nil

	local placeholderKey = props.PlaceholderKey or "search_placeholder"
	local placeholderText = props.Placeholder
	if placeholderText == nil then
		if localization and type(localization.Get) == "function" then
			placeholderText = localization:Get(placeholderKey)
		else
			placeholderText = "Search..."
		end
	end

	local function accent()
		if theme and type(theme.Get) == "function" then
			return theme:Get("Accent")
		end
		return Color3.fromRGB(232, 56, 102)
	end

	local root = Instance.new("Frame")
	root.BackgroundColor3 = Color3.new(0, 0, 0)
	root.BorderSizePixel = 0
	root.Size = props.Size or UDim2.new(1, 0, 0, 22)
	root.Parent = parent

	local box = Instance.new("TextBox")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.Text = props.Text or ""
	box.PlaceholderText = placeholderText
	box.TextSize = 14
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Center
	box.ClearTextOnFocus = false
	box.Size = UDim2.new(1, -12, 1, 0)
	box.Position = UDim2.fromOffset(8, 0)
	if theme and type(theme.Get) == "function" then
		box.TextColor3 = theme:Get("Text")
		box.PlaceholderColor3 = theme:Get("SecondaryText")
	else
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.PlaceholderColor3 = Color3.fromRGB(150, 145, 165)
	end
	box.Parent = root

	local bar = Instance.new("Frame")
	bar.Name = "AccentBar"
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
	bar.Size = UDim2.new(0, 2, 1, -4)
	bar.Position = UDim2.new(1, -2, 0.5, 0)
	bar.AnchorPoint = Vector2.new(1, 0.5)
	bar.Parent = root

	local conns = {}
	local function paint()
		if box:IsFocused() or box.Text ~= "" then
			bar.BackgroundColor3 = accent()
		else
			bar.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
		end
	end

	table.insert(conns, box:GetPropertyChangedSignal("Text"):Connect(function()
		paint()
		if type(props.OnChanged) == "function" then
			props.OnChanged(box.Text)
		end
	end))
	table.insert(conns, box.Focused:Connect(paint))
	table.insert(conns, box.FocusLost:Connect(function(enterPressed)
		paint()
		if enterPressed and type(props.OnEnter) == "function" then
			props.OnEnter(box.Text)
		end
	end))

	local unsubs = {}
	if theme and type(theme.Subscribe) == "function" then
		table.insert(unsubs, theme:Subscribe(function()
			box.TextColor3 = theme:Get("Text")
			box.PlaceholderColor3 = theme:Get("SecondaryText")
			paint()
		end))
	end
	if localization and type(localization.Subscribe) == "function" then
		table.insert(unsubs, localization:Subscribe(function()
			if box.Text == "" and props.Placeholder == nil then
				box.PlaceholderText = localization:Get(placeholderKey)
			end
		end))
	end

	return {
		Instance = root,
		Input = box,
		GetText = function()
			return box.Text
		end,
		SetText = function(_, text)
			box.Text = tostring(text)
		end,
		Focus = function()
			pcall(function()
				box:CaptureFocus()
			end)
		end,
		Clear = function()
			box.Text = ""
			pcall(function()
				box:ReleaseFocus()
			end)
			paint()
		end,
		Destroy = function()
			for _, c in ipairs(conns) do
				pcall(function() c:Disconnect() end)
			end
			for _, u in ipairs(unsubs) do
				pcall(u)
			end
			root:Destroy()
		end,
	}
end

return Input
