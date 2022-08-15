local F = require('utils.functional')

local M = {}

-- local patch = nil

M.touch = F.noop

M.draw = F.noop

M.message = log

return M
