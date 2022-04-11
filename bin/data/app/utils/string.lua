local M = {}

local R = require('../libs/lamda')
local curry2 = require('../utils/function').curry2

local join, split = R.join, R.split

M.keyEq = R.curry2(function(char, keyInt)
	return string.byte(char) == keyInt
end)

M.includes = R.curry2(function(pattern, x)
	return string.find(string.lower(x), string.lower(pattern))
end)

M.gmatch = curry2(string.gmatch)

M.match = curry2(string.match)

M.joinLines = join("\n")

M.splitWords = split(' ')

return M
