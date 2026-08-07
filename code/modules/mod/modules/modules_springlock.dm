// BLUEMOON EDIT - переработка пружинного модуля

#define SPRINGLOCK_INTEGRITY_FRAGILE "fragile" // Ломается с одного повреждения
#define SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE "indestructible" // Не ломается
#define SPRINGLOCK_INTEGRITY_FULL 100
#define SPRINGLOCK_COMMON_DAMAGE 5
#define SPRINGLOCK_VULN_REAGENTS (1<<0) // Уязвимость к реагентам
#define SPRINGLOCK_VULN_PUNCH (1<<1) // Уязвимость к ударам
#define SPRINGLOCK_VULN_MOVEMENT (1<<2) // Уязвимость к движению

///Springlock Mechanism - allows your modsuit to activate faster, but reagents are very dangerous.
/obj/item/mod/module/springlock
	name = "MOD springlock module"
	desc = "Модуль, охватывающий весь корпус MOD, расположенный под внешней оболочкой. \
		Этот механический экзоскелет отодвигается, когда пользователь входит, и помогает в загрузке, \
		но был убран из современных костюмов из-за склонности спринглока 'щёлкать' обратно \
		на место при контакте с влагой. Знаете, каково это — когда целый экзоскелет входит в вас?"
	icon_state = "springlock"
	complexity = 3 // it is inside every part of your suit, so
	var/springlock_integrity = SPRINGLOCK_INTEGRITY_FRAGILE // Прочность пружинных механизмов
	var/speed_bootup_bonus = 2 // Во сколько раз ускоряется активация костюма
	var/speed_move_bonus = 1 // Во сколько раз уменьшается замедление костюма
	var/failure = FALSE // Находятся ли сейчас пружинные механизмы в состоянии поломки (жуёт ли сейчас несчастного)
	var/vulnerability_flags = SPRINGLOCK_VULN_REAGENTS // То, к чему уязвим костюм
	var/stuck = FALSE // Застрял ли этот модсьют навсегда на несчастном носителе...
	incompatible_modules = list(/obj/item/mod/module/springlock, /obj/item/mod/module/springlock/advanced)

/obj/item/mod/module/springlock/New()
	. = ..()
	update_desc()

/obj/item/mod/module/springlock/screwdriver_act(mob/living/user, obj/item/screwdriver)
	. = ..()
	if(.)
		return TRUE
	if(springlock_integrity == SPRINGLOCK_INTEGRITY_FRAGILE || springlock_integrity == SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE || springlock_integrity == SPRINGLOCK_INTEGRITY_FULL)
		balloon_alert(user, "пружинные замки не требуют ремонта!")
		return FALSE
	balloon_alert(user, "закручиваем на место пружинные замки...")
	screwdriver.play_tool_sound(src, 100)
	if(screwdriver.use_tool(src, user, 7 SECONDS))
		screwdriver.play_tool_sound(src, 100)
		balloon_alert(user, "пружинные замки отремонтированы!")
		springlock_integrity = initial(springlock_integrity)
		update_desc()
	else
		balloon_alert(user, "не получилось!")
	return TRUE

/obj/item/mod/module/springlock/update_desc()
	. = ..()
	desc = initial(desc)
	var/integrity_message = ""
	switch(springlock_integrity)
		if(SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE)
			integrity_message = "Пружины выглядят аномально надёжными..."
		if(SPRINGLOCK_INTEGRITY_FRAGILE)
			integrity_message = "Пружины выглядят очень ненадёжными..."
		if(SPRINGLOCK_INTEGRITY_FULL)
			integrity_message = "Пружины выглядят целыми."
		if(SPRINGLOCK_INTEGRITY_FULL * 0.75 to SPRINGLOCK_INTEGRITY_FULL)
			integrity_message = "Пружины почти целые."
		if(SPRINGLOCK_INTEGRITY_FULL * 0.5 to SPRINGLOCK_INTEGRITY_FULL * 0.75)
			integrity_message = "Пружины слегка просели..."
		if(SPRINGLOCK_INTEGRITY_FULL * 0.25 to SPRINGLOCK_INTEGRITY_FULL * 0.5)
			integrity_message = "Пружины держатся слабо."
		if(0 to SPRINGLOCK_INTEGRITY_FULL * 0.25)
			integrity_message = "Пружины вот-вот сорвутся!."
	desc += "\n\n[integrity_message]"

