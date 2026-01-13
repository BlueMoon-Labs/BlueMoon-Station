// ============================================================
// BlueMoon - Knotting core (standalone) //By Stasdvrz
// ============================================================
#include "bm_knotting_defines.dm"

/mob/living
	var/tmp/knot_resist_cd_until = 0   // антиспам для Resist
	//var/tmp/knot_action_cd_until = 0   // антиспам для попытки заузлиться (новый верб)


/obj/item/organ/genital/penis
	// 0 — нет узла; 1 — обычный узел; 2 — «hemi»/усиленный
	var/knot_size = 0
	var/knot_locked = FALSE
	var/knot_until = 0      // world.time, когда спадёт
	var/knot_strength = 1   // на будущее
	var/knot_state = 0
	var/mob/living/knot_partner = null
	var/last_knot_check = 0

/obj/item/organ/genital/penis/Initialize(mapload)
	. = ..()
	update_knotting_from_shape()

/obj/item/organ/genital/penis/update_appearance()
	. = ..()
	update_knotting_from_shape()

/obj/item/organ/genital/penis/proc/update_knotting_from_shape()
	var/datum/sprite_accessory/S = GLOB.cock_shapes_list[shape]
	var/state = lowertext(S ? S.icon_state : "[shape]")

	// Taur shape check
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
// 🔗 Основная механика узла
// ============================================================

