#define TS_HIGHPOP_TRIGGER 100
#define TS_MIDPOP_TRIGGER 80
#define TS_MINPLAYERS_TRIGGER 50

/datum/round_event_control/spider_terror
	name = "Terror Spider Infestation"
	typepath = /datum/round_event/ghost_role/spider_terror
	weight = 1
	max_occurrences = 1
	min_players = 40
	earliest_start = 90 MINUTES
	category = EVENT_CATEGORY_ENTITIES
	severity = DIRECTOR_SEVERITY_GHOST // антаги из призраков - гост-пул, а не общий MAJOR
	cost = 20
	intensity = 45
	intensity_linger = 45 MINUTES // гнездо живёт заметно дольше спавнера
	antag_heavy = TRUE // угроза всей станции: мягкие профили такое выключают
	family = "terror_spiders" // с рулсетом-двойником динамика: не подряд
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM) // не экста и не лайт
	description = "Spawns spider eggs, ready to hatch."

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

/datum/round_event/ghost_role/spider_terror/start()
	// It is necessary to wrap this to avoid the event triggering repeatedly.
	INVOKE_ASYNC(src, PROC_REF(wrappedstart))

/datum/round_event/ghost_role/spider_terror/proc/wrappedstart()
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
	var/list/candidates = get_candidates(ROLE_TERROR_SPIDER, null, ROLE_TERROR_SPIDER)
	if(length(candidates) < spawncount)
		message_admins("Warning: not enough players volunteered to be terrors. Could only spawn [length(candidates)] out of [spawncount]!")
	while(spawncount && length(candidates))
		var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/S = new spider_type(pick(GLOB.xeno_spawn))
		var/mob/M = pick_n_take(candidates)
		S.key = M.key
		S.give_intro_text()
		spawncount--
		successSpawn = TRUE

#undef TS_MINPLAYERS_TRIGGER
#undef TS_HIGHPOP_TRIGGER
#undef TS_MIDPOP_TRIGGER
