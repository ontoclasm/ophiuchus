local particles = {pool = {}, next_id = 1}

local MAX_PARTICLES = 1000

function particles.init()
	for i = 1, MAX_PARTICLES do
		particles.pool[i] = Particle:new()
	end
end

local tries, p
function particles.activate_particle(x, y, dx, dy, color, dur)
	tries = 0
	while particles.pool[particles.next_id].particle_is_active and tries < MAX_PARTICLES do
		tries = tries + 1
		particles.next_id = particles.next_id + 1
		if particles.next_id > MAX_PARTICLES then
			particles.next_id = 1
		end
	end
	if tries == MAX_PARTICLES then
		error("pool is empty!")
	end
	p = particles.pool[particles.next_id]
	p.pos.x = x
	p.pos.y = y
	p.vel.dx = dx
	p.vel.dy = dy
	p.drawable.color = color
	TimerSystem:add_lifetime(p, dur)
	p.particle_is_active = true
	tiny.addEntity(world, p)
end

local random_spread = mymath.random_spread
local angle, speed
function particles.spray(x, y, num, color, angle, angle_spread, min_speed, speed_spread, min_dur, dur_spread)
	for n = 1, num do
		angle = random_spread(angle, angle_spread)
		speed = min_speed + love.math.random() * speed_spread
		particles.activate_particle(x, y, speed * math.cos(angle), speed * math.sin(angle), color, min_dur + love.math.random(dur_spread))
	end
end

return particles
