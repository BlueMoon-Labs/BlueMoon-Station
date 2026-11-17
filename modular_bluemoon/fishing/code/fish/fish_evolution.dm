/// Глобальный список эволюций рыб, по синглтону на тип.
GLOBAL_LIST_INIT(fish_evolutions, init_subtypes_w_path_keys(/datum/fish_evolution, list()))
/// Список типов эволюций, каждый хранит все виды рыб с этой эволюцией.
GLOBAL_LIST_EMPTY(fishes_by_fish_evolution)

/**
 * Датумы эволюции рыб
 *
 * Если эволюция есть в evolution_types рыбы и check_conditions() не против,
 * есть шанс, что потомство выйдет нового типа, а не как у источника или партнёра.
 */
/datum/fish_evolution
	/// Имя эволюции. Если пусто, берётся из имени нового типа рыбы при запуске.
	var/name
	/// Шанс, что эта эволюция вообще сработает.
	var/probability = 0
	/// Путь к типу новой рыбы
	var/obj/item/fish/new_fish_type = /obj/item/fish
	/// Нижняя граница температуры для появления новой рыбы
	var/required_temperature_min = 0
	/// Верхняя граница температуры для появления новой рыбы
	var/required_temperature_max = INFINITY
	/// Черты, которые получит новая рыба. Они важнее родительских.
	var/list/new_traits
	/// Если задано, эти черты у новой рыбы снимаются.
	var/list/removed_traits

/datum/fish_evolution/New()
	SHOULD_CALL_PARENT(TRUE)
	..()
	if(!ispath(new_fish_type, /obj/item/fish))
		stack_trace("[type] instantiated with a new fish type of [new_fish_type]. That's not a fish, hun, things will break.")
	if(!name)
		name = capitalize(initial(new_fish_type.name))
/**
 * Главная проверка, может ли эволюция случиться.
 * Держите в голове, что mate и aquarium могут быть null, если
 * рыба размножается сама или эволюцию запустил fish_growth
 */
/datum/fish_evolution/proc/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	SHOULD_CALL_PARENT(TRUE)
	// вне аквариума рыбы не плодятся, но растут, так что смотрим только температуру.
	if(!aquarium)
		return source.proper_environment(required_temperature_min, required_temperature_max)
	if(SEND_SIGNAL(aquarium, COMSIG_AQUARIUM_CHECK_EVOLUTION_CONDITIONS, source, mate, src) & COMPONENT_ALLOW_EVOLUTION)
		return TRUE
	return FALSE

/// Срабатывает, когда эволюция выбрана результатом компонента fish_growth
/datum/fish_evolution/proc/growth_checks(obj/item/fish/source, seconds_per_tick, growth)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	if(source.get_health_percentage() < 0.5)
		return COMPONENT_DONT_GROW
	if(source.get_hunger() >= 0.5) // слишком голодна, чтобы расти
		return COMPONENT_DONT_GROW
	if(HAS_TRAIT(source.loc, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH)) // в аквариуме размножение и рост отключены
		return COMPONENT_DONT_GROW
	if(!check_conditions(source))
		return COMPONENT_DONT_GROW

/datum/fish_evolution/lubefish
	probability = 25
	new_fish_type = /obj/item/fish/clownfish/lube
	new_traits = list(/datum/fish_trait/lubed)

/datum/fish_evolution/lubefish/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	if(!HAS_TRAIT(source, TRAIT_FISH_FED_LUBE))
		return FALSE
	return ..()

/datum/fish_evolution/purple_sludgefish
	probability = 5
	new_fish_type = /obj/item/fish/sludgefish/purple
	new_traits = list(/datum/fish_trait/recessive)
	removed_traits = list(/datum/fish_trait/no_mating)

/datum/fish_evolution/mastodon
	name = "???" // в каталоге эту рыбу не показываем
	probability = 40
	new_fish_type = /obj/item/fish/mastodon
	new_traits = list(/datum/fish_trait/heavy, /datum/fish_trait/amphibious, /datum/fish_trait/predator, /datum/fish_trait/territorial)

/datum/fish_evolution/mastodon/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	if((source.size < 120 || source.weight < 3000) || (mate && (mate.size < 120 || mate.weight < 3000)))
		return FALSE
	return ..()

