/// Дамп сетки космоса файлом: раскладка, вертикальные связки, гейты и претензии.
/client/proc/space_sectors_panel()
	set category = "Debug.7) Testing"
	set name = "Секторы космоса: сетка"
	if(!check_rights(R_DEBUG))
		return

	var/datum/space_grid/grid = SSmapping.space_grid
	if(!grid)
		to_chat(src, span_warning("Сетка космоса не собрана: карта не заказывала набор секторов."))
		return

	var/list/lines = list()
	lines += "=== Сетка космоса, [time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")] ==="
	lines += "набор карты: [SSmapping.config?.space_sector_set || "не задан"]"
	lines += "объявлено секторов всего: [length(SSmapping.space_sectors)], наборов: [length(SSmapping.space_sector_sets)]"
	lines += ""
	lines += grid.to_ascii()

	lines += ""
	lines += "--- вертикальные связки ---"
	var/list/pairs = grid.vertical_pairs()
	if(!length(pairs))
		lines += "стопок нет: все секторы на одном этаже."
	for(var/list/pair as anything in pairs)
		var/datum/space_level/lower = pair[1]
		var/datum/space_level/upper = pair[2]
		//Трейты - объявленная связка, z_level_above - принятая пересборкой; расходятся на разорванной стопке.
		var/accepted = SSmapping.z_level_above[lower.z_value] == upper.z_value
		lines += "z=[lower.z_value] -> z=[upper.z_value]\tвверх=[lower.traits[ZTRAIT_UP]] вниз=[upper.traits[ZTRAIT_DOWN]]\t[accepted ? "принята" : "НЕ ПРИНЯТА пересборкой связок"]"

	lines += ""
	lines += "--- гейты ---"
	if(!length(GLOB.sector_gates))
		lines += "гейтов на картах нет."
	for(var/gate_id in GLOB.sector_gates)
		var/list/gates = GLOB.sector_gates[gate_id]
		var/list/spots = list()
		for(var/obj/effect/sector_gate/gate as anything in gates)
			spots += "[AREACOORD(gate)]"
		lines += "'[gate_id]'\tштук [length(gates)][length(gates) == 2 ? "" : "  <-- пара не сложилась"]\t[spots.Join(" | ")]"

	lines += ""
	lines += "--- проблемы ---"
	var/list/complaints = grid.validate()
	if(!length(complaints))
		lines += "претензий нет."
	lines += complaints

	var/turf/our_turf = get_turf(mob)
	if(our_turf)
		lines += ""
		lines += "--- где вы ---"
		var/datum/space_level/level = SSmapping.z_list[our_turf.z]
		var/list/spot = grid.coords_of(level)
		var/datum/space_sector/sector = grid.level_sectors[level]
		lines += "z=[our_turf.z] '[level.name]'[sector ? ", сектор '[sector.id]'" : ", без объявления"][spot ? ", клетка ([spot[1]], [spot[2]], этаж [spot[3]])" : ", не на сетке"]"
		for(var/edge in level.neigbours)
			var/datum/space_level/neighbour = level.neigbours[edge]
			lines += "\t[space_grid_edge_name(edge)] -> z=[neighbour.z_value] '[neighbour.name]'"
		//Край уровня уже посчитан в турфы, и именно его видит игрок.
		var/turf/edge_probe = locate(1, our_turf.y, our_turf.z)
		if(isspaceturf(edge_probe))
			var/turf/open/space/probe = edge_probe
			lines += "\tзападный край на вашей широте ведёт на z=[probe.destination_z || "никуда"] ([probe.destination_x || "-"], [probe.destination_y || "-"])"

	multiz_write_dump("space_grid", lines)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Space Sector Grid")
