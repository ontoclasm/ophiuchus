-- math for detecting collisions between things

local collision = {}

local ax, bx, pad_x, sign_x, ay, by, pad_y, sign_y
local near_time_x, far_time_x, near_time_y, far_time_y, far_time
local hit_time, hit_x, hit_y, cpx, cpy, nx, ny
local grid_x1, grid_x2, grid_y1, grid_y2
local block_type
local box
local hit
local mx, my, mt, mnx, mny
local rx, ry, norm

-- STATIC: return true if colliding

function collision.collision_aabb_aabb(a, b)
	return a.x - a.half_w < b.x+b.half_w and
		   b.x - b.half_w < a.x+a.half_w and
		   a.y - a.half_h < b.y+b.half_h and
		   b.y - b.half_h < a.y+a.half_h
end

function collision.collision_aabb_slope(a, b, slope, slope_y_offset, slope_vert_multiplier, bhm)
	-- this assumes the relevant corner to hit the slope is a bottom corner
	return collision.collision_aabb_aabb(a, {x = b.x + (bhm.r - bhm.l) * 0.5 * b.half_w,
										   y = b.y + (bhm.d - bhm.u) * 0.5 * b.half_h,
										   half_w = b.half_w * 0.5 * (bhm.r + bhm.l),
										   half_h = b.half_h * 0.5 * (bhm.d + bhm.u)}) and
		a.y * slope_vert_multiplier + (a.half_h - 1E-5) > (slope * (a.x - (a.half_w - 1E-5) * slope_vert_multiplier * mymath.sign(slope) - b.x) + b.y + slope_y_offset) * slope_vert_multiplier
end

function collision.map_collision_aabb(a)
	grid_x1 = map.grid_at_pos(a.x - a.half_w - 1)
	grid_x2 = map.grid_at_pos(a.x + a.half_w + 1)
	grid_y1 = map.grid_at_pos(a.y - a.half_h - 1)
	grid_y2 = map.grid_at_pos(a.y + a.half_h + 1)

	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope then
					if collision.collision_aabb_slope(
						a, box,
						block_data[block_type].slope, block_data[block_type].slope_y_offset, block_data[block_type].slope_vert_multiplier,
						block_data.get_box_half_multipliers(block_type)) then
						return true
					end
				elseif collision.collision_aabb_aabb(a, box) then
					return true
				end
			end
		end
	end

	return false
end

------------------------

-- SWEEP: sweep a by (dx, dy) and, if this will cause it to hit b,
-- return a hit table: {x, y, time, nx, ny, dx, dy}

function collision.collision_aabb_sweep(a, b, dx, dy)
	-- subtract 0.00001 px from the box sizes to avoid (literal) edge cases
	ax, bx = a.x, b.x
	pad_x = b.half_w + a.half_w - 1E-5
	sign_x = mymath.sign(dx)

	ay, by = a.y, b.y
	pad_y = b.half_h + a.half_h - 1E-5
	sign_y = mymath.sign(dy)

	if dx ~= 0 then
		scale_x = 1 / dx
		near_time_x = (bx - sign_x * (pad_x) - ax) * scale_x
		far_time_x = (bx + sign_x * (pad_x) - ax) * scale_x
	else
		if ax > bx - pad_x and ax < bx + pad_x then
			near_time_x, far_time_x = -9999, 9999
		else
			return
		end
	end

	if dy ~= 0 then
		scale_y = 1 / dy
		near_time_y = (by - sign_y * (pad_y) - ay) * scale_y
		far_time_y = (by + sign_y * (pad_y) - ay) * scale_y
	else
		if ay > by - pad_y and ay < by + pad_y then
			near_time_y, far_time_y = -9999, 9999
		else
			return
		end
	end

	if near_time_x > far_time_y or near_time_y > far_time_x then
		-- missed
		return
	end

	-- pick the times we were closest
	near_time = math.max(near_time_x, near_time_y)
	far_time = math.min(far_time_x, far_time_y)

	if near_time > 1 or far_time < 0 then
		-- didn't reach b, or already past and moving away
		return
	end

	-- okay, we hit the aabb
	hit_time = mymath.clamp(0, near_time, 1)
	if near_time_x > near_time_y then
		nx = -sign_x
		ny = 0
	else
		nx = 0
		ny = -sign_y
	end

	if sign_x >= 0 then
		hit_x = math.floor(a.x + hit_time * dx + 1E-5)
	else
		hit_x = math.ceil(a.x + hit_time * dx - 1E-5)
	end

	if sign_y >= 0 then
		hit_y = math.floor(a.y + hit_time * dy + 1E-5)
	else
		hit_y = math.ceil(a.y + hit_time * dy - 1E-5)
	end

	return {x = hit_x, y = hit_y, time = hit_time, nx = nx, ny = ny, dx = dx, dy = dy}
