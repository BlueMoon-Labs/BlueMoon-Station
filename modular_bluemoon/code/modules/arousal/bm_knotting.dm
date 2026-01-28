// ============================================================
// BlueMoon - Knotting core (REFACTORED) //By Stasdvrz
// ============================================================
#include "bm_knotting_defines.dm"

// ============================================================
// CONFIGURATION DEFINES
// ============================================================
#define KNOT_BASE_CHANCE 20
#define KNOT_SIZE_MULTIPLIER 8
#define KNOT_STRENGTH_MULTIPLIER 4
#define KNOT_AROUSAL_BONUS_MAX 20
#define KNOT_ESTRUS_BONUS 10
#define KNOT_VAGINAL_BONUS 10
#define KNOT_ANAL_PENALTY 5
#define KNOT_ORAL_PENALTY 15
#define KNOT_RESIST_COOLDOWN 50 // 5 seconds
#define KNOT_DISTANCE_CHECK_INTERVAL 5 SECONDS
#define KNOT_AROUSAL_TICK_INTERVAL 5 SECONDS
#define KNOT_MOVEMENT_CHECK_COOLDOWN 10 // 1 second

// ============================================================
// MOB VARIABLES
// ============================================================
/mob/living
	var/tmp/knot_resist_cd_until = 0
	var/tmp/in_knot_check = FALSE

// ============================================================
// PENIS ORGAN EXTENSION
// ============================================================
/obj/item/organ/genital/penis
	var/knot_size = 0
	var/knot_locked = FALSE
	var/knot_until = 0
	var/knot_strength = 1
	var/knot_state = 0
	var/mob/living/knot_partner = null
	var/last_knot_check = 0
	var/last_tug_time = 0

/obj/item/organ/genital/penis/Initialize(mapload)
	. = ..()
	update_knotting_from_shape()

/obj/item/organ/genital/penis/update_appearance()
	. = ..()
	update_knotting_from_shape()

/obj/item/organ/genital/penis/Destroy()
	if(knot_locked && !QDELETED(knot_partner))
		release_knot(owner, knot_partner, knot_state, TRUE)
	return ..()

/obj/item/organ/genital/penis/proc/update_knotting_from_shape()
	var/datum/sprite_accessory/S = GLOB.cock_shapes_list[shape]
	var/state = lowertext(S ? S.icon_state : "[shape]")

	var/tauric_shape = FALSE
	var/datum/sprite_accessory/taur/T = GLOB.taur_list[src.owner?.dna.features["taur"]]
	if(istype(T) && S)
		tauric_shape = T.taur_mode && S.accepted_taurs

	if(tauric_shape || state == "hemiknot" || state == "barbedhemiknot")
		knot_size = 2
	else if(state == "knotted" || state == "barbknot")
		knot_size = 1
	else
		knot_size = 0

/obj/item/organ/genital/penis/proc/can_pull_out()
	return !knot_locked

// ============================================================
// MAIN KNOTTING LOGIC (REFACTORED)
// ============================================================
/obj/item/organ/genital/penis/proc/do_knotting(mob/living/user, mob/living/partner, target_zone, force_success = FALSE)
	if(!validate_knotting_conditions(user, partner))
		return FALSE

	var/knot_chance = calculate_knot_chance(user, partner, target_zone)

	if(!force_success && !prob(knot_chance))
		return FALSE

	var/duration = calculate_knot_duration(target_zone)

	activate_knot(user, partner, target_zone, duration)
	setup_knot_signals(user, partner)
	apply_knot_effects(user, partner, target_zone)

	schedule_knot_processes(user, partner, target_zone, duration)

	return TRUE

// ============================================================
// VALIDATION
// ============================================================
/obj/item/organ/genital/penis/proc/validate_knotting_conditions(mob/living/user, mob/living/partner)
	if(!knot_size || knot_locked || !user || !partner)
		return FALSE

	if(QDELETED(user) || QDELETED(partner))
		return FALSE

	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/HU = user
	if(!HU.lust || HU.lust < 60)
		return FALSE

	return TRUE

