// Источники рыбы - это датумы, которые описывают, что можно поймать в конкретном месте.
// Урезано и подогнано под эту кодовую базу из системы уровнем выше.

GLOBAL_LIST_INIT_TYPED(preset_fish_sources, /datum/fish_source, init_subtypes_w_path_keys(/datum/fish_source, list()))

GLOBAL_LIST_INIT(specific_fish_icons, generate_specific_fish_icons())

/proc/generate_specific_fish_icons()
	var/list/return_list = list()
	return_list[FISHING_RANDOM_SEED] = FISH_ICON_SEED
	return_list[FISHING_RANDOM_ORGAN] = FISH_ICON_ORGAN
	return_list[FISHING_VENDING_CHUCK] = FISH_ICON_COIN
	return_list[/obj/item/fish/armorfish] = FISH_ICON_CRAB
	return_list[/obj/item/fish/boned] = FISH_ICON_BONE
	return_list[/obj/item/fish/chainsawfish] = FISH_ICON_WEAPON
	return_list[/obj/item/fish/chasm_crab] = FISH_ICON_CRAB
	return_list[/obj/item/fish/gunner_jellyfish] = FISH_ICON_JELLYFISH
	return_list[/obj/item/fish/holo/crab] = FISH_ICON_CRAB
	return_list[/obj/item/fish/holo/puffer] = FISH_ICON_CHUNKY
	return_list[/obj/item/fish/jumpercable] = FISH_ICON_ELECTRIC
	return_list[/obj/item/fish/lavaloop] = FISH_ICON_WEAPON
	return_list[/obj/item/fish/mastodon] = FISH_ICON_BONE
	return_list[/obj/item/fish/pike/armored] = FISH_ICON_WEAPON
	return_list[/obj/item/fish/pufferfish] = FISH_ICON_CHUNKY
	return_list[/obj/item/fish/sand_crab] = FISH_ICON_CRAB
	return_list[/obj/item/fish/skin_crab] = FISH_ICON_CRAB
	return_list[/obj/item/fish/slimefish] = FISH_ICON_SLIME
	return_list[/obj/item/fish/sludgefish] = FISH_ICON_SLIME
	return_list[/obj/item/fish/starfish] = FISH_ICON_STAR
	return_list[/obj/item/fish/stingray] = FISH_ICON_WEAPON
	return_list[/obj/item/fish/swordfish] = FISH_ICON_WEAPON
	return_list[/obj/item/fish/zipzap] = FISH_ICON_ELECTRIC
	return_list[/obj/item/fishing_rod] = FISH_ICON_COIN
	return_list[/obj/item/stack/sheet/bone] = FISH_ICON_BONE
	return_list[/obj/item/stack/sheet/mineral] = FISH_ICON_GEM
	return_list[/obj/item/stack/ore] = FISH_ICON_GEM
	return return_list

/datum/fish_source
	/// Таблица улова с относительными весами.
	var/list/fish_table = list()
	/// Если ключ из fish_table есть и тут, рыба доступна в ограниченном количестве.
	var/list/fish_counts = list()
	/// Всё, что ограничено количеством, со временем вернётся в счётчики.
	var/list/fish_count_regen = list()
	/// Что сейчас ждёт возврата в fish_counts.
	var/list/currently_on_regen
	/// Всплывающая подсказка, если по таблице ничего не выпало.
	var/duds = list("ничего", "крючок пуст")
	/// Базовая сложность рыбалки тут.
	var/fishing_difficulty = FISHING_DEFAULT_DIFFICULTY
	/// Как этот тип места описан в каталоге источников рыбы.
	var/catalog_description
	/// Имя фоновой картинки из ресурсов мини-игры.
	var/background = "background_default"
	var/fish_source_flags = NONE
	///При привязке к рыболовному порталу станет icon_state варианта в радиальном меню.
	var/radial_state = "default"
	///Имя этого варианта в радиальном меню портала.
	var/radial_name = "Fishing"
	///При выборе в портале станет icon_state оверлея на самой машине.
	var/overlay_state = "portal_aquarium"
	///Если задано, задаёт свои верхнюю и нижнюю границы ожидания в фазе ожидания.
	var/list/wait_time_range
	/// Сколько уникальных рыб надо отсканировать, чтобы открыть источник в фиш-портере.
	var/unlock_requirement = 0
	///Если задано, местная рыба не погибнет, оставаясь на этих тайлах.
	var/list/associated_safe_turfs
	///подтипы безопасных тайлов, которые на самом деле НЕ безопасны
	var/list/safe_turfs_blacklist

