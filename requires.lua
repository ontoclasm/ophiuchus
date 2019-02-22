baton = require "lib/baton"
slogpixels = require "lib/slogpixels"
tiny = require "lib/tiny"
class = require "lib/30log"

camera = require "camera"
collision = require "collision"
color = require "color"
idcounter = require "idcounter"
img = require "img"
input = require "input"
map = require "map"
mymath = require "mymath"

block_data = require "block_data"

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

-- constants
PI = math.pi
ROOT_2 = math.sqrt(2)
ROOT_2_OVER_2 = math.sqrt(2) / 2
