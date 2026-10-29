/// Бриг, перма, пересылка и ГУЛАГ
GLOBAL_LIST_INIT(brother_brig_areas, list(
	/area/security/brig,
	/area/security/brig_cells,
	/area/security/holding_cell,
	/area/security/prison,
	/area/security/execution/transfer,
	/area/security/processing,
	/area/mine/laborcamp,
))

/// Людные зоны: бар, кафетерий, главные коридоры, прибытие
GLOBAL_LIST_INIT(brother_public_areas, list(
	/area/service/bar,
	/area/service/cafeteria,
	/area/hallway/primary,
	/area/hallway/floor1,
	/area/hallway/floor2,
	/area/hallway/floor3,
	/area/hallway/floor4,
	/area/hallway/secondary/entry,
))

/// Как вещи узелка клятвы называются в окне и в чате
GLOBAL_LIST_INIT(brother_kit_labels, list(
	/obj/item/clothing/gloves/color/yellow = "изолированные перчатки",
	/obj/item/multitool = "мультитул",
	/obj/item/screwdriver = "отвёртка",
	/obj/item/wirecutters = "кусачки",
	/obj/item/crowbar/red = "монтировка",
	/obj/item/clothing/mask/balaclava = "балаклава",
	/obj/item/restraints/handcuffs/cable/zipties = "стяжки",
	/obj/item/camera = "фотоаппарат",
	/obj/item/reagent_containers/glass/bottle/iron = "бутылочка железа для крови",
))

/// Предметы типа item_type у живых братьев и в Схроне крови
/proc/brother_team_items(datum/team/brother_team/team, item_type)
	. = list()
	if(!team || !item_type)
		return
	for(var/mob/living/brother_body as anything in team.living_brothers())
		. += brother_body.GetAllContents(item_type)
	if(team.stash)
		. += team.stash.GetAllContents(item_type)

/// Предмет у братьев; с item_info годится и замена из altitems, но только с особой проверкой цели кражи
/proc/brother_team_holds(datum/team/brother_team/team, item_type, datum/objective_item/item_info)
	for(var/obj/item/held as anything in brother_team_items(team, item_type))
		if(!item_info || item_info.check_special_completion(held))
			return TRUE
	if(!item_info)
		return FALSE
	for(var/alt_type in item_info.altitems)
		for(var/obj/item/held as anything in brother_team_items(team, alt_type))
			if(item_info.check_special_completion(held))
				return TRUE
	return FALSE

/// Ценность или её заменитель где-то в содержимом holder
/proc/brother_holder_has(atom/holder, datum/objective_item/item_info)
	if(!holder || !item_info)
		return FALSE
	for(var/obj/item/held as anything in holder.GetAllContents(/obj/item))
		if((istype(held, item_info.targetitem) || (held.type in item_info.altitems)) && item_info.check_special_completion(held))
			return TRUE
	return FALSE

/// Название ценности в винительном падеже: первая фраза, без точки на конце
/proc/brother_item_name(datum/objective_item/item_info)
	. = trim(item_info.name)
	var/sentence_end = findtext(., ". ")
	if(sentence_end)
		. = copytext(., 1, sentence_end)
	if(copytext(., -1) == ".")
		. = copytext(., 1, -1)

/// Ценность из пула краж с фильтрами steal/find_target; снаряжения братьям не выдаётся, такие цели пропускаются
/proc/brother_steal_pick(datum/team/brother_team/team, list/exclude_types, datum/mind/recipient)
	var/static/list/never_picked = typecacheof(list(/datum/objective_item/steal/functionalai, /datum/objective_item/steal/nukedisc))
	if(!length(GLOB.possible_items))
		for(var/item_type in subtypesof(/datum/objective_item/steal))
			new item_type
	var/list/datum/objective_item/candidates = list()
	for(var/datum/objective_item/possible_item as anything in GLOB.possible_items)
		if(never_picked[possible_item.type] || (possible_item.targetitem in exclude_types) || length(possible_item.special_equipment))
			continue
		if(recipient && (recipient.assigned_role in possible_item.excludefromjob))
			continue
		var/excluded = FALSE
		for(var/datum/mind/member as anything in team.members)
			if(member.assigned_role in possible_item.excludefromjob)
				excluded = TRUE
				break
		if(!excluded)
			candidates += possible_item
	while(length(candidates))
		var/datum/objective_item/picked = pick_n_take(candidates)
		if(picked.ExtraCheck())
			return picked
	return null

/// Разум годится в цели клятвы: живой человек, не брат, не антаг, не гост-роль, согласен на уровень
/proc/brother_target_valid(datum/team/brother_team/team, datum/mind/candidate, required_level, require_station = TRUE)
	if(!candidate || !ishuman(candidate.current))
		return FALSE
	var/mob/living/carbon/human/body = candidate.current
	if(QDELETED(body) || body.stat == DEAD)
		return FALSE
	if(team?.training)
		return candidate == team.training_target && !(candidate in team.members) && !(candidate in team.severed_minds)
	var/turf/body_turf = get_turf(body)
	if(!body_turf || (require_station && !is_station_level(body_turf.z)))
		return FALSE
	if(team && ((candidate in team.members) || (candidate in team.severed_minds)))
		return FALSE
	if(brother_mind_is_antagonist(candidate) || candidate.is_ghost_role())
		return FALSE
	return antag_opt_in_allows(candidate, required_level)

/// Случайная цель с игроком у тела; picker - клятва со своими требованиями к цели
/proc/brother_pick_target(datum/team/brother_team/team, required_level, list/exclude_roles, datum/blood_oath/picker)
	if(team?.training)
		return brother_target_valid(team, team.training_target, required_level) ? team.training_target : null
	var/list/datum/mind/candidates = list()
	for(var/datum/data/record/record as anything in GLOB.data_core.locked)
		var/datum/mind/candidate = record.fields["mindref"]
		if((candidate?.assigned_role in exclude_roles) || !brother_target_valid(team, candidate, required_level))
			continue
		var/mob/living/body = candidate.current
		if(!GET_CLIENT(body) || (picker && !picker.target_allowed(candidate)))
			continue
		candidates |= candidate
	return length(candidates) ? pick(candidates) : null

/proc/brother_team_violence_allowed(datum/team/brother_team/team)
	if(bm_traitor_violence_tier() == BM_TRAITOR_VIOLENCE_NONE)
		return FALSE
	if(!team)
		return TRUE
	for(var/datum/mind/member as anything in team.members - team.departed_minds)
		if(member.get_antag_objective_style() == ANTAG_OBJECTIVE_STYLE_QUIET)
			return FALSE
	return TRUE

/proc/brother_area_is(atom/place, list/area_types)
	var/area/place_area = get_area(place)
	return place_area && is_type_in_list(place_area, area_types)

/// Оба на одном z и не дальше range клеток
/proc/brother_within(atom/first, atom/second, range)
	var/turf/first_turf = get_turf(first)
	var/turf/second_turf = get_turf(second)
	if(!first_turf || !second_turf || first_turf.z != second_turf.z)
		return FALSE
	return get_dist(first_turf, second_turf) <= range

/// Длительность как «м:сс»
/proc/brother_time_text(duration)
	var/total_seconds = max(round(duration / (1 SECONDS)), 0)
	var/seconds = total_seconds % 60
	return "[round(total_seconds / 60)]:[seconds < 10 ? "0" : ""][seconds]"
