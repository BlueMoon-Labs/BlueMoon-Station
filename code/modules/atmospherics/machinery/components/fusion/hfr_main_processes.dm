// Stub: no hallucination pulse in BlueMoon
/proc/visible_hallucination_pulse(atom/source, range, duration)
	return

/obj/machinery/atmospherics/components/unary/hypertorus/core/process_atmos(seconds_per_tick)
	/*
	 *Pre-checks
	 */
	if(!active)
		return

	if(!check_part_connectivity())
		deactivate()
		return

	CHECK_TICK

	if (start_power || power_level)
		play_ambience(seconds_per_tick)
		fusion_process(seconds_per_tick)
		CHECK_TICK
		process_moderator_overflow(seconds_per_tick)
		CHECK_TICK
		process_damageheal(seconds_per_tick)
		CHECK_TICK
		check_alert()
	if (start_power)
		remove_waste(seconds_per_tick)
		CHECK_TICK
	update_pipenets()

	check_deconstructable()

	if(linked_interface)
		SStgui.update_uis(linked_interface)

/// Считает мощность, нестабильность, тепло и газы за тик. Без питания выставляет фолбек-значения и копит железо.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/fusion_process(seconds_per_tick)
	CHECK_TICK
	if (check_power_use())
		if (start_cooling)
			inject_from_side_components(seconds_per_tick)
			process_internal_cooling(seconds_per_tick)
	else
		magnetic_constrictor = HFR_FALLBACK_MAGNETIC_CONSTRICTOR
		heating_conductor = HFR_FALLBACK_HEATING_CONDUCTOR
		current_damper = HFR_FALLBACK_CURRENT_DAMPER
		fuel_injection_rate = HFR_FALLBACK_FUEL_INJECTION_RATE
		moderator_injection_rate = HFR_FALLBACK_MODERATOR_INJECTION_RATE
		waste_remove = FALSE
		iron_content += HFR_FALLBACK_IRON_RATE * seconds_per_tick

	update_temperature_status(seconds_per_tick)

	// Объём учёта: от объёма смеси и магнитного сужения (проценты). Дальше от него scale_factor и торoidal_size.
	var/archived_heat = internal_fusion.return_temperature()
	var/volume = internal_fusion.return_volume() * (magnetic_constrictor * HFR_MAGNETIC_VOLUME_FRAC)

	var/energy_concentration_multiplier = 1
	var/positive_temperature_multiplier = 1
	var/negative_temperature_multiplier = 1

	var/scale_factor = volume * HFR_VOLUME_SCALE

	hfr_fuel_list.Cut()
	hfr_scaled_fuel_list.Cut()
	if (selected_fuel)
		energy_concentration_multiplier = selected_fuel.energy_concentration_multiplier
		positive_temperature_multiplier = selected_fuel.positive_temperature_multiplier
		negative_temperature_multiplier = selected_fuel.negative_temperature_multiplier

		for(var/gas_id in selected_fuel.requirements | selected_fuel.primary_products)
			var/amount = internal_fusion.get_moles(gas_id)
			hfr_fuel_list[gas_id] = amount
			hfr_scaled_fuel_list[gas_id] = max((amount - HFR_FUSION_MOLE_THRESHOLD) / scale_factor, 0)

	hfr_moderator_list.Cut()
	hfr_scaled_moderator_list.Cut()
	var/list/moderator_gases = moderator_internal.get_gases()
	for(var/gas_id in moderator_gases)
		var/amount = moderator_internal.get_moles(gas_id)
		hfr_moderator_list[gas_id] = amount
		hfr_scaled_moderator_list[gas_id] = max((amount - HFR_FUSION_MOLE_THRESHOLD) / scale_factor, 0)

	CHECK_TICK

	// Нестабильность: gas_power по fusion_powers из обеих смесей, потом (gas_power*factor)^2 mod toroidal_size плюс дампер, минус железо.
	var/toroidal_size = (2 * PI) + TORADIANS(arctan((volume - TOROID_VOLUME_BREAKEVEN) / TOROID_VOLUME_BREAKEVEN))
	var/list/fusion_powers = GLOB.gas_data.fusion_powers
	var/gas_power = 0
	var/list/fusion_gases = internal_fusion.get_gases()
	for (var/gas_id in fusion_gases)
		gas_power += (fusion_powers[gas_id] * internal_fusion.get_moles(gas_id))
	for (var/gas_id in moderator_gases)
		gas_power += (fusion_powers[gas_id] * moderator_internal.get_moles(gas_id) * HFR_MODERATOR_GAS_POWER_FRAC)

	instability = MODULUS((gas_power * INSTABILITY_GAS_POWER_FACTOR)**2, toroidal_size) + (current_damper * HFR_INSTABILITY_DAMPER_FACTOR) - iron_content * HFR_INSTABILITY_IRON_PENALTY
	// Знак нестабильности: ниже порога эндотермичность (1), иначе экзотермичность (-1). Влияет на знак heat_output.
	var/internal_instability = 0
	if(instability * 0.5 < FUSION_INSTABILITY_ENDOTHERMALITY)
		internal_instability = 1
	else
		internal_instability = -1

	// Модификаторы от модератора и топлива: вклад каждого газа (scaled), потом clamp. Входят в energy, power_output, heat, radiation.
	var/energy_modifiers = hfr_scaled_moderator_list[GAS_N2] * 0.35 + \
								hfr_scaled_moderator_list[GAS_CO2] * 0.55 + \
								hfr_scaled_moderator_list[GAS_NITROUS] * 0.95 + \
								hfr_scaled_moderator_list[GAS_ZAUKER] * 1.55 + \
								hfr_scaled_moderator_list[GAS_ANTINOBLIUM] * 20
	energy_modifiers -= hfr_scaled_moderator_list[GAS_HYPERNOB] * 10 + \
								hfr_scaled_moderator_list[GAS_H2O] * 0.75 + \
								hfr_scaled_moderator_list[GAS_NITRIUM] * 0.15 + \
								hfr_scaled_moderator_list[GAS_HEALIUM] * 0.45 + \
								hfr_scaled_moderator_list[GAS_FREON] * 1.15
	var/power_modifier = hfr_scaled_moderator_list[GAS_O2] * 0.55 + \
								hfr_scaled_moderator_list[GAS_CO2] * 0.95 + \
								hfr_scaled_moderator_list[GAS_NITRIUM] * 1.45 + \
								hfr_scaled_moderator_list[GAS_ZAUKER] * 5.55 + \
								hfr_scaled_moderator_list[GAS_PLASMA] * 0.05 - \
								hfr_scaled_moderator_list[GAS_NITROUS] * 0.05 - \
								hfr_scaled_moderator_list[GAS_FREON] * 0.75
	var/heat_modifier = hfr_scaled_moderator_list[GAS_PLASMA] * 1.25 - \
								hfr_scaled_moderator_list[GAS_N2] * 0.75 - \
								hfr_scaled_moderator_list[GAS_NITROUS] * 1.45 - \
								hfr_scaled_moderator_list[GAS_FREON] * 0.95
	var/radiation_modifier = hfr_scaled_moderator_list[GAS_FREON] * 1.15 - \
									hfr_scaled_moderator_list[GAS_N2] * 0.45 - \
									hfr_scaled_moderator_list[GAS_PLASMA] * 0.95 + \
									hfr_scaled_moderator_list[GAS_BZ] * 1.9 + \
									hfr_scaled_moderator_list[GAS_PROTO_NITRATE] * 0.1 + \
									hfr_scaled_moderator_list[GAS_ANTINOBLIUM] * 10

	if (selected_fuel)
		energy_modifiers += hfr_scaled_fuel_list[selected_fuel.requirements[1]] + \
									hfr_scaled_fuel_list[selected_fuel.requirements[2]]
		energy_modifiers -= hfr_scaled_fuel_list[selected_fuel.primary_products[1]]

		power_modifier += hfr_scaled_fuel_list[selected_fuel.requirements[2]] * 1.05 - \
									hfr_scaled_fuel_list[selected_fuel.primary_products[1]] * 0.55

		heat_modifier += hfr_scaled_fuel_list[selected_fuel.requirements[1]] * 1.15 + \
									hfr_scaled_fuel_list[selected_fuel.primary_products[1]] * 1.05

		radiation_modifier += hfr_scaled_fuel_list[selected_fuel.primary_products[1]]

	power_modifier = clamp(power_modifier, HFR_MODIFIER_CLAMP_MIN, HFR_MODIFIER_CLAMP_MAX)
	heat_modifier = clamp(heat_modifier, HFR_MODIFIER_CLAMP_MIN, HFR_MODIFIER_CLAMP_MAX)
	radiation_modifier = clamp(radiation_modifier, HFR_RADIATION_MODIFIER_MIN, HFR_RADIATION_MODIFIER_MAX)

	internal_power = 0
	efficiency = VOID_CONDUCTION * 1

	// Внутренняя мощность: произведение по двум требованиям топлива (scaled*mod/100), площадь поперечника (радиусы H2/трит), и energy. Эффективность от первичного продукта.
	if (selected_fuel)
		internal_power = (hfr_scaled_fuel_list[selected_fuel.requirements[1]] * power_modifier / 100) * (hfr_scaled_fuel_list[selected_fuel.requirements[2]] * power_modifier / 100) * (PI * (2 * (hfr_scaled_fuel_list[selected_fuel.requirements[1]] * CALCULATED_H2RADIUS) * (hfr_scaled_fuel_list[selected_fuel.requirements[2]] * CALCULATED_TRITRADIUS))**2) * energy

		efficiency = VOID_CONDUCTION * clamp(hfr_scaled_fuel_list[selected_fuel.primary_products[1]], 1, 100)

	// Energy: модификаторы * c² * (темп * heat_mod/100), с масштабом чтобы не переполнить float. Дальше core_temperature, conduction, radiation, power_output.
	energy = (energy_modifiers * LIGHT_SPEED_SQ_SCALED) * max(internal_fusion.return_temperature() * heat_modifier / 100, 1) * LIGHT_SPEED_SQ_SCALE
	energy = energy / energy_concentration_multiplier
	energy = clamp(energy, 0, HFR_ENERGY_CLAMP_MAX)
	core_temperature = internal_power * power_modifier / HFR_CORE_TEMP_DIVISOR
	core_temperature = max(TCMB, core_temperature)
	delta_temperature = archived_heat - core_temperature
	conduction = - delta_temperature * (magnetic_constrictor * HFR_CONDUCTION_MAGNETIC_FACTOR)
	radiation = max(-(PLANCK_LIGHT_CONSTANT / HFR_PLANCK_RADIATION_DIVISOR) * radiation_modifier * delta_temperature, 0)
	power_output = HFR_SANITIZE_HEAT(efficiency * (internal_power - conduction - radiation))
	// Лимиты тепла: от уровня и heating_conductor. heat_output от нестабильности и power_output, ограничен min/max.
	heat_limiter_modifier = HFR_SANITIZE_HEAT(HFR_HEAT_LIMITER_BASE * (10 ** power_level) * (heating_conductor * HFR_MAGNETIC_VOLUME_FRAC))
	heat_output_min = HFR_SANITIZE_HEAT(- heat_limiter_modifier * HFR_COOLING_PER_TICK_FACTOR * negative_temperature_multiplier)
	heat_output_max = HFR_SANITIZE_HEAT(heat_limiter_modifier * positive_temperature_multiplier)
	heat_output = HFR_SANITIZE_HEAT(clamp(internal_instability * power_output * heat_modifier / HFR_HEAT_OUTPUT_DIVISOR, heat_output_min, heat_output_max))

	if (!check_fuel())
		return

	// Расход и производство за тик: consumption от уровня и fuel_injection_rate; production от heat_output и уровня (на 3/4 уровне по одному правилу, на остальных по другому).
	var/fuel_consumption_rate = clamp(fuel_injection_rate * HFR_FUEL_CONSUMPTION_RATE_FACTOR * power_level, HFR_FUEL_CONSUMPTION_CLAMP_MIN, HFR_FUEL_CONSUMPTION_CLAMP_MAX)
	var/consumption_amount = fuel_consumption_rate * seconds_per_tick
	var/production_amount
	switch(power_level)
		if(3,4)
			production_amount = clamp(heat_output / HFR_PRODUCTION_HEAT_DIVISOR, 0, fuel_consumption_rate) * seconds_per_tick
		else
			production_amount = clamp(heat_output * HFR_PRODUCTION_HEAT_MULT / 10 ** (power_level+1), 0, fuel_consumption_rate) * seconds_per_tick

	var/dirty_production_rate = hfr_scaled_fuel_list[selected_fuel.primary_products[1]] / fuel_injection_rate

	hfr_internal_output.clear()
	moderator_fuel_process(seconds_per_tick, production_amount, consumption_amount, hfr_internal_output, hfr_moderator_list, selected_fuel, hfr_fuel_list)

	CHECK_TICK

	var/common_production_amount = production_amount * selected_fuel.gas_production_multiplier
	moderator_common_process(seconds_per_tick, common_production_amount, hfr_internal_output, hfr_moderator_list, dirty_production_rate, heat_output, radiation_modifier)

