// Фиш-портер 3000 - портал для рыбалки по измерениям, которые открываются сканированием рыбы.

// ---- Рыбные источники портала ----
/datum/fish_source/portal
	background = "background_default"
	fish_table = list(
		FISHING_DUD = 7,
		/obj/item/fish/goldfish = 10,
		/obj/item/fish/guppy = 10,
		/obj/item/fish/angelfish = 10,
		/obj/item/fish/perch = 5,
		/obj/item/fish/goldfish/three_eyes = 3,
		/obj/item/fish/plasmatetra = 3,
	)
	catalog_description = "Аквариумное измерение (Фиш-портер 3000)"
	radial_name = "Аквариум"
	radial_state = "fish_tank"
	overlay_state = "portal_aquarium"
	associated_safe_turfs = list(/turf/open/water)
	unlock_requirement = 0

/datum/fish_source/portal/river
	background = "background_default"
	fish_table = list(
		FISHING_DUD = 12,
		/obj/item/fish/goldfish = 20,
		/obj/item/fish/guppy = 18,
		/obj/item/fish/angelfish = 10,
		/obj/item/fish/plasmatetra = 10,
		/obj/item/fish/catfish = 8,
		/obj/item/fish/perch = 10,
		/obj/item/fish/tadpole = 8,
		/obj/item/fish/sacabambaspis = 4,
		/obj/item/fish/sockeye_salmon = 4,
		/obj/item/fish/pike = 2,
		/obj/item/bait_can/worm = 2,
	)
	catalog_description = "Мелководье (Фиш-портер 3000)"
	radial_name = "Мелководье"
	radial_state = "river"
	overlay_state = "portal_river"
	associated_safe_turfs = list(/turf/open/water)
	unlock_requirement = 5

/datum/fish_source/portal/beach
	background = "background_default"
	fish_table = list(
		FISHING_DUD = 8,
		/obj/item/fish/clownfish = 18,
		/obj/item/fish/cardinal = 15,
		/obj/item/fish/greenchromis = 12,
		/obj/item/fish/pufferfish = 10,
		/obj/item/fish/plaice = 10,
		/obj/item/fish/squid = 6,
		/obj/item/fish/sand_crab = 5,
		/obj/item/fish/sand_surfer = 5,
		/obj/item/fish/bumpy = 4,
	)
	catalog_description = "Пляж (Фиш-портер 3000)"
	radial_name = "Пляж"
	radial_state = "palm_beach"
	overlay_state = "portal_beach"
	associated_safe_turfs = list(/turf/open/water)
	unlock_requirement = 8

/datum/fish_source/portal/chasm
	background = "background_chasm"
	fish_table = list(
		FISHING_DUD = 6,
		/obj/item/fish/chasm_crab = 12,
		/obj/item/fish/boned = 5,
		/obj/item/stack/sheet/bone = 6,
	)
	catalog_description = "Бездна (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 20
	radial_name = "Бездна"
	radial_state = "ground_hole"
	overlay_state = "portal_chasm"
	unlock_requirement = 12

/datum/fish_source/portal/ice
	background = "background_ice"
	fish_table = list(
		FISHING_DUD = 8,
		/obj/item/fish/arctic_char = 18,
		/obj/item/fish/sockeye_salmon = 15,
		/obj/item/fish/chasm_crab/ice = 8,
		/obj/item/fish/boned = 3,
	)
	catalog_description = "Ледяная вода (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 18
	radial_name = "Лёд"
	radial_state = "ice"
	overlay_state = "portal_ocean"
	unlock_requirement = 14

/datum/fish_source/portal/onsen
	background = "background_default"
	fish_table = list(
		FISHING_DUD = 10,
		/obj/item/fish/bumpy = 16,
		/obj/item/fish/sacabambaspis = 14,
		/obj/item/fish/catfish = 6,
	)
	catalog_description = "Горячий источник (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 15
	radial_name = "Источник"
	radial_state = "onsen"
	overlay_state = "portal_ocean"
	unlock_requirement = 16

/datum/fish_source/portal/plasma
	background = "background_plasma"
	fish_table = list(
		FISHING_DUD = 5,
		/obj/item/fish/chasm_crab/ice = 14,
		/obj/item/fish/lavaloop/plasma_river = 12,
		/obj/item/coin/plasma = 4,
		/obj/item/stack/ore/plasma = 4,
		/obj/effect/decal/remains/plasma = 2,
	)
	catalog_description = "Плазма (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 25
	radial_name = "Плазма"
	radial_state = "plasma"
	overlay_state = "portal_plasma"
	unlock_requirement = 18

/datum/fish_source/portal/plasma/reason_we_cant_fish(obj/item/fishing_rod/rod, mob/fisherman, atom/parent)
	if(!istype(rod) || !rod.line || !(rod.line.resistance_flags & LAVA_PROOF))
		return "Для рыбалки в плазме нужна укреплённая или огнеупорная леска."
	return ..()

