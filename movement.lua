local movement = {}

local hit, block_type, pos, controls, vx, vy
function movement.update(dt)
	for k,v in pairs(c_movements) do
		pos = c_positions[k]

		-- apply controls if they exist
		controls = c_controls[k]
		if controls then
			-- separate out the integer part of our motion
			if controls.x ~= 0 or controls.y ~= 0 then
				if controls.x == 0 then
					if controls.y * v.dy < 0 then
						-- quick reverse
						v.dy = v.dy * 0.9
					end
					v.dx = mymath.abs_subtract(v.dx, v.accel * dt)
					v.dy = v.dy + controls.y * v.accel * dt
				elseif controls.y == 0 then
					if controls.x * v.dx < 0 then
						-- quick reverse
						v.dx = v.dx * 0.9
					end
					v.dx = v.dx + controls.x * v.accel * dt
					v.dy = mymath.abs_subtract(v.dy, v.accel * dt)
				else
					if controls.x * v.dx < 0 then
						-- quick reverse
						v.dx = v.dx * 0.9
					end
					if controls.y * v.dy < 0 then
						-- quick reverse
						v.dy = v.dy * 0.9
					end
					v.dx = v.dx + controls.x * v.accel * dt * ROOT_2_OVER_2
					v.dy = v.dy + controls.y * v.accel * dt * ROOT_2_OVER_2
				end
			else
				v.dx = mymath.abs_subtract(v.dx, v.accel * dt)
				v.dy = mymath.abs_subtract(v.dy, v.accel * dt)
			end
		end

		if v.top_speed then
					-- slow down if we're going too fast
			local current_speed = mymath.vector_length(v.dx, v.dy)
			if current_speed > v.top_speed then
				v.dx, v.dy = mymath.set_vector_length(v.dx, v.dy, math.max(v.top_speed, current_speed - v.accel * dt))
			end
		end

		-- calculate how far to move this frame
		-- cut off the fractional part; we'll re-add it next frame
		v.dx_acc = v.dx_acc + v.dx * dt
		v.dy_acc = v.dy_acc + v.dy * dt
		vx, vy = mymath.abs_floor(v.dx_acc), mymath.abs_floor(v.dy_acc)
		v.dx_acc = v.dx_acc - vx
		v.dy_acc = v.dy_acc - vy

		if v.map_collision == "scrape" then
			-- collide with the map tiles we're inside
			-- should return ONLY INTEGERS for mx,my
			hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(pos, vx, vy)

			if hit then
				-- change our vector based on the slope we hit
				r = v.dx * ny - v.dy * nx

				v.dx = r * ny
				v.dy = r * (-nx)

				-- delete our accumulators if they point into the surface
				if nx ~= 0 then
					v.dx_acc = 0
				end
				if ny ~= 0 then
					v.dy_acc = 0
				end

				if m_time < 1 then
					-- try continuing our movement along the new vector
					-- if vx >= 1 and ny ~= 0 and nx < 0 then
					-- 	-- going right into a slope up and to the right
					-- 	hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = v.half_h, half_w = v.half_w},
					-- 		mymath.abs_ceil(v.dx * dt * (1 - m_time)), -mymath.abs_ceil(v.dx * dt * (1 - m_time)))
					-- elseif vx <= -1 and ny ~= 0 and nx > 0 then
					-- 	-- going left into a slope up and to the left
					-- 	hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = v.half_h, half_w = v.half_w},
					-- 		mymath.abs_ceil(v.dx * dt * (1 - m_time)), mymath.abs_ceil(v.dx * dt * (1 - m_time)))
					-- else
						hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep({x = mx, y = my, half_h = pos.half_h, half_w = pos.half_w},
																					   mymath.abs_ceil(v.dx * dt * (1 - m_time)),
																					   mymath.abs_ceil(v.dy * dt * (1 - m_time)))
					-- end

					if hit then
						r = v.dx * ny - v.dy * nx

						v.dx = r * ny
						v.dy = r * (-nx)
					end
				end
			end

			pos.x = mx
			pos.y = my
		elseif v.map_collision == "explode" then
			-- collide with the map tiles we're inside
			-- should return ONLY INTEGERS for mx,my
			hit, mx, my, m_time, nx, ny = physics.map_collision_aabb_sweep(pos, vx, vy)

			if hit then
				ecs.delete_entity(k)
			else
				pos.x = mx
				pos.y = my
			end
		else
			-- no map collision
			pos.x = pos.x + vx
			pos.y = pos.y + vy
		end

		-- check if we're on the ground
		v.grounded = movement.touching_down(pos)
	end
end

function movement.touching_down(a)
	return physics.map_collision_aabb({x = a.x, y = a.y + a.half_h, half_w = a.half_w, half_h = 1})
end

return movement
