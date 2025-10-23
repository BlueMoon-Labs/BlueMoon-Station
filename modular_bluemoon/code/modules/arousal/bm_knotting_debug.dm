/mob/verb/force_knot() //By Stasdvrz
	set name = "Force Knot (Debug)"
	set category = "Debug"

	if(!check_rights(R_ADMIN))
		to_chat(src, span_warning("⚠ Только для админов."))
		return

	var/mob/living/carbon/human/H = src
	var/obj/item/organ/genital/penis/P = H.getorganslot(ORGAN_SLOT_PENIS)

	var/list/modes = list()

	if(P)
		modes = list(
			"Проверить состояние узла" = "state",
			"Активировать узел (принудительно)" = "lock",
			"Принудительный мягкий спад" = "release_soft",
			"Принудительный силовой разрыв" = "release_force",
			"Проверка дистанции" = "distance",
			"Resist от себя" = "resist_self",
			"Resist от партнёра" = "resist_partner",
			"Симулировать движение (проверка натяжения)" = "simulate_move",
			"Симулировать resist (нажатие вручную)" = "simulate_resist",
			"Авто-resist через 5 секунд" = "auto_resist",
			"🧍 Проверить насаживание (женская сторона)" = "female_test"
		)
	else
		modes = list("🧍 Проверить насаживание (женская сторона)" = "female_test")

	var/mode = input(src, "Выбери действие:", "Knot Debug") as null|anything in modes
	if(!mode)
		return

	switch(modes[mode])
		if("state")
			to_chat(src, span_notice("📊 Проверка состояния узла:"))
			to_chat(src, "- shape: [P?.shape]")
			to_chat(src, "- knot_size: [P?.knot_size]")
			to_chat(src, "- knot_locked: [P?.knot_locked]")
			to_chat(src, "- knot_strength: [P?.knot_strength]")
			to_chat(src, "- knot_until: [P?.knot_until ? "[P.knot_until - world.time] тиков" : "нет таймера"]")
			to_chat(src, "- partner: [P?.knot_partner ? "[P.knot_partner]" : "нет партнёра"]")
			if(HAS_TRAIT(H, TRAIT_ESTROUS_ACTIVE))
				to_chat(src, span_love("💗 Активен эстральный цикл"))
			else
				to_chat(src, span_notice("🧊 Эстральный цикл не активен"))
			return

		if("lock")
			var/list/L = list("рот" = CUM_TARGET_MOUTH, "анус" = CUM_TARGET_ANUS, "влагалище" = CUM_TARGET_VAGINA)
			var/choice = input(src, "Куда клинить узлом?", "Knot test") as null|anything in L
			if(!choice)
				return
			var/zone = L[choice]

			var/list/moblist = list()
			for(var/mob/living/carbon/human/M in view(7, src))
				if(M != src)
					moblist += M
			if(!length(moblist))
				to_chat(src, span_warning("❌ Рядом нет целей."))
				return

			var/mob/living/carbon/human/target = input(src, "Выбери цель для узла:", "Knot test") as null|anything in moblist
			if(!target)
				return

			P.knot_locked = TRUE
			P.knot_partner = target
			P.knot_state = zone
			P.knot_until = world.time + 60 SECONDS

			H.visible_message(
				span_lewd("<b>[H]</b> застревает узлом в [choice] <b>[target]</b>!"),
				span_notice("Твой узел набухает и фиксируется внутри [target].")
			)
			to_chat(src, span_love("✅ Узел искусственно активирован (цель: [target], зона: [choice]) на 60 секунд."))

			addtimer(CALLBACK(P, TYPE_PROC_REF(/obj/item/organ/genital/penis, knot_distance_loop), H), 5 SECONDS)
			addtimer(CALLBACK(P, TYPE_PROC_REF(/obj/item/organ/genital/penis, release_knot), H, target, zone, FALSE), 60 SECONDS)

		if("release_soft")
			var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
			P.release_knot(H, P.knot_partner ? P.knot_partner : H, zone, FALSE)
			to_chat(src, span_notice("💧 Мягкий спад выполнен."))

		if("release_force")
			var/zone = P.knot_state ? P.knot_state : CUM_TARGET_VAGINA
			P.release_knot(H, P.knot_partner ? P.knot_partner : H, zone, TRUE)
			to_chat(src, span_danger("💥 Силовой разрыв выполнен."))

		if("distance")
			H.check_knot_distance()
			to_chat(src, span_notice("📡 Проверка дистанции выполнена."))

		if("resist_self")
			P.start_resist_attempt(H)
			to_chat(src, span_notice("🧩 Resist попытка запущена от своего лица."))

		if("resist_partner")
			if(P.knot_partner && ishuman(P.knot_partner))
				var/mob/living/carbon/human/partner = P.knot_partner
				P.start_resist_attempt(partner)
				to_chat(src, span_notice("🧩 Resist попытка запущена от лица партнёра."))

		if("simulate_move")
			to_chat(src, span_notice("🚶 Тест: симуляция движения с активным узлом."))
			if(P.knot_locked && P.knot_partner)
				var/dist = get_dist(src, P.knot_partner)
				to_chat(src, span_notice("📏 Расстояние до партнёра: [dist] тайлов."))
				call(src, "check_knot_distance")()
			else
				to_chat(src, span_warning("❌ Узел не активен или нет партнёра."))

		if("simulate_resist")
			if(!P.knot_locked)
				to_chat(src, span_warning("❌ Нет активного узла для resist."))
				return
			to_chat(src, span_notice("🧩 Симулируем нажатие resist..."))
			P.start_resist_attempt(src)

		if("auto_resist")
			if(!P.knot_locked)
				to_chat(src, span_warning("❌ Нет активного узла для resist."))
				return
			to_chat(src, span_notice("⏳ Resist через 5 секунд..."))
			addtimer(CALLBACK(P, TYPE_PROC_REF(/obj/item/organ/genital/penis, start_resist_attempt), src), 5 SECONDS)

		// 🧍 Новая ветка: тест женской стороны
		if("female_test")
			var/list/moblist = list()
			for(var/mob/living/carbon/human/M in view(7, src))
				if(M != src)
					var/obj/item/organ/genital/penis/Ptest = M.getorganslot(ORGAN_SLOT_PENIS)
					if(Ptest && !Ptest.knot_locked)
						moblist += M

			if(!length(moblist))
				to_chat(src, span_warning("❌ Рядом нет подходящих партнёров (обладателей члена без активного узла)."))
				return

			var/mob/living/carbon/human/target = input(src, "Выбери партнёра (обладателя члена):", "Knot test") as null|anything in moblist
			if(!target)
				return

			var/list/L = list("рот" = CUM_TARGET_MOUTH, "анус" = CUM_TARGET_ANUS, "влагалище" = CUM_TARGET_VAGINA)
			var/choice = input(src, "Куда насаживаешься?", "Knot test") as null|anything in L
			if(!choice)
				return

			var/zone = L[choice]

			to_chat(src, span_notice("🔬 Тест: симуляция узлирования от женской стороны..."))
			try_apply_knot(src, target, zone) // 👈 именно в таком порядке
			to_chat(src, span_love("💞 Ты насаживаешься на [target]. Проверка узла выполнена."))
