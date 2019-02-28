local TimerSystem = tiny.processingSystem(class "TimerSystem")

TimerSystem.filter = tiny.requireAll("timers")

function TimerSystem:process(e, dt)
	if next(e.timers) == nil then
		e.timers = nil
		tiny.addEntity(world, e)
	else
		for k,timer in pairs(e.timers) do
			if gamestate.game_frame >= timer.end_frame then
				timer.end_function(timer, e, dt)
				e.timers[k] = nil
			end
		end
	end
end

function TimerSystem:add_timer(e, dur, f, key)
	if not e.timers then
		e.timers = {}
		tiny.addEntity(world, e)
	end

	if key then
		if e.timers[key] then
			error()
		else
			e.timers[key] = {
				start_frame = gamestate.game_frame,
				end_frame = gamestate.game_frame + dur,
				end_function = f
			}
		end
	else
		table.insert(e.timers, {
			start_frame = gamestate.game_frame,
			end_frame = gamestate.game_frame + dur,
			end_function = f
		})
	end
end

function TimerSystem:add_lifetime(e, dur)
	TimerSystem:add_timer(e, dur, function(timer, e, dt)
		if e.die then
			e:die(true)
		else
			tiny.removeEntity(world, e)
		end
	end, "lifetime")
end

local timer
function TimerSystem:get_t(e, timer_key)
	timer = e.timers and e.timers[timer_key] or nil
	if timer then
		return (gamestate.game_frame - timer.start_frame) / (timer.end_frame - timer.start_frame)
	else
		error("bad timer id "..timer_key.." for "..e.name)
	end
end

return TimerSystem
