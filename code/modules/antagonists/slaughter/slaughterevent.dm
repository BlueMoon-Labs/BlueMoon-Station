/datum/round_event_control/slaughter
	name = "Spawn Slaughter Demon"
	typepath = /datum/round_event/ghost_role/slaughter
	weight = 1 //Very rare
	max_occurrences = 1
	earliest_start = 2 HOURS
	min_players = 30
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 15
	intensity = 30 // одиночка, но мясорубка
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	/// Тайпкэш дозволенных турфов для скана крови: набор типов фиксирован на компиляции,
	/// пересборка двух typecacheof на каждый вызов не нужна.
	var/static/list/allowed_turf_typecache
	/// world.time, до которого скан декалей не повторяется: бит зовёт can_fire до трёх раз
	/// (план гост-пула, отбор кандидатов, оценка панели) - весу хватает свежести раз в полминуты.
	var/decal_scan_expires = 0

/datum/round_event_control/slaughter/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	// Скан всех клинэблов мира стоит сотен мс на грязной станции, поэтому только после
	// дешёвых базовых гейтов (earliest_start, min_players): до них он выжигал слот
	// директора на каждом бите с накопленным MAJOR-кошельком. CHECK_TICK стоит первым
	// в теле цикла: после continue он недостижим, а не-кровь (грязь, копоть) - это
	// почти весь список, и без него скан не отдаёт тик вообще.
	if(world.time < decal_scan_expires)
		return .
	// Метка ставится ДО скана: он спит на CHECK_TICK, и параллельный вызов (оценка панели
	// поверх бита) не должен запускать второй такой же скан рядом.
	decal_scan_expires = world.time + 30 SECONDS
	weight = initial(src.weight)
	if(isnull(allowed_turf_typecache))
		allowed_turf_typecache = typecacheof(/turf/open) - typecacheof(/turf/open/space)
	var/list/allowed_z_cache = list()
	for(var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		allowed_z_cache[num2text(z)] = TRUE
	for(var/obj/effect/decal/cleanable/C as anything in GLOB.cleanable_decals)
		CHECK_TICK
		if(!C.loc || QDELETED(C))
			continue
		if(!C.can_bloodcrawl_in())
			continue
		if(!SSpersistence.IsValidDebrisLocation(C.loc, allowed_turf_typecache, allowed_z_cache, C.type, FALSE))
			continue
		weight += 0.03

/datum/round_event/ghost_role/slaughter
	minimum_required = 1
	role_name = "slaughter demon"

/datum/round_event/ghost_role/slaughter/spawn_role()
	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected = pick_n_take(candidates)

	var/datum/mind/player_mind = new /datum/mind(selected.key)
	player_mind.active = 1

	var/list/spawn_locs = list()
	for(var/obj/effect/landmark/carpspawn/L in GLOB.landmarks_list)
		if(isturf(L.loc))
			spawn_locs += L.loc
	for(var/obj/effect/landmark/loneopspawn/L in GLOB.landmarks_list)
		if(isturf(L.loc))
			spawn_locs += L.loc

	if(!spawn_locs)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/obj/effect/dummy/phased_mob/slaughter/holder = new /obj/effect/dummy/phased_mob/slaughter((pick(spawn_locs)))
	var/mob/living/simple_animal/slaughter/S = new (holder)
	S.holder = holder
	player_mind.transfer_to(S)
	player_mind.assigned_role = "Slaughter Demon"
	player_mind.special_role = "Slaughter Demon"
	player_mind.add_antag_datum(/datum/antagonist/slaughter)
	to_chat(S, S.playstyle_string)
	to_chat(S, "<B>You are currently not currently in the same plane of existence as the station. Blood Crawl near a blood pool to manifest.</B>")
	SEND_SOUND(S, 'sound/magic/demon_dies.ogg')
	message_admins("[ADMIN_LOOKUPFLW(S)] has been made into a slaughter demon by an event.")
	log_game("[key_name(S)] was spawned as a slaughter demon by an event.")
	spawned_mobs += S
	return SUCCESSFUL_SPAWN