/obj/item/organ/genital/penis/proc/do_knotting(mob/living/user, mob/living/partner, target_zone, force_success = FALSE)
	if(!knot_size || knot_locked || !user || !partner)
		return FALSE

	// 🔥 Проверка возбуждения
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		if(!HU.lust || HU.lust < 60)
			return FALSE

	// базовый шанс
	var/knot_chance = 20 + (knot_size * 8) + (knot_strength * 4)

	// возбуждение через органы
	var/total_genitals = 0
	var/aroused_genitals = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		for(var/obj/item/organ/genital/G in H.internal_organs)
			if(G.genital_flags & GENITAL_CAN_AROUSE)
				total_genitals++
				if(G.aroused_state)
					aroused_genitals++
	var/arousal_ratio = (total_genitals > 0) ? (aroused_genitals / total_genitals) : 0
	if(arousal_ratio >= 0.8)
		knot_chance += round(20 * ((arousal_ratio - 0.8) / 0.2))

	// эстральный бонус
	if(HAS_TRAIT(partner, TRAIT_ESTROUS_ACTIVE))
		knot_chance += 10
		to_chat(user, span_love("Тело [partner] отзывчивее из-за эстрального цикла."))

	knot_chance = clamp(knot_chance, 0, KNOTTING_MAX_CHANCE)

	// зона и длительность
	var/zone_text = ""
	var/duration_min = 600 SECONDS
	var/duration_max = 900 SECONDS
	if(target_zone == CUM_TARGET_VAGINA)
		if(!partner.has_vagina()) return FALSE
		zone_text = "влагалище"
		knot_chance += 10
	else if(target_zone == CUM_TARGET_ANUS)
		if(!partner.has_anus()) return FALSE
		zone_text = "анус"
		knot_chance -= 5
		duration_min *= 0.8
		duration_max *= 0.9
	else if(target_zone == CUM_TARGET_MOUTH)
		if(!partner.has_mouth()) return FALSE
		zone_text = "рот"
		knot_chance -= 15
		duration_min *= 0.1
		duration_max *= 0.2
	else
		return FALSE

	// 🚫 У партнёра уже активен узел
	if(ishuman(partner))
		var/mob/living/carbon/human/Hp = partner
		for(var/obj/item/organ/genital/penis/otherP in Hp.internal_organs)
			if(otherP.knot_locked && otherP.knot_state == target_zone)
				knot_chance = 0
				break

	if(!force_success && !prob(knot_chance))
		return FALSE

	// === активация узла ===
	knot_locked = TRUE
	knot_partner = partner
	knot_state = target_zone
	var/dur = rand(duration_min, duration_max)
	knot_until = world.time + dur

	// поводковая механика
	if(istype(user, /mob/living) && istype(partner, /mob/living))
		var/mob/living/master = user
		var/mob/living/pet = partner
		if(!pet.has_movespeed_modifier(/datum/movespeed_modifier/leash))
			pet.add_movespeed_modifier(/datum/movespeed_modifier/leash)
		RegisterSignal(master, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)
		RegisterSignal(pet, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)

	// оповещение
	visible_message(list(user, partner),
		span_love("<b>[user]</b> застревает узлом в [zone_text] <b>[partner]</b>!"),
		span_love("Твой узел набухает и фиксируется внутри [partner].")
	)

	// 💭 Положительный mood
	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)

	// Афродизиачный эффект при узлировании
	for(var/mob/living/M in list(user, partner))
		if(!M?.client?.prefs?.arousable || (M.client?.prefs?.cit_toggles & NO_APHRO))
			continue

		// случайные стоны / эмоуты
		if(prob(10))
			if(prob(50))
				M.say(pick("Ох-мхх...", "Ахх-р...", "Амрфпф...", "Мрр-ах...", "Ааах...", "Мнх...", "Ммм..."))
			else
				M.emote(pick("moan", "blush", "pant"))

		// чувственные тексты
		if(prob(15))
			var/msg = pick(
				"Ты чувствуешь, как всё внутри горит от удовольствия...",
				"Каждое движение узла усиливает твоё желание...",
				"Твоё тело отзывается на каждую пульсацию...")
			to_chat(M, span_love(msg))

		// усиление возбуждения + ограничение роста lust
		if(ishuman(M))
			var/mob/living/carbon/human/HM = M
			HM.adjust_arousal(100, "knotting", aphro = TRUE)

			if(hascall(HM, "get_lust") && hascall(HM, "get_climax_threshold"))
				var/max_lust = HM.get_climax_threshold()
				if(max_lust <= 0)
					max_lust = 100

				var/current_lust = HM.get_lust()
				if(current_lust < max_lust)
					var/to_add = NORMAL_LUST
					if(current_lust + to_add > max_lust)
						to_add = max_lust - current_lust
					if(to_add > 0)
						HM.add_lust(to_add)
			else
				HM.add_lust(NORMAL_LUST)
		else
			M.add_lust(NORMAL_LUST)

		var/climax_threshold = hascall(M, "get_climax_threshold") ? M.get_climax_threshold() : 100
		if(climax_threshold <= 0)
			climax_threshold = 100
		if(M.lust / climax_threshold < 0.65)
			M.add_lust(NORMAL_LUST)

		REMOVE_TRAIT(M, TRAIT_NEVERBONER, "KNOT_AROUSAL")

	// ⚡ Периодическое усиление возбуждения (авто-стимуляция узла)
	addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), 4 SECONDS)

	// партнёрское сообщение
	var/list/messages = list()
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

	to_chat(partner, span_love("<font color='#ff7ff5'><b>Узел блокирует выход — вы соединены с [user]!</b></font>"))
	to_chat(partner, span_love("[pick(messages)]"))

	// возбуждение при узловке
	if(ishuman(user))
		var/mob/living/carbon/human/HU2 = user
		HU2.handle_post_sex(NORMAL_LUST, null, partner)
	if(ishuman(partner))
		var/mob/living/carbon/human/HP = partner
		HP.handle_post_sex(NORMAL_LUST, null, user)

	addtimer(CALLBACK(src, PROC_REF(release_knot), user, partner, target_zone, FALSE), dur)
	addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), user), 5 SECONDS)
	return TRUE


// 🔁 повторяющийся эффект возбуждения, пока узел активен
/obj/item/organ/genital/penis/proc/knot_arousal_tick(mob/living/user, mob/living/partner)
	if(QDELETED(src) || !knot_locked || QDELETED(user) || QDELETED(partner))
		return // узел снят, выходим

	for(var/mob/living/M in list(user, partner))
		if(!M?.client?.prefs?.arousable)
			continue

		var/add_amount = rand(10, 20)

		if(ishuman(M) && hascall(M, "get_lust") && hascall(M, "get_climax_threshold"))
			var/max_lust = M.get_climax_threshold()
			if(max_lust <= 0)
				max_lust = 100

			var/current_lust = M.get_lust()
			if(current_lust >= max_lust)
				continue

			if(current_lust + add_amount > max_lust)
				add_amount = max_lust - current_lust
			if(add_amount <= 0)
				continue

			M.add_lust(add_amount)
		else
			M.add_lust(add_amount)

		if(prob(8))
			M.emote(pick("moan","pant","blush"))

	// продолжаем, пока активен узел
	addtimer(CALLBACK(src, PROC_REF(knot_arousal_tick), user, partner), 5 SECONDS)

// ============================================================
//  Release: мягкий спад и силовой разрыв
// ============================================================