/datum/fish_source/portal/mansus
	background = "background_mansus"
	fish_table = list(
		FISHING_DUD = 8,
		/obj/item/fish/starfish/chrystarfish = 6,
		/obj/item/fish/dolphish = 4,
		/obj/item/fish/flumpulus = 4,
		/obj/item/fish/gullion = 4,
		/obj/item/fish/mossglob = 2,
		/obj/item/fish/babbelfish = 1,
	)
	fish_counts = list(
		/obj/item/fish/mossglob = 2,
		/obj/item/fish/babbelfish = 1,
	)
	fish_count_regen = list(
		/obj/item/fish/mossglob = 15 MINUTES,
		/obj/item/fish/babbelfish = 25 MINUTES,
	)
	catalog_description = "Мансус (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 35
	radial_name = "Мансус"
	radial_state = "cursed"
	overlay_state = "portal_mansus"
	unlock_requirement = 30

/datum/fish_source/portal/ocean
	background = "background_default"
	fish_table = list(
		FISHING_DUD = 8,
		/obj/item/fish/clownfish = 18,
		/obj/item/fish/cardinal = 15,
		/obj/item/fish/greenchromis = 15,
		/obj/item/fish/firefish = 10,
		/obj/item/fish/pufferfish = 8,
		/obj/item/fish/lanternfish = 8,
		/obj/item/fish/plaice = 8,
		/obj/item/fish/stingray = 4,
		/obj/item/fish/squid = 4,
		/obj/item/fish/monkfish = 3,
		/obj/item/fish/swordfish = 2,
		/obj/item/fish/clownfish/lube = 1,
	)
	catalog_description = "Глубокая вода (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 15
	radial_name = "Глубина"
	radial_state = "seaboat"
	overlay_state = "portal_ocean"
	associated_safe_turfs = list(/turf/open/water)
	unlock_requirement = 10

/datum/fish_source/portal/lava
	background = "background_lavaland"
	fish_table = list(
		FISHING_DUD = 6,
		/obj/item/fish/chasm_crab = 12,
		/obj/item/fish/chasm_crab/ice = 6,
		/obj/item/fish/lavaloop = 8,
		/obj/item/fish/lavaloop/plasma_river = 4,
		/obj/item/fish/boned = 4,
		/obj/item/stack/sheet/bone = 4,
	)
	catalog_description = "Лавовое измерение (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 25
	radial_name = "Лава"
	radial_state = "lava"
	overlay_state = "portal_lava"
	unlock_requirement = 15

/datum/fish_source/portal/lava/reason_we_cant_fish(obj/item/fishing_rod/rod, mob/fisherman, atom/parent)
	if(!istype(rod) || !rod.line || !(rod.line.resistance_flags & LAVA_PROOF))
		return "Для рыбалки в лаве нужна укреплённая или огнеупорная леска."
	return ..()

/datum/fish_source/portal/hyperspace
	background = "background_space"
	fish_table = list(
		FISHING_DUD = 6,
		/obj/item/fish/starfish = 8,
		/obj/item/fish/baby_carp = 8,
		/obj/item/fish/sand_surfer = 5,
		/obj/item/fish/sand_crab = 5,
		/obj/item/fish/bumpy = 4,
		/obj/item/stack/ore/bluespace_crystal = 2,
	)
	catalog_description = "Гиперпространство (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 20
	radial_name = "Космос"
	radial_state = "space_rocket"
	overlay_state = "portal_hyperspace"
	unlock_requirement = 20

/// Открывается только через EMAG. Внутри синдикатская рыба и полезный улов.
/datum/fish_source/portal/syndicate
	background = "background_lavaland"
	fish_table = list(
		FISHING_DUD = 5,
		/obj/item/fish/donkfish = 6,
		/obj/item/fish/emulsijack = 6,
		/obj/item/fish/jumpercable = 4,
		/obj/item/fish/chainsawfish = 2,
		/obj/item/fish/pike/armored = 2,
	)
	fish_counts = list(
		/obj/item/fish/chainsawfish = 1,
		/obj/item/fish/pike/armored = 1,
	)
	fish_count_regen = list(
		/obj/item/fish/chainsawfish = 7 MINUTES,
		/obj/item/fish/pike/armored = 7 MINUTES,
	)
	catalog_description = "Синдикатское измерение (Фиш-портер 3000)"
	fishing_difficulty = FISHING_DEFAULT_DIFFICULTY + 30
	radial_name = "Синдикат"
	radial_state = "syndi_snake"
	overlay_state = "portal_syndicate"
	associated_safe_turfs = list(/turf/open/water)
	unlock_requirement = 0

/// Рандомизатор поздней игры. Смешивает таблицы всех порталов в одну случайную.
/datum/fish_source/portal/random
	fish_table = null
	catalog_description = "Случайное измерение (Фиш-портер 3000)"
	radial_name = "Случайность"
	radial_state = "misaligned_question_mark"
	overlay_state = "portal_randomizer"
	unlock_requirement = 25

/datum/fish_source/portal/random/on_fishing_spot_init(datum/component/fishing_spot/spot)
	if(fish_table)
		return
	fish_table = list(/obj/item/fish/holo/checkered = 1)
	for(var/source_type in GLOB.preset_fish_sources)
		if(source_type == type || !ispath(source_type, /datum/fish_source/portal) || ispath(source_type, /datum/fish_source/portal/syndicate))
			continue
		var/datum/fish_source/portal/other = GLOB.preset_fish_sources[source_type]
		fish_table |= other.fish_table
	fish_table -= FISHING_DUD
	for(var/reward in fish_table)
		fish_table[reward] = rand(1, 4)

