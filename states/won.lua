local st = GS.new()

local W, H
local title = 'YOU WIN'
local title_width, title_height

local first = true

function st:enter(pre)
	W = love.graphics.getWidth()
	H = love.graphics.getHeight()

	title_width = Font.slkscr[70]:getWidth(title)
	title_height = Font.slkscr[70]:getHeight(title)

	Timer.add(3, function() GS.transition(State.selection, 1) end)

	DONE[({
		[State.invaders] = 1,
		[State.manpac] = 2,
		[State.canabalt] = 3,
	})[pre]] = true
end

function st:draw()
	love.graphics.setColor(255,255,255,a)
	love.graphics.setFont(Font.slkscr[70])
	love.graphics.rectangle('fill', 20,(H-title_height)/2, W-40, title_height)
	love.graphics.setColor(0,0,0,a)
	love.graphics.print(title, (W-title_width)/2, (H-title_height)/2)
end

return st
