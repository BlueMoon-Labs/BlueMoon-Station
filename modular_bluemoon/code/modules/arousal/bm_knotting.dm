// BLUEMOON KNOT CYBORG + MOVEMENT V2 (Stasdvrz extension)
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
#define KNOT_STEP_BREAK_CHANCE 3 // % per outward step, independent of strain cooldown
#define KNOT_STRAIN_COOLDOWN 5 SECONDS

// Separate from /datum/movespeed_modifier/leash; no interference with leashes.
/datum/movespeed_modifier/knotting
	id = "BLUEMOON_KNOTTING"
	multiplicative_slowdown = 1


// ============================================================
// MOB VARIABLES
// ============================================================
/mob/living
	var/tmp/knot_resist_cd_until = 0
	var/tmp/in_knot_check = FALSE
	/// Active connection is an organ pointer; shared by both participants.
	var/tmp/obj/item/organ/genital/penis/active_knot = null

/obj/item/organ/genital
	var/is_knotted = FALSE

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
	var/obj/item/organ/genital/knotted_genital = null
	/// All receiver organs occupied by one knot (two zones for hemiknot forms).
	var/list/knotted_genitals = null
	var/list/knot_zones = null
	var/last_knot_strain = 0

	var/tmp/knot_is_hidden = FALSE
	var/tmp/knot_arousal_timer
	var/tmp/knot_release_timer
	var/tmp/knot_distance_timer
	/// Prevent movement signal recursion while moving the linked participant.
	var/tmp/knot_following = FALSE
/obj/item/organ/genital/penis/Initialize(mapload)
	. = ..()
	update_knotting_from_shape()

/obj/item/organ/genital/penis/Destroy()
	// Surgical Remove() already calls cleanup. Destruction is a technical cleanup,
	// not a forceful pull (which would hurt deleted / absent participants).
	if(knot_locked)
		cleanup_knot_state(get_knot_user(), knot_partner)
	return ..()

/obj/item/organ/genital/penis/proc/update_knotting_from_shape()
	var/datum/sprite_accessory/S = GLOB.cock_shapes_list[shape]
	var/state = lowertext(S ? S.icon_state : "[shape]")
	var/tauric_shape = FALSE
	var/datum/sprite_accessory/taur/T = GLOB.taur_list[owner?.dna.features["taur"]]
	if(istype(T) && S)
		tauric_shape = !!(T.taur_mode & S.accepted_taurs)

	if(tauric_shape || state == "hemiknot" || state == "bhemiknot" || state == "barbedhemiknot")
		knot_size = 2
	else if(state == "knotted" || state == "barbknot" || state == "pede_knotted")
		knot_size = 1
	else
		knot_size = 0
	// A character changing their shape should not silently break an existing connection.

/obj/item/organ/genital/penis/proc/can_pull_out()
	return !knot_locked

// ============================================================
// MAIN KNOTTING LOGIC (REFACTORED)
// ============================================================
/obj/item/organ/genital/penis/proc/do_knotting(mob/living/user, mob/living/partner, target_zone, force_success = FALSE, is_hidden = FALSE)
	if(!validate_knotting_conditions(user, partner, target_zone))
		return FALSE

	// A double-knotted shape is still ONE organ in BlueMoon. Allow it to occupy
	// both vagina and anus of the SAME partner without duplicating timers/signals.
	if(knot_locked)
		if(knot_size < 2 || partner != knot_partner || !(target_zone in list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS)))
			return FALSE
		if(target_zone in knot_zones || length(knot_zones) >= 2)
			return FALSE
		if(!force_success && !prob(calculate_knot_chance(user, partner, target_zone)))
			return FALSE
		register_knot_zone(partner, target_zone)
		to_chat(user, span_notice("Второй узел тоже зафиксировался."))
		to_chat(partner, span_notice("Оба узла теперь удерживают вас вместе."))
		return TRUE

	// Only ONE probability roll; try_apply_knot must not repeat it.
	if(!force_success && !prob(calculate_knot_chance(user, partner, target_zone)))
		return FALSE

	var/duration = calculate_knot_duration(target_zone)
	activate_knot(user, partner, target_zone, duration, is_hidden)
	setup_knot_signals(user, partner)
	apply_knot_effects(user, partner, target_zone)
	schedule_knot_processes(user, partner, target_zone, duration)
	return TRUE