/obj/item/mod/module/springlock/on_install()
	mod.activation_step_time /= speed_bootup_bonus

/obj/item/mod/module/springlock/on_uninstall(deleting = FALSE)
	mod.activation_step_time *= speed_bootup_bonus
	failure = FALSE // Починил перезагрузкой, и в чём он не прав?

/obj/item/mod/module/springlock/on_suit_activation()
	RegisterSignal(mod.wearer, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(handle_reagents))
	RegisterSignal(mod.wearer, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(handle_damage))
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(handle_move))
	RegisterSignal(mod, COMSIG_MOD_ACTIVATE, PROC_REF(on_activate_spring_block))
	mod.slowdown /= speed_move_bonus
	if(speed_move_bonus > 1)
		to_chat(mod.wearer, "<span class='nicegreen'>Вы ощущаете, как экзоскелет костюма движется вокруг вас, облегчая тяжесть костюма! </span>")

/obj/item/mod/module/springlock/on_suit_deactivation(deleting = FALSE)
	UnregisterSignal(mod.wearer, COMSIG_ATOM_EXPOSE_REAGENTS)
	UnregisterSignal(mod.wearer, COMSIG_MOB_APPLY_DAMAGE)
	UnregisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(mod, COMSIG_MOD_ACTIVATE)
	mod.slowdown *= speed_move_bonus

///Signal fired when wearer is exposed to reagents
/obj/item/mod/module/springlock/proc/handle_reagents(atom/source, list/reagents, datum/reagents/source_reagents, methods, volume_modifier, show_message, from_gas)
	SIGNAL_HANDLER

	if(!reagents.len)
		return
	// Игнорируем приём реагентов внутрь
	if(!(methods == VAPOR || methods == PATCH || methods == TOUCH))
		return
	// Пружинные замки должны быть уязвимы к влаге, чтобы реагенты наносили урон
	if(!(vulnerability_flags & SPRINGLOCK_VULN_REAGENTS))
		return
	var/all_volume = 0
	for(var/reagent in reagents)
		var/datum/reagent/R = reagent
		all_volume += R.volume
	// Шанс повреждения (в процентах) = 15 + 3 * объём реагентов)
	if(!prob(15 + (all_volume * 3)))
		return
	// Урон может увеличиться в 'кол-во реагентов / 3' раз, но не более, чем в 3 раза
	var/damage = clamp(all_volume * SPRINGLOCK_COMMON_DAMAGE / 3, SPRINGLOCK_COMMON_DAMAGE, SPRINGLOCK_COMMON_DAMAGE * 3)
	adjust_springlock_damage(damage, "попадания влаги")

///Signal fired when wearer is hit
/obj/item/mod/module/springlock/proc/handle_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

	if(!(vulnerability_flags & SPRINGLOCK_VULN_PUNCH))
		return
	// Только брут
	if(!damage || damagetype != BRUTE)
		return
	// Дамаг должен быть больше 4
	if(damage < 5)
		return
	// Если дамаг не выше 90, есть шанс на отсутствие повреждений
	if(prob(clamp(90 - damage, 0, 90)))
		return
	// Дамаг не очень сильный в силу балансных соображений
	var/springlocks_damage = clamp(damage * SPRINGLOCK_COMMON_DAMAGE / 4, SPRINGLOCK_COMMON_DAMAGE, SPRINGLOCK_COMMON_DAMAGE * 2)
	adjust_springlock_damage(springlocks_damage, "сотрясения, вызванного сильным ударом")

