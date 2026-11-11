/// Подсистема рыбалки. Крутит активные мини-игры и хранит данные каталога,
/// которыми пользуются удочка, интерфейс каталога и достижения.
SUBSYSTEM_DEF(fishing)
	name = "Fishing"
	wait = 0.1 SECONDS
	flags = SS_KEEP_TIMING
	priority = FIRE_PRIORITY_DEFAULT
	/// Кэш свойств рыбы. Нужен, пока награда ещё не создана и живёт лишь как путь типа.
	var/list/fish_properties = list()
	/// ID рыб, отсканированных анализатором. По ним открываются рыболовные порталы.
	var/list/discovered_fish = list()

/datum/controller/subsystem/fishing/Initialize(start_timeofday)
	. = ..()
	for(var/obj/item/fish/fish_path as anything in subtypesof(/obj/item/fish))
		if(fish_path == /obj/item/fish)
			continue
		fish_properties[fish_path] = list(
			FISH_PROPERTIES_FAV_BAIT = initial(fish_path.favorite_bait),
			FISH_PROPERTIES_BAD_BAIT = initial(fish_path.disliked_bait),
			FISH_PROPERTIES_TRAITS = initial(fish_path.fish_traits),
			FISH_PROPERTIES_BEAUTY_SCORE = initial(fish_path.beauty),
			FISH_PROPERTIES_EVOLUTIONS = initial(fish_path.evolution_types),
		)
	if(GLOB.maintenance_loot)
		GLOB.maintenance_loot[/obj/item/fishing_rod] = 2
		GLOB.maintenance_loot[/obj/item/bait_can/worm] = 2
		GLOB.maintenance_loot[/obj/item/fishing_lure/minnow] = 1
		GLOB.maintenance_loot[/obj/item/fish_catalog] = 1
		GLOB.maintenance_loot[/obj/item/aquarium_kit] = 1
	initialized = TRUE

/datum/controller/subsystem/fishing/proc/discover_fish(obj/item/fish/fish)
	if(!fish)
		return FALSE
	var/fish_id = fish.fish_id || "[fish.type]"
	if(discovered_fish[fish_id])
		return FALSE
	discovered_fish[fish_id] = TRUE
	return TRUE

/datum/controller/subsystem/fishing/proc/get_discovered_count()
	return length(discovered_fish)

/datum/controller/subsystem/fishing/fire(resumed = FALSE)
	var/seconds_per_tick = wait * 0.1
	for(var/mob/user as anything in GLOB.fishing_challenges_by_user)
		var/datum/fishing_challenge/challenge = GLOB.fishing_challenges_by_user[user]
		// Чистим устаревшие записи и чужие челленджи.
		if(QDELETED(challenge) || challenge.completed || challenge.user != user)
			GLOB.fishing_challenges_by_user -= user
			continue
		// Мини-игра обзаводится mover только на старте фазы UI.
		if(!challenge.mover)
			continue
		challenge.process(seconds_per_tick)
