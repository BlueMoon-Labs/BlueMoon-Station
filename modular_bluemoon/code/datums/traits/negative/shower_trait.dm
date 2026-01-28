#define STATUS_EFFECT_STINK /datum/status_effect/stink // оверлей вони

#define FINE_CLEAN 50 // ресет предупреждений о необходимости сходить в душ
#define FIRST_WARNING 750 // предупреждение, что пора сходить в душ
#define DIRTY 900 // негативное настроение
#define VERY_DIRTY 1000 // негативное настроение, визуальный эффект, сообщение при экзейме окружающим

/area/var/valid_to_shower = FALSE //Нарушаем правила кодинга сски ради красоты и практичности; переменная используемая для проверки является-ли зона правильной для душа
/area/security/prison/valid_to_shower = TRUE
/area/commons/toilet/valid_to_shower = TRUE
/area/command/heads_quarters/captain/valid_to_shower = TRUE
/area/commons/dorms/valid_to_shower = TRUE
/area/command/blueshielquarters/valid_to_shower = TRUE
/area/service/chapel/main/monastery/valid_to_shower = TRUE
/area/mine/laborcamp/valid_to_shower = TRUE
/area/survivalpod/valid_to_shower = TRUE
/area/mine/living_quarters/valid_to_shower = TRUE
/area/hilbertshotel/valid_to_shower = TRUE

/datum/quirk/bluemoon_shower_need
	name = BLUEMOON_TRAIT_NAME_SHOWER_NEED
	desc = "Вам нужно периодически ходить в душ. Хотя бы на станции. Из-за особенностей здешних мест, делать это нужно раз в час на пару минут. Можно мыться в душевых, сауне и бассейне. Лучше всего подходят душевые в жилых зонах, а также личных каютах."
	gain_text = span_warning("Чистота - залог хорошего настроения!")
	lose_text = span_notice("Мне достаточно мыться раз в неделю, ведь в среднем на 10-минутный душ расходуется 60 литров воды. Использование нагревателя повышает расход в три раза, а на ванну нужно как минимум 200 литров. Получается, что семья из четырех человек, которые каждый день принимают 10-минутный душ, расходует 25 куб. м воды каждый год (традиционно в Великобритании установлены отдельные краны с холодной и горячей водой без смесителя, и для теплого душа нужен проточный нагреватель — прим. ред.). Цена электричества повышает стоимость гигиены такой семьи с 400 £ до 1200 £ в год. И это еще не все: любители душа оказываются ответственными за выброс в атмосферу 3,5 тонн углекислого газа. Чтобы остановить глобальное потепление, мы можем позволить себе только 1 тонну СО2 на человека, с учетом всей его жизнедеятельности от еды до транспорта.")
	value = -2
	mob_trait = TRAIT_BLUEMOON_SHOWER_NEED
	flavor_quirk = TRUE
	processing_quirk = TRUE
	mood_quirk = TRUE

	var/cleanse_level = 0 // уровень загрязнения персонажа
	var/doing_shower = FALSE // оповещение, что персонаж вошёл в душ и игроку нужно подождать, пока он не станет чистым
	var/hide_visual_effect = FALSE // если игрок хочет, он может отключить визуальное отображение, но при этом будет сильное падение настроения
	var/cleaned_times = 0 // счётчик, сколько тиков игрок постоял под душем
	var/warning_level = 0 // предупреждения для игрока в чат. Обнуляются при достижении чистоты
	var/image/stink_overlay // оверлей вони
	var/mob/living/carbon/human/human_owner // хумановский quirk_holder, т.к. некоторых функций у living нет

/datum/quirk/bluemoon_shower_need/on_spawn()
	. = ..()
	if(quirk_holder)
		human_owner = quirk_holder
	RegisterSignal(quirk_holder, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(cleaning)) // реакция, когда персонаж встаёт под душ
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(examine)) // реакция, когда персонажа осматривают
	var/mob/living/carbon/human/H = quirk_holder
	if(!H)
		return
	var/datum/action/cooldown/change_stink_overlay/C = new // выдача способности для изменения оверлея вони
	C.Grant(H)

	// создание оверлея вони
	var/matrix/M = matrix()
	M.Scale(0.6)
	stink_overlay = mutable_appearance(icon = 'modular_bluemoon/icons/effects/stink.dmi', icon_state = "steam_double", layer = -FIRE_LAYER)
	stink_overlay.transform = M
	stink_overlay.pixel_y = 12

