local controls = {}

local last_key_dir = { l = 0, r = 0, u = 0, d = 0 } -- left right up down
local doubletap_time = 0.2 -- time to double-tap
local aim_distance = 32

function controls.update()
	for k,v in pairs(c_controls) do
		controls[v.ai](k,v)
	end
end

function controls.player(k,a)
	a.move_x, a.move_y = 0, 0
	if controller:down('dp_left') then a.move_x = a.move_x - 1 end
	if controller:down('dp_right') then a.move_x = a.move_x + 1 end
	if controller:down('dp_up') then a.move_y = a.move_y - 1 end
	if controller:down('dp_down') then a.move_y = a.move_y + 1 end

	-- a.jump = controller:pressed('l1')
	-- a.float = controller:down('l1')

	-- if controller:pressed('x') and a.weapon.ammo ~= a.weapon.ammo_max then
	-- 	a.reload = true
	-- end
	-- if controller:pressed('y') then
	-- 	a.swap_weapons = true
	-- end

	a.fire_pressed = controller:pressed('r1')
	a.fire_down = controller:down('r1')

	a.altfire_pressed = controller:down('r2')
	a.altfire_down = controller:down('r2')

	-- if controller:getActiveDevice() == "joystick" then
	-- 	jx = controller:get('r_right') - controller:get('r_left')
	-- 	jy = controller:get('r_down') - controller:get('r_up')
	-- 	if jx == 0 and jy == 0 then
	-- 		if a.facing == 'r' then
	-- 			mouse = {x = player.x + aim_distance - camera.x,
	-- 					 y = player.y - camera.y}
	-- 		else
	-- 			mouse = {x = player.x - aim_distance - camera.x,
	-- 					 y = player.y - camera.y}
	-- 		end
	-- 	else
	-- 		norm = math.sqrt(jx * jx + jy * jy)
	-- 		mouse = {x = player.x + mymath.round(aim_distance * (jx / norm)) - camera.x,
	-- 				 y = player.y + mymath.round(aim_distance * (jy / norm)) - camera.y}
	-- 	end
	-- else
	--	mouse = {x = lovepixels.mousex, y = lovepixels.mousey}
	-- end

	a.aim_x, a.aim_y = mouse.x + camera.x, mouse.y + camera.y

	-- face the cursor
	-- if a.aim_x >= a.x then
	-- 	a.facing = 'r'
	-- else
	-- 	a.facing = 'l'
	-- end
end

function controls.mook(k,a)
	if a.wake_frame <= game_frame then
		if (not a.ai_state) or mymath.one_chance_in(10) then
			-- rethink
			if mymath.one_chance_in(2) then
				a.ai_state = "random"
			else
				a.ai_state = "hunt"
			end
		end

		if a.ai_state == "random" then
			a.move_x = love.math.random(3) - 2
			a.move_y = love.math.random(3) - 2
		elseif a.ai_state == "hunt" then
			local pos, player_pos = c_positions[k], c_positions[player_id]
			local dx, dy = mymath.normalize(player_pos.x - pos.x, player_pos.y - pos.y)
			a.move_x = mymath.abs_floor(dx * 1.99)
			a.move_y = mymath.abs_floor(dy * 1.99)
		end

		a.wake_frame = game_frame + 10 + love.math.random(40)
	end
end

return controls
