/obj/item/fish/starfish/chrystarfish
	name = "chrystarfish"
	fish_id = "chrystarfish"
	desc = "Вот что бывает, когда космозвезда заберётся в блюспейс-отсек гипердвигателя. Очень колюче и опасно."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "chrystarfish"
	force = 12
	sharpness = SHARP_POINTY
	wound_bonus = -10
	exposed_wound_bonus = 15
	armour_penetration = 6
	demolition_mod = 1.2
	throwforce = 11
	throw_range = 8
	throw_speed = 4
	embed_type = /datum/embedding/chrystarfish
	attack_verb_continuous = list("stabs", "jabs")
	attack_verb_simple = list("stab", "jab")
	hitsound = SFX_SHATTER
	pickup_sound = 'sound/items/handling/materials/glass_pick_up.ogg'
	drop_sound = 'sound/items/handling/materials/glass_drop.ogg'

	sprite_width = 7
	sprite_height = 9

	average_size = 40
	average_weight = 1500
	food = /datum/reagent/bluespace
	feeding_frequency = 10 MINUTES
	max_integrity = 100
	death_text = "%SRC раскалывается на осколки!"
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	fillet_type = /obj/item/stack/ore/bluespace_crystal
	num_fillets = 3
	stable_population = 3
	compatible_types = list(/obj/item/fish/starfish)
	fish_traits = list(/datum/fish_trait/antigrav)
	beauty = FISH_BEAUTY_EXCELLENT
	fish_movement_type = /datum/fish_movement/accelerando
	fishing_difficulty_modifier = 15
	favorite_bait = list(/obj/item/stack/ore/bluespace_crystal)
	// бьётся током на блюспейс-энергии
	electrogenesis_power = 9 MEGA JOULES

// По сути сюрикен - часто застревает и телепортирует, если не остановиться и не вытащить. Зато урона совсем немного.
/datum/embedding/chrystarfish
	pain_mult = 1
	embed_chance = 85
	fall_chance = 1.5
	pain_chance = 9
	impact_pain_mult = 1
	remove_pain_mult = 2
	rip_time = 1.5 SECONDS
	ignore_throwspeed_threshold = TRUE // формой вышел сюрикен
	jostle_chance = 15
	jostle_pain_mult = 1

/datum/embedding/chrystarfish/jostle_effects()
	do_teleport(owner, get_turf(owner), 3, asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)
	owner.visible_message(span_danger("[owner] teleports as [parent] jostles inside of [owner.p_them()]!"))

/obj/item/fish/starfish/chrystarfish/set_status(new_status, silent)
	. = ..()
	if(new_status == FISH_DEAD)
		if(fillet_type)
			new fillet_type(get_turf(src))
		playsound(src, SFX_SHATTER, 50)
		qdel(src)

/obj/item/fish/starfish/chrystarfish/add_emissive()
	return

/obj/item/fish/starfish/chrystarfish/get_base_edible_reagents_to_add()
	var/list/return_list = ..()
	return_list[/datum/reagent/bluespace] = 5
	return return_list

/obj/item/fish/starfish/chrystarfish/flinch_on_eat(mob/living/eater, mob/living/feeder)
	if(status != FISH_ALIVE)
		return
	to_chat(feeder, span_warning("[src] slips out of the spacetime in pain!"))

	var/tp_range = 6 * clamp(weight/average_weight, 3, 9) // обычно 6, с поправкой на вес рыбы
	// телепортирует себя, если лежит на тайле, иначе свой контейнер - чем бы он ни был
	do_teleport(isturf(loc) ? src : loc, get_turf(feeder), tp_range, asoundin = 'sound/effects/phasein.ogg', channel = TELEPORT_CHANNEL_BLUESPACE)

/obj/item/fish/starfish/chrystarfish/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] проглатывает [src] целиком! Похоже, это попытка свести счёты с жизнью!"))
	forceMove(user)
	// буквально всё
	for(var/obj/thing in user.get_contents())
		if(QDELETED(thing) || istype(thing, /obj/item/bodypart/chest))
			continue // гиб нам не нужен
		stoplag(0.1 SECONDS)
		playsound(src, 'sound/effects/phasein.ogg', 15, TRUE)
		do_teleport(thing, get_turf(user), 2, asoundin = null, channel = TELEPORT_CHANNEL_BLUESPACE)
	qdel(src)
	return MANUAL_SUICIDE

// Чтобы первые два сообщения не спамили на каждом обновлении.
#define PATIENCE_FLINCH "PATIENCE_FLINCH"
#define PATIENCE_UNCOMFY "PATIENCE_UNCOMFY"

