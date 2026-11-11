// Черты рыбы. Полный набор из внешнего источника намеренно объявлен здесь,
// но реальное поведение несут только черты, важные для геймплея порта.

GLOBAL_LIST_INIT_TYPED(fish_traits, /datum/fish_trait, init_fish_traits())
GLOBAL_LIST_EMPTY(spontaneous_fish_traits)

/proc/init_fish_traits()
	. = list()
	for(var/path in subtypesof(/datum/fish_trait))
		var/datum/fish_trait/trait = new path()
		.[trait.type] = trait
	. = sortTim(., GLOBAL_PROC_REF(cmp_fish_trait_name), TRUE)

/proc/cmp_fish_trait_name(datum/fish_trait/a, datum/fish_trait/b)
	return sorttext(b.name, a.name)

/datum/fish_trait
	/// Имя для каталога рыб.
	var/name = "Fish trait"
	/// Короткое описание для каталога.
	var/desc = ""
	/// Как часто черта передаётся потомку от родителя.
	var/inheritability = 50
	/// Черты, с которыми эта не уживается.
	var/list/incompatible_traits = list()
	/// Если задано, черта работает только с перечисленными типами рыб.
	var/list/fish_whitelist
	/// Служебные флаги черты.
	var/trait_flags = NONE

/datum/fish_trait/proc/difficulty_mod(datum/fish_source/source, mob/fisherman)
	return 0

/datum/fish_trait/proc/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	return 1

/datum/fish_trait/proc/minigame_mod(obj/item/fishing_rod/rod, mob/fisherman, datum/fishing_challenge/minigame)
	return

/datum/fish_trait/proc/apply_to_fish(obj/item/fish/fish)
	return

/datum/fish_trait/proc/remove_from_fish(obj/item/fish/fish)
	return

/datum/fish_trait/proc/apply_to_mob(mob/living/basic/mob)
	return

/datum/fish_trait/proc/add_reagents(obj/item/fish/fish, list/reagents)
	return

/datum/fish_trait/proc/eat_fish(obj/item/fish/predator, obj/item/fish/prey)
	return

/datum/fish_trait/wary
	name = "Wary"
	desc = "Эта рыба легко пугается, и её труднее поймать."
	inheritability = 40

/datum/fish_trait/wary/difficulty_mod(datum/fish_source/source, mob/fisherman)
	return 5

/datum/fish_trait/shiny_lover
	name = "Shiny lover"
	desc = "Эта рыба любит блестящее и чаще клюёт на блестящие приманки."

/datum/fish_trait/shiny_lover/difficulty_mod(datum/fish_source/source, mob/fisherman)
	return 5

/datum/fish_trait/shiny_lover/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	var/obj/item/fishing_rod/rod = fisherman?.get_active_held_item()
	if(istype(rod) && HAS_TRAIT(rod, TRAIT_ROD_ATTRACT_SHINY_LOVERS))
		return 2
	if(istype(rod) && istype(rod.bait, /obj/item/stack/sheet/mineral/gold))
		return 1.8
	return 1

/datum/fish_trait/picky_eater
	name = "Picky eater"
	desc = "Эта рыба клюёт только на любимую приманку."

/datum/fish_trait/picky_eater/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	var/obj/item/fishing_rod/rod = fisherman?.get_active_held_item()
	if(!istype(rod) || !rod.bait)
		return 0.35
	return 1.4

/datum/fish_trait/nocturnal
	name = "Nocturnal"
	desc = "Эта рыба активнее в темноте."

/datum/fish_trait/nocturnal/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	var/turf/turf = get_turf(location)
	if(turf && turf.get_lumcount() < 0.3)
		return 1.6
	return 0.8

/datum/fish_trait/heavy
	name = "Heavy"
	desc = "Эта рыба плотная и отчаянно сопротивляется."
	inheritability = 35

/datum/fish_trait/heavy/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	return 0.9

/datum/fish_trait/heavy/minigame_mod(obj/item/fishing_rod/rod, mob/fisherman, datum/fishing_challenge/minigame)
	minigame.difficulty += 5
	minigame.completion_loss += 1

/datum/fish_trait/carnivore
	name = "Carnivore"
	desc = "Эта рыба предпочитает мясные приманки."

/datum/fish_trait/carnivore/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	var/obj/item/fishing_rod/rod = fisherman?.get_active_held_item()
	if(istype(rod) && istype(rod.bait, /obj/item/bait))
		return 1.35
	return 1

/datum/fish_trait/vegan
	name = "Herbivore"
	desc = "Эта рыба предпочитает растительные приманки."

/datum/fish_trait/vegan/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	var/obj/item/fishing_rod/rod = fisherman?.get_active_held_item()
	if(istype(rod) && istype(rod.bait, /obj/item/seeds))
		return 1.35
	return 1

/datum/fish_trait/predator
	name = "Predator"
	desc = "Эта рыба ест рыбу поменьше."
	inheritability = 35

/datum/fish_trait/predator/catch_weight_mod(datum/fish_source/source, mob/fisherman, atom/location, obj/item/fish/fish_type)
	return 1.15

/datum/fish_trait/predator/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_EATER, INNATE_TRAIT)

/datum/fish_trait/necrophage
	name = "Necrophage"
	desc = "Эта рыба питается падалью."
	inheritability = 35

/datum/fish_trait/necrophage/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_EATER, INNATE_TRAIT)

/datum/fish_trait/parthenogenesis
	name = "Parthenogenesis"
	desc = "Эта рыба может размножаться без партнёра."
	inheritability = 25

/datum/fish_trait/parthenogenesis/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_SELF_REPRODUCE, INNATE_TRAIT)