///Signal fired when wearer runs
/obj/item/mod/module/springlock/proc/handle_move()
	SIGNAL_HANDLER

	if(!(vulnerability_flags & SPRINGLOCK_VULN_MOVEMENT))
		return
	var/mob/living/carbon/human/wearer = mod.wearer
	if(!wearer || !istype(wearer))
		return
	if(wearer.m_intent == MOVE_INTENT_WALK || !(wearer.mobility_flags & MOBILITY_STAND))
		return
	if(prob(0.4))
		adjust_springlock_damage(SPRINGLOCK_COMMON_DAMAGE, "быстрого перемещения")

///Proc to lower springlock integrity
/obj/item/mod/module/springlock/proc/adjust_springlock_damage(damage = SPRINGLOCK_COMMON_DAMAGE, reason = "неизвестных причин")
	if(springlock_integrity == SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE)
		return
	if(!mod || failure)
		return
	if(!mod.wearer || !istype(mod.wearer, /mob/living/carbon/human))
		return
	// Не очень логично, но никому не будет интересно смотреть на перемалывание трупов в пружинном костюме...
	if(mod.wearer.stat == DEAD)
		return
	if(springlock_integrity == SPRINGLOCK_INTEGRITY_FRAGILE)
		initiate_failure()
		return
	// Не тупые и не глухие с определённым шансом могут заметить, что их костюм получает повреждения
	if(!(HAS_TRAIT(mod.wearer, TRAIT_DUMB) || HAS_TRAIT(mod.wearer, TRAIT_DEAF)))
		var/is_pro = FALSE
		// Робототехники, РД, антаги и синты могут с определённым шансом относительно точно понять, сколько дамага получили
		if(mod.wearer.mind?.assigned_role == "Roboticist" || mod.wearer.mind?.assigned_role == "Research Director" || isrobotic(mod.wearer) || mod.wearer.mind?.has_antag_datum(/datum/antagonist, TRUE))
			is_pro = TRUE
		// В зависимости от дамага шансы на понимание того, что что-то не так увеличатся или уменьшатся, но не более чем в 0.5 и 1.5 раза
		var/damage_multiplier = clamp((damage / (SPRINGLOCK_COMMON_DAMAGE * 2)) + (SPRINGLOCK_INTEGRITY_FULL / springlock_integrity) - 1, 0.5, 2.5)
		if(is_pro && prob(30 * damage_multiplier))
			if(prob(30 * damage_multiplier))
				to_chat(mod.wearer, "<span class='warning'>Ваши [isrobotic(mod.wearer) ? "чуткие сенсоры" : "навыки"] позволяют вам распознать, что пружинные механизмы вашего [mod] повредились из-за [reason]! Целостность где-то [clamp(round((springlock_integrity + rand(-10,10)) / SPRINGLOCK_INTEGRITY_FULL * 100), 1, 100)] процентов! </span>")
			else
				to_chat(mod.wearer, "<span class='warning'>Вы ощущаете, что пружины в вашем [mod] сидят менее прочно из-за [reason]... </span>")
		else if(prob(20 * damage_multiplier))
			to_chat(mod.wearer, "<span class='warning'>Вы ощущаете, что пружины в вашем [mod] сидят менее прочно из-за [reason]... </span>")
	springlock_integrity = clamp(springlock_integrity - damage, 0, SPRINGLOCK_INTEGRITY_FULL)
	update_desc()
	if(springlock_integrity <= 0)
		initiate_failure()

///Signal fired when wearer attempts to activate/deactivate suits
/obj/item/mod/module/springlock/proc/on_activate_spring_block(datum/source, user)
	SIGNAL_HANDLER

	if(failure)
		balloon_alert(user, "Пружинные замки не реагируют...")
		return MOD_CANCEL_ACTIVATE
	if(stuck)
		balloon_alert(user, "Слишком поздно...")
		return MOD_CANCEL_ACTIVATE

