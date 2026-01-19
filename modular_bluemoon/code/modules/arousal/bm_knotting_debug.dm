// ============================================================
// BlueMoon - Knotting Debug Commands (FIXED) //By Stasdvrz
// ============================================================

// ============================================================
// DEBUG HELPER PROCS
// ============================================================

/client/proc/debug_show_knot_state(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	to_chat(mob, span_notice("📊 Проверка состояния узла:"))
	to_chat(mob, "- shape: [P?.shape]")
	to_chat(mob, "- knot_size: [P?.knot_size]")
	to_chat(mob, "- knot_locked: [P?.knot_locked]")
	to_chat(mob, "- knot_strength: [P?.knot_strength]")
	to_chat(mob, "- knot_until: [P?.knot_until ? "[P.knot_until - world.time] тиков" : "нет таймера"]")
	to_chat(mob, "- knot_partner: [P?.knot_partner ? "[P.knot_partner]" : "нет партнёра"]")

	if(HAS_TRAIT(H, TRAIT_ESTROUS_ACTIVE))
		to_chat(mob, span_love("💗 Активен эстральный цикл"))
	else
		to_chat(mob, span_notice("🧊 Эстральный цикл не активен"))

	if(hascall(H, "get_lust") && hascall(H, "get_climax_threshold"))
		var/climax = H.get_climax_threshold()
		if(climax > 0)
			to_chat(mob, "- lust: [round((H.get_lust() / climax) * 100, 1)]%")

/client/proc/debug_force_lock_knot(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса для активации узла."))
		return

	var/list/L = list("рот" = CUM_TARGET_MOUTH, "анус" = CUM_TARGET_ANUS, "влагалище" = CUM_TARGET_VAGINA)
	var/choice = input(mob, "Куда клинить узлом?", "Knot test") as null|anything in L
	if(!choice)
		return
	var/zone = L[choice]

	var/list/moblist = list()
	for(var/mob/living/carbon/human/M in view(7, mob))
		if(M != H)
			moblist += M

	var/mob/living/carbon/human/target = null

	if(length(moblist))
		target = input(mob, "Выбери цель для узла:", "Knot test") as null|anything in moblist

	if(!target)
		to_chat(mob, span_warning("⚙️ Цель не выбрана — создаётся тестовый партнёр для проверки сообщений."))
		target = H

	P.activate_knot(H, target, zone, 60 SECONDS)
	P.setup_knot_signals(H, target)

	to_chat(mob, span_love("✅ Узел искусственно активирован (цель: [target], зона: [choice]) на 60 секунд."))
	to_chat(mob, span_notice("📎 Поводок активирован — движение будет отслеживаться."))

	to_chat(mob, span_love("<font color='#ff7ff5'><b>[DEBUG]</b> Запуск афродизиачного эффекта узла...</font>"))
	P.knot_arousal_tick(H, target)

	if(target == H)
		to_chat(mob, span_love("<font color='#ff7ff5'><b>[DEBUG]</b> Симуляция: партнёрские сообщения будут отображаться здесь же.</font>"))
		to_chat(mob, span_lewd("<b>(Партнёр)</b> Ты ощущаешь, как узел блокирует выход и пульсирует внутри..."))
	else
		to_chat(target, span_love("<font color='#ff7ff5'><b>Узел блокирует выход — вы соединены с [H]!</b></font>"))

	P.schedule_knot_processes(H, target, zone, 60 SECONDS)

/client/proc/debug_release_soft(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
	var/partner = P.knot_partner ? P.knot_partner : H
	P.release_knot(H, partner, zone, FALSE)
	to_chat(mob, span_notice("💧 Мягкий спад выполнен."))

/client/proc/debug_release_force(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
	var/partner = P.knot_partner ? P.knot_partner : H
	P.release_knot(H, partner, zone, TRUE)
	to_chat(mob, span_danger("💥 Силовой разрыв выполнен."))

/client/proc/debug_check_distance(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	P.check_knot_distance_safe(H)
	to_chat(mob, span_notice("📡 Проверка дистанции выполнена."))

/client/proc/debug_resist_self(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	P.start_resist_attempt(H)
	to_chat(mob, span_notice("🧩 Resist попытка запущена от своего лица."))

/client/proc/debug_resist_partner(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	if(P.knot_partner && ishuman(P.knot_partner))
		var/mob/living/carbon/human/partner = P.knot_partner
		P.start_resist_attempt(partner)
		to_chat(mob, span_notice("🧩 Resist попытка запущена от лица партнёра."))
	else
		to_chat(mob, span_warning("❌ Нет партнёра для resist."))

/client/proc/debug_simulate_move(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	to_chat(mob, span_notice("🚶 Симулируем движение..."))
	if(P.knot_locked && P.knot_partner)
		P.check_knot_distance_safe(H)
		to_chat(mob, span_notice("📏 Проверка натяжения выполнена."))
	else
		to_chat(mob, span_warning("❌ Узел не активен или нет партнёра."))

/client/proc/debug_simulate_resist(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	if(!P.knot_locked)
		to_chat(mob, span_warning("❌ Нет активного узла для resist."))
		return

	to_chat(mob, span_notice("🧩 Симулируем нажатие resist..."))
	P.start_resist_attempt(H)

/client/proc/debug_auto_resist(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	if(!P)
		to_chat(mob, span_warning("❌ Нет пениса."))
		return

	if(!P.knot_locked)
		to_chat(mob, span_warning("❌ Нет активного узла для resist."))
		return

	to_chat(mob, span_notice("⏳ Resist через 5 секунд..."))
	addtimer(CALLBACK(P, TYPE_PROC_REF(/obj/item/organ/genital/penis, start_resist_attempt), H), 5 SECONDS)

/client/proc/debug_female_test(mob/living/carbon/human/H, obj/item/organ/genital/penis/P)
	var/list/moblist = list()
	for(var/mob/living/carbon/human/M in view(7, mob))
		if(M != H)
			var/obj/item/organ/genital/penis/Ptest = M.getorganslot(ORGAN_SLOT_PENIS)
			if(Ptest && !Ptest.knot_locked)
				moblist += M

	if(!length(moblist))
		to_chat(mob, span_warning("❌ Рядом нет подходящих партнёров (обладателей члена без активного узла)."))
		return

	var/mob/living/carbon/human/target = input(mob, "Выбери партнёра (обладателя члена):", "Knot test") as null|anything in moblist
	if(!target)
		return

	var/list/L = list("рот" = CUM_TARGET_MOUTH, "анус" = CUM_TARGET_ANUS, "влагалище" = CUM_TARGET_VAGINA)
	var/choice = input(mob, "Куда насаживаешься?", "Knot test") as null|anything in L
	if(!choice)
		return

	var/zone = L[choice]

	to_chat(mob, span_notice("🔬 Тест: симуляция узлирования от женской стороны..."))
	try_apply_knot(H, target, zone, force_override = TRUE, force_knot = TRUE)
	to_chat(mob, span_love("💞 Ты насаживаешься на [target]. Проверка узла выполнена."))

// ============================================================
// MAIN DEBUG COMMAND
// ============================================================

/client/proc/force_knot()
	set name = "Force Knot"
	set category = "Debug"

	var/mob/living/carbon/human/H = mob
	if(!istype(H))
		to_chat(mob, span_warning("❌ Этот тест доступен только для людей."))
		return

	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)
	var/list/modes = list()

	if(P)
		modes = list(
			"📊 Проверить состояние узла" = "state",
			"🔒 Активировать узел (принудительно)" = "lock",
			"💧 Принудительный мягкий спад" = "release_soft",
			"💥 Принудительный силовой разрыв" = "release_force",
			"📡 Проверка дистанции" = "distance",
			"🧩 Resist от себя" = "resist_self",
			"🧩 Resist от партнёра" = "resist_partner",
			"🚶 Симулировать движение" = "simulate_move",
			"🧠 Симулировать resist (ручной)" = "simulate_resist",
			"⏳ Авто-resist через 5 секунд" = "auto_resist",
			"🧍 Проверить насаживание (женская сторона)" = "female_test"
		)
	else
		modes = list("🧍 Проверить насаживание (женская сторона)" = "female_test")

	var/mode = input(mob, "Выбери действие:", "Knot Debug") as null|anything in modes
	if(!mode)
		return

	switch(modes[mode])
		if("state")
			debug_show_knot_state(H, P)

		if("lock")
			debug_force_lock_knot(H, P)

		if("release_soft")
			debug_release_soft(H, P)

		if("release_force")
			debug_release_force(H, P)

		if("distance")
			debug_check_distance(H, P)

		if("resist_self")
			debug_resist_self(H, P)

		if("resist_partner")
			debug_resist_partner(H, P)

		if("simulate_move")
			debug_simulate_move(H, P)

		if("simulate_resist")
			debug_simulate_resist(H, P)

		if("auto_resist")
			debug_auto_resist(H, P)

		if("female_test")
			debug_female_test(H, P)