// ============================================================
// CHANCE CALCULATION
// ============================================================
/obj/item/organ/genital/penis/proc/calculate_knot_chance(mob/living/user, mob/living/partner, target_zone)
	var/chance = KNOT_BASE_CHANCE + (knot_size * KNOT_SIZE_MULTIPLIER) + (knot_strength * KNOT_STRENGTH_MULTIPLIER)

	chance += calculate_arousal_bonus(user)
	chance += calculate_zone_modifier(partner, target_zone)
	chance += calculate_estrus_bonus(partner)
	chance -= calculate_existing_knot_penalty(partner, target_zone)

	return clamp(chance, 0, KNOTTING_MAX_CHANCE)

/obj/item/organ/genital/penis/proc/calculate_arousal_bonus(mob/living/user)
	if(!ishuman(user))
		return 0

	var/mob/living/carbon/human/H = user
	var/total_genitals = 0
	var/aroused_genitals = 0

	for(var/obj/item/organ/genital/G in H.internal_organs)
		if(G.genital_flags & GENITAL_CAN_AROUSE)
			total_genitals++
			if(G.aroused_state)
				aroused_genitals++

	if(total_genitals <= 0)
		return 0

	var/arousal_ratio = aroused_genitals / total_genitals
	if(arousal_ratio < 0.8)
		return 0

	return round(KNOT_AROUSAL_BONUS_MAX * ((arousal_ratio - 0.8) / 0.2))

/obj/item/organ/genital/penis/proc/calculate_zone_modifier(mob/living/partner, target_zone)
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			if(!partner.has_vagina())
				return -100 // Impossible
			return KNOT_VAGINAL_BONUS
		if(CUM_TARGET_ANUS)
			if(!partner.has_anus())
				return -100
			return -KNOT_ANAL_PENALTY
		if(CUM_TARGET_MOUTH)
			if(!partner.has_mouth())
				return -100
			return -KNOT_ORAL_PENALTY
	return -100

/obj/item/organ/genital/penis/proc/calculate_estrus_bonus(mob/living/partner)
	if(HAS_TRAIT(partner, TRAIT_ESTROUS_ACTIVE))
		return KNOT_ESTRUS_BONUS
	return 0

/obj/item/organ/genital/penis/proc/calculate_existing_knot_penalty(mob/living/partner, target_zone)
	if(!ishuman(partner))
		return 0

	var/mob/living/carbon/human/Hp = partner
	for(var/obj/item/organ/genital/penis/otherP in Hp.internal_organs)
		if(otherP.knot_locked && otherP.knot_state == target_zone)
			return 100 // Block completely

	return 0

// ============================================================
// DURATION CALCULATION
// ============================================================
/obj/item/organ/genital/penis/proc/calculate_knot_duration(target_zone)
	var/duration_min = 600 SECONDS
	var/duration_max = 900 SECONDS

	switch(target_zone)
		if(CUM_TARGET_ANUS)
			duration_min *= 0.8
			duration_max *= 0.9
		if(CUM_TARGET_MOUTH)
			duration_min *= 0.1
			duration_max *= 0.2

	return rand(duration_min, duration_max)

// ============================================================
// KNOT ACTIVATION
// ============================================================
/obj/item/organ/genital/penis/proc/activate_knot(mob/living/user, mob/living/partner, target_zone, duration)
	knot_locked = TRUE
	knot_partner = partner
	knot_state = target_zone
	knot_until = world.time + duration

/obj/item/organ/genital/penis/proc/setup_knot_signals(mob/living/user, mob/living/partner)
	if(!istype(partner, /mob/living))
		return

	if(!partner.has_movespeed_modifier(/datum/movespeed_modifier/leash))
		partner.add_movespeed_modifier(/datum/movespeed_modifier/leash)

	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)
	RegisterSignal(partner, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)

