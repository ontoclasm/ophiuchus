local ZoneSystem = tiny.system(class "ZoneSystem")

ZoneSystem.filter = tiny.requireAll("pos", "activates_zones")
ZoneSystem.interval = 0.25

ZoneSystem.zone_list = {}

local occupying_team
function ZoneSystem:update(dt)
	for _, zone in pairs(self.zone_list) do
		occupying_team = nil
		for _, e in pairs(self.entities) do
			if collision.collision_aabb_aabb(e.pos, zone.pos) then
				if not occupying_team then
					occupying_team = e.team
				elseif occupying_team ~= e.team then
					-- contested; do nothing
					occupying_team = -99
					break
				end
			end
		end

		if not occupying_team or occupying_team == zone.capture_zone.owner_team then
			if zone.capture_zone.capturing_team and zone.capture_zone.capturing_team ~= zone.capture_zone.owner_team then
				if zone.capture_zone.capture_progress > 0 then
					zone.capture_zone.capture_progress = zone.capture_zone.capture_progress - 1
				end
				if zone.capture_zone.capture_progress <= 0 then
					zone.capture_zone.capturing_team = zone.capture_zone.owner_team
				end
			elseif zone.capture_zone.capture_progress < zone.capture_zone.capture_goal then
				zone.capture_zone.capture_progress = zone.capture_zone.capture_progress + 1
			end
		elseif occupying_team ~= -99 then
			if zone.capture_zone.capturing_team and occupying_team ~= zone.capture_zone.capturing_team then
				if zone.capture_zone.capture_progress > 0 then
					zone.capture_zone.capture_progress = zone.capture_zone.capture_progress - 1
				end
				if zone.capture_zone.capture_progress == 0 then
					zone.capture_zone.capturing_team = occupying_team
				end
			else
				zone.capture_zone.capturing_team = occupying_team
				zone.capture_zone.capture_progress = zone.capture_zone.capture_progress + 1
				if zone.capture_zone.capture_progress >= zone.capture_zone.capture_goal then
					-- successful capture!
					-- zone.capture_zone.capture_progress = 0
					-- zone.capture_zone.capturing_team = nil
					zone.capture_zone.owner_team = occupying_team
					if zone.drawable then
						zone.drawable.color = color.team_colors[occupying_team] or color.orange
					end
				end
			end
		end
	end
end

function ZoneSystem:add_zone(x, y, hw, hh)
	local zone = Zone:new(x, y, hw, hh)
	tiny.addEntity(world, zone)
	table.insert(self.zone_list, zone.id, zone)
end

function ZoneSystem:remove_zone(zone)
	self.zone_list[zone.id] = nil
end

function ZoneSystem:onRemoveFromWorld()
	error("fuck")
end

return ZoneSystem
