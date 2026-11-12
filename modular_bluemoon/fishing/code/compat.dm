// Слой совместимости

// Переменные предметов
/obj/item
	var/inhand_icon_state = null
	var/sound_vary = FALSE
	var/demolition_mod = 1
	var/exposed_wound_bonus = 0
	var/drag_slowdown = 0
	var/base_pixel_w = 0
	var/base_pixel_z = 0
	var/embed_type
	var/block_sound

// Общие помощники на все случаи
/atom/proc/add_traits(list/traits, source)
	for(var/trait in traits)
		ADD_TRAIT(src, trait, source)

/proc/isfish(atom/A)
	return istype(A, /obj/item/fish)

/proc/bitfield_to_list(bitfield)
	var/list/result = list()
	var/bit = 1
	while(bitfield >= bit)
		if(bitfield & bit)
			result += bit
		bit <<= 1
	return result

/datum/reagent/proc/used_on_fish(obj/item/fish/fish)
	return FALSE

/datum/reagent/proc/pre_rez_check(atom/target)
	return TRUE

/obj/item/lazarus_injector/proc/expend(atom/target, mob/user)
	qdel(src)

/obj/item/proc/fade_into_nothing(duration = 0, fade_time = 0)
	qdel(src)

/obj/item/proc/set_suicide()
	return

/obj/item/proc/manual_emote(emote)
	visible_message(span_danger("[src] [emote]"))

/datum/bodypart_overlay/simple
	var/icon_state

/mob/living/proc/drop_everything(del_on_drop = FALSE, force = FALSE, del_if_nodrop = FALSE)
	for(var/obj/item/item in get_contents())
		dropItemToGround(item)
	return

/mob/living/proc/painful_scream()
	emote("scream")

/mob/living/proc/shake_up_animation()
	do_jitter_animation(jitteriness)

/mob/living/proc/set_suicide(value = null)
	return

/mob/living/proc/can_block_magic(flags, charge_cost = 0)
	return check_magic_resistance(magic = TRUE, chargecost = charge_cost)

/mob/living/proc/adjust_temporary_deafness(amount)
	if(!iscarbon(src))
		return
	minimumDeafTicks(amount)

/mob/living/proc/adjust_organ_loss(organ, amount, max_amount = null, slot = null)
	if(!iscarbon(src))
		return
	adjustOrganLoss(organ, amount, max_amount)

/mob/living/proc/get_organ_slot(slot)
	if(!iscarbon(src))
		return null
	return getorganslot(slot)

/mob/living/proc/cause_wound_of_type_and_severity(wounding_type, obj/item/bodypart/part, severity, severity_max = null)
	if(!istype(part))
		return
	part.receive_damage(severity * 5, sharpness = wounding_type == WOUND_BLUNT ? SHARP_NONE : SHARP_EDGED)

/mob/living/proc/manual_emote(emote)
	visible_message(span_danger("[src] [emote]"))

/mob/living/proc/set_greyscale(colors = null)
	if(islist(colors))
		color = colors[1]
	else if(colors)
		color = colors

/mob/living/proc/adjust_stutter(amount)
	stuttering = max(stuttering, amount)

/mob/living/proc/adjust_slurring(amount)
	slurring = max(slurring, amount)

/mob/living/proc/adjust_dizzy(amount)
	dizziness = max(dizziness, amount)

/mob/living/proc/adjust_staggered(amount)
	dizziness = max(dizziness, amount)

/mob/living/proc/adjust_jitter(amount)
	jitteriness = max(jitteriness, amount)

/mob/living/proc/adjust_confusion(amount)
	confused = max(confused, amount)

/mob/living/proc/adjust_hallucinations(amount)
	hallucination = max(hallucination, amount)

/mob/living/proc/adjust_eye_blur(amount)
	eye_blurry = max(eye_blurry, amount)

/mob/living/proc/on_bodypart_insert(obj/item/bodypart/part)
	return

/mob/living/proc/on_bodypart_remove(obj/item/bodypart/part)
	return