// ============================================================
// KNOT EFFECTS
// ============================================================
/obj/item/organ/genital/penis/proc/apply_knot_effects(mob/living/user, mob/living/partner, target_zone)
	var/zone_text = get_zone_text(target_zone)

	send_knot_messages(user, partner, zone_text)
	apply_mood_effects(user, partner, TRUE)
	apply_aphrodisiac_effects(user, partner)
	handle_post_knot_arousal(user, partner)

/obj/item/organ/genital/penis/proc/send_knot_messages(mob/living/user, mob/living/partner, zone_text)
	visible_message(list(user, partner),
		span_love("<b>[user]</b> застревает узлом в [zone_text] <b>[partner]</b>!"),
		span_love("Твой узел набухает и фиксируется внутри [partner].")
	)

	to_chat(partner, span_love("<font color='#ff7ff5'><b>Узел блокирует выход — вы соединены с [user]!</b></font>"))
	to_chat(partner, span_love("[get_partner_sensation_message(knot_state)]"))

/obj/item/organ/genital/penis/proc/get_partner_sensation_message(target_zone)
	var/list/messages
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			messages = list(
				"Узел распухает в самой глубине, перекрывая выход...",
				"Ты ощущаешь, как внутри тебя пульсирует запирающий узел...",
				"Тесное тепло внутри не отпускает — узел держит крепко..."
			)
		if(CUM_TARGET_ANUS)
			messages = list(
				"Ты чувствуешь тугое давление — узел не даёт освободиться...",
				"Пульсации глубоко внутри сдавливают тебя изнутри...",
				"Горячие волны упираются в узел, не находя выхода..."
			)
		if(CUM_TARGET_MOUTH)
			messages = list(
				"Узел распухает у тебя во рту, перекрывая путь наружу...",
				"Твой рот полностью заполнен, узел не даёт отодвинуться...",
				"Каждая пульсация узла ощущается с каждым вдохом..."
			)
		else
			messages = list("Ты чувствуешь, как узел пульсирует внутри, соединяя вас крепче...")

	return pick(messages)

/obj/item/organ/genital/penis/proc/apply_mood_effects(mob/living/user, mob/living/partner, positive = TRUE)
	if(!ishuman(user) || !ishuman(partner))
		return

	if(positive)
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)
	else
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")
		SEND_SIGNAL(partner, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(partner, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")

/obj/item/organ/genital/penis/proc/apply_aphrodisiac_effects(mob/living/user, mob/living/partner)
	for(var/mob/living/M in list(user, partner))
		if(!should_apply_aphrodisiac(M))
			continue

		trigger_random_reactions(M)
		send_sensual_messages(M)
		apply_lust_increase(M)

/obj/item/organ/genital/penis/proc/should_apply_aphrodisiac(mob/living/M)
	if(!M?.client?.prefs?.arousable)
		return FALSE
	if(M.client?.prefs?.cit_toggles & NO_APHRO)
		return FALSE
	return TRUE

/obj/item/organ/genital/penis/proc/trigger_random_reactions(mob/living/M)
	if(prob(10))
		if(prob(50))
			M.say(pick("Ох-мхх...", "Ахх-р...", "Амрфпф...", "Мрр-ах...", "Ааах...", "Мнх...", "Ммм..."))
		else
			M.emote(pick("moan", "blush", "pant"))

/obj/item/organ/genital/penis/proc/send_sensual_messages(mob/living/M)
	if(!prob(15))
		return

	var/msg = pick("Ты чувствуешь, как всё внутри горит от удовольствия...","Каждое движение узла усиливает твоё желание...","Твоё тело отзывается на каждую пульсацию...")
	to_chat(M, span_love(msg))

/obj/item/organ/genital/penis/proc/apply_lust_increase(mob/living/M)
	if(ishuman(M))
		var/mob/living/carbon/human/HM = M
		HM.adjust_arousal(100, "knotting", aphro = TRUE)
		HM.safe_add_capped_lust(NORMAL_LUST)
	else
		M.add_lust(NORMAL_LUST)

	REMOVE_TRAIT(M, TRAIT_NEVERBONER, "KNOT_AROUSAL")

/mob/living/carbon/human/proc/safe_add_capped_lust(amount)
	if(!ishuman(src))
		add_lust(amount)
		return

	if(!hascall(src, "get_lust") || !hascall(src, "get_climax_threshold"))
		add_lust(amount)
		return

	var/max_lust = get_climax_threshold()
	if(max_lust <= 0)
		max_lust = 100

	var/current_lust = get_lust()
	if(current_lust >= max_lust)
		return

	amount = min(amount, max_lust - current_lust)
	if(amount > 0)
		add_lust(amount)

/obj/item/organ/genital/penis/proc/handle_post_knot_arousal(mob/living/user, mob/living/partner)
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		HU.handle_post_sex(NORMAL_LUST, null, partner)

	if(ishuman(partner))
		var/mob/living/carbon/human/HP = partner
		HP.handle_post_sex(NORMAL_LUST, null, user)

// ============================================================
// PROCESS SCHEDULING
// ============================================================
/obj/item/organ/genital/penis/proc/schedule_knot_processes(mob/living/user, mob/living/partner, target_zone, duration)
	addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), KNOT_AROUSAL_TICK_INTERVAL)
	addtimer(CALLBACK(src, PROC_REF(release_knot), user, partner, target_zone, FALSE), duration)
	addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), user), KNOT_DISTANCE_CHECK_INTERVAL)

