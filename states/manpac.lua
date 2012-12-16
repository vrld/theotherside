local st = GS.new()

-- the world
local ghosts, manpac
local Level = {}

function Level.wall(x,y, c)
	local co = vector(x,y)
	x,y = vector(x-1,y-1):permul(Level.tilesize):unpack()
	local sx, sy = (Level.tilesize/8):unpack()
	return {
		coords = co,
		walkable = false,
		draw = function()
			local img = Image.manpac.walls[c]
			love.graphics.setColor(100,100,255)
			love.graphics.draw(img, x,y, 0, sx,sy)
		end,
	}
end

function Level.floor(x,y, pill, steroids)
	local co = vector(x,y)
	local draw = function() end
	if pill or steroids then
		local r = steroids and Level.tilesize:minCoord() * .4 or 2
		x,y = Level.screencoords(co):unpack()
		draw = function()
			love.graphics.setColor(255,255,255)
			love.graphics.circle('fill', x,y, r)
		end
	end
	return {
		coords = co,
		walkable = true,
		pill = pill or steroids,
		steroids = steroids,
		draw = draw,
	}
end

function Level.draw()
	for i = 1,#Level.grid do
		for k = 1,#Level.grid[i] do
			Level.grid[i][k]:draw()
		end
	end

	--local W = love.graphics.getWidth()
	--local H = love.graphics.getHeight()
	--for i = 1,#Level.grid do
	--	love.graphics.line(0, i*Level.tilesize.y, W, i*Level.tilesize.y)
	--end
	--for k = 1,#Level.grid[1] do
	--	love.graphics.line(k*Level.tilesize.x, 0, k*Level.tilesize.x, H)
	--end
end

function Level.cellcoords(v)
	return v:round()
end

function Level.screencoords(v)
	return (v - vector(.5,.5)):permul(Level.tilesize)
end

function Level.cell(v)
	v = Level.cellcoords(v)
	local c = Level.grid[v.y]
	if not c then return {walkable = false} end
	return c[v.x] or {walkable = false}
end

function Level.inCell(coords, pos)
	return coords == Level.cellcoords(pos)
end

