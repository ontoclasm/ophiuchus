require "requires"

PIXEL_SCALE = 2 -- set to nil to use the largest integer scale that fits on screen
TIMESTEP = 1/60
TILE_SIZE = 8

function love.load()
	gui_frame = 0

	window_w, window_h = 480, 320
	love.graphics.setBackgroundColor(color.rouge)
	slogpixels:load(PIXEL_SCALE)

	controller = input.setup_controller()
	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
	mouse_x, mouse_y = 0, 0
	slogpixels:setCursor(1)

	love.graphics.setFont(font)
	love.graphics.setLineWidth(1)

	img.setup()
	particles.init()

	world = tiny.world(
		PlayerControlSystem,
		AIControlSystem,
		WeaponSystem,
		PhysicsSystem,
		ZoneSystem,
		TimerSystem,
		MortalSystem,
		img.DrawingSystem
	)

	gamestate = gamestate_manager.states.Splash:new()
	gamestate:enter()
end

function love.update(dt)
	gamestate:update(dt)
end

function love.draw()
	gamestate:draw()
end

function love.focus(f)
	gamestate:focus(f)
end