// ---- Сам фиш-портер ----
/obj/machinery/fishing_portal
	name = "fish-porter 3000"
	desc = "Позволяет рыбачить в других измерениях. Чем больше видов рыб вы просканировали, тем больше порталов открывается."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "portal"
	anchored = FALSE
	density = TRUE
	use_power = NO_POWER_USE
	/// Загруженный компонент рыболовного места.
	var/datum/component/fishing_spot/active
	/// Открывать все направления, не глядя на прогресс сканирования.
	var/all_destinations = FALSE

/obj/machinery/fishing_portal/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag))
	update_icon()

/obj/machinery/fishing_portal/Destroy()
	deactivate()
	return ..()

/obj/machinery/fishing_portal/update_overlays()
	. = ..()
	if(panel_open)
		. += "portal_open"
	if(!active || QDELETED(active) || !active.fish_source)
		return
	. += "portal_on"
	. += active.fish_source.overlay_state
	. += emissive_appearance(icon, "portal_emissive", layer = layer, offset_spokesman = src)

/obj/machinery/fishing_portal/examine(mob/user)
	. = ..()
	. += span_notice("Просканировано видов рыб: [SSfishing.get_discovered_count()].")
	. += span_info("Сканируйте новых рыб анализатором, чтобы открывать новые измерения.")
	if(active && !QDELETED(active) && active.fish_source)
		. += span_notice("Сейчас открыт портал: [active.fish_source.radial_name].")

/obj/machinery/fishing_portal/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	select_fish_source(user)

/obj/machinery/fishing_portal/proc/on_emag(datum/source)
	SIGNAL_HANDLER
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	balloon_alert(usr, "загружен синдикатский режим")
	playsound(src, SFX_SPARKS, 25, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	return TRUE

/obj/machinery/fishing_portal/proc/select_fish_source(mob/user)
	var/list/available = list()
	for(var/source_type in GLOB.preset_fish_sources)
		if(!ispath(source_type, /datum/fish_source/portal))
			continue
		var/datum/fish_source/portal/source = GLOB.preset_fish_sources[source_type]
		if(!source)
			continue
		if(istype(source, /datum/fish_source/portal/syndicate) && !(obj_flags & EMAGGED))
			continue
		if(!all_destinations && source.unlock_requirement > SSfishing.get_discovered_count())
			continue
		available[source.radial_name] = source

	if(!length(available))
		balloon_alert(user, "нет доступных измерений")
		return
	if(length(available) == 1)
		for(var/only_source in available)
			activate(available[only_source], user)
		return

	var/list/choices = list()
	for(var/radial_name in available)
		var/datum/fish_source/portal/source = available[radial_name]
		choices[radial_name] = mutable_appearance('modular_bluemoon/fishing/icons/hud/radial_fishing.dmi', source.radial_state)
	var/choice = show_radial_menu(user, src, choices, radius = 38, custom_check = CALLBACK(src, TYPE_PROC_REF(/atom, can_interact), user), tooltips = TRUE)
	if(!choice || !can_interact(user))
		return
	activate(available[choice], user)

/obj/machinery/fishing_portal/proc/activate(datum/fish_source/selected_source, mob/user)
	if(QDELETED(selected_source))
		return
	deactivate()
	active = AddComponent(/datum/component/fishing_spot, selected_source)
	ADD_TRAIT(src, TRAIT_CATCH_AND_RELEASE, INNATE_TRAIT)
	update_icon()
	balloon_alert(user, "портал открыт")

/obj/machinery/fishing_portal/proc/deactivate()
	if(!active)
		return
	QDEL_NULL(active)
	REMOVE_TRAIT(src, TRAIT_CATCH_AND_RELEASE, INNATE_TRAIT)
	if(!QDELETED(src))
		update_icon()

/obj/machinery/fishing_portal/full
	name = "fish-porter 4000 deluxe"
	desc = "Легендарный рыбацкий портал, открывающий все измерения сразу."
	all_destinations = TRUE

// ---- Набор для сборки ----
/obj/item/fishing_portal_kit
	name = "fish-porter 3000 kit"
	desc = "Разборный портал для рыбалки в других измерениях. Разверните его на полу."
	icon = 'modular_bluemoon/fishing/icons/obj/fishing.dmi'
	icon_state = "portal"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/fishing_portal_kit/attack_self(mob/user)
	. = ..()
	var/turf/target = get_step(user, user.dir)
	if(!target || target.density)
		target = get_turf(user)
	if(locate(/obj/machinery/fishing_portal) in target)
		to_chat(user, span_warning("Здесь уже есть рыбный портал."))
		return
	var/obj/machinery/fishing_portal/portal = new(target)
	portal.anchored = TRUE
	user.visible_message(span_notice("[user] разворачивает [src]."), span_notice("Вы разворачиваете [src]."))
	qdel(src)
