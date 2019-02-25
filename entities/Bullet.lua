local Bullet = class "Bullet"

function Bullet:init(x, y, dx, dy, team)
	self.id = idcounter.get_id("entity")
	self.name = "Bullet"
	self.team = team
	self.birth_frame = game_frame
	self.pos = {x = x, y = y, half_w = 1, half_h = 1,}
	self.vel = {dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,}

	TimerSystem:add_lifetime(self, 30)
end

Bullet.collides = {
	collides_with_map = true,
	map_reaction = "bounce 0.8",

	collides_with_entities = true,
	solid_entity_reaction = "die",

	attack_profile = {damage = 15, push = 2, knock = false, velocity_push = true},
}

Bullet.drawable = {
	sprite = "bullet_0",
	layer = img.layer_enum.PROJECTILE,
	color = color.rouge,
	flash_color = color.white, flash_end_frame = 0,
}

function Bullet:die(silent)
	if self.pos and self.drawable then
		particles.spray(self.pos.x, self.pos.y, 3, self.drawable.color, 0, PI, 0.5, 5, 5, 25)
	end

	tiny.removeEntity(world, self)
end

return Bullet