/obj/item/organ/genital/penis/proc/release_knot(mob/living/user, mob/living/partner, target_zone, forceful = FALSE)
	if(!knot_locked)
		return

	// сохраняем локальные ссылки до зануления
	var/mob/living/Luser = user
	var/mob/living/Lpartner = partner

	// сбрасываем состояние узла
	knot_locked = FALSE
	knot_state  = 0
	knot_partner = null
	knot_until  = 0

	var/zone_text = "тела"
	switch(target_zone)
		if(CUM_TARGET_VAGINA) zone_text = "влагалища"
		if(CUM_TARGET_ANUS)   zone_text = "ануса"
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT) zone_text = "рта"

	if(forceful)
		//  Силовой разрыв
		playsound(get_turf(Luser), 'sound/effects/snap01.ogg', 100, TRUE)
		Luser.visible_message(
			span_danger(" Узел [Luser] с силой вырывается из [zone_text] [Lpartner]!"),
			span_warning("Ты резко выдёргиваешь узел из [Lpartner]! Это больно обоим.")
		)
		to_chat(Lpartner, span_userdanger("Ты чувствуешь резкую боль, когда узел [Luser] рвётся!"))
		Lpartner.emote("scream")

		if(istype(Lpartner, /mob/living))
			Lpartner.Stun(40)
			if(prob(40))
				to_chat(Lpartner, span_danger(" Узел вырвался слишком резко, оставив боль."))
	else
		//  Мягкий спад
		playsound(get_turf(Luser), 'sound/effects/snap01.ogg', 50, 1)
		Luser.visible_message(
			span_lewd(" Узел [Luser] постепенно спадает, освобождая [Lpartner] из [zone_text]."),
			span_love("Ты чувствуешь, как узел спадает, освобождая [Lpartner].")
		)
		to_chat(Lpartner, span_lewd("<font color='#ee6bee'>Ты ощущаешь, как узел [Luser] мягко выходит из твоего [zone_text].</font>"))
		if(prob(25)) Lpartner.emote("moan")

	// 💭 очищаем положительные эффекты (если были)
	if(ishuman(Luser))
		SEND_SIGNAL(Luser, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(Luser, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")
	if(ishuman(Lpartner))
		SEND_SIGNAL(Lpartner, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(Lpartner, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")

	// FIX: негатив добавляем ТОЛЬКО при силовом разрыве.
	// При мягком — можно дать «облегчение», если у тебя есть такой datum; иначе ничего не даём.
	if(forceful)
		if(ishuman(Luser))
			SEND_SIGNAL(Luser, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)
		if(ishuman(Lpartner))
			SEND_SIGNAL(Lpartner, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)
	else
		if(ishuman(Luser))
			SEND_SIGNAL(Luser, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)
		if(ishuman(Lpartner))
			SEND_SIGNAL(Lpartner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)

	// FIX: снимаем «поводок» и отписываемся от сигналов, используя partner из аргумента,
	// а не занулённый knot_partner.
	if(istype(Lpartner, /mob/living))
		if(Lpartner.has_movespeed_modifier(/datum/movespeed_modifier/leash))
			Lpartner.remove_movespeed_modifier(/datum/movespeed_modifier/leash)

	if(istype(Luser, /mob/living))
		UnregisterSignal(Luser, COMSIG_MOVABLE_MOVED)
	if(istype(Lpartner, /mob/living))
		UnregisterSignal(Lpartner, COMSIG_MOVABLE_MOVED)


// ============================================================
// 🔁 Циклическая проверка дистанции (≤1 тайл) — безопасный цикл
// ============================================================

/obj/item/organ/genital/penis/proc/knot_distance_loop(mob/living/who)
	// орган или партнёр удалены / узел уже снят — выходим без перепланировки
	if(QDELETED(src) || !knot_locked || QDELETED(knot_partner))
		return

	// если не передали, берём владельца органа
	if(!who && ismob(owner))
		who = owner

	// страхуемся от некорректного типа
	if(istype(who, /mob/living))
		// эта проверка на /mob/living — там уже защита по состоянию узла
		who.check_knot_distance()

	// если узел всё ещё активен — перепланируем цикл
	if(!QDELETED(src) && knot_locked && !QDELETED(knot_partner))
		addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), who), 5 SECONDS)



// ============================================================
// 🚷 Автоматическая проверка дистанции
// ============================================================

/mob/living/var/tmp/in_knot_check = FALSE

/mob/living/proc/check_knot_distance()
	// ⚠️ Предотвращаем рекурсивные вызовы
	if(in_knot_check)
		return
	in_knot_check = TRUE

	var/obj/item/organ/genital/penis/P = getorganslot(ORGAN_SLOT_PENIS)
	if(!P || !P.knot_locked || !P.knot_partner)
		in_knot_check = FALSE
		return

	var/mob/living/partner = P.knot_partner
	if(!istype(partner))
		in_knot_check = FALSE
		return

	var/dist = get_dist(src, partner)
	if(dist <= 1)
		in_knot_check = FALSE
		return

	var/zone_text = "тела"
	switch(P.knot_state)
		if(CUM_TARGET_VAGINA) zone_text = "влагалища"
		if(CUM_TARGET_ANUS) zone_text = "ануса"
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT) zone_text = "рта"

	to_chat(src, span_warning(" Узел болезненно натягивается в области [zone_text]!"))
	to_chat(partner, span_danger(" Ты чувствуешь, как узел внутри твоего [zone_text] натягивается и причиняет боль!"))

	visible_message(
		list(src, partner),
		span_danger(" Между [src] и [partner] натянулся узел — связь вот-вот порвётся!"),
		span_notice("Ты ощущаешь сильное напряжение между ними...")
	)

	//  80% шанс на силовой разрыв
	if(prob(80))
		var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
		P.release_knot(src, partner, zone, TRUE)
		to_chat(src, span_danger(" Узел не выдерживает и резко вырывается!"))
		to_chat(partner, span_userdanger(" Узел резко вырывается из твоего [zone_text]!"))
	else
		to_chat(src, span_warning("Ты чувствуешь, что узел вот-вот сорвётся..."))

	// ✅ Двусторонняя проверка — вызываем у партнёра, если он не в процессе
	if(!partner.in_knot_check && istype(partner, /mob/living))
		partner.check_knot_distance()

	in_knot_check = FALSE

