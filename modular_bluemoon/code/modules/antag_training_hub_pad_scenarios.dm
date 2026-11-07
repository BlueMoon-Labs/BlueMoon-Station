/// Площадка хаба как место проведения сценария группы.
/datum/antag_training_venue/pad
	var/datum/antag_training_hub_pad/place
	/// Пресет, который сценарий грузит на старте; null - пресет площадки как есть.
	var/preset

/datum/antag_training_venue/pad/New(datum/antag_training_arena/owner, datum/antag_training_hub_pad/target, preset_id)
	..()
	place = target
	preset = preset_id

/datum/antag_training_venue/pad/Destroy()
	place = null
	return ..()

/datum/antag_training_venue/pad/id()
	return place?.id

/datum/antag_training_venue/pad/name()
	return place?.name || ..()

/datum/antag_training_venue/pad/noun(accusative = FALSE)
	return accusative ? "площадку" : "площадка"

/datum/antag_training_venue/pad/where()
	return "на площадке «[name()]»"

/datum/antag_training_venue/pad/ready()
	return !!place?.ready()

/datum/antag_training_venue/pad/held_by(datum/antag_training_squad/squad)
	return !!squad && place?.owner_squad == squad

/datum/antag_training_venue/pad/book(datum/antag_training_squad/squad, datum/antag_training_session/requester)
	if(held_by(squad))
		return TRUE
	if(!place || requester?.squad != squad)
		return FALSE
	return place.claim(requester) && held_by(squad)

/datum/antag_training_venue/pad/release(datum/antag_training_squad/squad, reason)
	return held_by(squad) && place.release(reason)

/datum/antag_training_venue/pad/reset()
	if(!place)
		return FALSE
	return place.load_preset(preset || place.preset_id) && ready()

/datum/antag_training_venue/pad/area_bounds()
	return place?.bounds

/datum/antag_training_venue/pad/target_zone()
	return place?.id

/datum/antag_training_venue/pad/side_turfs(side_key)
	. = list()
	if(!ready())
		return
	for(var/list/offset as anything in place.side_offsets[side_key])
		. += place.offset_turf(offset)

/datum/antag_training_venue/pad/side_keys()
	. = list()
	if(!ready())
		return
	for(var/side_key in place.side_offsets)
		. += side_key

/datum/antag_training_venue/pad/mark_turf(mark_id)
	var/list/offset = place?.mark_offsets[mark_id]
	return (offset && ready()) ? place.offset_turf(offset) : null

/datum/antag_training_venue/pad/zone_turfs(zone_id)
	var/turf/start = place_turf(zone_id)
	return start ? antag_training_room_turfs(start, place) : null

/datum/antag_training_venue/pad/floor_turfs()
	. = list()
	if(!ready())
		return
	for(var/turf/open/floor/tile in place.turfs)
		if(!tile.is_blocked_turf())
			. += tile

/datum/antag_training_venue/pad/power_area()
	return place ? GLOB.areas_by_type[place.area_type] : null

/// Площадка для сценария группы: своя, названная лидером или первая свободная. Отказ объясняет лидеру.
/datum/antag_training_hub/proc/scenario_pad(datum/antag_training_squad/squad, pad_id, datum/antag_training_session/requester)
	RETURN_TYPE(/datum/antag_training_hub_pad)
	var/datum/antag_training_hub_pad/held = squad_pad(squad)
	var/datum/antag_training_hub_pad/named = istext(pad_id) ? pad_by_id(pad_id) : null
	if(held && named && named != held)
		requester.practice_message("У группы уже есть [held.name]: сценарий пойдёт на ней. Освободите её, чтобы выбрать другую.")
	if(held)
		return held
	if(named)
		return named
	for(var/datum/antag_training_hub_pad/pad as anything in pads)
		if(pad.ready() && !pad.owner && !pad.owner_squad)
			return pad
	requester.practice_message(station_state == ANTAG_TRAINING_SECTOR_READY ? "Свободных площадок нет: подождите, пока одну освободят." : "Площадки хаба ещё не готовы: они загружаются, когда на полигон входит игрок.")
	return null

