local Enemy = class "Enemy"

function Enemy:init(x, y)
	self.id = idcounter.get_id("entity")
	self.name = "Mook"
	self.team = 2
	self.birth_frame = game_frame

	self.pos = {x = x, y = y, half_w = 3, half_h = 3,}
	self.vel = {dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,}
	self.walker = {
		top_speed = 1, accel = 0.1,
	}
	-- used when knocked back
	-- self.projectile = {
	-- 	collides_with_map = true, collides_with_hitboxes = true,
	-- 	collision_responses =
	-- 	{
	-- 		wall = "bounce",
	-- 		void = "bounce",
	-- 		enemy = "slow"
	-- 	},
	-- 	attack =
	-- 	{
	-- 		damage = 0,
	-- 		kb_factor = 0.7,
	-- 	},
	-- }

	self.ai = {
		brain = "mook",
		state = "thinking",
		wake_frame = 0,
		hunting_target = player,
	}
	self.controls = {
		target = player,
		move_x = 0, move_y = 0,
		aim_x = 0, aim_y = 0,
		fire_pressed = false, fire_down = false,
		altfire_pressed = false, altfire_down = false,
	}

	self.collides = {
		collides_with_map = true,
		map_reaction = "slide",

		collides_with_entities = true,
		solid_entity_reaction = "end",
		is_solid = true,

		attack_profile = true,
		defence_profile = true,
	}

	self.drawable = {
		sprite = "player",
		color = color.blue,
		flash_color = color.white, flash_end_frame = 0,
	}

	self.hp = 30
end

function Enemy:get_hit()

end

function Enemy:get_stunned()
	if self.ai then
		self.ai.state = "hunting"
		self.ai.wake_frame = game_frame + 20
	end
	if self.controls then
		self.controls.move_x = 0
		self.controls.move_y = 0
	end
end

function Enemy:die(silent)
	-- if self.pos and self.drawable then
	-- 	local pcolor = self.drawable and self.drawable.color or color.white
	-- 	for n = 1, 20 do
	-- 		angle = love.math.random() * 2 * PI
	-- 		speed = 0.5 + love.math.random() * 5
	-- 		ecs.spawn_particle(kind, pcolor, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
	-- 	end
	-- end

	tiny.removeEntity(world, self)
	hitstop_frames = 5
end

return Enemy
