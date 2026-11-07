#define HK47_TRAINING_EMP_SEVERITY 100

/datum/antag_training_program/hk47
	name = "HK-47 — дроид-ассасин"
	category = "Чужаки"
	desc = "Дроид-ассасин: учебные контракты всех видов, модули шасси за очки, ЭМИ, перепрошивка и бой с парой HK-50."
	icon = "robot"
	color = "orange"
	learn = "Учебные контракты всех видов|Модули шасси за очки|ЭМИ и перепрошивка|Бой с парой HK-50"
	difficulty = 3
	avatar_name = HK47_NAME
	target_action = "Цель контракта"
	options = list("Добавить очки", "Вызвать HK-50 для боя", "ЭМИ по себе", "Перепрошить меня", "Полный заряд", "Контракт: ликвидация", "Контракт: захват", "Контракт: кража", "Контракт: охрана", "Контракт: саботаж", "Контракт: охота с опознанием")
	/// Кнопка учебного контракта -> list(задача, заказчик).
	var/static/list/practice_tasks = list(
		"Контракт: ликвидация" = list(/datum/hk_contract_task/kill, HK_CLIENT_SYNDICATE),
		"Контракт: захват" = list(/datum/hk_contract_task/capture, HK_CLIENT_CORP),
		"Контракт: кража" = list(/datum/hk_contract_task/theft, HK_CLIENT_CORP),
		"Контракт: охрана" = list(/datum/hk_contract_task/protect, HK_CLIENT_PRIVATE),
		"Контракт: саботаж" = list(/datum/hk_contract_task/sabotage, HK_CLIENT_SYNDICATE),
		"Контракт: охота с опознанием" = list(/datum/hk_contract_task/hunt, HK_CLIENT_SYNDICATE),
	)
	var/datum/weakref/recent_target_ref

/datum/antag_training_program/hk47/New()
	. = ..()
	option_hints = list(
		"Добавить очки" = "Счёт HK-47 пополнится до [ANTAG_TRAINING_POINTS] очков - хватит на все модули терминала. В раунде очки дают выполненные контракты, а каждый следующий модуль шасси и каждый новый вызов пары HK-50 дороже. HK-50 с разумом на полигоне недоступен: призраков сюда не зовут.",
		"Вызвать HK-50 для боя" = "Пара враждебных HK-50 встанет в дальнем конце вашего сектора, а из центра - на арене противников. Новую пару можно вызвать, когда прежней не станет.",
		"ЭМИ по себе" = "Импульс как от ионной винтовки отключает шасси HK на [HK_EMP_HEAVY_STUN / (1 SECONDS)] с, слабый - на [HK_EMP_LIGHT_STUN / (1 SECONDS)] с, и разряжает винтовку. Этого окна хватает экипажу на наручники. Снова отключить шасси можно только через [HK_EMP_STUN_COOLDOWN / (1 SECONDS)] с. В безопасном центре не действует.",
		"Перепрошить меня" = "Итог операции экипажа на голове HK: хозяином станет ближайшая ваша учебная цель, и, как в раунде, роль HK-47, контракты и терминал погаснут. Вернуть их - «Начать новым персонажем». Без цели хозяин просто сбросится.",
		"Полный заряд" = "Заряд шасси и батарея винтовки до полного. В раунде заряд пополняют шнуром от APC, а винтовка тратит его на выстрелы.",
		"Контракт: ликвидация" = "Учебная ликвидация последней учебной цели: убить и просканировать тело терминалом.",
		"Контракт: захват" = "Учебный захват последней учебной цели: обездвижить и вызвать капсулу. Капсула не покидает сектор.",
		"Контракт: кража" = "Учебная кража: у последней учебной цели появится её ID-карта, её нужно забрать и просканировать.",
		"Контракт: охрана" = "Учебная охрана последней учебной цели: [DisplayTimeText(ANTAG_TRAINING_HK47_PROTECT_TIME)] вместо [DisplayTimeText(HK47_PROTECT_TIME)] раунда.",
		"Контракт: саботаж" = "В секторе встанет учебный сервер, его нужно вывести из строя.",
		"Контракт: охота с опознанием" = "[ANTAG_TRAINING_HK47_SUSPECTS] манекена рядом, цель - один из них: опознать вблизи, затем ликвидировать или захватить.",
	)

