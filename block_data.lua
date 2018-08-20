local block_data = {}

default_box_half_multipliers = { u=1, d=1, l=1, r=1 }

function block_data.get_box_half_multipliers(type)
	if block_data[type].box_half_multipliers then
		return block_data[type].box_half_multipliers
	else
		return default_box_half_multipliers
	end
end

block_data["void"] =
{
	hp = 0,
	breakable = false,
	collision_type = "solid",
	slope = false,
}

block_data["air"] =
{
	hp = 0,
	breakable = false,
	collision_type = "empty",
	slope = false,
	invisible = true,
}

block_data["wall"] =
{
	hp = 180,
	breakable = true,
	collision_type = "solid",
	slope = false,
}

block_data["slope_45"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = false, r = true},
	slope = -1,
	slope_y_offset = 0,
}

block_data["slope_-45"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = true, r = false},
	slope = 1,
	slope_y_offset = 0,
}

block_data["slope_45_a"] =
{
	hp = 60,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = false, l = false, r = false},
	slope = -1,
	slope_y_offset = 4,
	box_half_multipliers = { u = 0, d = 1, l = 0, r = 1 },
}

block_data["slope_45_b"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = false, r = true},
	slope = -1,
	slope_y_offset = -4,
}

block_data["slope_-45_a"] =
{
	hp = 60,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = false, l = false, r = false},
	slope = 1,
	slope_y_offset = 4,
	box_half_multipliers = { u = 0, d = 1, l = 1, r = 0 },
}

block_data["slope_-45_b"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = true, r = false},
	slope = 1,
	slope_y_offset = -4,
}

-- 23 degree slopes are offset one pixel downwards to avoid jamming the player into a wall in acute corners
block_data["slope_23_a"] =
{
	hp = 60,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = false, r = false},
	slope = -0.5,
	slope_y_offset = 2,
	box_half_multipliers = { u = 0, d = 1, l = 1, r = 1 },
}

block_data["slope_23_b"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = false, r = true},
	slope = -0.5,
	slope_y_offset = -2,
}

block_data["slope_-23_a"] =
{
	hp = 60,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = false, r = false},
	slope = 0.5,
	slope_y_offset = 2,
	box_half_multipliers = { u = 0, d = 1, l = 1, r = 1 },
}

block_data["slope_-23_b"] =
{
	hp = 120,
	breakable = true,
	collision_type = "slope",
	collision_dirs = { u = false, d = true, l = true, r = false},
	slope = 0.5,
	slope_y_offset = -2,
}

return block_data
