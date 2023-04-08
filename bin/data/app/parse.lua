-- TODO('parse arrays in [list *] or {*} format')
local S = require('utils.string')
local F = require('utils.functional')
local point = require('utils.point')

local push = F.push
local head, init, tail, last = S.head, S.init, S.tail, S.last

local scaleEvent = {scale = 1, scaleBegin = 1, scaleEnd = 1, scroll = 1}

local isKey = function(x)
	return x ~= nil and head(x) == '-'
end

local splitWords = function(s, nl)
	local separator = nl and '[%S\n]+' or '%S+'
	return s:gmatch(separator)
end

local parseColor = function(x)
	if x == 'black' or x == 'Black' then
		return '000000'
	elseif x == 'blue' or x == 'Blue' then
		return '0000ff'
	end
	return tail(x)
end

local advanceToCurly = function(word)
	while last(word()) ~= '}' do
		-- nothing, we just want to move on the cursor
	end
end

-- we only have one font, so we only get the fontsize from here
local parseFontsize = function(word)
	advanceToCurly(word)
	local fontsize = tonumber(word())
	if (fontsize < 0) then
		fontsize = fontsize * -1
	end
	advanceToCurly(word)
	return fontsize
end

local parsePoints = function(word)
	local points = {}
	local current = nil
	for part in word do
		local x = tonumber(part)
		if x == nil then
			current = part
			break
		end
		push(point(x, tonumber(word())), points)
	end
	return points, current
end

local parseText = function(word)
	local text = tail(word())
	if last(text) == '}' then
		return init(text)
	end

	for part in word do
		if last(part) == '}' then
			text = text .. ' ' .. init(part)
			break
		else
			text = text .. ' ' .. part
		end
	end
	return text
end

local parseList = function(word)
	local first = word()

	if first == '[list' then
		local list = {}
		local part = word()
		while last(part) ~= ']' do
			push(part, list)
			part = word()
		end
		push(init(part), list)
		return list
	end
	return {first}
end

local parseValue = function(key, word)
	if key == 'fill' or key == 'outline' then
		return parseColor(word())
	elseif key == 'width' then
		return tonumber(word())
	elseif key == 'font' then
		return parseFontsize(word)
	elseif key == 'text' then
		return parseText(word)
	elseif key == 'tags' then
		return parseList(word)
	else
		return word()
	end
end

local function parseParams(first, word)
	local params = {}
	params[first] = parseValue(first, word)
	for part in word do
		if isKey(part) then
			local key = tail(part)
			params[key] = parseValue(key, word)
		end
	end
	return params
end

local getId = function(tags)
	if (#tags > 0) then
		return tags[1]
	end
end

local function parseCreate(canvasId, word)
	local cmd = word()
	local params = {}
	local points, current = parsePoints(word)
	if (cmd == 'line' and #points > 2) then
		cmd = 'polyline'
	end
	if isKey(current) then
		params = parseParams(tail(current), word)
	end
	local id = getId(params.tags)
	return {canvasId = canvasId, cmd = cmd, id = id, points = points, params = params}
end

local parseNewText = function(canvasId, word)
	local tags = {tail(word()), word(), tail(word())}
	local points = {{x = tonumber(word()), y = tonumber(word())}}
	return {
		cmd = 'text',
		id = getId(tags),
		canvasId = canvasId,
		points = points,
		params = {tags = tags, text = parseText(word)}
	}
end

return function(input)
	local nl = input:sub(1, 9) == 'pdtk_text'
	local word = splitWords(input, nl)

	local first = word() -- calling order of word is important
	local second = word()

	if second == 'create' then
		return parseCreate(first, word)
	elseif (second == 'coords' or second == 'move' or second == 'delete') then
		return {cmd = second, tag = word(), points = parsePoints(word)}
	elseif (second == 'itemconfigure') then
		-- missing select-line and unselect-line
		local tag = word()
		local params = parseParams(tail(word()), word)
		return {cmd = second, tag = tag, params = params}
	elseif (first == 'pdtk_text_new') then
		return parseNewText(second, word)
	elseif (first == 'pdtk_canvas_editmode') then
		return {cmd = 'editmode', canvasId = second, value = tonumber(word())}
	elseif first == 'pdtk_text_set' then
		local tag = word()
		local params = {text = parseText(word)}
		return {cmd = 'set-text', canvasId = second, tag = tag, params = params}
	elseif (first == 'pdtk_canvas_new') then
		local width = tonumber(word())
		local height = tonumber(word())
		return {cmd = 'new-canvas', canvasId = second, width = width, height = height}
	elseif (first == 'touch') then
		local x = tonumber(word())
		local y = tonumber(word())
		return {cmd = first, type = tonumber(second), x = x, y = y}
	elseif (scaleEvent[first]) then
		local x = second
		return {cmd = first, x = x, y = tonumber(word()), value = tonumber(word())}
	elseif (first == 'orientation') then
		return {cmd = first, value = second}
	elseif input == 'update-start' or input == 'update-end' then
		return {cmd = input}
	elseif first == 'gui' then
		return {cmd = first, type = second, id = word(), value = word()}
	end
end
