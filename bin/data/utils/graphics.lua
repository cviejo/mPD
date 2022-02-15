local M = {}

M.hex = pipe(of.hexToInt, of.Color_fromHex)

M.isGrey = function(color)
	return color.r == color.g and color.g == color.b
end

return M
