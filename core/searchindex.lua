--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - SearchIndex

 Responsible for searching registered feature metadata without
 hardcoding feature names. Matches case-insensitively against
 Name, Keywords, Description and Category.
 Created by Main.Start after FeatureManager registration;
 the Input row queries it on every keystroke and on Enter.
]]

local SearchIndex = {}
SearchIndex.__index = SearchIndex

-- Builds an index over the given feature manager.
function SearchIndex.new(featureManager)
	return setmetatable({
		_featureManager = featureManager,
	}, SearchIndex)
end

-- Coerces a metadata field to string for safe matching.
local function asString(v)
	if type(v) == "string" then
		return v
	end
	return ""
end

-- Collects one sorted entry per registered feature.
function SearchIndex:Collect()
	local out = {}
	local fm = self._featureManager
	if not fm or type(fm.Features) ~= "table" then
		return out
	end
	for name, feature in pairs(fm.Features) do
		if type(feature) == "table" then
			local entry = {
				Name = asString(feature.Name ~= nil and feature.Name or name),
				Category = asString(feature.Category or name),
				Description = asString(feature.Description),
				Keywords = {},
			}
			if type(feature.Keywords) == "table" then
				for _, kw in ipairs(feature.Keywords) do
					if type(kw) == "string" and kw ~= "" then
						table.insert(entry.Keywords, kw)
					end
				end
			end
			entry._feature = feature
			table.insert(out, entry)
		end
	end
	table.sort(out, function(a, b)
		return a.Name < b.Name
	end)
	return out
end

-- Tests one entry against a lowercased needle.
local function matches(entry, needle)
	if needle == "" then
		return false
	end
	local function hit(haystack)
		return string.find(string.lower(haystack), needle, 1, true) ~= nil
	end
	if hit(entry.Name) then
		return true
	end
	if entry.Description ~= "" and hit(entry.Description) then
		return true
	end
	for _, kw in ipairs(entry.Keywords) do
		if hit(kw) then
			return true
		end
	end
	if entry.Category ~= "" and hit(entry.Category) then
		return true
	end
	return false
end

-- Returns entries matching the query. Empty query yields no results.
function SearchIndex:Search(query)
	local q = string.lower(asString(query):gsub("^%s+", ""):gsub("%s+$", ""))
	if q == "" then
		return {}
	end
	local results = {}
	for _, entry in ipairs(self:Collect()) do
		if matches(entry, q) then
			table.insert(results, entry)
		end
	end
	return results
end

return SearchIndex