/obj/item/fish/dolphish
	name = "walro-dolphish"
	fish_id = "walro-dolphish"
	desc = "Странный кровожадный сверххищник из-за грани. Мощное оружие, но терпеть не может, когда его держат."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/wide.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "dolphish"
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_righthand.dmi'
	force = 19
	sharpness = SHARP_POINTY
	wound_bonus = -5
	exposed_wound_bonus = 20
	armour_penetration = 12
	block_chance = 33
	throwforce = 7
	throw_range = 4
	attack_verb_continuous = list("bites", "impales", "rams")
	attack_verb_simple = list("bite", "impale", "ram")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_sound = 'sound/items/weapons/parry.ogg'
	drop_sound = 'modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_drop1.ogg'
	pickup_sound = SFX_FISH_PICKUP
	sound_vary = TRUE

	base_pixel_w = -16
	pixel_w = -16
	sprite_width = 13
	sprite_height = 9

	required_fluid_type = AQUARIUM_FLUID_AIR
	required_temperature_min = BODYTEMP_COLD_DAMAGE_LIMIT // прямо как у человека, странновато...
	required_temperature_max = BODYTEMP_HEAT_DAMAGE_LIMIT
	food = /datum/reagent/blood
	max_integrity = 800 // высший хищник, потому и живучий
	integrity_failure = 0.25
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	fillet_type = /obj/item/food/fishmeat/fish_tail
	num_fillets = 1
	stable_population = 3
	fish_traits = list(/datum/fish_trait/wary, /datum/fish_trait/carnivore, /datum/fish_trait/necrophage, /datum/fish_trait/predator, /datum/fish_trait/territorial, /datum/fish_trait/stinger)
	fish_movement_type = /datum/fish_movement/choppy
	fishing_difficulty_modifier = 30
	favorite_bait = list()
	disliked_bait = list()
	average_size = 150
	average_weight = 2750
	weight_size_deviation = 0.5
	safe_air_limits = list(
		/datum/gas/oxygen = list(12, 100),
		/datum/gas/nitrogen,
		/datum/gas/carbon_dioxide = list(0, 10),
	)
	min_pressure = HAZARD_LOW_PRESSURE
	max_pressure = HAZARD_HIGH_PRESSURE
	beauty = FISH_BEAUTY_GREAT
	/// Потолок терпения для переменной ниже.
	var/max_patience = 20
	/// Сколько ещё рыба будет терпеть, прежде чем цапнуть владельца.
	var/patience = 20
	/// Хранит последний эффект, чтобы он не повторялся
	var/last_effect

/obj/item/fish/dolphish/get_force_rank()
	var/multiplier = 1
	switch(w_class)
		if(WEIGHT_CLASS_TINY)
			multiplier = 0.35
		if(WEIGHT_CLASS_SMALL)
			multiplier = 0.5
		if(WEIGHT_CLASS_NORMAL)
			multiplier = 0.75
		// громоздкий считаем средним
		if(WEIGHT_CLASS_HUGE)
			multiplier = 1.15
		if(WEIGHT_CLASS_GIGANTIC)
			multiplier = 1.35

	if(status == FISH_DEAD)
		multiplier -= 0.35 // мёртвая рыба заметно слабее

	force *= multiplier
	attack_speed *= multiplier
	demolition_mod *= multiplier
	block_chance *= multiplier
	armour_penetration *= multiplier
	wound_bonus *= multiplier
	exposed_wound_bonus *= multiplier

/obj/item/fish/dolphish/do_fish_process(seconds_per_tick)
	. = ..()
	if(QDELETED(src))
		return

	var/patience_reduction = 1

	var/turf/onturf = get_turf(loc)
	// смотрим, чем там дышат
	var/datum/gas_mixture/turf_gasmix = onturf.return_air()
	// любит воду и сонную химию, от неё терпение тает
	if(turf_gasmix.gases[/datum/gas/water_vapor] && turf_gasmix.gases[/datum/gas/water_vapor][MOLES] >= 5)
		patience_reduction *= 0.5
	if(turf_gasmix.gases[/datum/gas/nitrous_oxide] && turf_gasmix.gases[/datum/gas/nitrous_oxide][MOLES] >= 5)
		patience_reduction *= 0.25
	if(turf_gasmix.gases[/datum/gas/healium] && turf_gasmix.gases[/datum/gas/healium][MOLES] >= 5)
		patience_reduction *= 0.1

	if(!ismob(loc))
		// деление на множитель даёт прирост. довольный дольфиш быстрее копит терпение
		var/patience_bonus = (1 / patience_reduction)
		patience = clamp(patience + patience_bonus * seconds_per_tick, 0, max_patience)
		return

	var/mob/living/moc = loc
	if(moc.mob_biotypes & MOB_AQUATIC)
		patience_reduction *= 0.6
	if(HAS_TRAIT(moc, TRAIT_IS_WET))
		patience_reduction *= 0.6

	patience = clamp(patience - (patience_reduction * seconds_per_tick), 0, max_patience)

	switch(patience)
		if(0)
			// тут без проверки - пусть кусает, когда терпение на нуле
			moc.visible_message(span_bolddanger("[src] bites directly into [moc] and squirms away from [moc.p_their()] grasp!"), span_userdanger("[src] sinks its fangs into you!!"))
			moc.apply_damage(force, BRUTE, moc.get_active_hand(), wound_bonus = wound_bonus, sharpness = sharpness)
			forceMove(moc.drop_location())
			moc.painful_scream()
			patience = max_patience
			playsound(src, hitsound, 45)
		if(1 to 10)
			// и последнее предупреждение без проверки - забавно же
			visible_message(span_bolddanger("[src] thrashes against [moc]'s grasp!"))
			moc.shake_up_animation()
		if(10 to 15)
			if(last_effect == PATIENCE_FLINCH)
				return
			visible_message(span_danger("[src] flinches away from [moc]!"))
			moc.shake_up_animation()
			last_effect = PATIENCE_FLINCH
		if(15 to 20)
			if(last_effect == PATIENCE_UNCOMFY)
				return
			visible_message(span_notice("[src] seems uncomfortable in [moc]'s grasp."))
			last_effect = PATIENCE_UNCOMFY

	return

