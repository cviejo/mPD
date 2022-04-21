local M = {}

-- local R = require('../libs/lamda')
-- local curry2 = require('../utils/function').curry2
-- local curry2 = require('../utils/function').curry2
local F = require('utils.functional')

local join, curry = F.join, F.curry

M.keyEq = curry(function(char, keyInt)
	return string.byte(char) == keyInt
end)

M.includes = curry(function(pattern, x)
	return string.find(string.lower(x), string.lower(pattern))
end)

M.gmatch = curry(string.gmatch)

M.match = curry(string.match)

M.joinLines = join("\n")

return M
