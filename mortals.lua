local mortals = {}

local m
function mortals.update()
	for k, m in pairs(c_mortals) do
		if m.hp <= 0 then
			mortals.kill(k)
		end
	end
end

function mortals.apply_damage(target, source, amount)
	m = c_mortals[target]
	if m then
		if not (m.immunities[source] and m.immunities[source] > game_frame) then
			m.hp = math.max(0, m.hp - amount)
			m.immunities[source] = game_frame + 20
			return true
		end
	end
	return false
end

function mortals.kill(id)
	local pos = c_positions[id]
	if pos then
		local pcolor = c_drawables[id] and c_drawables[id].color or color.white
		for n = 1, 20 do
			angle = love.math.random() * 2 * PI
			speed = 0.5 + love.math.random() * 5
			ecs.spawn_particle(kind, pcolor, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
		end
	end

	ecs.delete_entity(id)
	hitstop_frames = 5
end

return mortals