/datum/fish_trait/no_mating
	name = "Sterile"
	desc = "Эта рыба не может размножаться."
	inheritability = 70

/datum/fish_trait/no_mating/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_NO_MATING, INNATE_TRAIT)

/datum/fish_trait/recessive
	name = "Recessive"
	desc = "Признаки этой рыбы легко теряются при размножении."
	inheritability = 20

/datum/fish_trait/recessive/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_RECESSIVE, INNATE_TRAIT)

/datum/fish_trait/crossbreeder
	name = "Crossbreeder"
	desc = "Эта рыба может скрещиваться с другими видами."
	inheritability = 55

/datum/fish_trait/crossbreeder/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_CROSSBREEDER, INNATE_TRAIT)

/datum/fish_trait/revival
	name = "Revival"
	desc = "Эта рыба может ожить после готовки или повреждений."
	inheritability = 10

/datum/fish_trait/revival/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_SURVIVE_COOKING, INNATE_TRAIT)

/datum/fish_trait/yucky
	name = "Yucky"
	desc = "Эта рыба отвратительна на вкус."
	inheritability = 60

/datum/fish_trait/yucky/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_YUCKY, INNATE_TRAIT)

/datum/fish_trait/toxic
	name = "Toxic"
	desc = "Эту рыбу опасно есть - она ядовита."
	inheritability = 55

/datum/fish_trait/toxic/add_reagents(obj/item/fish/fish, list/reagents)
	reagents[/datum/reagent/toxin/carpotoxin] = max(reagents[/datum/reagent/toxin/carpotoxin] || 0, 1)

/datum/fish_trait/toxic/carpotoxin
	name = "Carpotoxin"
	desc = "Эта рыба содержит карпотоксин."

/datum/fish_trait/toxin_immunity
	name = "Toxin immunity"
	desc = "Эта рыба невосприимчива к яду."
	inheritability = 30

/datum/fish_trait/toxin_immunity/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_TOXIN_IMMUNE, INNATE_TRAIT)

/datum/fish_trait/territorial
	name = "Territorial"
	desc = "Эта рыба агрессивна к другим рыбам."
	inheritability = 40

/datum/fish_trait/territorial/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_EATER, INNATE_TRAIT)

/datum/fish_trait/lubed
	name = "Lubed"
	desc = "Эта рыба скользкая."
	inheritability = 30

/datum/fish_trait/lubed/difficulty_mod(datum/fish_source/source, mob/fisherman)
	return 3

/datum/fish_trait/amphibious
	name = "Amphibious"
	desc = "Эта рыба может выживать вне воды."
	inheritability = 25

/datum/fish_trait/amphibious/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_AMPHIBIOUS, INNATE_TRAIT)

/datum/fish_trait/antigrav
	name = "Antigravity"
	desc = "Эта рыба двигается странно."

/datum/fish_trait/antigrav/minigame_mod(obj/item/fishing_rod/rod, mob/fisherman, datum/fishing_challenge/minigame)
	minigame.special_effects |= FISHING_MINIGAME_RULE_ANTIGRAV

/datum/fish_trait/antigrav/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_AMPHIBIOUS, INNATE_TRAIT)

/datum/fish_trait/anxiety
	name = "Anxious"
	desc = "Эта рыба легко паникует."
	inheritability = 45

/datum/fish_trait/anxiety/difficulty_mod(datum/fish_source/source, mob/fisherman)
	return 4

/datum/fish_trait/electrogenesis
	name = "Electrogenesis"
	desc = "Эта рыба вырабатывает электричество."
	inheritability = 30

/datum/fish_trait/electrogenesis/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_ELECTROGENESIS, INNATE_TRAIT)

/datum/fish_trait/stinger
	name = "Stinger"
	desc = "У этой рыбы ядовитое жало."
	inheritability = 40

/datum/fish_trait/stinger/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_STINGER, INNATE_TRAIT)

/datum/fish_trait/toxic_barbs
	name = "Toxic barbs"
	desc = "Эта рыба покрыта ядовитыми шипами."
	inheritability = 40

/datum/fish_trait/toxic_barbs/apply_to_fish(obj/item/fish/fish)
	ADD_TRAIT(fish, TRAIT_FISH_STINGER, INNATE_TRAIT)

/datum/fish_trait/hallucinogenic
	name = "Hallucinogenic"
	desc = "Если съесть эту рыбу, могут начаться галлюцинации."

/datum/fish_trait/hallucinogenic/add_reagents(obj/item/fish/fish, list/reagents)
	reagents[/datum/reagent/toxin/mindbreaker] = max(reagents[/datum/reagent/toxin/mindbreaker] || 0, 1)

/datum/fish_trait/stunted
	name = "Stunted"
	desc = "Эта рыба растёт очень медленно."
	inheritability = 30

/datum/fish_trait/mixotroph
	name = "Mixotroph"
	desc = "Эта рыба питается и растениями, и мясом."

/datum/fish_trait/camouflage
	name = "Camouflage"
	desc = "Эту рыбу трудно заметить в воде."

/datum/fish_trait/camouflage/minigame_mod(obj/item/fishing_rod/rod, mob/fisherman, datum/fishing_challenge/minigame)
	minigame.special_effects |= FISHING_MINIGAME_RULE_CAMO

/datum/fish_trait/ink
	name = "Ink"
	desc = "Эта рыба может выпускать чернила."

/datum/fish_trait/emulsijack
	name = "Emulsijack"
	desc = "Эта рыба может эмульгировать реагенты."

/datum/fish_trait/emulsijack/psychic
	name = "Psychic emulsijack"
	desc = "Эта рыба может эмульгировать реагенты силой мысли."