/// Последний в игре: у стороны остался участник на ногах, у всех остальных сторон - никого.
/datum/antag_training_scenario_objective/last_standing
	name = "Остаться последним на ногах"

/datum/antag_training_scenario_objective/last_standing/check()
	var/standing = FALSE
	var/rivals = 0
	for(var/datum/antag_training_session/member as anything in scenario.assigned())
		var/down = scenario.member_down(member)
		if(member in scenario.side_members(side))
			standing ||= !down
		else
			rivals++
			if(!down)
				return FALSE
	return standing && rivals > 0

/// Ядро каждого блоба стороны target поставлено и уничтожено.
/datum/antag_training_scenario_objective/destroy_blob
	name = "Уничтожить ядро блоба"
	var/target
	/// Сеанс -> слабая ссылка на ядро, которое он поставил.
	var/list/cores = list()

/datum/antag_training_scenario_objective/destroy_blob/teardown()
	cores.Cut()

/datum/antag_training_scenario_objective/destroy_blob/check()
	var/list/members = scenario.side_members(target)
	if(!length(members))
		return FALSE
	for(var/datum/antag_training_session/member as anything in members)
		var/mob/camera/blob/overmind = member.current_body
		if(!cores[member] && istype(overmind) && overmind.blob_core)
			cores[member] = WEAKREF(overmind.blob_core)
	for(var/datum/antag_training_session/member as anything in members)
		var/datum/weakref/core_ref = cores[member]
		if(!core_ref || core_ref.resolve())
			return FALSE
	return TRUE

/datum/antag_training_scenario_objective/destroy_blob/progress()
	var/list/members = scenario.side_members(target)
	var/placed = 0
	var/destroyed = 0
	for(var/datum/antag_training_session/member as anything in members)
		var/datum/weakref/core_ref = cores[member]
		if(core_ref)
			placed++
			if(!core_ref.resolve())
				destroyed++
	return placed ? "уничтожено ядер [destroyed] из [length(members)]" : "ядро ещё не поставлено"

/// Быстрые сценарии площадок: пресет комнаты грузится на старте, площадка занимается за группой.
/datum/antag_training_scenario/blob_rush
	id = "blob_rush"
	name = "Все против блоба"
	desc = "Площадка «Медотсек». Блоб ставит ядро где-то в отсеке и растёт, все остальные ищут ядро и уничтожают его. Ядро уничтожено - победа экипажа; весь экипаж выведен из строя - победа блоба; не успели до конца отсчёта - тоже победа блоба."
	order = 20
	pad_preset = "medbay"
	min_players = 2
	max_players = 8
	time_limit = 15 MINUTES
	timeout_winner = "blob"
	sides = list("blob" = list("name" = "Блоб", "spawn" = "ward"), "crew" = list("name" = "Экипаж", "spawn" = "lobby"))
	slot_specs = list(
		list("blob", "Блоб", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/creature/blob, 1, TRUE),
		list("crew", "Член экипажа", ANTAG_TRAINING_ROLE_DEFAULT, null, 6, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/destroy_blob, "crew", list("name" = "Найти и уничтожить ядро блоба", "target" = "blob")),
		list(/datum/antag_training_scenario_objective/side_down, "blob", list("name" = "Вывести из строя весь экипаж", "target" = "crew")),
	)

/datum/antag_training_scenario/royale
	id = "royale"
	name = "Королевская битва"
	desc = "Площадка «Лабиринт». Каждый сам за себя: участники стартуют в разных углах, оружие - из снаряжения пульта. Побеждает последний на ногах; до конца отсчёта без итога - ничья."
	order = 21
	pad_preset = "maze"
	min_players = 2
	max_players = 6
	time_limit = 10 MINUTES
	sides = list(
		"first" = list("name" = "Боец 1", "spawn" = "sw"),
		"second" = list("name" = "Боец 2", "spawn" = "ne"),
		"third" = list("name" = "Боец 3", "spawn" = "se"),
		"fourth" = list("name" = "Боец 4", "spawn" = "nw"),
		"fifth" = list("name" = "Боец 5", "spawn" = "center"),
		"sixth" = list("name" = "Боец 6", "spawn" = "entrance"),
	)
	slot_specs = list(
		list("first", "Боец 1", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, TRUE),
		list("second", "Боец 2", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, TRUE),
		list("third", "Боец 3", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, FALSE),
		list("fourth", "Боец 4", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, FALSE),
		list("fifth", "Боец 5", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, FALSE),
		list("sixth", "Боец 6", ANTAG_TRAINING_ROLE_DEFAULT, null, 1, FALSE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/last_standing, "first"),
		list(/datum/antag_training_scenario_objective/last_standing, "second"),
		list(/datum/antag_training_scenario_objective/last_standing, "third"),
		list(/datum/antag_training_scenario_objective/last_standing, "fourth"),
		list(/datum/antag_training_scenario_objective/last_standing, "fifth"),
		list(/datum/antag_training_scenario_objective/last_standing, "sixth"),
	)

