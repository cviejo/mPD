local F = require('utils.functional')

local pipe, join, unapply = F.pipe, F.join, F.unapply

local M = {}

local queue = ''

local joinWords = join(' ')

local canvasCommand = function(cmd)
	return function(canvasId)
		return M.queue(canvasId, cmd)
	end
end

M.queue = function(...)
	queue = queue .. ';' .. joinWords({...})
end

M.flush = function()
	if (queue == '') then
		return
	end
	mpd.pdsend(queue)
	queue = ''
end

M.send = pipe(unapply(joinWords), mpd.pdsend)

M.save = canvasCommand('menusave')

M.selectAll = canvasCommand('selectall')

M.delete = function(canvasId)
	M.queue(canvasId, 'key 1 8 0 1 0;', canvasId, 'key 0 8 0 1 0')
end

return M
