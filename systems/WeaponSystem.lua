local WeaponSystem = tiny.processingSystem(class "WeaponSystem")

WeaponSystem.filter = tiny.requireAll("pos", "controls", "weapon")

local model
function WeaponSystem:process(e, dt)
	model = WeaponSystem.models[e.weapon.model]

	if not model then
		error("missing weapon model "..e.weapon.model)
	end

	if model.fire_pressed and e.controls.fire_pressed then
		model.fire_pressed(e, dt)
	end
	if model.fire_down and e.controls.fire_down then
		model.fire_down(e, dt)
	end
	if model.altfire_pressed and e.controls.altfire_pressed then
		model.altfire_pressed(e, dt)
	end
	if model.altfire_down and e.controls.altfire_down then
		model.altfire_down(e, dt)
	end
end

--

WeaponSystem.models = {}

WeaponSystem.models["assault"] = {
	-- fire_pressed = function(start_x, start_y, aim_x, aim_y)

	-- end,

	fire_down = function(e, dt)
		if e.weapon.ready_frame < game_frame then
			local angle = mymath.weighted_spread(math.atan2(e.controls.aim_y - e.pos.y, e.controls.aim_x - e.pos.x), 0.1)
			tiny.addEntity(world, Bullet:new(
				e.pos.x, e.pos.y,
				(e.vel and e.vel.dx or 0) + math.cos(angle) * 10, (e.vel and e.vel.dy or 0) + math.sin(angle) * 10,
				e.team))
			e.weapon.ready_frame = game_frame + 8
		end
	end,

	altfire_pressed = function(e, dt)
		if e.weapon.ready_frame < game_frame then
			local angle = mymath.weighted_spread(math.atan2(e.controls.aim_y - e.pos.y, e.controls.aim_x - e.pos.x), 0.1)
			tiny.addEntity(world, Slash:new(
				e.pos.x, e.pos.y,
				(e.vel and e.vel.dx or 0) + math.cos(angle) * 20, (e.vel and e.vel.dy or 0) + math.sin(angle) * 20,
				e.team))
			e.weapon.ready_frame = game_frame + 30
		end
	end,

	-- altfire_down = function(start_x, start_y, aim_x, aim_y)

	-- end,
}

return WeaponSystem
