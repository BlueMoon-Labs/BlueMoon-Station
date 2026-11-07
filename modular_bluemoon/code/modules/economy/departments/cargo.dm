/datum/economy_department/cargo
	id = ACCOUNT_CAR
	name = "Снабжение"
	budget_name = "бюджет снабжения"
	head_access = list(ACCESS_QM)

/// Руда платит на станции и на шахтёрских уровнях, кроме руин и чужих шаттлов.
/datum/economy_department/cargo/proc/pays_ore_at(atom/source)
	var/turf/source_turf = get_turf(source)
	if(!source_turf || !(is_station_level(source_turf.z) || is_mining_level(source_turf.z)))
		return FALSE
	var/area/source_area = get_area(source_turf)
	if(istype(source_area, /area/ruin))
		return FALSE
	return !istype(source_area, /area/shuttle) || istype(source_area, /area/shuttle/auxillary_base)

/datum/economy_department/cargo/proc/note_ore(obj/item/stack/ore/ore, amount, atom/source)
	if(!ore.points || amount <= 0 || !pays_ore_at(source))
		return
	SSeconomy.record_work(id, WORK_MINING_ORE, ore.points * amount * econ_sale_factor(COMMODITY_METALS), memo = "Переработка: [ore.name]")
