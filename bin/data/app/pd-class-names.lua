local M = {}
local F = require('utils.functional')

local includes, push = F.includes, F.push

local asc = function(a, b)
	return a < b
end

M.items = {}

M.add = function(name)
	if not includes(name, M.items) then
		push(name, M.items)
		M.items = F.sort(asc, M.items)
		-- log('classes\n\n', M.items)
	end
end

return M