#undef PATIENCE_FLINCH
#undef PATIENCE_UNCOMFY

/obj/item/fish/dolphish/pet_fish(mob/living/user, in_aquarium)
	user.visible_message(
		span_warning("[user] tries to pet [src], but it sinks its fangs into [user.p_their()] hand!"),
		span_warning("You try to pet [src], but it sinks its fangs into your hand!"),
		vision_distance = DEFAULT_MESSAGE_RANGE - 3,
		)
	user.apply_damage(force, BRUTE, user.get_active_hand(), wound_bonus = wound_bonus, sharpness = sharpness)
	if(!in_aquarium)
		forceMove(user.drop_location())
	user.painful_scream()

/obj/item/fish/flumpulus
	name = "flumpulus"
	fish_id = "flumpulus"
	desc = "С трудом верится, что это вообще считается рыбой. Почему-то кажется, что ею можно отлично смягчить падение."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "flumpulus"
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_righthand.dmi'
	attack_verb_continuous = list("splats", "splorts")
	attack_verb_simple = list("splat", "splort")

	sprite_width = 10
	sprite_height = 9

	required_fluid_type = AQUARIUM_FLUID_AIR
	required_temperature_min = 0
	required_temperature_max = INFINITY
	food = /datum/reagent/consumable/nutriment/fat
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	fillet_type = /obj/item/food/meat/slab/human/mutant/slime
	num_fillets = 2
	stable_population = 2
	fish_traits = list()
	fish_movement_type = /datum/fish_movement/slow
	fishing_difficulty_modifier = 22
	favorite_bait = list()
	disliked_bait = list()
	// вдвое крупнее, но вдвое легче
	average_size = 100
	average_weight = 500
	weight_size_deviation = 0.6
	safe_air_limits = list(
		/datum/gas/nitrogen = list(0, 100),
	)
	min_pressure = 0
	max_pressure = HAZARD_HIGH_PRESSURE
	beauty = FISH_BEAUTY_UGLY

/obj/item/fish/flumpulus/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] проглатывает [src] целиком! Похоже, это попытка свести счёты с жизнью!"))
	forceMove(user)
	. = MANUAL_SUICIDE
	for(var/i in 1 to rand(5, 15))
		addtimer(CALLBACK(src, PROC_REF(flump_attack), user), 0.4 SECONDS * i)
		user.death()

/obj/item/fish/flumpulus/proc/flump_attack(mob/living/user)
	var/obj/item/organ/eyes/eyes = user.get_organ_slot(ORGAN_SLOT_EYES)
	var/obj/item/organ/eyes/new_eyes = pick(list(/obj/item/organ/eyes/snail, /obj/item/organ/eyes/night_vision/mushroom))
	new_eyes = new new_eyes(user)
	new_eyes.Insert(user)
	playsound(user, 'sound/effects/cartoon_sfx/cartoon_pop.ogg', 50, TRUE)
	user.visible_message("[user]'s [eyes ? eyes : "eye holes"] suddenly sprout stalks and turn into [new_eyes]!")
	ASYNC
		user.emote("scream")
		eyes.throw_at(get_edge_target_turf(user, pick(GLOB.alldirs)), rand(1, 10), rand(1, 10))
		sleep(5 SECONDS)
		if(!QDELETED(eyes))
			eyes.visible_message(span_danger("[eyes] rapidly turn to dust."))
			eyes.dust()

/obj/item/fish/flumpulus/get_base_edible_reagents_to_add()
	var/list/return_list = ..()
	//return_list[/datum/reagent/flumpulus_extract] = 10
	return_list[/datum/reagent/medicine/oculine/flumpuline] = 10
	return return_list

