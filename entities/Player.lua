local Player = class "Player"

function Player:init(x, y)
	self.id = idcounter.get_id("entity")
	self.name = "Player"
	self.team = 1
	self.birth_frame = game_frame

	self.pos = {x = x, y = y, half_w = 3, half_h = 3}
	self.vel = {dx = 0, dy = 0, dx_acc = 0, dy_acc = 0}
	self.walker = {
		top_speed = 1.5, accel = 0.15,
		knockable = true
	}

	self.player_controlled = true
	self.controls = {
		x = 0, y = 0,
		aim_x = 0, aim_y = 0,
		fire_pressed = false, fire_down = false,
		altfire_pressed = false, altfire_down = false,
		wake_frame = 0,
	}

	self.collides = {
		collides_with_map = true,
		map_reaction = "slide",

		collides_with_entities = true,
		solid_entity_reaction = "end",
		is_solid = true,

		attack_profile = {damage = 5, push = 1, knock = false},
		defence_profile = true,
	}

	self.activates_zones = true

	self.hp = 30

	self.drawable = {
		layer = img.layer_enum.PLAYER,
		sprite = "player", color = color.rouge,
		flash_color = color.white, flash_end_frame = 0,
	}

	self.weapon = {model = "assault", ready_frame = 0}
end

function Player:get_knocked()
	self.walker.knocked = true
	if self.collides then
		self.collides.map_reaction = "bounce 0.8"
		self.collides.collides_with_entities = false
	end
	if self.drawable then
		self.drawable.color = color.yellow
	end
	hitstop_frames = 5
end

function Player:end_knock()
	self.walker.knocked = false
	self.collides.map_reaction = "slide"
	TimerSystem:add_timer(self, 60, function(timer, e, dt)
		if e.collides then
			e.collides.collides_with_entities = true
		end
		if e.drawable then
			e.drawable.color = color.rouge
		end
	end)
end

function Player:die(silent)
	-- if self.pos and self.drawable then
	-- 	local pcolor = self.drawable and self.drawable.color or color.white
	-- 	for n = 1, 20 do
	-- 		angle = love.math.random() * 2 * PI
	-- 		speed = 0.5 + love.math.random() * 5
	-- 		ecs.spawn_particle(kind, pcolor, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
	-- 	end
	-- end

	-- rip 2019
	error("you died"..(silent and " silently..." or " !"))
end

return Player
