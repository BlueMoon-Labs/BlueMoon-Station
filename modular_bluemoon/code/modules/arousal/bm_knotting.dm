// ============================================================
// BlueMoon - Knotting core (standalone) //By Stasdvrz
// ============================================================
#include "bm_knotting_defines.dm"

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
	if(istype(T))
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

/obj/item/organ/genital/penis/proc/do_knotting(mob/living/user, mob/living/partner, target_zone)
	if(!knot_size || knot_locked || !user || !partner)
		return FALSE

	// 🔥 Проверка на возбуждение
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		if(!HU.lust || HU.lust < 60) // меньше 60% — не узлируем
			return FALSE

	// базовый шанс
	var/knot_chance = 20 + (knot_size * 8) + (knot_strength * 4)

	// === возбуждение через органы ===
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
		var/arousal_bonus = round(20 * ((arousal_ratio - 0.8) / 0.2))
		knot_chance += arousal_bonus

	// === эстральный цикл ===
	if(HAS_TRAIT(partner, TRAIT_ESTROUS_ACTIVE))
		knot_chance += 10
		to_chat(user, span_love("✨ Тело [partner] отзывчивее из-за эстрального цикла."))

	knot_chance = clamp(knot_chance, 0, KNOTTING_MAX_CHANCE)

	// === зона и длительность ===
	var/zone_text = ""
	var/duration_min = 60 SECONDS
	var/duration_max = 120 SECONDS

	if(target_zone == CUM_TARGET_VAGINA)
		if(!partner.has_vagina()) return FALSE
		zone_text = "влагалище"
		knot_chance += 10
	else if(target_zone == CUM_TARGET_ANUS)
		if(!partner.has_anus()) return FALSE
		zone_text = "анус"
		knot_chance -= 5
		duration_min = round(duration_min * 0.8)
		duration_max = round(duration_max * 0.9)
	else if(target_zone == CUM_TARGET_MOUTH)
		if(!partner.has_mouth()) return FALSE
		zone_text = "рот"
		knot_chance -= 15
		duration_min = round(duration_min * 0.5)
		duration_max = round(duration_max * 0.6)
	else
		return FALSE

// 🚫 Проверка: если у партнёра уже активен узел в этой зоне — не срабатывает второй
	if(ishuman(partner))
		var/mob/living/carbon/human/Hp = partner
		for(var/obj/item/organ/genital/penis/otherP in Hp.internal_organs)
			if(otherP.knot_locked && otherP.knot_state == target_zone)
				// Просто снижаем шанс до нуля, чтобы не прокнуло
				knot_chance = 0
				break


	if(!prob(knot_chance))
		return FALSE

	knot_locked = TRUE
	knot_partner = partner
	knot_state = target_zone
	var/dur = rand(duration_min, duration_max)
	knot_until = world.time + dur

	// 💫 Активируем эффект поводка между партнёрами
	if(istype(user, /mob/living) && istype(partner, /mob/living))
		var/mob/living/master = user
		var/mob/living/pet = partner

		// Снижаем скорость партнёра, как будто на поводке
		if(!pet.has_movespeed_modifier(/datum/movespeed_modifier/leash))
			pet.add_movespeed_modifier(/datum/movespeed_modifier/leash)

		// Регистрация “натяжения” при движении
		RegisterSignal(master, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)
		RegisterSignal(pet, COMSIG_MOVABLE_MOVED, PROC_REF(on_knot_move), TRUE)


	visible_message(list(user, partner),
		span_lewd("<b>[user]</b> застревает узлом в [zone_text] <b>[partner]</b>!"),
		span_notice("Твой узел набухает и фиксируется внутри [partner].")
	)

