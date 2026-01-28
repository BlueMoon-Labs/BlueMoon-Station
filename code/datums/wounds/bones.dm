/*
	Bones
*/
// TODO: well, a lot really, but i'd kill to get overlays and a bonebreaking effect like Blitz: The League, similar to electric shock skeletons

/*
	Base definition
*/
/datum/wound/blunt
	sound_effect = 'sound/effects/wounds/crack1.ogg'
	wound_type = WOUND_BLUNT
	wound_flags = (BONE_WOUND | ACCEPTS_GAUZE)

	/// Have we been taped?
	var/taped
	/// Have we been bone gel'd?
	var/gelled
	/// Наногель нанесён?
	var/nano_gelled // BLUEMOON ADD
	/// If we did the gel + surgical tape healing method for fractures, how many regen points we need
	var/regen_points_needed
	/// Our current counter for gel + surgical tape regeneration
	var/regen_points_current
	/// If we suffer severe head booboos, we can get brain traumas tied to them
	var/datum/brain_trauma/active_trauma
	/// What brain trauma group, if any, we can draw from for head wounds
	var/brain_trauma_group
	/// If we deal brain traumas, when is the next one due?
	var/next_trauma_cycle
	/// How long do we wait +/- 20% for the next trauma?
	var/trauma_cycle_cooldown
	/// If this is a chest wound and this is set, we have this chance to cough up blood when hit in the chest
	var/internal_bleeding_chance = 0

/*
	Overwriting of base procs
*/
/datum/wound/blunt/wound_injury(datum/wound/old_wound = null)
	if(limb.body_zone == BODY_ZONE_HEAD && severity == WOUND_SEVERITY_CRITICAL && brain_trauma_group)
		processes = TRUE
		active_trauma = victim.gain_trauma_type(brain_trauma_group, TRAUMA_RESILIENCE_WOUND)
		next_trauma_cycle = world.time + (rand(100-WOUND_BONE_HEAD_TIME_VARIANCE, 100+WOUND_BONE_HEAD_TIME_VARIANCE) * 0.01 * trauma_cycle_cooldown)

	RegisterSignal(victim, COMSIG_HUMAN_EARLY_UNARMED_ATTACK, PROC_REF(attack_with_hurt_hand))
	if(limb.held_index && victim.get_item_for_held_index(limb.held_index) && (disabling || prob(33 * severity)))
		var/obj/item/I = victim.get_item_for_held_index(limb.held_index)
		if(istype(I, /obj/item/offhand))
			I = victim.get_inactive_held_item()

		if(I && victim.dropItemToGround(I))
			var/has_pain = victim.has_pain(limb)
			var/message = has_pain \
				? span_danger("[victim] роняет [I] от болевого шока!") \
				: span_danger("[victim] роняет [I] из-за травмы!")
			var/message_self = has_pain \
				? span_warning(span_bold("Ваша изнывающая от боли [limb.ru_name] больше не может удержать [I]!")) \
				: span_warning(span_bold("Ваша [limb.ru_name] травмирована и не может удержать [I]!"))
			victim.visible_message(message, message_self, vision_distance=COMBAT_MESSAGE_RANGE)

	update_inefficiencies()

/datum/wound/blunt/remove_wound(ignore_limb, replaced)
	limp_slowdown = 0
	QDEL_NULL(active_trauma)
	if(victim)
		UnregisterSignal(victim, COMSIG_HUMAN_EARLY_UNARMED_ATTACK)
	return ..()

