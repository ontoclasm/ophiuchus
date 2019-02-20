local collisions = {}

local j, k_pos
function collisions.collide(k, hit)
	-- entity k ran into something while moving direction dx,dy
	-- return true if it should stop moving
	pd = c_movements[k].projectile_data


	if hit.object.kind == "hitbox" then
		if pd.attack then
			collisions.get_hit(hit.object.id, k, pd.attack, hit)
		end
		if pd.collision_responses["enemy"] then
			return collisions[pd.collision_responses["enemy"]](k, hit)
		else
			return false
		end
	elseif pd.collision_responses[hit.object.kind] then

		return collisions[pd.collision_responses[hit.object.kind]](k, hit)
	else
		-- who cares, lol
		return false
	end
end

function collisions.get_hit(j, k, attack, hit)
	if mortals.apply_damage(j, k, attack.damage) then
		-- OW
		if c_drawables[j] then
			c_drawables[j].flash_end_frame = game_frame + 20
			if attack.kb then
				c_drawables[j].color = color.orange
			end
		end

		if attack.push then
			local mov = c_movements[j]
			if mov and mov.kind == "walker" then
				local angle = mymath.random_spread(math.atan2(hit.dy, hit.dx), PI/3)
				slow = 1 - math.min(1, 0.3 * attack.push)
				mov.dx = slow * mov.dx + attack.push * math.cos(angle)
				mov.dy = slow * mov.dy + attack.push * math.sin(angle)
			end
		elseif attack.kb or attack.kb_factor then
			local mov = c_movements[j]
			if mov and mov.kind == "walker" then
				local speed = attack.kb or mymath.vector_length(hit.dy, hit.dx) * attack.kb_factor
				speed = speed * (0.8 + 0.4 * love.math.random())
				if speed > 0.5 then
					mov.kind = "knockback"
					local angle = mymath.random_spread(math.atan2(hit.dy, hit.dx), PI/6)
					mov.dx = speed * math.cos(angle)
					mov.dy = speed * math.sin(angle)
				end
			end
		end

		if attack.damage > 0 then
			local pos = c_positions[j]
			if pos then
				for i = 1, love.math.random(3) do
					img.new_blood[#img.new_blood + 1] = {x = pos.x + love.math.random(21) - 11, y = pos.y + love.math.random(21) - 11,
														 r = 2 + love.math.random(5)}
				end
			end
		end
	end
end

----

function collisions.explode_small(k, hit)
	local angle, speed
	for n = 1, 5 do
		angle = mymath.random_spread(math.atan2(hit.ny, hit.nx), PI/3)
		speed = 0.5 + love.math.random() * 2
		ecs.spawn_particle(kind, color.rouge, hit.x, hit.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
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
				angle = math.atan2(hit.dy, hit.dx) + PI * 0.5
				speed = 0.5 + love.math.random() * 2
				ecs.spawn_particle(kind, color.white, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
			end
			for n = 1, 3 do
				angle = math.atan2(hit.dy, hit.dx) - PI * 0.5
				speed = 0.5 + love.math.random() * 2
				ecs.spawn_particle(kind, color.white, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
			end
		end
	end

	return false
end

function collisions.slow(k, hit)
	mov = c_movements[k]

	if mov then
		mov.dx, mov.dy = mymath.set_vector_length(mov.dx, mov.dy, math.max(0, mymath.vector_length(mov.dx, mov.dy) - 0.05))
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