// Shared knot source: a real carbon organ, or an opt-in synthetic control module.
/obj/item/organ/genital/penis/proc/get_knot_user()
	if(istype(src, /obj/item/organ/genital/penis/silicon_knot))
		var/obj/item/organ/genital/penis/silicon_knot/module = src
		return module.silicon_owner
	return owner

/obj/item/organ/genital/penis/proc/validate_knotting_conditions(mob/living/user, mob/living/partner, target_zone)
	if(!knot_size || QDELETED(user) || QDELETED(partner) || user == partner)
		return FALSE
	if(!(ishuman(user) || iscyborg(user)) || !(ishuman(partner) || iscyborg(partner)))
		return FALSE
	if(get_knot_user() != user)
		return FALSE
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		if(HU.getorganslot(ORGAN_SLOT_PENIS) != src)
			return FALSE
	else
		var/mob/living/silicon/robot/R = user
		if(R.synthetic_knot_module != src || !R.synthetic_knot_style)
			return FALSE
	if(!get_turf(user) || !get_turf(partner) || user.z != partner.z || get_dist(user, partner) > 1)
		return FALSE
	if(!(target_zone in list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS, CUM_TARGET_MOUTH, CUM_TARGET_THROAT)))
		return FALSE
	if(calculate_zone_modifier(partner, target_zone) <= -100)
		return FALSE
	if(user.active_knot && user.active_knot != src)
		return FALSE
	if(partner.active_knot && partner.active_knot != src)
		return FALSE
	if(knot_locked && knot_partner != partner)
		return FALSE
	return TRUE

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
	if(iscyborg(partner))
		var/mob/living/silicon/robot/R = partner
		if(!(target_zone in R.synthetic_knot_slots))
			return -100
		// A synthetic receiving slot exists only if that cyborg enabled it.
		switch(target_zone)
			if(CUM_TARGET_VAGINA)
				return KNOT_VAGINAL_BONUS
			if(CUM_TARGET_ANUS)
				return -KNOT_ANAL_PENALTY
			if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT)
				return -KNOT_ORAL_PENALTY
		return -100
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			if(!partner.has_vagina())
				return -100
			return KNOT_VAGINAL_BONUS
		if(CUM_TARGET_ANUS)
			if(!partner.has_anus())
				return -100
			return -KNOT_ANAL_PENALTY
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT)
			if(!partner.has_mouth())
				return -100
			return -KNOT_ORAL_PENALTY
	return -100

/obj/item/organ/genital/penis/proc/calculate_estrus_bonus(mob/living/partner)
	if(HAS_TRAIT(partner, TRAIT_ESTROUS_ACTIVE))
		return KNOT_ESTRUS_BONUS
	return 0

/obj/item/organ/genital/penis/proc/calculate_existing_knot_penalty(mob/living/partner, target_zone)
	if(partner.active_knot && partner.active_knot != src)
		return 100
	if(!ishuman(partner))
		return 0
	var/obj/item/organ/genital/receiver
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			receiver = partner.getorganslot(ORGAN_SLOT_VAGINA)
		if(CUM_TARGET_ANUS)
			receiver = partner.getorganslot(ORGAN_SLOT_ANUS)
	if(receiver?.is_knotted && !(target_zone in knot_zones))
		return 100
	return 0

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
/obj/item/organ/genital/penis/proc/activate_knot(mob/living/user, mob/living/partner, target_zone, duration, is_hidden = FALSE)
	if(knot_locked)
		cleanup_knot_state(get_knot_user(), knot_partner)
	knot_is_hidden = is_hidden
	knot_locked = TRUE
	knot_partner = partner
	knot_state = target_zone
	knot_zones = list(target_zone)
	knotted_genitals = list()
	knotted_genital = null
	knot_until = world.time + duration
	last_knot_strain = 0
	user.active_knot = src
	partner.active_knot = src

