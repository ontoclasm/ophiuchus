local AIControlSystem = tiny.processingSystem(class "AIControlSystem")

AIControlSystem.filter = tiny.requireAll("ai", "controls", "pos")

function AIControlSystem:process(e, dt)
	if self[e.ai.brain] then
		self[e.ai.brain](self[e.ai.brain], e, dt)
	else
		error("ABNORMAL BRAIN: " .. e.ai.brain)
	end
end

-- brain types

function AIControlSystem:mook(e, dt)
	if e.ai.wake_frame <= gamestate.game_frame then
		if e.ai.state == "thinking" or mymath.one_chance_in(10) then
			-- rethink
			if mymath.one_chance_in(2) then
				e.ai.state = "wandering"
			else
				e.ai.state = "hunting"
			end
		end

		if e.ai.state == "wandering" then
			e.controls.move_x = love.math.random(3) - 2
			e.controls.move_y = love.math.random(3) - 2

			e.ai.wake_frame = gamestate.game_frame + 60
		elseif e.ai.state == "hunting" then
			local target_pos = e.ai.hunting_target.pos
			if not target_pos then
				-- target gone, i guess
				e.ai.state = "thinking"
			else
				local dx, dy = mymath.normalize(target_pos.x - e.pos.x, target_pos.y - e.pos.y)
				e.controls.move_x = mymath.abs_floor(dx * 1.99)
				e.controls.move_y = mymath.abs_floor(dy * 1.99)
			end

			e.ai.wake_frame = gamestate.game_frame + 20
		end

	end
end

return AIControlSystem
