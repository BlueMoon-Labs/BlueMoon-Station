///Обитатели лавы
/obj/item/fish/chasm_crab
	name = "chasm chrab"
	fish_id = "chasm_crab"
	desc = "Разломный краб созревает в подземных водоёмах, поедая всё, что упадёт, пока не сможет выбраться."
	icon_state = "chrab"
	sprite_height = 9
	sprite_width = 8
	stable_population = 4
	feeding_frequency = 10 MINUTES
	random_case_rarity = FISH_RARITY_RARE
	fillet_type = /obj/item/food/meat/slab/rawcrab
	required_temperature_min = MIN_AQUARIUM_TEMP+9
	required_temperature_max = LAVALAND_MAX_TEMPERATURE+50
	min_pressure = HAZARD_LOW_PRESSURE
	safe_air_limits = list(
		/datum/gas/oxygen = list(2, 100),
		/datum/gas/nitrogen,
		/datum/gas/carbon_dioxide = list(0, 20),
		/datum/gas/water_vapor,
		/datum/gas/plasma = list(0, 5),
		/datum/gas/bz = list(0, 5),
		/datum/gas/miasma = list(0, 5),
	)
	evolution_types = list(/datum/fish_evolution/ice_chrab)
	compatible_types = list(/obj/item/fish/chasm_crab/ice)
	beauty = FISH_BEAUTY_GOOD
	favorite_bait = list(/obj/item/fish/lavaloop)
	///насколько краб недоволен жизнью. Чем выше, тем злее получится лобстрозити
	var/anger = 0
	///в какую лобстрозити он созревает
	var/lob_type = /mob/living/basic/mining/lobstrosity/juvenile/lava

/obj/item/fish/chasm_crab/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	RegisterSignal(src, COMSIG_FISH_BEFORE_GROWING, PROC_REF(growth_checks))
	RegisterSignal(src, COMSIG_FISH_FINISH_GROWING, PROC_REF(on_growth))

/obj/item/fish/chasm_crab/get_fish_taste()
	return list("raw crab" = 2)

/obj/item/fish/chasm_crab/get_fish_taste_cooked()
	return list("cooked crab" = 2)

///скорость роста краба зависит от начальных веса и размера, так что крупные дают более шустрых лобстрозити
/obj/item/fish/chasm_crab/update_size_and_weight(new_size = average_size, new_weight = average_weight, update_materials = TRUE)
	. = ..()
	var/multiplier = 1
	switch(size)
		if(0 to FISH_SIZE_TINY_MAX)
			multiplier -= 0.2
		if(FISH_SIZE_SMALL_MAX to FISH_SIZE_NORMAL_MAX)
			multiplier += 0.2
		if(FISH_SIZE_NORMAL_MAX to FISH_SIZE_BULKY_MAX)
			multiplier += 0.5
		if(FISH_SIZE_BULKY_MAX to INFINITY)
			multiplier += 0.8


	if(weight <= (average_weight - 200))
		multiplier -= 0.1 * round((average_weight - weight) / 200)
	else if(weight >= (average_weight + 500))
		multiplier += min(0.1 * round((weight - average_weight) / 500), 2)
	AddComponent(/datum/component/fish_growth, lob_type, 10 MINUTES * multiplier)

/obj/item/fish/chasm_crab/pet_fish(mob/living/user)
	. = ..()
	if(.)
		anger -= min(anger, 6.5)

