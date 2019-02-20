local PhysicsSystem = tiny.processingSystem(class "PhysicsSystem")

PhysicsSystem.filter = tiny.requireAll("pos", "vel")

local dx_goal, dy_goal
local hit_x, hit_y, hit_time, nx, ny, other_pos
COARSE_GRID_SIZE = 64
local other_pos_coarse = {half_h = COARSE_GRID_SIZE, half_w = COARSE_GRID_SIZE}
local hit_list = {}

local already_applied_hits = {}
local new

local ap

function PhysicsSystem:preProcess(dt)
	already_applied_hits = {}
end

function PhysicsSystem:process(e, dt)
	if e.controls and e.walker then
		if e.walker.knocked then
			local new_len = math.max(0, mymath.vector_length(e.vel.dx, e.vel.dy) - 2 * e.walker.accel)
			local angle = math.atan2(e.vel.dy, e.vel.dx)

			e.vel.dx = new_len * math.cos(angle)
			e.vel.dy = new_len * math.sin(angle)

			if e.vel.dx == 0 and e.vel.dy == 0 then
				e:end_knock()
			end
		else
			dx_goal = e.controls.move_x
			dy_goal = e.controls.move_y

			if (e.collides and e.collides.collides_with_map) and (math.abs(dx_goal) + math.abs(dy_goal) == 1) then
				-- alter the controls based on adjacent walls
				-- test one pixel in the relevant direction
				hit_list = {}
				collision.map_collision_aabb_sweep(e.pos, dx_goal, dy_goal, hit_list)
				-- sort by impact time
				table.sort(hit_list, function(hit_1, hit_2) return hit_1.time < hit_2.time end)

				if #hit_list >= 1 and hit_list[1].object.kind == "wall" then
					if dx_goal == 0 then
						if dy_goal == 1 and hit_list[1].ny < -0.01 then
							-- south
							dx_goal = mymath.sign(hit_list[1].nx)
						elseif dy_goal == -1 and hit_list[1].ny > 0.01 then
							-- north
							dx_goal = mymath.sign(hit_list[1].nx)
						end
					elseif dx_goal == 1 and dy_goal == 0 and hit_list[1].nx < -0.01 then
						-- east
						dy_goal = mymath.sign(hit_list[1].ny)
					elseif dy_goal == 0 and hit_list[1].nx > 0.01 then -- dx_goal == -1 here
						-- west
						dy_goal = mymath.sign(hit_list[1].ny)
					end
				end
			end

			dx_goal = dx_goal * e.walker.top_speed
			dy_goal = dy_goal * e.walker.top_speed

			-- xxx use abs_subtract?
			if e.vel.dx >= dx_goal then
				e.vel.dx = math.max(dx_goal, e.vel.dx - e.walker.accel)
			else
				e.vel.dx = math.min(dx_goal, e.vel.dx + e.walker.accel)
			end

			if e.vel.dy >= dy_goal then
				e.vel.dy = math.max(dy_goal, e.vel.dy - e.walker.accel)
			else
				e.vel.dy = math.min(dy_goal, e.vel.dy + e.walker.accel)
			end
		end
	end

	-- calculate how far to move this frame
	-- cut off the fractional part; we'll re-add it next frame
	e.vel.dx_acc = e.vel.dx_acc + e.vel.dx
	e.vel.dy_acc = e.vel.dy_acc + e.vel.dy
	idx, idy = mymath.abs_floor(e.vel.dx_acc), mymath.abs_floor(e.vel.dy_acc)
	e.vel.dx_acc = e.vel.dx_acc - idx
	e.vel.dy_acc = e.vel.dy_acc - idy

	if e.collides then
		PhysicsSystem:move_with_collision(e, idx, idy, self.entities, 0, dt)
	else
		e.pos.x = e.pos.x + idx
		e.pos.y = e.pos.y + idy
	end
end

