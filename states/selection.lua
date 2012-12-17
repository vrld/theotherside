local gui = require 'Quickie'
gui.core.style.color.normal = {bg = {  0,  0,  0}, fg = {255,255,255}, border = {0,0,0}}
gui.core.style.color.hot    = {bg = {255,255,255}, fg = {  0,  0,  0}, border = {0,0,0}}
gui.core.style.color.active = {bg = {200,200,200}, fg = {  0,  0,  0}, border = {0,0,0}}
gui.core.style.gradient:set(255,255)

local function ImageButton(w)
	assert(type(w) == "table" and w.img, "Invalid argument")

	local imw,imh = w.img:getWidth(), w.img:getHeight()

	local tight = w.size and (w.size[1] == 'tight' or w.size[2] == 'tight')
	if tight then
		if w.size[1] == 'tight' then
			w.size[1] = imw
		end
		if w.size[2] == 'tight' then
			w.size[2] =  imh
		end
	end

	local id = gui.core.generateID()
	local pos, size = gui.group.getRect(w.pos, w.size)
	gui.mouse.updateWidget(id, pos, size, w.widgetHit)
	gui.keyboard.makeCyclable(id)
	gui.core.registerDraw(id, function(state, img, x,y,w,h, sx,sy)
		love.graphics.setColor(255,255,255)
		love.graphics.draw(img,x,y,0,sx,sy)
		if state == 'hot' then
			love.graphics.setLineWidth(3)
			love.graphics.rectangle('line', x-5,y-5,w+10,h+10)
		end
	end, w.img, pos[1],pos[2], size[1],size[2], size[1]/imw,size[2]/imh)

	return gui.mouse.releasedOn(id) or (gui.keyboard.key == 'return' and gui.keyboard.hasFocus(id))
end

local st = GS.new()
local fade_color, show_credits

local W, H

function st:init()
	gui.keyboard.cycle.prev = {key = 'up'}
	gui.keyboard.cycle.next = {key = 'down'}
	--gui.mouse.disable()
end

local mouse_hot, mouse_x, mouse_y
function st:enter()
	mouse_hot, mouse_x, mouse_y = nil, nil, nil
	W = love.graphics.getWidth()
	H = love.graphics.getHeight()
	gui.keyboard.clearFocus()
end

function st:leave()
	love.graphics.setLineWidth(1)
end

function st:update(dt)
	love.graphics.setFont(Font.slkscr[30])
	gui.group.push{grow = "right", size = {200,200}, spacing = 20, pos = {(W-640)/2, 210}}

	gui.group.push{grow = "down"}
	if ImageButton{img = Image.btn_invaders} then
		Sound.static.select:play()
		GS.transition(State.tutorial, 1, "earth defenders", State.invaders)
	end
	if DONE[1] then
		gui.Label{text = "mastered", align="center", size = {200, 'tight'}, pos = {nil,10}}
	end
	gui.group.pop{}

	gui.group.push{grow = "down"}
	if ImageButton{img = Image.btn_manpac} then
		Sound.static.select:play()
		GS.transition(State.tutorial, 1, "pill addict", State.manpac)
	end
	if DONE[2] then
		gui.Label{text = "mastered", align="center", size = {200, 'tight'}, pos = {nil,10}}
	end
	gui.group.pop{}

	gui.group.push{grow = "down"}
	if ImageButton{img = Image.btn_canabalt} then
		Sound.static.select:play()
		GS.transition(State.tutorial, 1, "jumping maniac", State.canabalt)
	end
	if DONE[3] then
		gui.Label{text = "mastered", align="center", size = {200, 'tight'}, pos = {nil,10}}
	end
	gui.group.pop{}

	gui.group.pop{}

	love.graphics.setFont(Font.slkscr[40])
	gui.group.push{grow = "down", size = {700,30}, spacing = 5, pos = {(W-700)/2, H-70}}
	if gui.Button{text = "back", size = {400,40}, pos = {150}} then
		Sound.static.select:play()
		GS.transition(State.menu)
	end
	gui.group.pop{}

	-- on mouse move -> set widget focus to mouse
	if mouse_hot ~= gui.mouse.getHot() then
		gui.keyboard.setFocus(gui.mouse.getHot() or gui.keyboard.getFocus())
		mouse_hot = gui.mouse.getHot()
	end
end

function st:keypressed(key, code)
	if key == ' ' then key = 'return' end
	if key == 'left' then
		key = gui.keyboard.cycle.prev.key
	end
	if key == 'right' then
		key = gui.keyboard.cycle.next.key
	end

	if key == gui.keyboard.cycle.next.key or key == gui.keyboard.cycle.prev.key then
		gui.mouse.setHot(gui.keyboard.getFocus())
		mouse_hot = gui.mouse.getHot()
		Sound.static.switch:play()
	end
	return gui.keyboard.pressed(key, code)
end

function st:draw()
	local title = 'SELECT CHALLENGE'
	local tw = Font.slkscr[70]:getWidth(title)
	local th = Font.slkscr[70]:getHeight(title)

	gui.core.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.setFont(Font.slkscr[70])
	love.graphics.rectangle('fill', 20,40, W-40, th)
	love.graphics.setColor(0,0,0)
	love.graphics.print(title, (W-tw)/2, 40)
end

return st
