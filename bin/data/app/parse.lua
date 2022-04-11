local splitWords = function(s, nl)
	local sep = '%S+'
	if nl then sep = '[%S\n]+' end

	local words = {}
	for word in s:gmatch(sep) do
		if word ~= '' then
			words[#words + 1] = word --
		end
	end
	return words
end

local isKey = function(s)
	return s:sub(1, 1) == '-'
end

local parseColor = function(x)
	if x == 'black' or x == 'Black' then
		return '000000'
	elseif x == 'blue' or x == 'Blue' then
		return '0000ff'
	end
	return x:sub(2)
end

local parseParams = function(i, parts, match)
	local size = #parts

	match.params = {}
	match.tags = {}

	while (i < size) do
		if (not isKey(parts[i])) then
			i = i + 1
		else
			local key = parts[i]:sub(2)
			local value = parts[i + 1]

			if (key == 'fill' or key == 'outline') then
				match.params[key] = parseColor(value)
				i = i + 2
			elseif (key == 'tags') then
				if (value == '[list') then
					i = i + 2
					value = parts[i]
					while (value:sub(-1) ~= ']') do
						match.tags[#match.tags + 1] = value
						i = i + 1
						value = parts[i]
					end
					match.tags[#match.tags + 1] = value:sub(1, -2)
				else
					match.tags[#match.tags + 1] = value
					i = i + 1
				end
			elseif (key == 'width') then
				match.params[key] = tonumber(value)
				i = i + 2
			elseif (i ~= size or isKey(parts[i + 2])) then
				match.params[key] = value
				i = i + 2
			else
				i = i + 1
			end
		end
	end
end

local parsePoints = function(i, parts, match)
	local size = #parts

	match.points = {}

	while (i < size) do
		local x = tonumber(parts[i])
		if x == nil then break end
		match.points[#match.points + 1] = {x = x, y = tonumber(parts[i + 1])}
		i = i + 2
	end

	return i
end

return function(input)
	local nl = input:sub(1, 9) == 'pdtk_text'
	local parts = splitWords(input, nl)

	if #parts > 2 then
		local cmd = parts[2]
		local match = {message = input, canvasId = parts[1], cmd = cmd}

		if cmd == 'create' then
			match.cmd = parts[3];
			local i = parsePoints(4, parts, match)
			parseParams(i, parts, match)
			if (match.cmd == 'line' and #match.points > 2) then match.cmd = 'polyline' end
			if (#match.tags > 0) then match.id = match.tags[1] end
		elseif (cmd == 'coords' or cmd == 'move' or cmd == 'delete') then
			match.tag = parts[3];
			parsePoints(4, parts, match)
		elseif (cmd == 'itemconfigure') then
			match.tag = parts[3]
			parseParams(4, parts, match)
		elseif (parts[1] == 'scale') then
			match.cmd = parts[1]
			match.type = parts[2]
			match.value = tonumber(parts[3])
			match.x = tonumber(parts[4])
			match.y = tonumber(parts[5])
		elseif (parts[1] == 'scale') then
			match.cmd = parts[1]
			match.type = parts[2]
			match.value = tonumber(parts[3])
			match.x = tonumber(parts[4])
			match.y = tonumber(parts[5])
		elseif (parts[1] == 'pdtk_canvas_new') then
			match.cmd = 'new-canvas'
			match.canvasId = parts[2]
			match.width = tonumber(parts[3])
			match.height = tonumber(parts[4])
		elseif (parts[1] == 'pdtk_canvas_editmode') then
			match.cmd = 'editmode'
			match.canvasId = parts[2]
			match.value = tonumber(parts[3])
		elseif (parts[1] == 'pdtk_text_new') then
			match.cmd = 'new-text'
			match.canvasId = parts[2]
			match.tags = {parts[3]:sub(2), parts[4], parts[5]:sub(1, -2)}
			match.points = {{x = tonumber(parts[6]), y = tonumber(parts[7])}}
			match.value = parts[8]:sub(2)
			local i = 9
			while (parts[i] ~= '}') do
				match.value = match.value .. ' ' .. parts[i]
				i = i + 1
			end
		elseif (parts[1] == 'pdtk_text_set') then
			match.cmd = 'set-text'
			match.canvasId = parts[2]
			match.tag = parts[3]
			match.value = parts[4]:sub(2)
			local i = 5
			while (parts[i] ~= '}') do
				match.value = match.value .. ' ' .. parts[i]
				i = i + 1
			end
		else
			if _dev then log(red('not parsed'), input) end
			return nil
		end
		return match
	end
end

-- local isHyphen = function(x)
-- 	return x == '-'
-- end
--
-- local isDigit = function(x)
-- 	-- LuaFormatter off
-- 	return x == '0' or x == '1' or x == '2' or x == '3' or x == '4' or
-- 	       x == '5' or x == '6' or x == '7' or x == '8' or x == '9'
-- 	-- LuaFormatter on
-- end
--
-- local charAt = function(i, x)
-- 	return x:sub(i, i)
-- end
