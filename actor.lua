local actor = {}

function actor:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function actor:update(dt)
	self:update_controls(dt)
	self:update_location(dt)
end

function actor:update_controls(dt)
	if self.ai.control == "player" then
		controls.process(self)
	elseif self.ai.control == "enemy" then
		ai.process(self)
	end
end

local hit
local block_type
function actor:update_location(dt)
	-- separate out the integer part of our motion
	if self.controls.x ~= 0 then
		self.dx = self.dx + self.controls.x * self.walk_accel * dt
	elseif self.dx > 0 then
		self.dx = math.max(0, self.dx - self.walk_friction * dt)
	elseif self.dx < 0 then
		self.dx = math.min(0, self.dx + self.walk_friction * dt)
	end

	if self.controls.jump then
		self.dy = -self.jump_speed
	else
		grounded = physics.map_collision_aabb_sweep(self, 0, 1)
		if not grounded then
			self.dy = self.dy + gravity * dt
		-- else
		-- 	self.dy = self.dy + 0.5 * gravity * dt
		end
	end

	self.dx = mymath.clamp(-self.top_speed, self.dx, self.top_speed)
	-- self.dy = mymath.clamp(-self.top_speed, self.dy, self.top_speed)

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