/mob/living/proc/on_mob_insert(obj/item/organ/organ)
	return

/mob/living/proc/on_mob_remove(obj/item/organ/organ)
	return

/mob/living
	var/obscured_slots = NONE
	var/usable_hands = 2

/mob/living/proc/PossessByPlayer(ckey)
	if(!ckey)
		return
	src.ckey = ckey

/obj/item/organ
	var/list/organ_traits
	var/visual

/obj/item/organ/proc/apply_organ_damage(amount, max_amount = null)
	if(!isnum(amount))
		return
	applyOrganDamage(amount, max_amount)

/obj/item/organ/proc/adjust_temporary_deafness(amount)
	if(!istype(src, /obj/item/organ/ears))
		return
	var/obj/item/organ/ears/ears = src
	ears.minimumDeafTicks(amount)

/obj/item/organ/proc/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	return

/obj/item/organ/proc/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)
	return

/obj/item/organ/proc/dust()
	qdel(src)

/obj/item/bodypart
	var/head_flags = NONE

/obj/item/bodypart/proc/add_color_override()
	return

/obj/item/bodypart/proc/remove_color_override()
	return

/obj/item/bodypart/arm

/obj/item/organ/ears/babbelfish
/obj/item/organ/eyes/snail

/obj/effect/spawner/random/frog

/obj/effect/mob_spawn/corpse/human/skeleton

/datum/holodeck_program
	var/list/spawned_atoms = list()

/datum/holodeck_program/proc/add_to_spawned(atom/movable/thing)
	spawned_atoms += thing

/area/station/holodeck
	var/datum/holodeck_program/linked

/area/station/holodeck/proc/add_to_spawned(atom/movable/thing)
	return

GLOBAL_LIST_INIT(carp_colors, list("#ffffff", "#cccccc", "#999999"))

/proc/skintone2hex(skin_tone)
	return "#[skin_tone]"

// Пустышки реагентов
/datum/reagent/consumable/nutriment/fat
	name = "Fat"
	taste_description = "fat"
	description = "Fatty nutrients."

/datum/reagent/consumable/liquidgibs
	name = "Liquid Gibs"
	taste_description = "gibs"
	description = "Liquefied organic matter."

/datum/reagent/consumable/salt
	name = "Salt"
	taste_description = "salt"
	description = "Table salt."

/datum/reagent/drug/kronkaine
	name = "Kronkaine"
	taste_description = "chemicals"
	description = "A highly addictive stimulant."

/datum/reagent/bone_dust
	name = "Bone dust"
	taste_description = "chalk"
	description = "Powdered bone."

/datum/reagent/medicine/oculine/flumpuline
	name = "Flumpuline"
	taste_description = "slime"
	description = "A strange ocular medicine."

// Пустышки типов данных
/datum/embedding
	var/mob/living/owner
	var/obj/item/parent
	var/pain_mult = 1
	var/embed_chance = 100
	var/fall_chance = 0
	var/pain_chance = 0
	var/impact_pain_mult = 1
	var/remove_pain_mult = 1
	var/rip_time = 1 SECONDS
	var/ignore_throwspeed_threshold = FALSE
	var/jostle_chance = 0
	var/jostle_pain_mult = 1

/datum/embedding/proc/jostle_effects()
	return

/datum/mood_event/inked
/datum/memory/witnessed_inking
/datum/memory/caught_fish

/datum/status_effect/go_away/deletes_mob
/datum/status_effect/grouped/hooked
/datum/status_effect/grouped/hooked/jaws

/datum/ai_controller/basic_controller/lobstrosity/juvenile/calm
/datum/ai_controller/basic_controller/lobstrosity/juvenile/capricious

/datum/bodypart_overlay/texture/checkered

// Пустышки компонентов
/datum/component/fish_growth
	var/result
	var/growth_time
	var/use_drop_loc
	var/del_on_grow
	var/inherit_name
	var/growth_timer

