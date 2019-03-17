local gamestate_manager = {states = {
	Splash = require "gamestates/SplashState",
	Play = require "gamestates/PlayState",
	GameOver = require "gamestates/GameOverState",
}}

function gamestate_manager.switch_to(new_state)
	gamestate:exit()
	gamestate = gamestate_manager.states[new_state]:new()
	gamestate:enter()
end

return gamestate_manager
