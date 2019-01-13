local weapons = {}

function weapons.create(kind)
	return {kind = kind, ready_time = 0}
end

local pos, controls, kind
function weapons.update()
	for k,v in pairs(c_weapons) do
		pos = c_positions[k]
		controls = c_controls[k]
		kind = weapons.kinds[v[1].kind]

		if kind.fire_pressed and controls.fire_pressed then
			kind.fire_pressed(v[1], pos.x, pos.y, controls.aim_x, controls.aim_y)
		end
		if kind.fire_down and controls.fire_down then
			kind.fire_down(v[1], pos.x, pos.y, controls.aim_x, controls.aim_y)
		end
		if kind.altfire_pressed and controls.altfire_pressed then
			kind.altfire_pressed(v[1], pos.x, pos.y, controls.aim_x, controls.aim_y)
		end
		if kind.altfire_down and controls.altfire_down then
			kind.altfire_down(v[1], pos.x, pos.y, controls.aim_x, controls.aim_y)
		end
	end
end

--

weapons.kinds = {}

weapons.kinds["assault"] = {
	-- fire_pressed = function(start_x, start_y, aim_x, aim_y)

	-- end,

	fire_down = function(weapon, start_x, start_y, aim_x, aim_y)
		if weapon.ready_time < game_frame then
			dx, dy = mymath.normalize(aim_x - start_x, aim_y - start_y)
			ecs.spawn_shot("pellet", start_x, start_y, dx, dy, 20)
			weapon.ready_time = game_frame + 8
		end
	end,

	-- altfire_pressed = function(start_x, start_y, aim_x, aim_y)

	-- end,

	-- altfire_down = function(start_x, start_y, aim_x, aim_y)

	-- end,
}

return weapons
