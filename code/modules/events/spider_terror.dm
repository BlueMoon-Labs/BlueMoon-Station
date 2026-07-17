#define TS_HIGHPOP_TRIGGER 100
#define TS_MIDPOP_TRIGGER 80
#define TS_MINPLAYERS_TRIGGER 50

/datum/round_event_control/spider_terror
	name = "Terror Spider Infestation"
	typepath = /datum/round_event/ghost_role/spider_terror
	weight = 2
	max_occurrences = 1
	min_players = 40
	// Было 90 мин - паучье гнездо почти не успевало в обычный раунд. 55 мин даёт окно; всё ещё
	// поздняя тяжёлая угроза (min_players 40, вес 2, нужно 2-3 призрака-паука).
	earliest_start = 55 MINUTES
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 20
	intensity = 45
	director_ghost_jobban = ROLE_TERROR_SPIDER
	director_ghost_preference = ROLE_TERROR_SPIDER
	intensity_linger = 45 MINUTES // гнездо живёт заметно дольше спавнера
	antag_heavy = TRUE // угроза всей станции: мягкие профили такое выключают
	family = "terror_spiders" // с рулсетом-двойником динамика: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	description = "Spawns spider eggs, ready to hatch."

/datum/round_event_control/spider_terror/director_preflight()
	if(!length(GLOB.xeno_spawn))
		director_preflight_failure = "на карте нет точек xeno_spawn для пауков ужаса"
		return FALSE
	return ..()

/datum/round_event/ghost_role/spider_terror
	announce_when = 240
	role_name = "Паук Ужаса"
	var/spawncount = 1
	var/successSpawn = FALSE	//So we don't make a command report if nothing gets spawned.

/datum/round_event/ghost_role/spider_terror/setup()
	announce_when = rand(announce_when, announce_when + 30)

/datum/round_event/ghost_role/spider_terror/announce()
	if(successSpawn)
		priority_announce("Вспышка биологической угрозы 3-го уровня зафиксирована на борту станции [station_name()]. Всему персоналу надлежит сдержать её распространение любой ценой!", "ВНИМАНИЕ: БИОЛОГИЧЕСКАЯ УГРОЗА.", 'sound/effects/siren-spooky.ogg')

/datum/round_event/ghost_role/spider_terror/spawn_role()
	if(!length(GLOB.xeno_spawn))
		return MAP_ERROR

	var/spider_type
	var/infestation_type
	if((length(GLOB.clients)) >= TS_HIGHPOP_TRIGGER)
		infestation_type = pick(5, 6)
	else if((length(GLOB.clients)) >= TS_MIDPOP_TRIGGER)
		infestation_type = pick(3, 4)
	else
		infestation_type = pick(1, 2)
	switch(infestation_type)
		if(1)          //lowpop spawns
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/defiler
			spawncount = 2
		if(2)
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/princess
			spawncount = 2
		if(3)          //midpop spawns
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/defiler
			spawncount = 3
		if(4)
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen/princess
			spawncount = 3
		if(5)          //highpop spawns
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/queen
			spawncount = 1
		if(6)
			spider_type = /mob/living/simple_animal/hostile/retaliate/poison/terror_spider/prince
			spawncount = 1
	minimum_required = spawncount
	var/list/candidates = get_candidates(ROLE_TERROR_SPIDER, null, ROLE_TERROR_SPIDER)
	if(length(candidates) < spawncount)
		message_admins("Warning: not enough players volunteered to be terrors. Could only spawn [length(candidates)] out of [spawncount]!")
	while(spawncount && length(candidates))
		var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/S = new spider_type(pick(GLOB.xeno_spawn))
		var/mob/M = pick_n_take(candidates)
		S.key = M.key
		S.give_intro_text()
		spawned_mobs += S
		spawncount--
		successSpawn = TRUE
	return successSpawn ? SUCCESSFUL_SPAWN : NOT_ENOUGH_PLAYERS

#undef TS_MINPLAYERS_TRIGGER
#undef TS_HIGHPOP_TRIGGER
#undef TS_MIDPOP_TRIGGER