/obj/item/organ/genital/penis/proc/on_knot_move()
	SIGNAL_HANDLER

	if(QDELETED(src) || !knot_locked || QDELETED(knot_partner))
		UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
		if(istype(knot_partner, /mob/living))
			UnregisterSignal(knot_partner, COMSIG_MOVABLE_MOVED)
		return

	var/mob/living/user = owner
	if(!user || !knot_partner || !knot_locked)
		return

	var/mob/living/partner = knot_partner
	if(QDELETED(user) || QDELETED(partner))
		return

	var/dist = get_dist(user, partner)
	if(dist <= 1)
		return

	// 🔁 Антиспам проверка (не чаще раза в секунду)
	if(!src.last_knot_check)
		src.last_knot_check = 0
	if(world.time < src.last_knot_check + 10)
		return
	src.last_knot_check = world.time

	// ⚠️ Если они немного натянули узел
	if(dist == 2)
		to_chat(user, span_warning(" Узел натягивается между тобой и [partner]!"))
		to_chat(partner, span_danger(" Ты чувствуешь, как узел внутри натягивается и причиняет боль!"))

		if(prob(25))
			partner.emote("whimper")

		// 💢 Урон от натяжения
		var/stam_damage = rand(5, 10)
		var/brute_damage = rand(1, 3)
		user.apply_damage(stam_damage * 2, STAMINA)     // держатель узла страдает сильнее
		user.apply_damage(brute_damage * 2, BRUTE)
		partner.apply_damage(stam_damage, STAMINA)
		partner.apply_damage(brute_damage, BRUTE)

		// 🔸 Возможность короткого "оглушения" при боли
		if(prob(20))
			partner.Stun(10)
			if(prob(10))
				user.Stun(15)

		// 🔹 Малый шанс самопроизвольного разрыва
		if(prob(10))
			to_chat(user, span_danger(" Узел не выдерживает и рвётся!"))
			to_chat(partner, span_userdanger(" Узел резко вырывается из тебя!"))
			release_knot(user, partner, (knot_state ? knot_state : CUM_TARGET_VAGINA), TRUE)
			return

		// 🔹 Небольшое «подтягивание» партнёра
		if(prob(70))
			apply_tug_mob_to_mob(partner, user, 1)

	//  Если ушли дальше чем на 2 тайла — гарантированный разрыв
	else if(dist > 2)
		to_chat(user, span_danger(" Узел не выдерживает и рвётся!"))
		to_chat(partner, span_userdanger(" Узел резко вырывается из тебя!"))
		release_knot(user, partner, (knot_state ? knot_state : CUM_TARGET_VAGINA), TRUE)

		//  Боль и травма при разрыве
		user.apply_damage(rand(15, 25), STAMINA)
		user.apply_damage(rand(5, 10), BRUTE)
		partner.apply_damage(rand(10, 20), STAMINA)
		partner.apply_damage(rand(3, 6), BRUTE)

		to_chat(user, span_danger(" Ты чувствуешь резкую боль — узел вырывается наружу!"))
		to_chat(partner, span_danger(" Твоя плоть горит болью от резкого разрыва узла!"))
		if(prob(50))
			user.emote("scream")
		if(prob(25))
			partner.emote("moan")

