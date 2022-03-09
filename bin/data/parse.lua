local str = require('utils/string')
local fn = require('utils/function')
local safe, firstOf = fn.safe, fn.firstOf

local toNumber = safe(unary(tonumber))

local toPoint = function(tuple)
	return {x = tuple[1], y = tuple[2]}
end

local s = '%s*' -- spaces

local w = '([^%s]*)' -- word

local n = '([-%d%s%.]*)' -- number

local match = pipe(unapply(join(s)), str.match)

local gmatch = pipe(unapply(join(s)), str.gmatch)

local text = match('%-text', s, '{(.-)}')

local width = pipe(match('%-width%s+(%d+)'), toNumber)

-- LuaFormatter off
local parseTags = pipe(
	firstOf(
		match('%-tags%W-list%s*(.-)]'),
		match('%-tags%s*{(.-)}'),
		match('%-tags' .. s .. w)
	),
	when(isString, split(' '))
)

local toHex = cond({
	{equals('black'), always('000000')},
	{equals('blue'), always('0000ff')},
	{T, identity}
})
-- LuaFormatter on

local font = function(line)
	local name, size, style = match('%-font%W*(.-)}%W*(%d+)%s+(%w-)}')(line)
	if not name then
		return nil --
	end
	return {name = name, size = size, style = style}
end

local parseColor = function(param)
	return match('%-' .. param .. '%s*#?(%w*)')
end

local parseNumbers = pipe(split(' '), map(toNumber))

local parsePoints = pipe(parseNumbers, splitEvery(2), map(toPoint))

local fill = pipe(parseColor('fill'), safe(toHex))

local outline = pipe(parseColor('outline'), safe(toHex))

local raiseCord = gmatch(w, '(raise)', 'cord')

local coords = gmatch(w, 'coords', w, n)

local move = gmatch(w, 'move', w, n)

local configure = gmatch(w, 'itemconfigure', w, '(.*)')

local create = gmatch(w, 'create', w, n, '(%-.*)')

local bind = gmatch(w, 'bind', w, w, '.*concat', '(.*)\\;')

local newText = gmatch('pdtk_text_new ', w, '{(.-)}', n, '{(.-)} (.*) (.*)')

local setText = gmatch('pdtk_text_set ', w, s, w, '{(.*)}')

local newCanvas = gmatch('pdtk_canvas_new', w, n, n)

local delete = gmatch(w, 'delete', w)

local scale = gmatch('scale', w, n)

-- incremental parsing would perform better than this, but for now:
-- https://c.tenor.com/5uf-u2UYhxoAAAAC/pig-car.gif
return function(line)
	for canvasId, cmd in raiseCord(line) do
		return {cmd = cmd, canvasId = canvasId} --
	end
	for canvasId, tag in delete(line) do
		return {cmd = 'delete', canvasId = canvasId, tag = tag}
	end
	for canvasId, tag, points in coords(line) do
		return {
			cmd = 'coords',
			canvasId = canvasId,
			tag = tag,
			points = parsePoints(points)
		}
	end
	for canvasId, tag, params in configure(line) do
		return {
			cmd = 'configure',
			canvasId = canvasId,
			tag = tag,
			text = text(params),
			width = width(params),
			fill = fill(params),
			outline = outline(params)
		}
	end
	for canvasId, tag, points in move(line) do
		return {
			cmd = 'move',
			canvasId = canvasId,
			tag = tag,
			points = parsePoints(points)
		}
	end
	for canvasId, shape, points, params in create(line) do
		local parsedPoints = parsePoints(points)
		if (shape == 'line' and #parsedPoints ~= 2) then shape = 'polyline' end
		-- not sure what dash or capstyle do
		return {
			cmd = 'create',
			shape = shape,
			canvasId = canvasId,
			points = parsedPoints,
			fill = fill(params),
			outline = outline(params),
			font = font(line),
			tags = parseTags(params),
			width = width(params),
			text = text(params)
		}
	end
	for canvasId, tags, points, text, _, color in newText(line) do
		return { -- not sure what the _ is (0)
			cmd = "new-text",
			text = text,
			color = color,
			canvasId = canvasId,
			tags = split(' ', tags),
			points = parsePoints(points)
		}
	end
	for canvasId, tag, text in setText(line) do
		return {cmd = 'set-text', canvasId = canvasId, tag = tag, text = text}
	end
	for canvasId, width, height in newCanvas(line) do
		return {
			cmd = 'new-canvas',
			canvasId = canvasId,
			width = width,
			height = height
		}
	end
	for canvasId, tag, action, callback in bind(line) do
		return {
			cmd = 'bind',
			canvasId = canvasId,
			tag = tag,
			action = action,
			callback = callback
		}
	end
	for type, values in scale(line) do
		local parsed = parseNumbers(values)
		return {
			cmd = 'scale',
			type = type,
			value = parsed[1],
			x = parsed[2],
			y = parsed[3]
		}
	end
end
