local player_controls = {
	x = 0, y = 0,
	aim_x = 0, aim_y = 0,
	fire_pressed = false, fire_down = false,
	altfire_pressed = false, altfire_down = false,
}

local last_key_dir = { l = 0, r = 0, u = 0, d = 0 } -- left right up down
local doubletap_time = 0.2 -- time to double-tap
local aim_distance = 32
function player_controls.update()
	player_controls.x, player_controls.y = 0, 0
	if controller:down('dp_left') then player_controls.x = player_controls.x - 1 end
	if controller:down('dp_right') then player_controls.x = player_controls.x + 1 end
	if controller:down('dp_up') then player_controls.y = player_controls.y - 1 end
	if controller:down('dp_down') then player_controls.y = player_controls.y + 1 end

	-- player_controls.jump = controller:pressed('l1')
	-- player_controls.float = controller:down('l1')

	-- if controller:pressed('x') and a.weapon.ammo ~= a.weapon.ammo_max then
	-- 	player_controls.reload = true
	-- end
	-- if controller:pressed('y') then
	-- 	player_controls.swap_weapons = true
	-- end

	player_controls.fire_pressed = controller:pressed('r1')
	player_controls.fire_down = controller:down('r1')

	player_controls.altfire_pressed = controller:down('r2')
	player_controls.altfire_down = controller:down('r2')

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

	player_controls.aim_x, player_controls.aim_y = mouse.x + camera.x, mouse.y + camera.y

	-- face the cursor
	-- if player_controls.aim_x >= a.x then
	-- 	a.facing = 'r'
	-- else
	-- 	a.facing = 'l'
	-- end
end

return player_controls