/datum/wound/blunt/handle_process()
	. = ..()
	if(limb.body_zone == BODY_ZONE_HEAD && severity == WOUND_SEVERITY_CRITICAL && brain_trauma_group && world.time > next_trauma_cycle)
		if(active_trauma)
			QDEL_NULL(active_trauma)
		else
			active_trauma = victim.gain_trauma_type(brain_trauma_group, TRAUMA_RESILIENCE_WOUND)
		next_trauma_cycle = world.time + (rand(100-WOUND_BONE_HEAD_TIME_VARIANCE, 100+WOUND_BONE_HEAD_TIME_VARIANCE) * 0.01 * trauma_cycle_cooldown)

	if(!regen_points_needed)
		return

	regen_points_current++
	if(prob(severity * 2))
		victim.take_bodypart_damage(rand(2, severity * 2), stamina=rand(2, severity * 2.5), wound_bonus=CANT_WOUND)
		if(prob(33))
			if(limb.is_robotic_limb())
				to_chat(victim, span_danger("Ваша гидравлика продолжает восстанавливаться, в процессе надрывая обшивку рядом!"))
			else
				var/has_pain = victim.has_pain(limb)
				if(!has_pain)
					to_chat(victim, span_big_warning("Вы ощущаете как двигаются ваши кости в теле, восстанавливаясь!"))
				else if(has_pain <= PAIN_LOW)
					to_chat(victim, span_big_warning("Вы ощущаете боль в теле, пока ваши кости восстанавливаются!"))
				else
					to_chat(victim, span_danger("Вы ощущаете острую боль в теле, пока ваши кости восстанавливаются!"))

	if(regen_points_current > regen_points_needed)
		if(!victim || !limb)
			qdel(src)
			return
		to_chat(victim, span_green("Ваша [limb.ru_name] была избавлена от перелома!"))
		remove_wound()

/// If we're a human who's punching something with a broken arm, we might hurt ourselves doing so
/datum/wound/blunt/proc/attack_with_hurt_hand(mob/M, atom/target, proximity)
	if(victim.get_active_hand() != limb || victim.a_intent == INTENT_HELP || !ismob(target) || severity <= WOUND_SEVERITY_MODERATE)
		return

	// With a severe or critical wound, you have a 15% or 30% chance to proc pain on hit
	if(prob((severity - 1) * 15))
		// And you have a 70% or 50% chance to actually land the blow, respectively
		if(prob(70 - 20 * (severity - 1)))

			if(limb.is_robotic_limb())
				to_chat(victim, span_userdanger("Гидравлика в вашей [limb.ru_name_v] смещается, пока вы бьете [target], повреждаясь!"))
			else
				var/has_pain = victim.has_pain(limb)
				if(has_pain <= PAIN_LOW)
					to_chat(victim, span_userdanger("Кости в вашей [limb.ru_name_v] двигаются, пока вы бьете [target]!"))
				else
					to_chat(victim, span_userdanger("Перелом в вашей [limb.ru_name_v] отзывается болью, пока вы бьете [target]!"))
			limb.receive_damage(brute=rand(1,5))
		else
			var/robo_limb = limb.is_robotic_limb()
			var/has_pain = victim.has_pain(limb)
			victim.visible_message(
				span_danger("[victim] слабо бьет [target] [victim.ru_ego()] [robo_limb ? "поврежденной" : "сломанной"] конечностью - [limb.ru_name][has_pain ? ", изнывая от боли" : ""]!"), \
				span_userdanger("Вам не удается ударить [target] из-за [has_pain ? "боли и " : ""][robo_limb ? "повреждений" : "перелома"] в вашей конечности - [limb.ru_name]!"), vision_distance=COMBAT_MESSAGE_RANGE
			)
			if(has_pain)
				victim.pain_emote(has_pain)
				if(has_pain > PAIN_LOW)
					victim.adjustStaminaLoss(15)
			victim.Stun(0.5 SECONDS)
			limb.receive_damage(brute=rand(3,7))
			return COMPONENT_NO_ATTACK_HAND