/obj/item/fish/flumpulus/intercept_zImpact(list/falling_movables, levels)
	. = ..()
	if(status == FISH_DEAD)
		return .

	for(var/mob/living/fallen_mob in falling_movables)
		visible_message(span_danger("[src] flattens like a pancake as [fallen_mob] lands on top of it!"))
		damage_fish(max_integrity * integrity_failure * 0.9) // вот такой он "прочный"
		AddElement(/datum/element/squish, 15 SECONDS)
		fallen_mob.Paralyze(0.5 SECONDS)
		playsound(src, 'sound/effects/cartoon_sfx/cartoon_splat.ogg', 75)

	return FALL_INTERCEPTED | FALL_NO_MESSAGE

/obj/item/fish/gullion
	name = "gullion"
	fish_id = "gullion"
	desc = "Эта кристаллическая рыба - одна из двух известных кремниевых форм жизни."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "gullion"
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_righthand.dmi'
	attack_verb_continuous = list("stabs", "jabs")
	attack_verb_simple = list("stab", "jab")
	hitsound = SFX_DEFAULT_FISH_SLAP
	pickup_sound = 'sound/items/handling/materials/glass_pick_up.ogg'
	drop_sound = 'sound/items/handling/materials/glass_drop.ogg'
	sprite_width = 7
	sprite_height = 5

	food = /datum/reagent/silicon
	feeding_frequency = 30 SECONDS
	max_integrity = 320
	death_text = "%SRC застывает."
	random_case_rarity = FISH_RARITY_GOOD_LUCK_FINDING_THIS
	fillet_type = /obj/item/stack/sheet/mineral/diamond
	num_fillets = 2
	stable_population = 3
	fish_traits = list(/datum/fish_trait/heavy, /datum/fish_trait/parthenogenesis) // по сути живая алмазная ферма
	beauty = FISH_BEAUTY_EXCELLENT
	fish_movement_type = /datum/fish_movement/slow
	favorite_bait = list(/obj/item/stack/sheet/mineral/diamond)
	fishing_difficulty_modifier = 22
	average_size = 30
	average_weight = 2000
	weight_size_deviation = 0.3
	safe_air_limits = list(
		/datum/gas/oxygen = list(0, 2), // кислород терпеть не может
		/datum/gas/water_vapor,
	)
	required_fluid_type = AQUARIUM_FLUID_SULPHWATEVER
	required_temperature_min = 0
	required_temperature_max = BODYTEMP_HEAT_DAMAGE_LIMIT
	min_pressure = HAZARD_LOW_PRESSURE
	max_pressure = WARNING_HIGH_PRESSURE

/obj/item/fish/gullion/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] проглатывает [src] целиком! Похоже, это попытка свести счёты с жизнью!"))
	forceMove(user)
	var/datum/gas_mixture/environment = user.loc.return_air()
	var/oxygen_in_air = locate(/datum/gas/oxygen) in environment.gases
	if(!oxygen_in_air || (status == FISH_DEAD))
		visible_message(span_suicide("[user] давится и умирает! (От рыбы или от нехватки воздуха?)"))
		return OXYLOSS

	user.petrify(statue_timer = INFINITY)
	user.death()
	visible_message(span_suicide("Кожа [user] превращается в кварц при контакте с кислородом!"))
	qdel(src)
	return MANUAL_SUICIDE

// (Ещё одна) причина не рыбачить в разломах.
// Эта штука - настоящая чума. Летает повсюду и травит всех, в кого попадёт.
// Хуже того, ей плевать на среду, и она всё равно возрождается.
/obj/item/fish/mossglob
	name = "mossglob"
	fish_id = "mossglob"
	desc = "Этот жуткий злобный и почти неубиваемый комок мха - вероятно, месть природы рыбакам."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "mossglob"
	lefthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/mob/inhands/fish_righthand.dmi'
	attack_verb_continuous = list("stings", "pricks")
	attack_verb_simple = list("sting", "prick")
	force = 11
	damtype = TOX
	sharpness = SHARP_POINTY
	throwforce = 9
	throw_range = 7
	hitsound = SFX_ALT_FISH_SLAP

	sprite_width = 12
	sprite_height = 13

	max_integrity = 750
	integrity_failure = 0.33
	death_text = "%SRC разлагается."
	random_case_rarity = FISH_RARITY_NOPE
	// собрано вручную, чтобы стать твоим злейшим врагом
	fish_traits = list(
		/datum/fish_trait/wary, /datum/fish_trait/nocturnal, /datum/fish_trait/emulsijack,
		/datum/fish_trait/yucky, /datum/fish_trait/lubed, /datum/fish_trait/revival,
		/datum/fish_trait/toxin_immunity, /datum/fish_trait/hallucinogenic,
		/datum/fish_trait/stinger, /datum/fish_trait/toxic_barbs,
	)
	beauty = FISH_BEAUTY_DISGUSTING
	fish_movement_type = /datum/fish_movement/slow // зато очень лёгкая добыча!
	fishing_difficulty_modifier = -35
	favorite_bait = list(/obj/item/food/badrecipe)
	average_size = 150
	average_weight = 5000
	required_fluid_type = AQUARIUM_FLUID_ANY_WATER
	required_temperature_min = 0
	required_temperature_max = INFINITY
	min_pressure = 0
	max_pressure = INFINITY
	safe_air_limits = list()
	fillet_type = /obj/item/food/badrecipe/moldy/bacteria
	stable_population = 2

