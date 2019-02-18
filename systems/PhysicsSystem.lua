local PhysicsSystem = tiny.processingSystem(class "PhysicsSystem")

PhysicsSystem.filter = tiny.requireAll("pos", "vel")

local dx_goal, dy_goal
local hit_x, hit_y, hit_time, nx, ny, other_pos
COARSE_GRID_SIZE = 64
local other_pos_coarse = {half_h = COARSE_GRID_SIZE, half_w = COARSE_GRID_SIZE}
local hit_list = {}
local already_applied_hits = {}
local already_applied = false

function PhysicsSystem:preProcess(dt)
	already_applied_hits = {}
end

function PhysicsSystem:process(e, dt)
	if e.controls and e.walker then
		dx_goal = e.controls and e.controls.move_x * e.walker.top_speed or 0
		dy_goal = e.controls and e.controls.move_y * e.walker.top_speed or 0

		-- check adjacent walls
		-- e.vel.touching_up = movement.touching_up(pos)
		-- e.vel.touching_down = movement.touching_down(pos)
		-- e.vel.touching_left = movement.touching_left(pos)
		-- e.vel.touching_right = movement.touching_right(pos)

		-- xxx use abs_subtract?
		if e.vel.dx >= dx_goal then
			e.vel.dx = math.max(dx_goal, e.vel.dx - e.walker.accel)
		else
			e.vel.dx = math.min(dx_goal, e.vel.dx + e.walker.accel)
		end

		-- if e.vel.dx > 0 and e.vel.touching_right then
		-- 	e.vel.dx = 0
		-- elseif e.vel.dx < 0 and e.vel.touching_left then
		-- 	e.vel.dx = 0
		-- end

		if e.vel.dy >= dy_goal then
			e.vel.dy = math.max(dy_goal, e.vel.dy - e.walker.accel)
		else
			e.vel.dy = math.min(dy_goal, e.vel.dy + e.walker.accel)
		end

		-- if e.vel.dy > 0 and e.vel.touching_down then
		-- 	e.vel.dy = 0
		-- elseif e.vel.dy < 0 and e.vel.touching_up then
		-- 	e.vel.dy = 0
		-- end
	end

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	e.vel.dx_acc = e.vel.dx_acc + e.vel.dx
	e.vel.dy_acc = e.vel.dy_acc + e.vel.dy
	idx, idy = mymath.abs_floor(e.vel.dx_acc), mymath.abs_floor(e.vel.dy_acc)
	e.vel.dx_acc = e.vel.dx_acc - idx
	e.vel.dy_acc = e.vel.dy_acc - idy

	if e.collides then
		hit_list = {}

		if e.collides.map then
			-- get map hits
			collision.map_collision_aabb_sweep(e.pos, idx, idy, hit_list)
		end

		if e.collides.entity_filter then
			for _, other_e in pairs(self.entities) do
				if other_e.collides and e.collides.entity_filter(other_e) then
					other_pos_coarse.x, other_pos_coarse.y = other_e.pos.x, other_e.pos.y
					-- first check if we're anywhere near it, then actually do the sweep. XXX useful or not?
					if collision.collision_aabb_aabb(e.pos, other_pos_coarse) then
						hit = collision.collision_aabb_sweep(e.pos, other_e.pos, idx, idy)
						if hit then
							hit.object = {kind = "entity", entity = other_e}
							hit_list[#hit_list + 1] = hit
						end
					end
				end
			end
		end

		if #hit_list == 0 then
			-- didn't hit anything; just fly free, man
			e.pos.x = e.pos.x + idx
			e.pos.y = e.pos.y + idy
		else
			-- sort by impact time
			table.sort(hit_list, function(hit_1, hit_2) return hit_1.time < hit_2.time end)
			local stop = false

			for _, hit in ipairs(hit_list) do
				if hit.object.kind == "entity" then
					already_applied = false
					for i,v in ipairs(already_applied_hits) do
						if v[1] == hit.object.entity.id and v[2] == e.id then
							-- we already did this one
							already_applied = true
							break
						end
					end

					stop = e.collides.collide_with_entity(hit, already_applied)
					if not already_applied then
						table.insert(already_applied_hits, {e.id, hit.object.entity.id})
						hit.object.entity.collides.get_collided_with(e, hit)
					end
				else
					stop = e.collides.collide_with_map(hit)
				end

				if stop then
					-- we hit something solid, so ignore later collisions
					break
				end
			end

			if not stop then
				-- we passed through everything
				e.pos.x = e.pos.x + idx
				e.pos.y = e.pos.y + idy
			end
			-- if m_hit[1] == "block" and mainmap:block_at(m_hit[2], m_hit[3]) == "void" then
			-- 	-- oob
			-- 	movement.collision_responses.vanish(k)
			-- elseif e.vel.collision_response then
			-- 	-- react to the collision
			-- 	idx, idy = mymath.normalize(idx, idy)
			-- 	movement.collision_responses[e.vel.collision_response](k, mov, m_hit, m_hit_x, m_hit_y, idx, idy, m_nx, m_ny)
			-- end
		end
	else
		e.pos.x = e.pos.x + idx
		e.pos.y = e.pos.y + idy
	end
end

return PhysicsSystem
