local point = function(x, y)
	return {x = x, y = y}
end

if jit then
	local ffi = require('ffi')
	ffi.cdef('typedef struct point{ int16_t x, y; } point;')
	point = function(x, y)
		return ffi.new('point', x, y)
	end
end

return point
