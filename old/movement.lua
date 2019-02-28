local movement = {}


function movement.update()
	for k,mov in pairs(c_movements) do
		movement[mov.kind](k, mov)
	end
end

local m_hit, pos, controls, idx, idy
function movement.walker(k, mov)
	wd = mov.walker_data
	pos = c_positions[k]

	-- apply controls if they exist
	controls = c_controls[k]
	dx_goal = controls and controls.move_x * wd.top_speed or 0
	dy_goal = controls and controls.move_y * wd.top_speed or 0

	-- check adjacent walls
	-- mov.touching_up = movement.touching_up(pos)
	-- mov.touching_down = movement.touching_down(pos)
	-- mov.touching_left = movement.touching_left(pos)
	-- mov.touching_right = movement.touching_right(pos)

	-- xxx use abs_subtract?
	if mov.dx >= dx_goal then
		mov.dx = math.max(dx_goal, mov.dx - wd.accel)
	else
		mov.dx = math.min(dx_goal, mov.dx + wd.accel)
	end

	-- if mov.dx > 0 and mov.touching_right then
	-- 	mov.dx = 0
	-- elseif mov.dx < 0 and mov.touching_left then
	-- 	mov.dx = 0
	-- end

	if mov.dy >= dy_goal then
		mov.dy = math.max(dy_goal, mov.dy - wd.accel)
	else
		mov.dy = math.min(dy_goal, mov.dy + wd.accel)
	end

	-- if mov.dy > 0 and mov.touching_down then
	-- 	mov.dy = 0
	-- elseif mov.dy < 0 and mov.touching_up then
	-- 	mov.dy = 0
	-- end

	mov.dx_acc = mov.dx_acc + mov.dx
	idx = mymath.abs_floor(mov.dx_acc)
	mov.dx_acc = mov.dx_acc - idx
	mov.dy_acc = mov.dy_acc + mov.dy
	idy = mymath.abs_floor(mov.dy_acc)
	mov.dy_acc = mov.dy_acc - idy

	if idx == 0 and idy == 0 then
		return
	end

	-- move pixel by pixel i guess
	sign_x = mymath.sign(idx)
	idx = math.abs(idx)
	sign_y = mymath.sign(idy)
	idy = math.abs(idy)

	stuck = false
	if idx >= idy then
		while idx > 0 and stuck == false do
			if idy > 0 then
				-- diagonal
				-- first try moving diag, then right, then up
				m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, sign_y)
				if not m_hit then
					pos.x = pos.x + sign_x
					pos.y = pos.y + sign_y
				else
					m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, 0)
					if not m_hit then
						pos.x = pos.x + sign_x
					else
						m_hit = physics.map_collision_aabb_sweep_test(pos, 0, sign_y)
						if not m_hit then
							pos.y = pos.y + sign_y
						else
							-- welp
							stuck = true
						end
					end
				end
				idx = idx - 1
				idy = idy - 1
			else
				-- cardinal
				-- first try moving straight, then up, then down
				m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, 0)
				if not m_hit then
					pos.x = pos.x + sign_x
				else
					m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, -1)
					if not m_hit then
						pos.x = pos.x + sign_x
						pos.y = pos.y - 1
					else
						m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, 1)
						if not m_hit then
							pos.x = pos.x + sign_x
							pos.y = pos.y + 1
						else
							-- welp
							stuck = true
						end
					end
				end
				idx = idx - 1
			end
		end
	else
		while idy > 0 and stuck == false do
			if idx > 0 then
				-- diagonal
				-- first try moving diag, then right, then up
				m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, sign_y)
				if not m_hit then
					pos.x = pos.x + sign_x
					pos.y = pos.y + sign_y
				else
					m_hit = physics.map_collision_aabb_sweep_test(pos, sign_x, 0)
					if not m_hit then
						pos.x = pos.x + sign_x
					else
						m_hit = physics.map_collision_aabb_sweep_test(pos, 0, sign_y)
						if not m_hit then
							pos.y = pos.y + sign_y
						else
							-- welp
							stuck = true
						end
					end
				end
				idy = idy - 1
				idx = idx - 1
			else
				-- cardinal
				-- first try moving straight, then left, then right
				m_hit = physics.map_collision_aabb_sweep_test(pos, 0, sign_y)
				if not m_hit then
					pos.y = pos.y + sign_y
				else
					m_hit = physics.map_collision_aabb_sweep_test(pos, -1, sign_y)
					if not m_hit then
						pos.y = pos.y + sign_y
						pos.x = pos.x - 1
					else
						m_hit = physics.map_collision_aabb_sweep_test(pos, 1, sign_y)
						if not m_hit then
							pos.y = pos.y + sign_y
							pos.x = pos.x + 1
						else
							-- welp
							stuck = true
						end
					end
				end
				idy = idy - 1
			end
		end
	end
