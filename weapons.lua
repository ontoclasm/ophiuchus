local weapons = {}

function weapons.create(kind)
	return {kind = kind, ready_time = 0}
end

function weapons.spawn_shot(kind, start_x, start_y, dx, dy)
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Pellet"}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 1, half_h = 1}
	c_movements[id] =	{dx = dx, dy = dy, dx_acc = 0, dy_acc = 0, map_collision = "explode"}
	c_drawables[id] =	{sprite = "bullet_23", color = color.rouge,
						 flash_color = color.white, flash_time = 0,}
end

local pos, controls, kind
function weapons.update(dt)
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
		if weapon.ready_time < ctime then
			dx, dy = mymath.normalize(aim_x - start_x, aim_y - start_y)
			dx, dy = dx * 500, dy * 500
			weapons.spawn_shot("pellet", start_x, start_y, dx, dy)
			weapon.ready_time = ctime + 0.2
		end
	end,

	-- altfire_pressed = function(start_x, start_y, aim_x, aim_y)

	-- end,

	-- altfire_down = function(start_x, start_y, aim_x, aim_y)

	-- end,
}

return weapons