// ============================================================
// PERIODIC AROUSAL TICK
// ============================================================
/obj/item/organ/genital/penis/proc/knot_arousal_tick(mob/living/user, mob/living/partner)
	if(QDELETED(src) || !knot_locked || QDELETED(user) || QDELETED(partner))
		return

	for(var/mob/living/M in list(user, partner))
		if(!M?.client?.prefs?.arousable)
			continue

		var/add_amount = rand(10, 20)

		if(ishuman(M))
			var/mob/living/carbon/human/HM = M
			HM.safe_add_capped_lust(add_amount)
		else
			M.add_lust(add_amount)

		if(prob(8))
			M.emote(pick("moan", "pant", "blush"))

	addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), KNOT_AROUSAL_TICK_INTERVAL)

// ============================================================
// KNOT RELEASE (REFACTORED)
// ============================================================
/obj/item/organ/genital/penis/proc/release_knot(mob/living/user, mob/living/partner, target_zone, forceful = FALSE)
	if(!knot_locked)
		return

	var/mob/living/Luser = user
	var/mob/living/Lpartner = partner

	cleanup_knot_state(Luser, Lpartner)

	var/zone_text = get_zone_text(target_zone)

	if(forceful)
		apply_forceful_release(Luser, Lpartner, zone_text)
	else
		apply_gentle_release(Luser, Lpartner, zone_text)

/obj/item/organ/genital/penis/proc/cleanup_knot_state(mob/living/user, mob/living/partner)
	knot_locked = FALSE
	knot_state = 0
	knot_partner = null
	knot_until = 0

	if(istype(user, /mob/living))
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)

	if(istype(partner, /mob/living))
		UnregisterSignal(partner, COMSIG_MOVABLE_MOVED)
		if(partner.has_movespeed_modifier(/datum/movespeed_modifier/leash))
			partner.remove_movespeed_modifier(/datum/movespeed_modifier/leash)

/obj/item/organ/genital/penis/proc/get_zone_text(target_zone)
	switch(target_zone)
		if(CUM_TARGET_VAGINA) return "влагалища"
		if(CUM_TARGET_ANUS) return "ануса"
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT) return "рта"
	return "тела"