/datum/quirk/bluemoon_shower_need/remove()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, list(COMSIG_COMPONENT_CLEAN_ACT, COMSIG_PARENT_EXAMINE))

		// забираем способность изменения оверлея вони
		var/mob/living/carbon/human/H = quirk_holder
		var/datum/action/cooldown/change_stink_overlay/C = locate() in H.actions
		if(C)
			C.Remove(H)

		quirk_holder.cut_overlay(stink_overlay) // удаляем оверлей вони с игрока

	stink_overlay = null
	human_owner = null
	. = ..()

/datum/quirk/bluemoon_shower_need/process()
	. = ..()
	if(!human_owner.insanelycomfy)
		cleanse_level = clamp(cleanse_level + 0.23, 0, 1001) // около 70 минут (без учёта лагов) нужно, чтобы требование к мытью поднялось до максимума (оверлея)

	var/turf/open/T = get_turf(quirk_holder)
	if(T.air)
		var/datum/gas_mixture/G = T.air
		if(HAS_TRAIT(quirk_holder, TRAIT_SWIMMING) || G.get_moles(GAS_H2O) > 0) // персонаж находится в бассейне или сауне, происходит мытьё
			cleaning(10) // при вызове сигнала COMSIG_COMPONENT_CLEAN_ACT этой функции в аргументы присваивается персонаж, что делает невозможным применение TRUE

	switch(cleanse_level)
		if(-INFINITY to FINE_CLEAN)
			if(warning_level > 0)
				to_chat(quirk_holder, span_notice("Моё тело чистое, можно выходить."))
				human_owner.cut_overlay(stink_overlay)
				doing_shower = FALSE
				warning_level = 0
		if(FIRST_WARNING to DIRTY)
			SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "need_shower", /datum/mood_event/need_shower)
			if(warning_level < 1)
				to_chat(quirk_holder, span_notice("Мне не помешает сходить в душ..."))
				warning_level = 1
		if(DIRTY to VERY_DIRTY)
			SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "need_shower", /datum/mood_event/need_shower/dirty)
			if(warning_level < 2)
				to_chat(quirk_holder, span_phobia("Мне нужно сходить в душ."))
				warning_level = 2
		if(VERY_DIRTY to INFINITY)
			if(hide_visual_effect)
				SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "need_shower", /datum/mood_event/need_shower/very_dirty_catastrophic)
			else
				SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "need_shower", /datum/mood_event/need_shower/very_dirty)
			if(warning_level < 3)
				if(!hide_visual_effect)
					human_owner.add_overlay(stink_overlay)
				to_chat(quirk_holder, span_phobia("Мне ОЧЕНЬ нужно сходить в душ!"))
				warning_level = 3

/datum/quirk/bluemoon_shower_need/proc/examine(atom/examine_target, mob/examiner, list/examine_list)
	SIGNAL_HANDLER

	if(hide_visual_effect) // игрок скрывает статус персонажа
		return

	var/cannot_smell = FALSE // некоторые персонажи могут не замечать вон, но всё ещё будут понимать, что следует принять душ


	if(HAS_TRAIT(examiner, /datum/quirk/no_smell))  // персонажи с аносмией не замечают вонь
		cannot_smell = TRUE

	if(iscarbon(examiner))
		var/mob/living/carbon/C = examiner
		if(C.internal) // персонажи со включенными баллоном не замечают вонь
			cannot_smell = TRUE

	if(cleanse_level >= DIRTY) // если персонаж достаточно грязный, об этом пишется в экзейм
		if(cannot_smell)
			examine_list += span_notice("[quirk_holder.ru_who(TRUE)] давно не мы[quirk_holder.ru_sya()].") // т.к. облачко в таком исходе всё ещё существует, на глаз можно определить, что персонаж давно не мылся
		else
			examine_list += span_redtext("[quirk_holder.ru_who(TRUE)] плохо пахнет.")


/datum/quirk/bluemoon_shower_need/proc/chance_visual_effect()
	hide_visual_effect = !hide_visual_effect

	if(!hide_visual_effect)
		if(cleanse_level >= VERY_DIRTY)
			human_owner.cut_overlay(stink_overlay)
			human_owner.add_overlay(stink_overlay)
	else
		human_owner.cut_overlay(stink_overlay)

