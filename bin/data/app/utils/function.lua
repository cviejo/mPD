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

M.includes = function(x, xs)
	for i = 1, #xs do
		if xs[i] == x then
			return true --
		end
	end
	return false
end

M.intersects = function(a, b)
	for ai = 1, #a do
		for bi = 1, #b do
			if a[ai] == b[bi] then
				return true --
			end
		end
	end

	return false
end

M.hasTag = function(tag)
	return function(x)
		return (x.tags and M.includes(tag, x.tags))
	end
end

M.findByTag = function(tag, xs)
	for i = 1, #xs do
		for j = 1, #xs[i].tags do
			if xs[i].tags[j] == tag then
				return xs[i] --
			end
		end
	end
end

M.rejectByTag = function(tag, xs)
	local result = {}
	for i = 1, #xs do
		local found = false
		for j = 1, #xs[i].tags do
			if xs[i].tags[j] == tag then
				found = true --
			end
		end
		if not found then
			result[#result + 1] = xs[i] --
		end
	end
	return result
	-- return filter(M.hasTag(tag), xs)
	-- local result = {}
	-- local fn = M.hasTag(tag)
	-- local y = {}
	-- for _, v in ipairs(xs) do
	-- 	if fn(v) then y[#y + 1] = v end --
	-- end
	-- return y

	-- local fn = M.hasTag(tag)
	-- for _, value in pairs(xs) do
	-- 	if fn(value) then
	-- 		return value --
	-- 	end
	-- end
end

M.filterByTag = function(tag, xs)
	local result = {}
	for i = 1, #xs do
		for j = 1, #xs[i].tags do
			if xs[i].tags[j] == tag then
				result[#result + 1] = xs[i] --
			end
		end
	end
	return result
	-- return filter(M.hasTag(tag), xs)
	-- local result = {}
	-- local fn = M.hasTag(tag)
	-- local y = {}
	-- for _, v in ipairs(xs) do
	-- 	if fn(v) then y[#y + 1] = v end --
	-- end
	-- return y

	-- local fn = M.hasTag(tag)
	-- for _, value in pairs(xs) do
	-- 	if fn(value) then
	-- 		return value --
	-- 	end
	-- end
end

return M
