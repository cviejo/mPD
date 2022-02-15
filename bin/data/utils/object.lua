local M = {}

M.keys = function(t)
	local keys = {}
	for key, _ in pairs(t) do
		print(key)
		table.insert(keys, key)
	end
	return keys
end

return M
