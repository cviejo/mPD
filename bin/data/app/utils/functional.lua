local M = {}

M.noop = function()
end

-- not pretty, but fast. after receiving the first argument
-- performance is similar to non-curried form
M.curry2 = function(fn)
	local function handler(a, b)
		if a == nil then
			return handler
		elseif b ~= nil then
			return fn(a, b)
		else
			local function last(_b)
				if _b ~= nil then
					return fn(a, _b)
				else
					return last
				end
			end
			return last
		end
	end
	return handler
end

-- see curry2 comment
M.curry3 = function(fn)
	local function handler(a, b, c)
		if a == nil then -- no args
			return handler
		elseif b ~= nil and c ~= nil then -- all args
			return fn(a, b, c)
		elseif b == nil then -- one arg
			local function lastTwo(_b, _c)
				if _b ~= nil and _c ~= nil then
					return fn(a, _b, _c)
				elseif _b ~= nil then
					return handler(a, _b)
				else
					return lastTwo
				end
			end
			return lastTwo
		else -- two args
			local function last(_c)
				if _c ~= nil then
					return fn(a, b, _c)
				else
					return last
				end
			end
			return last
		end
	end
	return handler()
end

M.curry = function(fn)
	if debug.getinfo(fn).nparams == 2 then
		return M.curry2(fn)
	else
		return M.curry3(fn)
	end
end

M.add = M.curry2(function(a, b)
	return a + b
end)

-- not pure, but convenient
M.assign = M.curry2(function(target, source)
	for key, value in pairs(source) do
		target[key] = value
	end
end)

M.complement = function(fn)
	return function(...)
		return not fn(...)
	end
end

M.concat = M.curry2(function(a, b)
	local result = {}
	for i = 1, #a do
		result[#result + 1] = a[i]
	end
	for i = 1, #b do
		result[#result + 1] = b[i]
	end
	return result
end)

M.equals = M.curry2(function(a, b)
	return a == b
end)

M.find = M.curry2(function(fn, xs)
	for i = 1, #xs do
		local item = xs[i]
		if fn(item) then
			return item
		end
	end
end)

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

M.isNil = function(x)
	return x == nil
end

M.map = M.curry(function(fn, xs)
	local result = {}
	for i = 1, #xs do
		result[#result + 1] = fn(xs[i], i)
	end
	return result
end)

M.max = M.curry2(function(a, b)
	return a > b and a or b
end)

M.negate = function(x)
	return not x
end

M.safe = function(fn)
	return function(x)
		if x == nil then
			return x
		else
			return fn(x)
		end
	end
end

M.prop = M.curry(function(name, x)
	if x then
		return x[name]
	end
end)

M.forEach = M.curry(function(fn, xs)
	for i = 1, #xs do
		fn(xs[i], i)
	end
end)

M.filter = M.curry(function(fn, xs)
	local result = {}
	for i = 1, #xs do
		local x = xs[i]
		if fn(x) then
			result[#result + 1] = x
		end
	end
	return result
end)

M.forEachReverse = M.curry(function(fn, xs)
	for i = #xs, 1, -1 do
		fn(xs[i], i)
	end
end)

M.each = M.forEach

M.reduce = M.curry3(function(fn, init, xs)
	local acc = init
	for i = 1, #xs do
		acc = fn(acc, xs[i])
	end
	return acc
end)

-- avoid inlining / creating functions dynamically in potentially hot paths
-- in this case means declaring the reducer only once
M.pipe = function(...)
	local fns = { ... }
	local run = M.reduce(function(acc, fn)
		return fn(acc)
	end)
	return function(x)
		return run(x, fns)
	end
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

M.pick = M.curry2(function(fields, obj)
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

-- not pure, but convenient
M.push = function(x, xs)
	xs[#xs + 1] = x
end

M.merge = M.curry2(function(a, b)
	local result = {}
	M.assign(result, a)
	M.assign(result, b)
	return result
end)

M.path = M.curry2(function(parts, x)
	local current = x
	for i = 1, #parts do
		current = current[parts[i]]
		if current == nil then
			return nil
		end
	end
	return current
end)

M.pathEq = M.curry3(function(parts, value, x)
	return M.path(parts, x) == value
end)

M.reject = M.curry(function(fn, xs)
	return M.filter(function(x)
		return not fn(x)
	end, xs)
end)

M.reverse = function(xs)
	local result = {}
	M.forEachReverse(function(x)
		result[#result + 1] = x
	end, xs)
	return result
end

M.times = M.curry2(function(fn, n)
	local result = {}
	for i = 1, n do
		M.push(fn(i), result)
	end
	return result
end)

M.thunkify = function(fn)
	return function(...)
		local args = { ... }
		return function()
			return fn(unpack(args))
		end
	end
end

M.toUpper = function(x)
	return x:upper()
end

M.unapply = function(fn)
	return function(...)
		return fn({ ... })
	end
end

M.unless = M.curry(function(cond, success, x)
	if (not cond(x)) then
		return success(x)
	end
	return x
end)

M.values = function(x)
	local result = {}
	for _, value in pairs(x) do
		result[#result + 1] = value
	end
	return result
end

M.sort = M.curry2(function(fn, xs)
	local result = {}
	M.assign(result, xs)
	table.sort(result, fn)
	return result
end)

return M
