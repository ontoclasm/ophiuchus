require "requires"

function love.load()
	guitime, ctime, guiframe, cframe = 0,0,0,0

	window = {}
	window.w, window.h = 960, 600
	love.window.setMode(window.w, window.h)
	love.graphics.setBackgroundColor(color.bg)

	shader_desaturate = love.graphics.newShader("desaturate.lua")

	controller = controls.setup()

	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
	mouse = {x = love.mouse.getX(), y = love.mouse.getY()}

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

	gravity = 2000

	player = actor:new(
		{
			class = "player", id = 1, name = "player1", faction = "player",
			x = 250, y = 250, half_w = 7, half_h = 7,
			dx = 0, dy = 0,
			sprite = "player", color = color.rouge, flash_color = color.white, flash_time = 0,
			facing = 'r', anim_start = ctime,
			ai = {control = "player"}, controls = {},
			top_speed = 250,
			walk_accel = 1200, walk_friction = 500,
			jump_speed = 550, air_accel = 700,
			dash_speed = 700, dash_dur = 0.3, dash_cooldown = 0.1,
			touching_floor = false, double_jumps = 0, double_jumps_max = 2,
			hp = 1000, status = {},
			shot_cooldown = 0, cof = 0, cof_factor = 0
		})
end

local time_acc = 0
local TIMESTEP = 1/60
function love.update(dt)
	time_acc = time_acc + dt

	while time_acc >= TIMESTEP do
		guitime = guitime + TIMESTEP
		guiframe = guiframe + 1

		-- handle input
		controller:update()
		if game_state == "play" then
			if controller:pressed('menu') then
				pause()
				return
			end
			ctime = ctime + TIMESTEP
			cframe = cframe + 1

			-- update everything
			player:update(TIMESTEP)
			camera.update(TIMESTEP)
		elseif game_state == "pause" then
			if controller:pressed('menu') then unpause() end
			if controller:pressed('view') then love.event.push("quit") end
		end
		time_acc = time_acc - TIMESTEP
	end
end

function love.draw()
	if game_state == "pause" then
		love.graphics.setShader(shader_desaturate)
	end

	img.update_tileset_batch()
	love.graphics.draw(img.tileset_batch, -(camera.x % 32), -(camera.y % 32))

	player:draw()

	-- gui

	if game_state == "play" then
		love.graphics.draw(img.cursor, mouse.x - 2, mouse.y - 2)
	end

	love.graphics.setColor(player.color)
	love.graphics.print(player.hp, 20, 20)
	love.graphics.setColor(color.white)
	-- debug msg
	love.graphics.print("Time: "..string.format("%.2f", ctime), 20, window.h - 140)
	love.graphics.print("FPS: "..love.timer.getFPS(), 20, window.h - 120)
	love.graphics.print("p: "..mymath.round(player.x)..", "..mymath.round(player.y), 20, window.h - 100)
	love.graphics.print("d: "..mymath.round(player.dx)..", "..mymath.round(player.dy), 20, window.h - 80)
	local dc = love.graphics.getStats()
	love.graphics.print("draws: "..dc.drawcalls, 20, window.h - 60)
	love.graphics.print(map.grid_at_pos(mouse.x + camera.x)..", "..map.grid_at_pos(mouse.y + camera.y), 20, window.h - 40)

	-- physics.map_collision_test(player)

	if game_state == "pause" then
		love.graphics.setShader()
		draw_pause_menu()
	end
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
	love.graphics.circle("fill", window.w/2, window.h/2, 200)
	love.graphics.setColor(color.white)
	love.graphics.printf("Press Q to quit", math.floor(window.w/2 - 200), math.floor(window.h/2 - font:getHeight()/2), 400, "center")
	love.graphics.setColor(color.white)
	love.graphics.draw(img.cursor, love.mouse.getX() - 2, love.mouse.getY() - 2)
end
