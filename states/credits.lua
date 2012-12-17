local gui = require 'Quickie'

local st = GS.new()

local W, H
local title = 'CREDITS'
local title_width, title_height

local credits = {
	{"a game brought to you by",  "matthias richter // vrld.org"},
	{"inspired by the amazing",   "Space Invaders // Tomohiro Nishikado, Taito",
	                              "Pac-Man // Toru Iwatani, Namco",
	                              "Canabalt // Adam Saltsman"},
	{"made with L:OVE",           "pimp inc. // love2d.org"},
	{"with help of anim8",        "enrique garcia // github.com/kikito"},
	{"and the font `silkscreen'", "jason kotte // kotte.org"},
}

function st:enter(pre)
	W = love.graphics.getWidth()
	H = love.graphics.getHeight()

	title_width = Font.slkscr[70]:getWidth(title)
	title_height = Font.slkscr[70]:getHeight(title)
end

function st:keypressed(key, code)
	return gui.keyboard.pressed(key, code)
end

function st:update(dt)
	gui.group.push{grow = "down", size = {700,20}, spacing = 5, pos = {(W-700)/2, title_height + 70}}
	for _,line in ipairs(credits) do
		love.graphics.setFont(Font.slkscr[30])
		gui.Label{text = line[1], align = "left"}
		for i = 2,#line do
			love.graphics.setFont(Font.slkscr[25])
			gui.Label{text = line[i], align = "right", size = {nil, 'tight'}}
		end
		gui.Label{text = '', size = {nil, 3}} -- spacer
	end
	gui.group.pop{}

	gui.group.push{grow = "down", size = {700,30}, spacing = 5, pos = {(W-700)/2, H-70}}
	love.graphics.setFont(Font.slkscr[40])
	gui.keyboard.clearFocus()
	if gui.Button{text = "Back", size = {400,40}, pos = {150}} then
		Sound.static.select:play()
		GS.transition(State.menu, 1)
	end
	gui.group.pop{}
end

function st:draw()
	gui.core.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.setFont(Font.slkscr[70])
	love.graphics.rectangle('fill', 20,40, W-40, title_height)
	love.graphics.setColor(0,0,0)
	love.graphics.print(title, (W-title_width)/2, 40)
end

return st