/datum/wound/blunt/receive_damage(wounding_type, wounding_dmg, wound_bonus)
	if(!victim || wounding_dmg < WOUND_MINIMUM_DAMAGE)
		return
	if(ishuman(victim))
		var/mob/living/carbon/human/human_victim = victim
		if(NOBLOOD in human_victim.dna?.species.species_traits)
			return

	if(limb.body_zone == BODY_ZONE_CHEST && victim.blood_volume && prob(internal_bleeding_chance + wounding_dmg))
		var/blood_bled = rand(1, wounding_dmg * (severity == WOUND_SEVERITY_CRITICAL ? 2 : 1.5)) // 12 brute toolbox can cause up to 18/24 bleeding with a severe/critical chest wound
		switch(blood_bled)
			if(1 to 6)
				victim.bleed(blood_bled, TRUE)
			if(7 to 13)
				// BLUEMOON ADD START - кастомное описание для роботов
				if(limb.is_robotic_limb())
					// TO DO
				else
				// BLUEMOON ADD END
					victim.visible_message(span_smalldanger("[victim] выкашлывивает немного крови из [victim.ru_ego()] грудной клетки."), span_danger("Вы выкашливаете немного крови из своей грудной клетки."), vision_distance=COMBAT_MESSAGE_RANGE)
				victim.bleed(blood_bled, TRUE)
			if(14 to 19)
				// BLUEMOON ADD START - кастомное описание для роботов
				if(limb.is_robotic_limb())
					// TO DO
				else
				// BLUEMOON ADD END
					victim.visible_message(span_smalldanger("[victim] выкашливает кровь из [victim.ru_ego()] грудной клетки!"), span_danger("Вы выкашливаете кровь из своей грудной клетки!"), vision_distance=COMBAT_MESSAGE_RANGE)
				if(ishuman(victim))
					var/mob/living/carbon/human/H = victim
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir, H.dna.species.exotic_blood_color)
				else
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir)
				victim.bleed(blood_bled)
			if(20 to INFINITY)
				// BLUEMOON ADD START - кастомное описание для роботов
				if(limb.is_robotic_limb())
					// TO DO
				else
				// BLUEMOON ADD END
					victim.visible_message(span_danger("[victim] закашливывается и сплёвывает кучу крови из [victim.ru_ego()] грудной клетки!"), span_danger("<b>Вы обильно кашляете и сплёвываете кучу крови из своей грудной клетки!</b>"), vision_distance=COMBAT_MESSAGE_RANGE)
				victim.bleed(blood_bled)
				if(ishuman(victim))
					var/mob/living/carbon/human/H = victim
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir, H.dna.species.exotic_blood_color)
				else
					new /obj/effect/temp_visual/dir_setting/bloodsplatter(victim.loc, victim.dir)
				victim.add_splatter_floor(get_step(victim.loc, victim.dir))

/datum/wound/blunt/get_examine_description(mob/user)
	if(!limb.current_gauze && !gelled && !taped)
		return ..()

	var/list/msg = list()
	if(!limb.current_gauze)
		msg += "[victim.ru_ego(TRUE)] [limb.ru_name] [examine_desc]"
	else
		var/sling_condition = ""
		// how much life we have left in these bandages
		switch(limb.current_gauze.obj_integrity / limb.current_gauze.max_integrity * 100)
			if(0 to 25)
				sling_condition = "слабо "
			if(25 to 50)
				sling_condition = "частично "
			if(50 to 75)
				sling_condition = "обильно "
			else
				sling_condition = "туго "

		msg += "[victim.ru_ego(TRUE)] [limb.ru_name] [sling_condition] перевязана жгутом из [limb.current_gauze.name]"

	if(taped)
		msg += ", [span_notice("и, похоже, восстанавливается после обработки хирургической лентой!")]"
	else if(gelled)
		msg += ", [span_notice("и покрыта шипящим костным гелем синеватого оттенка!")]"
	else
		msg +=  "!"
	return "<B>[msg.Join()]</B>"

/*
	New common procs for /datum/wound/blunt/
*/

