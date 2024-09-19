local F = require('utils.functional')

local M = {}

local curry = F.curry
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

M.join = curry(function(sep, xs) -- todo: reduce
	local length = #xs
	if length == 0 then
		return ''
	end
	local acc = '' .. xs[1]
	for i = 2, #xs do
		acc = acc .. sep .. xs[i]
	end
	return acc
end)

M.joinLines = M.join('\n')

M.capitalize = function(x)
	return x:sub(1, 1):upper() .. x:sub(2)
end

return M
