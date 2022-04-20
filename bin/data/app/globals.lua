---@diagnostic disable: lowercase-global
local R = require('libs/lamda')
local L = require('libs/fun')
local logging = require('utils.logging')
local inspect = require('libs.inspect')

if _G.mpd then
	_G.dpi = mpd.getDPI()
else
	_G.dpi = 1
end

_G.Target = 'desktop'

_G.inspect = inspect
_G.logging = logging
_G.log = logging.verbose
_G.console = {log = log}
_G.red = logging.colour(31)
_G.green = logging.colour(32)
_G.blue = logging.colour(34)
_G.noop = function()
end

_G.time = function()
	return os.clock() * 1000
end

_G.TODO = function(msg)
	print(red('TODO'), msg)
end

TODO('remove lamda?')
TODO('selected lines mesh')
TODO('big grid')
TODO('events/bind for externals')
TODO("buttons don't change on press (except toggles), render them an image/vbo")
TODO('the whole lastTouch,dragging = loc thing and scaleBegin when edimode = 1')
TODO('render text to image/texture?')
TODO('overwrite object outline when selected (blue)')

_G.forEach = L.each
_G.each = L.each

_G.jit = jit
_G.mpd = mpd
_G.audio = audio
_G.of = of
_G.glm = glm
_G.swig_type = swig_type

-- adding explictly to the global table works better with the linter
-- than then dynamic approach below
_G.R = R
_G.T = R.T
_G.any = R.any
_G.always = R.always
_G.both = R.both
_G.clamp = R.clamp
_G.cond = R.cond
_G.contains = R.contains
_G.curry2 = R.curry2
_G.draw = R.draw
_G.either = R.either
_G.equals = R.equals
_G.filter = R.filter
_G.find = R.find
_G.identity = R.identity
_G.includes = R.includes
_G.isString = R.isString
_G.join = R.join
_G.keys = R.keys
_G.map = R.map
_G.pick = R.pick
_G.pipe = R.pipe
_G.prop = R.prop
_G.propEq = R.propEq
_G.reject = R.reject
_G.setup = R.setup
_G.split = R.split
_G.splitEvery = R.splitEvery
_G.tap = R.tap
_G.times = R.times
_G.touchMoved = R.touchMoved
_G.unary = R.unary
_G.unapply = R.unapply
_G.values = R.values
_G.when = R.when
_G.tryCatch = R.tryCatch