/obj/item/organ/genital/penis/proc/apply_forceful_release(mob/living/user, mob/living/partner, zone_text)
	playsound(get_turf(user), 'sound/effects/snap01.ogg', 100, TRUE)

	user.visible_message(
		span_danger("Узел [user] с силой вырывается из [zone_text] [partner]!"),
		span_warning("Ты резко выдёргиваешь узел из [partner]! Это больно обоим.")
	)

	to_chat(partner, span_userdanger("Ты чувствуешь резкую боль, когда узел [user] рвётся!"))
	partner.emote("scream")
	partner.Stun(40)

	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)

/obj/item/organ/genital/penis/proc/apply_gentle_release(mob/living/user, mob/living/partner, zone_text)
	playsound(get_turf(user), 'sound/effects/snap01.ogg', 50, TRUE)

	user.visible_message(
		span_lewd("Узел [user] постепенно спадает, освобождая [partner] из [zone_text]."),
		span_love("Ты чувствуешь, как узел спадает, освобождая [partner].")
	)

	to_chat(partner, span_lewd("<font color='#ee6bee'>Ты ощущаешь, как узел [user] мягко выходит из твоего [zone_text].</font>"))

	if(prob(25))
		partner.emote("moan")

	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)

// ============================================================
// DISTANCE CHECKING (SIMPLIFIED)
// ============================================================
/obj/item/organ/genital/penis/proc/knot_distance_loop(mob/living/who)
	if(QDELETED(src) || !knot_locked || QDELETED(knot_partner))
		return

	if(!who && istype(owner, /mob/living))
		who = owner

	if(istype(who, /mob/living))
		check_knot_distance_safe(who)

	if(!QDELETED(src) && knot_locked && !QDELETED(knot_partner))
		addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), who), KNOT_DISTANCE_CHECK_INTERVAL)

/obj/item/organ/genital/penis/proc/check_knot_distance_safe(mob/living/user)
	if(QDELETED(user) || QDELETED(knot_partner))
		return

	var/dist = get_dist(user, knot_partner)
	if(dist <= 1)
		return

	var/zone_text = get_zone_text(knot_state)

	if(dist == 2)
		handle_knot_strain(user, knot_partner, zone_text)
	else
		handle_knot_break(user, knot_partner, zone_text)

/obj/item/organ/genital/penis/proc/handle_knot_strain(mob/living/user, mob/living/partner, zone_text)
	to_chat(user, span_warning("Узел натягивается между тобой и [partner]!"))
	to_chat(partner, span_danger("Ты чувствуешь, как узел внутри натягивается и причиняет боль!"))

	if(prob(25))
		partner.emote("whimper")

	user.apply_damage(rand(10, 20), STAMINA)
	user.apply_damage(rand(2, 6), BRUTE)
	partner.apply_damage(rand(5, 10), STAMINA)
	partner.apply_damage(rand(1, 3), BRUTE)

	if(prob(20))
		partner.Stun(10)
		if(prob(10))
			user.Stun(15)

	if(prob(10))
		release_knot(user, partner, knot_state, TRUE)
		return

	if(prob(70))
		apply_tug_to_partner(partner, user)

/obj/item/organ/genital/penis/proc/handle_knot_break(mob/living/user, mob/living/partner, zone_text)
	to_chat(user, span_danger("Узел не выдерживает и рвётся!"))
	to_chat(partner, span_userdanger("Узел резко вырывается из тебя!"))

	user.apply_damage(rand(15, 25), STAMINA)
	user.apply_damage(rand(5, 10), BRUTE)
	partner.apply_damage(rand(10, 20), STAMINA)
	partner.apply_damage(rand(3, 6), BRUTE)

	if(prob(50))
		user.emote("scream")
	if(prob(25))
		partner.emote("moan")

	release_knot(user, partner, knot_state, TRUE)

