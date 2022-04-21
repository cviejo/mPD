local inspect = require('libs.inspect')
local F = require('utils.functional')

local map, unless, join = F.map, F.unless, F.join

local isPrintable = function(x)
	local t = type(x)
	return t == 'nil' or t == 'number' or t == 'string' or t == 'boolean'
end

local toPrintable = map(unless(isPrintable, inspect))

local of = _G.of or {
	LOG_VERBOSE = '[verbose]',
	LOG_NOTICE = '[notice]',
	LOG_WARN = '[warn]',
	LOG_ERROR = '[error]',
	log = print
}

local function colour(code)
	return function(x)
		local value = x
		if type(x) ~= "string" then
			value = inspect(x)
		end
		return "\027[" .. code .. "m" .. value .. "\027[0m"
	end
end

local log = function(logLevel)
	return function(...)
		local args = toPrintable({...})

		of.log(logLevel, join('\t', args))
	end
end

return {
	colour = colour,
	verbose = log(of.LOG_VERBOSE),
	notice = log(of.LOG_NOTICE),
	warn = log(of.LOG_WARNING),
	error = log(of.LOG_ERROR)
}
-- LOG_FATAL_ERROR,
-- LOG_SILENT