/// Топливо: вычитаем из fusion по requirements, добавляем primary_products. В модератор по уровням (tier) добавляем вторичные продукты. Коэффициенты по уровням захардкожены.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/moderator_fuel_process(seconds_per_tick, production_amount, consumption_amount, datum/gas_mixture/internal_output, moderator_list, datum/hfr_fuel/fuel, fuel_list)
	var/fuel_consumption = consumption_amount * HFR_FUEL_CONSUMPTION_MULT * selected_fuel.fuel_consumption_multiplier
	var/scaled_production = production_amount * selected_fuel.gas_production_multiplier

	for(var/gas_id in fuel.requirements)
		internal_fusion.adjust_moles(gas_id, -min(fuel_list[gas_id], fuel_consumption))
	for(var/gas_id in fuel.primary_products)
		internal_fusion.adjust_moles(gas_id, fuel_consumption * HFR_PRIMARY_PRODUCTION_FRAC)

	var/list/tier = fuel.secondary_products
	switch(power_level)
		if(1)
			moderator_internal.adjust_moles(tier[1], scaled_production * 0.95)
			moderator_internal.adjust_moles(tier[2], scaled_production * 0.75)
		if(2)
			moderator_internal.adjust_moles(tier[1], scaled_production * 1.65)
			moderator_internal.adjust_moles(tier[2], scaled_production)
			if(moderator_list[GAS_PLASMA] > 50)
				moderator_internal.adjust_moles(tier[3], scaled_production * 1.15)
		if(3)
			moderator_internal.adjust_moles(tier[2], scaled_production * 0.5)
			moderator_internal.adjust_moles(tier[3], scaled_production * 0.45)
		if(4)
			moderator_internal.adjust_moles(tier[3], scaled_production * 1.65)
			moderator_internal.adjust_moles(tier[4], scaled_production * 1.25)
		if(5)
			moderator_internal.adjust_moles(tier[4], scaled_production * 0.65)
			moderator_internal.adjust_moles(tier[5], scaled_production)
			moderator_internal.adjust_moles(tier[6], scaled_production * 0.75)
		if(6)
			moderator_internal.adjust_moles(tier[5], scaled_production * 0.35)
			moderator_internal.adjust_moles(tier[6], scaled_production)

