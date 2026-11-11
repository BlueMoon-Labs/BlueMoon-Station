/// Обычные рыболовные источники для водоёмов и мелких водопроводных объектов.
/datum/fish_source/water
	catalog_description = "Открытая вода"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY
	background = "background_default"

/datum/fish_source/water/freshwater
	fish_table = list(
		FISHING_DUD = 20,
		/obj/item/fish/goldfish = 25,
		/obj/item/fish/guppy = 20,
		/obj/item/fish/angelfish = 12,
		/obj/item/fish/plasmatetra = 10,
		/obj/item/fish/catfish = 8,
		/obj/item/fish/perch = 10,
		/obj/item/fish/tadpole = 8,
		/obj/item/fish/sacabambaspis = 4,
		/obj/item/fish/goldfish/three_eyes = 2,
		/obj/item/fish/sockeye_salmon = 4,
		/obj/item/fish/arctic_char = 3,
		/obj/item/fish/pike = 2,
		/obj/item/fish/lcm/bass = 6,
		/obj/item/fish/lcm/trout = 3,
		/obj/item/fish/lcm/eel = 3,
		/obj/item/fish/lcm/northernpike = 2,
		/obj/item/fish/lcm/yang = 1,
		/obj/item/fish/lcm/yin = 1,
		/obj/item/fishing_rod/fiberglass = 1,
		/obj/item/bait_can/worm = 2,
	)
	associated_safe_turfs = list(/turf/open/water)

/datum/fish_source/water/saltwater
	fish_table = list(
		FISHING_DUD = 20,
		/obj/item/fish/clownfish = 22,
		/obj/item/fish/cardinal = 18,
		/obj/item/fish/greenchromis = 18,
		/obj/item/fish/firefish = 12,
		/obj/item/fish/pufferfish = 9,
		/obj/item/fish/lanternfish = 8,
		/obj/item/fish/plaice = 10,
		/obj/item/fish/stingray = 4,
		/obj/item/fish/squid = 4,
		/obj/item/fish/monkfish = 3,
		/obj/item/fish/swordfish = 2,
		/obj/item/fish/clownfish/lube = 1,
		/obj/item/fish/lcm/blue_tang = 10,
		/obj/item/fish/lcm/sheephead = 4,
		/obj/item/fish/lcm/bluefintuna = 2,
		/obj/item/fish/lcm/smolshark = 3,
		/obj/item/fish/lcm/marine_shrimp = 8,
		/obj/item/fish/lcm/lobster = 4,
		/obj/item/fishing_rod/titanium = 1,
	)
	associated_safe_turfs = list(/turf/open/water)

/datum/fish_source/water/anadromous
	fish_table = list(
		FISHING_DUD = 15,
		/obj/item/fish/sockeye_salmon = 30,
		/obj/item/fish/arctic_char = 25,
		/obj/item/fish/pike = 20,
		/obj/item/fish/pike/armored = 4,
		/obj/item/fish/goldfish = 10,
		/obj/item/fish/catfish = 8,
	)
	associated_safe_turfs = list(/turf/open/water)

/datum/fish_source/water/any
	fish_table = list(
		FISHING_DUD = 20,
		/obj/item/fish/goldfish = 10,
		/obj/item/fish/guppy = 10,
		/obj/item/fish/angelfish = 8,
		/obj/item/fish/clownfish = 10,
		/obj/item/fish/cardinal = 8,
		/obj/item/fish/greenchromis = 8,
		/obj/item/fish/plasmatetra = 6,
		/obj/item/fish/catfish = 5,
		/obj/item/fish/perch = 6,
		/obj/item/fish/firefish = 4,
		/obj/item/fish/pufferfish = 3,
		/obj/item/fish/tadpole = 4,
		/obj/item/bait_can/worm = 2,
	)
	associated_safe_turfs = list(/turf/open/water)

/datum/fish_source/water/pool
	catalog_description = "Плавательный бассейн"
	fishing_difficulty = FISHING_EASY_DIFFICULTY
	fish_table = list(
		FISHING_DUD = 30,
		/obj/item/fish/goldfish = 20,
		/obj/item/fish/guppy = 20,
		/obj/item/fish/clownfish = 10,
		/obj/item/fish/plasmatetra = 6,
		/obj/item/fish/tadpole = 6,
		/obj/item/fish/starfish = 3,
		/obj/item/stack/spacecash/c10 = 3,
	)

