local PlayState = class("PlayState")

PlayState.name = "Play Screen"

function PlayState:enter()
	self.game_frame = 0
	self.time_acc = 0
	self.hitstop_frames = 0

	self.mainmap = map:new(64, 64)
	self.mainmap:fill_main()
	_G.mainmap = self.mainmap

	-- img.blood_canvas = love.graphics.newCanvas((mainmap.width + 4) * TILE_SIZE, (mainmap.height + 4) * TILE_SIZE)
	-- img.blood_canvas:setFilter("linear", "nearest")

	self.player = tiny.addEntity(world, Player:new(50, 300))

	local found, start_x, start_y = false, nil, nil
	for i = 1, 40 do
		found = false
		while not found do
			start_x = love.math.random(mainmap.width * TILE_SIZE / 2, mainmap.width * TILE_SIZE)
			start_y = love.math.random(1, mainmap.height * TILE_SIZE / 2)
			found = not collision.map_collision_aabb({x = start_x, y = start_y, half_w = 3, half_h = 3})
		end
		tiny.addEntity(world, Enemy:new(start_x, start_y))
	end
end

function PlayState:update(dt)
	slogpixels:pixelMouse()
	slogpixels:calcOffset()

	self.time_acc = self.time_acc + dt

	while self.time_acc >= TIMESTEP do
		gui_frame = gui_frame + 1

		-- handle input
		controller:update()
		mouse_x = slogpixels.mousex
		mouse_y = slogpixels.mousey

		if not self.paused then
			if controller:pressed('menu') then
				self:pause()
				return
			end

			if self.hitstop_frames > 0 then
				self.hitstop_frames = self.hitstop_frames - 1
			else
				self.game_frame = self.game_frame + 1

				tiny.update(world, TIMESTEP)

				-- -- update all systems
				-- for k,v in pairs(c_timeouts) do
				-- 	if gamestate.game_frame >= v then
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
		else
			if controller:pressed('menu') then self:unpause() end
			if controller:pressed('view') then gamestate_manager.switch_to("Splash") end
		end
		self.time_acc = self.time_acc - TIMESTEP
	end
end

function PlayState:draw()
	slogpixels:drawGameArea()
	if self.paused then
		love.graphics.setShader(shader_desaturate)
	end

	-- love.graphics.setCanvas(game_canvas)
	love.graphics.clear(color.bg)

	img.render()

	-- gui

	-- if game_state == "play" then
	-- 	love.graphics.draw(img.cursor, mouse_x - 2, mouse_y - 2)
	-- end

	love.graphics.setColor(self.player.drawable.color)
	love.graphics.print("HP: "..self.player.hp, 2, 2)
	love.graphics.setColor(color.white)
	-- debug msg
	love.graphics.print("Time: "..string.format("%.0f", self.game_frame / 60), 2, window_h - 96)
	love.graphics.setColor(color.yellow)
	love.graphics.print("FPS: "..love.timer.getFPS(), 2, window_h - 80)
	love.graphics.setColor(color.ltblue)
	love.graphics.print("Pos: "..self.player.pos.x..", "..self.player.pos.y, 2, window_h - 64)
	love.graphics.print("Vel: "..string.format("%+.2f", self.player.vel.dx)..", "..string.format("%+.2f", self.player.vel.dy), 2, window_h - 48)
	love.graphics.setColor(color.green)
	local dc = love.graphics.getStats()
	love.graphics.print("Draws: "..dc.drawcalls, 2, window_h - 32)
	-- love.graphics.print(map.grid_at_pos(mouse_x + camera.x)..", "..map.grid_at_pos(mouse_y + camera.y), 2, window_h - 16)
	-- love.graphics.setColor(color.black)
	-- love.graphics.print("Jackdaws Love My Big Sphinx of Quartz * 1234567890", 3, window_h - 15)
	-- love.graphics.setColor(color.orange)
	-- love.graphics.print("Jackdaws Love My Big Sphinx of Quartz * 1234567890", 2, window_h - 16)
	love.graphics.print("Entities: "..tiny.getEntityCount(world), 2, window_h - 16)

	-- collision.debug_map_collision_sweep(c_positions[player_id])
	-- collision.debug_map_collision({x = mouse_x + camera.x, y = mouse_y + camera.y, half_w = 4, half_h = 4})

	love.graphics.setColor(color.white)
	love.graphics.setShader()
	if self.paused then
		-- draw pause menu
		love.graphics.setColor(color.rouge)
		love.graphics.circle("fill", window_w/2, window_h/2, 50)
		love.graphics.setColor(color.white)
		love.graphics.printf("Press Q to quit", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center")
		love.graphics.setColor(color.white)
		-- love.graphics.draw(img.cursor, love.mouse.getX() - 2, love.mouse.getY() - 2)
	end

	-- love.graphics.setCanvas()
	-- love.graphics.draw(game_canvas)
	slogpixels:endDrawGameArea()
end

function PlayState:focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		if not self.paused then
			self:pause()
		end
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

function PlayState:exit()
	tiny.clearEntities(world)
end

-- -- -- --

function PlayState:pause()
	self.paused = true
	self.pause_mouse_x, self.pause_mouse_y = love.mouse.getPosition()
	slogpixels:setCursor(2)
end

function PlayState:unpause()
	self.paused = false
	love.mouse.setPosition(self.pause_mouse_x, self.pause_mouse_y)
	slogpixels:setCursor(1)
end

return PlayState