/datum/wound/blunt/proc/update_inefficiencies()
	if(limb.body_zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		if(limb.current_gauze)
			limp_slowdown = initial(limp_slowdown) * limb.current_gauze.splint_factor
		else
			limp_slowdown = initial(limp_slowdown)
		victim.apply_status_effect(STATUS_EFFECT_LIMP)
	else if(limb.body_zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		if(limb.current_gauze)
			interaction_efficiency_penalty = 1 + ((interaction_efficiency_penalty - 1) * limb.current_gauze.splint_factor)
		else
			interaction_efficiency_penalty = interaction_efficiency_penalty

	if(initial(disabling))
		disabling = !limb.current_gauze

	limb.update_wounds()

/*
	Moderate (Joint Dislocation)
*/

/datum/wound/blunt/moderate
	name = "Joint Dislocation"
	ru_name = "Вывих"
	ru_name_r = "вывиха"
	desc = "Кость пациента неестественно выгнулась, что вызывает болевые ощущения и ухудшает моторику."
	treat_text = "Использовать костоправ. В крайнем случае возможно, но не рекомендуется вправление конечности своими силами с помощью агрессивного захвата."
	examine_desc = "неестественно вывихнута"
	occur_text = "сильно дергается, издавая хруст"
	severity = WOUND_SEVERITY_MODERATE
	viable_zones = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	interaction_efficiency_penalty = 1.8
	limp_slowdown = 1.3
	threshold_minimum = 35
	threshold_penalty = 13
	treatable_tool = TOOL_BONESET
	wound_flags = (BONE_WOUND)
	status_effect_type = /datum/status_effect/wound/blunt/moderate
	scar_keyword = "bluntmoderate"

// BLUEMOON ADD START
/datum/wound/blunt/moderate/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Повреждение крепления"
		ru_name_r = "повреждения крепления"
		desc = "Крепление конечности некорректно повернуто. Это сказывается на моторике."
		treat_text = "Использовать гаечный ключ. В крайнем случае возможно, но не рекомендуется вправление конечности своими силами с помощью агрессивного захвата."
		examine_desc = "неестественно выгнута"
		treatable_tool = TOOL_WRENCH

	return ..()
// BLUEMOON ADD END

/datum/wound/blunt/moderate/crush()
	if(prob(33))
		if(limb.is_robotic_limb())
			victim.visible_message(span_danger("Сдвинутое крепление [limb.ru_name] [victim] возвращается на место!"), span_userdanger("Ваше сдвинутое крепление у [limb.ru_name] возвращается на место! Система в норме."))
		else
			victim.visible_message(span_danger("Вывихнутая [limb.ru_name] [victim] возвращается на место!"), span_userdanger("Ваша вывихнутая [limb.ru_name] возвращается на место! Ау!"))
		remove_wound()

/datum/wound/blunt/moderate/try_handling(mob/living/carbon/human/user)
	if(user.pulling != victim || user.zone_selected != limb.body_zone || user.a_intent == INTENT_GRAB)
		return FALSE

	if(user.grab_state == GRAB_PASSIVE)
		to_chat(user, span_warning("Необходимо взять [victim] в агрессивный захват с целью дальнейших манипуляций с [victim.ru_ego()] конечностью!"))
		return TRUE

	if(user.grab_state >= GRAB_AGGRESSIVE)
		user.visible_message(span_danger("[user] начинает впралять вывих на [limb.ru_name_v] - [victim]!"), span_notice("Вы начинаете вправлять вывих на [limb.ru_name_v] у [victim]..."), ignored_mobs=victim)
		to_chat(victim, span_userdanger("[user] начинает вправлять вывих на вашей [limb.ru_name_v]!"))
		handle_joint(user, user.a_intent != INTENT_HELP)
		return TRUE

/// Общий прок для ручного вправления вывиха
/datum/wound/blunt/moderate/proc/handle_joint(mob/living/carbon/human/user, harmfull = FALSE)
	var/time = base_treat_time

	if(!do_after(user, time, target=victim, extra_checks = CALLBACK(src, PROC_REF(still_exists))))
		return FALSE

	var/has_pain = victim.has_pain(limb)
	var/stamina_damage = (has_pain > PAIN_LOW) ? 30 : 0
	var/glass_bones = HAS_TRAIT(victim, TRAIT_GLASS_BONES)

	if(glass_bones || !prob(65))
		// Провал
		user.visible_message(
			span_danger("[user] болезненно выкручивает вывих на [limb.ru_name_v] персонажа [victim]."),
			span_danger("Вы болезненно выкручиваете вывих на [limb.ru_name_v] персонажа [victim]!"),
			ignored_mobs = victim,
		)
		to_chat(victim,
			span_userdanger("[user] [has_pain ? "болезненно " : ""]выкручивает вывих на вашей [limb.ru_name_v]!"),
		)

		if(glass_bones)
			replace_wound(harmfull ? /datum/wound/blunt/severe : /datum/wound/blunt/critical)
			return FALSE

		limb.receive_damage(brute = 10, stamina=stamina_damage, wound_bonus = (harmfull ? 10 : CANT_WOUND))
		// рекурсивно повторяем
		return handle_joint(user, user.a_intent != INTENT_HELP)

	// Успех
	var/message = harmfull \
		? span_danger("[user] с резким хрустом вправляет вывих на [limb.ru_name_v] персонажа [victim]!") \
		: span_danger("[user] вправляет вывих на [limb.ru_name_v] персонажа [victim]!")
	var/self_message = harmfull \
		? span_notice("Вы с резким хрустом вправляете вывих на [limb.ru_name_v] персонажа [victim]!") \
		: span_notice("Вы вправляете вывих на [limb.ru_name_v] персонажа [victim]!")
	var/victim_message = harmfull \
		? span_userdanger("[user] с резким хрустом вправляет вывих на вашей [limb.ru_name_v]!") \
		: span_userdanger("[user] вправляет вашу вывих на [limb.ru_name_v] - на место!")
	var/success_brute = harmfull ? 25 : 20
	var/success_wound_bonus = harmfull ? 30 : CANT_WOUND

	user.visible_message(message, self_message, ignored_mobs = victim)
	to_chat(victim,victim_message)
	victim.pain_emote(has_pain)
	limb.receive_damage(brute = success_brute, stamina = stamina_damage, wound_bonus = success_wound_bonus)
	if(!harmfull)
		qdel(src)

	return TRUE

/datum/wound/blunt/moderate/treat(obj/item/I, mob/user)
	if(victim == user)
		victim.visible_message(span_danger("[user] пытается вправить свою [ru_kogo_zone(limb)], используя [I]."), span_warning("Вы пытаетесь восстановить свою [ru_kogo_zone(limb)], используя [I]..."))
	else
		user.visible_message(span_danger("[user] пытается вправить [ru_kogo_zone(limb)] [victim], используя [I]."), span_notice("Вы пытаетесь восстановить [ru_kogo_zone(limb)] [victim], используя [I]..."))

	if(!do_after(user, base_treat_time * (user == victim ? 1.5 : 1), target = victim, extra_checks=CALLBACK(src, PROC_REF(still_exists))))
		return

	if(victim == user)
		limb.receive_damage(brute=15, wound_bonus=CANT_WOUND)
		victim.visible_message(span_danger("[user] вправляет [victim.ru_ego()] конечность - [limb.ru_name]!"), span_userdanger("Вы вправляете свою [ru_kogo_zone(limb)]!"))
	else
		limb.receive_damage(brute=10, wound_bonus=CANT_WOUND)
		user.visible_message(span_danger("[user] вправляет [ru_kogo_zone(limb)] [victim]!"), span_nicegreen("Вы успешно вправляете [ru_kogo_zone(limb)] [victim]!"), victim)
		to_chat(victim, span_userdanger("[user] вправляет вашу [ru_kogo_zone(limb)]!"))

	var/has_pain = victim.has_pain()
	var/stamina_damage = min(10 * has_pain, 50)

	if(has_pain)
		victim.pain_emote(has_pain)
		limb.receive_damage(stamina = stamina_damage)
	qdel(src)

/*
	Severe (Hairline Fracture)
*/

/datum/wound/blunt/severe
	name = "Hairline Fracture"
	ru_name = "Перелом"
	ru_name_r = "перелома"
	desc = "Кость пациента сломана. Это вызывает сильные боли и серьёзно ухудшает моторику."
	treat_text = "Хирургическое вмешательство с применением костного геля. Наложение марлевой повязки позволит избежать усугубления ситуации."
	examine_desc = "сильно распухла и покрылась синяками"
	occur_text = "набухает от обломков костей и образует неприятного вида синяк"

	severity = WOUND_SEVERITY_SEVERE
	interaction_efficiency_penalty = 2.5
	limp_slowdown = 3.2
	threshold_minimum = 65
	threshold_penalty = 17
	disabling = TRUE
	treatable_by = list(/obj/item/stack/sticky_tape/surgical, /obj/item/stack/medical/bone_gel)
	status_effect_type = /datum/status_effect/wound/blunt/severe
	scar_keyword = "bluntsevere"
	brain_trauma_group = BRAIN_TRAUMA_MILD
	trauma_cycle_cooldown = 1.5 MINUTES
	internal_bleeding_chance = 40
	wound_flags = (BONE_WOUND | ACCEPTS_GAUZE | MANGLES_BONE)
	pain_realagony = TRUE

// BLUEMOON ADD START
/datum/wound/blunt/severe/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L) && L.is_robotic_limb())
		ru_name = "Повреждение гидравлики"
		ru_name_r = "Повреждения гидравлики"
		desc = "Гидравлика сильно повреждена и треснула. Серьёзно ухудшает моторику."
		treat_text = "Глубокий ремонт (или нанесение наногеля на поврежденный привод)."
		examine_desc = "трешит и хрустит"
		occur_text = "трешит с неприятным звуком"
		wound_flags = (BONE_WOUND | MANGLES_BONE)
		treatable_by = list(/obj/item/stack/medical/nanogel)

	return ..()