/obj/item/organ/genital/penis/proc/register_knot_zone(mob/living/partner, target_zone)
	if(!(target_zone in knot_zones))
		knot_zones += target_zone
	// Cyborg receiving slots are configuration, not actual carbon organs.
	if(!ishuman(partner))
		return
	var/obj/item/organ/genital/receiver
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			receiver = partner.getorganslot(ORGAN_SLOT_VAGINA)
		if(CUM_TARGET_ANUS)
			receiver = partner.getorganslot(ORGAN_SLOT_ANUS)
	if(receiver && !QDELETED(receiver))
		receiver.is_knotted = TRUE
		if(!(receiver in knotted_genitals))
			knotted_genitals += receiver
		if(!knotted_genital)
			knotted_genital = receiver

/obj/item/organ/genital/penis/proc/setup_knot_signals(mob/living/user, mob/living/partner)
	if(!istype(partner, /mob/living))
		return

	if(!partner.has_movespeed_modifier(/datum/movespeed_modifier/knotting))
		partner.add_movespeed_modifier(/datum/movespeed_modifier/knotting)

	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)
	RegisterSignal(user, COMSIG_PARENT_QDELETING, PROC_REF(on_knot_participant_deleted))
	if(partner != user)
		RegisterSignal(partner, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)
		RegisterSignal(partner, COMSIG_PARENT_QDELETING, PROC_REF(on_knot_participant_deleted))

/obj/item/organ/genital/penis/proc/on_knot_participant_deleted()
	SIGNAL_HANDLER
	cleanup_knot_state(get_knot_user(), knot_partner)

// ============================================================
// KNOT EFFECTS
// ============================================================
/obj/item/organ/genital/penis/proc/apply_knot_effects(mob/living/user, mob/living/partner, target_zone)
	var/zone_text = get_zone_text(target_zone)

	send_knot_messages(user, partner, zone_text)
	apply_mood_effects(user, partner, TRUE)
	apply_aphrodisiac_effects(user, partner)
	handle_post_knot_arousal(user, partner)
	register_knot_zone(partner, target_zone)

/obj/item/organ/genital/penis/proc/send_knot_messages(mob/living/user, mob/living/partner, zone_text)
	user.visible_message(
		span_love("[HIDDEN_INTERACTION_PREFIX(knot_is_hidden)]<b>[user]</b> застревает узлом в [zone_text] <b>[partner]</b>!"),
		span_love("Твой узел набухает и фиксируется внутри [partner]."),
		vision_distance = INTERACTION_MESSAGE_RANGE(knot_is_hidden),
		visible_message_flags = INTERACTION_MESSAGE_FLAGS(knot_is_hidden)
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
	if(positive)
		if(ishuman(user))
			SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
		if(ishuman(partner))
			SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)
	else
		if(ishuman(user))
			SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
			SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")
		if(ishuman(partner))
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
	if(!ishuman(M))
		return FALSE
	if(!M?.client?.prefs?.arousable)
		return FALSE
	if(M.client?.prefs?.cit_toggles & NO_APHRO)
		return FALSE
	return TRUE

/obj/item/organ/genital/penis/proc/trigger_random_reactions(mob/living/M)
	if(prob(10))
		if(knot_is_hidden)
			M.moan(TRUE)
		else if(prob(50))
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
		HU.handle_post_sex(NORMAL_LUST, null, partner, is_hidden = knot_is_hidden)

	if(ishuman(partner))
		var/mob/living/carbon/human/HP = partner
		HP.handle_post_sex(NORMAL_LUST, null, user, is_hidden = knot_is_hidden)

// ============================================================
// PROCESS SCHEDULING
// ============================================================
/obj/item/organ/genital/penis/proc/schedule_knot_processes(mob/living/user, mob/living/partner, target_zone, duration)
	if(!knot_locked || knot_partner != partner)
		return
	if(!knot_arousal_timer)
		knot_arousal_timer = addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), KNOT_AROUSAL_TICK_INTERVAL, TIMER_STOPPABLE)
	knot_release_timer = addtimer(CALLBACK(src, PROC_REF(release_knot), user, partner, target_zone, FALSE), duration, TIMER_STOPPABLE)
	knot_distance_timer = addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), user), KNOT_DISTANCE_CHECK_INTERVAL, TIMER_STOPPABLE)

