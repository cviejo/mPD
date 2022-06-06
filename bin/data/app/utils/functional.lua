local M = {}

local curry2 = function(fn)
	local delayedA = nil
	local delayedFn = function(b)
		return fn(delayedA, b)
	end
	return function(a, b)
		if b ~= nil then
			return fn(a, b)
		else
			delayedA = a
			return delayedFn
		end
	end
end

_G.t = function(...)
	print(...)
end

local curry3 = function(fn)
	local delayedA = nil
	local delayedFn = curry2(function(b, c)
		return fn(delayedA, b, c)
	end)
	return function(a, b, c)
		if c ~= nil then
			return fn(a, b, c)
		else
			delayedA = a
			if b then
				return delayedFn(b)
			else
				return delayedFn
			end
		end
	end
end

-- probably not needed
M.tern = function(cond, a, b)
	if cond then
		return a
	end
	return b
end

-- not is a lua keyword
M.negate = function(x)
	return not x
end

M.unapply = function(fn)
	return function(...)
		return fn({...})
	end
end

M.curry = function(fn)
	local nparams = debug.getinfo(fn).nparams

	if nparams == 2 then
		return curry2(fn)
	else
		return curry3(fn)
	end
end

M.equals = curry2(function(a, b)
	return a == b
end)

M.isNil = function(x)
	return x == nil
end

M.unless = M.curry(function(cond, success, x)
	if (not cond(x)) then
		return success(x)
	end
	return x
end)

M.safe = function(fn)
	return function(x)
		if x == nil then
			return x
		else
			return fn(x)
		end
	end
end

M.includes = M.curry(function(x, xs)
	for i = 1, #xs do
		if xs[i] == x then
			return true
		end
	end
	return false
end)

M.intersects = function(a, b)
	for ia = 1, #a do
		for ib = 1, #b do
			if a[ia] == b[ib] then
				return true
			end
		end
	end

	return false
end

M.prop = M.curry(function(name, x)
	if x then
		return x[name]
	end
end)

M.map = M.curry(function(fn, xs)
	local result = {}
	for i = 1, #xs do
		result[#result + 1] = fn(xs[i], i)
	end
	return result
end)

M.forEach = M.curry(function(fn, xs)
	for i = 1, #xs do
		fn(xs[i], i)
	end
end)

M.each = forEach

M.reduce = function(fn, init, xs)
	local acc = init
	for i = 1, #xs do
		acc = fn(acc, xs[i])
	end
	return acc
end

M.join = M.curry(function(sep, xs) -- todo: reduce
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

-- avoid inlining / creating functions dynamically in potentially hot paths
-- in this case means declaring the reducer only once
M.pipe = function(...)
	local fns = {...}
	local reducer = function(acc, fn)
		return fn(acc)
	end
	return function(x)
		return M.reduce(reducer, x, fns)
	end
end

M.noop = function()
end

M.tryCatch = M.curry(function(tryer, catcher)
	print 'tryCatch is expensive, remove for production'

	return function(x)
		local error
		local success, result = xpcall(function()
			return tryer(x)
		end, function(err)
			error = err
		end)
		if not success then
			result = catcher(error, x)
		end
		return result
	end
end)

M.clamp = M.curry(function(min, max, x)
	if x > max then
		return max
	elseif x < min then
		return min
	else
		return x
	end
end)

M.pick = curry2(function(fields, obj)
	local result = {}
	M.forEach(function(field)
		local value = obj[field]
		if (value) then
			result[field] = value
		end
	end, fields)
	return result
end)

M.keys = function(x)
	local result = {}
	for key, _ in pairs(x) do
		result[#result + 1] = key
	end
	return result
end

-- not pure, but for convenience let's keep them here
M.assign = curry2(function(target, source)
	for key, value in pairs(source) do
		target[key] = value
	end
end)

M.push = function(x, xs)
	xs[#xs + 1] = x
end
-- not pure, but for convenience let's keep them here

M.merge = curry2(function(a, b)
	local result = {}
	M.assign(result, a)
	M.assign(result, b)
	return result
end)

M.complement = function(fn)
	return function(...)
		return not fn(...)
	end
end

return M
