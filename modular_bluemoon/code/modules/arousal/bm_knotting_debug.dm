/datum/admins/proc/force_knot() // By Stasdvrz
	set name = "Force Knot (Debug)"
	set category = "Debug"
	set hidden = TRUE

	if(!check_rights(R_ADMIN))
		to_chat(src, span_warning("⚠ Только для админов."))
		return

	if(!check_rights(R_SPAWN))
		return

	var/mob/living/carbon/human/H = src
	if(!istype(H))
		to_chat(src, span_warning("❌ Этот тест доступен только для людей."))
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
			to_chat(src, "- knot_partner: [P?.knot_partner ? "[P.knot_partner]" : "нет партнёра"]")
			if(HAS_TRAIT(H, TRAIT_ESTROUS_ACTIVE))
				to_chat(src, span_love("💗 Активен эстральный цикл"))
			else
				to_chat(src, span_notice("🧊 Эстральный цикл не активен"))
			if(hascall(H, "get_lust") && hascall(H, "get_climax_threshold"))
				to_chat(src, "- lust: [round((H.get_lust()/H.get_climax_threshold())*100,1)]%")
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

			var/mob/living/carbon/human/target = null
			var/fake_partner = FALSE

			if(length(moblist))
				target = input(src, "Выбери цель для узла:", "Knot test") as null|anything in moblist

			if(!target)
				to_chat(src, span_warning("⚙️ Цель не выбрана — создаётся тестовый партнёр для проверки сообщений."))
				target = src
				fake_partner = TRUE

			P.knot_locked = TRUE
			P.knot_partner = target
			P.knot_state = zone
			P.knot_until = world.time + 60 SECONDS

			// подключаем поводковую механику
			var/mob/living/master = H
			var/mob/living/pet = target
			if(!pet.has_movespeed_modifier(/datum/movespeed_modifier/leash))
				pet.add_movespeed_modifier(/datum/movespeed_modifier/leash)

			// регистрация движения
			P.RegisterSignal(master, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/obj/item/organ/genital/penis, on_knot_move))
			P.RegisterSignal(pet, COMSIG_MOVABLE_MOVED, TYPE_PROC_REF(/obj/item/organ/genital/penis, on_knot_move))


			to_chat(src, span_love("✅ Узел искусственно активирован (цель: [target], зона: [choice]) на 60 секунд."))
			to_chat(src, span_notice("📎 Поводок активирован — движение будет отслеживаться."))

			// 💞 Принудительная симуляция возбуждения (для дебага)
			if(istype(P, /obj/item/organ/genital/penis))
				to_chat(src, span_love("<font color='#ff7ff5'><b>[DEBUG]</b> Запуск афродизиачного эффекта узла...</font>"))
				P.knot_arousal_tick(H, target)

			// 💬 Отладочная проверка видимости сообщений
			if(fake_partner)
				to_chat(src, span_love("<font color='#ff7ff5'><b>[DEBUG]</b> Симуляция: партнёрские сообщения будут отображаться здесь же.</font>"))
				to_chat(src, span_lewd("<b>(Партнёр)</b> Ты ощущаешь, как узел блокирует выход и пульсирует внутри..."))
			else
				to_chat(target, span_love("<font color='#ff7ff5'><b>Узел блокирует выход — вы соединены с [src]!</b></font>"))

			// планируем таймеры
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
			to_chat(src, span_notice("🚶 Симулируем движение..."))
			if(P.knot_locked && P.knot_partner)
				H.check_knot_distance()
				to_chat(src, span_notice("📏 Проверка натяжения выполнена."))
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
			try_apply_knot(src, target, zone, TRUE)
			to_chat(src, span_love("💞 Ты насаживаешься на [target]. Проверка узла выполнена."))
