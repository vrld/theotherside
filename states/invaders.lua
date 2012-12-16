local st = GS.new()

local function sign(x)
	if x < -1 then return -1
	elseif x > 1 then return 1
	else return 0 end
end

local animations

local hero, aliens, shots, naliens, may_shoot
local HC
local W,H

local move_direction, down_allowed

local function get_target()
	hero.target = nil
	for i = 1,math.random(naliens) do
		hero.target = next(aliens, hero.target)
	end
end

local function move(dx,dy, dt)
	local alien_speed = (30 + (1 - naliens / 55) * 100) * dt

	if (dx < 0 and move_direction == 'left') or (dx > 0 and move_direction == 'right') then
		local minx, maxx = math.huge, -math.huge
		for a in pairs(aliens) do
			local x,y = a:center()
			minx,maxx = math.min(minx,x-23), math.max(maxx,x+23)
		end

		if (dx < 0 and minx > alien_speed) or (dx > 0 and maxx < W - alien_speed) then
			for a in pairs(aliens) do
				a:move(alien_speed * dx, 0)
			end
			down_allowed = 0
		else
			down_allowed = 36
		end
	elseif dy ~= 0 then
		if down_allowed > 0 then
			alien_speed = math.min(down_allowed, alien_speed)
			for a in pairs(aliens) do
				a:move(0, alien_speed)
			end
			down_allowed = down_allowed - alien_speed
			if down_allowed <= 0 then
				move_direction = ({
					left  = 'right',
					right = 'left'
				})[move_direction]
			end
		end
	end
end

local function shoot(dir, x,y)
	local s = HC:addRectangle(0,0,6,18)
	s:moveTo(x,y)
	s.dy = dir * 200
	s.type = 'shot'
	shots[s] = s
	-- TODO: play sound
	return s
end

local pixel, particlesys
function st:init()
	W,H = love.graphics.getWidth(), love.graphics.getHeight()
	local g = anim8.newGrid(15, 12, 15*2, 12*3)
	local b = Image.invaders.shot
	local h = anim8.newGrid(2,6,4,6)
	animations = {
		anim8.newAnimation('loop', g('1-2,1'), .5),
		anim8.newAnimation('loop', g('1-2,2'), .5),
		anim8.newAnimation('loop', g('1-2,3'), .5),
		shot = anim8.newAnimation('loop', h('1-2,1'), .2),
	}

	pixel = love.image.newImageData(5,5)
	pixel:mapPixel(function() return 255,255,255,255 end)
	pixel = love.graphics.newImage(pixel)
end

function st:enter(prestate)
	particlesys = {}
	HC = Collider(100, function(_,a,b)
		if a.type == 'hero' and (b.type == 'alien' or b.type == 'shot') then
			return you_lose()
		elseif b.type == 'hero' and (a.type == 'alien' or a.type == 'shot') then
			return you_lose()
		end

		if a.type == 'shot' then a,b = b,a end
		if a.type == 'shot' then
			shots[a] = nil
		else -- alien
			if hero.target == a then hero.target = nil end
			aliens[a] = nil
			naliens = naliens - 1
			local p = love.graphics.newParticleSystem(pixel, 32)
			p:setColors(255,255,255,255, 200,200,200,255, 0,0,0,0)
			p:setEmissionRate(32/.2)
			p:setGravity(8,10)
			p:setParticleLife(.2,.2)
			p:setPosition(a:center())
			p:setSpeed(200,200)
			p:setSpread(2*math.pi)
			p:start()
			particlesys[p] = p
			Timer.do_for(.2, function(dt) p:update(dt) end, function() particlesys[p] = nil end)
			end
		HC:remove(a,b)
		shots[b] = nil

		if naliens <= 0 then
			GS.transition(State.tutorial, 1, "jumping maniac", State.canabalt)
		end
	end)

	aliens = {}
	for i = 1,11 do
		for k = 1,5 do
			local a = HC:addRectangle(0,0,45,36)
			a.type = 'alien'
			HC:setPassive(a)
			a:moveTo(((i-1) + .5) * 45 + (W-11*45)-10, ((k-1) + .5) * 36 + 10)
			a.anim= animations[math.ceil((k+1)/2)]
			aliens[a] = a
			HC:addToGroup('aliens', a)
		end
	end
	naliens = 55

	hero = HC:addRectangle(0,0,60,30)
	hero:moveTo(W/2,H-20)
	hero.type = 'hero'
	HC:addToGroup('hero', hero)

	hero.timer = Timer.new()
	hero.timer:add(math.random() * 5 + 5, function(f)
		get_target()
		hero.timer:add(math.random() * 5 + 5, f)
	end)
	hero.timer:add(math.random() + .5, function(f)
		local s = shoot(-1, hero:center())
		s.type = 'shot'
		HC:addToGroup('hero', s)
		hero.timer:add(math.random() + .5, f)
	end)

	shots = {}
	may_shoot = true

	move_direction, down_allowed = 'left', 0
end

function st:update(dt)
	if naliens <= 0 then return end
	for _,a in pairs(animations) do
		a:update(dt)
	end

	for s in pairs(shots) do
		local x,y = s:center()
		if y < -10 or y > H + 10 then
			HC:remove(s)
			shots[s] = nil
		else
			s:move(0,s.dy * dt)
		end
	end

	-- artificial dumbness
	hero.timer:update(dt)
	if not hero.target then
		get_target()
	end

	local x = hero:center()
	local d = sign(hero.target:center() - x)
	for s in pairs(shots) do
		local ds = hero:center() - s:center()
		if s:inGroup('aliens') and math.abs(ds) <= 40 then
			d = sign(ds)
			if d == 0 then
				d = x > W/2 and -1 or 1
			end
		end
	end

	hero:move(100 * d * dt,0)
	x = hero:center()
	if x < 30 then
		hero:move(30-x,0)
	elseif x > W-30 then
		hero:move(W-30-x,0)
	end

	if love.keyboard.isDown('left', 'a') then
		move(-1,0,dt)
	elseif love.keyboard.isDown('right', 'd')  then
		move(1,0,dt)
	elseif love.keyboard.isDown('down', 's') then
		move(0,1,dt)
	end

	HC:update(dt)
end

function st:draw()
	local hx,hy = hero:center()
	love.graphics.draw(Image.invaders.hero, hx,hy, 0,4,4, 7.5,3)

	--if hero.target then hero.target:draw() end

	for a in pairs(aliens) do
		local sx,sy = a:center()
		a.anim:draw(Image.invaders.aliens, sx,sy, 0,3,3, 7.5,6)
	end

	for s in pairs(shots) do
		local sx,sy = s:center()
		animations.shot:draw(Image.invaders.shot, sx,sy, 0,3,3,1,3)
	end

	for p in pairs(particlesys) do
		love.graphics.draw(p,0,0)
	end
end

function st:keypressed(key)
	if key == ' ' and may_shoot then
		local a
		for i = 1,math.random(naliens) do
			a = next(aliens, a)
		end
		local s = shoot(1, a:center())
		HC:addToGroup('aliens', s)
		may_shoot = false
		Timer.add(math.random() + .5, function() may_shoot = true end)
	end
end

return st