/datum/component/fish_growth/Initialize(output, growth_time, use_drop_loc = TRUE, del_on_grow = TRUE, inherit_name = TRUE)
	if(!istype(parent, /obj/item/fish))
		return COMPONENT_INCOMPATIBLE
	src.result = output
	src.growth_time = growth_time
	src.use_drop_loc = use_drop_loc
	src.del_on_grow = del_on_grow
	src.inherit_name = inherit_name
	growth_timer = addtimer(CALLBACK(src, PROC_REF(do_growth)), growth_time, TIMER_STOPPABLE)
	return ..()

/datum/component/fish_growth/Destroy()
	if(growth_timer && growth_timer != -1)
		deltimer(growth_timer)
	return ..()

/datum/component/fish_growth/proc/do_growth()
	var/obj/item/fish/fish = parent
	if(QDELETED(fish))
		return
	var/obj/item/fish/output_type = result
	var/datum/fish_evolution/evolution
	if(ispath(result, /datum/fish_evolution))
		evolution = GLOB.fish_evolutions[result]
		output_type = evolution?.new_fish_type
	if(!ispath(output_type, /atom/movable))
		return
	var/dont_grow = SEND_SIGNAL(fish, COMSIG_FISH_BEFORE_GROWING, 1, growth_time, output_type) & COMPONENT_DONT_GROW
	if(evolution && (evolution.growth_checks(fish, 0, src) & COMPONENT_DONT_GROW))
		dont_grow = TRUE
	if(dont_grow)
		growth_timer = addtimer(CALLBACK(src, PROC_REF(do_growth)), 30 SECONDS, TIMER_STOPPABLE)
		return
	var/atom/spawn_location = use_drop_loc ? fish.drop_location() : get_turf(fish)
	var/atom/movable/new_thing = new output_type(spawn_location)
	if(!new_thing)
		return
	if(inherit_name)
		new_thing.name = fish.name
	if(istype(new_thing, /obj/item/fish))
		var/obj/item/fish/new_fish = new_thing
		new_fish.inherit_traits(fish.fish_traits, null, evolution?.new_traits, evolution?.removed_traits)
	SEND_SIGNAL(fish, COMSIG_FISH_FINISH_GROWING, new_thing)
	if(del_on_grow)
		qdel(fish)
	else
		growth_timer = addtimer(CALLBACK(src, PROC_REF(do_growth)), growth_time, TIMER_STOPPABLE)

/datum/component/boomerang
	var/range
	var/spin

/datum/component/boomerang/Initialize(range, spin)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.range = range
	src.spin = spin
	RegisterSignal(parent, COMSIG_MOVABLE_IMPACT, PROC_REF(on_impact))

/datum/component/boomerang/proc/on_impact(obj/item/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	var/mob/thrower = throwingdatum?.thrower
	if(!thrower || QDELETED(thrower) || source.loc == thrower)
		return
	addtimer(CALLBACK(src, PROC_REF(throw_back), source, thrower), 1)

/datum/component/boomerang/proc/throw_back(obj/item/source, mob/thrower)
	if(QDELETED(source) || QDELETED(thrower))
		return
	source.throw_at(thrower, range, 1, thrower, spin)

/datum/component/throwbonus_on_windup
	var/maximum_bonus
	var/windup_increment_speed
	var/throw_text
	var/datum/callback/pass_maximum_callback
	var/datum/callback/apply_bonus_callback
	var/sound_on_success
	var/effect_on_success
	var/current_bonus = 0
	var/windup_timer
	var/mob/living/holder

/datum/component/throwbonus_on_windup/Initialize(maximum_bonus, windup_increment_speed = 1, throw_text = null, pass_maximum_callback, apply_bonus_callback, sound_on_success, effect_on_success)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.maximum_bonus = maximum_bonus
	src.windup_increment_speed = windup_increment_speed
	src.throw_text = throw_text
	src.pass_maximum_callback = pass_maximum_callback
	src.apply_bonus_callback = apply_bonus_callback
	src.sound_on_success = sound_on_success
	src.effect_on_success = effect_on_success
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_drop))
	RegisterSignal(parent, COMSIG_MOVABLE_PRE_THROW, PROC_REF(on_pre_throw))
	RegisterSignal(parent, COMSIG_MOVABLE_IMPACT, PROC_REF(on_impact))

