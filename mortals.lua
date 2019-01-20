local mortals = {}

local m
function mortals.apply_damage(target, source, amount)
	m = c_mortals[target]
	if m then
		if not (m.immunities[source] and m.immunities[source] > game_frame) then
			m.hp = math.max(0, m.hp - amount)
			if m.hp == 0 then
				mortals.kill(target)
			else
				m.immunities[source] = game_frame + 20
			end
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
			speed = 1 + love.math.random() * 8
			ecs.spawn_particle(kind, pcolor, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 4 + love.math.random(6))
		end
	end

	ecs.delete_entity(id)
	hitstop_frames = 5
end

return mortals