end

function collision.collision_aabb_sweep_slope(a, b, dx, dy, slope, slope_y_offset, slope_vert_multiplier, bhm)
	ax, bx =  a.x, b.x
	sign_x = mymath.sign(dx)
	scale_x = 1 / dx

	ay, by =  a.y, b.y
	sign_y = mymath.sign(dy)
	scale_y = 1 / dy

	if dx ~= 0 then
		if sign_x == 1 then
			near_time_x = (bx - ax - b.half_w * bhm.l - a.half_w + 1E-5) * scale_x
			far_time_x = (bx - ax + b.half_w * bhm.r + a.half_w - 1E-5) * scale_x
		else
			near_time_x = (bx - ax + b.half_w * bhm.r + a.half_w - 1E-5) * scale_x
			far_time_x = (bx - ax - b.half_w * bhm.l - a.half_w + 1E-5) * scale_x
		end
	else
		if ax > bx - b.half_w * bhm.l - a.half_w and ax < bx + b.half_w * bhm.r + a.half_w then
			near_time_x, far_time_x = -9999, 9999
		else
			return
		end
	end

	if dy ~= 0 then
		if sign_y == 1 then
			near_time_y = (by - ay - b.half_h * bhm.u - a.half_h + 1E-5) * scale_y
			far_time_y = (by - ay + b.half_h * bhm.d + a.half_h - 1E-5) * scale_y
		else
			near_time_y = (by - ay + b.half_h * bhm.d + a.half_h - 1E-5) * scale_y
			far_time_y = (by - ay - b.half_h * bhm.u - a.half_h + 1E-5) * scale_y
		end
	else
		if ay > by - b.half_h * bhm.u - a.half_h and ay < by + b.half_h * bhm.d + a.half_h then
			near_time_y, far_time_y = -9999, 9999
		else
			return
		end
	end

	if near_time_x > far_time_y or near_time_y > far_time_x then
		-- missed the whole box
		return
	end

	-- ugh, now deal with the slanted edge

	-- coords of the relevant corner of a; currently this is always a bottom corner
	rx = ax - (a.half_w - 1E-5) * slope_vert_multiplier * mymath.sign(slope)
	ry = ay + (a.half_h - 1E-5) * slope_vert_multiplier

	if dx ~= 0 then
		-- find the x distance traveled; divide by dx to find near_time_q
		vslope = dy / dx

		-- x coord of the contact point is (1/(slope - vslope))(slope * bx - by - vslope * rx + ry)
		near_time_q = ((slope * bx - by - slope_y_offset - vslope * rx + ry) / (slope - vslope) - rx) * scale_x
	else
		-- x is fixed: find the y distance and divide by dy to find near_time_q

		-- y coord of the contact point is (slope * (rx - bx) + by)
		near_time_q = (slope * (rx - bx) + by + slope_y_offset - ry) * scale_y
	end

	if ry * slope_vert_multiplier > (slope * (rx - bx) + by + slope_y_offset) * slope_vert_multiplier then
		if near_time_q < 0 then
			-- below and moving away
			far_time_q = 9999
		else
			-- below, but moving out of the slope
			far_time_q = near_time_q
			near_time_q = -9999
		end
	else
		if near_time_q < 0 then
			-- above, but moving away
			return
		else
			-- above, and moving towards
			far_time_q = 9999
		end
	end

	if near_time_q > far_time_x or near_time_q > far_time_y or near_time_x > far_time_q or near_time_y > far_time_q then
		-- missed again, rip
		return
	end

	-- pick the times we were closest
	near_time = math.max(near_time_x, near_time_y, near_time_q)
	far_time = math.min(far_time_x, far_time_y, far_time_q)

	if near_time > 1 or far_time < 0 then
		-- didn't reach b, or already past and moving away
		return
	end

	-- okay?????
	hit_time = mymath.clamp(0, near_time, 1)
	if near_time_q > near_time_x and near_time_q > near_time_y then
		-- normal to the slope
		norm = slope_vert_multiplier * math.sqrt(math.pow(slope, 2) + 1)
		nx = slope / norm
		ny = - 1 / norm

		if sign_x >= 0 then
			hit_x = math.floor(a.x + hit_time * dx + 1E-5)
		else
			hit_x = math.ceil(a.x + hit_time * dx - 1E-5)
		end

		if sign_y >= 0 then
			hit_y = math.floor(a.y + hit_time * dy + 1E-5)
		else
			hit_y = math.ceil(a.y + hit_time * dy - 1E-5)
		end
	else
		if near_time_x > near_time_y then
			nx = -sign_x
			ny = 0
		else
			nx = 0
			ny = -sign_y
		end

		if sign_x >= 0 then
			hit_x = math.floor(a.x + hit_time * dx + 1E-5)
		else
			hit_x = math.ceil(a.x + hit_time * dx - 1E-5)
		end

		if sign_y >= 0 then
			hit_y = math.floor(a.y + hit_time * dy + 1E-5)
		else
			hit_y = math.ceil(a.y + hit_time * dy - 1E-5)
		end
	end

	return {x = hit_x, y = hit_y, time = hit_time, nx = nx, ny = ny, dx = dx, dy = dy}
