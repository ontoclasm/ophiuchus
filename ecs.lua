local ecs = {}

function ecs.spawn_shot(kind, start_x, start_y, dx, dy, speed)
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Pellet", birth_frame = game_frame}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 1, half_h = 1}
	c_movements[id] =	{kind = "projectile", dx = dx, dy = dy, dx_acc = 0, dy_acc = 0, speed = speed,
						 collides_with_map = true, collision_response = "bounce"}
	c_drawables[id] =	{sprite = "bullet_23", color = color.rouge,
						 flash_color = color.white, flash_time = 0,}
end

function ecs.spawn_particle(kind, start_x, start_y, dx, dy, speed, duration)
	id = idcounter.get_id("entity")
	c_identities[id] =	{name = "Spark", birth_frame = game_frame}
	c_positions[id] =	{x = start_x, y = start_y, half_w = 1, half_h = 1}
	c_movements[id] =	{kind = "projectile", dx = dx, dy = dy, dx_acc = 0, dy_acc = 0, speed = speed,
						 collision_response = "vanish"}
	c_drawables[id] =	{sprite = "bullet_23", color = color.rouge,
						 flash_color = color.white, flash_time = 0,}
	c_timeouts[id] =	game_frame + duration
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
end

return ecs