function PhysicsSystem:move_with_collision(e, idx, idy, entity_list, tries, dt)
	if tries > 16 then
		-- error("physics called too many times by " .. e.name .. ", id "..e.id.." at " .. e.pos.x .. ", " .. e.pos.y)
		return
	end

	hit_list = {}

	if e.collides.collides_with_map then
		-- get map hits
		collision.map_collision_aabb_sweep(e.pos, idx, idy, hit_list)
	end

	if e.collides.collides_with_entities then
		for _, other_e in pairs(entity_list) do
			if other_e.id ~= e.id and other_e.collides and other_e.collides.collides_with_entities
				and ((other_e.team ~= e.team) or other_e.collides.collides_with_friends) then
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
		local reaction = "pass"

		for _, v in ipairs(hit_list) do
			hit = v
			if hit.object.kind == "entity" then
				-- figure out how to proceed after this hit
				reaction = PhysicsSystem:entity_collision_reaction(e, hit.object.entity, hit)

				-- if we've already detected this collision from the other side, don't reapply it
				new = true
				for i,v in ipairs(already_applied_hits) do
					if v[1] == hit.object.entity.id and v[2] == e.id then
						-- we already did this one
						new = false
						break
					end
				end
				if new then
					PhysicsSystem:collide(e, hit.object.entity, hit)
					table.insert(already_applied_hits, {e.id, hit.object.entity.id})
				end
			else
				-- XXX do something when hitting a wall

				reaction = e.collides.map_reaction
			end

			if reaction ~= "pass" then
				-- we hit something solid, so ignore later collisions
				e.pos.x = hit.x
				e.pos.y = hit.y
				break
			end
		end

		if reaction == "pass" then
			-- we passed through everything
			e.pos.x = e.pos.x + idx
			e.pos.y = e.pos.y + idy
		elseif reaction == "stick" then
			-- stop dead
			e.vel.dx = 0
			e.vel.dy = 0
			e.vel.dx_acc = 0
			e.vel.dy_acc = 0
		elseif reaction == "slide" then
			-- slide along the surface we hit
			local dot = e.vel.dx * hit.ny - e.vel.dy * hit.nx

			e.vel.dx = dot * hit.ny
			e.vel.dy = dot * (-hit.nx)

			dot = e.vel.dx_acc * hit.ny - e.vel.dy_acc * hit.nx

			e.vel.dx_acc = dot * hit.ny
			e.vel.dy_acc = dot * (-hit.nx)

			if hit.time < 1 then
				-- try continuing our movement along the new vector
				e.vel.dx_acc = e.vel.dx_acc + e.vel.dx * (1 - hit.time)
				e.vel.dy_acc = e.vel.dy_acc + e.vel.dy * (1 - hit.time)
				idx, idy = mymath.abs_floor(e.vel.dx_acc), mymath.abs_floor(e.vel.dy_acc)
				e.vel.dx_acc = e.vel.dx_acc - idx
				e.vel.dy_acc = e.vel.dy_acc - idy

				if idx ~= 0 or idy ~= 0 then
					PhysicsSystem:move_with_collision(e, idx, idy, entity_list, tries + 1, dt)
				end
			end
		elseif string.sub(reaction, 1, 6) == "bounce" then
			local dot = e.vel.dy * hit.ny + e.vel.dx * hit.nx
			local restitution = string.sub(reaction, 8)

			e.vel.dx = (e.vel.dx - 2 * dot * hit.nx) * restitution
			e.vel.dy = (e.vel.dy - 2 * dot * hit.ny) * restitution

			if hit.time < 1 then
				-- try continuing our movement along the new vector
				e.vel.dx_acc = e.vel.dx_acc + e.vel.dx * (1 - hit.time)
				e.vel.dy_acc = e.vel.dy_acc + e.vel.dy * (1 - hit.time)
				idx, idy = mymath.abs_floor(e.vel.dx_acc), mymath.abs_floor(e.vel.dy_acc)
				e.vel.dx_acc = e.vel.dx_acc - idx
				e.vel.dy_acc = e.vel.dy_acc - idy

				if idx ~= 0 or idy ~= 0 then
					PhysicsSystem:move_with_collision(e, idx, idy, entity_list, tries + 1, dt)
				end
			end
		elseif reaction == "die" or reaction == "vanish" then
			if e.die then
				e:die(reaction == "vanish")
			else
				tiny.removeEntity(world, e)
			end
		-- elseif reaction == "end" then
			-- do nothing
		end
	end
end

function PhysicsSystem:collide(a, b, hit)
	-- while moving, a ran into b
	if a.team ~= b.team then
		if a.collides.attack_profile and b.collides.defence_profile then
			ap = a.collides.attack_profile
			if b.drawable then
				b.drawable.flash_end_frame = game_frame + 5*ap.push
			end
			local angle = math.atan2(b.pos.y - a.pos.y, b.pos.x - a.pos.x)
			b.vel.dx = ap.push * math.cos(angle)
			b.vel.dy = ap.push * math.sin(angle)
			if ap.knock and b.walker and b.walker.knockable then
				b:get_knocked()
			end
		end

		if b.collides.attack_profile and a.collides.defence_profile then
			ap = b.collides.attack_profile
			if a.drawable then
				a.drawable.flash_end_frame = game_frame + 5*ap.push
			end
			local angle = math.atan2(a.pos.y - b.pos.y, a.pos.x - b.pos.x)
			a.vel.dx = ap.push * math.cos(angle)
			a.vel.dy = ap.push * math.sin(angle)
			if ap.knock and a.walker and a.walker.knockable then
				a:get_knocked()
			end
		end
	else
		-- check for knocked dudes
		local a_knocked = a.walker and a.walker.knocked
		local b_knocked = b.walker and b.walker.knocked

		if a_knocked and not b_knocked then
			local len = mymath.vector_length(a.vel.dx, a.vel.dy)
			local angle = mymath.average_angles(math.atan2(a.pos.y - b.pos.y, a.pos.x - b.pos.x), math.atan2(a.vel.dy, a.vel.dx))
			-- if b.drawable then
			-- 	b.drawable.flash_end_frame = game_frame + 5*len
			-- end
			b.vel.dx = 0.6 * len * math.cos(angle)
			b.vel.dy = 0.6 * len * math.sin(angle)
		elseif b_knocked and not a_knocked then
			local len = mymath.vector_length(b.vel.dx, b.vel.dy)
			local angle = mymath.average_angles(math.atan2(b.pos.y - a.pos.y, b.pos.x - a.pos.x), math.atan2(b.vel.dy, b.vel.dx))
			if a.drawable then
				a.drawable.flash_end_frame = game_frame + 5*len
			end
			a.vel.dx = 0.6 * len * math.cos(angle)
			a.vel.dy = 0.6 * len * math.sin(angle)
		end
	end
end

function PhysicsSystem:entity_collision_reaction(a, b, hit)
	-- how should a proceed after colliding with b?

	-- pass: pass through, ignoring the hit
	-- stick: stop and lose all momentum
	-- slide: slide along the surface
	-- bounce X: reflect off, with bounce restitution X
	-- die: call a:die(false)
	-- vanish: call a:die(true)
	-- end: stop moving this frame, but retain momentum

	if a.team == b.team or not b.collides.is_solid then
		return "pass"
	else
		return a.collides.solid_entity_reaction or "pass"
	end
end

return PhysicsSystem