/obj/item/organ/genital/penis/proc/apply_tug_to_partner(mob/living/partner, mob/living/user)
	if(world.time - last_tug_time < 10)
		return

	last_tug_time = world.time

	// Простое подтягивание партнёра на 1 тайл ближе
	// Если у вас есть система поводков, интегрируйте её здесь
	step_towards(partner, user)

// ============================================================
// MOVEMENT HANDLER
// ============================================================
/obj/item/organ/genital/penis/proc/on_knot_move()
	SIGNAL_HANDLER

	if(QDELETED(src) || !knot_locked || QDELETED(knot_partner))
		cleanup_movement_signals()
		return

	if(!istype(owner, /mob/living))
		return

	var/mob/living/user = owner

	if(world.time < last_knot_check + KNOT_MOVEMENT_CHECK_COOLDOWN)
		return

	last_knot_check = world.time

	check_knot_distance_safe(user)

/obj/item/organ/genital/penis/proc/cleanup_movement_signals()
	if(istype(owner, /mob/living))
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	if(istype(knot_partner, /mob/living))
		UnregisterSignal(knot_partner, COMSIG_MOVABLE_MOVED)

// ============================================================
// RESIST MECHANIC
// ============================================================
/obj/item/organ/genital/penis/proc/start_resist_attempt(mob/living/user)
	if(!knot_locked)
		to_chat(user, span_notice("Узел уже спал."))
		return

	if(!owner || QDELETED(owner) || !knot_partner || QDELETED(knot_partner))
		to_chat(user, span_warning("Цель отсутствует."))
		return

	var/mob/living/pen_owner = owner
	var/mob/living/pen_partner = knot_partner

	if(DOING_INTERACTION_WITH_TARGET(user, pen_owner) || DOING_INTERACTION_WITH_TARGET(user, pen_partner))
		to_chat(user, span_warning("Ты уже пытаешься освободиться — не дёргайся!"))
		return

	if(world.time < user.knot_resist_cd_until)
		to_chat(user, span_warning("Ты только что пытался освободиться — подожди немного..."))
		return

	user.knot_resist_cd_until = world.time + KNOT_RESIST_COOLDOWN

	var/is_partner = (user == pen_partner)
	var/duration = is_partner ? 4 SECONDS : 3 SECONDS

	send_resist_start_messages(user, pen_owner, pen_partner, is_partner)

	if(prob(35))
		to_chat(user, span_danger("Тебе не удаётся найти удобное положение..."))
		if(prob(40))
			user.emote(pick("pant", "whimper"))
		return

	if(!do_after(user, duration, target = is_partner ? pen_owner : pen_partner))
		to_chat(user, span_danger("Ты не смог освободиться от узла!"))
		if(prob(40))
			user.emote(pick("scream", "pant"))
		return

	if(!knot_locked)
		to_chat(user, span_notice("Ты уже свободен."))
		return

	release_knot(pen_owner, pen_partner, knot_state, FALSE)
	send_resist_success_messages(user, pen_owner, pen_partner, is_partner)

/obj/item/organ/genital/penis/proc/send_resist_start_messages(mob/living/user, mob/living/pen_owner, mob/living/pen_partner, is_partner)
	var/msg_start
	if(is_partner)
		msg_start = "[user] начинает извиваться, пытаясь вытолкнуть узел [pen_owner]."
	else
		msg_start = "[user] осторожно пытается освободить узел из [pen_partner]."

	user.visible_message(
		span_notice(msg_start),
		span_notice("Ты начинаешь попытку освободиться от узла...")
	)

	to_chat(user, span_warning("Ты пытаешься освободиться... Не двигайся!"))

/obj/item/organ/genital/penis/proc/send_resist_success_messages(mob/living/user, mob/living/pen_owner, mob/living/pen_partner, is_partner)
	if(is_partner)
		to_chat(user, span_love("Узел постепенно выходит, принося облегчение."))
		if(prob(40))
			user.emote(pick("moan", "blush"))
		if(prob(20))
			pen_owner.emote(pick("groan", "pant"))
	else
		to_chat(user, span_love("Ты осторожно помогаешь узлу сойти."))
		if(prob(25))
			user.emote(pick("sigh"))
		if(prob(25))
			pen_partner.emote(pick("moan", "blush"))