// 💭 Эффекты настроения при успешном узле (оба получают положительные эмоции)
	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_satisfied", /datum/mood_event/knotting_satisfied)

	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_linked", /datum/mood_event/knotting_linked)

	// партнёру текст
	var/partner_msg
	switch(target_zone)
		if(CUM_TARGET_VAGINA)
			switch(shape)
				if("Barbed, Knotted")
					partner_msg = "Ты ощущаешь, как шипованный узел пульсирует в твоей киске, медленно выталкивая волны горячего семени..."
				if("Knotted Hemi", "Barbed, Knotted Hemi")
					partner_msg = "Двойные узлы туго запирают тебя, внутри всё ещё чувствуется пульсирующая эякуляция..."
				if("Knotted")
					partner_msg = "Узел распухает в самой глубине, перекрывая выход, а сперма всё ещё вырывается наружу..."
				else
					partner_msg = "Ты ощущаешь, как внутри тебя пульсирует член, извергая остатки семени..."
		if(CUM_TARGET_ANUS)
			switch(shape)
				if("Barbed, Knotted")
					partner_msg = "Ты чувствуешь, как шипованный узел пульсирует в твоём анусе..."
				if("Knotted Hemi", "Barbed, Knotted Hemi")
					partner_msg = "Двойные узлы давят изнутри, горячая сперма всё ещё прорывается наружу..."
				if("Knotted")
					partner_msg = "Узел полностью перекрыл выход, ты чувствуешь, как семя движется внутри..."
				else
					partner_msg = "Ты ощущаешь, как пульсации члена внутри продолжаются..."
		if(CUM_TARGET_MOUTH)
			switch(shape)
				if("Barbed, Knotted")
					partner_msg = "Узел распухает у тебя во рту, сперма всё ещё вырывается внутрь..."
				if("Knotted Hemi", "Barbed, Knotted Hemi")
					partner_msg = "Двойные узлы запирают рот, сперма медленно вытекает, ты чувствуешь биение..."
				if("Knotted")
					partner_msg = "Узел распух у тебя во рту, горячие капли всё ещё вырываются внутрь..."
				else
					partner_msg = "Ты чувствуешь, как орган всё ещё выпускает последние капли, заполняя рот..."
		else
			partner_msg = "Ты чувствуешь, как узел набухает и пульсирует внутри, выпуская остатки семени."

	to_chat(partner, span_lewd("[partner_msg]"))

	// 💗 Возбуждение при узловке
	if(ishuman(user))
		var/mob/living/carbon/human/HU = user
		HU.handle_post_sex(NORMAL_LUST, null, partner)

	if(ishuman(partner))
		var/mob/living/carbon/human/HP = partner
		HP.handle_post_sex(NORMAL_LUST, null, user)

	// Таймер спада узла
	addtimer(CALLBACK(src, PROC_REF(release_knot), user, partner, target_zone, FALSE), dur)

	// Таймер проверки дистанции (каждые 5 сек)
	addtimer(CALLBACK(src, PROC_REF(knot_distance_loop), user), 5 SECONDS)
	return TRUE


// ============================================================
// 💥 Release: мягкий спад и силовой разрыв
// ============================================================

