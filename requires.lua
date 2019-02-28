baton = require "lib/baton"
slogpixels = require "lib/slogpixels"
tiny = require "lib/tiny"
class = require "lib/30log"

camera = require "camera"
collision = require "collision"
color = require "color"
gamestate_manager = require "gamestate_manager"
idcounter = require "idcounter"
img = require "img"
input = require "input"
map = require "map"
mymath = require "mymath"
particles = require "particles"

block_data = require "block_data"

shader_desaturate = love.graphics.newShader("desaturate.lua")

font = love.graphics.newImageFont("art/font_small.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")
font_mono = love.graphics.newImageFont("art/font_mono.png",
		" abcdefghijklmnopqrstuvwxyz" ..
		"ABCDEFGHIJKLMNOPQRSTUVWXYZ0" ..
		"123456789.,!?-+/():;%&`'*#=[]\"|_")

Bullet = require "entities/Bullet"
Enemy = require "entities/Enemy"
Player = require "entities/Player"
Particle = require "entities/Particle"
Slash = require "entities/Slash"
Zone = require "entities/Zone"

PlayerControlSystem = require ("systems/PlayerControlSystem")()
AIControlSystem = require ("systems/AIControlSystem")()
WeaponSystem = require ("systems/WeaponSystem")()
PhysicsSystem = require ("systems/PhysicsSystem")()
ZoneSystem = require ("systems/ZoneSystem")()
TimerSystem = require ("systems/TimerSystem")()
MortalSystem = require ("systems/MortalSystem")()

-- SplashState = require ("gamestates/SplashState")()
-- PlayState = require ("gamestates/PlayState")()

-- constants
PI = math.pi
ROOT_2 = math.sqrt(2)
ROOT_2_OVER_2 = math.sqrt(2) / 2
