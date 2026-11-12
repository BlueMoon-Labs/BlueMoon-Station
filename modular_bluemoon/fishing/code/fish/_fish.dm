// Базовый предмет-рыба. Собран из внешней системы рыбалки и подогнан под старые
// API еды и целостности этой кодовой базы. Поля данных при этом сохранены -
// их используют виды рыб, черты, аквариум и мини-игра рыбалки.

#define FISH_SAD 0
#define FISH_VERY_HAPPY 4

#define GET_FISH_ELECTROGENESIS(fish) (fish.electrogenesis_power * fish.size * 0.1)

#define FISH_SUBMERGING_THRESHOLD 100 SECONDS
#define STARVING_FISH_SUBMERGING_THRESHOLD 20 SECONDS

GLOBAL_LIST_INIT(fish_compatible_fluid_types, list(
	AQUARIUM_FLUID_ANY_WATER = list(AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_FRESHWATER, AQUARIUM_FLUID_SULPHWATEVER),
	AQUARIUM_FLUID_ANADROMOUS = list(AQUARIUM_FLUID_SALTWATER, AQUARIUM_FLUID_FRESHWATER),
	AQUARIUM_FLUID_SALTWATER = list(AQUARIUM_FLUID_SALTWATER),
	AQUARIUM_FLUID_FRESHWATER = list(AQUARIUM_FLUID_FRESHWATER),
	AQUARIUM_FLUID_SULPHWATEVER = list(AQUARIUM_FLUID_SULPHWATEVER),
	AQUARIUM_FLUID_AIR = list(AQUARIUM_FLUID_AIR),
))

/obj/item/fish
	name = "fish"
	desc = "очень пресная."
	parent_type = /obj/item/reagent_containers/food/snacks
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/fish.dmi'
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_righthand.dmi'
	force = 6
	throwforce = 6
	throw_range = 8
	attack_verb_continuous = list("slaps", "whacks")
	attack_verb_simple = list("slap", "whack")
	hitsound = SFX_DEFAULT_FISH_SLAP
	drop_sound = 'modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_drop1.ogg'
	pickup_sound = SFX_FISH_PICKUP
	sound_vary = TRUE
	obj_flags = UNIQUE_RENAME

	max_integrity = 200
	integrity_failure = 0.5

	/// Флаги для переменных рыбы, которым иначе хватило бы TRUE/FALSE
	var/fish_flags = FISH_FLAG_SHOW_IN_CATALOG|FISH_DO_FLOP_ANIM|FISH_FLAG_EXPERIMENT_SCANNABLE
	/// Таймер, который крутит повторяющийся звук трепыхания.
	var/flopping_sound_timer

	/// Ширина иконки рыбы в аквариуме
	var/sprite_width = 3
	/// Высота иконки рыбы в аквариуме
	var/sprite_height = 3
	/// Кэш смещения по горизонтали и вертикали внутри аквариума. Нужен, чтобы рыба не прыгала при обновлении иконки.
	var/aquarium_pixel_x
	var/aquarium_pixel_y
	/// Старые флаги каталога, на которые опираются данные рыб L Corp.
	var/show_in_catalog = TRUE

	/// Этот файл иконки пойдёт на визуал рыбы в аквариуме
	var/dedicated_in_aquarium_icon
	/// icon_state для визуала рыбы в аквариуме.
	var/dedicated_in_aquarium_icon_state

	/// Если задан, рыба в аквариуме будет такого цвета
	var/aquarium_vc_color

	/// Какая жидкость нужна рыбе для жизни.
	var/required_fluid_type = AQUARIUM_FLUID_FRESHWATER
	/// Минимальная температура, при которой рыба живёт.
	var/required_temperature_min = MIN_AQUARIUM_TEMP
	/// Максимальная температура, которую рыба ещё терпит.
	var/required_temperature_max = MAX_AQUARIUM_TEMP

	/// Какой реагент рыба считает едой.
	var/datum/reagent/food = /datum/reagent/consumable/nutriment
	/// Как часто рыбу положено кормить
	var/feeding_frequency = 5 MINUTES
	/// Когда рыбу кормили в последний раз
	var/last_feeding

	/// Текущее состояние рыбы
	var/status = FISH_ALIVE
	/// Иконка для мёртвой рыбы, если она задана.
	var/icon_state_dead

	/// Сообщение, которое прозвучит при смерти рыбы.
	var/death_text = "%SRC dies."

	/// Насколько редко рыба попадается в случайных случаях
	var/random_case_rarity = FISH_RARITY_BASIC

	/// Из рыбы, созданной этим поведением, выйдет вот такое филе
	var/fillet_type = /obj/item/food/fishmeat
	/// Сколько филе выходит с рыбы. Зависит от размера.
	var/num_fillets = 2

	/// Дальше этого количества в одном аквариуме рыба не размножается.
	var/stable_population = 1
	/// Отсечка времени до появления новой рыбы
	var/breeding_wait
	/// Сколько времени уходит на создание новой рыбы
	var/breeding_timeout = 2 MINUTES
	/// Если задано, рыба может скрещиваться ещё и с этими типами
	var/list/compatible_types
	/// Если задано, при размножении появятся эти типы рыб, а не 'type'
	var/list/spawn_types
	/// Возможные эволюции. Если условия сойдутся, потомство может оказаться рыбой нового типа.
	var/list/evolution_types

	// Всё, что связано с рыбалкой

	/**
	 * Список типов черт рыбы. Они могут менять вероятность и сложность в зависимости от удочки и рыбака,
	 * а ещё задают поведение рыбы и кое-какие её качества.
	 */
	var/list/fish_traits = list()

	/// Путь к датуму, который ведёт рыбу в мини-игре рыбалки
	var/fish_movement_type = /datum/fish_movement

	/// Базовый модификатор сложности рыбалки, просто прибавка
	var/fishing_difficulty_modifier = 0

	/// Приманки, которые рыбе нравятся. Облегчают и повышают шанс поимки
	var/list/favorite_bait = list()

	/// Приманки, которые рыбе не по вкусу. Мешают и снижают шанс поимки
	var/list/disliked_bait = list()

	/// Размер в сантиметрах.
	var/size
	/// Средний размер рыбы этого типа в сантиметрах.
	var/average_size = 50
	/// Сюда временно кладётся новый размер из randomize_size_and_weight().
	var/temp_size
	/// Предельный размер, до которого эта рыба может вырасти.
	var/maximum_size

	/// Вес в 'килокламах'.
	var/weight
	/// Средний вес рыбы этого типа в 'килокламах'
	var/average_weight = 1000
	/// Сюда временно кладётся новый вес рыбы.
	var/temp_weight
	/// Предельный вес, до которого эта рыба может отъесться.
	var/maximum_weight
	/// Держит текущую суммарную прибавку к весу от материалов.
	material_flags = MATERIAL_COLOR | MATERIAL_ADD_PREFIX

	/// Насколько в дикой природе вес и размер гуляют от среднего
	var/weight_size_deviation = 0.2

	/// Вне аквариума по этим газам проверяется, безопасна ли среда.
	var/list/safe_air_limits = list(
		/datum/gas/oxygen = list(12, 100),
		/datum/gas/nitrogen,
		/datum/gas/carbon_dioxide = list(0, 10),
		/datum/gas/water_vapor,
	)
	/// Вне аквариума давление должно попадать между этими двумя числами, иначе среда небезопасна.
	var/min_pressure = WARNING_LOW_PRESSURE
	var/max_pressure = HAZARD_HIGH_PRESSURE

	/// Откат между электрическими разрядами
	COOLDOWN_DECLARE(electrogenesis_cooldown)
	/// Мощность разряда рыбы в биоэлектрическом генераторе. Растёт с размером.
	var/electrogenesis_power = 2 MEGA JOULES

	/// Красота, которую рыба добавляет аквариуму или трофею, куда её сунули.
	var/beauty = FISH_BEAUTY_GENERIC

	/// Для трофеев. Здесь имя того, кто сделал трофей.
	var/catcher_name
	/// Для трофеев. Здесь дата, когда трофей сделали впервые
	var/catch_date

	/// Сколько раз от рыбы уже откусили.
	var/bites_amount = 0

	/**
	 * Идентификатор рыбы, по нему между раундами считается прогресс пойманного.
	 * Нужен только рыбе, которую можно поймать. Поставили один раз и не меняем.
	 */
	var/fish_id
	/// Перенаправляет на другой путь рыбы, чтобы поимка открывала запись именно его.
	var/obj/item/fish/fish_id_redirect_path
	/// Только для самоубийства, ради комического эффекта
	var/suicide_slap_text = "*SLAP!*"

	var/time_passed_on_safe_turf = 0

	// Поля, через которые рыба дружит с современной едой. Их ждут перенесённые файлы видов.
	var/list/food_reagents = list()
	var/foodtypes = SEAFOOD|MEAT|RAW|GORE
	var/bite_consumption = 2
	var/microwaved_type = /obj/item/food/cooked_fish
	var/list/remove_reagents_on_cooked
	var/starting_reagent_purity = 1
	var/crafting_complexity = FOOD_COMPLEXITY_1