/datum/fish_source/New()
	if(!SSfishing || !SSfishing.initialized && associated_safe_turfs)
		associated_safe_turfs = typecacheof(associated_safe_turfs)
		if(safe_turfs_blacklist)
			associated_safe_turfs -= typecacheof(safe_turfs_blacklist)
	for(var/path in fish_counts)
		if(!(path in fish_count_regen))
			fish_count_regen[path] = 30 MINUTES

/datum/fish_source/proc/on_fishing_spot_init(datum/component/fishing_spot/spot)
	return

/datum/fish_source/proc/on_fishing_spot_del(datum/component/fishing_spot/spot)
	return

/datum/fish_source/proc/reason_we_cant_fish(obj/item/fishing_rod/rod, mob/fisherman, atom/parent)
	return rod?.reason_we_cant_fish(src)

/datum/fish_source/proc/on_start_fishing(obj/item/fishing_rod/rod, mob/fisherman, atom/parent)
	return

/datum/fish_source/proc/calculate_difficulty_minigame(datum/fishing_challenge/challenge, reward_path, obj/item/fishing_rod/rod, mob/fisherman)
	. = calculate_difficulty(reward_path, rod, fisherman)
	if(!(challenge.special_effects & FISHING_MINIGAME_RULE_NO_EXP))
		. -= (fisherman.mind?.get_skill_level(/datum/skill/level/fishing) || 0) * 1.5
	if(challenge.special_effects & FISHING_MINIGAME_RULE_KILL)
		challenge.RegisterSignal(src, COMSIG_FISH_SOURCE_REWARD_DISPENSED, TYPE_PROC_REF(/datum/fishing_challenge, hurt_fish))