/obj/item/organ/genital/penis/proc/release_knot(mob/living/user, mob/living/partner, target_zone, forceful = FALSE)
	if(!knot_locked)
		return

	knot_locked = FALSE
	knot_state = 0
	knot_partner = null
	knot_until = 0

	var/zone_text = "тела"
	switch(target_zone)
		if(CUM_TARGET_VAGINA) zone_text = "влагалища"
		if(CUM_TARGET_ANUS) zone_text = "ануса"
		if(CUM_TARGET_MOUTH, CUM_TARGET_THROAT) zone_text = "рта"

	if(forceful)
		// 💥 Силовой разрыв
		playsound(get_turf(user), 'sound/effects/dismember.ogg', 90, TRUE)
		user.visible_message(
			span_danger("💥 Узел [user] с силой вырывается из [zone_text] [partner]!"),
			span_warning("Ты резко выдёргиваешь узел из [partner]! Это больно обоим.")
		)
		to_chat(partner, span_userdanger("Ты чувствуешь резкую боль, когда узел [user] рвётся!"))
		partner.emote("scream")

		if(istype(partner, /mob/living))
			partner.Stun(40)
			if(prob(40))
				to_chat(partner, span_danger("🔥 Узел вырвался слишком резко, оставив боль."))
	else
		// 💧 Мягкий спад
		playsound(get_turf(user), 'sound/effects/snap01.ogg', 50, 1)
		user.visible_message(
			span_lewd("💧 Узел [user] постепенно спадает, освобождая [partner] из [zone_text]."),
			span_notice("Ты чувствуешь, как узел спадает, освобождая [partner].")
		)
		to_chat(partner, span_lewd("<font color='#c0aaff'>Ты ощущаешь, как узел [user] мягко выходит из твоего [zone_text].</font>"))
		if(prob(25)) partner.emote("moan")

	// 💭 Снятие положительных эмоций, если они были
	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(user, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")

	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_CLEAR_MOOD_EVENT, "knotting_satisfied")
		SEND_SIGNAL(partner, COMSIG_CLEAR_MOOD_EVENT, "knotting_linked")

	// 💢 И добавляем негативное настроение
	if(ishuman(user))
		SEND_SIGNAL(user, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)
	if(ishuman(partner))
		SEND_SIGNAL(partner, COMSIG_ADD_MOOD_EVENT, "knotting_painful", /datum/mood_event/knotting_painful)

	// 💨 Удаляем “поводок”, если он был
	if(knot_partner)
		if(partner.has_movespeed_modifier(/datum/movespeed_modifier/leash))
			partner.remove_movespeed_modifier(/datum/movespeed_modifier/leash)

		// 💨 Очистка сигналов движения
		if(istype(user, /mob/living))
			UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		if(istype(partner, /mob/living))
			UnregisterSignal(partner, COMSIG_MOVABLE_MOVED)


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
	if(istype(who))
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

	to_chat(src, span_warning("❗ Узел болезненно натягивается в области [zone_text]!"))
	to_chat(partner, span_danger("💢 Ты чувствуешь, как узел внутри твоего [zone_text] натягивается и причиняет боль!"))

	visible_message(
		list(src, partner),
		span_danger("💥 Между [src] и [partner] натянулся узел — связь вот-вот порвётся!"),
		span_notice("Ты ощущаешь сильное напряжение между ними...")
	)

	// 💥 80% шанс на силовой разрыв
	if(prob(80))
		var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
		P.release_knot(src, partner, zone, TRUE)
		to_chat(src, span_danger("💥 Узел не выдерживает и резко вырывается!"))
		to_chat(partner, span_userdanger("💥 Узел резко вырывается из твоего [zone_text]!"))
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
		to_chat(user, span_warning("❗ Узел натягивается между тобой и [partner]!"))
		to_chat(partner, span_danger("💢 Ты чувствуешь, как узел внутри натягивается и причиняет боль!"))

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
			to_chat(user, span_danger("💥 Узел не выдерживает и рвётся!"))
			to_chat(partner, span_userdanger("💥 Узел резко вырывается из тебя!"))
			release_knot(user, partner, (knot_state ? knot_state : CUM_TARGET_VAGINA), TRUE)
			return

		// 🔹 Небольшое «подтягивание» партнёра
		if(prob(70))
			apply_tug_mob_to_mob(partner, user, 1)

	// 💥 Если ушли дальше чем на 2 тайла — гарантированный разрыв
	else if(dist > 2)
		to_chat(user, span_danger("💥 Узел не выдерживает и рвётся!"))
		to_chat(partner, span_userdanger("💥 Узел резко вырывается из тебя!"))
		release_knot(user, partner, (knot_state ? knot_state : CUM_TARGET_VAGINA), TRUE)

		// 💥 Боль и травма при разрыве
		user.apply_damage(rand(15, 25), STAMINA)
		user.apply_damage(rand(5, 10), BRUTE)
		partner.apply_damage(rand(10, 20), STAMINA)
		partner.apply_damage(rand(3, 6), BRUTE)

		to_chat(user, span_danger("🔥 Ты чувствуешь резкую боль — узел вырывается наружу!"))
		to_chat(partner, span_danger("🔥 Твоя плоть горит болью от резкого разрыва узла!"))
		if(prob(50))
			user.emote("scream")
		if(prob(25))
			partner.emote("moan")

// ============================================================
// 🧩 Grab-style Resist (оба могут освободиться)
// ============================================================