/obj/item/fish/mossglob/Initialize(mapload, apply_qualities)
	. = ..()
	AddElement(/datum/element/haunted, COLOR_GREEN)

/obj/item/fish/mossglob/set_status(new_status, silent)
	. = ..()
	if(new_status == FISH_DEAD)
		RemoveElement(/datum/element/haunted, COLOR_GREEN)
	else if(new_status == FISH_ALIVE)
		AddElement(/datum/element/haunted, COLOR_GREEN)

/obj/item/fish/mossglob/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] засовывает руку глубоко в [src]! Похоже, [user] предлагает себя в жертву!"))
	user.drop_everything()
	set_status(FISH_ALIVE)
	transform = transform.Scale(1.15, 1.15)
	update_size_and_weight(new_size = size * 1.15, new_weight = weight * 1.15)
	visible_message(span_suicide("[user] поглощён [src]!"))
	objectify(user, src)
	return MANUAL_SUICIDE_NONLETHAL

/obj/item/fish/mossglob/get_force_rank()
	var/multiplier = 1
	switch(w_class)
		if(WEIGHT_CLASS_TINY)
			multiplier = 0.35
		if(WEIGHT_CLASS_SMALL)
			multiplier = 0.5
		if(WEIGHT_CLASS_NORMAL)
			multiplier = 0.75
		if(WEIGHT_CLASS_BULKY)
			multiplier = 0.85
		// огромный считаем средним
		if(WEIGHT_CLASS_GIGANTIC)
			multiplier = 1.15

	if(status == FISH_DEAD)
		multiplier -= 0.35 // мёртвая рыба заметно слабее

	force *= multiplier
	attack_speed *= multiplier
	demolition_mod *= multiplier
	block_chance *= multiplier
	armour_penetration *= multiplier

// Вавилон-рыбы - психические "хищники". Физически не атакуют, зато давят добычу аурой и доедают трупы.
// А умирая, издают жуткий вопль, который оглушает и изматывает всех рядом - рыбу в первую очередь.
/obj/item/fish/babbelfish
	name = "babbelfish"
	fish_id = "babbelfish"
	desc = "Вавилон-рыбы пугают и видом, и психикой: их вопль бьёт по разуму окружающих. На людей почти не действует, а рыбу убивает."
	icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	dedicated_in_aquarium_icon = 'modular_bluemoon/fishing/icons/obj/aquarium/rift.dmi'
	icon_state = "babbelfish"
	force = 7
	damtype = BRAIN
	attack_verb_continuous = list("screeches", "shrieks")
	attack_verb_simple = list("screech", "shriek")
	hitsound = SFX_DEFAULT_FISH_SLAP // todo - записать настоящий вопль
	sound_vary = TRUE

	sprite_width = 11
	sprite_height = 13

	death_text = span_big(span_alertalien("%SRC emits a horrendous wailing as it perishes!"))
	random_case_rarity = FISH_RARITY_NOPE
	max_integrity = 500
	average_size = 30
	average_weight = 2000
	fillet_type = /obj/item/food/fishmeat/quality
	num_fillets = 2
	stable_population = 3
	fish_traits = list(
		/datum/fish_trait/wary, /datum/fish_trait/picky_eater, /datum/fish_trait/heavy,
		/datum/fish_trait/emulsijack/psychic, /datum/fish_trait/necrophage,
	)
	beauty = FISH_BEAUTY_NULL // жуткая, но при этом внушающая благоговение
	fish_movement_type = /datum/fish_movement/slow
	fishing_difficulty_modifier = 15
	favorite_bait = list(/obj/item/organ/ears)
	var/mob/living/moron_inside
	/// Не даёт воплю запускать цепную реакцию среди других вавилон-рыб.
	var/suppress_wail = FALSE

// Когда деморализаторы перестанут быть намертво захардкожены под Синдикат, этой рыбе стоит их выдать