// ============================================================
// PERIODIC AROUSAL TICK
// ============================================================
/obj/item/organ/genital/penis/proc/knot_arousal_tick(mob/living/user, mob/living/partner)
	knot_arousal_timer = null
	if(QDELETED(src) || !knot_locked || QDELETED(user) || QDELETED(partner))
		return

	for(var/mob/living/M in list(user, partner))
		if(!ishuman(M) || !M?.client?.prefs?.arousable)
			continue

		var/add_amount = rand(10, 20)

		if(ishuman(M))
			var/mob/living/carbon/human/HM = M
			HM.safe_add_capped_lust(add_amount)
		else
			M.add_lust(add_amount)

		if(prob(8))
			if(knot_is_hidden)
				M.moan(TRUE)
			else
				M.emote(pick("moan", "pant", "blush"))

	if(knot_locked && !knot_arousal_timer)
		knot_arousal_timer = addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), KNOT_AROUSAL_TICK_INTERVAL, TIMER_STOPPABLE)

// ============================================================
// KNOT RELEASE (REFACTORED)
// ============================================================
/obj/item/organ/genital/penis/proc/release_knot(mob/living/user, mob/living/partner, target_zone, forceful = FALSE)
	if(!knot_locked)
		return
	// Never trust stale callback arguments: use the currently stored participants.
	var/mob/living/Luser = get_knot_user()
	var/mob/living/Lpartner = knot_partner
	var/hidden = knot_is_hidden
	var/zone_text = get_zone_text(knot_state)
	if(length(knot_zones) > 1)
		zone_text = "влагалища и ануса"
	cleanup_knot_state(Luser, Lpartner)
	if(QDELETED(Luser) || QDELETED(Lpartner))
		return
	if(forceful)
		apply_mood_effects(Luser, Lpartner, FALSE)
		apply_forceful_release(Luser, Lpartner, zone_text, hidden)
	else
		apply_gentle_release(Luser, Lpartner, zone_text, hidden)

/obj/item/organ/genital/penis/proc/cleanup_knot_state(mob/living/user, mob/living/partner)
	deltimer(knot_arousal_timer)
	deltimer(knot_release_timer)
	deltimer(knot_distance_timer)
	knot_arousal_timer = null
	knot_release_timer = null
	knot_distance_timer = null
	if(islist(knotted_genitals))
		for(var/obj/item/organ/genital/G in knotted_genitals)
			if(!QDELETED(G))
				G.is_knotted = FALSE
	else if(!QDELETED(knotted_genital))
		knotted_genital.is_knotted = FALSE
	knotted_genitals = null
	knotted_genital = null
	knot_zones = null
	knot_locked = FALSE
	knot_is_hidden = FALSE
	knot_following = FALSE
	knot_state = 0
	knot_partner = null
	knot_until = 0
	if(!QDELETED(user))
		if(user.active_knot == src)
			user.active_knot = null
		UnregisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
	if(!QDELETED(partner))
		if(partner.active_knot == src)
			partner.active_knot = null
		if(partner != user)
			UnregisterSignal(partner, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING))
		if(partner.has_movespeed_modifier(/datum/movespeed_modifier/knotting))
			partner.remove_movespeed_modifier(/datum/movespeed_modifier/knotting)

/obj/item/organ/genital/penis/proc/get_zone_text(target_zone)
	switch(target_zone)
		if(CUM_TARGET_VAGINA) return "влагалища"
		if(CUM_TARGET_ANUS) return "ануса"
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT) return "рта"
	return "тела"

/obj/item/organ/genital/penis/proc/apply_forceful_release(mob/living/user, mob/living/partner, zone_text, is_hidden)
	playsound(get_turf(user), 'sound/effects/snap01.ogg', 100, TRUE, INTERACTION_SOUND_EXTRARANGE(is_hidden, 0), local_only = is_hidden)

	user.visible_message(
		span_danger("Узел [user] с силой вырывается из [zone_text] [partner]!"),
		span_warning("Ты резко выдёргиваешь узел из [partner]! Это больно обоим."),
		vision_distance = INTERACTION_MESSAGE_RANGE(is_hidden),
		visible_message_flags = INTERACTION_MESSAGE_FLAGS(is_hidden)
	)

	to_chat(partner, span_userdanger("Ты чувствуешь резкую боль, когда узел [user] рвётся!"))
	if(!is_hidden)
		partner.emote("scream")
	partner.Stun(40)

	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)