/// Выход в output: по уровням 1–6 от количества модератора (BZ, plasma, proto_nitrate и т.д.) добавляем газы в internal_output, правим radiation/heat. Healium при proximity > порога уменьшает proximity и съедает GAS_HEALIUM.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/moderator_common_process(seconds_per_tick, scaled_production, datum/gas_mixture/internal_output, moderator_list, dirty_production_rate, heat_output, radiation_modifier)
	switch(power_level)
		if(1)
			if(moderator_list[GAS_PLASMA] > 100)
				internal_output.adjust_moles(GAS_NITROUS, scaled_production * 0.5)
				moderator_internal.adjust_moles(GAS_PLASMA, -min(moderator_internal.get_moles(GAS_PLASMA), scaled_production * 0.85))
			if(moderator_list[GAS_BZ] > 150)
				internal_output.adjust_moles(GAS_HALON, scaled_production * 0.55)
				moderator_internal.adjust_moles(GAS_BZ, -min(moderator_internal.get_moles(GAS_BZ), scaled_production * 0.95))
		if(2)
			if(moderator_list[GAS_PLASMA] > 50)
				internal_output.adjust_moles(GAS_BZ, scaled_production * 1.8)
				moderator_internal.adjust_moles(GAS_PLASMA, -min(moderator_internal.get_moles(GAS_PLASMA), scaled_production * 1.75))
			if(moderator_list[GAS_PROTO_NITRATE] > 20)
				radiation *= 1.55
				heat_output *= 1.025
				internal_output.adjust_moles(GAS_NITRIUM, scaled_production * 1.05)
				moderator_internal.adjust_moles(GAS_PROTO_NITRATE, -min(moderator_internal.get_moles(GAS_PROTO_NITRATE), scaled_production * 1.35))
		if(3, 4)
			if(moderator_list[GAS_PLASMA] > 10)
				internal_output.adjust_moles(GAS_FREON, scaled_production * 0.15)
				internal_output.adjust_moles(GAS_NITRIUM, scaled_production * 1.05)
				moderator_internal.adjust_moles(GAS_PLASMA, -min(moderator_internal.get_moles(GAS_PLASMA), scaled_production * 0.45))
			if(moderator_list[GAS_FREON] > 50)
				heat_output *= 0.9
				radiation *= 0.8
			if(moderator_list[GAS_PROTO_NITRATE] > 15)
				internal_output.adjust_moles(GAS_NITRIUM, scaled_production * 1.25)
				internal_output.adjust_moles(GAS_HALON, scaled_production * 1.15)
				moderator_internal.adjust_moles(GAS_PROTO_NITRATE, -min(moderator_internal.get_moles(GAS_PROTO_NITRATE), scaled_production * 1.55))
				radiation *= 1.95
				heat_output *= 1.25
			if(moderator_list[GAS_BZ] > 100)
				internal_output.adjust_moles(GAS_HEALIUM, scaled_production * 1.5)
				internal_output.adjust_moles(GAS_PROTO_NITRATE, scaled_production * 1.5)
				visible_hallucination_pulse(src, HALLUCINATION_HFR(heat_output), 100 SECONDS * power_level * seconds_per_tick)

		if(5)
			if(moderator_list[GAS_PLASMA] > 15)
				internal_output.adjust_moles(GAS_FREON, scaled_production * 0.25)
				moderator_internal.adjust_moles(GAS_PLASMA, -min(moderator_internal.get_moles(GAS_PLASMA), scaled_production * 1.45))
			if(moderator_list[GAS_FREON] > 500)
				heat_output *= 0.5
				radiation *= 0.2
			if(moderator_list[GAS_PROTO_NITRATE] > 50)
				internal_output.adjust_moles(GAS_NITRIUM, scaled_production * 1.95)
				internal_output.adjust_moles(GAS_PLUOXIUM, scaled_production)
				moderator_internal.adjust_moles(GAS_PROTO_NITRATE, -min(moderator_internal.get_moles(GAS_PROTO_NITRATE), scaled_production * 1.35))
				radiation *= 1.95
				heat_output *= 1.25
			if(moderator_list[GAS_BZ] > 100)
				internal_output.adjust_moles(GAS_HEALIUM, scaled_production)
				visible_hallucination_pulse(src, HALLUCINATION_HFR(heat_output), 100 SECONDS * power_level * seconds_per_tick)
				internal_output.adjust_moles(GAS_FREON, scaled_production * 1.15)
			if(moderator_list[GAS_HEALIUM] > 100)
				if(critical_threshold_proximity > HFR_HEALIUM_HEAL_PROXIMITY_THRESHOLD)
					critical_threshold_proximity = max(critical_threshold_proximity - (moderator_list[GAS_HEALIUM] / 100) * HFR_HEALIUM_HEAL_RATE_FACTOR * melting_point * seconds_per_tick, 0)
					moderator_internal.adjust_moles(GAS_HEALIUM, -min(moderator_internal.get_moles(GAS_HEALIUM), scaled_production * 20))
			if(moderator_internal.return_temperature() < HFR_ANTINOBLIUM_TEMP_THRESHOLD || (moderator_list[GAS_PLASMA] > 100 && moderator_list[GAS_BZ] > 50))
				internal_output.adjust_moles(GAS_ANTINOBLIUM, dirty_production_rate * 0.9 / 0.065 * seconds_per_tick)
		if(6)
			if(moderator_list[GAS_PLASMA] > 30)
				internal_output.adjust_moles(GAS_BZ, scaled_production * 1.15)
				moderator_internal.adjust_moles(GAS_PLASMA, -min(moderator_internal.get_moles(GAS_PLASMA), scaled_production * 1.45))
			if(moderator_list[GAS_PROTO_NITRATE])
				internal_output.adjust_moles(GAS_ZAUKER, scaled_production * 5.35)
				internal_output.adjust_moles(GAS_NITRIUM, scaled_production * 2.15)
				moderator_internal.adjust_moles(GAS_PROTO_NITRATE, -min(moderator_internal.get_moles(GAS_PROTO_NITRATE), scaled_production * 3.35))
				radiation *= 2
				heat_output *= 2.25
			if(moderator_list[GAS_BZ])
				visible_hallucination_pulse(src, HALLUCINATION_HFR(heat_output), 100 SECONDS * power_level * seconds_per_tick)
				internal_output.adjust_moles(GAS_ANTINOBLIUM, clamp(dirty_production_rate / 0.045, 0, 10) * seconds_per_tick)
			if(moderator_list[GAS_HEALIUM] > 100)
				if(critical_threshold_proximity > HFR_HEALIUM_HEAL_PROXIMITY_THRESHOLD)
					critical_threshold_proximity = max(critical_threshold_proximity - (moderator_list[GAS_HEALIUM] / 100) * HFR_HEALIUM_HEAL_RATE_FACTOR * melting_point * seconds_per_tick, 0)
					moderator_internal.adjust_moles(GAS_HEALIUM, -min(moderator_internal.get_moles(GAS_HEALIUM), scaled_production * 20))
			internal_fusion.adjust_moles(GAS_ANTINOBLIUM, dirty_production_rate * 0.01 / 0.095 * seconds_per_tick)

	src.heat_output = HFR_SANITIZE_HEAT(heat_output)

	// Температура fusion: если не перегрев, добавляем heat_output за тик и clamp; иначе охлаждаем на heat_limiter_modifier за тик.
	if(internal_fusion.return_temperature() <= FUSION_MAXIMUM_TEMPERATURE)
		internal_fusion.set_temperature(clamp(
			internal_fusion.return_temperature() + heat_output * seconds_per_tick,
			TCMB,
			FUSION_MAXIMUM_TEMPERATURE,
		))
	else
		internal_fusion.set_temperature(internal_fusion.return_temperature() - heat_limiter_modifier * HFR_COOLING_PER_TICK_FACTOR * seconds_per_tick)

	// Температура выхода: от модератора или от fusion. Мержим в linked_output и чистим кэш.
	if(hfr_internal_output.total_moles() > 0)
		if(moderator_internal.total_moles() > 0)
			hfr_internal_output.set_temperature(moderator_internal.return_temperature() * HIGH_EFFICIENCY_CONDUCTIVITY)
		else
			hfr_internal_output.set_temperature(internal_fusion.return_temperature() * METALLIC_VOID_CONDUCTIVITY)
		linked_output.airs[1].merge(hfr_internal_output)
		hfr_internal_output.clear()

	evaporate_moderator(seconds_per_tick)

	check_nuclear_particles(hfr_moderator_list)

	check_lightning_arcs(hfr_moderator_list)

	// Хил железа кислородом: при достаточном O2 в модераторе убавляем iron_content и тратим O2 по константам.
	if(hfr_moderator_list[GAS_O2] > HFR_IRON_HEAL_O2_THRESHOLD)
		if(iron_content > 0)
			var/max_iron_removable = IRON_OXYGEN_HEAL_PER_SECOND
			var/iron_removed = min(max_iron_removable * seconds_per_tick, iron_content)
			iron_content -= iron_removed
			moderator_internal.adjust_moles(GAS_O2, -iron_removed * OXYGEN_MOLES_CONSUMED_PER_IRON_HEAL)

	check_gravity_pulse(seconds_per_tick)

	radiation_pulse(src, 500, HFR_LIGHTNING_RADIATION_RANGE)

