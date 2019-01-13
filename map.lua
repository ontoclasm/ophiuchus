local map = {}

function map:new(w, h)
	o = {width = w, height = h}
	setmetatable(o, self)
	self.__index = self

	for x=1, w do
		o[x] = {}
		for y=1, h do
			o[x][y] = {block = "void", hp = 0}
		end
	end

	return o
end

function map.grid_at_pos(px)
	return math.floor(px / img.tile_size)
end

function map.bounding_box(x, y)
	return {x = img.tile_size * (x + 0.5), y = img.tile_size * (y + 0.5), half_w = img.tile_size / 2, half_h = img.tile_size / 2}
end

function map.orth_normal_to_dir(nx, ny)
	if nx == 1 then return 'r' end
	if nx == -1 then return 'l' end
	if ny == 1 then return 'd' end
	if ny == -1 then return 'u' end
end

function map:in_bounds(x, y)
	return x >= 1 and x <= self.width and y >= 1 and y <= self.height
end

function map:set_block(block, x, y)
	if self:in_bounds(x, y) then
		self[x][y].block = block
		self[x][y].hp = block_data[block].hp
	end
end

function map:set_block_rect(block, x, y, w, h)
	for i = x, x + w - 1 do
		for j = y, y + h - 1 do
			self:set_block(block, i, j)
		end
	end
end

function map:fill_main()
	self:set_block_rect("air", 1, 1, self.width, self.height)
	self:set_block_rect("wall", 5, 13, self.width - 8, 1)
	local w = 3
	-- for i = 1, 5 do
	-- 	w = love.math.random(3,16)
	-- 	self:set_block_rect("wall", love.math.random(1,self.width) - math.floor(w/2), love.math.random(1,self.height - 4), w, 1)
	-- end

	-- debug stuff
	self:set_block("slope_45", 26, 12)
	self:set_block("slope_45", 27, 11)
	self:set_block("slope_45", 28, 10)
	self:set_block_rect("wall", 29, 10, 3, 3)
	self:set_block("slope_-45", 32, 10)
	self:set_block("slope_-45", 33, 11)
	self:set_block("slope_-45", 34, 12)

	self:set_block("slope_45_a", 8, 12)
	self:set_block("slope_45_a", 9, 11)
	self:set_block("slope_45_a", 10, 10)
	self:set_block("slope_45_b", 9, 12)
	self:set_block("slope_45_b", 10, 11)
	self:set_block("slope_45_b", 11, 10)
	self:set_block("slope_-45_a", 15, 12)
	self:set_block("slope_-45_a", 14, 11)
	self:set_block("slope_-45_a", 13, 10)
	self:set_block("slope_-45_b", 14, 12)
	self:set_block("slope_-45_b", 13, 11)
	self:set_block("slope_-45_b", 12, 10)

	self:set_block_rect("wall", 19, 10, 1, 7)

	self:set_block("islope_-45", 26, 1)
	self:set_block("islope_-45", 27, 2)
	self:set_block("islope_-45", 28, 3)
	self:set_block_rect("wall", 29, 1, 3, 3)
	self:set_block("islope_45", 32, 3)
	self:set_block("islope_45", 33, 2)
	self:set_block("islope_45", 34, 1)

	-- self:set_block("slope_23_a", 26, 12)
	-- self:set_block("slope_23_a", 28, 11)
	-- self:set_block("slope_23_a", 30, 10)
	-- self:set_block("slope_23_b", 27, 12)
	-- self:set_block("slope_23_b", 29, 11)
	-- self:set_block("slope_23_b", 31, 10)
	-- self:set_block("slope_-23_a", 37, 12)
	-- self:set_block("slope_-23_a", 35, 11)
	-- self:set_block("slope_-23_a", 33, 10)
	-- self:set_block("slope_-23_b", 36, 12)
	-- self:set_block("slope_-23_b", 34, 11)
	-- self:set_block("slope_-23_b", 32, 10)

	self.death_line = (self.height - 1) * 32 -- this is two blocks above the bottom
end

function map:fill_z()
	for x = 1, self.width do
		for y = 1, self.height do
			if (x == 1 and y <= 4) or y == 4 or (x == 7 and y >= 4) then
				self:set_block("wall", x, y)
			end
		end
	end
end

function map:block_at(x, y)
	if not self:in_bounds(x, y) then
		return "void" -- the void
	else
		return self[x][y].block
	end
end

function map:grid_has_collision(x, y)
	return block_data[self:block_at(x,y)].collision_type ~= "empty"
end

local collision_type
function map:grid_blocks_dir(x, y, dir)
	collision_type = block_data[self:block_at(x,y)].collision_type
	if collision_type == 'empty' then
		return false
	elseif collision_type == 'solid' then
		return true
	elseif collision_type == 'slope' then
		return block_data[self:block_at(x,y)].collision_dirs[dir]
	end
end

local gx, gy, slope
function map:can_stand_on_pos(px, py)
	gx, gy = map.grid_at_pos(px), map.grid_at_pos(py)
	collision_type = block_data[self:block_at(gx,gy)].collision_type
	if collision_type == 'empty' then
		return false
	elseif collision_type == 'solid' then
		return true
	elseif collision_type == 'slope' then
		-- kill me
		slope = block_data[self:block_at(gx, gy)].slope
		if slope then
			return py + 1 >= slope * (px - img.tile_size * (gx + 0.5)) + img.tile_size * (gy + 0.5) + block_data[self:block_at(gx, gy)].slope_y_offset
		end
	end
	return false
end

function map:hurt_block(x, y, damage)
	if block_data[self:block_at(x,y)].breakable then
		self[x][y].hp = math.max(0, self[x][y].hp - damage)
		if self[x][y].hp == 0 then
			self:destroy_block(x,y)
		end
		redraw = true
	end
end

function map:destroy_block(x, y)
	self:set_block("air", x, y)
	for i=1,10 do
		angle = love.math.random() * math.pi * 2
		v = 200 + 200 * love.math.random()
		spark_data.spawn("spark_s", color.white, img.tile_size * (x + love.math.random()), img.tile_size * (y + love.math.random()),
						 v * math.cos(angle), v * math.sin(angle), 0, 1, 1)
	end
	for i=1,4 do
		angle = love.math.random() * math.pi * 2
		v = 200 + 200 * love.math.random()
		spark_data.spawn("chunk_s", color.white, img.tile_size * (x + love.math.random()), img.tile_size * (y + love.math.random()),
						 v * math.cos(angle), v * math.sin(angle), 0, 1, 1)
	end
	for i=1,2 do
		angle = love.math.random() * math.pi * 2
		v = 200 + 200 * love.math.random()
		spark_data.spawn("chunk_m", color.white, img.tile_size * (x + love.math.random()), img.tile_size * (y + love.math.random()),
						 v * math.cos(angle), v * math.sin(angle), 0, 1, 1)
	end
end

function map:print(m, px, py)
	-- draw the data from the map m onto self at grid (px,py)
	for x = 1, m.width do
		for y = 1, m.height do
			if self:in_bounds(px + x - 1, py + y - 1) and m[x][y].block ~= "void" then
				self[px + x - 1][py + y - 1].block = m[x][y].block
				self[px + x - 1][py + y - 1].hp = m[x][y].hp
			end
		end
	end
	redraw = true
end

function map:tileframe_at(x,y)
	if block_data[self:block_at(x,y)].breakable then
		local hp = self[x][y].hp
		local max_hp = block_data[self:block_at(x,y)].hp
		if hp > max_hp * 0.6667 then return 1
		elseif hp > max_hp * 0.3334 then return 2
		else return 3
		end
	else
		return 1
	end
end

return map
