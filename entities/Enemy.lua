local Enemy = class "Enemy"

function Enemy:init(x, y)
	self.id = idcounter.get_id("entity")
	self.name = "Mook"
	self.team = 2
	self.birth_frame = gamestate.game_frame

	self.pos = {x = x, y = y, half_w = 3, half_h = 3,}
	self.vel = {dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,}
	self.walker = {
		top_speed = 1, accel = 0.1,
		knockable = true
	}

	self.ai = {
		brain = "mook",
		state = "thinking",
		wake_frame = 0,
		hunting_target = gamestate.player,
	}
	self.controls = {
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

		attack_profile = {damage = 5, push = 5, knock = true},
		defence_profile = true,
	}

	self.activates_zones = true

	self.hp = 30

	self.drawable = {
		layer = img.layer_enum.ACTOR,
		sprite = "player",
		color = {0.15 + love.math.random() * 0.10,	0.20 + love.math.random() * 0.15,	0.80 + love.math.random() * 0.20},
		flash_color = color.white, flash_end_frame = 0,
	}
end

function Enemy:get_knocked()
	self.walker.knocked = true
	self.collides.map_reaction = "bounce 1.0"
	self.collides.collides_with_friends = true
end

function Enemy:end_knock()
	self.walker.knocked = false
	self.collides.map_reaction = "slide"
	self.collides.collides_with_friends = false
	self:get_stunned()
end

function Enemy:get_stunned()
	if self.ai then
		self.ai.state = "hunting"
		self.ai.wake_frame = gamestate.game_frame + 20
	end
	if self.controls then
		self.controls.move_x = 0
		self.controls.move_y = 0
	end
end

function Enemy:die(silent)
	if self.pos and self.drawable then
		particles.spray(self.pos.x, self.pos.y, 20, self.drawable.color, 0, PI, 0.5, 5, 5, 25)
	end

	tiny.removeEntity(world, self)
end

return Enemy
