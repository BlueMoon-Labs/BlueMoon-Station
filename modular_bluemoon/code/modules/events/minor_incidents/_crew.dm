/// Свободный станционный пол; с require_air - ещё и пригодный для дыхания.
/proc/minor_crew_valid_floor(turf/target, require_air = TRUE)
	var/turf/open/floor/floor = target
	if(!istype(floor) || !is_station_level(floor.z) || floor.is_blocked_turf())
		return FALSE
	if(!require_air)
		return TRUE
	var/datum/gas_mixture/air = floor.return_air()
	if(!air)
		return FALSE
	var/pressure = air.return_pressure()
	if(pressure < 80 || pressure > 120 || air.temperature < 270 || air.temperature > 330)
		return FALSE
	return air.get_moles(GAS_O2) >= 10 && air.get_moles(GAS_PLASMA) <= 0.1

/proc/minor_crew_station_areas(list/area_types, list/excluded_types)
	var/list/result = list()
	for(var/area/location as anything in GLOB.sortedAreas)
		if(!is_type_in_list(location, area_types))
			continue
		if(excluded_types && is_type_in_list(location, excluded_types))
			continue
		result += location
	return result

/// Свободный станционный пол отсека; first_only - для неинтерактивного preflight.
/proc/minor_crew_area_floors(area/location, first_only = FALSE, require_air = TRUE)
	var/list/result = list()
	for(var/turf/open/floor/floor in location)
		if(!minor_crew_valid_floor(floor, require_air))
			continue
		result += floor
		if(first_only)
			return result
	return result

/proc/minor_crew_pay_department(account_id, amount, reason)
	var/datum/bank_account/department/account = SSeconomy.get_dep_account(account_id)
	if(!account || amount <= 0)
		return FALSE
	return account.adjust_money(amount, reason)

/proc/minor_crew_pay_person(mob/living/person, amount, reason)
	var/datum/bank_account/account = person?.get_bank_account()
	if(!account || amount <= 0)
		return FALSE
	if(!account.adjust_money(amount, reason))
		return FALSE
	account.bank_card_talk("На счёт поступило [amount] кр.: [reason].")
	return TRUE

/// Снимает участника гост-роли с учёта директора вместе с его долей нагрузки: директор делит её на число назначенных.
/proc/minor_crew_release_ghost_role(action_name, datum/mind/released)
	if(!released)
		return FALSE
	for(var/list/entry as anything in SSdirector.live_ghost_role_spawns)
		var/list/minds = entry["minds"]
		if(entry["name"] != action_name || !(released in minds))
			continue
		var/list/mob_refs = entry["mobs"]
		var/assigned = length(minds) + length(mob_refs)
		entry["intensity"] = entry["intensity"] * (assigned - 1) / assigned
		minds -= released
		return TRUE
	return FALSE

/// Человек, который тащит существо, держит его на руках или несёт на себе.
/proc/minor_crew_carrier(mob/living/creature)
	var/mob/living/carrier = creature.pulledby
	if(!carrier && istype(creature.loc, /obj/item/clothing/head/mob_holder))
		carrier = get(creature.loc, /mob/living)
	if(!carrier && isliving(creature.buckled))
		carrier = creature.buckled
	return ishuman(carrier) ? carrier : null

/// Имя для объявлений: с надетой ID-карты, а без неё - то, что видно со стороны.
/proc/minor_crew_public_name(mob/living/carbon/human/person)
	return person.get_id_name(null) || person.get_visible_name()