///Launches springlock failure in few seconds
/obj/item/mod/module/springlock/proc/initiate_failure()
	if(!mod.wearer)
		return
	failure = TRUE
	mod.wearer.visible_message("<span class='warning'>Внутри [mod], который носит [mod.wearer], что-то еле слышно щёлкает...</span>", "<span class='boldwarning'>Вы слышите тихий звук медленно распрямляющихся пружин из своего [mod]...</span>")
	playsound(src, 'sound/items/modsuit/springlock.ogg', 75, TRUE)
	addtimer(CALLBACK(src, PROC_REF(snap_shut)), rand(3 SECONDS, 5 SECONDS))

///Result of springlocks failure, gives award, flashes red screen, plays a sound and launches snap_death_process proc
/obj/item/mod/module/springlock/proc/snap_shut(silenced = FALSE)
	if(!mod.wearer || !mod.active)
		return
	var/mob/living/carbon/human/springtrapped = mod.wearer
	if(!istype(springtrapped) || springtrapped.stat == DEAD)
		return
	failure = TRUE // На случай, если прок был вызван без initiate_failure()
	//Фаново же
	notify_ghosts("[springtrapped] доигра[springtrapped.ru_sya()] с пружинными замками в [get_area(src)]!", 'sound/items/modsuit/springlock.ogg', source = springtrapped, header = "Что-то забавное")
	springtrapped.visible_message(span_boldwarning("[springtrapped] вздрагивает всем телом и начинает биться в конвульсиях, когда [src] в [springtrapped.ru_ego()] [mod.name] срываются, перемалывая [springtrapped.ru_ego()] изнутри!"), span_userdanger("*ЩЁЛК*"), span_warning("Вы слышите громкий треск и какие-то странные хлюпающие звуки..."))
	// Эти звуки не будут производиться, если процесс будет заглушён (например, если он вызван эмоутом)
	if(!silenced)
		playsound(springtrapped, 'sound/effects/snap.ogg', 75, TRUE, frequency = 0.5)
		playsound(springtrapped, 'sound/effects/splat.ogg', 50, TRUE, frequency = 0.5)
	springtrapped.client?.give_award(/datum/award/achievement/misc/springlock, springtrapped)
	flash_color(springtrapped, flash_color = "#FF0000", flash_time = 30 SECONDS)
	// Мим настолько крут, что его кости ломаются беззвучно и он не кричит в агонии. И роботы тоже, да
	if(isrobotic(springtrapped) || springtrapped.mind?.miming)
		silenced = TRUE
	snap_death_process(silenced)

