/datum/round_event_control/portal_storm_syndicate
	name = "Portal Storm: Syndicate Shocktroops"
	typepath = /datum/round_event/portal_storm/syndicate_shocktroop
	weight = 5
	min_players = 40
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/syndicate_shocktroop
	boss_types = list(/mob/living/simple_animal/hostile/syndicate/ranged/space/anthro/cat = 3,\
					/mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space/stormtrooper/anthro/fox = 3,\
					/mob/living/simple_animal/hostile/syndicate/melee/space/anthro/lizard = 3)
	hostile_types = list(/mob/living/simple_animal/hostile/syndicate/melee/anthro = 8,\
						/mob/living/simple_animal/hostile/syndicate/melee/sword/anthro = 6,\
						/mob/living/simple_animal/hostile/syndicate/ranged/smg/anthro = 4,\
						/mob/living/simple_animal/hostile/syndicate/ranged/anthro = 4,\
						/mob/living/simple_animal/hostile/viscerator = 8)
	triggersound = 'modular_bluemoon/sound/ambience/storm/syndie_storm.ogg'

/datum/round_event_control/portal_storm_inteq
	name = "Portal Storm: Inteq Shocktroops"
	typepath = /datum/round_event/portal_storm/inteq_shocktroop
	weight = 55
	min_players = 40
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/inteq_shocktroop
	boss_types = list(/mob/living/simple_animal/hostile/syndicate/ranged/smg/space/stormtrooper = 3,\
					/mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space/stormtrooper = 3,\
					/mob/living/simple_animal/hostile/syndicate/melee/sword/space/stormtrooper = 3)
	hostile_types = list(/mob/living/simple_animal/hostile/syndicate/melee/space = 8,\
						/mob/living/simple_animal/hostile/syndicate/melee = 6,\
						/mob/living/simple_animal/hostile/syndicate/ranged/smg = 4,\
						/mob/living/simple_animal/hostile/syndicate/ranged/shotgun = 4,\
						/mob/living/simple_animal/hostile/viscerator = 8)
	triggersound = 'modular_bluemoon/sound/ambience/storm/syndie_storm.ogg'

/datum/round_event_control/portal_storm_narsie
	name = "Portal Storm: Constructs"
	typepath = /datum/round_event/portal_storm/portal_storm_narsie
	weight = 30
	min_players = 40
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_narsie
	boss_types = list(/mob/living/simple_animal/hostile/cult/magic/elite = 2)
	hostile_types = list(/mob/living/simple_animal/hostile/construct/armored/hostile = 6,\
						/mob/living/simple_animal/hostile/construct/wraith = 6,\
						/mob/living/simple_animal/hostile/cult/ghost = 4,\
						/mob/living/simple_animal/hostile/cult/mannequin = 4,\
						/mob/living/simple_animal/hostile/cult/horror = 4,\
						/mob/living/simple_animal/hostile/cult/warrior = 4,\
						/mob/living/simple_animal/hostile/cult/spear = 2,\
						/mob/living/simple_animal/hostile/cult/assassin = 2,\
						/mob/living/simple_animal/hostile/cult/magic = 2)
	triggersound = 'sound/announcer/classic/_admin_horror_music.ogg'

/datum/round_event_control/portal_storm_clown
	name = "Portal Storm: Clowns"
	typepath = /datum/round_event/portal_storm/portal_storm_clown
	weight = 30
	min_players = 40
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_clown
	boss_types = list(/mob/living/simple_animal/hostile/retaliate/clown/clownhulk = 1)
	hostile_types = list(/mob/living/simple_animal/hostile/retaliate/clown/mutant = 7,\
						/mob/living/simple_animal/hostile/retaliate/clown/mutant/blob = 4,\
						/mob/living/simple_animal/hostile/retaliate/clown/longface = 4,\
						/mob/living/simple_animal/hostile/retaliate/clown/clownhulk/honcmunculus = 7,\
						/mob/living/simple_animal/hostile/retaliate/clown/lube = 5,\
						/mob/living/simple_animal/hostile/retaliate/clown/banana = 5,\
						/mob/living/simple_animal/hostile/retaliate/clown/fleshclown = 4)
	triggersound = 'modular_bluemoon/sound/ambience/storm/clown_storm.ogg'

/datum/round_event_control/portal_storm_necros
	name = "Portal Storm: Necromorphs"
	typepath = /datum/round_event/portal_storm/portal_storm_necros
	weight = 40
	min_players = 50
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_necros
	boss_types = list(/mob/living/simple_animal/hostile/brute = 1)
	hostile_types = list(/mob/living/simple_animal/hostile/brute = 2,\
						/mob/living/simple_animal/hostile/grunt = 10,\
						/mob/living/simple_animal/hostile/spider = 6,\
						/mob/living/simple_animal/hostile/brute/leaper = 5,\
						/mob/living/simple_animal/hostile/brute/uber = 5)
	triggersound = 'modular_bluemoon/sound/ambience/storm/necros_storm.ogg'

/datum/round_event_control/portal_storm_funclaws
	name = "Portal Storm: Funclaws"
	typepath = /datum/round_event/portal_storm/portal_storm_funclaws
	weight = 40
	min_players = 50
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_funclaws
	boss_types = list(/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw/mommyclaw = 1,\
					/mob/living/simple_animal/hostile/deathclaw/funclaw/gentle/newclaw/alphaclaw = 1)
	hostile_types = list(/mob/living/simple_animal/hostile/deathclaw/funclaw/femclaw =4,\
						/mob/living/simple_animal/hostile/deathclaw/funclaw = 4)

	triggersound = 'sound/announcer/classic/_admin_horror_music.ogg'

