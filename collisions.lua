local collisions = {}

local j, k_pos
function collisions.collide(k, hit)
	-- entity k ran into something while moving direction dx,dy
	-- return true if it should stop moving

	if hit.object.kind == "block" then
		-- we ran into a wall, how dumb is that
		collisions.hit_wall(k, hit)
		return true
	elseif hit.object.kind == "hitbox" then
		collisions.get_hit(hit.object.id, k, hit)
		collisions.hit_hitbox(k, hit)
		return true
	else
		-- a ghost!!!?!
		return false
	end
end

function collisions.hit_wall(k, hit)
	local angle, speed
	for n = 1, 5 do
		angle = mymath.random_spread(math.atan2(hit.ny, hit.nx), PI/3)
		speed = 1 + love.math.random() * 4
		ecs.spawn_particle(kind, color.rouge, hit.x, hit.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
	end
	ecs.delete_entity(k)
end

function collisions.hit_hitbox(k, hit)
	local angle, speed
	for n = 1, 5 do
		angle = mymath.average_angles(math.atan2(-hit.dy, -hit.dx), math.atan2(hit.ny, hit.nx))
		angle = mymath.random_spread(angle, PI/3)
		speed = 1 + love.math.random() * 4
		ecs.spawn_particle(kind, color.ltblue, hit.x, hit.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
	end
	ecs.delete_entity(k)
end

function collisions.get_hit(j, k, hit)
	if c_drawables[j] then
		c_drawables[j].flash_time = game_frame + 20
	end

	local mov = c_movements[j]
	if mov then
		mov.dx = mov.dx + 1 * hit.dx
		mov.dy = mov.dy + 1 * hit.dy
	end
end

return collisions