end

function collision.map_collision_aabb_sweep_test(a, dx, dy, hit_list)
	-- return true if we hit anything
	grid_x1 = map.grid_at_pos(math.min(a.x - a.half_w - 1, a.x - a.half_w + dx - 1))
	grid_x2 = map.grid_at_pos(math.max(a.x + a.half_w + 1, a.x + a.half_w + dx + 1))
	grid_y1 = map.grid_at_pos(math.min(a.y - a.half_h - 1, a.y - a.half_h + dy - 1))
	grid_y2 = map.grid_at_pos(math.max(a.y + a.half_h + 1, a.y + a.half_h + dy + 1))

	mt = 1
	hit = nil
	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope then
					hit = collision.collision_aabb_sweep_slope(
						a, box, dx, dy,
						block_data[block_type].slope, block_data[block_type].slope_y_offset, block_data[block_type].slope_vert_multiplier,
						block_data.get_box_half_multipliers(block_type))
				else
					hit = collision.collision_aabb_sweep(a, box, dx, dy)
				end

				if hit then
					if (nx ~= 0 and ny ~= 0) or not mainmap:grid_blocks_dir(i + nx, j + ny, map.orth_normal_to_dir(-nx, -ny)) then
						return true
					end
				end
			end
		end
	end
	return false
end