/datum/quirk/bluemoon_shower_need/proc/cleaning(var/hide_clothing_warning)
	SIGNAL_HANDLER
	var/cleaning_efficiency = 10 // 3.5~ минуты с 1000

	if(cleanse_level <= 10) // снижение нагрузки, чтобы стояние куклы под душем с этим квирком не генерило постоянно все проверки внизу
		return

	cleaned_times++
	if(!check_for_clothing())
		if(!(cleaned_times % 10) && (hide_clothing_warning != 10))
			to_chat(quirk_holder, span_warning("Нужно снять одежду, не подходящую для душа! Бюстгалтер и трусы допустимы."))
		return

	var/area/A = get_area(quirk_holder)
	if(A.valid_to_shower)
		if(!doing_shower && warning_level != 0)
			to_chat(quirk_holder, span_notice("Теперь только подождать... Есть время разгрузить голову и расслабиться. Это займёт до пары минут."))
			doing_shower = TRUE
		cleaning_efficiency = 20 // 1.7~ минут с 1000
	else // за поставленный в неподходящей зоне душ и мытьё там штраф
		if(!doing_shower && warning_level != 0)
			to_chat(quirk_holder, span_warning("Я смогу помыться, но это место плохо подходит для душевой и это будет в два раза дольше, до четырёх минут. Жилые зоны, в том числе дормиторий, уборные и личные каюты подходят куда лучше..."))
			doing_shower = TRUE

	if(!(cleaned_times % 10)) // каждые 10 тиков новый сон в чат
		if(iscarbon(quirk_holder))
			var/mob/living/carbon/holder = quirk_holder
			holder.dream(dreaming_in_shower = TRUE)
	cleanse_level = max(0, cleanse_level - cleaning_efficiency)

/datum/quirk/bluemoon_shower_need/proc/check_for_clothing()
	if(ishuman(quirk_holder))
		var/mob/living/carbon/human/holder = quirk_holder

		if(holder.w_shirt) // мыться в футболках нельзя
			if(!(holder.w_shirt.type in typesof(/obj/item/clothing/underwear/shirt/bra, /obj/item/clothing/underwear/shirt/top))) // мыться в лифчике можно
				return

		if(holder.back) // мыться с рюкзаком нельзя
			return

		if(holder.gloves) // мыться в перчатках нельзя
			if(!(holder.gloves.type in typesof(/obj/item/clothing/accessory/ring))) // с кольцами можно
				return

		if(holder.w_uniform) // мыться в униформе нельзя
			if(holder.w_uniform.body_parts_covered & CHEST) // можно, если униформа закрывает грудь
				return

		if(holder.wear_suit) // мыться в костюме нельзя
			return

		if(!get_location_accessible(holder, BODY_ZONE_HEAD)) // мыться в шапочке нельзя
			return

		if(!get_location_accessible(holder, BODY_ZONE_PRECISE_L_FOOT)) // мыться в обуви нельзя
			return

	return TRUE // в наушниках, очках, галстуках, части нижнего белья можно мыться

/*
 * СПОСОБНОСТЬ
 */

/datum/action/cooldown/change_stink_overlay
	name = "Change Stink Overlay"
	desc = "Вы можете убрать отображение того, что персонаж плохо пахнет (облачко над ним и сообщение при осмотре), но это будет стоить катастрофического падения настроения."
	icon_icon = 'icons/obj/watercloset.dmi'
	button_icon_state = "shower"
	cooldown_time = 15 SECONDS // чтобы игрок не кликал изменение оверлея туда-сюда без понимания, почему он не исчезает
	transparent_when_unavailable = TRUE

/datum/action/cooldown/change_stink_overlay/Activate()
	var/mob/living/carbon/human/action_holder = owner
	for(var/datum/quirk/bluemoon_shower_need/quirk in action_holder.roundstart_quirks)
		quirk.chance_visual_effect()
		to_chat(owner, span_notice("Теперь окружающие [quirk.hide_visual_effect ? "не будут" : "будут"] замечать плохой запах. [quirk.hide_visual_effect ? "Однако, настроение будет контролировать намного сложнее, если долго не ходить в душ..." : ""]"))
		StartCooldown() // начала отчёта для КД на способность

/*
 * ИВЕНТЫ НАСТРОЕНИЯ
 */

/datum/mood_event/need_shower
	description = "Мне не помешало бы сходить в душ...\n"
	mood_change = 0 // индикатор для игрока через муд
	timeout = 10 SECONDS // эффект постоянно обновляется

/datum/mood_event/need_shower/dirty
	description = span_danger("Мне нужно сходить в душ.\n")
	mood_change = -2

/datum/mood_event/need_shower/very_dirty
	description = span_boldwarning("Мне ОЧЕНЬ нужно сходить в душ!\n")
	mood_change = -4

/datum/mood_event/need_shower/very_dirty_catastrophic
	description = span_phobia("МНЕ КРИТИЧЕСКИ НУЖНО СХОДИТЬ В ДУШ!\n")
	mood_change = -16 // игрок скрывает визуальный негативный эффект, но от этого персонаж сильно страдает

#undef STATUS_EFFECT_STINK

#undef FINE_CLEAN
#undef FIRST_WARNING
#undef DIRTY
#undef VERY_DIRTY
