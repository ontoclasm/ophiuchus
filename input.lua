local input = {
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
	},

	pairs = {dpad = {'dp_left', 'dp_right', 'dp_up', 'dp_down'}}
}

function input.setup_controller()
	controller = baton.new(input.bindings) -- set controller.joystick to a Joystick later
	controller.deadzone = 0.2
	return controller
end

function love.joystickadded(joystick)
	controller.joystick = joystick
end

return input