/obj/item/fish/babbelfish/examine_more(mob/user)
	. = ..()
	. += span_smallnoticeital(
		"“Sorry, you <i>speak Anglish</i>, how is that possible?\n\
		“I speak many languages,” the pile of octopuses replied. It was hard to get a handle on where it was speaking from, or how, and that was with me using vibration magic to check. “Those are babel fish in front of you. They're very rare, and available for a good trade.”\n\
		“Babel fish,” I said, pointing down at the tank with the bright yellow fish. “Meaning … fish capable of letting you hear any language?” That still wouldn't have explained how the octopus pile spoke Anglish.\n\
		“Ah, no, my apologies, I'm afraid not,” they replied, wiggling some tentacles. “These fish, if put into your ear, will make everything another person says sound like gibberish.”\n\
		“Ah,” I replied. “Babble fish. And if two people with babble fish in their ears talk to each other, they're suddenly mutually intelligible?”\n\
		The octopus pile swayed from side to side. “No.”\n\
		“I don't know your business,” replied the octopus pile. “Why <i>do</i> you want them?”\n\
		I looked down at the fish. “Uh,” I said. “I guess … it would help to keep me from hearing things I didn't want to hear?”\n\
		They burst into applause, which in this case was a bunch of tentacles wetly slapping against equally wet flesh. “Very good! I hadn't thought of that.”\n\
		“But then why,” I began, then thought better of it. “Alright, I''ll buy one. <i>But</i>, you need to explain to me how you speak Anglish.”")

// тут задумана занятная механика самоубийства
/obj/item/fish/babbelfish/suicide_act(mob/living/user)
	if(status == FISH_DEAD)
		if(moron_inside)
			visible_message(span_suicide("[user] подносит [src] к губам, но [src] уже полон!"))
			return SHAME
		visible_message(span_suicide("[user] подносит [src] к губам, но психический след [src] затягивает [user] внутрь!"))
		user.drop_everything()
		objectify(user, src)
		user.fully_replace_character_name(null, name) // берём имя рыбы
		set_status(FISH_ALIVE) // ВОССТАНЬ, тебе говорят!
		moron_inside = user
		RegisterSignal(src, COMSIG_FISH_STATUS_CHANGED, PROC_REF(fishes_die_twice))
		RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(check_loc))
		return MANUAL_SUICIDE_NONLETHAL // вдруг они всё-таки вырвутся

	visible_message(span_suicide("[user] подносит [src] к губам! Похоже, [user] собирается что-то сказать!"))
	var/psychic_speech = tgui_input_text(user, message = "Say something!", title = "What are your last words?", timeout = 15 SECONDS)
	if(!psychic_speech || !(src in user.get_contents()))
		user.say("Err, umm... uhh... erm...", forced = "blustering like a moron due to babbelfish suicide")
		visible_message(span_suicide("[user] умирает от стыда!"))
		return OXYLOSS

	voice_of_god(psychic_speech, user, list("big", "alertalien"), base_multiplier = 5, include_speaker = TRUE)
	psy_wail()
	user.adjust_organ_loss(ORGAN_SLOT_BRAIN, INFINITY, INFINITY, ORGAN_SLOT_BRAIN)
	user.death()
	return MANUAL_SUICIDE


/obj/item/fish/babbelfish/proc/fishes_die_twice(datum/source)
	SIGNAL_HANDLER
	if(QDELETED(moron_inside))
		release_moron()
		return
	if(status == FISH_DEAD)
		INVOKE_ASYNC(moron_inside, TYPE_PROC_REF(/mob/living, death))
	else if(status == FISH_ALIVE)
		INVOKE_ASYNC(moron_inside, TYPE_PROC_REF(/mob/living, revive), HEAL_ALL)

/obj/item/fish/babbelfish/proc/check_loc(datum/source)
	SIGNAL_HANDLER
	if(moron_inside?.loc == src)
		return
	release_moron()

/obj/item/fish/babbelfish/proc/release_moron()
	UnregisterSignal(src, COMSIG_FISH_STATUS_CHANGED)
	if(moron_inside)
		UnregisterSignal(moron_inside, COMSIG_MOVABLE_MOVED)
	moron_inside = null

/obj/item/fish/babbelfish/Destroy()
	release_moron()
	return ..()

/obj/item/fish/babbelfish/set_status(new_status, silent)
	. = ..()
	if(new_status != FISH_DEAD)
		suppress_wail = FALSE
		damtype = BRAIN
		return
	psy_wail()
	damtype = BRUTE

