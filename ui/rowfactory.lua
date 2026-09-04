--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - RowFactory

 Responsible for building one menu row from a declarative item
 definition using exactly three components: Button, Input and
 Dropdown. Supported types: toggle, search, dropdown, button.
 BeatX maps Feature Search to Input and Language plus Theme
 to Dropdown; toggle and button stay for future categories.
 Runs inside Category.new with a ctx carrying Components plus
 Theme, Localization and menu callbacks.
]]

local RowFactory = {}

local SUPPORTED = {
	toggle = true,
	search = true,
	dropdown = true,
	button = true,
}

-- Reports whether a row type can be built.
function RowFactory.IsSupported(rowType)
	return SUPPORTED[rowType] == true
end

-- Builds one row frame from an item definition.
function RowFactory.Create(itemDef, parent, ctx)
	assert(type(itemDef) == "table" and type(itemDef.type) == "string", "Invalid itemDef")
	assert(SUPPORTED[itemDef.type], "Unsupported row type: " .. tostring(itemDef.type))
	ctx = ctx or {}
	local comps = ctx.Components or {}

	local rowType = itemDef.type
	local key = itemDef.key or itemDef.type

	if rowType == "toggle" then
		assert(comps.Button, "Button component missing")
		local handle = comps.Button.Create(parent, {
			Label = itemDef.text,
			LabelKey = itemDef.labelKey,
			Active = itemDef.default == true,
			OnClick = function(state)
				if type(itemDef.onChanged) == "function" then
					itemDef.onChanged(state)
				end
			end,
			Size = UDim2.new(1, 0, 0, 22),
		}, ctx)
		handle.Instance.LayoutOrder = itemDef.order or 1
		return {
			Key = key,
			Type = rowType,
			Instance = handle.Instance,
			Get = handle.GetActive,
			Set = handle.SetActive,
			Destroy = handle.Destroy,
		}
	end

	if rowType == "search" then
		assert(comps.Input, "Input component missing")
		local handle = comps.Input.Create(parent, {
			Placeholder = itemDef.placeholder,
			PlaceholderKey = itemDef.placeholderKey,
			OnChanged = ctx.OnSearchQuery or itemDef.onQuery,
			OnEnter = ctx.OnSearchEnter or itemDef.onEnter,
		}, ctx)
		handle.Instance.LayoutOrder = itemDef.order or 1
		return {
			Key = key,
			Type = rowType,
			Instance = handle.Instance,
			Clear = handle.Clear,
			Focus = handle.Focus,
			Destroy = handle.Destroy,
		}
	end

	if rowType == "dropdown" then
		assert(comps.Dropdown, "Dropdown component missing")
		local initial = itemDef.value
		if initial == nil then
			initial = itemDef.default
		end
		local handle = comps.Dropdown.Create(parent, {
			Label = itemDef.label,
			LabelKey = itemDef.labelKey or key,
			Options = itemDef.options or {},
			Selected = initial,
			OnSelect = itemDef.onSelect or ctx.OnLanguageSelect,
		}, ctx)
		handle.Instance.LayoutOrder = itemDef.order or 2
		return {
			Key = key,
			Type = rowType,
			Instance = handle.Instance,
			Get = handle.Get,
			Set = handle.Set,
			SetValue = handle.Set,
			RefreshText = handle.RefreshText,
			Close = handle.Close,
			Destroy = handle.Destroy,
		}
	end

	assert(comps.Button, "Button component missing")
	local initial = itemDef.value
	if initial == nil then
		initial = itemDef.default
	end
	local handle = comps.Button.Create(parent, {
		Label = itemDef.label,
		LabelKey = itemDef.labelKey or key,
		Value = initial,
		OnClick = function()
			if type(ctx.OnBeatXAction) == "function" then
				ctx.OnBeatXAction(key)
			elseif type(itemDef.onClick) == "function" then
				itemDef.onClick()
			end
		end,
	}, ctx)
	handle.Instance.LayoutOrder = itemDef.order or 3
	return {
		Key = key,
		Type = rowType,
		Instance = handle.Instance,
		SetValue = handle.SetValue,
		RefreshText = handle.RefreshText,
		Destroy = handle.Destroy,
	}
end

return RowFactory
