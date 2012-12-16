local st = GS.new()

local W, H
local title = 'GAME OVER'
local title_width, title_height
local pre, t

local first = true

function st:enter(prestate)
	pre = prestate
	t = 10
	W = love.graphics.getWidth()
	H = love.graphics.getHeight()

	title_width = Font.slkscr[70]:getWidth(title)
	title_height = Font.slkscr[70]:getHeight(title)

	local delay = 1
	if first then
		delay = 3
		first = false
	end
	Timer.add(math.random() * 1 + delay, function()
		GS.transition(pre, 1)
	end)
end

function st:update(dt)
	t = t - dt
end

function st:draw()
	local a = 255 * (1 - math.max(0, 1 - (10-t)*2) ^ 2)
	pre:draw()
	love.graphics.setColor(0,0,0,a)
	love.graphics.rectangle('fill',0,0,W,H)

	love.graphics.setColor(255,255,255,a)
	love.graphics.setFont(Font.slkscr[70])
	love.graphics.rectangle('fill', 20,40, W-40, title_height)
	love.graphics.setColor(0,0,0,a)
	love.graphics.print(title, (W-title_width)/2, 40)

	local offset = 160
	love.graphics.setColor(255,255,255,a)
	love.graphics.setFont(Font.slkscr[50])
	love.graphics.printf('insert coin', 0,title_height+offset, W, 'center')
	love.graphics.printf('to continue', 0,title_height+offset+60, W, 'center')

	love.graphics.setFont(Font.slkscr[70])
	love.graphics.printf(tostring(math.ceil(t)), 0,title_height+offset+130, W, 'center')
end

return st
