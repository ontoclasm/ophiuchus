require "requires"

function love.load()
	gui_frame, game_frame = 0,0
	hitstop_frames = 0

	slogpixels:load() -- use the largest integer scale that fits on screen
	window = {}
	window.w, window.h = 320, 180
	love.graphics.setBackgroundColor(color.rouge)

	shader_desaturate = love.graphics.newShader("desaturate.lua")

	controller = input.setup_controller()
	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
	mouse = {x = 0, y = 0}

	font = love.graphics.newImageFont("art/font_small.png",
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
	blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * img.tile_size, (mainmap.height + 4) * img.tile_size)
	blood_canvas:setFilter("linear", "nearest")

	world = tiny.world(
		require ("systems/PlayerControlSystem")(),
		require ("systems/AIControlSystem")(),
		require ("systems/WeaponSystem")(),
		require ("systems/PhysicsSystem")(),
		require ("systems/TimerSystem")(),
		img.DrawingSystem
	)

	player = tiny.addEntity(world, {
		id = idcounter.get_id("entity"),
		name = "Player",
		team = 1,
		birth_frame = 0,

		pos = {x = 50, y = 50, half_w = 3, half_h = 3},
		vel = {dx = 0, dy = 0, dx_acc = 0, dy_acc = 0},
		walker = {
			top_speed = 1.5, accel = 0.15,
		},

		player_controlled = true,
		controls = {
			x = 0, y = 0,
			aim_x = 0, aim_y = 0,
			fire_pressed = false, fire_down = false,
			altfire_pressed = false, altfire_down = false,
			wake_frame = 0,
		},
		collides = {
			entity_filter = function(other_e)
				return other_e.team ~= 1
			end,
			collide_with_map = function(hit)
				return "slide"
			end,
			collide_with_entity = function(hit, already_applied)
				if not already_applied then
					if player.drawable then
						player.drawable.flash_end_frame = game_frame + 20
					end
					local angle = math.atan2(player.pos.y - hit.object.entity.pos.y, player.pos.x - hit.object.entity.pos.x)
					player.vel.dx = player.vel.dx + 2 * math.cos(angle)
					player.vel.dy = player.vel.dy + 2 * math.sin(angle)
				end
				return "end"
			end,
			get_collided_with = function(e, hit)
				if player.drawable then
					player.drawable.flash_end_frame = game_frame + 20
				end
				local angle = math.atan2(player.pos.y - e.pos.y, player.pos.x - e.pos.x)
				player.vel.dx = player.vel.dx + 2 * math.cos(angle)
				player.vel.dy = player.vel.dy + 2 * math.sin(angle)
			end,
		},
		drawable = {
			sprite = "player", color = color.rouge,
			flash_color = color.white, flash_end_frame = 0,
		},
		weapon = {model = "assault", ready_frame = 0},
	})

	local found, start_x, start_y = false, nil, nil
	for i = 1, 20 do
		found = false
		while not found do
			start_x = love.math.random(1, mainmap.width * img.tile_size)
			start_y = love.math.random(1, mainmap.height * img.tile_size)
			found = not collision.map_collision_aabb({x = start_x, y = start_y, half_w = 3, half_h = 3})
		end
		tiny.addEntity(world, Enemy:new(start_x, start_y))
	end
end

local time_acc = 0
local TIMESTEP = 1/60
function love.update(dt)
	-- update lovepixel stuff
	slogpixels:pixelMouse()
	slogpixels:calcOffset()

	time_acc = time_acc + dt

	while time_acc >= TIMESTEP do
		gui_frame = gui_frame + 1

		-- handle input
		controller:update()
		mouse.x = slogpixels.mousex
		mouse.y = slogpixels.mousey

		if game_state == "play" then
			if controller:pressed('menu') then
				pause()
				return
			end

			if hitstop_frames > 0 then
				hitstop_frames = hitstop_frames - 1
			else
				game_frame = game_frame + 1

				tiny.update(world, TIMESTEP)

				-- -- update all systems
				-- for k,v in pairs(c_timeouts) do
				-- 	if game_frame >= v then
				-- 		-- respond to timing out?
				-- 		ecs.delete_entity(k)
				-- 	end
				-- end

				-- controls.update()
				-- weapons.update()
				-- mortals.update()
				-- movement.update()

				camera.update()
			end
		elseif game_state == "pause" then
			if controller:pressed('menu') then unpause() end
			if controller:pressed('view') then love.event.push("quit") end
		end
		time_acc = time_acc - TIMESTEP
	end
end

function love.draw()
	slogpixels:drawGameArea()
	if game_state == "pause" then
		love.graphics.setShader(shader_desaturate)
	end

	-- love.graphics.setCanvas(game_canvas)
	love.graphics.clear(color.bg)

	img.render()

	-- gui

	-- if game_state == "play" then
	-- 	love.graphics.draw(img.cursor, mouse.x - 2, mouse.y - 2)
	-- end

	-- love.graphics.setColor(player.color)
	-- love.graphics.print(player.hp, 20, 20)
	love.graphics.setColor(color.white)
	-- debug msg
	love.graphics.print("Time: "..string.format("%.0f", game_frame / 60), 2, window.h - 96)
	love.graphics.setColor(color.yellow)
	love.graphics.print("FPS: "..love.timer.getFPS(), 2, window.h - 80)
	love.graphics.setColor(color.ltblue)
	love.graphics.print("Pos: "..player.pos.x..", "..player.pos.y, 2, window.h - 64)
	love.graphics.print("Vel: "..string.format("%+.2f", player.vel.dx)..", "..string.format("%+.2f", player.vel.dy), 2, window.h - 48)
	-- love.graphics.print("pressed: "..(c_controls[player_id].fire_pressed and "t" or "f") ..", down: "..(c_controls[player_id].fire_down and "t" or "f"), 2, window.h - 48)
	love.graphics.setColor(color.green)
	local dc = love.graphics.getStats()
	love.graphics.print("Draws: "..dc.drawcalls, 2, window.h - 32)
	-- love.graphics.print(map.grid_at_pos(mouse.x + camera.x)..", "..map.grid_at_pos(mouse.y + camera.y), 2, window.h - 16)
	-- love.graphics.setColor(color.black)
	-- love.graphics.print("Jackdaws Love My Big Sphinx of Quartz * 1234567890", 3, window.h - 15)
	-- love.graphics.setColor(color.orange)
	-- love.graphics.print("Jackdaws Love My Big Sphinx of Quartz * 1234567890", 2, window.h - 16)
	love.graphics.print("Entities: "..tiny.getEntityCount(world)..", Systems: "..tiny.getSystemCount(world), 2, window.h - 16)

	-- collision.debug_map_collision_sweep(c_positions[player_id])
	-- collision.debug_map_collision({x = mouse.x + camera.x, y = mouse.y + camera.y, half_w = 4, half_h = 4})

	love.graphics.setColor(color.white)
	if game_state == "pause" then
		love.graphics.setShader()
		draw_pause_menu()
	end

	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
	slogpixels:endDrawGameArea()
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
	-- love.graphics.draw(img.cursor, love.mouse.getX() - 2, love.mouse.getY() - 2)
end
