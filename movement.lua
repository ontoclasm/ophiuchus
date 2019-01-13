local movement = {}


function movement.update()
	for k,mov in pairs(c_movements) do
		movement[mov.kind](k, mov)
	end
end

local hit, pos, controls, vx, vy
function movement.walker(k, mov)
	pos = c_positions[k]

	-- apply controls if they exist
	controls = c_controls[k]
	dx_goal = controls and controls.x or 0

	-- jump if necessary
	if controls and mov.grounded and controls.y ~= 0 then
		mov.grounded = false
		mov.jumping = true -- while going upwards we can't become grounded
		mov.dy = -0.5
	elseif not mov.jumping then
		-- check for groundedness
		if not mov.grounded then
			if movement.touching_down(pos) then
				-- landed just now
				mov.grounded = true
				if c_drawables[k] then
					c_drawables[k].flash_time = game_frame + 20
				end
			end
		else
			mov.grounded = movement.touching_down(pos)
		end
	end

	-- check adjacent walls
	mov.touching_left = movement.touching_left(pos)
	mov.touching_right = movement.touching_right(pos)

	if mov.grounded then
		-- on ground

		-- xxx use abs_subtract?
		if mov.dx >= dx_goal then
			mov.dx = math.max(dx_goal, mov.dx - mov.accel)
		else
			mov.dx = math.min(dx_goal, mov.dx + mov.accel)
		end

		if mov.dx > 0 and mov.touching_right then
			mov.dx = 0
		elseif mov.dx < 0 and mov.touching_left then
			mov.dx = 0
		end

		mov.dy = 0
		mov.jumping = false

		mov.dx_acc = mov.dx_acc + mov.dx * mov.speed
		vx = mymath.abs_floor(mov.dx_acc)
		mov.dx_acc = mov.dx_acc - vx

		-- move pixel by pixel i guess
		sign = mymath.sign(vx)
		vx = math.abs(vx)

		stuck = false
		while vx > 0 and stuck == false do
			-- first try sliding down, then straight, then up
			hit = physics.map_collision_aabb_sweep(pos, sign, 1)
			if not hit then
				pos.x = pos.x + sign
				pos.y = pos.y + 1
			else
				hit = physics.map_collision_aabb_sweep(pos, sign, 0)
				if not hit then
					pos.x = pos.x + sign
				else
					hit = physics.map_collision_aabb_sweep(pos, sign, -1)
					if not hit then
						pos.x = pos.x + sign
						pos.y = pos.y - 1
					else
						-- welp
						stuck = true
					end
				end
			end
			vx = vx - 1
		end
	else
		-- in air

		-- xxx use abs_subtract?
		if mov.dx >= dx_goal then
			mov.dx = math.max(dx_goal, mov.dx - mov.air_accel)
		else
			mov.dx = math.min(dx_goal, mov.dx + mov.air_accel)
		end

		if mov.dx > 0 and mov.touching_right then
			mov.dx = 0
		elseif mov.dx < 0 and mov.touching_left then
			mov.dx = 0
		end

		-- apply gravity
		if mov.dy >= 1 then
			mov.dy = math.max(1, mov.dy - 0.02)
		else
			mov.dy = math.min(1, mov.dy + 0.02)
		end

		if mov.jumping and mov.dy >= 0 then
			mov.jumping = false
		end

		-- calculate how far to move this frame
		-- cut off the fractional part; we'll re-add it next frame
		mov.dx_acc = mov.dx_acc + mov.dx * mov.speed
		mov.dy_acc = mov.dy_acc + mov.dy * gravity
		vx, vy = mymath.abs_floor(mov.dx_acc), mymath.abs_floor(mov.dy_acc)
		mov.dx_acc = mov.dx_acc - vx
		mov.dy_acc = mov.dy_acc - vy

		-- collide with the map tiles we're inside
		-- should return ONLY INTEGERS for mx,my
		hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(pos, vx, vy)

		if hit then
			-- change our vector based on the slope we hit
			r = mov.dx * ny - mov.dy * nx

			mov.dx = r * ny
			mov.dy = r * (-nx)
		end

		pos.x = mx
		pos.y = my

		-- sometimes we hit a slope but aren't on the ground because of the angle; if so we need to drop a pixel
		-- XXX do we still need this?
		if hit and ny ~= 1 and ny ~= 0 then
			hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(pos, 0, 1)
			if not hit then
				pos.y = pos.y + 1
			end
		end
	end

	if not mov.jumping then
		-- check if we're now on the ground
		if not mov.grounded then
			if movement.touching_down(pos) then
				-- landed just now
				mov.grounded = true
				if c_drawables[k] then
					c_drawables[k].flash_time = game_frame + 20
				end
			end
		else
			mov.grounded = movement.touching_down(pos)
		end
	end