/obj/item/fish/Initialize(mapload, apply_qualities = TRUE)
	. = ..()
	base_icon_state = icon_state
	obj_integrity = max_integrity
	if(!show_in_catalog)
		fish_flags &= ~FISH_FLAG_SHOW_IN_CATALOG
	if(status != FISH_DEAD)
		ADD_TRAIT(src, TRAIT_UNCOMPOSTABLE, REF(src))
		START_PROCESSING(SSobj, src)

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_FISH_STASIS), PROC_REF(enter_stasis))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_FISH_STASIS), PROC_REF(exit_stasis))
	add_traits(list(TRAIT_DUCT_TAPE_UNREPAIRABLE, TRAIT_VALID_DNA_INFUSION), INNATE_TRAIT)

	breeding_wait = world.time + (breeding_timeout * NEW_FISH_BREEDING_TIMEOUT_MULT)
	last_feeding = world.time - (feeding_frequency * NEW_FISH_LAST_FEEDING_MULT)

	if(loc && HAS_TRAIT(loc, TRAIT_FISH_SAFE_STORAGE))
		ADD_TRAIT(src, TRAIT_FISH_STASIS, REF(src))
	if(apply_qualities)
		apply_traits()
		update_size_and_weight()

/obj/item/fish/proc/get_fish_taste()
	return list("raw fish" = 2.5, "scales" = 1)

/obj/item/fish/proc/get_fish_taste_cooked()
	return list("cooked fish" = 2)

/obj/item/fish/proc/get_base_edible_reagents_to_add()
	var/return_list = list(
		/datum/reagent/consumable/nutriment/protein = 2,
		/datum/reagent/blood = 1,
	)
	if(required_fluid_type == AQUARIUM_FLUID_SALTWATER)
		return_list[/datum/reagent/consumable/salt] = 0.4
	return return_list

/// Набивает контейнер реагентов старого образца, но сами реагенты берёт из современной генерации рыбы.
/obj/item/fish/proc/generate_fish_reagents(multiplier = 1)
	var/list/reagents_to_add = get_base_edible_reagents_to_add()
	SEND_SIGNAL(src, COMSIG_GENERATE_REAGENTS_TO_ADD, reagents_to_add)
	for(var/fish_trait_type in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait_type]
		trait?.add_reagents(src, reagents_to_add)
	if(multiplier != 1)
		for(var/reagent in reagents_to_add)
			reagents_to_add[reagent] *= multiplier
	if(!reagents)
		create_reagents(INFINITY, INJECTABLE)
	reagents.add_reagent_list(reagents_to_add)
	var/datum/reagent/consumable/nutriment/protein/protein = reagents.has_reagent(/datum/reagent/consumable/nutriment/protein)
	if(protein)
		protein.data = HAS_TRAIT(src, TRAIT_FISH_WELL_COOKED) ? get_fish_taste_cooked() : get_fish_taste()

/obj/item/fish/proc/refresh_edibility()
	if(!reagents)
		create_reagents(INFINITY, INJECTABLE)
	reagents.clear_reagents()
	generate_fish_reagents()
	reagents.maximum_volume = max(round(reagents.total_volume * 1.25, 1), 1)
	var/bites_to_finish = max(weight / FISH_WEIGHT_BITE_DIVISOR, 1)
	bitesize = max(round(reagents.total_volume / bites_to_finish, 0.1), 0.5)
	tastes = HAS_TRAIT(src, TRAIT_FISH_WELL_COOKED) ? get_fish_taste_cooked() : get_fish_taste()
	foodtype = foodtypes
	list_reagents = null

/obj/item/fish/proc/get_hunger(cap = FISH_STARVING_THRESHOLD)
	. = clamp((world.time - last_feeding) / feeding_frequency, 0, cap)
	if(HAS_TRAIT(src, TRAIT_FISH_NO_HUNGER))
		return min(., FISH_STARVING_THRESHOLD * 0.2)

