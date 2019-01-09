local physics = {}

local ax, bx, pad_x, sign_x, ay, by, pad_y, sign_y
local near_time_x, far_time_x, near_time_y, far_time_y, far_time
local hit_time, hit_x, hit_y, nx, ny

-- test if a and b are intersecting
function physics.collision_aabb_aabb(a, b)
	return a.x - a.half_w < b.x+b.half_w and
		   b.x - b.half_w < a.x+a.half_w and
		   a.y - a.half_h < b.y+b.half_h and
		   b.y - b.half_h < a.y+a.half_h
end

function physics.collision_aabb_slope(a, b, slope, slope_y_offset, bhm)
	-- this assumes the relevant corner to hit the slope is a bottom corner
	return physics.collision_aabb_aabb(a, {x = b.x + (bhm.r - bhm.l) * 0.5 * b.half_w,
										   y = b.y + (bhm.d - bhm.u) * 0.5 * b.half_h,
										   half_w = b.half_w * 0.5 * (bhm.r + bhm.l),
										   half_h = b.half_h * 0.5 * (bhm.d + bhm.u)}) and
		a.y + a.half_h - 1E-5 > slope * (a.x - (a.half_w - 1E-5) * mymath.sign(slope) - b.x) + b.y + slope_y_offset
end

--- test if moving a by (vx,vy) will cause it to hit b
-- if so, return x,y (point of impact), 0 <= t <= 1 ("time" of impact), nx,ny (normal of the surface we ran into)
function physics.collision_aabb_sweep(a, b, vx, vy)
	-- subtract 0.00001 px from the box sizes to avoid (literal) edge cases
	ax, bx = a.x, b.x
	pad_x = b.half_w + a.half_w - 1E-5
	sign_x = mymath.sign(vx)

	ay, by = a.y, b.y
	pad_y = b.half_h + a.half_h - 1E-5
	sign_y = mymath.sign(vy)

	if vx ~= 0 then
		scale_x = 1 / vx
		near_time_x = (bx - sign_x * (pad_x) - ax) * scale_x
		far_time_x = (bx + sign_x * (pad_x) - ax) * scale_x
	else
		if ax > bx - pad_x and ax < bx + pad_x then
			near_time_x, far_time_x = -9999, 9999
		else
			return
		end
	end

	if vy ~= 0 then
		scale_y = 1 / vy
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
		hit_x = math.floor(a.x + hit_time * vx + 1E-5)
	else
		hit_x = math.ceil(a.x + hit_time * vx - 1E-5)
	end

	if sign_y >= 0 then
		hit_y = math.floor(a.y + hit_time * vy + 1E-5)
	else
		hit_y = math.ceil(a.y + hit_time * vy - 1E-5)
	end

	return hit_x, hit_y, hit_time, nx, ny
end

local rx, ry, norm

function physics.collision_aabb_sweep_slope(a, b, vx, vy, slope, slope_y_offset, bhm)
	ax, bx =  a.x, b.x
	sign_x = mymath.sign(vx)
	scale_x = 1 / vx

	ay, by =  a.y, b.y
	sign_y = mymath.sign(vy)
	scale_y = 1 / vy

	if vx ~= 0 then
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

	if vy ~= 0 then
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
	rx = ax - (a.half_w - 1E-5) * mymath.sign(slope)
	ry = ay + a.half_h - 1E-5

	if vx ~= 0 then
		-- find the x distance traveled; divide by vx to find near_time_q
		vslope = vy / vx

		-- x coord of the contact point is (1/(slope - vslope))(slope * bx - by - vslope * rx + ry)
		near_time_q = ((slope * bx - by - slope_y_offset - vslope * rx + ry) / (slope - vslope) - rx) * scale_x
	else
		-- x is fixed: find the y distance and divide by vy to find near_time_q

		-- y coord of the contact point is (slope * (rx - bx) + by)
		near_time_q = (slope * (rx - bx) + by + slope_y_offset - ry) * scale_y
	end

	if ry > slope * (rx - bx) + by + slope_y_offset then
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
		norm = math.sqrt(math.pow(slope, 2) + 1)
		nx = slope / norm
		ny = - 1 / norm

		if sign_x >= 0 then
			hit_x = math.floor(a.x + hit_time * vx + 1E-5)
		else
			hit_x = math.ceil(a.x + hit_time * vx - 1E-5)
		end

		if sign_y >= 0 then
			hit_y = math.floor(a.y + hit_time * vy + 1E-5)
		else
			hit_y = math.ceil(a.y + hit_time * vy - 1E-5)
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
			hit_x = math.floor(a.x + hit_time * vx + 1E-5)
		else
			hit_x = math.ceil(a.x + hit_time * vx - 1E-5)
		end

		if sign_y >= 0 then
			hit_y = math.floor(a.y + hit_time * vy + 1E-5)
		else
			hit_y = math.ceil(a.y + hit_time * vy - 1E-5)
		end
	end

	return hit_x, hit_y, hit_time, nx, ny
end

-------------

local grid_x1, grid_x2, grid_y1, grid_y2
local block_type
local box
local hit
local mx, my, mt, mnx, mny

function physics.map_collision_aabb(a)
	grid_x1 = map.grid_at_pos(a.x - a.half_w - 1)
	grid_x2 = map.grid_at_pos(a.x + a.half_w + 1)
	grid_y1 = map.grid_at_pos(a.y - a.half_h - 1)
	grid_y2 = map.grid_at_pos(a.y + a.half_h + 1)

	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope and
				   not (mainmap:grid_has_collision(i, j-1) and (block_type == "slope_23_b" or block_type == "slope_-23_b")) then
					if physics.collision_aabb_slope(
						a, box,
						block_data[block_type].slope, block_data[block_type].slope_y_offset,
						block_data.get_box_half_multipliers(block_type)) then
						return true
					end
				elseif physics.collision_aabb_aabb(a, box) then
					return true
				end
			end
		end
	end

	return false
