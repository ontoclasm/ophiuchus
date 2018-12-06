local ecs = {}

function ecs.delete_entity(k)
	-- XXX there must be a better way :shobon:
	c_identities[k] = nil
	c_positions[k] = nil
	c_movements[k] = nil
	c_controls[k] = nil
	c_drawables[k] = nil
	c_weapons[k] = nil
end

return ecs