/datum/component/throwbonus_on_windup/Destroy()
	stop_windup()
	return ..()

/datum/component/throwbonus_on_windup/proc/on_equip(obj/item/source, mob/user, slot)
	if(slot != ITEM_SLOT_HANDS)
		return
	holder = user
	if(!windup_timer)
		windup_timer = addtimer(CALLBACK(src, PROC_REF(increment)), windup_increment_speed, TIMER_LOOP | TIMER_STOPPABLE)

/datum/component/throwbonus_on_windup/proc/on_drop(obj/item/source, mob/user)
	holder = null
	stop_windup()
	reset_bonus()

/datum/component/throwbonus_on_windup/proc/on_pre_throw(obj/item/source, list/arguments)
	stop_windup()

/datum/component/throwbonus_on_windup/proc/stop_windup()
	if(windup_timer && windup_timer != -1)
		deltimer(windup_timer)
	windup_timer = null

/datum/component/throwbonus_on_windup/proc/reset_bonus()
	current_bonus = 0
	var/obj/item/item = parent
	if(istype(item))
		item.throwforce = initial(item.throwforce)

/datum/component/throwbonus_on_windup/proc/increment()
	if(!holder || QDELETED(holder) || !(parent in holder.held_items))
		stop_windup()
		return
	current_bonus = min(current_bonus + 1, maximum_bonus)
	var/obj/item/item = parent
	item.throwforce = initial(item.throwforce) + current_bonus
	if(current_bonus < maximum_bonus)
		return
	stop_windup()
	if(throw_text)
		holder.visible_message(span_warning("[holder] [throw_text]"))
	pass_maximum_callback?.Invoke(holder)

/datum/component/throwbonus_on_windup/proc/on_impact(obj/item/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!current_bonus)
		return
	var/success = apply_bonus_callback?.Invoke(hit_atom, current_bonus)
	if(success)
		if(sound_on_success)
			playsound(source, sound_on_success, 50, TRUE)
		if(effect_on_success)
			new effect_on_success(get_turf(source))
	reset_bonus()

/datum/component/face_decal/splat
	var/mutable_appearance/ink_overlay

/datum/component/face_decal/splat/Initialize(color, memory_type, mood_event_type)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/wearer = parent
	ink_overlay = mutable_appearance('icons/effects/blood.dmi', "maskblood")
	ink_overlay.color = color || COLOR_NEARLY_ALL_BLACK
	wearer.add_overlay(ink_overlay)

/datum/component/face_decal/splat/Destroy()
	if(ink_overlay && ismob(parent))
		var/mob/living/wearer = parent
		wearer.cut_overlay(ink_overlay)
	return ..()

/datum/component/omen/Initialize()
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	if(ismob(parent))
		to_chat(parent, span_warning("На вас ложится тяжёлое зловещее проклятие..."))

/datum/component/omen/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if(!prob(2))
		return
	var/mob/living/cursed = parent
	switch(rand(1, 4))
		if(1)
			cursed.adjustBruteLoss(2)
			to_chat(cursed, span_warning("Что-то царапает вас изнутри."))
		if(2)
			cursed.adjust_hallucinations(10)
			to_chat(cursed, span_warning("Тени шевелятся в углах зрения."))
		if(3)
			cursed.adjust_jitter(10)
			to_chat(cursed, span_warning("Вас передёргивает от чужого взгляда."))
		if(4)
			cursed.adjust_stutter(10)
			to_chat(cursed, span_warning("Слова путаются сами собой."))

/datum/component/anti_magic
/datum/component/anti_magic/Initialize(antimagic_flags, inventory_flags, charges, block_magic, expiration)
	var/protects_magic = !!(antimagic_flags & MAGIC_RESISTANCE_MIND)
	return ..(_magic = protects_magic, _psychic = protects_magic, _charges = charges, _reaction = block_magic, _expire = expiration)

