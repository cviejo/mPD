of.TrueTypeFont.setGlobalDpi(96)

local makeFont = function(file, size)
	local font = of.TrueTypeFont()
	font:load(file, size)
	return font
end

local current = makeFont("fonts/DejaVuSansMono.ttf", 22)

local draw = function(str, x, y)
	current:drawString(str, x, y)
end

return {draw = draw}