/obj/item/fish/proc/get_starvation_mult()
	var/hunger = get_hunger(cap = FISH_STARVING_THRESHOLD * 2)
	return hunger >= FISH_STARVING_THRESHOLD ? hunger : 0

/obj/item/fish/proc/feed(datum/reagents/fed_reagents)
	if(status != FISH_ALIVE)
		return
	var/was_hungry = get_hunger()
	for(var/datum/reagent/reagent as anything in fed_reagents.reagent_list)
		if(!fed_reagents.has_reagent(reagent.type, 0.1) || !reagent.used_on_fish(src))
			continue
		fed_reagents.remove_reagent(reagent.type, 0.1)
		if(reagent.type == food)
			sate_hunger()
			return
	if(was_hungry && !get_hunger())
		return
	if(fed_reagents.remove_reagent(food, 0.1))
		sate_hunger()
		return
	var/datum/reagent/wrong_reagent = pick(fed_reagents.reagent_list)
	if(wrong_reagent)
		fed_reagents.remove_reagent(wrong_reagent.type, 0.1)

/obj/item/fish/proc/sate_hunger()
	if(HAS_TRAIT(loc, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH))
		last_feeding = world.time
		return
	var/hunger = get_hunger()
	last_feeding = world.time
	if(hunger < 0.05)
		return
	var/new_size = size
	var/new_weight = weight
	var/hunger_mult
	if(hunger <= FISH_GROWTH_PEAK)
		hunger_mult = hunger / FISH_GROWTH_PEAK
	else
		hunger_mult = 1 - (hunger - FISH_GROWTH_PEAK) * 4
		if(hunger_mult <= 0)
			return
	var/base_mult = FISH_GROWTH_MULT
	if(HAS_TRAIT(src, TRAIT_FISH_QUICK_GROWTH))
		base_mult *= 2.5
	if(size < maximum_size)
		new_size += CEILING((maximum_size - size) * base_mult / (w_class * FISH_SIZE_WEIGHT_GROWTH_MALUS) * hunger_mult, 1)
		new_size = min(new_size, maximum_size)
	if(weight < maximum_weight)
		new_weight += CEILING((maximum_weight - weight) * base_mult / (GET_FISH_WEIGHT_RANK(weight) * FISH_SIZE_WEIGHT_GROWTH_MALUS) * hunger_mult, 1)
		new_weight = min(new_weight, maximum_weight)
	if(new_size != size || new_weight != weight)
		update_size_and_weight(new_size, new_weight)

/obj/item/fish/proc/randomize_size_and_weight(base_size = average_size, base_weight = average_weight, deviation = weight_size_deviation, update = TRUE)
	var/size_deviation = 0.2 * base_size
	temp_size = round(clamp(gaussian(base_size, size_deviation), average_size / MAX_FISH_DEVIATION_COEFF, average_size * MAX_FISH_DEVIATION_COEFF))
	var/weight_deviation = 0.2 * base_weight
	temp_weight = round(clamp(gaussian(base_weight, weight_deviation), average_weight / MAX_FISH_DEVIATION_COEFF, average_weight * MAX_FISH_DEVIATION_COEFF))
	set_max_size_and_weight(temp_size, temp_weight)
	if(update)
		update_size_and_weight(temp_size, temp_weight)

/obj/item/fish/proc/set_max_size_and_weight(base_size, base_weight)
	if(!maximum_size)
		maximum_size = min(base_size * 2, average_size * MAX_FISH_DEVIATION_COEFF)
	if(!maximum_weight)
		maximum_weight = min(base_weight * 2, average_weight * MAX_FISH_DEVIATION_COEFF)

/obj/item/fish/proc/update_size_and_weight(new_size = average_size, new_weight = average_weight)
	fish_flags |= FISH_FLAG_UPDATING_SIZE_AND_WEIGHT
	SEND_SIGNAL(src, COMSIG_FISH_UPDATE_SIZE_AND_WEIGHT, new_size, new_weight)
	if(!isnull(size))
		remove_fillet_type()
	else
		set_max_size_and_weight(new_size, new_weight)
	size = new_size
	switch(size)
		if(0 to FISH_SIZE_TINY_MAX)
			w_class = WEIGHT_CLASS_TINY
		if(FISH_SIZE_TINY_MAX to FISH_SIZE_SMALL_MAX)
			w_class = WEIGHT_CLASS_SMALL
		if(FISH_SIZE_SMALL_MAX to FISH_SIZE_NORMAL_MAX)
			w_class = WEIGHT_CLASS_NORMAL
		if(FISH_SIZE_NORMAL_MAX to FISH_SIZE_BULKY_MAX)
			w_class = WEIGHT_CLASS_BULKY
		if(FISH_SIZE_BULKY_MAX to FISH_SIZE_HUGE_MAX)
			w_class = WEIGHT_CLASS_HUGE
		if(FISH_SIZE_HUGE_MAX to INFINITY)
			w_class = WEIGHT_CLASS_GIGANTIC
	update_holding_state()
	add_fillet_type()
	weight = new_weight
	if(weight >= FISH_WEIGHT_SLOWDOWN && !HAS_TRAIT(src, TRAIT_SPEED_POTIONED))
		slowdown = GET_FISH_SLOWDOWN(weight)
		drag_slowdown = round(slowdown * 0.5, 1)
	else
		slowdown = 0
		drag_slowdown = 0
	refresh_edibility()
	update_fish_force()
	fish_flags &= ~FISH_FLAG_UPDATING_SIZE_AND_WEIGHT

/// Подбирает состояние спрайта в руках под размер рыбы и её видовые особенности.
/obj/item/fish/proc/get_inhand_state()
	var/state = inhand_icon_state
	if(!state)
		switch(size)
			if(0 to FISH_SIZE_SMALL_MAX)
				state = "fish_small"
			if(FISH_SIZE_SMALL_MAX to FISH_SIZE_NORMAL_MAX)
				state = "fish_normal"
			if(FISH_SIZE_NORMAL_MAX to FISH_SIZE_BULKY_MAX)
				state = "fish_bulky"
			else
				state = "fish_huge"
	var/two_handed = !isnull(size) && (size > FISH_SIZE_TWO_HANDS_REQUIRED || (HAS_TRAIT(src, TRAIT_FISH_SHOULD_TWOHANDED) && w_class >= WEIGHT_CLASS_BULKY))
	if(two_handed)
		state = "[state]_wielded"
	return state