/obj/item/fish/babbelfish/proc/psy_wail()
	if(suppress_wail)
		return
	manual_emote("wails!")
	playsound(src, 'modular_bluemoon/fishing/sound/mobs/non-humanoids/fish/fish_psyblast.ogg', 100)
	var/list/mob/living/mobs_in_range = get_hearers_in_range(7, src)
	for(var/mob/living/screeched in mobs_in_range)
		if(screeched.can_block_magic(MAGIC_RESISTANCE_MIND))
			to_chat(screeched, span_notice("You resist the psychic wail!"))
			continue
		var/power = 1
		if(HAS_TRAIT(screeched, TRAIT_DEAF)) // глухому чуть легче, но эффект всё равно психический
			power *= 0.5
		var/affect_time = 15 SECONDS * power
		// вот это реально разносит
		screeched.Knockdown(affect_time * 0.1)
		screeched.adjust_disgust(affect_time)
		screeched.adjust_stutter(affect_time)
		screeched.adjust_slurring(affect_time)
		screeched.adjust_dizzy(affect_time)
		screeched.adjust_staggered(affect_time)
		screeched.adjust_jitter(affect_time)
		screeched.adjust_confusion(affect_time)
		screeched.adjust_hallucinations(affect_time)
		screeched.adjust_eye_blur(affect_time)
		if(iscarbon(screeched))
			var/mob/living/carbon/carbon_screeched = screeched
			carbon_screeched.vomit(MOB_VOMIT_MESSAGE)
			carbon_screeched.adjust_organ_loss(ORGAN_SLOT_BRAIN, 10)

	var/affected = 0
	for(var/obj/item/fish/fishie in range(7, src))
		if(HAS_TRAIT(fishie, TRAIT_RESIST_PSYCHIC))
			continue
		if(fishie.status == FISH_DEAD)
			continue
		if(istype(fishie, /obj/item/fish/babbelfish))
			var/obj/item/fish/babbelfish/other_babbelfish = fishie
			other_babbelfish.suppress_wail = TRUE
		fishie.set_status(FISH_DEAD)
		affected++
	if(affected)
		visible_message(span_bolddanger("[src]'s wail kills [affected] fish nearby!")) // м-м-м-м-м, МОНСТР УБИЙСТВО

/obj/item/fish/babbelfish/attack_hand(mob/living/user, list/modifiers)

	if(loc != user)
		return ..()

	if((user.usable_hands < 2) && !HAS_TRAIT(user, TRAIT_STRENGTH))
		to_chat(user, span_notice("[src] is too dense to twist apart with only one hand."))
		return

	to_chat(user, span_danger("You start pulling and twisting [src], trying to split it down the middle..."))
	if(!do_after(user, 5 SECONDS, src))
		return

	playsound(get_turf(user), 'sound/effects/wounds/crack1.ogg', 60)
	set_status(FISH_DEAD)
	var/cracked = new /obj/item/organ/ears/babbelfish(user)
	user.put_in_hands(cracked)
	qdel(src)

/** Эти уши дают потрясающий сверхъестественный слух, но ломают знание языков.
 * Возможны три исхода.
 * Ты говоришь на всех языках, но не понимаешь ни одного. Даже свои слова звучат бессмыслицей.
 * Ты понимаешь все языки, но не можешь говорить ни на одном. Только "странные звуки".
 * Ты понимаешь и говоришь на всех языках. Редкий случай.
 * И всё это ради того, чтобы стать куратором. Глупо, да.
*/
/obj/item/organ/ears/babbelfish
	name = "split babbelfish halves"
	icon_state = "babbearfish"
	desc = "Обе половины вавилон-рыбы после того, как их разорвали. Легенды говорят, что вставка этих половин раскрывает психический потенциал."
	organ_traits = list(TRAIT_XRAY_HEARING, TRAIT_GOOD_HEARING)

	healing_factor = STANDARD_ORGAN_HEALING * 5
	decay_factor = 0

	low_threshold_passed = span_noticealien("Psychic whispers make it a bit difficult to hear sometimes..")
	now_failing = span_noticealien("Psychic noise is overcrowding your senses!")
	now_fixed = span_noticealien("The psychic noise starts to fade.")
	low_threshold_cleared = span_noticealien("The whispers leave you alone.")

	bang_protect = EAR_PROTECTION_VACUUM
	damage_multiplier = 0.1
	visual = TRUE
	/// Оверлей для спрайта моба. Настоящие оверлеи органов - кошмар, которым невозможно пользоваться
	var/datum/bodypart_overlay/simple/babbearfish/babbel_overlay
	var/bound_component
	var/datum/language_holder/removal_holder

/**
 * Оверлей части тела для вавилон-рыбы.
 * Нужна только иконка (и иногда её скрыть), так что мутантный вариант излишен и расточителен.
 * Он ломает всё остальное, поэтому делаем простой. А органы такого не умеют, так что просто налепим наспех.
 */
/datum/bodypart_overlay/simple/babbearfish
	icon_state = "babbearfish"

/datum/bodypart_overlay/simple/babbearfish/can_draw_on_bodypart(obj/item/bodypart/bodypart_owner)
	. = ..()
	return . && !(bodypart_owner.owner?.obscured_slots & HIDEEARS)

/obj/item/organ/ears/babbelfish/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/noticable_organ, "%PRONOUN_They %PRONOUN_have weird, deep-rooted obsidian tubes sticking out of where their ears should be.")
	RegisterSignal(src, COMSIG_ORGAN_INSERTED, PROC_REF(on_organ_inserted))
	RegisterSignal(src, COMSIG_ORGAN_REMOVED, PROC_REF(on_organ_removed))
	babbel_overlay = new()
	removal_holder = new(src)

/obj/item/organ/ears/babbelfish/proc/on_organ_inserted(datum/source)
	SIGNAL_HANDLER
	if(owner)
		on_mob_insert(owner, TRUE, NONE)

