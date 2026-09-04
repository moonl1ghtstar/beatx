--[[
  /$$$$$$$                        /$$     /$$   /$$
 | $$__  $$                      | $$    | $$  / $$
 | $$  \ $$  /$$$$$$   /$$$$$$  /$$$$$$  |  $$/ $$/
 | $$$$$$$  /$$__  $$ |____  $$|_  $$_/   \  $$$$/
 | $$__  $$ | $$$$$$$$  /$$$$$$$  | $$      >$$  $$
 | $$  \ $$| $$_____/ /$$__  $$  | $$ /$$ /$$/\  $$
 | $$$$$$$/|  $$$$$$$|  $$$$$$$  |  $$$$/| $$  \ $$
 |_______/  \_______/ \_______/   \___/  |__/  |__/

 BeatX - Filesystem Adapter

 Responsible for sole access to executor filesystem APIs.
 Wraps isfile/readfile/writefile in pcall guards and exposes
 JSON helpers backed by HttpService.
 Loaded by Main.Start before SettingsStore; UI modules never
 touch filesystem APIs directly.
]]

local Filesystem = {}
Filesystem.__index = Filesystem

-- Resolves HttpService without throwing when unavailable.
local function getHttpService()
	local ok, service = pcall(function()
		return game:GetService("HttpService")
	end)
	if ok then
		return service
	end
	return nil
end

-- Reports whether persistent file APIs exist in this executor.
function Filesystem.isSupported()
	return type(readfile) == "function"
		and type(writefile) == "function"
		and type(isfile) == "function"
end

-- Checks file existence. Returns false when the API is missing.
function Filesystem.exists(path)
	if type(isfile) ~= "function" then
		return false
	end
	local ok, result = pcall(isfile, path)
	return ok and result == true
end

-- Reads raw text. Returns nil on missing API or failure.
function Filesystem.read(path)
	if type(readfile) ~= "function" then
		return nil
	end
	local ok, result = pcall(readfile, path)
	if ok and type(result) == "string" then
		return result
	end
	return nil
end

-- Writes raw text. Single-file configs need no folder creation.
function Filesystem.write(path, content)
	if type(writefile) ~= "function" then
		return false
	end
	local ok = pcall(writefile, path, content)
	return ok
end

-- Reads and decodes a JSON file into a table. Nil on any failure.
function Filesystem.readJson(path)
	local raw = Filesystem.read(path)
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local http = getHttpService()
	if not http then
		return nil
	end
	local ok, decoded = pcall(function()
		return http:JSONDecode(raw)
	end)
	if ok and type(decoded) == "table" then
		return decoded
	end
	return nil
end

-- Encodes a table as JSON and writes it. False on any failure.
function Filesystem.writeJson(path, value)
	local http = getHttpService()
	if not http then
		return false
	end
	local ok, encoded = pcall(function()
		return http:JSONEncode(value)
	end)
	if not ok or type(encoded) ~= "string" then
		return false
	end
	return Filesystem.write(path, encoded)
end

return Filesystem