/obj/item/organ/genital/penis/proc/apply_gentle_release(mob/living/user, mob/living/partner, zone_text, is_hidden)
	playsound(get_turf(user), 'sound/effects/snap01.ogg', 50, TRUE, INTERACTION_SOUND_EXTRARANGE(is_hidden, 0), local_only = is_hidden)

	user.visible_message(
		span_lewd("Узел [user] постепенно спадает, освобождая [partner] из [zone_text]."),
		span_love("Ты чувствуешь, как узел спадает, освобождая [partner]."),
		vision_distance = INTERACTION_MESSAGE_RANGE(is_hidden),
		visible_message_flags = INTERACTION_MESSAGE_FLAGS(is_hidden)
	)

	to_chat(partner, span_lewd("<font color='#ee6bee'>Ты ощущаешь, как узел [user] мягко выходит из твоего [zone_text].</font>"))

	if(prob(25))
		if(is_hidden)
			partner.moan(TRUE)
		else
			partner.emote("moan")

	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)

// ============================================================
// DISTANCE CHECKING (SIMPLIFIED)
// ============================================================
/obj/item/organ/genital/penis/proc/knot_distance_loop(mob/living/who)
	knot_distance_timer = null
	if(QDELETED(src) || !knot_locked || QDELETED(knot_partner))
		return

	if(!who)
		who = get_knot_user()

	if(istype(who, /mob/living))
		check_knot_distance_safe(who)

	if(!QDELETED(src) && knot_locked && !QDELETED(knot_partner) && !knot_distance_timer)
		knot_distance_timer = addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), who), KNOT_DISTANCE_CHECK_INTERVAL, TIMER_STOPPABLE)

/obj/item/organ/genital/penis/proc/check_knot_distance_safe(mob/living/user)
	if(!knot_locked)
		return
	if(QDELETED(user) || QDELETED(knot_partner) || get_knot_user() != user)
		cleanup_knot_state(user, knot_partner)
		return
	if(!get_turf(user) || !get_turf(knot_partner) || user.z != knot_partner.z)
		cleanup_knot_state(user, knot_partner)
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
	if(world.time < last_knot_strain + KNOT_STRAIN_COOLDOWN)
		return
	last_knot_strain = world.time
	to_chat(user, span_warning("Узел натягивается между тобой и [partner]!"))
	to_chat(partner, span_danger("Ты чувствуешь, как узел внутри натягивается и причиняет боль!"))

	if(!knot_is_hidden && prob(25))
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


/obj/item/organ/genital/penis/proc/handle_knot_break(mob/living/user, mob/living/partner, zone_text)
	to_chat(user, span_danger("Узел не выдерживает и рвётся!"))
	to_chat(partner, span_userdanger("Узел резко вырывается из тебя!"))

	user.apply_damage(rand(15, 25), STAMINA)
	user.apply_damage(rand(5, 10), BRUTE)
	partner.apply_damage(rand(10, 20), STAMINA)
	partner.apply_damage(rand(3, 6), BRUTE)

	if(!knot_is_hidden && prob(50))
		user.emote("scream")
	if(prob(25))
		if(knot_is_hidden)
			partner.moan(TRUE)
		else
			partner.emote("moan")

	release_knot(user, partner, knot_state, TRUE)

