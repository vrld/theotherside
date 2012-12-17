local st = GS.new()

local W,H
local HC, cam
local hero, houses
local anim, bg_quad

local tgoal
function st:init()
	W,H = love.graphics.getWidth(), love.graphics.getHeight()
	local g = anim8.newGrid(12,18,24,18)
	anim = anim8.newAnimation('loop', g('1-2,1'), .1)

	bg_quad = love.graphics.newQuad(0,0,100*800,600,800,600)
	Image.city:setWrap('repeat','repeat')
		Sound.stream.canabalt:setLooping(true)
end

function st:enter(pre)
	if pre == State.tutorial then
		Sound.stream.canabalt:stop()
		Sound.stream.canabalt:play()
		Sound.stream.canabalt:setVolume(1)
	end
	cam = Camera()
	HC = Collider(100, function(_,a,b,dx,dy)
		hero.vel.y = math.max(0, hero.vel.y)
		a:move(dx,dy)
		if dx == 0 then
			hero.touches = b
		end
	end)
	hero = HC:addRectangle(0,0,20,20)
	hero:moveTo(0,H/4)
	hero.vy = 0
	hero.vel = vector(300, 300)
	hero.lastx = hero:center()

	houses = {}
	local x,y = 0,H/2+20
	for i = 1,100 do
		local w = (1 + math.random() * .5) * W
		local h = HC:addRectangle(0,0, w,H)
		h:move(x,y)
		HC:setPassive(h)
		h.isHouse = true

		houses[i] = h
		x = x + w + math.random(100,200)
		y = H/2 + math.random(-60,60)
	end

	tgoal = 45
end

function st:leave()
end

function st:update(dt)
	tgoal = tgoal - dt
	if tgoal <= 0 then
		local t = .5
		Timer.do_for(.5, function(dt)
			t = t - dt
			Sound.stream.canabalt:setVolume(t/.5)
		end, function()
			Sound.stream.canabalt:stop()
		end)
		GS.transition(State.won, 1)
		return
	end
	anim:update(dt)

	if hero.touches then
		hero.vely = 0
		if love.keyboard.isDown('up', 'w') then
			hero.touches:move(0, -70*dt)
			-- TODO: play sound
		elseif love.keyboard.isDown('down', 's') then
			hero.touches:move(0, 70*dt)
			-- TODO: play sound
		end

		local _,_,x2 = hero.touches:bbox()
		if x2 - hero:center() < math.random(15,30) then
			hero.vel.y = -math.random(375,525)
			hero.touches = nil
		end
	end

	hero.vel.x = (.5 + (1-tgoal/45)) * 800
	hero.vel.y = math.min(500, hero.vel.y + (700 + hero.vel.x*.7) * dt)
	hero:move((hero.vel * dt):unpack())

	HC:update(dt)

	local x,y = hero:center()
	cam:lookAt(x+W*.4, H/2)
	if y > H then --or  x == hero.lastx then
		you_lose()
	end
	hero.lastx = x
end

function st:draw()
	cam:attach()
	love.graphics.setColor(255,255,255)
	love.graphics.drawq(Image.city, bg_quad, -300,0, 0, 1.3,1)
	local x,y = hero:center()
	anim:draw(Image.canabolt, x,y, 0,3,3, 6,14)

	local x,y = cam:worldCoords(0,0)
	for h in pairs(HC:shapesInRange(x,y,x+800,y+600)) do
		if h.isHouse then
			local x1,y1,x2,y2 = h:bbox()
			love.graphics.setColor(160,160,160)
			h:draw('fill')
			love.graphics.setColor(240,240,240)
			love.graphics.rectangle('fill', x1-4,y1, (x2-x1)+8, 5)
			love.graphics.setColor(120,120,120)
			love.graphics.rectangle('fill', x1,y1+5, (x2-x1), 5)

			love.graphics.rectangle('fill', x1,y1+20, (x2-x1), 2)
			local w = (x2-x1)
			local nwindows = math.floor(w/60)
			local ox = x1 + (w - nwindows * 60)
			for i = 0,nwindows-1 do
				local x = i * 60 + ox
				for y = y1+40,H+40,60 do
					love.graphics.rectangle('fill', x,y, 40,40)
				end
			end
		end
	end
	
	cam:detach()
	love.graphics.setFont(Font.slkscr[20])
	love.graphics.setColor(40,40,40)
	love.graphics.print(('time to rescue: %.1f'):format(math.max(0,tgoal)), 5, H-25)
end

return st
