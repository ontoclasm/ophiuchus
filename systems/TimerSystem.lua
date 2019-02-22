local TimerSystem = tiny.processingSystem(class "TimerSystem")

TimerSystem.filter = tiny.requireAll("timers")

function TimerSystem:process(e, dt)
	if #e.timers == 0 then
		e.timers = nil
		tiny.addEntity(world, e)
	else
		for k,timer in pairs(e.timers) do
			if game_frame >= timer.end_frame then
				timer.end_function(timer, e, dt)
				e.timers[k] = nil
			end
		end
	end
end

function TimerSystem:add_timer(e, dur, f)
	if not e.timers then
		e.timers = {}
		tiny.addEntity(world, e)
	end

	table.insert(e.timers, {
		start_frame = game_frame,
		end_frame = game_frame + dur,
		end_function = f
	})
end

function TimerSystem:add_death_timer(e, dur)
	TimerSystem:add_timer(e, dur, function(timer, e, dt)
		tiny.removeEntity(world, e)
	end)
end

return TimerSystem