// ============================================================
// SYNCHRONOUS KNOT MOVEMENT
// ============================================================
// Called once per successful step for EITHER participant. A synthetic
// following step triggers a second signal; knot_following suppresses it.
/obj/item/organ/genital/penis/proc/on_knot_move(datum/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	if(knot_following)
		return
	var/mob/living/knot_user = get_knot_user()
	if(!knot_locked || QDELETED(knot_user) || QDELETED(knot_partner))
		cleanup_knot_state(knot_user, knot_partner)
		return
	if(source != knot_user && source != knot_partner)
		return
	var/mob/living/mover = source
	var/mob/living/follower = (mover == knot_user) ? knot_partner : knot_user
	var/turf/previous = get_turf(old_loc)
	var/turf/current = get_turf(mover)
	var/turf/follower_tile = get_turf(follower)
	if(!previous || !current || !follower_tile || current.z != follower_tile.z)
		cleanup_knot_state(knot_user, knot_partner)
		return
	// Forced moves and teleports must not drag somebody through obstacles.
	if(forced || previous.z != current.z)
		check_knot_distance_safe(knot_user)
		return
	// Manhattan distance notices sideways separation that get_dist() hides.
	var/old_separation = abs(previous.x - follower_tile.x) + abs(previous.y - follower_tile.y)
	var/new_separation = abs(current.x - follower_tile.x) + abs(current.y - follower_tile.y)
	var/old_tile_distance = max(abs(previous.x - follower_tile.x), abs(previous.y - follower_tile.y))
	var/new_tile_distance = max(abs(current.x - follower_tile.x), abs(current.y - follower_tile.y))
	if(new_separation > old_separation || new_tile_distance > old_tile_distance)
		// A new roll for EVERY outward step. No 1-second cooldown.
		if(prob(KNOT_STEP_BREAK_CHANCE))
			handle_knot_break(knot_user, knot_partner, get_zone_text(knot_state))
			return
		// Move the partner onto our previous tile, not onto our current tile.
		// step_towards respects solid turfs and movement restrictions.
		if(!follower.anchored && !follower.buckled && CHECK_ALL_MOBILITY(follower, MOBILITY_STAND | MOBILITY_MOVE))
			knot_following = TRUE
			step_towards(follower, previous)
			knot_following = FALSE
	// Failed follow, obstruction, or an independent move may leave strain.
	if(knot_locked)
		check_knot_distance_safe(knot_user)

/obj/item/organ/genital/penis/proc/cleanup_movement_signals()
	var/mob/living/knot_user = get_knot_user()
	if(!QDELETED(knot_user))
		UnregisterSignal(knot_user, COMSIG_MOVABLE_MOVED)
	if(!QDELETED(knot_partner) && knot_partner != knot_user)
		UnregisterSignal(knot_partner, COMSIG_MOVABLE_MOVED)

// ============================================================
// RESIST MECHANIC
// ============================================================
/obj/item/organ/genital/penis/proc/start_resist_attempt(mob/living/user)
	if(!knot_locked)
		to_chat(user, span_notice("Узел уже спал."))
		return

	var/mob/living/current_owner = get_knot_user()
	if(QDELETED(current_owner) || QDELETED(knot_partner))
		to_chat(user, span_warning("Цель отсутствует."))
		return

	var/mob/living/pen_owner = current_owner
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
	var/is_hidden = knot_is_hidden

	send_resist_start_messages(user, pen_owner, pen_partner, is_partner)

	if(prob(35))
		to_chat(user, span_danger("Тебе не удаётся найти удобное положение..."))
		if(!is_hidden && prob(40))
			user.emote(pick("pant", "whimper"))
		return

	if(!do_after(user, duration, target = is_partner ? pen_owner : pen_partner))
		to_chat(user, span_danger("Ты не смог освободиться от узла!"))
		if(!is_hidden && prob(40))
			user.emote(pick("scream", "pant"))
		return

	if(!knot_locked)
		to_chat(user, span_notice("Ты уже свободен."))
		return

	release_knot(pen_owner, pen_partner, knot_state, FALSE)
	send_resist_success_messages(user, pen_owner, pen_partner, is_partner, is_hidden)

/obj/item/organ/genital/penis/proc/send_resist_start_messages(mob/living/user, mob/living/pen_owner, mob/living/pen_partner, is_partner)
	var/msg_start
	if(is_partner)
		msg_start = "[user] начинает извиваться, пытаясь вытолкнуть узел [pen_owner]."
	else
		msg_start = "[user] осторожно пытается освободить узел из [pen_partner]."

	user.visible_message(
		span_notice(msg_start),
		span_notice("Ты начинаешь попытку освободиться от узла..."),
		vision_distance = INTERACTION_MESSAGE_RANGE(knot_is_hidden),
		visible_message_flags = INTERACTION_MESSAGE_FLAGS(knot_is_hidden)
	)

	to_chat(user, span_warning("Ты пытаешься освободиться... Не двигайся!"))

/obj/item/organ/genital/penis/proc/send_resist_success_messages(mob/living/user, mob/living/pen_owner, mob/living/pen_partner, is_partner, is_hidden)
	if(is_partner)
		to_chat(user, span_love("Узел постепенно выходит, принося облегчение."))
		if(prob(40))
			if(is_hidden)
				user.moan(TRUE)
			else
				user.emote(pick("moan", "blush"))
		if(!is_hidden && prob(20))
			pen_owner.emote(pick("groan", "pant"))
	else
		to_chat(user, span_love("Ты осторожно помогаешь узлу сойти."))
		if(!is_hidden && prob(25))
			user.emote(pick("sigh"))
		if(prob(25))
			if(is_hidden)
				pen_partner.moan(TRUE)
			else
				pen_partner.emote(pick("moan", "blush"))

// ============================================================
// HUMAN VERB INTEGRATION
// ============================================================
/mob/living/carbon/human/verb/knot_resist()
	set name = "Resist Knot"
	set category = "IC"
	set desc = "Попытаться освободиться от узла (если застрял)."
	if(!active_knot || QDELETED(active_knot) || !active_knot.knot_locked)
		to_chat(src, span_notice("Вы не связаны узлом."))
		return
	active_knot.start_resist_attempt(src)

/// Single source of truth for knot-capable equipment in the ERP menu and server.
/// This is queried on demand; there is no new processing loop.
/mob/living/proc/get_knotting_capability()
	if(iscyborg(src))
		var/mob/living/silicon/robot/R = src
		if(!R.synthetic_profile_selected)
			return SYNTHETIC_KNOT_NONE
		return R.synthetic_knot_style
	if(!ishuman(src))
		return SYNTHETIC_KNOT_NONE
	var/mob/living/carbon/human/H = src
	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
	if(QDELETED(P))
		return SYNTHETIC_KNOT_NONE
	P.update_knotting_from_shape()
	return P.knot_size

// Global admin diagnostic for isolated testing. Timeboxed, OFF by default.
// Real players who declined the preference are never opted in by this switch.
/proc/knotting_debug_subject(mob/living/M)
	if(QDELETED(M))
		return FALSE
	if(!M.client)
		return !M.ckey // freshly spawned test dummy, not an SSD player
	return check_rights_for(M.client, R_DEBUG)

/proc/knotting_debug_prefs_active()
	return world.time < GLOB.knot_debug_ignore_prefs_until

/// Unified check used by UI and try_apply_knot.
/proc/knotting_prefs_satisfied(mob/living/user, mob/living/partner)
	if(QDELETED(user) || QDELETED(partner))
		return FALSE
	if(user.client?.prefs?.sexknotting && partner.client?.prefs?.sexknotting)
		return TRUE
	return knotting_debug_prefs_active() && knotting_debug_subject(user) && knotting_debug_subject(partner)

/proc/try_apply_knot(mob/living/user, mob/living/partner, target_zone, force_override = FALSE, force_knot = FALSE, is_hidden = FALSE)
	if(QDELETED(user) || QDELETED(partner) || user == partner)
		return FALSE
	if(!(ishuman(user) || iscyborg(user)) || !(ishuman(partner) || iscyborg(partner)))
		return FALSE
	if(!force_override && !knotting_prefs_satisfied(user, partner))
		return FALSE
	if(!(target_zone in list(CUM_TARGET_VAGINA, CUM_TARGET_ANUS, CUM_TARGET_MOUTH, CUM_TARGET_THROAT)))
		return FALSE
	var/obj/item/organ/genital/penis/P
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		P = HU.getorganslot(ORGAN_SLOT_PENIS)
		if(!P || P.owner != user)
			return FALSE
		P.update_knotting_from_shape()
		var/threshold = HU.get_climax_threshold()
		if(threshold <= 0)
			return FALSE
		if(HU.get_lust() / threshold * 100 < 65 && !force_knot)
			return FALSE
	else
		var/mob/living/silicon/robot/R = user
		P = R.get_synthetic_knot()
	if(!P || QDELETED(P) || P.get_knot_user() != user || !P.knot_size)
		return FALSE
	var/was_active = P.knot_locked
	if(!P.do_knotting(user, partner, target_zone, force_knot, is_hidden))
		return FALSE
	if(!was_active)
		GLOB.knottings++
	return TRUE

// Borg verb parallels the existing human Resist Knot verb.
/mob/living/silicon/robot/verb/knot_resist_silicon()
	set name = "Resist Knot"
	set category = "Robot Commands"
	if(!active_knot || QDELETED(active_knot) || !active_knot.knot_locked)
		to_chat(src, span_notice("Вы не связаны узлом."))
		return
	active_knot.start_resist_attempt(src)