/// Удаляет из модератора долю молей за тик (экспонента от уровня). Чем выше уровень, тем быстрее испарение.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/evaporate_moderator(seconds_per_tick)
	if (!power_level)
		return
	if(moderator_internal.total_moles() > 0)
		moderator_internal.remove(moderator_internal.total_moles() * (1 - (1 - HFR_EVAPORATE_RATE_BASE * power_level) ** seconds_per_tick))

/// Целостность (critical_threshold_proximity): урон от переполнения, температуры, железа, overmole; хил от малой массы, холодного куланта, кислорода. В конце cap по DAMAGE_CAP_MULTIPLIER.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/process_damageheal(seconds_per_tick)
	critical_threshold_proximity_archived = critical_threshold_proximity

	warning_damage_flags &= HYPERTORUS_FLAG_EMPED

	// Урон при переполнении (много молей и/или высокая темп) на высоком уровне. Плюс урон от лога температуры.
	if(power_level >= HYPERTORUS_OVERFULL_MIN_POWER_LEVEL)
		var/fusion_temp = internal_fusion.return_temperature()
		var/overfull_damage_taken = HYPERTORUS_OVERFULL_MOLAR_SLOPE * internal_fusion.total_moles() + HYPERTORUS_OVERFULL_TEMPERATURE_SLOPE * fusion_temp + HYPERTORUS_OVERFULL_CONSTANT
		critical_threshold_proximity = max(critical_threshold_proximity + max(overfull_damage_taken * seconds_per_tick, 0), 0)
		warning_damage_flags |= HYPERTORUS_FLAG_HIGH_POWER_DAMAGE
		// High fusion temperature damage: log10(fusion_temp) - 5 per tick (doc: 2 at 5e7K, 1 at 1e6K)
		var/high_temp_damage = log(10, max(fusion_temp, 1)) - 5
		critical_threshold_proximity = max(critical_threshold_proximity + max(high_temp_damage * seconds_per_tick, 0), 0)

	// Хил при малой массе в смеси (ниже порога) на уровне не выше 4.
	if(internal_fusion.total_moles() < HYPERTORUS_SUBCRITICAL_MOLES && power_level <= 4)
		var/subcritical_heal_restore = (internal_fusion.total_moles() - HYPERTORUS_SUBCRITICAL_MOLES) / HYPERTORUS_SUBCRITICAL_SCALE
		critical_threshold_proximity = max(critical_threshold_proximity + min(subcritical_heal_restore * seconds_per_tick, 0), 0)

	// Хил от холодного куланта: температура куланта ниже порога, лог даёт отрицательный restore, min(...,0) убавляет proximity.
	if(internal_fusion.total_moles() > 0 && (airs[1].total_moles() && coolant_temperature < HYPERTORUS_COLD_COOLANT_THRESHOLD) && power_level <= 4)
		var/cold_coolant_heal_restore = log(10, max(coolant_temperature, 1) * HYPERTORUS_COLD_COOLANT_SCALE) - (HYPERTORUS_COLD_COOLANT_MAX_RESTORE * 2)
		critical_threshold_proximity = max(critical_threshold_proximity + min(cold_coolant_heal_restore * seconds_per_tick, 0), 0)

	// Урон от железа: (iron_content - 1) * коэффициент за тик. Потом общий cap роста за тик.
	critical_threshold_proximity += max(round(iron_content) - 1, 0) * HFR_IRON_DAMAGE_PER_POINT * seconds_per_tick
	if(round(iron_content) > 1)
		warning_damage_flags |= HYPERTORUS_FLAG_IRON_CONTENT_DAMAGE

	critical_threshold_proximity = min(critical_threshold_proximity_archived + (seconds_per_tick * DAMAGE_CAP_MULTIPLIER * melting_point), critical_threshold_proximity)

	// Гиперкритический урон: молей выше порога, прирост ограничен HYPERTORUS_HYPERCRITICAL_MAX_DAMAGE за тик.
	if(internal_fusion.total_moles() >= HYPERTORUS_HYPERCRITICAL_MOLES)
		var/hypercritical_damage_taken = max((internal_fusion.total_moles() - HYPERTORUS_HYPERCRITICAL_MOLES) * HYPERTORUS_HYPERCRITICAL_SCALE, 0)
		var/clamped_increment = min(hypercritical_damage_taken, HYPERTORUS_HYPERCRITICAL_MAX_DAMAGE) * seconds_per_tick
		critical_threshold_proximity = max(critical_threshold_proximity + clamped_increment, 0)
		warning_damage_flags |= HYPERTORUS_FLAG_HIGH_FUEL_MIX_MOLE

	// Over HFR_OVERMOLE_MOLES: lose HFR_OVERMOLE_DAMAGE_FRAC integrity every HFR_OVERMOLE_INTERVAL_DS ds, capped so large melting_point doesn't overshoot
	if(internal_fusion.total_moles() > HFR_OVERMOLE_MOLES && (world.time - last_overmole_damage) >= HFR_OVERMOLE_INTERVAL_DS)
		var/overmole_cap = 10 * seconds_per_tick * DAMAGE_CAP_MULTIPLIER * melting_point
		critical_threshold_proximity += min(melting_point * HFR_OVERMOLE_DAMAGE_FRAC, overmole_cap, HYPERTORUS_OVERMOLE_MAX_ADD)
		critical_threshold_proximity = min(critical_threshold_proximity_archived + overmole_cap, critical_threshold_proximity)
		last_overmole_damage = world.time

	// Железо: на уровне >4 с вероятностью растёт; на уровне <=4 с вероятностью падает. Потом clamp в [0, max].
	if(power_level > 4 && prob(IRON_CHANCE_PER_FUSION_LEVEL * power_level))
		iron_content += IRON_ACCUMULATED_PER_SECOND * seconds_per_tick
		warning_damage_flags |= HYPERTORUS_FLAG_IRON_CONTENT_INCREASE
	if(iron_content > 0 && power_level <= 4 && prob(HFR_IRON_HEAL_CHANCE_DIVISOR / (power_level + 1)))
		iron_content = max(iron_content - HFR_IRON_DECAY_RATE * seconds_per_tick, 0)
	iron_content = clamp(iron_content, 0, HFR_IRON_CONTENT_MAX)

