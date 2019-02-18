local DrawingSystem = tiny.system(class "DrawingSystem")

DrawingSystem.filter = tiny.requireAll("pos", "drawable")
DrawingSystem.active = false

-- stub system for keeping track of what to draw

function DrawingSystem:draw()
	-- draw all drawables
	for _, e in pairs(self.entities) do
		if e.drawable.flash_end_frame > game_frame then
			love.graphics.setColor(color.mix(e.drawable.color, e.drawable.flash_color, (e.drawable.flash_end_frame - game_frame)/30))
		else
			-- -- debug
			-- if k == player_id and c_movements[k].grounded then
			-- 	love.graphics.setColor(color.orange)
			-- else
				love.graphics.setColor(e.drawable.color)
			-- end
		end
		love.graphics.draw(img.tileset, img.tile[v.sprite][1],
						   camera.view_x(e.pos) - (img.tile_size / 2), camera.view_y(e.pos) - (img.tile_size / 2))
	end
end

return DrawingSystem
