local Particle = class "Particle"

function Particle:init(x, y, dx, dy, color, dur)
	self.id = idcounter.get_id("entity")
	self.name = "Particle"
	self.team = 0
	self.birth_frame = game_frame
	self.pos = {x = x, y = y, half_w = 1, half_h = 1,}
	self.vel = {dx = dx, dy = dy, dx_acc = 0, dy_acc = 0,}
	self.projectile = {accel = -0.3}

	self.drawable = {
		sprite = "bullet_23",
		layer = img.layer_enum.PARTICLE,
		color = color,
		flash_color = color.white, flash_end_frame = 0,
		fades_away = true
	}

	TimerSystem:add_lifetime(self, dur)
end

return Particle