end

local hit_x, hit_y, hit_time, nx, ny, other_pos
COARSE_GRID_SIZE = 64
local other_pos_coarse = {half_h = COARSE_GRID_SIZE, half_w = COARSE_GRID_SIZE}
local hit_list = {}
function movement.projectile(k, mov)
	pd = mov.projectile_data
	pos = c_positions[k]

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	mov.dx_acc = mov.dx_acc + mov.dx
	mov.dy_acc = mov.dy_acc + mov.dy
	idx, idy = mymath.abs_floor(mov.dx_acc), mymath.abs_floor(mov.dy_acc)
	mov.dx_acc = mov.dx_acc - idx
	mov.dy_acc = mov.dy_acc - idy

	hit_list = {}

	if pd.collides_with_map then
		-- get map hits
		physics.map_collision_aabb_sweep(pos, idx, idy, hit_list)
	end

	if pd.collides_with_hitboxes then
		for j, hitbox in pairs(c_hitboxes) do
			-- XXX ask j if we can hit them? they should be immune to projectiles that hit them recently
			-- or: keep track of what we've hit recently and ignore those
			if hitbox.alignment == "enemy" then
				other_pos = c_positions[j]
				other_pos_coarse.x, other_pos_coarse.y = other_pos.x, other_pos.y
				-- first check if we're anywhere near it, then actually do the sweep. XXX useful or not?
				if physics.collision_aabb_aabb(pos, other_pos_coarse) then
					hit = physics.collision_aabb_sweep(pos, other_pos, idx, idy)
					if hit then
						hit.object = {kind = "hitbox", id = j}
						hit_list[#hit_list + 1] = hit
					end
				end
			end
		end
	end

	if #hit_list == 0 then
		-- didn't hit anything; just fly free, man
		pos.x = pos.x + idx
		pos.y = pos.y + idy
	else
		-- sort by impact time
		table.sort(hit_list, function(hit_1, hit_2) return hit_1.time < hit_2.time end)
		local stop = false

		for i = 1, #hit_list do
			hit = hit_list[i]

			-- to do: tell the object we hit it.
			-- tell k that it hit the object, and have it return whether to stop.

			stop = collisions.collide(k, hit)

			if stop then
				-- we hit something solid, so ignore later collisions
				break
			end
		end

		if not stop then
			-- we passed through everything
			pos.x = pos.x + idx
			pos.y = pos.y + idy
		end
		-- if m_hit[1] == "block" and mainmap:block_at(m_hit[2], m_hit[3]) == "void" then
		-- 	-- oob
		-- 	movement.collision_responses.vanish(k)
		-- elseif mov.collision_response then
		-- 	-- react to the collision
		-- 	idx, idy = mymath.normalize(idx, idy)
		-- 	movement.collision_responses[mov.collision_response](k, mov, m_hit, m_hit_x, m_hit_y, idx, idy, m_nx, m_ny)
		-- end
	end
end

function movement.knockback(k, mov)
	-- slow down
	local new_len = math.max(0, mymath.vector_length(mov.dx, mov.dy) - mov.knockback_data.decel)

	if new_len == 0 then
		if not mov.kb_end_frame then
			mov.kb_end_frame = gamestate.game_frame + 20
		elseif mov.kb_end_frame <= gamestate.game_frame then
			-- done being knocked
			mov.kind = "walker"
			c_drawables[k].color = color.ltblue
		end
	else
		mov.kb_end_frame = nil
	end

	pos = c_positions[k]
	pd = mov.projectile_data
	mov.dx, mov.dy = mymath.set_vector_length(mov.dx, mov.dy, new_len)

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	mov.dx_acc = mov.dx_acc + mov.dx
	mov.dy_acc = mov.dy_acc + mov.dy
	idx, idy = mymath.abs_floor(mov.dx_acc), mymath.abs_floor(mov.dy_acc)
	mov.dx_acc = mov.dx_acc - idx
	mov.dy_acc = mov.dy_acc - idy

	hit_list = {}

	if pd.collides_with_map then
		-- get map hits
		physics.map_collision_aabb_sweep(pos, idx, idy, hit_list)
	end

	if pd.collides_with_hitboxes then
		for j, hitbox in pairs(c_hitboxes) do
			-- XXX ask j if we can hit them? they should be immune to projectiles that hit them recently
			-- or: keep track of what we've hit recently and ignore those
			if hitbox.alignment == "enemy" then
				other_pos = c_positions[j]
				other_pos_coarse.x, other_pos_coarse.y = other_pos.x, other_pos.y
				-- first check if we're anywhere near it, then actually do the sweep. XXX useful or not?
				if physics.collision_aabb_aabb(pos, other_pos_coarse) then
					hit = physics.collision_aabb_sweep(pos, other_pos, idx, idy)
					if hit then
						hit.object = {kind = "hitbox", id = j}
						hit_list[#hit_list + 1] = hit
					end
				end
			end
		end
	end

	if #hit_list == 0 then
		-- didn't hit anything; just fly free, man
		pos.x = pos.x + idx
		pos.y = pos.y + idy
	else
		-- sort by impact time
		table.sort(hit_list, function(hit_1, hit_2) return hit_1.time < hit_2.time end)
		local stop = false

		for i = 1, #hit_list do
			hit = hit_list[i]

			-- to do: tell the object we hit it.
			-- tell k that it hit the object, and have it return whether to stop.

			stop = collisions.collide(k, hit)

			if stop then
				-- we hit something solid, so ignore later collisions
				break
			end
		end

		if not stop then
			-- we passed through everything
			pos.x = pos.x + idx
			pos.y = pos.y + idy
		end
		-- if m_hit[1] == "block" and mainmap:block_at(m_hit[2], m_hit[3]) == "void" then
		-- 	-- oob
		-- 	movement.collision_responses.vanish(k)
		-- elseif mov.collision_response then
		-- 	-- react to the collision
		-- 	idx, idy = mymath.normalize(idx, idy)
		-- 	movement.collision_responses[mov.collision_response](k, mov, m_hit, m_hit_x, m_hit_y, idx, idy, m_nx, m_ny)
		-- end
	end
end

function movement.touching_up(a)
	return physics.map_collision_aabb({x = a.x, y = a.y - a.half_h, half_w = a.half_w, half_h = 1})
end

function movement.touching_down(a)
	return physics.map_collision_aabb({x = a.x, y = a.y + a.half_h, half_w = a.half_w, half_h = 1})
end

function movement.touching_left(a)
	return physics.map_collision_aabb({x = a.x - a.half_w, y = a.y, half_w = 1, half_h = a.half_h})
end

function movement.touching_right(a)
	return physics.map_collision_aabb({x = a.x + a.half_w, y = a.y, half_w = 1, half_h = a.half_h})
end

----

-- movement.collision_responses = {}

-- function movement.collision_responses.pop(k, mov, hit, mx, my, dx, dy, nx, ny)
-- 	if hit[1] == "hitbox" then
-- 		if c_drawables[hit[2]] then
-- 			c_drawables[hit[2]].flash_end_frame = gamestate.game_frame + 20
-- 		end

-- 		local mov = c_movements[hit[2]]
-- 		if mov then
-- 			mov.dx = mov.dx + 2 * dx
-- 			mov.dy = mov.dy + 2 * dy
-- 		end

-- 		for n = 1, 5 do
-- 			local angle = mymath.average_angles(math.atan2(-dy, -dx), math.atan2(ny, nx))
-- 			angle = mymath.random_spread(angle, PI/3)
-- 			local speed = 1 + love.math.random() * 4
-- 			ecs.spawn_particle(kind, mx, my, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
-- 		end
-- 	else
-- 		local angle
-- 		for n = 1, 5 do
-- 			angle = mymath.random_spread(math.atan2(ny, nx), PI/3)
-- 			local speed = 1 + love.math.random() * 4
-- 			ecs.spawn_particle(kind, mx, my, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
-- 		end
-- 	end
-- 	ecs.delete_entity(k)
-- end

-- function movement.collision_responses.vanish(k, mov, hit, mx, my, dx, dy, nx, ny)
-- 	ecs.delete_entity(k)
-- end

-- function movement.collision_responses.bounce(k, mov, hit, mx, my, dx, dy, nx, ny)
-- 	-- reflect off, maybe
-- 	-- chance is based on the angle of incidence
-- 	local dot = mov.dy * ny + mov.dx * nx
-- 	-- if (love.math.random() * math.pi) < 2 * math.abs(math.acos(dot / mymath.vector_length(self.dx, self.dy)) - math.pi) - 0.2 then
-- 		mov.dx = (mov.dx - 2 * dot * nx)
-- 		mov.dy = (mov.dy - 2 * dot * ny)
-- 	-- else
-- 	-- 	mainmap:hurt_block(hit[2], hit[3], self.damage)
-- 	-- 	self:die()
-- 	-- 	audio.play('hit2')
-- 	-- end
-- end

return movement
