local actor = {}

function actor:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function actor:update(dt)
	if self.controls then
		self.controls:update()
	end
	self:update_location(dt)
end

local hit
local block_type
function actor:update_location(dt)
	-- separate out the integer part of our motion
	if self.controls.x ~= 0 or self.controls.y ~= 0 then
		if self.controls.x == 0 then
			if self.controls.y * self.dy < 0 then
				-- quick reverse
				self.dy = self.dy * 0.9
			end
			self.dx = mymath.abs_subtract(self.dx, self.walk_accel * dt)
			self.dy = self.dy + self.controls.y * self.walk_accel * dt
		elseif self.controls.y == 0 then
			if self.controls.x * self.dx < 0 then
				-- quick reverse
				self.dx = self.dx * 0.9
			end
			self.dx = self.dx + self.controls.x * self.walk_accel * dt
			self.dy = mymath.abs_subtract(self.dy, self.walk_accel * dt)
		else
			if self.controls.x * self.dx < 0 then
				-- quick reverse
				self.dx = self.dx * 0.9
			end
			if self.controls.y * self.dy < 0 then
				-- quick reverse
				self.dy = self.dy * 0.9
			end
			self.dx = self.dx + self.controls.x * self.walk_accel * dt * ROOT_2_OVER_2
			self.dy = self.dy + self.controls.y * self.walk_accel * dt * ROOT_2_OVER_2
		end
	else
		self.dx = mymath.abs_subtract(self.dx, self.walk_accel * dt)
		self.dy = mymath.abs_subtract(self.dy, self.walk_accel * dt)
	end

	-- slow down if we're going too fast
	local current_speed = mymath.vector_length(self.dx, self.dy)
	if current_speed > self.top_speed then
		self.dx, self.dy = mymath.set_vector_length(self.dx, self.dy, math.max(self.top_speed, current_speed - self.walk_friction * dt))
	end

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	self.dx_acc = self.dx_acc + self.dx * dt
	self.dy_acc = self.dy_acc + self.dy * dt
	vx, vy = mymath.abs_floor(self.dx_acc), mymath.abs_floor(self.dy_acc)
	if self.dx == 0 and self.dy == 0 then
		-- forget the acc
		self.dx_acc, self.dy_acc = 0, 0
	else
		self.dx_acc = self.dx_acc - vx
		self.dy_acc = self.dy_acc - vy
	end

	-- collide with the map tiles we're inside
	-- should return ONLY INTEGERS for mx,my
	hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(self, vx, vy)

	if hit then
		-- change our vector based on the slope we hit
		r = self.dx * ny - self.dy * nx

		self.dx = r * ny
		self.dy = r * (-nx)

		-- delete our accumulators if they point into the surface
		if nx ~= 0 then
			self.dx_acc = 0
		end
		if ny ~= 0 then
			self.dy_acc = 0
		end

		if m_time < 1 then
			-- try continuing our movement along the new vector
			-- if vx >= 1 and ny ~= 0 and nx < 0 then
			-- 	-- going right into a slope up and to the right
			-- 	hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = self.half_h, half_w = self.half_w},
			-- 		mymath.abs_ceil(self.dx * dt * (1 - m_time)), -mymath.abs_ceil(self.dx * dt * (1 - m_time)))
			-- elseif vx <= -1 and ny ~= 0 and nx > 0 then
			-- 	-- going left into a slope up and to the left
			-- 	hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = self.half_h, half_w = self.half_w},
			-- 		mymath.abs_ceil(self.dx * dt * (1 - m_time)), mymath.abs_ceil(self.dx * dt * (1 - m_time)))
			-- else
				hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = self.half_h, half_w = self.half_w},
																			   mymath.abs_ceil(self.dx * dt * (1 - m_time)),
																			   mymath.abs_ceil(self.dy * dt * (1 - m_time)))
			-- end

			if hit then
				r = self.dx * ny - self.dy * nx

				self.dx = r * ny
				self.dy = r * (-nx)
			end
		end
	end

	self.x = mx
	self.y = my
end

function actor:apply_status(s, dur)
	self.status[s] = dur + ctime
end

local status_complete_effect =
{
	["reload"] = function (self)
		self.weapon.ammo = self.weapon.ammo_max
	end
}

function actor:end_status(s, cancelled) -- if cancelled == true, skip the end effect
	if not cancelled then
		if status_complete_effect[s] then
			status_complete_effect[s](self)
		end
	end
	self.status[s] = nil
end

function actor:check_status(s)
	for i,v in pairs(self.status) do
		if i == s then
			if v < ctime then
				-- duration ran out
				self:end_status(s, false)
				return false
			else
				return true
			end
		end
	end
	return false
end

function actor:draw()
	if self.flash_time > ctime then
		love.graphics.setColor(color.mix(self.color, self.flash_color, 2 * (self.flash_time - ctime)))
	else
		love.graphics.setColor(self.color)
	end
	love.graphics.draw(img.tileset, img.tile[self.sprite][1],
					   camera.view_x(self) - 4, camera.view_y(self) - 4)
end

return actor
