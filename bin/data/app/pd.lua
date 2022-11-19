local F = require('utils.functional')
local joinWords = require('utils.join-words')

local M = {}

local buffer = ''

local canvasCommand = function(cmd)
	return function(canvasId)
		return M.queue(canvasId, cmd)
	end
end

M.queue = function(...)
	buffer = buffer .. ';' .. joinWords({...})
end

M.flush = function()
	if (buffer == '') then
		return
	end
	mpd.pdsend(buffer)
	buffer = ''
end

M.send = F.pipe(F.unapply(joinWords), mpd.pdsend)

M.save = canvasCommand('menusave')

M.selectAll = canvasCommand('selectall')

M.delete = function(canvasId)
	M.queue(canvasId, 'key 1 8 0 1 0;', canvasId, 'key 0 8 0 1 0')
end

return M