/datum/fish_source/water/sink
	catalog_description = "Раковина"
	fishing_difficulty = FISHING_EASY_DIFFICULTY
	fish_table = list(
		FISHING_DUD = 35,
		/obj/item/fish/goldfish = 18,
		/obj/item/fish/guppy = 12,
		/obj/item/fish/tadpole = 10,
		/obj/item/fish/ratfish = 6,
		/obj/item/fish/sludgefish = 4,
		/obj/item/fish/slimefish = 3,
		/obj/item/stack/spacecash/c1 = 4,
		/obj/item/trash/plate = 4,
		/obj/item/soap = 2,
	)

// Вешаем рыболовные места на водные тайлы и разливы жидкости.
/turf/open/water/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/any])

/turf/open/pool/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/pool])

/obj/structure/toilet/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/toilet])

/obj/structure/sink/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/sink])

/obj/structure/urinal/Initialize(no_shit = FALSE)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/toilet])

/obj/machinery/shower/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/sink])

/obj/structure/reagent_dispensers/water_cooler/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/fishing_spot, GLOB.preset_fish_sources[/datum/fish_source/water/sink])


/// Главное сокровище любой станции - унитаз.
/datum/fish_source/toilet
	catalog_description = "Мутная вода унитаза"
	fishing_difficulty = FISHING_EASY_DIFFICULTY
	background = "background_dank"
	duds = list("ничего", "просто вода", "крючок пуст")
	fish_table = list(
		FISHING_DUD = 30,
		/obj/item/fish/ratfish = 20,
		/obj/item/fish/sludgefish = 10,
		/obj/item/fish/slimefish = 8,
		/obj/item/fish/donkfish = 5,
		/obj/item/fish/emulsijack = 3,
		/obj/item/fish/baby_carp = 4,
		/obj/item/fish/goldfish = 3,
		/obj/item/stack/spacecash/c1 = 5,
		/obj/item/trash/plate = 3,
		/obj/item/soap = 2,
		/obj/item/reagent_containers/food/snacks/badrecipe = 2,
	)
	fish_counts = list(
		/obj/item/fish/donkfish = 2,
		/obj/item/fish/emulsijack = 1,
	)
	fish_count_regen = list(
		/obj/item/fish/donkfish = 15 MINUTES,
		/obj/item/fish/emulsijack = 25 MINUTES,
	)

/datum/fish_source/moisture_trap
	catalog_description = "Ловушка влаги"
	fishing_difficulty = FISHING_EASY_DIFFICULTY
	fish_table = list(
		FISHING_DUD = 40,
		/obj/item/fish/tadpole = 20,
		/obj/item/fish/ratfish = 10,
		/obj/item/fish/sludgefish = 8,
		/obj/item/fish/slimefish = 5,
		/obj/item/trash/plate = 5,
		/obj/item/soap = 3,
	)

/datum/fish_source/chasm
	catalog_description = "Бездонная пропасть"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY
	background = "background_chasm"
	fish_table = list(
		FISHING_DUD = 20,
		/obj/item/fish/chasm_crab = 25,
		/obj/item/fish/lavaloop = 8,
		/obj/item/stack/sheet/bone = 12,
		/obj/item/stack/ore/slag = 8,
		/obj/item/stack/spacecash/c50 = 3,
	)


/// Датум, который вытаскивает всё, что свалилось в пропасть.
/datum/chasm_detritus
	/// Шанс в процентах вытащить что-нибудь из default_contents.
	var/default_contents_chance = 25
	/// Улов, который достанется даже из пустой ямы.
	var/static/list/default_contents = list(
		/obj/item/stack/sheet/bone = 6,
		/obj/item/stack/ore/slag = 4,
		/obj/effect/mob_spawn/corpse/human/skeleton = 2,
	)

/datum/chasm_detritus/proc/dispense_detritus(atom/spawn_location, atom/fishing_spot)
	var/default_spawn = pick(default_contents)
	return new default_spawn(spawn_location)

/datum/chasm_detritus/restricted
	var/chasm_storage_restricted_type = /obj

/datum/chasm_detritus/restricted/objects
	default_contents_chance = 12.5

/datum/chasm_detritus/restricted/bodies
	default_contents_chance = 12.5
	chasm_storage_restricted_type = /mob