// BLUEMOON ADD END

/datum/wound/blunt/critical
	name = "Compound Fracture"
	ru_name = "Открытый перелом"
	ru_name_r = "открытого перелома"
	desc = "Кости пациента получили множественные серьёзные переломы. Конечность, вкупе с сопутствующими невыносимыми болями, практически не функционирует."
	treat_text = "Немедленная фиксация конечности с последующим хирургическим вмешательством."
	examine_desc = "изуродована и раздроблена, держась только благодаря тканям"
	occur_text = "надламывается, из-за чего кости выходят наружу"

	severity = WOUND_SEVERITY_CRITICAL
	interaction_efficiency_penalty = 6
	limp_slowdown = 6.5
	sound_effect = 'sound/effects/wounds/crack2.ogg'
	threshold_minimum = 115
	threshold_penalty = 25
	disabling = TRUE
	treatable_by = list(/obj/item/stack/sticky_tape/surgical, /obj/item/stack/medical/bone_gel)
	status_effect_type = /datum/status_effect/wound/blunt/critical
	scar_keyword = "bluntcritical"
	brain_trauma_group = BRAIN_TRAUMA_SEVERE
	trauma_cycle_cooldown = 2.5 MINUTES
	internal_bleeding_chance = 60
	wound_flags = (BONE_WOUND | ACCEPTS_GAUZE | MANGLES_BONE)
	pain_realagony = TRUE