/obj/item/fish/chasm_crab/proc/growth_checks(datum/source, seconds_per_tick, growth, result_path)
	SIGNAL_HANDLER
	var/hunger = get_hunger()
	if(get_health_percentage() <= 0.6 || hunger >= 0.6) //слишком ранен или голоден, значит не растёт
		anger += growth * 2
		return COMPONENT_DONT_GROW

	if(hunger >= 0.4) //голоден и зол, копится злость
		anger += growth * 0.6

	if(!loc || !HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
		return

	if(HAS_TRAIT(loc, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH)) //в аквариуме размножение и рост отключены
		return COMPONENT_DONT_GROW
	if(!locate(/obj/item/aquarium_prop) in loc) //декора маловато, крабу скучно
		anger += growth * 0.25
	var/fish_count = length(get_aquarium_fishes())
	if(!ISINRANGE(fish_count, 3, AQUARIUM_MAX_BREEDING_POPULATION * 0.5)) //слишком пусто или слишком тесно
		anger += growth * 0.3
	if(fish_count > AQUARIUM_MAX_BREEDING_POPULATION * 0.5) //проверяем, хватит ли места для созревания
		return COMPONENT_DONT_GROW

/obj/item/fish/chasm_crab/proc/on_growth(datum/source, mob/living/basic/mining/lobstrosity/juvenile/result)
	SIGNAL_HANDLER
	if(!result)
		return
	if(!prob(anger))
		result.AddElement(/datum/element/ai_retaliate)

/obj/item/fish/chasm_crab/ice
	name = "arctic chrab"
	fish_id = "arctic_crab"
	desc = "Подвид бездонных крабов, приспособившийся к холоду и отсутствию бездн Ледяной луны."
	icon_state = "arctic_chrab"
	required_temperature_min = ICEBOX_MIN_TEMPERATURE-20
	required_temperature_max = MIN_AQUARIUM_TEMP+15
	evolution_types = list(/datum/fish_evolution/chasm_chrab)
	compatible_types = list(/obj/item/fish/chasm_crab)
	beauty = FISH_BEAUTY_GREAT
	lob_type = /mob/living/basic/mining/lobstrosity/juvenile

/obj/item/fish/boned
	name = "unmarine bonemass"
	fish_id = "bonemass"
	desc = "То, что можно принять за останки рыбы, на самом деле вид, давно отказавшийся от плоти. Живая окаменелость."
	icon_state = "bonemass"
	sprite_width = 10
	sprite_height = 7
	fish_movement_type = /datum/fish_movement/zippy
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	required_fluid_type = AQUARIUM_FLUID_ANY_WATER
	min_pressure = HAZARD_LOW_PRESSURE
	max_integrity = 300
	stable_population = 3
	fillet_type = /obj/item/stack/sheet/bone
	num_fillets = 2
	fish_traits = list(/datum/fish_trait/revival, /datum/fish_trait/carnivore)
	average_size = 70
	average_weight = 2000
	death_text = "%SRC перестает двигаться" //он мёртв, или всё-таки нет
	evolution_types = list(/datum/fish_evolution/mastodon)
	beauty = FISH_BEAUTY_UGLY

/obj/item/fish/boned/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	ADD_TRAIT(src, TRAIT_FISH_MADE_OF_BONE, INNATE_TRAIT)

/obj/item/fish/boned/fish_grind_results()
	return list(/datum/reagent/bone_dust = 10)

/obj/item/fish/boned/make_edible(weight_val)
	return //тут одни кости и ни грамма мяса

/obj/item/fish/boned/get_health_warnings(mob/user, always_deep = FALSE)
	return list(span_deadsay("It's bones."))

/obj/item/fish/boned/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] проглатывает [src] целиком! Похоже, это попытка свести счёты с жизнью!"))
	forceMove(user)
	addtimer(CALLBACK(src, PROC_REF(skeleton_appears), user), 2 SECONDS)
	return MANUAL_SUICIDE_NONLETHAL // шанс выжить

/obj/item/fish/boned/proc/skeleton_appears(mob/living/user)
	user.visible_message(span_warning("[user]'s skin melts off!"), span_boldwarning("Your skin melts off!"))
	user.spawn_gibs()
	user.drop_everything(del_on_drop = FALSE, force = FALSE, del_if_nodrop = FALSE)
	user.set_species(/datum/species/skeleton)
	user.say("AAAAAAAAAAAAHHHHHHHHHH!!!!!!!!!!!!!!", forced = "bone fish suicide")
	if(prob(90))
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, death)), 3 SECONDS)
		user.set_suicide(TRUE)
	qdel(src)