/datum/round_event_control/portal_storm_skibidi
	name = "Portal Storm: Skibidi"
	typepath = /datum/round_event/portal_storm/portal_storm_skibidi
	weight = 5
	min_players = 75
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_skibidi
	boss_types = list(/mob/living/simple_animal/hostile/skibidi_toilet = 2,\
					/mob/living/simple_animal/hostile/skibidi_toilet/vulp = 2)
	hostile_types = list(/mob/living/simple_animal/hostile/skibidi_toilet = 6,\
						/mob/living/simple_animal/hostile/skibidi_toilet/vulp = 6)

	triggersound = "modular_bluemoon/sound/ambience/storm/skibidi_toilets.ogg"

/datum/round_event_control/portal_storm_clock
	name = "Portal Storm: Clock Cult"
	typepath = /datum/round_event/portal_storm/portal_storm_clock
	weight = 30
	min_players = 40
	earliest_start = 60 MINUTES
	max_occurrences = 1
	category = EVENT_CATEGORY_INVASION

/datum/round_event/portal_storm/portal_storm_clock
	boss_types = list(/mob/living/simple_animal/hostile/boss/clockcultistboss = 1)
	hostile_types = list(/mob/living/simple_animal/hostile/clockcultistmelee = 8,\
						/mob/living/simple_animal/hostile/clockcultistranged = 5,\
						/mob/living/simple_animal/hostile/clockwork/clocktank/weak = 3,\
						/mob/living/simple_animal/hostile/clockwork/clocktank = 2)
	triggersound = 'modular_bluemoon/sound/ambience/storm/clock_storm.ogg'

/datum/round_event/portal_storm
	start_when = 7
	end_when = 999
	announce_when = 1

	var/list/boss_types = list() //only configure this if you have hostiles
	var/number_of_bosses
	var/next_boss_spawn
	var/list/hostile_types = list()
	var/number_of_hostiles
	var/mutable_appearance/storm
	var/triggersound
	var/turf/anchor_turf

/datum/round_event/portal_storm/setup()
	storm = mutable_appearance('icons/obj/tesla_engine/energy_ball.dmi', "energy_ball_fast", FLY_LAYER)
	storm.color = "#ff0000"

	number_of_bosses = 0
	for(var/boss in boss_types)
		number_of_bosses += boss_types[boss]

	number_of_hostiles = 0
	for(var/hostile in hostile_types)
		number_of_hostiles += hostile_types[hostile]

	if(number_of_bosses)
		next_boss_spawn = start_when + CEILING(2 * number_of_hostiles / number_of_bosses, 1)

/datum/round_event/portal_storm/announce(fake)
	do_announce()

/datum/round_event/portal_storm/proc/do_announce()
	set waitfor = FALSE
	sound_to_playing_players('sound/magic/lightning_chargeup.ogg')
	sleep(80)
	var/announce_body
	if(anchor_turf)
		var/area/impact = get_area(anchor_turf)
		var/area_name = impact?.name || "неизвестной зоны"
		if(is_station_level(anchor_turf.z))
			announce_body = "На [station_name()], в районе [area_name], зафиксирована крупная блюспейс-аномалия. Источник — локальная нестабильность. Приготовьтесь к столкновению с угрозами."
		else
			announce_body = "Зафиксирована крупная блюспейс-аномалия в районе [area_name] на внешнем объекте. Источник — локальная нестабильность. Приготовьтесь к столкновению с угрозами."
	else
		announce_body = "На [station_name()] зафиксирована крупная блюспейс-аномалия. Приготовьтесь к столкновению с угрозами."
	priority_announce(announce_body, "Центральное Командование, Отдел Работы с Реальностью", triggersound)
	sleep(20)
	sound_to_playing_players('sound/magic/lightningbolt.ogg')

/datum/round_event/portal_storm/tick()
	var/do_hostile = spawn_hostile()
	var/do_boss = spawn_boss()

	if(do_hostile)
		var/type = safepick(hostile_types)
		hostile_types[type] = hostile_types[type] - 1
		spawn_mob(type)
		if(!hostile_types[type])
			hostile_types -= type

	if(do_boss)
		var/type = safepick(boss_types)
		boss_types[type] = boss_types[type] - 1
		spawn_mob(type)
		if(!boss_types[type])
			boss_types -= type

	time_to_end()

/datum/round_event/portal_storm/proc/spawn_mob(type)
	if(!type)
		return
	var/turf/T
	if(anchor_turf)
		T = get_safe_random_turf_near(anchor_turf)
	else
		T = get_safe_random_station_turf()
	if(!T)
		return
	new type(T)
	spawn_effects(T)

/datum/round_event/portal_storm/proc/spawn_effects(turf/T)
	if(!T)
		log_game("Portal Storm failed to spawn effect due to an invalid location.")
		return
	T = get_step(T, SOUTHWEST) //align center of image with turf
	flick_overlay_static(storm, T, 15)
	playsound(T, 'sound/magic/lightningbolt.ogg', rand(80, 100), 1)

/datum/round_event/portal_storm/proc/spawn_hostile()
	if(!hostile_types || !hostile_types.len)
		return FALSE
	return ISMULTIPLE(activeFor, 2)

/datum/round_event/portal_storm/proc/spawn_boss()
	if(!boss_types || !boss_types.len)
		return FALSE

	if(activeFor == next_boss_spawn)
		next_boss_spawn += CEILING(number_of_hostiles / number_of_bosses, 1)
		return TRUE

/datum/round_event/portal_storm/proc/time_to_end()
	if(!hostile_types.len && !boss_types.len)
		end_when = activeFor

	if(!number_of_hostiles && number_of_bosses)
		end_when = activeFor
