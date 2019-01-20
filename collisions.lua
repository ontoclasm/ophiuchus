local collisions = {}

local j, k_pos
function collisions.collide(k, hit)
	-- entity k ran into something while moving direction dx,dy
	-- return true if it should stop moving
	mov = c_movements[k]

	if hit.object.kind == "hitbox" then
		collisions.get_hit(hit.object.id, k, hit)
		if mov.collision_responses["enemy"] then
			return collisions[mov.collision_responses["enemy"]](k, hit)
		else
			return false
		end
	elseif mov.collision_responses[hit.object.kind] then

		return collisions[mov.collision_responses[hit.object.kind]](k, hit)
	else
		-- who cares, lol
		return false
	end
end

function collisions.get_hit(j, k, hit)
	ident = c_identities[k]

	damage = ident.name == "Slash" and 10 or 5
	kb = ident.name == "Slash" and 3 or 1
	if mortals.apply_damage(j, k, damage) then
		-- OW
		if c_drawables[j] then
			c_drawables[j].flash_time = game_frame + damage * 4
		end

		local mov = c_movements[j]
		if mov then
			mov.dx = mov.dx + kb * hit.dx
			mov.dy = mov.dy + kb * hit.dy
		end

		if ident.name == "Slash" then
			hitstop_frames = 5
		end
	end
end

----

function collisions.explode_small(k, hit)
	local angle, speed
	for n = 1, 5 do
		angle = mymath.random_spread(math.atan2(hit.ny, hit.nx), PI/3)
		speed = 1 + love.math.random() * 4
		ecs.spawn_particle(kind, color.rouge, hit.x, hit.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
	end
	ecs.delete_entity(k)
	return true
end

function collisions.slice(k, hit)
	target = hit.object.id

	if target then
		pos = c_positions[target]
		if pos then
			local angle, speed
			for n = 1, 3 do
				angle = mymath.random_spread(math.atan2(hit.dy, hit.dx) + PI * 0.5, PI/12)
				speed = 1 + love.math.random() * 4
				ecs.spawn_particle(kind, color.white, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
			end
			for n = 1, 3 do
				angle = mymath.random_spread(math.atan2(hit.dy, hit.dx) - PI * 0.5, PI/12)
				speed = 1 + love.math.random() * 4
				ecs.spawn_particle(kind, color.white, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
			end
		end
	end

	return false
end

function collisions.explode_big(k, hit)
	local angle, speed
	for n = 1, 5 do
		angle = mymath.average_angles(math.atan2(-hit.dy, -hit.dx), math.atan2(hit.ny, hit.nx))
		angle = mymath.random_spread(angle, PI/3)
		speed = 1 + love.math.random() * 4
		ecs.spawn_particle(kind, color.ltblue, hit.x, hit.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
	end
	ecs.delete_entity(k)
	return true
end

function collisions.vanish(k, hit)
	ecs.delete_entity(k)
	return true
end

function collisions.bounce(k, hit)
	pos = c_positions[k]
	mov = c_movements[k]

	pos.x = hit.x
	pos.y = hit.y
	if mov then
		-- reflect off, maybe
		-- chance is based on the angle of incidence
		local dot = mov.dy * hit.ny + mov.dx * hit.nx
		-- if (love.math.random() * math.pi) < 2 * math.abs(math.acos(dot / mymath.vector_length(self.dx, self.dy)) - math.pi) - 0.2 then
			mov.dx = (mov.dx - 2 * dot * hit.nx)
			mov.dy = (mov.dy - 2 * dot * hit.ny)
		-- else
		-- 	mainmap:hurt_block(hit[2], hit[3], self.damage)
		-- 	self:die()
		-- 	audio.play('hit2')
		-- end
	end
	return true
end

return collisions
