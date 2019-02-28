local Particle = class "Particle"

function Particle:init()
	self.id = idcounter.get_id("entity")
	self.name = "Particle"
	self.team = 0
	self.birth_frame = 0
	self.pos = {x = 0, y = 0, half_w = 1, half_h = 1,}
	self.vel = {dx = 0, dy = 0, dx_acc = 0, dy_acc = 0,}
	self.projectile = {accel = -0.3}

	self.drawable = {
		sprite = "bullet_23",
		layer = img.layer_enum.PARTICLE,
		color = color.white,
		flash_color = color.white, flash_end_frame = 0,
		fades_away = true
	}

	self.particle_is_active = false
end

function Particle:die(silent)
	self.particle_is_active = false
	tiny.removeEntity(world, self)
end

return Particle
