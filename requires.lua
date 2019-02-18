baton = require "lib/baton"
slogpixels = require "lib/slogpixels"
tiny = require "lib/tiny"
class = require "lib/30log"

camera = require "camera"
collision = require "collision"
color = require "color"
ecs = require "ecs"
idcounter = require "idcounter"
img = require "img"
input = require "input"
map = require "map"
mymath = require "mymath"

block_data = require "block_data"

Bullet = require "entities/Bullet"
Enemy = require "entities/Enemy"

-- constants
PI = math.pi
ROOT_2 = math.sqrt(2)
ROOT_2_OVER_2 = math.sqrt(2) / 2