// BLUEMOON ADD START
/datum/wound/blunt/critical/apply_wound(obj/item/bodypart/L, silent, datum/wound/old_wound, smited)
	if(istype(L))
		var/robo_limb = L.is_robotic_limb()
		if(robo_limb)
			ru_name = "Разрыв гидравлики"
			ru_name_r = "разрыва гидравлики"
			desc = "Гидравлика переломалась и практически не функционирует."
			treat_text = "Глубокий ремонт (или нанесение наногеля на поврежденный привод)."
			examine_desc = "раздроблена и не работает, держась на обшивке и проводах вокруг разорванной гидравлики"
			occur_text = "надламывается, из-за чего гидравлика выходит наружу"
			wound_flags = (BONE_WOUND | MANGLES_BONE)
			treatable_by = list(/obj/item/stack/medical/nanogel)

		if(L.body_zone == BODY_ZONE_HEAD && severity == WOUND_SEVERITY_CRITICAL)
			occur_text = robo_limb \
				? "раскалывается, обнажая сквозь поврежденную обшивку и провода, различные платы" \
				: "раскалывается, обнажая сквозь пелену крови и плоти, потрескавшийся череп"
			examine_desc = robo_limb \
				? "имеет раскол, из которого торчат куски проводов" \
				: "имеет выемку, из которой торчат куски черепа"


	return ..()