/datum/fish_evolution/chasm_chrab
	probability = 50
	new_fish_type = /obj/item/fish/chasm_crab
	required_temperature_min = MIN_AQUARIUM_TEMP+14
	required_temperature_max = MIN_AQUARIUM_TEMP+15

/datum/fish_evolution/ice_chrab
	probability = 50
	new_fish_type = /obj/item/fish/chasm_crab/ice
	required_temperature_min = MIN_AQUARIUM_TEMP+9
	required_temperature_max = MIN_AQUARIUM_TEMP+10

/datum/fish_evolution/three_eyes
	probability = 3
	new_fish_type = /obj/item/fish/goldfish/three_eyes
	new_traits = list(/datum/fish_trait/recessive)

/datum/fish_evolution/chainsawfish
	probability = 30
	new_fish_type = /obj/item/fish/chainsawfish
	new_traits = list(/datum/fish_trait/predator, /datum/fish_trait/territorial)

/datum/fish_evolution/chainsawfish/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	var/double_avg_size = /obj/item/fish/goldfish::average_size * 2
	var/double_avg_weight = /obj/item/fish/goldfish::average_weight * 2
	if(source.size >= double_avg_size && source.weight >= double_avg_weight && (/datum/fish_trait/territorial in source.fish_traits))
		return ..()
	return FALSE

/datum/fish_evolution/armored_pike
	probability = 75
	new_fish_type = /obj/item/fish/pike/armored

/datum/fish_evolution/armored_pike/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	if(HAS_TRAIT(source, TRAIT_FISH_STINGER))
		return ..()
	return FALSE

/datum/fish_evolution/fritterish
	new_fish_type = /obj/item/fish/fryish/fritterish
	removed_traits = list(/datum/fish_trait/no_mating)

/datum/fish_evolution/nessie
	name = "???"
	new_fish_type = /obj/item/fish/fryish/nessie

/datum/fish_evolution/nessiefish/check_conditions(obj/item/fish/source, obj/item/fish/mate, atom/movable/aquarium)
	if(source.size >= (/obj/item/fish/fryish/fritterish::average_size * 1.5) && source.size >= (/obj/item/fish/fryish/fritterish::average_weight * 1.5))
		return ..()
	return FALSE

/datum/fish_evolution/moonfish
	probability = 200 // гарантированно, если условия сошлись
	new_fish_type = /obj/item/fish/moonfish

/datum/fish_evolution/moonfish/check_conditions(obj/item/fish/source, obj/item/fish/mate, obj/structure/aquarium/aquarium)
	if(source.size < (/obj/item/fish/moonfish/dwarf::average_size * 1.5) && source.size < (/obj/item/fish/moonfish/dwarf::average_weight * 1.5))
		return FALSE
	if(mate && (mate.size < (/obj/item/fish/moonfish::average_size * 1.3) && mate.size < (/obj/item/fish/moonfish::average_weight * 1.3)))
		return FALSE
	return ..()

/datum/fish_evolution/dwarf_moonfish
	probability = 200 // гарантированно, если условия сошлись
	new_fish_type = /obj/item/fish/moonfish/dwarf

/datum/fish_evolution/dwarf_moonfish/check_conditions(obj/item/fish/source, obj/item/fish/mate, obj/structure/aquarium/aquarium)
	if(source.size > (/obj/item/fish/moonfish::average_size * 0.66) && source.size > (/obj/item/fish/moonfish::average_weight * 0.66))
		return FALSE
	if(mate && (mate.size > (/obj/item/fish/moonfish::average_size * 0.7) && mate.size > (/obj/item/fish/moonfish::average_weight * 0.7)))
		return FALSE
	return ..()

/datum/fish_evolution/lavaloop
	probability = 85
	new_fish_type = /obj/item/fish/lavaloop
	required_temperature_min = MIN_AQUARIUM_TEMP + 60

/datum/fish_evolution/plasmaloop
	probability = 85
	new_fish_type = /obj/item/fish/lavaloop/plasma_river
	required_temperature_max = MIN_AQUARIUM_TEMP + 60
