local M = {}

-- local safe = unless(isNil)
M.safe = function(fn)
	return function(x)
		if x == nil then
			return x
		else
			return fn(x)
		end
	end
end

-- lamda's curry can't return multiple values
M.curry2 = function(fn)
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

M.firstOf = function(...)
	local fns = {...}
	return function(x)
		for _, fn in ipairs(fns) do
			local result = fn(x)
			if result then return result end
		end
	end
end

M.intersects = M.curry2(function(a, b)
	return any(function(x)
		return includes(x, a)
	end, b)
end)

M.hasTag = function(tag)
	return function(x)
		return (x.tags and includes(tag, x.tags))
	end
end

M.findByTag = function(tag, xs)
	return find(M.hasTag(tag), xs)
end

M.filterByTag = function(tag, xs)
	return filter(M.hasTag(tag), xs)
end

return M
