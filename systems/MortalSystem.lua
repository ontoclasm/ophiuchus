local MortalSystem = tiny.processingSystem(class "MortalSystem")

MortalSystem.filter = tiny.requireAll("hp")

function MortalSystem:process(e, dt)
	if e.hp <= 0 then
		e.dying = true
	end
	if e.dying and not (e.walker and e.walker.knocked) then
		if e.die then
			e:die(false)
		else
			tiny.removeEntity(world, e)
		end
	end
end

return MortalSystem
