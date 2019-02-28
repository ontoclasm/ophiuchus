local Zone = class "Zone"

function Zone:init(x, y, hw, hh)
	self.id = idcounter.get_id("entity")
	self.name = "Zone"
	self.team = 0
	self.birth_frame = gamestate.game_frame

	self.pos = {x = x, y = y, half_w = hw, half_h = hh}

	self.drawable = {
		layer = img.layer_enum.FLOOR,
		sprite = "player", color = color.dkgrey,
		flash_color = color.white, flash_end_frame = 0,
		label = function()
			return self.capture_zone.owner_team..", "..(self.capture_zone.capturing_team or "-")..", "..self.capture_zone.capture_progress
		end
	}

	self.capture_zone = {owner_team = 0, capturing_team = 0, capture_progress = 10, capture_goal = 10}
end

return Zone