end

local mx, my, m_time, nx, ny
function movement.projectile(k, mov)
	pos = c_positions[k]

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	mov.dx_acc = mov.dx_acc + mov.dx * mov.speed
	mov.dy_acc = mov.dy_acc + mov.dy * mov.speed
	vx, vy = mymath.abs_floor(mov.dx_acc), mymath.abs_floor(mov.dy_acc)
	mov.dx_acc = mov.dx_acc - vx
	mov.dy_acc = mov.dy_acc - vy

	hit = nil
	if mov.collides_with_map then
		-- collide with the map tiles we're inside
		-- should return ONLY INTEGERS for mx,my
		hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(pos, vx, vy)
	end

	if not hit then
		pos.x = pos.x + vx
		pos.y = pos.y + vy
	else
		pos.x = mx
		pos.y = my
		if hit[1] == "block" and mainmap:block_at(hit[2], hit[3]) == "void" then
			-- oob
			movement.collision_responses.vanish(k, mov, hit, mx, my, nx, ny)
		elseif mov.collision_response then
			-- react to the collision
			movement.collision_responses[mov.collision_response](k, mov, hit, mx, my, nx, ny)
		end
	end
end

function movement.touching_up(a)
	return physics.map_collision_aabb({x = a.x, y = a.y - a.half_h, half_w = a.half_w, half_h = 1, slope_inset = a.slope_inset})
end

function movement.touching_down(a)
	return physics.map_collision_aabb({x = a.x, y = a.y + a.half_h, half_w = a.half_w, half_h = 1, slope_inset = a.slope_inset})
end

function movement.touching_left(a)
	-- reduce height by 1 pixel in order to ignore slopes
	return physics.map_collision_aabb({x = a.x - a.half_w, y = a.y - 0.5, half_w = 1, half_h = a.half_h - 1, slope_inset = a.slope_inset})
end

function movement.touching_right(a)
	return physics.map_collision_aabb({x = a.x + a.half_w, y = a.y - 0.5, half_w = 1, half_h = a.half_h - 1, slope_inset = a.slope_inset})
end

----

movement.collision_responses = {}

function movement.collision_responses.pop(k, mov, hit, mx, my, nx, ny)
	local angle
	for n = 1, 5 do
		angle = mymath.random_spread(math.atan2(ny, nx), PI/3)
		ecs.spawn_particle(kind, mx, my, math.cos(angle), math.sin(angle), 1 + love.math.random() * 4, 4 + love.math.random(6))
	end
	ecs.delete_entity(k)
end

function movement.collision_responses.vanish(k, mov, hit, mx, my, nx, ny)
	ecs.delete_entity(k)
end

function movement.collision_responses.bounce(k, mov, hit, mx, my, nx, ny)
	-- reflect off, maybe
	-- chance is based on the angle of incidence
	local dot = mov.dy * ny + mov.dx * nx
	-- if (love.math.random() * math.pi) < 2 * math.abs(math.acos(dot / mymath.vector_length(self.dx, self.dy)) - math.pi) - 0.2 then
		mov.dx = (mov.dx - 2 * dot * nx)
		mov.dy = (mov.dy - 2 * dot * ny)
	-- else
	-- 	mainmap:hurt_block(hit[2], hit[3], self.damage)
	-- 	self:die()
	-- 	audio.play('hit2')
	-- end
end

return movement
