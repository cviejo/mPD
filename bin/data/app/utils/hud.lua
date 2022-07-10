of.TrueTypeFont.setGlobalDpi(96)

local font = of.TrueTypeFont()
font:load("fonts/DejaVuSansMono.ttf", 22)

local draw = function(str, x, y)
	of.setColor(0, 0, 0, 100)
	font:drawString('fps: ' .. of.getFrameRate(), 50, 50)
	font:drawString('mem: ' .. math.floor(collectgarbage("count")), 50, 75)
end

return {draw = draw}