/obj/item/fish/lavaloop
	name = "lavaloop"
	fish_id = "lavaloop"
	desc = "Из-за изогнутой формы его можно использовать как импровизированный бумеранг."
	icon_state = "lava_loop"
	sprite_width = 3
	sprite_height = 5
	average_size = 30
	average_weight = 500
	resistance_flags = FIRE_PROOF | LAVA_PROOF
	required_fluid_type = AQUARIUM_FLUID_ANY_WATER //выживает в лаве и ледяной плазме, значит выживет где угодно
	fish_movement_type = /datum/fish_movement/zippy
	min_pressure = HAZARD_LOW_PRESSURE
	required_temperature_min = MIN_AQUARIUM_TEMP+40
	required_temperature_max = MAX_AQUARIUM_TEMP+900
	fish_traits = list(
		/datum/fish_trait/carnivore,
		/datum/fish_trait/heavy,
	)
	stable_population = 5
	compatible_types = list(/obj/item/fish/lavaloop/plasma_river)
	evolution_types = list(/datum/fish_evolution/plasmaloop)
	hitsound = null
	throwforce = 5
	beauty = FISH_BEAUTY_GOOD
	///максимальный бонус к урону при раскрутке
	var/maximum_bonus = 25

/obj/item/fish/lavaloop/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	add_traits(list(TRAIT_FISHING_BAIT, TRAIT_GOOD_QUALITY_BAIT, TRAIT_BYPASS_RANGED_ARMOR), INNATE_TRAIT)
	AddComponent(/datum/component/boomerang, throw_range, TRUE)
	AddComponent(\
		/datum/component/throwbonus_on_windup,\
		maximum_bonus = maximum_bonus,\
		windup_increment_speed = 2,\
		throw_text = "starts cooking in your hands, it may explode soon!",\
		pass_maximum_callback = CALLBACK(src, PROC_REF(explode_on_user)),\
		apply_bonus_callback = CALLBACK(src, PROC_REF(on_fish_land)),\
		sound_on_success = 'sound/items/weapons/parry.ogg',\
		effect_on_success = /obj/effect/temp_visual/guardian/phase,\
	)
	AddElement(/datum/element/raptor_food, attack_modifier = 1.5, growth_modifier = -0.075)

/obj/item/fish/lavaloop/get_fish_taste()
	return list("chewy fish" = 2)

/obj/item/fish/lavaloop/get_food_types()
	return SEAFOOD|MEAT|GORE //уже прожарено в лаве или плазме

/obj/item/fish/lavaloop/proc/explode_on_user(mob/living/user)
	var/obj/item/bodypart/arm/active_arm = user.get_active_hand()
	active_arm?.dismember()
	to_chat(user, span_warning("[src] explodes!"))
	playsound(src, 'sound/effects/explosion/explosion1.ogg', 40, TRUE)
	user.flash_act(1, 1)
	qdel(src)

/obj/item/fish/lavaloop/proc/on_fish_land(mob/living/target, bonus_value)
	if(!istype(target))
		return FALSE
	return (target.mob_size >= MOB_SIZE_LARGE)

/obj/item/fish/lavaloop/plasma_river
	name = "plasmaloop"
	desc = "Лавалуп, приспособившийся к холодной жидкой плазме. Импровизированный бумеранг."
	fish_id = "plasma_lavaloop"
	icon_state = "plasma_loop"
	dedicated_in_aquarium_icon_state = /obj/item/fish/lavaloop::icon_state + "_small"
	required_temperature_min = MIN_AQUARIUM_TEMP - 100
	required_temperature_max = MIN_AQUARIUM_TEMP+80
	compatible_types = list(/obj/item/fish/lavaloop)
	evolution_types = list(/datum/fish_evolution/lavaloop)
	maximum_bonus = 30

/obj/item/fish/lavaloop/plasma_river/explode_on_user(mob/living/user)
	playsound(src, 'sound/effects/explosion/explosion1.ogg', 40, TRUE)
	user.flash_act(1, 1)
	user.apply_status_effect(/datum/status_effect/ice_block_talisman, 5 SECONDS)
	qdel(src)

/obj/item/fish/lavaloop/plasma_river/on_fish_land(mob/living/target, bonus_value)
	if(!istype(target))
		return FALSE
	if(target.mob_size < MOB_SIZE_LARGE)
		return FALSE
	var/freeze_timer = (bonus_value * 0.1)
	if(freeze_timer <= 0)
		return FALSE
	target.apply_status_effect(/datum/status_effect/ice_block_talisman, freeze_timer SECONDS)
	return FALSE