/// При уровне >= 4 и достаточном BZ стреляет ядерной частицей из случайного угла в противоположную сторону.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_nuclear_particles(moderator_list)
	if(power_level < 4)
		return
	if(moderator_list[GAS_BZ] < (150 / power_level))
		return
	if(!length(corners))
		return
	var/obj/machinery/hypertorus/corner/picked_corner = pick(corners)
	if(!picked_corner)
		return
	picked_corner.loc.fire_nuclear_particle(REVERSE_DIR(picked_corner.dir))

/// При уровне >= 4, достаточном Antinoblium или proximity запускает tesla_zap. Количество разрядов и флаги урона зависят от power_level и proximity.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_lightning_arcs(moderator_list)
	if(power_level < 4)
		return
	if(moderator_list[GAS_ANTINOBLIUM] <= HFR_LIGHTNING_ANTINOBLIUM_MIN && critical_threshold_proximity <= HFR_LIGHTNING_PROXIMITY_MAX)
		return
	var/zap_number = power_level - 2

	if(critical_threshold_proximity > 650 && prob(20))
		zap_number += 1

	var/flags = ZAP_SUPERMATTER_FLAGS
	switch(power_level)
		if(5)
			flags |= (ZAP_MOB_DAMAGE)
		if(6)
			flags |= (ZAP_MOB_DAMAGE | ZAP_OBJ_DAMAGE)

	playsound(loc, 'sound/weapons/emitter2.ogg', 100, TRUE, extrarange = 10)
	for(var/i in 1 to zap_number)
		tesla_zap(src, 5, power_level * 2.4e5, flags)

