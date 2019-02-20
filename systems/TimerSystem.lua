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

return TimerSystem