// ============================================================
//  Grab-style Resist (оба могут освободиться)
// ============================================================

/obj/item/organ/genital/penis/proc/start_resist_attempt(mob/living/user)
	if(!knot_locked)
		to_chat(user, span_notice("Узел уже спал."))
		return

	var/mob/living/pen_owner   = owner
	var/mob/living/pen_partner = knot_partner
	if(!pen_owner || !pen_partner)
		to_chat(user, span_warning("Цель отсутствует."))
		return

	//  антиспам: активный do_after?
	if(DOING_INTERACTION_WITH_TARGET(user, owner) || DOING_INTERACTION_WITH_TARGET(user, knot_partner))
		to_chat(user, span_warning("Ты уже пытаешься освободиться — не дёргайся!"))
		return

	//  антиспам: локальный кулдаун на нажатия (5 секунд)
	if(world.time < user.knot_resist_cd_until)
		to_chat(user, span_warning("Ты только что пытался освободиться — подожди немного..."))
		return
	user.knot_resist_cd_until = world.time + 50  // 5 SECONDS

	var/is_partner = (user == pen_partner)

	// сообщение начала попытки
	var/msg_start
	if(is_partner)
		msg_start = "[user] начинает извиваться, пытаясь вытолкнуть узел [pen_owner]."
	else
		msg_start = "[user] осторожно пытается освободить узел из [pen_partner]."

	user.visible_message(
		span_notice(msg_start),
		span_notice("Ты начинаешь попытку освободиться от узла...")
	)

	var/duration = is_partner ? 4 SECONDS : 3 SECONDS
	to_chat(user, span_warning("Ты пытаешься освободиться... Не двигайся!"))

	// 🔸 шанс на неудачу попытки
	if(prob(35))
		to_chat(user, span_danger("Тебе не удаётся найти удобное положение..."))
		if(prob(40)) user.emote(pick("pant","whimper"))
		return

	// сам процесс
	if(!do_after(user, duration, target = is_partner ? pen_owner : pen_partner))
		to_chat(user, span_danger("Ты не смог освободиться от узла!"))
		if(prob(40)) user.emote(pick("scream","pant"))
		return

	// успех — мягкий спад
	if(!knot_locked)
		to_chat(user, span_notice("Ты уже свободен."))
		return

	var/zone = knot_state ? knot_state : CUM_TARGET_VAGINA
	release_knot(pen_owner, pen_partner, zone, FALSE)

	if(is_partner)
		to_chat(user, span_love("Узел постепенно выходит, принося облегчение."))
		if(prob(40)) user.emote(pick("moan","blush"))
		if(prob(20)) pen_owner.emote(pick("groan","pant"))
	else
		to_chat(user, span_love("Ты осторожно помогаешь узлу сойти."))
		if(prob(25)) user.emote(pick("sigh"))
		if(prob(25)) pen_partner.emote(pick("moan","blush"))

// ============================================================
// Верб: Resist Knot (обёртка над обычным Resist)
// ============================================================

/mob/living/carbon/human/verb/knot_resist()
	set name = "Resist Knot"
	set category = "IC"
	set desc = "Попытаться освободиться от узла (если застрял)."

	// Просто вызываем стандартный Resist, который уже умеет
	// проверять узел и запускать start_resist_attempt().
	resist()