end

function physics.map_collision_aabb_sweep(a, vx, vy)
	grid_x1 = map.grid_at_pos(math.min(a.x - a.half_w - 1, a.x - a.half_w + vx - 1))
	grid_x2 = map.grid_at_pos(math.max(a.x + a.half_w + 1, a.x + a.half_w + vx + 1))
	grid_y1 = map.grid_at_pos(math.min(a.y - a.half_h - 1, a.y - a.half_h + vy - 1))
	grid_y2 = map.grid_at_pos(math.max(a.y + a.half_h + 1, a.y + a.half_h + vy + 1))

	mt = 1
	hit = nil
	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope and
				   not (mainmap:grid_has_collision(i, j-1) and (block_type == "slope_23_b" or block_type == "slope_-23_b"))then
					hx, hy, ht, nx, ny = physics.collision_aabb_sweep_slope(
						a, box, vx, vy,
						block_data[block_type].slope, block_data[block_type].slope_y_offset,
						block_data.get_box_half_multipliers(block_type))
				else
					hx, hy, ht, nx, ny = physics.collision_aabb_sweep(a, box, vx, vy)
				end

				if ht and ht < mt then
					if (nx ~= 0 and ny ~= 0) or not mainmap:grid_blocks_dir(i + nx, j + ny, map.orth_normal_to_dir(-nx, -ny)) then
						hit = {"block", i, j}
						mt = ht
						mx = hit_x
						my = hit_y
						mnx = nx
						mny = ny
						if nx > 0 then
							mx = math.ceil(mx)
						elseif nx < 0 then
							mx = math.floor(mx)
						end
						if ny > 0 then
							my = math.ceil(my)
						elseif ny < 0 then
							my = math.floor(my)
						end
					end
				end
			end
		end
	end

	if not hit then
		mx, my = a.x + vx, a.y + vy
		mnx, mny = 0, 0
	end

	return hit, mx, my, mt, mnx, mny
end

local vx, vy
local ijhx, ijhy, ijht, ijnx, ijny
local rt, rvx, rvy

function physics.map_collision_test(a)
	vx = mouse.x + camera.x - a.x
	vy = mouse.y + camera.y - a.y

	grid_x1 = map.grid_at_pos(math.min(a.x - a.half_w, a.x - a.half_w + vx))
	grid_x2 = map.grid_at_pos(math.max(a.x + a.half_w, a.x + a.half_w + vx))
	grid_y1 = map.grid_at_pos(math.min(a.y - a.half_h, a.y - a.half_h + vy))
	grid_y2 = map.grid_at_pos(math.max(a.y + a.half_h, a.y + a.half_h + vy))

	mx, my, mt, mnx, mny = a.x + vx, a.y + vy, 1, 0, 0

	for i = grid_x1, grid_x2 do
		for j = grid_y1, grid_y2 do
			if mainmap:grid_has_collision(i, j) then
				block_type = mainmap:block_at(i, j)
				box = map.bounding_box(i, j)

				if block_data[block_type].slope then
					ijhx, ijhy, ijht, ijnx, ijny = physics.collision_aabb_sweep_slope(
						a, box, vx, vy,
						block_data[block_type].slope, block_data[block_type].slope_y_offset,
						block_data.get_box_half_multipliers(block_type))
				else
					ijhx, ijhy, ijht, ijnx, ijny = physics.collision_aabb_sweep(a, box, vx, vy)
				end

				if ijht and ijht < mt then
					mt = hit_time
					mx = ijhx
					my = ijhy
					mnx = nx
					mny = ny
					if mnx > 0 then
							mx = math.ceil(mx)
						elseif nx < 0 then
							mx = math.floor(mx)
						end
						if mny > 0 then
							my = math.ceil(my)
						elseif ny < 0 then
							my = math.floor(my)
						end
				end
			end
		end
	end

	if mt < 1 then
		rt = 1 - mt
		-- px = ny
		-- py = -nx
		-- wx = vx * rem_time
		-- wy = vy * rem_time

		-- (vx rt, vy rt) dot (ny, -nx)
		r = vx * rt * mny - vy * rt * mnx

		rvx = r * mny
		rvy = r * (-mnx)
	end

	-- draw debug tracer
	if mt == 1 then
		love.graphics.setColor(color.blue)
	else
		love.graphics.setColor(color.orange)
	end
	love.graphics.line(a.x - camera.x, a.y - camera.y, mx - camera.x, my - camera.y)
	love.graphics.rectangle('line', mx - a.half_w - camera.x + 0.5, my - a.half_h - camera.y + 0.5, a.half_w * 2 - 1, a.half_h * 2 - 1)
	love.graphics.setColor(color.white)
	-- love.graphics.rectangle('line', a.x - camera.x, a.y - camera.y, a.w, a.h)
	if mt < 1 then
		love.graphics.line(mx - camera.x, my - camera.y, mx - camera.x + rvx, my - camera.y + rvy)
		love.graphics.setColor(color.rouge)
		love.graphics.line(mx - camera.x, my - camera.y, mx - camera.x + mnx * 8, my - camera.y + mny * 8)
		love.graphics.setColor(color.white)
	end
end

function physics.map_collision_test2(a)
	if physics.map_collision_aabb(a) then
		love.graphics.setColor(color.orange)
	else
		love.graphics.setColor(color.blue)
	end
	love.graphics.rectangle('line', a.x - a.half_w - camera.x + 0.5, a.y - a.half_h - camera.y + 0.5, a.half_w * 2 - 1, a.half_h * 2 - 1)
	love.graphics.setColor(color.white)
end

return physics
