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
	dy_goal = controls and controls.y or 0

	-- check adjacent walls
	mov.touching_up = movement.touching_up(pos)
	mov.touching_down = movement.touching_down(pos)
	mov.touching_left = movement.touching_left(pos)
	mov.touching_right = movement.touching_right(pos)

	-- xxx use abs_subtract?
	if mov.dx >= dx_goal then
		mov.dx = math.max(dx_goal, mov.dx - mov.accel)
	else
		mov.dx = math.min(dx_goal, mov.dx + mov.accel)
	end

	-- if mov.dx > 0 and mov.touching_right then
	-- 	mov.dx = 0
	-- elseif mov.dx < 0 and mov.touching_left then
	-- 	mov.dx = 0
	-- end

	if mov.dy >= dy_goal then
		mov.dy = math.max(dy_goal, mov.dy - mov.accel)
	else
		mov.dy = math.min(dy_goal, mov.dy + mov.accel)
	end

	-- if mov.dy > 0 and mov.touching_down then
	-- 	mov.dy = 0
	-- elseif mov.dy < 0 and mov.touching_up then
	-- 	mov.dy = 0
	-- end

	mov.dx_acc = mov.dx_acc + mov.dx * mov.speed
	vx = mymath.abs_floor(mov.dx_acc)
	mov.dx_acc = mov.dx_acc - vx
	mov.dy_acc = mov.dy_acc + mov.dy * mov.speed
	vy = mymath.abs_floor(mov.dy_acc)
	mov.dy_acc = mov.dy_acc - vy

	if vx == 0 and vy == 0 then
		return
	end

	-- move pixel by pixel i guess
	sign_x = mymath.sign(vx)
	vx = math.abs(vx)
	sign_y = mymath.sign(vy)
	vy = math.abs(vy)

	stuck = false
	if vx >= vy then
		while vx > 0 and stuck == false do
			if vy > 0 then
				-- diagonal
				-- first try moving diag, then right, then up
				hit = physics.map_collision_aabb_sweep(pos, sign_x, sign_y)
				if not hit then
					pos.x = pos.x + sign_x
					pos.y = pos.y + sign_y
				else
					hit = physics.map_collision_aabb_sweep(pos, sign_x, 0)
					if not hit then
						pos.x = pos.x + sign_x
					else
						hit = physics.map_collision_aabb_sweep(pos, 0, sign_y)
						if not hit then
							pos.y = pos.y + sign_y
						else
							-- welp
							stuck = true
						end
					end
				end
				vx = vx - 1
				vy = vy - 1
			else
				-- cardinal
				-- first try moving straight, then up, then down
				hit = physics.map_collision_aabb_sweep(pos, sign_x, 0)
				if not hit then
					pos.x = pos.x + sign_x
				else
					hit = physics.map_collision_aabb_sweep(pos, sign_x, -1)
					if not hit then
						pos.x = pos.x + sign_x
						pos.y = pos.y - 1
					else
						hit = physics.map_collision_aabb_sweep(pos, sign_x, 1)
						if not hit then
							pos.x = pos.x + sign_x
							pos.y = pos.y + 1
						else
							-- welp
							stuck = true
						end
					end
				end
				vx = vx - 1
			end
		end
	else
		while vy > 0 and stuck == false do
			if vx > 0 then
				-- diagonal
				-- first try moving diag, then right, then up
				hit = physics.map_collision_aabb_sweep(pos, sign_x, sign_y)
				if not hit then
					pos.x = pos.x + sign_x
					pos.y = pos.y + sign_y
				else
					hit = physics.map_collision_aabb_sweep(pos, sign_x, 0)
					if not hit then
						pos.x = pos.x + sign_x
					else
						hit = physics.map_collision_aabb_sweep(pos, 0, sign_y)
						if not hit then
							pos.y = pos.y + sign_y
						else
							-- welp
							stuck = true
						end
					end
				end
				vy = vy - 1
				vx = vx - 1
			else
				-- cardinal
				-- first try moving straight, then left, then right
				hit = physics.map_collision_aabb_sweep(pos, 0, sign_y)
				if not hit then
					pos.y = pos.y + sign_y
				else
					hit = physics.map_collision_aabb_sweep(pos, -1, sign_y)
					if not hit then
						pos.y = pos.y + sign_y
						pos.x = pos.x - 1
					else
						hit = physics.map_collision_aabb_sweep(pos, 1, sign_y)
						if not hit then
							pos.y = pos.y + sign_y
							pos.x = pos.x + 1
						else
							-- welp
							stuck = true
						end
					end
				end
				vy = vy - 1
			end
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
	return physics.map_collision_aabb({x = a.x - a.half_w, y = a.y, half_w = 1, half_h = a.half_h, slope_inset = a.slope_inset})
end

function movement.touching_right(a)
	return physics.map_collision_aabb({x = a.x + a.half_w, y = a.y, half_w = 1, half_h = a.half_h, slope_inset = a.slope_inset})
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
