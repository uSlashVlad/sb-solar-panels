require '/scripts/fupower.lua'

function init()
	self.powerLevel = config.getParameter("powerLevel",1)
	power.init()
end

function update(dt)
	storage.checkticks = (storage.checkticks or 0) + dt
	if storage.checkticks >= 10 then
		storage.checkticks = storage.checkticks - 10
		if isn_powerGenerationBlocked() then
			animator.setAnimationState("meter", "0")
			power.setPower(0)
		else
			local location = isn_getTruePosition()
			local light = (world.type() ~= 'playerstation' and getLight(location) or 0.0)
			local genmult = 1

			if world.type() == 'playerstation' then
				genmult = 3.75 -- player space station always counts as high power, but never MAX power.
			elseif world.getProperty("ship.level") == 0 then
				genmult = 4 -- maximum generation on ship
			elseif light >= 0.85 then
				genmult = 4 * (1 + light)
			elseif light >= 0.75 then
				genmult = 4
			elseif light >= 0.65 then
				genmult = 3
			elseif light >= 0.55 then
				genmult = 2
			elseif light <= 0 then
				genmult = 0
			end
			if world.liquidAt(location)then genmult = genmult * 0.05 end -- water significantly reduces the output

			local generated = self.powerLevel * genmult
			
			if genmult >= 4 then
			animator.setAnimationState("meter", "4")
			elseif genmult >= 3 then
				animator.setAnimationState("meter", "3")
			elseif genmult >= 2 then
				animator.setAnimationState("meter", "2")
			elseif genmult > 0 then
				animator.setAnimationState("meter", "1")
			else
				animator.setAnimationState("meter", "0")
			end

			power.setPower(generated)
		end
	end
	power.update(dt)
end

function getLight(location)
	local objects = world.objectQuery(entity.position(), 20)
	local lights = {}
	for i=1,#objects do
		local light = world.callScriptedEntity(objects[i],'object.getLightColor')
		if light and (light[1] > 0 or light[2] > 0 or light[3] > 0) then
			lights[objects[i]] = light
			world.callScriptedEntity(objects[i],'object.setLightColor',{light[1]/3,light[2]/3,light[3]/3})
		end
	end
	local light = math.min(world.lightLevel(location),1.0) --via 'compressing' liquids like lava it is possible to get exhorbitant values on light level, over 100x the expected range.
	for key,value in pairs(lights) do
		world.callScriptedEntity(key,'object.setLightColor',value)
	end
	return light
end

function isn_powerGenerationBlocked()
	local location = isn_getTruePosition()
	local result = world.underground(location) or world.lightLevel(location) < 0.2 or (world.timeOfDay() > 0.55 and world.type() ~= 'playerstation')
	result = result and world.getProperty("ship.level") ~= 0
	return result --or world.type == 'unknown'
end

function isn_getTruePosition()
	storage.truepos = storage.truepos or {entity.position()[1] + math.random(2,3), entity.position()[2] + 1}
	return storage.truepos
end