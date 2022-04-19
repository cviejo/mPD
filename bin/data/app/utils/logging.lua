local R = require('libs/lamda')
local inspect = require('libs/inspect')

local isPrintable = R.anyPass(R.isNil, R.isNumber, R.isString, R.isBoolean)

local toPrintable = R.map(R.unless(isPrintable, inspect))

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

		of.log(logLevel, R.join('\t', args))
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