function Level.getNeighbors(v)
	v = v:round()
	local cell = Level.cell(v)

	if not cell.neighbors then
		local ret = {}
		for o in Set{vector(1,0), vector(-1,0), vector(0,1), vector(0,-1)} do
			local c = Level.cell(v+o)
			if c.walkable and not c.house then ret[#ret+1] = c end
		end
		cell.neighbors = ret
	end

	return cell.neighbors
end

-- common stuff
local function walk(self, dir, dt)
	if Level.cell(self.pos + dir * .5).walkable then
		self.pos = self.pos + dir * dt * self.speed
	end

	-- lock in center of tunnel
	local c = Level.cellcoords(self.pos)
	if dir.x == 0 and dir.y ~= 0 then
		self.pos.x = self.pos.x + (c.x - self.pos.x) * dt * self.speed
	end
	if dir.y == 0 and dir.x ~= 0 then
		self.pos.y = self.pos.y + (c.y - self.pos.y) * dt * self.speed
	end
end

-- the villian
Ghost = class(function(self,x,y)
	self.pos = vector(x,y)
	self.direction = vector(0,-1)
	self.scatter_target = vector(math.random(#Level.grid[1]), math.random(#Level.grid))
end)
Ghost.speed = 5
Ghost.color = {
	{255,50,10},
	{200,120,255},
	{255,200,50},
	{10,200,255},
}

function Ghost:draw(i, is_player_controlled)
	local x,y = Level.screencoords(self.pos):unpack()

	if self.mode == 'frightened' then
		love.graphics.setColor(10,20,200)
	else
		love.graphics.setColor(Ghost.color[i])
	end

	if is_player_controlled then
		love.graphics.polygon('fill',
			x-7, y - self.center.y * 4,
			x+7, y - self.center.y * 4,
			x,   y - self.center.y * 4 + 10)
	end
	self.anim:draw(Image.manpac.ghost, x,y, 0, self.scale.x, self.scale.y, self.center:unpack())

	--if self.target then
	--	local tx,ty = Level.screencoords(self.target):unpack()
	--	love.graphics.line(x,y,tx,ty)
	--end

	--love.graphics.setColor(255,255,255)
	--local v = Level.screencoords(Level.cellcoords(self.pos))
	--love.graphics.circle('fill', v.x, v.y, 4)
end

function Ghost:inHouse()
	return Level.cell(self.pos).house
end

function Ghost:updatePlayer(dt)
	if self.undead_but_dead then return end
	local dx,dy = 0,0
	if love.keyboard.isDown('left', 'a') then
		dx = -1
	elseif love.keyboard.isDown('right', 'd') then
		dx = 1
	end
	if love.keyboard.isDown('up', 'w') then
		dy = -1
	elseif love.keyboard.isDown('down', 's') then
		dy = 1
	end

	walk(self, vector(dx,dy), dt)
end

local function find_direction(self)
	local cell = Level.cell(self.pos)
	if self.last_decision == cell then
		return
	end

	-- decide where to go next when reaching an intersection
	local neighbors = Level.getNeighbors(self.pos)

	if #neighbors > 2 then
		local pos = self.pos:round()
		local dist, closest = math.huge
		if self.mode == 'frightened' then
			closest = neighbors[math.random(#neighbors)].coords
		else
			local target
			if self.mode == 'scatter' then
				target = self.scatter_target
			else -- self.mode == 'chase'
				local phi,r = math.random()*2*math.pi, math.random(1,3)
				target = manpac.pos + vector(math.cos(phi)*r, math.sin(phi)*r):round()
			end
			self.target = target

			for i,n in ipairs(neighbors) do
				-- if we are not coming from this tile...
				if n.coords ~= (pos - self.direction) then
					local d = n.coords:dist(target)
					if d < dist then
						dist, closest = d, n.coords
					end
				end
			end
		end
		self.direction = closest - pos
		self.last_decision = cell
	end

	if not Level.cell(self.pos + self.direction).walkable then
		self.direction = self.direction:perpendicular()
		if not Level.cell(self.pos + self.direction).walkable then
			self.direction = -self.direction
		end
	end
end

function Ghost:updateAI(dt)
	if self.undead_but_dead then return end
	if self:inHouse() then
		local dir = vector(0,0)
		if self.pos.x < 14 then
			dir.x = 1
		elseif self.pos.x > 15 then
			dir.x = -1
		else
			dir.y = -1
		end
		self.direction = dir
		walk(self, self.direction, dt)
		return
	end

	find_direction(self)
	walk(self, self.direction, dt)
end

-- the hero
ManPac = class(function(self, x,y)
	self.pos = vector(x,y)
	self.path = {}
	self.wacca = 0
	self.direction = vector(1,0)
end)
ManPac.speed = 7

function ManPac:draw()
	love.graphics.setColor(255,255,100)
	local x,y = Level.screencoords(self.pos):unpack()
	local r = Level.tilesize:minCoord() * .8
	local phi = (1 - 2 * math.abs((self.wacca % 1) - .5)) * math.pi/4

	local rot
	if self.direction.x == 1 then
		rot = 0
	elseif self.direction.x == -1 then
		rot = math.pi
	elseif self.direction.y == 1 then
		rot = math.pi/2
	else
		rot = -math.pi/2
	end
	love.graphics.push()
	love.graphics.translate(x,y)
	love.graphics.rotate(rot)
	love.graphics.arc('fill', 0,0, r, 2*math.pi - phi, phi)
	love.graphics.pop()

	--local p0 = Level.cellcoords(self.pos)
	--for _,p in ipairs(self.path) do
	--	local q,r = Level.screencoords(p0), Level.screencoords(p[2])
	--	love.graphics.line(q.x,q.y, r.x,r.y)
	--	p0 = p[2]
	--end
	--love.graphics.setColor(255,255,255)
	--local v = Level.screencoords(Level.cellcoords(self.pos))
	--love.graphics.circle('fill', v.x, v.y, 4)
end

local function find_path(pos, dir)
	local cell = Level.cell(pos)
	local seen, active = {}, {}
	active[cell] = {}

	while true do
		local new_active, has_active = table.copy(active), false
		for cell, path in pairs(active) do
			for _,n in ipairs(Level.getNeighbors(cell.coords)) do
				if not seen[n] and n.walkable and not n.has_ghost then
					local path = table.copy(path)
					path[#path+1] = {n.coords - cell.coords, n.coords}
					if n.pill then
						return path
					end
					new_active[n] = path
					has_active = true
				end
				seen[n] = true

				new_active[cell] = nil
			end
		end
		active = new_active

		if not has_active then
			local d = dir
			for d in Set{d, d:perpendicular(), -d:perpendicular(), -d} do
				local c = Level.cell(pos + d)
				if c.walkable then return {d, c.coords} end
			end
		end
	end
end

function ManPac:update(dt)
	self.wacca = self.wacca + dt * math.pi * 1.5

	local cell = Level.cell(self.pos)
	if cell.steroids then
		local mode = Ghost.mode
		local toggle_timer = Ghost.toggle_timer
		local speed = Ghost.speed
		Ghost.mode = 'frightened'
		Ghost.toggle_timer = {update = function() end}
		Ghost.speed = Ghost.speed * .6
		Timer.add(10, function()
			Ghost.mode = mode
			Ghost.toggle_timer = Ghost.toggle_timer
			Ghost.speed = speed
		end)
	end

	if cell.pill then
		-- TODO: play sound
		cell.pill = false
		cell.steroids = false
		cell.draw = function() end
		Level.pills = Level.pills - 1
	end

	for _,g in ipairs(ghosts) do
		local dist = g.pos:dist(self.pos)
		local hit = dist < 1
		if hit and g.mode == 'frightened' then
			-- TODO: play sound
			g.undead_but_dead = true
			local s = 0
			local init = g.pos:clone()
			local delta = vector(14,15) - g.pos
			Timer.do_for(2, function(dt)
				s = s + dt / 2
				g.pos = init + delta * s
			end, function()
				g.undead_but_dead = false
			end)
		elseif hit then
			-- TODO: play sound
			you_lose()
			return
		end
	end

	if #self.path >= 1 then
		local p0 = self.path[1][2]
		if cell.coords == p0 then
			table.remove(self.path, 1)
		end
	end

	if #self.path < 1 then
		self.path = find_path(self.pos, self.direction)
	else
		self.direction = self.path[1][1]
	end

	walk(self, self.direction, dt)
end

-- the game
function st:init()
	local w,h = Image.manpac.ghost:getWidth(), Image.manpac.ghost:getHeight()
	local g = anim8.newGrid(w/2,h, w,h)
	Ghost.anim = anim8.newAnimation('loop', g('1-2,1'), 0.1)
end

function st:enter()
	Level.grid = (function(str)
		Level.pills = 0
		local grid = {}
		for l in str:gmatch('[^\n]+') do
			local row = {}
			for c in l:gmatch('.') do
				row[#row+1] = c
			end
			grid[#grid+1] = row
		end

		Level.tilesize = vector(love.graphics.getWidth() / #grid[1], love.graphics.getHeight() / #grid)

		for i = 1,#grid do
			local row = grid[i]
			for k = 1,#row do
				if row[k] == ' ' or row[k] == '.' or row[k] == 'o' then
					local t = Level.floor(k,i, row[k] == '.', row[k] == 'o')
					Level.pills = Level.pills + (t.pill and 1 or 0)
					row[k] = t
				else
					row[k] = Level.wall(k,i, row[k])
				end
			end
		end

		for y = 13,17 do
			for x = 11,18 do
				grid[y][x].house = true
			end
		end

		return grid
	end)[[
j^^^^^^^^^^^^^^^^^^^^^^^^^^k
<............78............>
<.7NN8.7NNN8.||.7NNN8.7NN8.>
<o|  |.|   |.||.|   |.|  |o>
<.UNNI.UNNNI.UI.UNNNI.UNNI.>
<..........................>
<.7NN8.78.7NNNNNN8.78.7NN8.>
<.UNNI.||.UNNNNNNI.||.UNNI.>
<......||....78....||......>
u____s.|UNN8 || 7NNI|.a____i
     <.|7NNI UI UNN8|.>     
     <.||          ||.>     
     <.|| 1__  __2 ||.>     
     <.UI >      < UI.>     
     <.   >      <   .>     
     <.78 >      < 78.>     
     <.|| 3^^^^^^4 ||.>     
     <.||          ||.>     
     <.|| 7NNNNNN8 ||.>     
j^^^^w.UI UNN87NNI UI.q^^^^k
<............||............>
<.7NN8.7NNN8.||.7NNN8.7NN8.>
<oUN8|.UNNNI.UI.UNNNI.|7NIo>
<...||.......  .......||...>
tN8.||.78.7NNNNNN8.78.||.7Ng
yNI.UI.||.UNN87NNI.||.UI.UNh
<......||....||....||......>
<.7NNNNIUNN8.||.7NNIUNNNN8.>
<.UNNNNNNNNI.UI.UNNNNNNNNI.>
<..........................>
u__________________________i
]]


	ghosts = {
		playercontrol = 1,
		start_when_npills = {244,244*.9,244*.6,244*.3},
		Ghost(14.5,12),
		Ghost(14.4,15),
		Ghost(12.5,15),
		Ghost(16.3,15),
	}
	manpac = ManPac(14.5,24)

	local w,h = Image.manpac.ghost:getWidth(), Image.manpac.ghost:getHeight()
	Ghost.center = vector(w/2, h) / 2
	Ghost.scale  = Level.tilesize:permul(vector(2/w, 1/h)) * 1.3
	Ghost.mode   = 'scatter'
	Ghost.toggle_timer = Timer.new()
	Ghost.toggle_timer:addPeriodic(7, function()
		if Ghost.mode == 'chase' then
			Ghost.mode = 'scatter'
			for _,g in ipairs(ghosts) do
				g.scatter_target = vector(math.random(#Level.grid[1]), math.random(#Level.grid))
			end
		else
			Ghost.mode = 'chase'
		end
	end)
end

function st:update(dt)
	if Level.pills <= 0 then return end

	Ghost.anim:update(dt)
	Ghost.toggle_timer:update(dt)

	local ghosts_in_house = false
	for i,g in ipairs(ghosts) do
		ghosts_in_house = ghosts_in_house or g:inHouse()
		if Level.pills <= ghosts.start_when_npills[i] then
			Level.cell(g.pos).has_ghost = false
			if i == ghosts.playercontrol then
				g:updatePlayer(dt)
			else
				g:updateAI(dt)
			end
			Level.cell(g.pos).has_ghost = true
		end
	end

	if not ghosts_in_house and Level.grid[13][14].walkable then
		Level.grid[13][14] = Level.wall(14,13,'-')
		Level.grid[13][15] = Level.wall(15,13,'-')
	elseif ghosts_in_house and not Level.grid[13][14].walkable then
		Level.grid[13][14] = Level.floor(14,13)
		Level.grid[13][15] = Level.floor(15,13)
	end

	manpac:update(dt)

	if Level.pills <= 0 then
		GS.transition(State.menu, .5)
	end
end

function st:draw()
	Level.draw()
	manpac:draw()

	for i,g in ipairs(ghosts) do
		g:draw(i, i == ghosts.playercontrol)
	end
end

function st:keypressed(key)
	if key == 'tab' then
		ghosts.playercontrol = (ghosts.playercontrol % #ghosts) + 1
	end
end

return st
