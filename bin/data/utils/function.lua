-- local safe = unless(isNil)
local safe = function(fn)
	return function(x)
		if x == nil then
			return x
		else
			return fn(x)
		end
	end
end

-- lamda's curry can't return multiple values
local curry2 = function(fn)
	return function(a, b1)
		if b1 ~= nil then
			return fn(b1, a)
		else
			return function(b2)
				return fn(b2, a)
			end
		end
	end
end

return {safe = safe, curry2 = curry2}
