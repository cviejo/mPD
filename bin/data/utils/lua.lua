local M = {}

M.version = _VERSION

M.jitVersion = ""
if type(jit) == 'table' then M.jitVersion = jit.version end

return M