/* // Оставлю на потом (не работает блятьц)
// ============================================================
// Verb: Try Knot (ручное заузливание)
// ============================================================

/mob/living/carbon/human/verb/knot_attempt()
	set name = "Try Knot"
	set category = "IC"
	set desc = "Попробовать заузлить узелом партнёра рядом."

	var/mob/living/carbon/human/H = src

	// антиспам / проверка на активное взаимодействие
	for(var/mob/living/L in view(1, H))
		if(DOING_INTERACTION_WITH_TARGET(H, L))
			to_chat(H, span_warning("Ты уже выполняешь другое действие — подожди немного."))
			return

	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!P || P.knot_locked)
		to_chat(H, span_warning("Твой узел не готов или уже зафиксирован."))
		return

	// выбор цели рядом
	var/list/moblist = list()
	for(var/mob/living/carbon/human/M in view(1, H))
		if(M != H)
			moblist += M
	if(!length(moblist))
		to_chat(H, span_notice("Рядом нет подходящих целей."))
		return

	var/mob/living/carbon/human/target = input(H, "Кого заузлить?", "Try Knot") as null|anything in moblist
	if(!target)
		return

	// проверка валидности зоны
	var/list/L = list("влагалище" = CUM_TARGET_VAGINA, "анус" = CUM_TARGET_ANUS, "рот" = CUM_TARGET_MOUTH)
	var/choice = input(H, "Куда заузлить?", "Try Knot") as null|anything in L
	if(!choice)
		return

	var/zone = L[choice]

	to_chat(H, span_notice("Ты пытаешься заузлить [target]..."))
	if(do_after(H, 3 SECONDS, target = target))
		if(!P.knot_locked)
			P.do_knotting(H, target, zone)
	else
		to_chat(H, span_warning("Ты не смог завершить попытку заузливания."))
*/
/mob/living/carbon/human/resist()
	//  Узловая проверка перед стандартным Resist
	var/obj/item/organ/genital/penis/P = getorganslot(ORGAN_SLOT_PENIS)
	if(P && P.knot_locked)
		to_chat(src, span_love("Ты пытаешься освободиться от узла..."))
		P.start_resist_attempt(src)
		return

	// Если у кого-то рядом узел с тобой
	for(var/mob/living/carbon/human/other in view(1, src))
		if(other == src) continue
		var/obj/item/organ/genital/penis/P2 = other.getorganslot(ORGAN_SLOT_PENIS)
		if(P2 && P2.knot_locked && P2.knot_partner == src)
			to_chat(src, span_love("Ты пытаешься вырваться из узла [other]!"))
			P2.start_resist_attempt(src)
			return

	..()

// ============================================================
// 🌐 Универсальный прок: попытка активировать узел при сексе
// ============================================================

// force_override — игнорировать префы
// force_knot     — гарантировать срабатывание узла (если технически возможно)
/proc/try_apply_knot(mob/living/user, mob/living/partner, target_zone, force_override = FALSE, force_knot = FALSE)
	// Проверка корректных типов
	if(!ishuman(user) || !ishuman(partner))
		return

	// Проверка префов
	if(!force_override)
		if(!user?.client?.prefs.sexknotting || !partner?.client?.prefs.sexknotting)
			return

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

	var/source = initiator.last_genital
	if(istype(source, /obj/item/organ/genital/penis))
		P = source
	else if(istype(receiver.last_genital, /obj/item/organ/genital/penis))
		P = receiver.last_genital
		var/tmp = initiator
		initiator = receiver
		receiver = tmp
	else
		return

	// Проверка на блокировку
	if(!P.knot_size || P.knot_locked)
		return

	// 🎯 Проверка возбуждения владельца
	var/effective_lust = 0
	if(istype(initiator, /mob/living/carbon))
		var/mob/living/carbon/C = initiator
		if(hascall(C, "get_lust") && hascall(C, "get_climax_threshold"))
			var/max_lust = C.get_climax_threshold()
			if(max_lust > 0)
				effective_lust = (C.get_lust() / max_lust) * 100

	if(effective_lust < 65 && !force_knot)
		return

	// 🎲 Шанс узла
	var/chance = 10 + (P.knot_size * 10)
	if(effective_lust >= 80)
		chance += 10
	if(HAS_TRAIT(receiver, TRAIT_ESTROUS_ACTIVE))
		chance += 5

	chance = clamp(chance, 5, 60)

	// Если явно попросили — делаем 100% шанс
	if(force_knot)
		chance = 100

	if(force_knot || prob(chance))
		if(P.do_knotting(initiator, receiver, target_zone, force_knot))
			to_chat(initiator, span_love(" Ты чувствуешь, как узел набухает внутри [receiver]!"))
			to_chat(receiver, span_love(" Ты ощущаешь, как узел [initiator] застревает внутри!"))
			GLOB.knottings++