/obj/item/organ/ears/babbelfish/proc/on_organ_removed(datum/source)
	SIGNAL_HANDLER
	if(owner)
		on_mob_remove(owner, TRUE, NONE)

/obj/item/organ/ears/babbelfish/Destroy()
	QDEL_NULL(babbel_overlay)
	QDEL_NULL(removal_holder)
	QDEL_NULL(bound_component)
	. = ..()

/obj/item/organ/ears/babbelfish/attack(mob/living/target_mob, mob/living/user, list/modifiers, list/attack_modifiers)
	if(!target_mob)
		return ..()
	var/obj/item/organ/ears/ears = target_mob.get_organ_slot(ORGAN_SLOT_EARS)
	if(!ears)
		to_chat(user, span_notice(target_mob == user ? "У вас нет ушей, куда можно засунуть [src]!" : "У [target_mob] нет ушей, куда можно засунуть [src]!"))
		return ..()

	to_chat(user, span_danger(target_mob == user ? "Вы начинаете заталкивать [src] себе в уши. Наверное, это плохая идея." : "Вы начинаете заталкивать [src] в уши [target_mob]. Наверное, это плохая идея."))
	if(!do_after(user, 2.5 SECONDS * (target_mob == user ? 1 : 3), target_mob))
		return

	target_mob.apply_damage(25, BRUTE, ears.zone)
	to_chat(user, span_notice(target_mob == user ? "Уши вгрызаются в вашу голову, занимая место прежних ушей!" : "Уши вгрызаются в голову [target_mob], занимая место прежних ушей!"))
	playsound(target_mob, 'sound/effects/magic/demon_consume.ogg', vol = 100, falloff_exponent = 2, vary = TRUE)
	// заслужил плохой мудлет
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	Insert(target_mob, special = TRUE, drop_if_replaced = TRUE)

/obj/item/organ/ears/babbelfish/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	bound_component = organ_owner.AddComponent(
		/datum/component/anti_magic, \
		antimagic_flags = MAGIC_RESISTANCE_MIND, \
		inventory_flags = null, \
		charges = maxHealth * 0.1, \
		block_magic = CALLBACK(src, PROC_REF(on_drain_magic)), \
		expiration = CALLBACK(src, PROC_REF(on_expire)), \
	)

	if(HAS_MIND_TRAIT(organ_owner, TRAIT_TOWER_OF_BABEL))
		to_chat(organ_owner, span_noticealien("You don't feel that much different this time. Looks like your brain has attuned to the [src]'s effect."))
		return

	if(!removal_holder)
		removal_holder = new(src)
	removal_holder.copy_languages(organ_owner.get_language_holder(), LANGUAGE_BABEL)

	switch(rand(1, 100))
		if(1 to 45)
			// не понимает ничего
			organ_owner.remove_all_languages(source = LANGUAGE_ALL)
			// зато говорит на всём
			organ_owner.grant_all_languages(language_flags = SPOKEN_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_BABEL)
			to_chat(organ_owner, span_noticealien("You feel like you've been given the first half of a cosmic puzzle!"))
		if(46 to 90)
			// не говорит ни на одном
			organ_owner.remove_all_languages(source = LANGUAGE_ALL)
			// зато понимает всё
			organ_owner.grant_all_languages(language_flags = UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_BABEL)
			to_chat(organ_owner, span_noticealien("You feel like you've been given the second half of a cosmic puzzle!"))
		if(91 to 100)
			// джекпот, оба таланта разом
			organ_owner.grant_all_languages(language_flags = ALL, grant_omnitongue = TRUE, source = LANGUAGE_BABEL)
			to_chat(organ_owner, span_noticealien("You feel like you've been given both halves of a cosmic puzzle!"))
			to_chat(organ_owner, span_boldnicegreen("So <i>that's</i> what they said to you that one time..."))

	if(organ_owner.mind)
		ADD_TRAIT(organ_owner.mind, TRAIT_TOWER_OF_BABEL, MAGIC_TRAIT) // один бросок на разум, и хватит

/obj/item/organ/ears/babbelfish/on_mob_remove(mob/living/carbon/organ_owner, special, movement_flags)

	// откатываем всё назад
	organ_owner.remove_all_languages(source = LANGUAGE_ALL)
	organ_owner.copy_languages(removal_holder)
	to_chat(organ_owner, span_notice("You feel significantly more mundane."))
	QDEL_NULL(removal_holder)
	QDEL_NULL(bound_component)

/obj/item/organ/ears/babbelfish/proc/on_drain_magic(mob/user)
	to_chat(user, span_noticealien("Your [src] pop as they protect your mind from psychic phenomena!"))
	adjust_temporary_deafness(40 SECONDS)

/obj/item/organ/ears/babbelfish/proc/on_expire(mob/user)
	to_chat(user, span_noticealien("Your [src] suddenly burst apart!"))
	apply_organ_damage(maxHealth, maxHealth)
