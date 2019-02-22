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

	attack_profile = {damage = 15, push = 2, knock = false},
}

Bullet.drawable = {
	sprite = "bullet_0",
	layer = img.layer_enum.PROJECTILE,
	color = color.rouge,
	flash_color = color.white, flash_end_frame = 0,
}

function Bullet:die(silent)
	if self.pos and self.drawable then
		local pcolor = self.drawable and self.drawable.color or color.white
		for n = 1, 3 do
			angle = love.math.random() * 2 * PI
			speed = 0.5 + love.math.random() * 5
			tiny.addEntity(world, Particle:new(self.pos.x, self.pos.y, speed * math.cos(angle), speed * math.sin(angle), pcolor, 10 + love.math.random(10)))
		end
	end

	tiny.removeEntity(world, self)
end

return Bullet
