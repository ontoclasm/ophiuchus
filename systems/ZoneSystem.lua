local ZoneSystem = tiny.processingSystem(class "ZoneSystem")

ZoneSystem.filter = tiny.requireAll("pos", "activates_zones")
ZoneSystem.interval = 0.25

ZoneSystem.zone_list = {}

function ZoneSystem:process(e, dt)
	for k, zone in pairs(self.zone_list) do
		if collision.collision_aabb_aabb(e.pos, zone.pos) then
			zone.value = zone.value + 1
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

return ZoneSystem
