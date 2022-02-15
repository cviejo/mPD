local s = require('utils/string')
local fn = require('utils/function')
local match, gmatch = s.match, s.gmatch
local safe = fn.safe

local toNumber = unary(tonumber)

local toPoint = function(tuple)
	return {x = tuple[1], y = tuple[2]}
end

local text = match('%-text%s-{(.-)}')

local anchor = match('%-anchor%s+(%w+)')

local width = match('%-width%s+(%d+)')

-- LuaFormatter off
local tags = pipe(
	either(match('%-tags%W-list%s*(.-)]'), match('%-tags%s*(%w*)')),
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

local fill = pipe(parseColor('fill'), safe(toHex))

local outline = pipe(parseColor('outline'), safe(toHex))

local canvas = "(%.%w-%.c)"

local raiseCord = gmatch(canvas .. ' (raise) cord')

local coords = gmatch(canvas .. ' coords ([^%s]-) ([%d%s%.]*)')

local move = gmatch(canvas .. ' move ([^%s]-) ([%d%s%.]*)')

local configure = gmatch(canvas .. ' itemconfigure ([^%s]-) (.*)')

local create = gmatch(canvas .. ' create (%w+) ([%d%s%.]*) (%-.*)')

local setText = gmatch('pdtk_text_set ' .. canvas .. ' ([^%s]-) {(.*)}')

-- LuaFormatter off
local newText = gmatch('pdtk_text_new ' .. canvas .. ' {(.-)} ([%d%s%.]*) {(.-)} (.*) (.*)')

local newCanvas = gmatch('pdtk_canvas_new (%.%w-) (%d-) (%d-) ')

local delete = gmatch(canvas .. ' delete ([%.%w]+)')
-- LuaFormatter on
local parsePoints = pipe(split(' '), map(toNumber), splitEvery(2), map(toPoint))

return function(line)
	for canvasId, cmd in raiseCord(line) do
		return {cmd = cmd, canvasId = canvasId} --
	end
	for canvasId, id, points in coords(line) do
		return {
			cmd = 'coords',
			canvasId = canvasId,
			id = id,
			points = parsePoints(points)
		}
	end
	for canvasId, id, params in configure(line) do
		return {
			cmd = 'configure',
			canvasId = canvasId,
			id = id,
			width = width(params),
			fill = fill(params),
			outline = outline(params)
		}
	end
	for canvasId, id, points in move(line) do
		return {
			cmd = 'move',
			canvasId = canvasId,
			id = id,
			points = parsePoints(points)
		}
	end
	for canvasId, shape, points, params in create(line) do
		-- not sure what dash or capstyle do
		return {
			cmd = 'create',
			shape = shape,
			canvasId = canvasId,
			fill = fill(params),
			outline = outline(params),
			font = font(line),
			points = parsePoints(points),
			tags = tags(params),
			width = width(params)
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
	for canvasId, id, text in setText(line) do
		return {canvasId = canvasId, id = id, text = text}
	end
	for canvasId, width, height in newCanvas(line) do
		return {
			cmd = 'new-canvas',
			canvasId = canvasId,
			width = width,
			height = height
		}
	end
	for canvasId, tag in delete(line) do
		return {cmd = 'delete', canvasId = canvasId, tag = tag}
	end
end