/datum/antag_training_scenario/morph_hunt
	id = "morph_hunt"
	name = "Охота на морфа"
	desc = "Площадка «Техи». Морф прячется в тоннелях под видом вещей, охотники с фонарями прочёсывают комнаты. Морф убит - победа охотников; продержался 8 минут - победа морфа."
	order = 22
	pad_preset = "maint"
	min_players = 2
	max_players = 6
	time_limit = 10 MINUTES
	timeout_winner = "morph"
	sides = list("morph" = list("name" = "Морф", "spawn" = "junk"), "hunters" = list("name" = "Охотники", "spawn" = "corridor"))
	slot_specs = list(
		list("morph", "Морф", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/creature/morph, 1, TRUE),
		list("hunters", "Охотник", "crew:Security Officer", null, 5, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "hunters", list("name" = "Убить морфа", "target" = "morph")),
		list(/datum/antag_training_scenario_objective/survive, "morph", list("minutes" = 8)),
	)

/datum/antag_training_scenario/wizard_duel
	id = "wizard_duel"
	name = "Магическая дуэль 2x2"
	desc = "Пустая площадка. Две пары волшебников с разных краёв зала. Побеждает пара, которая выведет из строя обоих соперников; до конца отсчёта без итога - ничья."
	order = 23
	pad_preset = ANTAG_TRAINING_HUB_PAD_BARE
	min_players = 2
	max_players = 4
	time_limit = 10 MINUTES
	sides = list("red" = list("name" = "Красные", "spawn" = "west"), "blue" = list("name" = "Синие", "spawn" = "east"))
	slot_specs = list(
		list("red", "Красный волшебник", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/antag/wizard, 2, TRUE),
		list("blue", "Синий волшебник", ANTAG_TRAINING_ROLE_DEFAULT, /datum/antag_training_program/antag/wizard, 2, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "red", list("name" = "Вывести из строя синих", "target" = "blue")),
		list(/datum/antag_training_scenario_objective/side_down, "blue", list("name" = "Вывести из строя красных", "target" = "red")),
	)

/datum/antag_training_scenario/brig_defense
	id = "brig_defense"
	name = "Оборона брига"
	desc = "Площадка «Бриг». СБ держит бриг за дверями с доступом, налётчики врываются из приёмной. Все офицеры выведены из строя - победа налётчиков; налётчики в крите, мертвы или закованы - победа СБ; до конца отсчёта без итога - тоже победа СБ."
	order = 24
	pad_preset = "brig"
	min_players = 2
	max_players = 8
	time_limit = 10 MINUTES
	timeout_winner = "security"
	sides = list("security" = list("name" = "СБ", "spawn" = "corridor"), "raiders" = list("name" = "Налётчики", "spawn" = "lobby"))
	slot_specs = list(
		list("security", "Офицер СБ", "crew:Security Officer", null, 3, TRUE),
		list("security", "Смотритель", "crew:Warden", null, 1, FALSE),
		list("raiders", "Налётчик", "crew:Assistant", /datum/antag_training_program/antag/traitor, 4, TRUE),
	)
	objective_specs = list(
		list(/datum/antag_training_scenario_objective/side_down, "raiders", list("name" = "Вывести из строя всех офицеров", "target" = "security")),
		list(/datum/antag_training_scenario_objective/side_down, "security", list("name" = "Остановить налётчиков", "target" = "raiders")),
	)
