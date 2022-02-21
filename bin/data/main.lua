require('globals')

local text = require('utils/text')
local file = require('utils/io')
local s = require('utils/string')
local fifo = require('utils/fifo')
local pd = require('pd')
local frame = require('ui/frame')
local canvas = require('canvas')
local parse = require('parse')

Target = 'desktop'
Scaling = false
Scale = 2
UpdateNeeded = true

local editmode = 0
local trace = fifo(30)
local canvasId

function setup()
	of.setVerticalSync(false) -- false for fps > 60 (desktop only, apparently)
	of.setFrameRate(90)
	of.enableSmoothing()
	of.enableAntiAliasing()

	local success = false

	if Target == 'android' then
		success = mpd.initAudio(1, 2, 44100)
	else
		success = mpd.initAudio("Apple Inc.: MacBook Pro Microphone",
		                        "Apple Inc.: MacBook Pro Speakers", 48000)
	end

	if (success) then
		pd.queue('pd open test.pd', file.getPath('.')) --
	end
end

function draw()
	pd.flush()

	if UpdateNeeded then
		frame.render(canvas.draw)
		UpdateNeeded = false
	end
	frame.draw(0, 0)

	of.setColor(0, 0, 0, 100)
	text.draw(math.floor(of.getFrameRate()) .. " items:" .. #canvas.items(), 50, 60)
	text.draw(s.joinLines(trace.items()), 50, 120)
end

function touchEvent(touch)
	local x = math.floor(touch.x / Scale)
	local y = math.floor(touch.y / Scale)

	if (touch.type == of.TouchEventArgs_down) then
		pd.queue(canvasId, 'mouse', x, y, '1 0')
	elseif (touch.type == of.TouchEventArgs_up) then
		pd.queue(canvasId, 'mouseup', x, y, '1')
	elseif (touch.type == of.TouchEventArgs_move) then
		pd.queue(canvasId, 'motion', x, y, '0')
	elseif (touch.type == of.TouchEventArgs_doubleTap) then
		if (editmode == 1) then
			editmode = 0
		else
			editmode = 1
		end
		pd.queue(canvasId, 'editmode', editmode)
	end
end

function keyPressed(key)
	if (s.keyEq('e', key)) then
		pd.queue(canvasId, 'editmode 0') --
	elseif (s.keyEq('a', key)) then
		pd.queue(canvasId, 'selectall') --
	elseif (s.keyEq('w', key)) then
		pd.queue(canvasId, 'editmode 1') --
	elseif (s.keyEq('x', key)) then
		pd.delete(canvasId) --
	elseif (s.keyEq('u', key)) then
		pd.queue(canvasId, 'undo') --
	end
end

function gotMessage(msg)
	local parsed = parse(msg)

	if parsed == nil then
		log('not parsed', msg)
	elseif parsed.cmd == 'new-canvas' then
		canvasId = parsed.canvasId
		pd.queue(canvasId, 'map 1')
		pd.queue(canvasId, 'query-editmode')
		pd.queue(canvasId, 'updatemenu')
		pd.queue(canvasId, 'editmode', editmode)
	else
		canvas.message(parsed)
		UpdateNeeded = true
	end
end

function exit()
end

touchMoved = touchEvent
-- function(touch)
-- 	touchCount = touchCount + 1
--
-- 		touchEvent(touch)
-- 	elseif touchable then
-- 		touchEvent(touch)
-- 		touchable = false
-- 	end
-- end