/// Caused by springlock failure cycle of wounds, killing the modsuit wearer
/obj/item/mod/module/springlock/proc/snap_death_process(silenced = FALSE)
	if(!mod.wearer)
		return
	var/mob/living/carbon/human/springtrapped = mod.wearer
	var/deathcycle = 0

	// Цикл ежесекундных процессов, постепенно убивающих жертву. Останавливается при смерти, отключении МОДа или после ~15 секунд
	while(!QDELETED(springtrapped) && istype(springtrapped) && mod.active && springtrapped.stat != DEAD)
		deathcycle++
		// Оглушаем, трясём, заглушаем
		springtrapped.Stun(20)
		springtrapped.do_jitter_animation(40)
		springtrapped.silent = clamp(springtrapped.silent + rand(5,10), 0, 10)
		// Ломаем тело брутом от 10 до 25 по всему телу за цикл
		springtrapped.apply_damage(rand(5, 20), BRUTE, spread_damage = TRUE)
		// Ломаем внутренние органы (каждый из органов дамажится с шансом 30% на 8 урона)
		for(var/obj/item/organ/organ in springtrapped.internal_organs)
			if(istype(organ, /obj/item/organ/genital))
				continue
			if(prob(30))
				organ.applyOrganDamage(5)
		// Вызываем кровотечения, расплёскивая кровь вокруг
		if(!(NOBLOOD in springtrapped.dna.species.species_traits))
			springtrapped.bleed(20)
			for(var/turf/adjacent_turf in oview(springtrapped, 2))
				if(adjacent_turf.density || !adjacent_turf.Adjacent(springtrapped.loc))
					continue
				if(prob(10))
					springtrapped.add_splatter_floor(adjacent_turf)
		// Если процесс не заглушён, издаём звуки ломающихся костей и разорванной плоти, а также заставляем кричать
		if(!silenced)
			if(prob(40))
				var/noise = pick('sound/effects/snap.ogg', 'sound/surgery/organ2.ogg', 'sound/effects/splat.ogg', 'modular_bluemoon/sound/emotes/bonecrack.ogg')
				playsound(springtrapped, noise, 70, TRUE, frequency = 0.5)
			if(prob(20))
				var/agony_emote = pick("scream", "realagony")
				springtrapped.emote(agony_emote)
		// Пишем сообщения в чат перемолотому
		if(prob(20))
			var/message = pick("Вы чувствуете, как в ваше тело загоняется металлическая арматура!",
			"Ваши внутренности разрываются гидравлическими приводами [mod]!",
			"Вы чувствуете, как в ваш мозг загоняется какой-то кабель, вызывая ощущение, что вы сходите с ума...",
			"ВЫСШИЕ СИЛЫ, УМОЛЯЮ, ПРЕКРАТИТЕ ЭТО!!!",
			"ЭТА БОЛЬ НЕВЫНОСИМА!",
			"ПОМОГИТЕ, СНИМИТЕ, СНИМИТЕ ЭТО С МЕНЯ!!",
			"НЕТ, НЕТ, НЕТ, НЕТ!!!",
			"ВСЁ НЕ МОЖЕТ ТАК ЗАКОНЧИТЬСЯ!")
			to_chat(springtrapped, "<span class='boldwarning'>[message]</span>")
		// Роняем после трёх циклов
		if(deathcycle > 3)
			springtrapped.Knockdown(50)
		// Убиваем после 15 циклов и завершаем процесс (как минимум чтобы не длился бесконечно)
		if(deathcycle > 15)
			if(!HAS_TRAIT(springtrapped, TRAIT_NODEATH))
				springtrapped.death()
				break
			else
				to_chat(springtrapped, "<span class='boldnotice'>Пружинные замки останавливаются, не в силах уничтожить ваше бессмертное тело. Какая жалость... </span>")
				break
		// Процесс повторяется раз в 1,5 секунды
		sleep(1.5 SECONDS)

	// Какой-то добрый самаритянин снял модсьют с несчастного до того, как последний скончался
	if(!QDELETED(springtrapped) && springtrapped.stat != DEAD && istype(springtrapped) && !mod.active)
		to_chat(springtrapped, "<span class='nicegreen'>Кто-то... кто-то снял это с меня... я... я буду жить?... </span>")
		visible_message("<span class='boldnotice'>С омерзительным хлюпающим звуком [mod] сползает с [springtrapped], со штырей костюма капает влага...</span>")
		playsound(springtrapped, 'sound/effects/splat.ogg', 30, TRUE, frequency = 0.5)
	// Наш несчастный оказался антагом, так что man behind the slaughter always come back... наверное
	if(!QDELETED(springtrapped) && springtrapped.mind?.has_antag_datum(/datum/antagonist, TRUE) && springtrapped.stat == DEAD)
		to_chat(springtrapped, "<span class='boldwarning'>У меня... остались незаконченные дела... я... ещё... вернусь... </span>")
		addtimer(CALLBACK(src, PROC_REF(comeback), springtrapped), 30 MINUTES) // 30 YEARS SINCE ALL THIS HAPPENED, 30 YEARS IT TOOK TO RISE
	failure = FALSE

