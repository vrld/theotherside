local gui = require 'Quickie'
gui.core.style.color.normal = {bg = {  0,  0,  0}, fg = {255,255,255}, border = {0,0,0}}
gui.core.style.color.hot    = {bg = {255,255,255}, fg = {  0,  0,  0}, border = {0,0,0}}
gui.core.style.color.active = {bg = {200,200,200}, fg = {  0,  0,  0}, border = {0,0,0}}
gui.core.style.gradient:set(255,255)

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

function st:update(dt)
	gui.group.push{grow = "down", size = {W,20}, spacing = 5, pos = {0,H/2-140}}
	love.graphics.setFont(Font.slkscr[30])
	gui.Label{text = "Made in 48 hours for Ludum Dare 25", align='center', size = {nil,30}}
	if not love.graphics.isSupported('npot', 'canvas', 'pixeleffect') then
		love.graphics.setFont(Font.slkscr[21])
		gui.Label{text = "Your computer does not support PixelEffects(tm).", align='center', pos = {0,67}}
		gui.Label{text = "Of course you can still play the game,", align = 'center'}
		gui.Label{text = "but it wont look and feel as hipster :'(", align='center'}
	end
	gui.group.pop{}

	love.graphics.setFont(Font.slkscr[40])
	gui.group.push{grow = "down", size = {400,40}, spacing = 5, pos = {(W-400)/2, H-200}}
	if gui.Button{text = "Start"} then
		Sound.static.select:play()
		GS.transition(State.selection)
	end
	if gui.Button{text = "Credits"} then
		Sound.static.select:play()
		GS.transition(State.credits)
	end
	if gui.Button{text = "Exit"} then
		love.event.push("quit")
		return
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
	if key == gui.keyboard.cycle.next.key or key == gui.keyboard.cycle.prev.key then
		gui.mouse.setHot(gui.keyboard.getFocus())
		mouse_hot = gui.mouse.getHot()
		Sound.static.switch:play()
	end
	return gui.keyboard.pressed(key, code)
end

function st:draw()
	local title = 'THE OTHER SIDE'
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
