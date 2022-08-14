local F = require('utils.functional')

local M = {}

local join, curry = F.join, F.curry
local byte, find, lower = string.byte, string.find, string.lower

M.keyEq = curry(function(char, keyInt)
	return byte(char) == keyInt
end)

M.includes = curry(function(pattern, x)
	return find(lower(x), lower(pattern))
end)

M.head = function(x)
	return x:sub(1, 1)
end

M.tail = function(x)
	return x:sub(2)
end

M.init = function(x)
	return x:sub(1, -2)
end

M.last = function(x)
	return x:sub(-1)
end

M.joinLines = join("\n")

return M