/// С вероятностью от proximity тянет мобов в радиусе grav_range к реактору. Радиус от log(2.5, proximity).
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_gravity_pulse(seconds_per_tick)
	if(SPT_PROB(100 - critical_threshold_proximity / 15, seconds_per_tick))
		return
	var/grav_range = round(log(2.5, critical_threshold_proximity))
	for(var/mob/living/grav_mob in view(grav_range, src))
		if(grav_mob.mob_negates_gravity())
			continue
		step_towards(grav_mob, loc)

/// Сливает в output отфильтрованные газы модератора и побочные продукты fusion (primary_products). Топливо не выводится.
/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/remove_waste(seconds_per_tick)
	if(!waste_remove)
		return
	var/filtering_amount = moderator_scrubbing.len
	if(filtering_amount > 0)
		for(var/gas_id in moderator_internal.get_gases() & moderator_scrubbing)
			var/datum/gas_mixture/removed = moderator_internal.remove_specific(gas_id, (moderator_filtering_rate / filtering_amount) * seconds_per_tick, hfr_removed_waste)
			if(removed)
				linked_output.airs[1].merge(removed)
				hfr_removed_waste.clear()

	if(selected_fuel)
		for(var/gas_id in selected_fuel.primary_products)
			if(internal_fusion.get_moles(gas_id) <= 0)
				continue
			var/datum/gas_mixture/removed = internal_fusion.remove_specific(gas_id, internal_fusion.get_moles(gas_id) * (1 - (1 - 0.25) ** seconds_per_tick), hfr_removed_waste)
			if(removed)
				linked_output.airs[1].merge(removed)
				hfr_removed_waste.clear()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/process_internal_cooling(seconds_per_tick)
	if(moderator_internal.total_moles() > 0 && internal_fusion.total_moles() > 0)
		var/fusion_temperature_delta = internal_fusion.return_temperature() - moderator_internal.return_temperature()
		var/fusion_heat_amount = (1 - (1 - METALLIC_VOID_CONDUCTIVITY) ** seconds_per_tick) * fusion_temperature_delta * (internal_fusion.heat_capacity() * moderator_internal.heat_capacity() / (internal_fusion.heat_capacity() + moderator_internal.heat_capacity()))
		internal_fusion.set_temperature(max(internal_fusion.return_temperature() - fusion_heat_amount / internal_fusion.heat_capacity(), TCMB))
		moderator_internal.set_temperature(max(moderator_internal.return_temperature() + fusion_heat_amount / moderator_internal.heat_capacity(), TCMB))

	if(airs[1].total_moles() * 0.05 <= MINIMUM_MOLE_COUNT)
		return
	var/datum/gas_mixture/cooling_port = airs[1]
	var/datum/gas_mixture/cooling_remove = cooling_port.remove(0.05 * cooling_port.total_moles())
	if(moderator_internal.total_moles() > 0)
		var/coolant_temperature_delta = cooling_remove.return_temperature() - moderator_internal.return_temperature()
		var/cooling_heat_amount = (1 - (1 - HIGH_EFFICIENCY_CONDUCTIVITY) ** seconds_per_tick) * coolant_temperature_delta * (cooling_remove.heat_capacity() * moderator_internal.heat_capacity() / (cooling_remove.heat_capacity() + moderator_internal.heat_capacity()))
		cooling_remove.set_temperature(max(cooling_remove.return_temperature() - cooling_heat_amount / cooling_remove.heat_capacity(), TCMB))
		moderator_internal.set_temperature(max(moderator_internal.return_temperature() + cooling_heat_amount / moderator_internal.heat_capacity(), TCMB))

	else if(internal_fusion.total_moles() > 0)
		var/coolant_temperature_delta = cooling_remove.return_temperature() - internal_fusion.return_temperature()
		var/cooling_heat_amount = (1 - (1 - METALLIC_VOID_CONDUCTIVITY) ** seconds_per_tick) * coolant_temperature_delta * (cooling_remove.heat_capacity() * internal_fusion.heat_capacity() / (cooling_remove.heat_capacity() + internal_fusion.heat_capacity()))
		cooling_remove.set_temperature(max(cooling_remove.return_temperature() - cooling_heat_amount / cooling_remove.heat_capacity(), TCMB))
		internal_fusion.set_temperature(max(internal_fusion.return_temperature() + cooling_heat_amount / internal_fusion.heat_capacity(), TCMB))
	cooling_port.merge(cooling_remove)

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/inject_from_side_components(seconds_per_tick)
	update_pipenets()

	var/datum/gas_mixture/moderator_port = linked_moderator.airs[1]
	if(start_moderator && moderator_port.total_moles())
		moderator_internal.merge(moderator_port.remove(moderator_injection_rate * seconds_per_tick))
		linked_moderator.update_parents()

	if(!start_fuel || !selected_fuel || !check_gas_requirements())
		return

	var/datum/gas_mixture/fuel_port = linked_input.airs[1]
	for(var/gas_type in selected_fuel.requirements)
		var/datum/gas_mixture/removed = fuel_port.remove_specific(gas_type, fuel_injection_rate * seconds_per_tick / length(selected_fuel.requirements), hfr_removed_waste)
		if(removed)
			internal_fusion.merge(removed)
			hfr_removed_waste.clear()
		linked_input.update_parents()

/obj/machinery/atmospherics/components/unary/hypertorus/core/proc/check_deconstructable()
	if(!active)
		return
	if(power_level > 0)
		fusion_started = TRUE
		linked_input.fusion_started = TRUE
		linked_output.fusion_started = TRUE
		linked_moderator.fusion_started = TRUE
		linked_interface.fusion_started = TRUE
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.fusion_started = TRUE
	else
		fusion_started = FALSE
		linked_input.fusion_started = FALSE
		linked_output.fusion_started = FALSE
		linked_moderator.fusion_started = FALSE
		linked_interface.fusion_started = FALSE
		for(var/obj/machinery/hypertorus/corner/corner in corners)
			corner.fusion_started = FALSE