/obj/item/organ/genital/penis/proc/start_resist_attempt(mob/living/user)
	if(!knot_locked)
		to_chat(user, span_notice("💧 Узел уже спал."))
		return

	var/is_partner = (user == knot_partner)
	var/mob/living/other = is_partner ? owner : knot_partner
	if(!other)
		to_chat(user, span_warning("❌ Цель отсутствует."))
		return

	var/msg_start
	if(is_partner)
		msg_start = "[user] начинает извиваться, пытаясь вытолкнуть узел [other]."
	else
		msg_start = "[user] осторожно пытается освободить узел из [other]."

	user.visible_message(
		span_notice(msg_start),
		span_notice("Ты начинаешь попытку освободиться от узла...")
	)

	var/duration = is_partner ? 4 SECONDS : 3 SECONDS
	to_chat(user, span_warning("⏳ Ты пытаешься освободиться... Не двигайся!"))

	if(do_after(user, duration, target = other))
		if(knot_locked)
			var/zone = knot_state ? knot_state : CUM_TARGET_VAGINA
			release_knot(other, user, zone, FALSE)
			to_chat(user, span_love("✨ Узел постепенно выходит, принося облегчение."))
			user.visible_message(
				span_love("💞 [user] наконец освобождается от узла [other]."),
				span_notice("Ты чувствуешь, как напряжение спадает.")
			)
			if(prob(30)) user.emote("moan")
			if(prob(15)) other.emote("groan")
		else
			to_chat(user, span_notice("Ты уже свободен."))
	else
		to_chat(user, span_danger("Ты не смог освободиться от узла!"))
		if(prob(40)) user.emote("scream")


// ============================================================
// 🧍 Верб: Resist Knot
// ============================================================

/mob/living/carbon/human/verb/knot_resist()
	set name = "Resist Knot"
	set category = "IC"
	set desc = "Попытаться освободиться от узла (если застрял)."

	var/mob/living/carbon/human/H = src
	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)

	if(P && P.knot_locked)
		P.start_resist_attempt(H)
		return

	for(var/mob/living/carbon/human/other in view(1, H))
		if(other == H) continue
		var/obj/item/organ/genital/penis/P2 = other.getorganslot(ORGAN_SLOT_PENIS)
		if(P2 && P2.knot_locked && P2.knot_partner == H)
			P2.start_resist_attempt(H)
			return

	to_chat(H, span_notice("Нет активного узла поблизости."))

/mob/living/carbon/human/resist()
	// 🧩 Узловая проверка перед стандартным Resist
	var/obj/item/organ/genital/penis/P = getorganslot(ORGAN_SLOT_PENIS)
	if(P && P.knot_locked)
		to_chat(src, span_notice("Ты пытаешься освободиться от узла..."))
		P.start_resist_attempt(src)
		return

	// Если у кого-то рядом узел с тобой
	for(var/mob/living/carbon/human/other in view(1, src))
		if(other == src) continue
		var/obj/item/organ/genital/penis/P2 = other.getorganslot(ORGAN_SLOT_PENIS)
		if(P2 && P2.knot_locked && P2.knot_partner == src)
			to_chat(src, span_notice("Ты пытаешься вырваться из узла [other]!"))
			P2.start_resist_attempt(src)
			return

	..()

// ============================================================
// 🌐 Универсальный прок: попытка активировать узел при сексе
// ============================================================

/proc/try_apply_knot(mob/living/user, mob/living/partner, target_zone)
	// Проверка корректных типов
	if(!ishuman(user) || !ishuman(partner))
		return

	// Проверка префов
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

	if(effective_lust < 65)
		return

	// 🎲 Шанс узла
	var/chance = 10 + (P.knot_size * 10)
	if(effective_lust >= 80)
		chance += 10
	if(HAS_TRAIT(receiver, TRAIT_ESTROUS_ACTIVE))
		chance += 5

	chance = clamp(chance, 5, 60)

	if(prob(chance))
		if(P.do_knotting(initiator, receiver, target_zone))
			to_chat(initiator, span_love("💞 Ты чувствуешь, как узел набухает внутри [receiver]!"))
			to_chat(receiver, span_lewd("🔥 Ты ощущаешь, как узел [initiator] застревает внутри!"))
			GLOB.knottings++