/// Синхронизирует item_state и двуручное удержание с текущим размером рыбы.
/obj/item/fish/proc/update_holding_state()
	item_state = get_inhand_state()
	var/two_handed = !isnull(size) && (size > FISH_SIZE_TWO_HANDS_REQUIRED || (HAS_TRAIT(src, TRAIT_FISH_SHOULD_TWOHANDED) && w_class >= WEIGHT_CLASS_BULKY))
	if(two_handed)
		if(!GetComponent(/datum/component/two_handed))
			AddComponent(/datum/component/two_handed, require_twohands = TRUE)
	else
		qdel(GetComponent(/datum/component/two_handed))
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_inv_hands()

/obj/item/fish/proc/remove_fillet_type()
	if(!fillet_type)
		return
	var/amount = max(round(num_fillets * size / FISH_FILLET_NUMBER_SIZE_DIVISOR, 1), 1)
	var/time = 0.5 SECONDS * amount
	RemoveElement(/datum/element/processable, TOOL_KNIFE, fillet_type, amount, time, screentip_verb = "Cut")

/obj/item/fish/proc/add_fillet_type()
	if(!fillet_type)
		return
	var/amount = max(round(num_fillets * size / FISH_FILLET_NUMBER_SIZE_DIVISOR, 1), 1)
	var/time = 0.5 SECONDS * amount
	AddElement(/datum/element/processable, TOOL_KNIFE, fillet_type, amount, time, screentip_verb = "Cut")

/obj/item/fish/proc/update_fish_force()
	if(force >= 15 && hitsound == SFX_ALT_FISH_SLAP)
		hitsound = SFX_DEFAULT_FISH_SLAP
	force = initial(force)
	throwforce = initial(throwforce)
	throw_range = initial(throw_range)
	demolition_mod = initial(demolition_mod)
	attack_verb_continuous = initial(attack_verb_continuous)
	attack_verb_simple = initial(attack_verb_simple)
	hitsound = initial(hitsound)
	damtype = initial(damtype)
	attack_speed = initial(attack_speed)
	block_chance = initial(block_chance)
	armour_penetration = initial(armour_penetration)
	wound_bonus = initial(wound_bonus)
	exposed_wound_bonus = initial(exposed_wound_bonus)
	toolspeed = initial(toolspeed)
	var/weight_rank = GET_FISH_WEIGHT_RANK(weight)
	throw_range -= weight_rank
	get_force_rank()
	var/bonus_malus = weight_rank - w_class
	if(bonus_malus)
		calculate_fish_force_bonus(bonus_malus)
	SEND_SIGNAL(src, COMSIG_FISH_FORCE_UPDATED, weight_rank, bonus_malus)
	throwforce = force
	if(force >= 15 && hitsound == SFX_DEFAULT_FISH_SLAP)
		hitsound = SFX_ALT_FISH_SLAP

/obj/item/fish/proc/calculate_fish_force_bonus(bonus_malus)
	demolition_mod += bonus_malus * 0.1
	attack_speed += bonus_malus * 0.1
	force = round(force * (1 + bonus_malus * 0.1), 0.1)

/obj/item/fish/proc/get_force_rank()
	switch(w_class)
		if(WEIGHT_CLASS_TINY)
			force -= 3
			attack_speed -= 0.1 SECONDS
		if(WEIGHT_CLASS_NORMAL)
			force += 2
		if(WEIGHT_CLASS_BULKY)
			force += 5
			attack_speed += 0.1 SECONDS
		if(WEIGHT_CLASS_HUGE)
			force += 9
			attack_speed += 0.2 SECONDS
			demolition_mod += 0.2
		if(WEIGHT_CLASS_GIGANTIC)
			force += 13
			attack_speed += 0.4 SECONDS
			demolition_mod += 0.4