// ============================================================
// HUMAN VERB INTEGRATION
// ============================================================
/mob/living/carbon/human/verb/knot_resist()
	set name = "Resist Knot"
	set category = "IC"
	set desc = "Попытаться освободиться от узла (если застрял)."

	resist()

/mob/living/carbon/human/resist()
	var/obj/item/organ/genital/penis/P = getorganslot(ORGAN_SLOT_PENIS)
	if(P && P.knot_locked)
		to_chat(src, span_love("Ты пытаешься освободиться от узла..."))
		P.start_resist_attempt(src)
		return

	for(var/mob/living/carbon/human/other in view(1, src))
		if(other == src)
			continue
		var/obj/item/organ/genital/penis/P2 = other.getorganslot(ORGAN_SLOT_PENIS)
		if(P2 && P2.knot_locked && P2.knot_partner == src)
			to_chat(src, span_love("Ты пытаешься вырваться из узла [other]!"))
			P2.start_resist_attempt(src)
			return

	return ..()

// ============================================================
// GLOBAL HELPER PROC
// ============================================================
/proc/try_apply_knot(mob/living/user, mob/living/partner, target_zone, force_override = FALSE, force_knot = FALSE)
	if(!ishuman(user) || !ishuman(partner))
		return
/*
	if(!force_override)
		if(!user?.client?.prefs?.sexknotting || !partner?.client?.prefs?.sexknotting)
			return
*/
	var/static/list/valid_orifices = list(
		CUM_TARGET_VAGINA,
		CUM_TARGET_ANUS,
		CUM_TARGET_MOUTH,
		CUM_TARGET_THROAT
	)

	if(!(target_zone in valid_orifices))
		return

	var/mob/living/carbon/human/initiator = user
	var/mob/living/carbon/human/receiver = partner
	var/obj/item/organ/genital/penis/P = null

	// FIX: правильная проверка типа last_genital
	if(initiator.last_genital)
		var/obj/item/organ/genital/temp_organ = initiator.last_genital
		if(istype(temp_organ, /obj/item/organ/genital/penis))
			if(!QDELETED(temp_organ))
				P = temp_organ

	// Если не нашли у initiator, проверяем receiver
	if(!P && receiver.last_genital)
		var/obj/item/organ/genital/temp_organ2 = receiver.last_genital
		if(istype(temp_organ2, /obj/item/organ/genital/penis))
			if(!QDELETED(temp_organ2))
				P = temp_organ2
				// Меняем местами
				var/mob/living/carbon/human/swap_temp = initiator
				initiator = receiver
				receiver = swap_temp

	if(!P)
		return

	if(!P.knot_size || P.knot_locked)
		return

	var/effective_lust = 0
	if(ishuman(initiator))
		var/mob/living/carbon/human/H = initiator
		if(hascall(H, "get_lust") && hascall(H, "get_climax_threshold"))
			var/threshold = H.get_climax_threshold()
			if(threshold > 0)
				effective_lust = (H.get_lust() / threshold) * 100

	if(effective_lust < 65 && !force_knot)
		return

	var/chance = 10 + (P.knot_size * 10)
	if(effective_lust >= 80)
		chance += 10
	if(HAS_TRAIT(receiver, TRAIT_ESTROUS_ACTIVE))
		chance += 5

	chance = clamp(chance, 5, 60)

	if(force_knot)
		chance = 100

	if(force_knot || prob(chance))
		if(P.do_knotting(initiator, receiver, target_zone, force_knot))
			to_chat(initiator, span_love("Ты чувствуешь, как узел набухает внутри [receiver]!"))
			to_chat(receiver, span_love("Ты ощущаешь, как узел [initiator] застревает внутри!"))
			GLOB.knottings++
