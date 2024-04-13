local F = require('utils.functional')

local M = {}

local timeouts = {}

M.elapsed = of.getElapsedTimeMillis

M.update = function()
	if #timeouts > 0 then
		F.forEach(function(x)
			if M.elapsed() - x.start > x.timeout then
				x.callback()
				M.clearTimeout(x)
			end
		end, timeouts)
	end
end

M.setTimeout = function(callback, timeout)
	F.push({ callback = callback, timeout = timeout, start = M.elapsed() }, timeouts)
end

M.clearTimeout = function(timeout)
	timeouts = F.reject(function(x)
		return x == timeout
	end, timeouts)
end

return M
