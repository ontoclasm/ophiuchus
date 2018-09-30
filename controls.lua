local controls = {
	bindings = {
		-- aim controls
		r_left = {'key:left', 'axis:rightx-'},
		r_right = {'key:right', 'axis:rightx+'},
		r_up = {'key:up', 'axis:righty-'},
		r_down = {'key:down', 'axis:righty+'},
		-- movement
		dp_left = {'key:a', 'button:dpleft'},
		dp_right = {'key:d', 'button:dpright'},
		dp_up = {'key:w', 'button:dpup'},
		dp_down = {'key:s', 'button:dpdown'},
		-- buttons
		a = {'key:g', 'button:a'},
		x = {'key:r', 'button:x'},
		y = {'key:t', 'button:y'},
		r1 = {'mouse:1', 'button:rightshoulder'},
		r2 = {'mouse:2'},
		l1 = {'key:space', 'button:leftshoulder'},

		menu = {'key:escape', 'button:start'},
		view = {'key:q', 'button:back'},
	}
}

function controls.setup()
	controller = baton.new(controls.bindings) -- set controller.joystick to a Joystick later
	controller.pairs = {dpad = {'dp_left', 'dp_right', 'dp_up', 'dp_down'}}
	controller.deadzone = 0.2
	return controller
end

local last_key_dir = { l = 0, r = 0, u = 0, d = 0 } -- left right up down
local doubletap_time = 0.2 -- time to double-tap
local aim_distance = 300
function controls.process(a)
	a.controls.x, a.controls.y = 0, 0
	if controller:down('dp_left') then a.controls.x = a.controls.x - 1 end
	if controller:down('dp_right') then a.controls.x = a.controls.x + 1 end
	if controller:down('dp_up') then a.controls.y = a.controls.y - 1 end
	if controller:down('dp_down') then a.controls.y = a.controls.y + 1 end

	a.controls.jump = controller:pressed('l1')
	a.controls.float = controller:down('l1')

	if controller:pressed('x') and a.weapon.ammo ~= a.weapon.ammo_max then
		a.controls.reload = true
	end
	if controller:pressed('y') then
		a.controls.swap_weapons = true
	end

	a.controls.fire_1 = controller:down('r1')
	a.controls.fire_2 = controller:down('r2')

	if controller:getActiveDevice() == "joystick" then
		jx = controller:get('r_right') - controller:get('r_left')
		jy = controller:get('r_down') - controller:get('r_up')
		if jx == 0 and jy == 0 then
			if a.facing == 'r' then
				mouse = {x = player.x + aim_distance - camera.x,
						 y = player.y - camera.y}
			else
				mouse = {x = player.x - aim_distance - camera.x,
						 y = player.y - camera.y}
			end
		else
			norm = math.sqrt(jx * jx + jy * jy)
			mouse = {x = player.x + mymath.round(aim_distance * (jx / norm)) - camera.x,
					 y = player.y + mymath.round(aim_distance * (jy / norm)) - camera.y}
		end
	else
		mouse = {x = lovepixels.mousex, y = lovepixels.mousey}
	end
	a.controls.aim_x, a.controls.aim_y = mouse.x + camera.x, mouse.y + camera.y

	-- face the cursor
	if a.controls.aim_x >= a.x then
		a.facing = 'r'
	else
		a.facing = 'l'
	end
end

function love.joystickadded(joystick)
	controller.joystick = joystick
end

return controls
