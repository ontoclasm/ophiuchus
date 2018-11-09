require "requires"

function love.load()
	guitime, ctime, guiframe, cframe = 0,0,0,0

	lovepixels:load() -- use the largest integer scale that fits on screen
	window = {}
	window.w, window.h = 320, 180
	love.graphics.setBackgroundColor(color.rouge)

	shader_desaturate = love.graphics.newShader("desaturate.lua")

	controller = input.setup_controller()
	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
	mouse = {x = 0, y = 0}

	font = love.graphics.newImageFont("art/font.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"")
	love.graphics.setFont(font)
	love.graphics.setLineWidth(1)

	game_state = "play"

	mainmap = map:new(48, 32)
	mainmap:fill_main()

	img.setup()
	game_canvas = love.graphics.newCanvas()
	game_canvas:setFilter("linear", "nearest")

	gravity = 200

	-- component holders
	c_identities = {}
	c_positions = {}
	c_movements = {}
	c_controls = {}
	c_drawables = {}

	player_id = idcounter.get_id("entity")
	c_identities[player_id] =	{name = "Player"}
	c_positions[player_id] =	{x = 50, y = 50, half_w = 4, half_h = 4}
	c_movements[player_id] =	{dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,
								 top_speed = 100, accel = 400}
	c_controls[player_id] =		{
		ai = "player",
		x = 0, y = 0,
		aim_x = 0, aim_y = 0,
		fire_pressed = false, fire_down = false,
		altfire_pressed = false, altfire_down = false,
	}
	c_drawables[player_id] =	{sprite = "player", color = color.rouge,
								 flash_color = color.white, flash_time = 0,}


	-- player = actor:new(
	-- 	{
	-- 		class = "player", id = 1, name = "player1", faction = "player",
	-- 		x = 50, y = 50,
	-- 		dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,
	-- 		half_w = 4, half_h = 4,
	-- 		sprite = "player", color = color.rouge, flash_color = color.white, flash_time = 0,
	-- 		facing = 'r', anim_start = ctime,
	-- 		ai_type = "player", controls = player_controls,
	-- 		top_speed = 100,
	-- 		walk_accel = 400, walk_friction = 400,
	-- 		jump_speed = 120, air_accel = 200,
	-- 		dash_speed = 200, dash_dur = 0.3, dash_cooldown = 0.1,
	-- 		touching_floor = false, double_jumps = 0, double_jumps_max = 2,
	-- 		hp = 1000, status = {},
	-- 		shot_cooldown = 0, cof = 0, cof_factor = 0
	-- 	})
end

local time_acc = 0
local TIMESTEP = 1/60
function love.update(dt)
	-- update lovepixel stuff
	lovepixels:pixelMouse()
	lovepixels:calcOffset()

	time_acc = time_acc + dt

	while time_acc >= TIMESTEP do
		guitime = guitime + TIMESTEP
		guiframe = guiframe + 1

		-- handle input
		controller:update()
		mouse = {x = lovepixels.mousex, y = lovepixels.mousey}

		if game_state == "play" then
			if controller:pressed('menu') then
				pause()
				return
			end
			ctime = ctime + TIMESTEP
			cframe = cframe + 1

			-- update all systems
			controls.update(TIMESTEP)
			movement.update(TIMESTEP)
			camera.update(TIMESTEP)

		elseif game_state == "pause" then
			if controller:pressed('menu') then unpause() end
			if controller:pressed('view') then love.event.push("quit") end
		end
		time_acc = time_acc - TIMESTEP
	end
end

function love.draw()
	lovepixels:drawGameArea()
	if game_state == "pause" then
		love.graphics.setShader(shader_desaturate)
	end

	-- love.graphics.setCanvas(game_canvas)
	-- love.graphics.clear()

	img.render()

	-- gui

	if game_state == "play" then
		love.graphics.draw(img.cursor, mouse.x - 2, mouse.y - 2)
	end

	-- love.graphics.setColor(player.color)
	-- love.graphics.print(player.hp, 20, 20)
	love.graphics.setColor(color.white)
	-- debug msg
	love.graphics.print("Time: "..string.format("%.2f", ctime), 2, window.h - 96)
	love.graphics.print("FPS: "..love.timer.getFPS(), 2, window.h - 80)
	love.graphics.print("p: "..c_positions[player_id].x..", "..c_positions[player_id].y, 2, window.h - 64)
	love.graphics.print("d: "..mymath.round(c_movements[player_id].dx)..", "..mymath.round(c_movements[player_id].dy), 2, window.h - 48)
	local dc = love.graphics.getStats()
	love.graphics.print("draws: "..dc.drawcalls, 2, window.h - 32)
	love.graphics.print(map.grid_at_pos(mouse.x + camera.x)..", "..map.grid_at_pos(mouse.y + camera.y), 2, window.h - 16)

	physics.map_collision_test(c_positions[player_id])

	if game_state == "pause" then
		love.graphics.setShader()
		draw_pause_menu()
	end

	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
	lovepixels:endDrawGameArea()
end

function love.keypressed(key, unicode)
	-- debug
	if key == "3" then
		mainmap:set_block("slope_45", map.grid_at_pos(mouse.x + camera.x), map.grid_at_pos(mouse.y + camera.y))
		redraw = true
	end
	if key == "8" then
		player.dy = player.dy - 50000
	end
	if key == "9" then
		player.dx = player.dx - 50000
	end
	if key == "0" then
		player.dx = player.dx + 50000
		player.dy = player.dy - 50000
	end
end

function love.focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		if game_state ~= "pause" then pause() end
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

function pause()
	game_state = "pause"
	pause_mouse_x, pause_mouse_y = love.mouse.getPosition()
end

function unpause()
	game_state = "play"
	love.mouse.setPosition(pause_mouse_x, pause_mouse_y)
end

function draw_pause_menu()
	love.graphics.setColor(color.rouge)
	love.graphics.circle("fill", window.w/2, window.h/2, 50)
	love.graphics.setColor(color.white)
	love.graphics.printf("Press Q to quit", math.floor(window.w/2 - 100), math.floor(window.h/2 - font:getHeight()/2), 200, "center")
	love.graphics.setColor(color.white)
	love.graphics.draw(img.cursor, love.mouse.getX() - 2, love.mouse.getY() - 2)
end
