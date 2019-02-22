local Zone = class "Zone"

function Zone:init(x, y, hw, hh)
	self.id = idcounter.get_id("entity")
	self.name = "Zone"
	self.team = 0
	self.birth_frame = game_frame

	self.pos = {x = x, y = y, half_w = hw, half_h = hh}

	self.drawable = {
		layer = img.layer_enum.FLOOR,
		sprite = "player", color = color.dkgrey,
		flash_color = color.white, flash_end_frame = 0,
		label = function()
			return self.value
		end
	}

	self.value = 0
end

return Zone