/datum/component/two_handed
/datum/component/grillable
/datum/component/infective
/datum/component/germ_sensitive
/datum/component/aquarium_content

// Пустышки элементов
/datum/element/noticable_organ
/datum/element/noticable_organ/Attach(datum/target, description)
	return ..()

/datum/element/lube_walking
/datum/element/lube_walking/Attach(datum/target)
	. = ..()
	if(!isliving(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/element/lube_walking/Detach(datum/source, ...)
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	return ..()

/datum/element/lube_walking/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced, list/old_locs, momentum_change)
	SIGNAL_HANDLER
	if(!iscarbon(source) || source.body_position == LYING_DOWN || !prob(30))
		return
	source.slip(8, get_turf(source), SLIDE|GALOSHES_DONT_HELP)

/datum/element/raptor_food
/datum/element/raptor_food/Attach(datum/target, attack_modifier = 1, growth_modifier = 0)
	return ..()

/datum/element/haunted
/datum/element/haunted/Attach(datum/target, haunt_color = null)
	return ..()

/datum/element/squish
/datum/element/squish/Attach(datum/target, duration)
	return ..()

/datum/element/bane
/datum/element/bane/Attach(datum/target, target_type, damage_multiplier = 1)
	return ..()

/datum/element/quality_food_ingredient
/datum/element/quality_food_ingredient/Attach(datum/target, complexity)
	return ..()

// Пустышки мобов, которых используют сразу несколько рыб
/mob/living/basic
	parent_type = /mob/living/simple_animal

/mob/living/basic/frog
	parent_type = /mob/living/simple_animal/hostile/retaliate/frog
/mob/living/basic/frog/rare
	parent_type = /mob/living/simple_animal/hostile/retaliate/frog
/mob/living/basic/carp
	parent_type = /mob/living/simple_animal/hostile/carp
/mob/living/basic/carp/advanced
	parent_type = /mob/living/simple_animal/hostile/carp
/mob/living/basic/carp/mega
	parent_type = /mob/living/simple_animal/hostile/carp/megacarp
/mob/living/basic/mining/lobstrosity
	parent_type = /mob/living/simple_animal/hostile/asteroid/lobstrosity
/mob/living/basic/mining/lobstrosity/juvenile
	parent_type = /mob/living/simple_animal/hostile/asteroid/lobstrosity
/mob/living/basic/mining/lobstrosity/lava
	parent_type = /mob/living/simple_animal/hostile/asteroid/lobstrosity/lava
/mob/living/basic/mining/lobstrosity/juvenile/lava
	parent_type = /mob/living/simple_animal/hostile/asteroid/lobstrosity/lava
/mob/living/basic/axolotl
/mob/living/basic/skeleton
/mob/living/basic/stickman
/mob/living/basic/spaceman
/mob/living/basic/spaceman/soulman
	parent_type = /mob/living/carbon/human

// Пустышки предметов
/obj/item/food/meat/slab/rawcrab
/obj/item/food/meat/slab/human/mutant/zombie
/obj/item/food/meat/slab/human/mutant/slime
/obj/item/food/meat/cutlet/plain/human
/obj/item/food/nugget/fish
/obj/item/food/badrecipe
/obj/item/food/badrecipe/moldy/bacteria
/obj/item/stock_parts/power_store/cell/lead
/obj/item/aquarium_prop
/obj/item/storage/toolbox/mechanical/old/cleaner
/obj/item/organ/ears/babbelfish
/obj/item/organ/eyes/snail
/obj/item/reagent_containers/cup/fish_feed
	name = "fish feed"
	desc = "Дозатор питательных рыбьих хлопьев."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/supplies.dmi'
	icon_state = "fish_feed"
	w_class = WEIGHT_CLASS_SMALL
	volume = 50

/obj/item/reagent_containers/cup/fish_feed/Initialize(mapload)
	. = ..()
	create_reagents(50, INJECTABLE)
	reagents.add_reagent(/datum/reagent/consumable/nutriment, 50)