/datum/fish_source/proc/calculate_difficulty(result, obj/item/fishing_rod/rod, mob/fisherman)
	. = fishing_difficulty
	if(HAS_TRAIT(fisherman, TRAIT_EXPERT_FISHER))
		. += EXPERT_FISHER_DIFFICULTY_MOD
	. += rod?.difficulty_modifier
	var/is_fish_instance = isfish(result)
	var/obj/item/fish/caught_fish = result
	if(!ispath(result, /obj/item/fish) && !is_fish_instance)
		return
	var/result_path = is_fish_instance ? caught_fish.type : result
	. += initial(caught_fish.fishing_difficulty_modifier)
	var/list/fish_properties = SSfishing.fish_properties[result_path]
	if(!fish_properties)
		return
	if(rod?.bait)
		var/obj/item/bait = rod.bait
		for(var/bait_identifier in fish_properties[FISH_PROPERTIES_FAV_BAIT])
			if(is_matching_bait(bait, bait_identifier))
				. += FAV_BAIT_DIFFICULTY_MOD
		for(var/bait_identifier in fish_properties[FISH_PROPERTIES_BAD_BAIT])
			if(is_matching_bait(bait, bait_identifier))
				. += DISLIKED_BAIT_DIFFICULTY_MOD
	var/list/fish_traits = is_fish_instance ? caught_fish.fish_traits : fish_properties[FISH_PROPERTIES_TRAITS]
	var/additive_mod = 0
	var/multiplicative_mod = 1
	for(var/fish_trait in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
		var/mod = trait?.difficulty_mod(rod, fisherman)
		if(islist(mod))
			additive_mod += mod[ADDITIVE_FISHING_MOD]
			multiplicative_mod *= mod[MULTIPLICATIVE_FISHING_MOD]
		else
			additive_mod += mod
	. += additive_mod
	. *= multiplicative_mod

/datum/fish_source/proc/roll_reward_minigame(datum/source, obj/item/fishing_rod/rod, mob/fisherman, atom/location, list/rewards)
	SIGNAL_HANDLER
	rewards += roll_reward(rod, fisherman, location)

/datum/fish_source/proc/roll_reward(obj/item/fishing_rod/rod, mob/fisherman, atom/location)
	return pick_weight(get_modified_fish_table(rod, fisherman, location)) || FISHING_DUD

/datum/fish_source/proc/pre_challenge_started(obj/item/fishing_rod/rod, mob/user, datum/fishing_challenge/challenge)
	return

/datum/fish_source/proc/interrupt_challenge(reason)
	SEND_SIGNAL(src, COMSIG_FISHING_SOURCE_INTERRUPT_CHALLENGE, reason)

/datum/fish_source/proc/on_challenge_completed(mob/user, datum/fishing_challenge/challenge, success)
	SIGNAL_HANDLER
	UnregisterSignal(user, COMSIG_MOB_COMPLETE_FISHING)
	if(!success)
		return
	var/atom/movable/reward = dispense_reward(challenge.reward_path, user, challenge.location, challenge.used_rod)
	SEND_SIGNAL(challenge.used_rod, COMSIG_FISHING_ROD_CAUGHT_FISH, reward, user)
	challenge.used_rod?.on_reward_caught(reward, user)
	if(reward)
		REMOVE_TRAIT(reward, TRAIT_FISH_JUST_SPAWNED, TRAIT_GENERIC)

/datum/fish_source/proc/dispense_reward(reward_path, mob/fisherman, atom/fishing_spot, obj/item/fishing_rod/rod)
	var/atom/movable/reward = simple_dispense_reward(reward_path, get_turf(fisherman), fishing_spot)
	if(!reward)
		fisherman.balloon_alert(fisherman, pick(duds))
		return
	if(isitem(reward))
		INVOKE_ASYNC(fisherman, TYPE_PROC_REF(/mob, put_in_hands), reward)
	else if(istype(reward, /obj/effect/spawner))
		fisherman.balloon_alert(fisherman, "что-то поймано!")
		return
	fisherman.balloon_alert(fisherman, "поймано: [reward]!")
	if(isfish(reward))
		ADD_TRAIT(reward, TRAIT_NO_FISHING_ACHIEVEMENT, TRAIT_GENERIC)
	return reward

/datum/fish_source/proc/simple_dispense_reward(reward_path, atom/spawn_location, atom/fishing_spot)
	if(isnull(reward_path))
		return null
	if(!isnull(fish_counts[reward_path]))
		if(fish_counts[reward_path] <= 0)
			return null
		fish_counts[reward_path] -= 1
		var/regen_time = fish_count_regen?[reward_path]
		if(regen_time)
			LAZYADDASSOC(currently_on_regen, reward_path, 1)
			if(currently_on_regen[reward_path] == 1)
				addtimer(CALLBACK(src, PROC_REF(regen_count), reward_path), regen_time)
	var/atom/movable/reward = spawn_reward(reward_path, spawn_location, fishing_spot)
	SEND_SIGNAL(src, COMSIG_FISH_SOURCE_REWARD_DISPENSED, reward)
	return reward

/datum/fish_source/proc/regen_count(reward_path)
	if(!LAZYACCESS(currently_on_regen, reward_path))
		return
	fish_counts[reward_path] += 1
	currently_on_regen[reward_path] -= 1
	if(currently_on_regen[reward_path] <= 0)
		LAZYREMOVE(currently_on_regen, reward_path)
		return
	addtimer(CALLBACK(src, PROC_REF(regen_count), reward_path), fish_count_regen[reward_path])

/datum/fish_source/proc/spawn_reward(reward_path, atom/spawn_location, atom/fishing_spot)
	if(reward_path == FISHING_DUD)
		return
	if(ismovable(reward_path))
		var/atom/movable/reward = reward_path
		reward.forceMove(spawn_location)
		return reward
	if(!ispath(reward_path, /atom/movable))
		return
	var/atom/movable/reward = new reward_path(spawn_location)
	if(isfish(reward))
		var/obj/item/fish/caught_fish = reward
		ADD_TRAIT(caught_fish, TRAIT_FISH_JUST_SPAWNED, TRAIT_GENERIC)
		caught_fish.randomize_size_and_weight()
	return reward

/datum/fish_source/proc/get_fish_table(atom/location, from_explosion = FALSE)
	var/list/table = fish_table.Copy()
	for(var/result in table)
		if(!isnull(fish_counts[result]) && fish_counts[result] <= 0)
			table -= result
	return table

/datum/fish_source/proc/get_modified_fish_table(obj/item/fishing_rod/rod, mob/fisherman, atom/location)
	var/obj/item/bait/bait_item = rod?.bait
	var/list/final_table = get_fish_table(location)
	if(rod && HAS_TRAIT(rod, TRAIT_ROD_REMOVE_FISHING_DUD))
		final_table -= FISHING_DUD
	for(var/result in final_table)
		if(rod?.hook)
			final_table[result] *= rod.hook.get_hook_bonus_multiplicative(result)
			final_table[result] += rod.hook.get_hook_bonus_additive(result)
		if(ispath(result, /obj/item/fish) || isfish(result))
			if(bait_item)
				var/mult = bait_item.check_bait(result)
				final_table[result] = round(final_table[result] * mult, 1)
				if(mult > 1 && HAS_TRAIT(bait_item, TRAIT_BAIT_ALLOW_FISHING_DUD))
					final_table -= FISHING_DUD
			else
				final_table[result] = round(final_table[result] * FISH_WEIGHT_MULT_WITHOUT_BAIT, 1)
			final_table[result] = get_fish_trait_catch_mods(final_table[result], result, rod, fisherman, location)
		if(final_table[result] <= 0)
			final_table -= result
	return final_table

/datum/fish_source/proc/get_fish_trait_catch_mods(weight, obj/item/fish/fish, obj/item/fishing_rod/rod, mob/user, atom/location)
	var/is_fish_instance = isfish(fish)
	if(!ispath(fish, /obj/item/fish) && !is_fish_instance)
		return weight
	var/multiplier = 1
	var/list/fish_traits = is_fish_instance ? fish.fish_traits : SSfishing.fish_properties[fish]?[FISH_PROPERTIES_TRAITS]
	for(var/fish_trait in fish_traits)
		var/datum/fish_trait/trait = GLOB.fish_traits[fish_trait]
		var/mod = trait?.catch_weight_mod(rod, user, location, is_fish_instance ? fish.type : fish)
		if(islist(mod))
			weight += mod[ADDITIVE_FISHING_MOD]
			multiplier *= mod[MULTIPLICATIVE_FISHING_MOD]
		else if(isnum(mod))
			multiplier *= mod
	return round(weight * multiplier, 1)

/datum/fish_source/proc/has_known_fishes(atom/location)
	var/show_anyway = fish_source_flags & FISH_SOURCE_FLAG_IGNORE_HIDDEN_ON_CATALOG
	for(var/reward in get_fish_table(location))
		if(!ispath(reward, /obj/item/fish) && !isfish(reward))
			continue
		var/obj/item/fish/prototype = reward
		if(show_anyway || (initial(prototype.fish_flags) & FISH_FLAG_SHOW_IN_CATALOG))
			return TRUE
	return FALSE

/datum/fish_source/proc/get_catchable_fish_names(mob/user, atom/location, list/examine_text)
	var/list/known_fishes = list()
	var/show_anyway = fish_source_flags & FISH_SOURCE_FLAG_IGNORE_HIDDEN_ON_CATALOG
	for(var/reward in get_fish_table(location))
		if(!ispath(reward, /obj/item/fish) && !isfish(reward))
			continue
		var/obj/item/fish/prototype = reward
		if(!show_anyway && !(initial(prototype.fish_flags) & FISH_FLAG_SHOW_IN_CATALOG))
			continue
		known_fishes += initial(prototype.name)
	if(!length(known_fishes))
		return
	examine_text += span_info("You can catch the following fish here: [english_list(known_fishes)].")

/datum/fish_source/proc/readd_fish(atom/location, obj/item/fish/fish, mob/living/releaser)
	if(fish.status == FISH_DEAD || isnull(fish_table[fish.type]) || isnull(fish_counts[fish.type]))
		return
	if(!LAZYACCESS(currently_on_regen, fish.type))
		fish_counts[fish.type] += 1
	else
		regen_count(fish.type)


// Рыбное место. Вешается на тайлы, структуры или любой другой атом.
/datum/component/fishing_spot
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Задаёт вероятности и доступность рыбы
	var/datum/fish_source/fish_source

/datum/component/fishing_spot/Initialize(configuration)
	if(ispath(configuration, /datum/fish_source))
		fish_source = new configuration
	else if(istype(configuration, /datum/fish_source))
		fish_source = configuration
	else
		return COMPONENT_INCOMPATIBLE
	fish_source.on_fishing_spot_init(src)
	RegisterSignal(parent, COMSIG_FISHING_ROD_CAST, PROC_REF(handle_cast))
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examined))
	RegisterSignal(parent, COMSIG_FISH_RELEASED_INTO, PROC_REF(fish_released))
	ADD_TRAIT(parent, TRAIT_FISHING_SPOT, REF(src))

