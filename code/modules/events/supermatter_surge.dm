/datum/round_event_control/supermatter_surge
	name = "Supermatter Surge"
	typepath = /datum/round_event/supermatter_surge
	weight = 15
	max_occurrences = 12
	earliest_start = 10 MINUTES
	category = EVENT_CATEGORY_ENGINEERING
	description = "Randomly modifies the supermatter's power, giving the engineers a lot of headaches."

/datum/round_event_control/supermatter_surge/canSpawnEvent()
	if(GLOB.main_supermatter_engine?.has_been_powered)
		return ..()

/datum/round_event/supermatter_surge
	var/power = 2000

/datum/round_event/supermatter_surge/setup()
	if(prob(70))
		power = rand(200,150000)
	else
		power = rand(200,300000)

/datum/round_event/supermatter_surge/announce()
	var/severity = ""
	var/important = FALSE
	switch(power)
		if(-INFINITY to 100000)
			var/low_threat_perc = 100-round(100*((power-200)/(100000-200)))
			if(prob(low_threat_perc))
				if(prob(low_threat_perc))
					severity = "низкая; Спустя время Суперматерия должна вернуться к нормальной работе."
				else
					severity = "средняя; Спустя время Суперматерия должна вернуться к нормальной работе, но в любом случае проверьте, не нужно ли временно отключить Излучатели."
			else
				severity = "высокая; Скорее всего, излучатели придется отключить, а если контур охлаждения Суперматерии не укреплен, то может потребоваться добавление предварительно охлажденного газа."
				important = TRUE
		if(100000 to INFINITY)
			severity = "экстремальная; Аварийные Действия для последующего тушения Суперматерии потребуются даже в том случае, если контур охлаждения в порядке. Отключите Излучатели и убедитесь, что контур охлаждает газы должным образом."
			important = TRUE
	if(power > 20000 || prob(round(power/200)))
		priority_announce("Обнаружен энергетический всплеск Суперматерии. Предполагаемая степень тяжести - [severity]", "ВНИМАНИЕ: АНОМАЛИЯ", has_important_message = important)

/datum/round_event/supermatter_surge/start()
	var/obj/machinery/power/supermatter_crystal/supermatter = GLOB.main_supermatter_engine
	var/power_proportion = supermatter.powerloss_inhibitor * 0.75 // what % of the power goes into matter power, at most 50%
	// we reduce the proportion that goes into actual matter power based on powerloss inhibitor
	// primarily so the supermatter doesn't tesla the instant these happen
	supermatter.matter_power += power * power_proportion
	var/datum/gas_mixture/methane_puff = new
	var/selected_gas = pick(4;GAS_CO2, 10;GAS_METHANE, 4;GAS_H2O, 1;GAS_BZ, 1;GAS_METHYL_BROMIDE)
	methane_puff.set_moles(selected_gas, 500)
	methane_puff.set_temperature(500)
	var/energy_ratio = (power * 500 * (1-power_proportion)) / methane_puff.thermal_energy()
	if(energy_ratio < 1) // energy output we want is lower than current energy, reduce the amount of gas we puff out
		methane_puff.set_moles(GAS_METHANE, energy_ratio * 500)
	else // energy output we want is higher than current energy, increase its actual heat
		methane_puff.set_temperature(energy_ratio * 500)
	supermatter.assume_air(methane_puff)
	qdel(methane_puff)
