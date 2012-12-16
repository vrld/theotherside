local st = GS.new()

local W, H
local title, title_width, title_height
local image, next_state

function st:enter(_, t, ns)
	W = love.graphics.getWidth()
	H = love.graphics.getHeight()

	title = t
	image = Image[t]
	title_width = Font.slkscr[70]:getWidth(title)
	title_height = Font.slkscr[70]:getHeight(title)

	next_state = ns
end

function st:keypressed(key, code)
	if key == ' ' or key == 'return' then
		GS.transition(next_state, .5)
	end
end

local t = 0
function st:update(dt)
	t = t + dt
end

function st:draw()
	love.graphics.setColor(255,255,255)
	love.graphics.setFont(Font.slkscr[70])
	love.graphics.rectangle('fill', 20,40, W-40, title_height)
	love.graphics.setColor(0,0,0)
	love.graphics.print(title, (W-title_width)/2, 40)

	love.graphics.setColor(255,255,255)
	love.graphics.draw(image, W/2,H/2+30,0,2,2, image:getWidth()/2,image:getHeight()/2)

	love.graphics.setColor(255,255,255,(math.sin(t)*.5+.5) * 100 + 155)
	love.graphics.setFont(Font.slkscr[40])
	love.graphics.printf("Press [space] to continue", 0,H-70,W, 'center')
end

return st