/datum/component/fishing_spot/Destroy()
	REMOVE_TRAIT(parent, TRAIT_FISHING_SPOT, REF(src))
	fish_source.on_fishing_spot_del(src)
	fish_source = null
	return ..()

/datum/component/fishing_spot/proc/handle_cast(datum/source, obj/item/fishing_rod/rod, mob/user)
	SIGNAL_HANDLER
	if(try_start_fishing(rod, user))
		return FISHING_ROD_CAST_HANDLED
	return NONE

/datum/component/fishing_spot/proc/on_examined(datum/source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if(!fish_source.has_known_fishes(source))
		return
	examine_text += span_smallnoticeital("This is a fishing spot. You can fish here with a fishing rod.")

/datum/component/fishing_spot/proc/try_start_fishing(obj/item/possibly_rod, mob/user)
	SIGNAL_HANDLER
	var/obj/item/fishing_rod/rod = possibly_rod
	if(!istype(rod))
		return
	var/datum/fishing_challenge/existing_challenge = GLOB.fishing_challenges_by_user[user]
	if(existing_challenge && (QDELETED(existing_challenge) || existing_challenge.completed))
		GLOB.fishing_challenges_by_user -= user
		existing_challenge = null
	if(existing_challenge || (rod.fishing_line && !QDELETED(rod.fishing_line)))
		user.balloon_alert(user, "уже рыбачите")
		return COMPONENT_NO_AFTERATTACK
	if(rod.fishing_line && QDELETED(rod.fishing_line))
		rod.fishing_line = null
	var/denial_reason = fish_source.reason_we_cant_fish(rod, user, parent)
	if(denial_reason)
		to_chat(user, span_warning(denial_reason))
		return COMPONENT_NO_AFTERATTACK
	fish_source.on_start_fishing(rod, user, parent)
	var/datum/fishing_challenge/challenge = new(src, rod, user)
	fish_source.pre_challenge_started(rod, user, challenge)
	challenge.start(user)
	return COMPONENT_NO_AFTERATTACK

/datum/component/fishing_spot/proc/fish_released(atom/source, obj/item/fish/fish, mob/living/releaser)
	SIGNAL_HANDLER
	fish_source.readd_fish(source, fish, releaser)