function collision.map_collision_aabb_sweep(a, dx, dy, hit_list)
	-- populate hit_list with any collisions with the map
	-- returns the list UNSORTED
	grid_x1 = map.grid_at_pos(math.min(a.x - a.half_w - 1, a.x - a.half_w + dx - 1))
	grid_x2 = map.grid_at_pos(math.max(a.x + a.half_w + 1, a.x + a.half_w + dx + 1))
	grid_y1 = map.grid_at_pos(math.min(a.y - a.half_h - 1, a.y - a.half_h + dy - 1))
	grid_y2 = map.grid_at_pos(math.max(a.y + a.half_h + 1, a.y + a.half_h + dy + 1))

	hit = nil
	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope then
					hit = collision.collision_aabb_sweep_slope(
						a, box, dx, dy,
						block_data[block_type].slope, block_data[block_type].slope_y_offset, block_data[block_type].slope_vert_multiplier,
						block_data.get_box_half_multipliers(block_type))
				else
					hit = collision.collision_aabb_sweep(a, box, dx, dy)
				end

				if hit then
					if (nx ~= 0 and ny ~= 0) or not mainmap:grid_blocks_dir(i + nx, j + ny, map.orth_normal_to_dir(-nx, -ny)) then
						hit.object = {kind = (block_type == "void" and "void" or "wall"), gx = i, gy = j}
						-- if hit.nx > 0 then
						-- 	hit.x = math.ceil(hit.x)
						-- elseif hit.nx < 0 then
						-- 	hit.x = math.floor(hit.x)
						-- end
						-- if hit.ny > 0 then
						-- 	hit.y = math.ceil(hit.y)
						-- elseif hit.ny < 0 then
						-- 	hit.y = math.floor(y)
						-- end
						hit_list[#hit_list + 1] = hit
					end
				end
			end
		end
	end
end

local dx, dy
local ijhx, ijhy, ijht, ijnx, ijny
local rt, rdx, rdy

function collision.debug_map_collision_sweep(a)
	dx = mouse.x + camera.x - a.x
	dy = mouse.y + camera.y - a.y

	grid_x1 = map.grid_at_pos(math.min(a.x - a.half_w, a.x - a.half_w + dx))
	grid_x2 = map.grid_at_pos(math.max(a.x + a.half_w, a.x + a.half_w + dx))
	grid_y1 = map.grid_at_pos(math.min(a.y - a.half_h, a.y - a.half_h + dy))
	grid_y2 = map.grid_at_pos(math.max(a.y + a.half_h, a.y + a.half_h + dy))

	first_hit = {x = a.x + dx, y = a.y + dy, time = 1, nx = 0, ny = 0, dx = dx, dy = dy}
	hit = nil
	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope then
					hit = collision.collision_aabb_sweep_slope(
						a, box, dx, dy,
						block_data[block_type].slope, block_data[block_type].slope_y_offset, block_data[block_type].slope_vert_multiplier,
						block_data.get_box_half_multipliers(block_type))
				else
					hit = collision.collision_aabb_sweep(a, box, dx, dy)
				end

				if hit and hit.time < first_hit.time then
					if (nx ~= 0 and ny ~= 0) or not mainmap:grid_blocks_dir(i + nx, j + ny, map.orth_normal_to_dir(-nx, -ny)) then
						hit.object = {kind = (block_type == "void" and "void" or "wall"), gx = i, gy = j}
						-- if hit.nx > 0 then
						-- 	hit.x = math.ceil(hit.x)
						-- elseif hit.nx < 0 then
						-- 	hit.x = math.floor(hit.x)
						-- end
						-- if hit.ny > 0 then
						-- 	hit.y = math.ceil(hit.y)
						-- elseif hit.ny < 0 then
						-- 	hit.y = math.floor(y)
						-- end
						first_hit = hit
					end
				end
			end
		end
	end

	-- calculate the residual vector
	if first_hit.time < 1 then
		rt = 1 - first_hit.time
		-- px = ny
		-- py = -nx
		-- wx = dx * rem_time
		-- wy = dy * rem_time

		-- (dx rt, dy rt) dot (ny, -nx)
		r = dx * rt * first_hit.ny - dy * rt * first_hit.nx

		rdx = r * first_hit.ny
		rdy = r * (-first_hit.nx)
	end

	-- draw debug tracer
	if first_hit.time == 1 then
		love.graphics.setColor(color.blue)
	else
		love.graphics.setColor(color.orange)
	end
	love.graphics.line(a.x - camera.x, a.y - camera.y, first_hit.x - camera.x, first_hit.y - camera.y)
	love.graphics.rectangle('line', first_hit.x - a.half_w - camera.x + 0.5, first_hit.y - a.half_h - camera.y + 0.5,
							a.half_w * 2 - 1, a.half_h * 2 - 1)
	love.graphics.setColor(color.white)
	-- love.graphics.rectangle('line', a.x - camera.x, a.y - camera.y, a.w, a.h)
	if first_hit.time < 1 then
		love.graphics.line(first_hit.x - camera.x, first_hit.y - camera.y, first_hit.x - camera.x + rdx, first_hit.y - camera.y + rdy)
		love.graphics.setColor(color.rouge)
		love.graphics.line(first_hit.x - camera.x, first_hit.y - camera.y,
						   first_hit.x - camera.x + first_hit.nx * 8, first_hit.y - camera.y + first_hit.ny * 8)
		love.graphics.setColor(color.white)
	end
end

function collision.debug_map_collision(a)
	if collision.map_collision_aabb(a) then
		love.graphics.setColor(color.orange)
	else
		love.graphics.setColor(color.blue)
	end
	love.graphics.rectangle('line', a.x - a.half_w - camera.x + 0.5, a.y - a.half_h - camera.y + 0.5, a.half_w * 2 - 1, a.half_h * 2 - 1)
	love.graphics.setColor(color.white)
end

return collision