// BLUEMOON ADD END

// BLUEMOON ADD START - нанесение наногеля на рану (только для синтетиков)
/datum/wound/blunt/proc/nanogel(obj/item/stack/medical/nanogel/I, mob/user)
	if(nano_gelled)
		to_chat(user, span_warning("[user == victim ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [victim]"] уже покрыта нано гелем!"))
		return

	user.visible_message(span_danger("[user] пытаетесь нанести [I] на [limb.ru_name] [victim]..."), span_warning("Вы пытаетесь нанести [I] на [limb.ru_name] [user == victim ? "" : "[victim]"]."))

	if(!do_after(user, base_treat_time * 1.5 * (user == victim ? 1.5 : 1), target = victim, extra_checks=CALLBACK(src, PROC_REF(still_exists))))
		return

	I.use(1)
	user.visible_message(span_notice("[user] с шипящим звуком наносит [I] на [limb.ru_name] [victim]!"), span_notice("Вы наносите [I] на [limb.ru_name] [victim]!"), ignored_mobs=victim)
	to_chat(victim, span_userdanger("[user] наносит [I] на вашу [limb.ru_name]. Нано гель вскоре начнёт считывать данные, подбирая нужную форму для приводов."))

	regen_points_current = 0
	regen_points_needed = 30 SECONDS * (user == victim ? 1.5 : 1) * (severity - 1)

	nano_gelled = TRUE
	processes = TRUE
// BLUEMOON ADD END

/// if someone is using bone gel on our wound
/datum/wound/blunt/proc/gel(obj/item/stack/medical/bone_gel/I, mob/user)
	if(gelled)
		to_chat(user, span_warning("[user == victim ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [victim]"] уже покрыта костным гелем!"))
		return

	user.visible_message(span_danger("[user] пытаетесь нанести [I] на конечность - [limb.ru_name] - персонажа [victim]..."), span_warning("Вы пытаетесь нанести [I] на [user == victim ? "вашу конечность - [limb.ru_name]" : "конечность - [limb.ru_name] - персонажа [victim]"]."))

	if(!do_after(user, base_treat_time * 1.5 * (user == victim ? 1.5 : 1), target = victim, extra_checks=CALLBACK(src, PROC_REF(still_exists))))
		return

	I.use(1)
	var/has_pain = victim.has_pain(limb)
	victim.pain_emote(has_pain)
	if(user != victim)
		user.visible_message(span_notice("[user] с шипящим звуком наносит [I] на конечность - [limb.ru_name] - персонажа [victim]!"), span_notice("Вы наносите [I] на конечность - [limb.ru_name] - персонажа [victim]!"), ignored_mobs=victim)
		to_chat(victim, span_userdanger("[user] наносит [I] на вашу на конечность - [limb.ru_name]. Вы чувствуете, как ваши кости [has_pain ? "болезнено " : ""]хрустят, срастаясь и перестриваясь."))
	else
		var/painkiller_bonus = 0

		if(has_pain <= PAIN_LOW)
			painkiller_bonus += 25
		else if(has_pain <= PAIN_MEDIUM)
			painkiller_bonus += 15

		if(has_pain && prob(25 + (20 * severity - 2) - painkiller_bonus)) // 15%/35% chance to fail self-applying with severe and critical wounds, modded by painkillers
			victim.visible_message(span_danger("[victim] проваливается с нанесением [I] на [victim.ru_ego()] конечность - [limb.ru_name]!"), span_notice("Вы дергаетесь от боли, не в силах нанести [I] на вашу конечность [limb.ru_name]!"))
			victim.Stun(0.5 SECONDS)
			victim.Jitter(10)
			limb.receive_damage(stamina=15)
			return

	var/stamina_damage = 60
	if(!has_pain)
		stamina_damage = 0
	else if(has_pain <= PAIN_LOW)
		stamina_damage = 30

	limb.receive_damage(30, stamina=stamina_damage, wound_bonus=CANT_WOUND)
	if(!gelled)
		gelled = TRUE

/// if someone is using surgical tape on our wound
/datum/wound/blunt/proc/tape(obj/item/stack/sticky_tape/surgical/I, mob/user)
	if(!gelled)
		to_chat(user, span_warning("[user == victim ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [victim]"] должна быть покрыта костным гелем прежде, чем вы приступите к этой операции!"))
		return
	if(taped)
		to_chat(user, span_warning("[user == victim ? "Ваша [limb.ru_name]" : "[limb.ru_name_capital] персонажа [victim]"] уже обработана с помощью [I.name] и восстанавливается!"))
		return

	user.visible_message(span_danger("[user] пытается нанести [I] на конечность - [limb.ru_name] - персонажа [victim]..."), span_warning("Вы пытаетесь нанести [I] на [user == victim ? "свою конечность - [limb.ru_name]" : "конечность персонажа [victim] - [limb.ru_name]"]..."))

	if(!do_after(user, base_treat_time * (user == victim ? 1.5 : 1), target = victim, extra_checks=CALLBACK(src, PROC_REF(still_exists))))
		return

	regen_points_current = 0
	regen_points_needed = 30 SECONDS * (user == victim ? 1.5 : 1) * (severity - 1)
	I.use(1)
	if(user != victim)
		user.visible_message(span_notice("[user] с шипящим звуком наносит [I] на конечность - [limb.ru_name] - персонажа [victim]!"), span_notice("Вы наносите [I] на конечность - [limb.ru_name] - персонажа [victim]!"), ignored_mobs=victim)
		to_chat(victim, span_green("[user] наносит [I] на вашу конечность - [limb.ru_name], в результате чего ощущаете, как ваши кости начинают срастаться!"))
	else
		victim.visible_message(span_notice("[victim] наносит [I] на [victim.ru_ego()] конечность - [limb.ru_name]!"), span_green("Вы наносите [I] на конечность - [limb.ru_name], в результате чего ощущаете, как ваши кости начинают срастаться!"))

	taped = TRUE
	processes = TRUE

/datum/wound/blunt/treat(obj/item/I, mob/user)
	if(istype(I, /obj/item/stack/medical/bone_gel))
		gel(I, user)
	else if(istype(I, /obj/item/stack/sticky_tape/surgical))
		tape(I, user)
	else if(istype(I, /obj/item/stack/medical/nanogel))
		nanogel(I, user)

/datum/wound/blunt/get_scanner_description(mob/user)
	. = ..()

	. += "<div class='ml-3'>"

	if(!gelled)
		. += "Альтернативное лечение: Нанести костный гель прямо на поврежденную конечность, после чего перевязать её хирургической лентой. Рекомендуется применять в экстренных ситуациях, ввиду медлительности и болезненности данной процедуры.\n"
	else if(!taped)
		. += span_notice("Продолжайте альтернативное лечение: Нанесите хирургическое ленту прямо на поврежденную конечность. Стоит учесть: эта процедура болезненна и медленна.\n")
	else
		. += span_notice("Уточнение: Восстановление костей началось. Кости восстановились на [round(regen_points_current*100/regen_points_needed)]%.\n")

	if(limb.body_zone == BODY_ZONE_HEAD && severity == WOUND_SEVERITY_CRITICAL)
		. += "Обнаружена черепно-мозговая травма: Пациент будет испытывать неконтроллируемые [severity == WOUND_SEVERITY_CRITICAL ? "приступы средней тяжести" : "тяжелые приступы"] до того момента, как кости будут восстановлены."
	else if(limb.body_zone == BODY_ZONE_CHEST && victim.blood_volume)
		. += "Обнаружена травма грудной клетки: Последующие повреждения будут усиливать внутреннее кровотечения до того момента, пока кости не будут восстановлены."
	. += "</div>"
