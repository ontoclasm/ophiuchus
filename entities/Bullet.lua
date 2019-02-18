local Bullet = class "Bullet"

function Bullet:init(x, y, dx, dy, team)
	self.id = idcounter.get_id("entity")
	self.name = "Bullet"
	self.team = team
	self.birth_frame = game_frame
	self.pos = {x = x, y = y, half_w = 3, half_h = 3,}
	self.vel = {dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,}

	self.collides = {
		entity_filter = function(other_e)
			return other_e.team ~= self.team
		end,
		collide_with_map = function(hit)
			if hit.object.kind == "void" then
				self:die()
				return "end"
			else
				return "bounce"
			end
		end,
		collide_with_entity = function(hit, already_applied)
			self:die()
			return "end"
		end,
		get_collided_with = function(e, hit)
			self:die()
		end,
	}

	self.drawable = {
		sprite = "bullet_23",
		color = color.rouge,
		flash_color = color.white, flash_end_frame = 0,
	}
end

function Bullet:get_hit()

end

function Bullet:die(silent)
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

return Bullet
