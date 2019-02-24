local Slash = class "Slash"

function Slash:init(x, y, dx, dy, team)
	self.id = idcounter.get_id("entity")
	self.name = "Slash"
	self.team = team
	self.birth_frame = game_frame
	self.pos = {x = x, y = y, half_w = 8, half_h = 8,}
	self.vel = {dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,}

	self.collides = {
		collides_with_entities = true,

		attack_profile = {damage = 30, push = 9, knock = true, velocity_push = true},
	}

	TimerSystem:add_lifetime(self, 1)
end

function Slash:get_hit()

end

function Slash:die(silent)
	-- if self.pos and self.drawable then
	-- 	local pcolor = self.drawable and self.drawable.color or color.white
	-- 	for n = 1, 3 do
	-- 		angle = love.math.random() * 2 * PI
	-- 		speed = 0.5 + love.math.random() * 5
	-- 		ecs.spawn_particle(kind, pcolor, pos.x, pos.y, speed * math.cos(angle), speed * math.sin(angle), 10 + love.math.random(10))
	-- 	end
	-- end

	tiny.removeEntity(world, self)
end

return Slash
