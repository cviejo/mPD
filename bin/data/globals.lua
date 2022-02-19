---@diagnostic disable: lowercase-global
local R = require('libs/lamda')

_G.inspect = require('libs/inspect')
_G.log = require('utils/log')
_G.console = {log = log}
_G.noop = function()
end

_G.jit = jit
_G.mpd = mpd
_G.of = of
_G.swig_type = swig_type

-- adding explictly to the global table works better with the linter
-- than then dynamic approach below
_G.T = R.T
_G.always = R.always
_G.cond = R.cond
_G.draw = R.draw
_G.either = R.either
_G.equals = R.equals
_G.filter = R.filter
_G.filter = R.filter
_G.find = R.find
_G.forEach = R.forEach
_G.identity = R.identity
_G.includes = R.includes
_G.isString = R.isString
_G.join = R.join
_G.map = R.map
_G.pipe = R.pipe
_G.propEq = R.propEq
_G.reject = R.reject
_G.setup = R.setup
_G.split = R.split
_G.splitEvery = R.splitEvery
_G.tap = R.tap
_G.times = R.times
_G.touchMoved = R.touchMoved
_G.unary = R.unary
_G.when = R.when

-- local function makeGlobal(x, name)
-- 	if not _G[name] and R.isFunction(x) then _G[name] = x end
-- end
-- R.forEach(makeGlobal, R)

