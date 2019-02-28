local SplashState = class("SplashState")

SplashState.name = "Splash Screen"

function SplashState:enter()
	self.time_acc = 0
end

function SplashState:update(dt)
	slogpixels:pixelMouse()
	slogpixels:calcOffset()

	self.time_acc = self.time_acc + dt

	while self.time_acc >= TIMESTEP do
		gui_frame = gui_frame + 1

		-- handle input
		controller:update()
		mouse_x = slogpixels.mousex
		mouse_y = slogpixels.mousey

		if controller:pressed('r1') then
			gamestate_manager.switch_to("Play")
		elseif controller:pressed('view') or controller:pressed('menu') then
			love.event.push("quit")
		end

		self.time_acc = self.time_acc - TIMESTEP
	end
end

function SplashState:draw()
	slogpixels:drawGameArea()

	love.graphics.clear(color.bg)

	local k = math.cos(gui_frame / 120) + 2
	love.graphics.setColor(0.3 * k, 0.08 * k, 0.05 * k, 1)
	love.graphics.circle("fill", window_w/2, window_h/2, 50)
	love.graphics.setColor(color.white)
	love.graphics.printf("Ophiuchus", math.floor(window_w/2 - 100), math.floor(window_h/2 - font:getHeight()/2), 200, "center")
	love.graphics.setColor(color.white)

	slogpixels:endDrawGameArea()
end

function SplashState:focus(f)
	if f then
		love.mouse.setVisible(false)
		love.mouse.setGrabbed(true)
	else
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
	end
end

function SplashState:exit()

end

return SplashState