// Будем честны, такая штука будет случаться раз в десять лет, так что это максимум будет маленькой пасхалкой
///Springtrapped antagonist comes back if possible
/obj/item/mod/module/springlock/proc/comeback(mob/living/carbon/human/springtrap)
	// В порядке ли пружинные замки?
	if(!src || QDELETED(src) || !istype(src) || loc != mod)
		return
	// В порядке ли модсьют?
	if(!mod || QDELETED(mod) || !istype(mod) || !mod.active)
		return
	// Находится ли попавший в модсьют ещё в нём?
	if(!springtrap || QDELETED(springtrap) || !istype(springtrap) || mod.wearer != springtrap)
		return
	// Подходит ли жертва для воскрешения?
	if(isrobotic(springtrap) || springtrap.stat != DEAD || !springtrap.mind)
		return
	// Всё подошло

	// Изменяем модсьют - теперь он не снимается, а пружины неломаемы
	mod.item_flags |= DROPDEL
	mod.desc += "\n\nВ этом потёртом и заметно повреждённом костюме находился специальный экзоскелет, который схлопнулся и навсегда запер носителя внутри. Как ни странно, он выглядит очень прочным..."
	springlock_integrity = SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE
	update_desc()
	failure = FALSE
	stuck = TRUE
	mod.helmet.flags_cover &= ~HEADCOVERSMOUTH
	mod.helmet.visor_flags_cover &= ~HEADCOVERSMOUTH
	var/list/all_parts = mod.mod_parts.Copy() + mod
	for(var/obj/item/part in all_parts)
		ADD_TRAIT(part, TRAIT_NODROP, CURSED_ITEM_TRAIT)
		part.resistance_flags |= (INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF)

	// Изменяем носителя - теперь он злая нежить
	springtrap.revive(TRUE, TRUE)
	springtrap.grab_ghost(FALSE)
	springtrap.remove_quirk(/datum/quirk/family_heirloom)
	springtrap.remove_quirk(/datum/quirk/well_trained)
	springtrap.remove_quirk(/datum/quirk/friendly)
	springtrap.remove_quirk(/datum/quirk/empath)
	springtrap.remove_quirk(/datum/quirk/monophobia)
	springtrap.remove_quirk(/datum/quirk/nyctophobia)
	ADD_TRAIT(springtrap, TRAIT_NOHUNGER, "undead_springtrap")
	ADD_TRAIT(springtrap, TRAIT_NOTHIRST, "undead_springtrap")

	if(!(springtrap.mob_biotypes & MOB_UNDEAD))
		var/old_species = springtrap.dna?.species
		switch(old_species)
			if(/datum/species/mammal)
				springtrap.set_species(/datum/species/mammal/undead)
			if(/datum/species/insect)
				springtrap.set_species(/datum/species/insect/undead)
			if(/datum/species/lizard)
				springtrap.set_species(/datum/species/lizard/undead)
			else
				springtrap.set_species(/datum/species/zombie)
	springtrap.visible_message("<span class='boldwarning'>[springtrap] внезапно вздрагивает и медленно поднимается, [mod], кажется, сидит на нём плотнее, чем когда-либо...</span>", "<span class='userdanger'>Вы восстали из мёртвых!</span>")
	to_chat(springtrap, "<span class='boldwarning'>Вы вернулись в этот мир, привязанные к этому проклятому костюму. [mod] теперь часть вас, и намерены выполнить свои задачи и отомстить своим обидчикам...</span>")
	playsound(springtrap, 'modular_bluemoon/sound/emotes/always_come_back.ogg', 50)


// Улучшенная версия пружинных замков, делаемая в лейтгейм РнД - имеет запас прочности и гораздо эффективнее, но ещё более уязвима

/obj/item/mod/module/springlock/advanced
	name = "MOD electronic exoskeleton module"
	desc = "Улучшенная версия печально известного модуля спринг-механизма, \
			которая более стабильна и позволяет гораздо быстрее надевать костюмы MOD. \
			Имеет совершенно новый механизм генерации энергии для питания себя и предоставления носителю возможности \
			двигаться быстрее.\
			However, it can still be dangerous if used carelessly, and fast movement, moisture, and strong impacts \
			can throw the module off balance, leading to a tragic outcome for the wearer.\n\nUse a screwdriver to repair damaged springs."
	icon_state = "springlock_improved"
	springlock_integrity = SPRINGLOCK_INTEGRITY_FULL
	speed_bootup_bonus = 5
	speed_move_bonus = 2
	vulnerability_flags = SPRINGLOCK_VULN_REAGENTS | SPRINGLOCK_VULN_PUNCH | SPRINGLOCK_VULN_MOVEMENT // Больше уязвимостей, но имеет запас прочности