/obj/item/fish/proc/inherit_traits(list/x_traits, list/y_traits, list/fixed_traits, list/removed_traits)
	fish_traits = fixed_traits?.Copy() || list()
	var/list/same_traits = x_traits & y_traits
	var/list/all_traits = (y_traits ? (x_traits|y_traits) : x_traits) - removed_traits
	var/list/incompatible_traits = list()
	var/list/potential_spontaneous_traits = GLOB.spontaneous_fish_traits[type]
	for(var/trait_type in potential_spontaneous_traits)
		if(!prob(potential_spontaneous_traits[trait_type]))
			continue
		var/datum/fish_trait/trait = GLOB.fish_traits[trait_type]
		if(length(fish_traits & trait.incompatible_traits))
			continue
		fish_traits |= trait_type
		incompatible_traits |= trait.incompatible_traits
	for(var/trait_type in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[trait_type]
		incompatible_traits |= trait.incompatible_traits
	for(var/trait_type in shuffle(all_traits))
		if((trait_type in fish_traits) || (trait_type in incompatible_traits))
			continue
		var/datum/fish_trait/trait = GLOB.fish_traits[trait_type]
		if(isnull(trait))
			continue
		if(!isnull(trait.fish_whitelist) && !(type in trait.fish_whitelist))
			continue
		if(length(fish_traits & trait.incompatible_traits))
			continue
		if(!y_traits || (trait_type in same_traits) || prob(trait.inheritability))
			fish_traits |= trait_type
			incompatible_traits |= trait.incompatible_traits
	apply_traits()

/obj/item/fish/proc/apply_traits()
	for(var/fish_trait_type in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait_type]
		trait?.apply_to_fish(src)

/obj/item/fish/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(loc && HAS_TRAIT(loc, TRAIT_FISH_SAFE_STORAGE))
		ADD_TRAIT(src, TRAIT_FISH_STASIS, REF(src))
	else
		REMOVE_TRAIT(src, TRAIT_FISH_STASIS, REF(src))
	check_flopping()

/obj/item/fish/proc/enter_stasis(datum/source)
	SIGNAL_HANDLER
	stop_flopping()
	update_appearance()
	STOP_PROCESSING(SSobj, src)

/obj/item/fish/proc/exit_stasis(datum/source)
	SIGNAL_HANDLER
	if(status == FISH_DEAD)
		return
	START_PROCESSING(SSobj, src)
	check_flopping()

/obj/item/fish/proc/check_flopping()
	if(QDELETED(src))
		return
	if(!(fish_flags & FISH_DO_FLOP_ANIM))
		return
	var/should_be_flopping = status == FISH_ALIVE && (loc && !HAS_TRAIT(loc, TRAIT_STOP_FISH_FLOPPING))
	if(should_be_flopping)
		start_flopping()
	else
		stop_flopping()

/obj/item/fish/proc/start_flopping()
	if(HAS_TRAIT(src, TRAIT_FISH_FLOPPING))
		return
	ADD_TRAIT(src, TRAIT_FISH_FLOPPING, TRAIT_GENERIC)
	flop_animation()
	flopping_sound_loop()

/obj/item/fish/proc/stop_flopping()
	if(HAS_TRAIT(src, TRAIT_FISH_FLOPPING))
		REMOVE_TRAIT(src, TRAIT_FISH_FLOPPING, TRAIT_GENERIC)
		animate(src, transform = matrix())
	if(flopping_sound_timer && flopping_sound_timer != -1)
		deltimer(flopping_sound_timer)
		flopping_sound_timer = null

/// Крутит звук падения, пока рыба не перестанет трепыхаться.
/obj/item/fish/proc/flopping_sound_loop()
	if(QDELETED(src) || !HAS_TRAIT(src, TRAIT_FISH_FLOPPING))
		return
	if(drop_sound)
		playsound(src, drop_sound, 30, TRUE, -1)
	flopping_sound_timer = addtimer(CALLBACK(src, PROC_REF(flopping_sound_loop)), rand(20, 35), TIMER_STOPPABLE)

#define PAUSE_BETWEEN_PHASES 15
#define PAUSE_BETWEEN_FLOPS 2
#define FLOP_COUNT 2
#define FLOP_DEGREE 20
#define FLOP_SINGLE_MOVE_TIME 1.5
#define JUMP_X_DISTANCE 5
#define JUMP_Y_DISTANCE 6

/obj/item/fish/proc/flop_animation()
	var/pause_between = PAUSE_BETWEEN_PHASES + rand(1, 5)
	animate(src, time = pause_between, loop = -1)
	for(var/_ in 1 to FLOP_COUNT)
		var/matrix/up_matrix = matrix()
		up_matrix.Turn(FLOP_DEGREE)
		var/matrix/down_matrix = matrix()
		down_matrix.Turn(-FLOP_DEGREE)
		animate(transform = down_matrix, time = FLOP_SINGLE_MOVE_TIME, loop = -1)
		animate(transform = up_matrix, time = FLOP_SINGLE_MOVE_TIME, loop = -1)
		animate(transform = matrix(), time = FLOP_SINGLE_MOVE_TIME, loop = -1, easing = BOUNCE_EASING | EASE_IN)
		animate(time = PAUSE_BETWEEN_FLOPS, loop = -1)
	animate(time = pause_between, loop = -1, flags = ANIMATION_PARALLEL)
	var/jumping_right = FALSE
	var/up_time = 3 * FLOP_SINGLE_MOVE_TIME / 2
	for(var/_ in 1 to FLOP_COUNT)
		jumping_right = !jumping_right
		var/x_step = jumping_right ? JUMP_X_DISTANCE/2 : -JUMP_X_DISTANCE/2
		animate(time = up_time, pixel_y = JUMP_Y_DISTANCE, pixel_x = x_step, loop = -1, flags = ANIMATION_RELATIVE, easing = BOUNCE_EASING | EASE_IN)
		animate(time = up_time, pixel_y = -JUMP_Y_DISTANCE, pixel_x = x_step, loop = -1, flags = ANIMATION_RELATIVE, easing = BOUNCE_EASING | EASE_OUT)
		animate(time = PAUSE_BETWEEN_FLOPS, loop = -1)

#undef PAUSE_BETWEEN_PHASES
#undef PAUSE_BETWEEN_FLOPS
#undef FLOP_COUNT
#undef FLOP_DEGREE
#undef FLOP_SINGLE_MOVE_TIME
#undef JUMP_X_DISTANCE
#undef JUMP_Y_DISTANCE

/obj/item/fish/process(seconds_per_tick)
	if(HAS_TRAIT(src, TRAIT_FISH_STASIS) || status != FISH_ALIVE)
		return
	do_fish_process(seconds_per_tick)
	if(status != FISH_ALIVE || !loc || !isturf(loc))
		return
	time_passed_on_safe_turf += seconds_per_tick SECONDS
	if(time_passed_on_safe_turf >= (get_starvation_mult() ? STARVING_FISH_SUBMERGING_THRESHOLD : FISH_SUBMERGING_THRESHOLD))
		released(loc)

/obj/item/fish/proc/do_fish_process(seconds_per_tick)
	if(loc && HAS_TRAIT(loc, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH))
		last_feeding += seconds_per_tick SECONDS
		breeding_wait += seconds_per_tick SECONDS
	else
		process_health(seconds_per_tick)
		if(ready_to_reproduce())
			try_to_reproduce()
		if(HAS_TRAIT(src, TRAIT_FISH_ELECTROGENESIS) && COOLDOWN_FINISHED(src, electrogenesis_cooldown))
			try_electrogenesis()
	SEND_SIGNAL(src, COMSIG_FISH_LIFE, seconds_per_tick)

/obj/item/fish/proc/set_status(new_status, silent = FALSE)
	if(status == new_status)
		return
	switch(new_status)
		if(FISH_ALIVE)
			status = FISH_ALIVE
			obj_integrity = max_integrity
			regenerate_bites(bites_amount)
			last_feeding = world.time
			check_flopping()
			START_PROCESSING(SSobj, src)
			ADD_TRAIT(src, TRAIT_UNCOMPOSTABLE, INNATE_TRAIT)
		if(FISH_DEAD)
			status = FISH_DEAD
			STOP_PROCESSING(SSobj, src)
			REMOVE_TRAIT(src, TRAIT_UNCOMPOSTABLE, INNATE_TRAIT)
			stop_flopping()
			if(!silent)
				var/message = span_warning(replacetext(death_text, "%SRC", "[src]"))
				if(loc && HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
					loc.visible_message(message)
				else
					visible_message(message)
	update_appearance()
	update_fish_force()
	SEND_SIGNAL(src, COMSIG_FISH_STATUS_CHANGED)

/obj/item/fish/proc/proper_environment(temp_range_min = required_temperature_min, temp_range_max = required_temperature_max)
	if(!loc)
		return TRUE
	if(HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
		// Эволюция и рост могут передать диапазон уже, чем у самой рыбы.
		var/obj/structure/aquarium/tank = loc
		if(istype(tank) && (temp_range_min > required_temperature_min || temp_range_max < required_temperature_max))
			if(!ISINRANGE(tank.fluid_temp, temp_range_min, temp_range_max))
				return FALSE
		return (fish_flags & FISH_FLAG_SAFE_TEMPERATURE) && (fish_flags & FISH_FLAG_SAFE_FLUID)
	if(istype(loc, /turf/open/water))
		return TRUE
	if(istype(loc, /obj/effect/abstract/liquid_turf))
		return TRUE
	if(isturf(loc))
		var/turf/turf = loc
		if(turf.liquids)
			var/obj/effect/abstract/liquid_turf/liquid = turf.liquids
			if(liquid?.total_reagents && liquid.reagent_list[/datum/reagent/water])
				return TRUE
	if(required_fluid_type == AQUARIUM_FLUID_AIR || HAS_TRAIT(src, TRAIT_FISH_AMPHIBIOUS))
		return TRUE
	return FALSE

/obj/item/fish/proc/process_health(seconds_per_tick)
	var/health_change = 0
	if(!proper_environment())
		health_change -= 2.5
	var/starvation_mult = get_starvation_mult()
	if(starvation_mult)
		health_change -= 0.25 * starvation_mult
	else
		health_change += 0.5
	if(!health_change)
		return
	health_change *= seconds_per_tick
	if(health_change < 0)
		damage_fish(-health_change)
	else
		repair_fish_damage(health_change)

/obj/item/fish/proc/damage_fish(amount)
	if(status == FISH_DEAD || amount <= 0)
		return
	obj_integrity = max(obj_integrity - amount, max_integrity * integrity_failure)
	if(obj_integrity <= max_integrity * integrity_failure)
		set_status(FISH_DEAD)

/obj/item/fish/proc/repair_fish_damage(amount)
	obj_integrity = min(obj_integrity + amount, max_integrity)

/obj/item/fish/proc/fish_grind_results()
	return list()

/obj/item/fish/proc/get_food_types()
	return foodtypes

/obj/item/fish/proc/objectify()
	return src

/obj/item/fish/proc/flinch_on_eat(mob/living/eater, mob/living/feeder)
	return

/obj/item/fish/suicide_act(mob/living/user)
	if(!force)
		user.visible_message(span_suicide("[user] шлёпает себя [src], но ничего не происходит!"))
		return SHAME
	user.visible_message(span_suicide("[user] начинает быстро шлёпать себя [src]! Похоже, это попытка свести счёты с жизнью!"))
	slapperoni(user)
	if(user.stat == DEAD)
		return MANUAL_SUICIDE
	user.visible_message(span_suicide("[user] шлёпает себя [src], но в последний момент передумывает!"))
	return SHAME

/obj/item/fish/proc/slapperoni(mob/living/user, iteration = 1)
	if(QDELETED(src) || QDELETED(user) || iteration > 100)
		return
	if(user.stat > SOFT_CRIT)
		user.gib(drop_items = TRUE)
		return
	stoplag(0.1 SECONDS)
	user.visible_message(span_bolddanger(suicide_slap_text))
	user.attackby(src, user)
	slapperoni(user, iteration + 1)

/obj/item/fish/proc/persistence_save(list/data)
	return

/obj/item/fish/proc/persistence_load(list/data)
	return

/obj/item/fish/proc/get_aquarium_beauty()
	var/actual_beauty = beauty
	if(status == FISH_DEAD)
		actual_beauty = clamp(beauty - 500, -600, -200)
	return actual_beauty

/obj/item/fish/proc/get_integrity()
	return obj_integrity

/obj/item/fish/proc/get_health_percentage()
	var/max_health = max_integrity * (1 - integrity_failure)
	var/death_thres = max_integrity - max_health
	return CLAMP01((obj_integrity - death_thres) / max_health)

/obj/item/fish/proc/regenerate_bites(amount)
	amount = min(amount, bites_amount)
	if(amount <= 0)
		return
	bites_amount -= amount
	refresh_edibility()

/obj/item/fish/proc/get_aquarium_fishes(shuffle = FALSE, blacklist)
	. = list()
	for(var/obj/item/fish/fish in loc)
		. += fish
	. -= blacklist
	if(shuffle)
		. = shuffle(.)
	return .

/obj/item/fish/proc/ready_to_reproduce(being_targeted = FALSE)
	if(!loc || !HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
		return FALSE
	if(istype(loc, /obj/structure/aquarium))
		var/obj/structure/aquarium/tank = loc
		if(!tank.allow_breeding)
			return FALSE
	if(being_targeted && HAS_TRAIT(src, TRAIT_FISH_NO_MATING))
		return FALSE
	if(!being_targeted && length(get_aquarium_fishes()) >= AQUARIUM_MAX_BREEDING_POPULATION)
		return FALSE
	return !HAS_TRAIT(loc, TRAIT_STOP_FISH_REPRODUCTION_AND_GROWTH) && get_health_percentage() >= 0.8 && world.time >= breeding_wait

/obj/item/fish/proc/try_to_reproduce()
	if(!loc || !HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
		return FALSE
	var/obj/item/fish/second_fish
	if(!HAS_TRAIT(src, TRAIT_FISH_NO_MATING))
		var/list/available_fishes = list()
		SEND_SIGNAL(loc, COMSIG_AQUARIUM_GET_REPRODUCTION_CANDIDATES, src, available_fishes)
		available_fishes -= src
		if(length(available_fishes))
			available_fishes = shuffle(available_fishes)
			for(var/obj/item/fish/other_fish as anything in available_fishes)
				if(other_fish.ready_to_reproduce(TRUE))
					second_fish = other_fish
					break
	if(!second_fish && !HAS_TRAIT(src, TRAIT_FISH_SELF_REPRODUCE))
		return FALSE
	var/chosen_type
	var/datum/fish_evolution/chosen_evolution
	var/list/possible_evolutions = list()
	for(var/evolution_type in evolution_types)
		var/datum/fish_evolution/evolution = GLOB.fish_evolutions[evolution_type]
		if(evolution?.check_conditions(src, second_fish, loc))
			possible_evolutions += evolution
	if(second_fish?.evolution_types)
		var/secondary_evolutions = (second_fish.evolution_types - evolution_types)
		for(var/evolution_type in secondary_evolutions)
			var/datum/fish_evolution/evolution = GLOB.fish_evolutions[evolution_type]
			if(evolution?.check_conditions(second_fish, src, loc))
				possible_evolutions += evolution
	var/list/types = spawn_types || list(type)
	if(length(possible_evolutions))
		chosen_evolution = pick(possible_evolutions)
		chosen_type = chosen_evolution.new_fish_type
	else if(second_fish)
		var/list/second_fish_types = second_fish.spawn_types || list(second_fish.type)
		var/recessive = HAS_TRAIT(src, TRAIT_FISH_RECESSIVE)
		var/recessive_partner = HAS_TRAIT(second_fish, TRAIT_FISH_RECESSIVE)
		if(fish_flags & FISH_FLAG_OVERPOPULATED)
			if(recessive_partner && !recessive)
				return FALSE
			chosen_type = pick(second_fish_types)
		else
			if(recessive && !recessive_partner)
				chosen_type = pick(second_fish_types)
			else if(recessive_partner && !recessive)
				chosen_type = pick(types)
			else
				chosen_type = pick(second_fish_types + types)
	else
		chosen_type = pick(types)
	return create_offspring(chosen_type, second_fish, chosen_evolution)

#define OFFSPRING_FISH_BREEDING_TIMEOUT_MULT 2

/obj/item/fish/proc/create_offspring(chosen_type, obj/item/fish/partner, datum/fish_evolution/evolution)
	var/obj/item/fish/new_fish = new chosen_type(loc, FALSE)
	new_fish.inherit_traits(fish_traits, partner?.fish_traits, evolution?.new_traits, evolution?.removed_traits)
	if(partner)
		var/ratio_size = new_fish.average_size * (((size / average_size) + (partner.size / partner.average_size)) / 2)
		var/mean_size = (size + partner.size)/2
		var/ratio_weight = new_fish.average_weight * (((weight / average_weight) + (partner.weight / partner.average_weight)) / 2)
		var/mean_weight = (weight + partner.weight)/2
		new_fish.randomize_size_and_weight((mean_size + ratio_size) * 0.5, (mean_weight + ratio_weight) * 0.5, 0.3, update = FALSE)
		partner.breeding_wait = world.time + partner.breeding_timeout
	else
		new_fish.temp_size = size
		new_fish.temp_weight = weight
	new_fish.update_size_and_weight(new_fish.temp_size, new_fish.temp_weight)
	breeding_wait = world.time + breeding_timeout
	new_fish.breeding_wait = world.time + new_fish.breeding_timeout * OFFSPRING_FISH_BREEDING_TIMEOUT_MULT
	if(istype(loc, /obj/structure/aquarium))
		var/obj/structure/aquarium/aquarium = loc
		aquarium.add_fish(new_fish)
	return new_fish

#undef OFFSPRING_FISH_BREEDING_TIMEOUT_MULT

/obj/item/fish/proc/try_electrogenesis()
	if(status == FISH_DEAD || get_starvation_mult())
		return
	COOLDOWN_START(src, electrogenesis_cooldown, ELECTROGENESIS_DURATION + ELECTROGENESIS_VARIANCE)
	var/fish_zap_range = 1
	var/fish_zap_power = 1 KILO JOULES
	var/fish_zap_flags = ZAP_MOB_DAMAGE
	if(HAS_TRAIT(loc, TRAIT_BIOELECTRIC_GENERATOR))
		fish_zap_range = 5
		fish_zap_power = GET_FISH_ELECTROGENESIS(src)
		fish_zap_flags |= (ZAP_GENERATES_POWER | ZAP_MOB_STUN)
	tesla_zap(source = get_turf(src), zap_range = fish_zap_range, power = fish_zap_power, zap_flags = fish_zap_flags)

#define FISH_PRICE_MULTIPLIER 0.01
#define FISH_PRICE_CURVE_EXPONENT 0.85
#define FISH_PRICE_SOFT_CAP_THRESHOLD 6000
#define FISH_PRICE_SOFT_CAP_EXPONENT 0.86

/obj/item/fish/proc/get_export_price(price)
	var/size_weight_exponentation = (size * weight * FISH_PRICE_MULTIPLIER)**FISH_PRICE_CURVE_EXPONENT
	var/raw_price = price + size_weight_exponentation
	if(raw_price >= FISH_PRICE_SOFT_CAP_THRESHOLD + 1)
		var/soft_cap = (raw_price - FISH_PRICE_SOFT_CAP_THRESHOLD)**FISH_PRICE_SOFT_CAP_EXPONENT
		raw_price = FISH_PRICE_SOFT_CAP_THRESHOLD + soft_cap
	if(HAS_TRAIT(src, TRAIT_FISH_LOW_PRICE))
		raw_price *= 0.05
	return raw_price

#undef FISH_PRICE_MULTIPLIER
#undef FISH_PRICE_CURVE_EXPONENT
#undef FISH_PRICE_SOFT_CAP_THRESHOLD
#undef FISH_PRICE_SOFT_CAP_EXPONENT

/obj/item/fish/proc/get_happiness_value()
	var/happiness_value = 0
	if(fish_flags & FISH_FLAG_PETTED)
		happiness_value++
	if(get_hunger() < 0.5)
		happiness_value++
	if(loc && HAS_TRAIT(loc, TRAIT_IS_AQUARIUM))
		if(fish_flags & FISH_FLAG_SAFE_FLUID)
			happiness_value++
		if(fish_flags & FISH_FLAG_SAFE_TEMPERATURE)
			happiness_value++
	else if(proper_environment())
		happiness_value += 2
	if(bites_amount)
		happiness_value -= 2
	if(get_health_percentage() < 0.6)
		happiness_value -= 1
	return clamp(happiness_value, FISH_SAD, FISH_VERY_HAPPY)

/obj/item/fish/attack_self(mob/living/user)
	. = ..()
	try_pet_fish(user)

/obj/item/fish/proc/try_pet_fish(mob/living/user)
	var/in_aquarium = loc && HAS_TRAIT(loc, TRAIT_IS_AQUARIUM)
	if(status == FISH_DEAD)
		to_chat(user, span_warning("You try to pet [src], but [p_theyre()] motionless!"))
		return FALSE
	if(!proper_environment())
		to_chat(user, span_warning("You try to pet [src], but [p_theyre()] not feeling well!"))
		return FALSE
	return pet_fish(user, in_aquarium)

/obj/item/fish/proc/pet_fish(mob/living/user, in_aquarium)
	if(fish_flags & FISH_FLAG_PETTED)
		if(in_aquarium)
			to_chat(user, span_warning("[src] runs away from your finger as you dip it into the water!"))
		else
			to_chat(user, span_warning("You try to pet [src] but [p_they()] squirms away!"))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_FISH_ELECTROGENESIS) && GET_FISH_ELECTROGENESIS(src) > 15 MEGA JOULES)
		user.electrocute_act(5, src)
	fish_flags |= FISH_FLAG_PETTED
	new /obj/effect/temp_visual/heart(get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(clear_petted_flag)), 30 SECONDS)
	if((/datum/fish_trait/predator in fish_traits) && prob(50))
		user.visible_message(
			span_warning("[src] bites [user]'s hand!"),
			span_warning("You pet [src] as you hold [p_they()], only for [p_them()] to happily bite back!"),
			vision_distance = DEFAULT_MESSAGE_RANGE - 3,
		)
		var/body_zone = pick(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM)
		user.apply_damage((force * 0.2) + w_class * 2, BRUTE, body_zone, user.run_armor_check(body_zone, MELEE))
	else
		user.visible_message(span_notice("[user] pets [src]."), span_notice("You pet [src]. It seems to like it!"))
	return TRUE

/obj/item/fish/proc/clear_petted_flag()
	fish_flags &= ~FISH_FLAG_PETTED

/obj/item/fish/proc/clear_fed_lube(source)
	REMOVE_TRAIT(src, TRAIT_FISH_FED_LUBE, source)

/obj/item/fish/proc/clear_mutagenic(source)
	REMOVE_TRAIT(src, TRAIT_FISH_MUTAGENIC, source)

/obj/item/fish/proc/use_lazarus(datum/source, obj/item/lazarus_injector/injector, mob/user)
	SIGNAL_HANDLER
	if(status != FISH_DEAD)
		return
	set_status(FISH_ALIVE)
	injector.expend(src, user)
	return LAZARUS_INJECTOR_USED

/obj/item/fish/proc/released(atom/location, mob/living/user)
	playsound(location, 'sound/effects/splash.ogg', 50)
	SEND_SIGNAL(location, COMSIG_FISH_RELEASED_INTO, src, user)
	qdel(src)

/obj/item/fish/examine(mob/user)
	. = ..()
	if(catcher_name && catch_date)
		. += span_boldnicegreen("Caught by [catcher_name] on [catch_date].")
	if(HAS_MIND_TRAIT(user, TRAIT_EXAMINE_FISH) || HAS_TRAIT(loc, TRAIT_EXAMINE_FISH))
		. += span_notice("[p_theyre(TRUE)] [size] cm long.")
		. += span_notice("[p_they(TRUE)] weighs [weight] [span_tooltip("kiloclam", "the standard unit of measurement for space age fish", "", "", "")].")
	. += get_health_warnings(user, always_deep = FALSE)
	if(HAS_TRAIT(src, TRAIT_FISHING_BAIT))
		. += span_smallnoticeital("[p_they(TRUE)] can be used as a fishing bait.")
	if(bites_amount)
		. += span_warning("[p_theyve(TRUE)] been bitten by someone.")

/obj/item/fish/proc/get_health_warnings(mob/user, always_deep = FALSE)
	if(!HAS_MIND_TRAIT(user, TRAIT_EXAMINE_DEEPER_FISH) && !always_deep)
		return
	if(status == FISH_DEAD)
		return span_deadsay("[p_theyre(TRUE)] [HAS_MIND_TRAIT(user, TRAIT_NAIVE) ? "taking the big snooze" : "dead"].")
	var/list/warnings = list()
	if(get_starvation_mult())
		warnings += "starving"
	if(!HAS_TRAIT(src, TRAIT_FISH_STASIS) && !proper_environment())
		warnings += "drowning"
	var/health_ratio = get_health_percentage()
	switch(health_ratio)
		if(0 to 0.25)
			warnings += "dying"
		if(0.25 to 0.5)
			warnings += "very unhealthy"
		if(0.5 to 0.75)
			warnings += "unhealthy"
		if(0.75 to 0.9)
			warnings += "mostly healthy"
	if(length(warnings))
		. += span_warning("[p_theyre(TRUE)] [english_list(warnings)].")
	return .

/obj/item/fish/update_icon_state()
	if((status == FISH_DEAD || HAS_TRAIT(src, TRAIT_FISH_STASIS)) && icon_state_dead)
		icon_state = icon_state_dead
	else
		icon_state = base_icon_state
	item_state = get_inhand_state()
	return ..()

/obj/item/fish/attackby(obj/item/item, mob/living/user, params)
	if(!istype(item, /obj/item/reagent_containers/cup/fish_feed))
		return ..()
	if(!item.reagents.total_volume)
		balloon_alert(user, "[item.name] пуст!")
		return TRUE
	if(status == FISH_DEAD)
		balloon_alert(user, "[name] [HAS_MIND_TRAIT(user, TRAIT_NAIVE) ? "не голодна" : "мертва!"]")
		return TRUE
	feed(item.reagents)
	balloon_alert(user, "покормлена: [name]")
	return TRUE

/obj/item/fish/proc/get_aquarium_animation(fluid_type)
	if(fluid_type == AQUARIUM_FLUID_AIR || status == FISH_DEAD)
		return AQUARIUM_ANIMATION_FISH_DEAD
	return AQUARIUM_ANIMATION_FISH_SWIM

/obj/item/fish/proc/atom_break(damage_flag)
	set_status(FISH_DEAD)

/obj/item/fish/proc/on_fish_cooked(cooking_time)
	if(HAS_TRAIT(src, TRAIT_FISH_SURVIVE_COOKING))
		return
	damage_fish(max_integrity)
	if(cooking_time >= FISH_SAFE_COOKING_DURATION)
		well_cooked()

/obj/item/fish/proc/well_cooked()
	ADD_TRAIT(src, TRAIT_FISH_WELL_COOKED, INNATE_TRAIT)
	refresh_edibility()

/obj/item/fish/Destroy()
	stop_flopping()
	if(istype(loc, /obj/structure/aquarium))
		var/obj/structure/aquarium/tank = loc
		if(!QDELETED(tank))
			tank.tracked_fish -= src
			tank.recalculate_beauty()
			tank.update_icon()
	return ..()

/obj/item/fish/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, status))
			if(var_value != FISH_DEAD && var_value != FISH_ALIVE)
				var_value = var_value ? FISH_ALIVE : FISH_DEAD
			set_status(var_value)
		if(NAMEOF(src, size))
			if(!isnum(var_value) || var_value == 0)
				return FALSE
			update_size_and_weight(var_value, weight)
		if(NAMEOF(src, weight))
			if(!isnum(var_value) || var_value == 0)
				return FALSE
			update_size_and_weight(size, var_value)
		else
			return ..()
	return TRUE
