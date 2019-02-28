local PlayerControlSystem = tiny.processingSystem(class "PlayerControlSystem")

PlayerControlSystem.filter = tiny.requireAll("player_controlled", "controls")

local last_key_dir = { l = 0, r = 0, u = 0, d = 0 } -- left right up down
local doubletap_time = 0.2 -- time to double-tap
local aim_distance = 32

function PlayerControlSystem:process(e, dt)
	e.controls.move_x, e.controls.move_y = 0, 0
	if controller:down('dp_left') then e.controls.move_x = e.controls.move_x - 1 end
	if controller:down('dp_right') then e.controls.move_x = e.controls.move_x + 1 end
	if controller:down('dp_up') then e.controls.move_y = e.controls.move_y - 1 end
	if controller:down('dp_down') then e.controls.move_y = e.controls.move_y + 1 end

	-- a.jump = controller:pressed('l1')
	-- a.float = controller:down('l1')

	-- if controller:pressed('x') and a.weapon.ammo ~= a.weapon.ammo_max then
	-- 	a.reload = true
	-- end
	-- if controller:pressed('y') then
	-- 	a.swap_weapons = true
	-- end

	e.controls.fire_pressed = controller:pressed('r1')
	e.controls.fire_down = controller:down('r1')

	e.controls.altfire_pressed = controller:pressed('r2')
	e.controls.altfire_down = controller:down('r2')

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

	e.controls.aim_x, e.controls.aim_y = mouse_x + camera.x, mouse_y + camera.y

	-- face the cursor
	-- if a.aim_x >= a.x then
	-- 	a.facing = 'r'
	-- else
	-- 	a.facing = 'l'
	-- end
end

return PlayerControlSystem