/**
 * Особый эмоут для антуража (кекв)
 */
/datum/emote/sound/human/afton_laugh
	name = "Маниакально смеяться"
	key = "laughmaniac"
	key_third_person = "laughs maniacally"
	message = "маниакально смеётся!"
	message_mime = "с жуткой гримасой изображает смех, рубя невидимым ножом кого-то!"
	emote_type = EMOTE_AUDIBLE
	muzzle_ignore = FALSE
	restraint_check = FALSE
	emote_cooldown = 4 SECONDS

/datum/emote/sound/human/afton_laugh/run_emote(mob/living/user, params)
	var/obj/item/mod/module/springlock/spring = check_springlocks(user)
	var/miming = user.mind?.miming
	// На нас нет включённого пружинного костюма - просто смеёмся
	if(!spring)
		. = ..()
		if(!miming && .)
			playsound(user, 'modular_bluemoon/sound/emotes/afton_laugh.ogg', 75)
	// Шутки кончились...
	else
		// Большинство этих проверок сделано для красивого эмоута в обход initiate_failure()
		var/integrity = spring.springlock_integrity
		// На нас был костюм, но он достаточно прочный и ему лишь нанесли 10 дамага
		if(integrity == SPRINGLOCK_INTEGRITY_INDESTRUCTIBLE || spring.failure || (isnum(integrity) && integrity > 10))
			. = ..()
			if(!.)
				return
			spring.adjust_springlock_damage(10, "слишком сильного смеха")
			if(!miming)
				playsound(user, 'modular_bluemoon/sound/emotes/afton_laugh.ogg', 75)
			return
		message = "маниакально смеётся, как вдруг..."
		message_mime = "с жуткой гримасой изображает смех, рубя невидимым ножом кого-то, как вдруг резко хватается за грудь и беззвучно открывает рот в крике агонии..."
		emote_cooldown = 20 SECONDS // Вряд-ли юзер доживёт до конца кулдауна, но на всякий
		. = ..()
		if(!.)
			emote_cooldown = initial(emote_cooldown)
			message = initial(message)
			message_mime = initial(message_mime)
			return
		if(spring.springlock_integrity != SPRINGLOCK_INTEGRITY_FRAGILE && spring.springlock_integrity < 10)
			spring.springlock_integrity = clamp(spring.springlock_integrity - 10, 0, spring.springlock_integrity)
		var/mob/living/carbon/human/springtrapped = user
		spring.failure = TRUE
		springtrapped.silent = clamp(springtrapped.silent + 10, 0, 10) // Сложно говорить в такой ситуации
		springtrapped.Stun(120)
		if(!miming)
			playsound(springtrapped, 'modular_bluemoon/sound/emotes/afton_death_laugh.ogg', 75)
		addtimer(CALLBACK(spring, TYPE_PROC_REF(/obj/item/mod/module/springlock, snap_shut), TRUE), 3.5 SECONDS)
		emote_cooldown = initial(emote_cooldown)
		message = initial(message)
		message_mime = initial(message_mime)

/// Checks if user wears active modsuit with the springlock module
/datum/emote/sound/human/afton_laugh/proc/check_springlocks(mob/living/user)
	if(!istype(user, /mob/living/carbon/human))
		return FALSE
	var/obj/item/mod/control/modsuit = user.get_item_by_slot(ITEM_SLOT_BACK)
	if(!modsuit || !istype(modsuit))
		return FALSE
	if(!modsuit.active)
		return FALSE
	var/obj/item/mod/module/springlock/spring = locate() in modsuit.modules
	if(spring)
		return spring
	return FALSE
