local R = require('libs/lamda')
local inspect = require('libs/inspect')

local isNil, isNumber, isString = R.isNil, R.isNumber, R.isString
local anyPass, unless, isBoolean = R.anyPass, R.unless, R.isBoolean

local isPrintable = anyPass(isNil, isNumber, isString, isBoolean)

return function(...)
	local args = map(unless(isPrintable, inspect), {...})

	print(unpack(args))
end
