-- PD sends a ridiculous amount of messages for every update. We need to be able to both
-- find items by tag quickly and keep the creating order for rendering, classic find and
-- filter methods causing lags. Quick solution here is to keep both a dictionary for
-- quick access and list for rendering.
--
return function()
	local M = {}

	local ordered = {}
	local tagged = {}
	local dirty = false

	M.count = function()
		return #ordered
	end

	M.get = function()
		return ordered
	end

	M.add = function(x)
		ordered[#ordered + 1] = x

		local id = x.id

		if not tagged[id] then
			tagged[id] = {}
		end

		local list = tagged[id];

		list[#list + 1] = x
	end

	M.forEach = function(fn)
		for i = 1, #ordered do
			local item = ordered[i]
			if not item.deletion then
				fn(item)
			end
		end
	end

	M.byTag = function(fn, tag)
		local items = tagged[tag]

		if not items then
			return
		end

		for i = 1, #items do
			fn(items[i])
		end
	end

	M.cleanup = function()
		if not dirty then
			return
		end
		dirty = false
		local tmp = {}
		M.forEach(function(item)
			tmp[#tmp + 1] = item
		end)
		ordered = tmp
	end

	M.delete = function(tag)
		M.byTag(function(item)
			item.deletion = true
		end, tag)
		tagged[tag] = nil
		dirty = true
	end

	return M
end
