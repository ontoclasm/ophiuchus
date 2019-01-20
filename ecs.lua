local ecs = {}

function ecs.spawn_shot(kind, start_x, start_y, dx, dy)
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Pellet", birth_frame = game_frame}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 1, half_h = 1}
	c_movements[id] =	{kind = "projectile", dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,
						 collides_with_map = true, collides_with_hitboxes = true, collision_response = "pop"}
	c_drawables[id] =	{sprite = "bullet_23", color = color.rouge,
						 flash_color = color.white, flash_time = 0,}
end

function ecs.spawn_particle(kind, color, start_x, start_y, dx, dy, duration)
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Spark", birth_frame = game_frame}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 1, half_h = 1}
	c_movements[id] =	{kind = "projectile", dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,
						 collision_response = "vanish"}
	c_drawables[id] =	{sprite = "bullet_23", color = color,
						 flash_color = color.white, flash_time = 0,}
	c_timeouts[id] =	game_frame + duration
end

function ecs.spawn_enemy()
	-- find a spot
	local found, start_x, start_y = false, nil, nil
	while not found do
		start_x = love.math.random(1, mainmap.width * img.tile_size)
		start_y = love.math.random(1, mainmap.height * img.tile_size)
		found = not physics.map_collision_aabb({x = start_x, y = start_y, half_w = 3, half_h = 3})
	end
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Mook", birth_frame = game_frame}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 3, half_h = 3}
	c_hitboxes[id] =	{alignment = "enemy"}
	c_controls[id] =	{
		ai = "mook",
		move_x = 0, move_y = 0,
		aim_x = 0, aim_y = 0,
		fire_pressed = false, fire_down = false,
		altfire_pressed = false, altfire_down = false,
		wake_frame = 0,
	}
	c_movements[id] =	{kind = "walker", dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,
								 speed = 1, accel = 0.1, air_accel = 0.05, grounded = false, jumping = false,
								 touching_left = false, touching_right = false,}
	c_drawables[id] =	{sprite = "player", color = color.ltblue,
						 flash_color = color.white, flash_time = 0,}
	if mymath.one_chance_in(5) then
		c_hitboxes[id].alignment = "friend"
		c_drawables[id].color = color.yellow
	end
end

function ecs.delete_entity(k)
	-- XXX there must be a better way :shobon:
	c_identities[k] = nil
	c_positions[k] = nil
	c_movements[k] = nil
	c_controls[k] = nil
	c_drawables[k] = nil
	c_weapons[k] = nil
	c_timeouts[k] = nil
	c_hitboxes[k] = nil
end

return ecs