/datum/antag_training_program/hk47/setup(datum/antag_training_session/session)
	var/mob/living/carbon/human/droid = session.avatar
	for(var/obj/item/worn as anything in droid.get_equipped_items(include_pockets = TRUE))
		qdel(worn)
	for(var/obj/item/bodypart/part as anything in droid.bodyparts)
		if(part.is_robotic_limb(FALSE))
			qdel(part)
	droid.regenerate_limbs()
	droid.set_species(/datum/species/ipc/hk/hk47)
	droid.gender = MALE
	droid.real_name = HK47_NAME
	droid.name = HK47_NAME
	droid.dna.real_name = HK47_NAME
	droid.dna.update_dna_identity()
	session.avatar_mind.name = HK47_NAME
	droid.equipOutfit(/datum/outfit/hk47)
	droid.AddComponent(/datum/component/hk_loyalty)
	var/datum/antagonist/hk47/training/role = new
	role.training = session
	session.avatar_mind.add_antag_datum(role)
	return TRUE

/datum/antag_training_program/hk47/handle_choice(datum/antag_training_session/session, mob/living/user, choice)
	if(!is_species(user, /datum/species/ipc/hk))
		to_chat(user, span_warning("Кнопки HK-47 работают только в теле дроида HK. Начните новым персонажем, чтобы вернуть его."))
		return
	if(practice_tasks[choice])
		start_practice_contract(session, user, choice)
		return
	switch(choice)
		if("Добавить очки")
			var/datum/antagonist/hk47/training/role = user.mind?.has_antag_datum(/datum/antagonist/hk47/training)
			if(!role)
				to_chat(user, span_warning("Роль HK-47 снята. Начните новым персонажем, чтобы вернуть её."))
			else if(role.points >= ANTAG_TRAINING_POINTS)
				to_chat(user, span_notice("На счету уже [role.points] очков."))
			else
				role.award(ANTAG_TRAINING_POINTS - role.points)
		if("Вызвать HK-50 для боя")
			call_hk50(session, user)
		if("ЭМИ по себе")
			if(session.arena.safe_turf(get_turf(user)))
				to_chat(user, span_warning("В безопасной зоне ЭМИ не действует. Перейдите на боевую площадку."))
				return
			new /obj/effect/temp_visual/emp(get_turf(user))
			user.emp_act(HK47_TRAINING_EMP_SEVERITY)
			to_chat(user, span_notice("Так HK встречают ионная винтовка и ЭМИ-гранаты: шасси отключено на [HK_EMP_HEAVY_STUN / (1 SECONDS)] с, винтовка разряжена. Этого хватает, чтобы надеть наручники. Следующий импульс отключит шасси не раньше чем через [HK_EMP_STUN_COOLDOWN / (1 SECONDS)] с."))
		if("Перепрошить меня")
			var/datum/component/hk_loyalty/loyalty = user.GetComponent(/datum/component/hk_loyalty)
			if(!loyalty)
				return
			var/mob/living/carbon/human/surgeon = nearest_target(session, user)
			loyalty.set_master(surgeon?.mind)
			if(surgeon)
				to_chat(user, span_notice("Так выглядит перепрошивка: хозяином стала учебная цель [surgeon.real_name]. В раунде экипаж проводит её операцией на голове обездвиженного HK - сбитого с ног, скованного или в крите. Вернуть роль - «Начать новым персонажем»."))
			else
				to_chat(user, span_notice("Учебной цели нет, поэтому хозяин просто сброшен. Создайте цель в разделе «Цели», и перепрошивка назначит её хозяином. В раунде экипаж проводит её операцией на голове обездвиженного HK."))
		if("Полный заряд")
			user.set_nutrition(NUTRITION_LEVEL_WELL_FED)
			for(var/obj/item/gun/energy/hk_rifle/rifle in user.GetAllContents())
				rifle.cell.give(rifle.cell.maxcharge)
				if(!rifle.chambered)
					rifle.recharge_newshot(TRUE)
				rifle.update_appearance()
			to_chat(user, span_notice("Заряд шасси и винтовки полный. В раунде заряд пополняют шнуром от APC, а винтовка расходует его на выстрелы."))

/// Ближайшая живая учебная цель этого участника с разумом.
/datum/antag_training_program/hk47/proc/nearest_target(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/nearest
	for(var/mob/living/carbon/human/target in session.arena.targets)
		if(!target.mind || target.stat == DEAD || !session.can_manage_target(target))
			continue
		if(!nearest || get_dist(user, target) < get_dist(user, nearest))
			nearest = target
	return nearest

/datum/antag_training_program/hk47/proc/call_hk50(datum/antag_training_session/session, mob/living/user)
	var/datum/antag_training_arena/arena = session.arena
	if(arena.finished || arena.resetting || world.time < arena.next_spawn_at)
		to_chat(user, span_warning("Подождите пару секунд перед новым вызовом."))
		return
	arena.prune_targets()
	var/active = 0
	for(var/mob/living/simple_animal/hostile/hk50/droid in arena.targets)
		if(droid.training_owner?.resolve() == session)
			active++
	if(active >= ANTAG_TRAINING_HK50_PAIR)
		to_chat(user, span_warning("Ваша пара HK-50 ещё в строю. Уничтожьте её или удалите в разделе «Цели»."))
		return
	var/zone_id = session.hk47_sector(user)
	if(zone_id == "melee" && arena.duel && arena.duel.phase != "invite")
		to_chat(user, span_warning("На арене ближнего боя идёт дуэль. Вызовите HK-50 в другом секторе."))
		return
	arena.next_spawn_at = world.time + 1 SECONDS
	var/list/zone = arena.zones[zone_id]
	var/spawned = 0
	while(active + spawned < ANTAG_TRAINING_HK50_PAIR && arena.has_target_room())
		var/turf/spot = arena.free_spot(zone["target"], zone["bounds"])
		if(!spot)
			break
		var/mob/living/simple_animal/hostile/hk50/droid = new(spot)
		if(!arena.claim_target(droid, session, TRUE))
			qdel(droid)
			break
		droid.toggle_ai(AI_ON)
		spawned++
	if(!spawned)
		to_chat(user, span_warning("HK-50 негде встать: сектор занят или достигнут лимит целей."))
		return
	to_chat(user, span_notice("HK-50 в секторе «[zone["name"]]»: [spawned]. Они стреляют лазером с дистанции и отходят, если подойти вплотную. ЭМИ ненадолго их выключает."))

/datum/antagonist/hk47/training
	name = "Учебный HK-47"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	prevent_roundtype_conversion = FALSE
	soft_antag = TRUE
	replace_banned = FALSE

/// На полигоне ядро памяти не выпадает: его баунти - награда за настоящего HK-47.
/datum/antagonist/hk47/training/on_droid_death(mob/living/source, gibbed)
	return

/datum/antagonist/hk47/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/// Брифинг и голос прибытия только для самого игрока.
/datum/antagonist/hk47/training/proc/brief()
	var/mob/living/droid = owner.current
	to_chat(droid, span_boldnotice("Тренировка HK-47: вы - дроид-ассасин серии HK. Винтовка на спине стреляет только в ваших руках и подзаряжается от вашего заряда. Комбинезон, броня и шлем на шасси не надеваются, зато шлюзы техтоннелей открываются без карты. Боевой режим - клавиша C или кнопка на HUD: в нём вы разворачиваетесь к курсору, блокируете и парируете."))
	to_chat(droid, span_notice("Контрактный терминал и целеуказатель работают как в раунде, но цели - учебные манекены, а станция ничего не узнает. «Пульт полигона», раздел «Моя роль»: очки, пара HK-50 для боя, ЭМИ по себе, перепрошивка, заряд и учебные контракты всех видов. Подсказка на каждой кнопке объясняет, что она показывает."))
	droid.playsound_local(get_turf(droid), voice_lines["hk47_activate"], HK47_VOICE_VOLUME, FALSE)

#undef HK47_TRAINING_EMP_SEVERITY
