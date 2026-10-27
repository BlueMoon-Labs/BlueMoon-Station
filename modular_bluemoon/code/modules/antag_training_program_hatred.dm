/// Источник трейтов и иммунитетов массового стрелка, HATRED_ANTAG в hatred.dm.
#define ANTAG_TRAINING_HATRED_SOURCE "hatred"
#define ANTAG_TRAINING_HATRED_KNOCKOUT (30 SECONDS)

/datum/antag_training_program/antag/hatred
	name = "Массовый стрелок"
	category = "Предатели экипажа"
	desc = "Безымянный с проклятым снаряжением: автомат, автоматический дробовик или пистолеты, подсумок, наполняющий магазины, казни в упор, которые лечат стрелка, и пояс, обращающий сердца во взрывчатку. Кукла принимает облик Безымянного. Без высадки на станцию, объявления и взрывного импланта."
	icon = "gun"
	color = "red"
	learn = "Выбор оружия Безымянного|Подсумок, наполняющий магазины|Казни в упор и лечение|Пояс, обращающий сердца во взрывчатку"
	difficulty = 2
	antag_type = /datum/antagonist/hatred/training
	avatar_name = "The Man without a name"
	choice_prompt = "Оружие"
	target_action = "Отметить для казни"
	options = list("Пополнить магазины и C4", "Цель для казни")
	choices = list("AK47" = "AK47", "Automatic Shotgun" = "Автоматический дробовик", "Pistols" = "Пистолеты")
	var/high_gear
	var/static/list/gear_choices = list("Обычное снаряжение" = "", "Больше брони" = "More armor", "Быстрые казни" = "Faster executions")
	var/static/list/gun_hints = list(
		"AK47" = "Автомат AK-47 Ненависти и подсумок с двумя магазинами.",
		"Automatic Shotgun" = "Автоматический дробовик с четырьмя магазинами разных патронов, стрельба одной рукой при занятой второй и двустволка «План Б» на поясе с патронами, выбивающими двери и окна.",
		"Pistols" = "Два пистолета M1911 в кобуре: стрельба с двух рук в боевом намерении, пустой пистолет выбрасывается, кобура тут же воплощает новый. Вместо подсумка с магазинами - подсумок для взлома с зарядом C4 на короткий таймер.",
	)
	var/static/list/gear_hints = list(
		"Обычное снаряжение" = "Так стрелок выходит почти всегда: усиление в раунде дают, только если на станции сильная охрана.",
		"Больше брони" = "Усиление сильной охраны: плащ и вуаль крепче по всем видам защиты.",
		"Быстрые казни" = "Усиление сильной охраны: казнь выстрелом и ножом готовится быстрее.",
	)

/datum/antag_training_program/antag/hatred/New()
	. = ..()
	for(var/label in gear_choices)
		options += gear_option(label)
	option_hints = list(
		"Пополнить магазины и C4" = "Магазины в подсумке и в оружии, патроны «Плана Б» и пистолетов наполняются, подсумок для взлома сразу получает заряд C4. В раунде пустой магазин наполняет только Подсумок Ненависти, а новый C4 появляется в подсумке через время после того, как прежний вынут.",
		"Цель для казни" = "Последняя ваша живая учебная цель или отмеченная кнопкой «Отметить для казни» в разделе «Цели» теряет сознание на [ANTAG_TRAINING_HATRED_KNOCKOUT / (1 SECONDS)] секунд. Казнь ножом - только цели без сознания; выстрел в упор в рот - любой. В раунде казнь лечит только на целях-игроках, учебные цели засчитываются здесь.",
	)
	for(var/key in choices)
		option_hints[choice_option(key)] = "[gun_hints[key]] Смена оружия перевыдаёт роль: прежнее снаряжение исчезает, вещи из сумки выпадают на пол."
	for(var/label in gear_choices)
		option_hints[gear_option(label)] = "[gear_hints[label]] Смена перевыдаёт роль с тем же оружием."

/datum/antag_training_program/antag/hatred/proc/gear_option(label)
	return "Усиление: [label]"

/datum/antag_training_program/antag/hatred/apply_choice(datum/antagonist/hatred/training/role)
	role.chosen_gun = choice
	role.chosen_high_gear = high_gear
	role.gun_label = choices[choice]
	for(var/label in gear_choices)
		if(gear_choices[label] == (high_gear || ""))
			role.gear_label = label

/datum/antag_training_program/antag/hatred/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	. = ..()
	if(target.mind)
		to_chat(session.current_body, span_notice("[target.real_name] отмечен[target.ru_a()]: «Цель для казни» в «Моей роли» лишит [target.ru_ego()] сознания."))

/datum/antag_training_program/antag/hatred/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	for(var/label in gear_choices)
		if(option == gear_option(label))
			high_gear = gear_choices[label] || null
			change_choice(session, user, choice)
			return TRUE
	var/datum/antagonist/hatred/training/shooter = role(session)
	if(!shooter)
		to_chat(user, span_warning("Роль стрелка снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Пополнить магазины и C4")
			shooter.resupply()
		if("Цель для казни")
			knock_out_target(session, user)
	return TRUE

/datum/antag_training_program/antag/hatred/proc/knock_out_target(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = recent_target(session)
	if(!dummy)
		to_chat(user, span_warning("Нет живой учебной цели. Создайте человека в разделе «Цели» и нажмите кнопку снова."))
		return FALSE
	if(!session.can_condition_target(dummy))
		return FALSE
	dummy.Unconscious(ANTAG_TRAINING_HATRED_KNOCKOUT, TRUE, TRUE)
	to_chat(user, span_notice("[dummy.real_name] без сознания. Прицельтесь в рот: нож перерезает горло, оружие в упор после долгого прицеливания стреляет в голову."))
	return TRUE

/// Учебная цель арены учебного стрелка годится для казни без игрока в теле.
/proc/antag_training_glory_target(datum/antagonist/hatred/training/shooter, mob/living/target)
	var/datum/antag_training_arena/arena = istype(shooter) ? shooter.training?.arena : null
	return !!arena && (target.mind in arena.target_minds) && target.training_origin?.resolve() == arena

/datum/antagonist/hatred/training
	name = "Training Mass Shooter"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	outfit_type = /datum/outfit/hatred/training
	var/datum/antag_training_session/training
	var/gun_label = "AK47"
	var/gear_label = "Обычное снаряжение"
	var/list/datum/weakref/training_gear
	var/list/datum/quirk/training_quirks
	var/had_mood = FALSE
	var/could_knock_down = FALSE
	var/was_unconvertable = FALSE
	var/previous_drag_slowdown
	var/static/list/kit_slots = list(ITEM_SLOT_LPOCKET, ITEM_SLOT_SUITSTORE, ITEM_SLOT_ID, ITEM_SLOT_BELT, ITEM_SLOT_BACK, ITEM_SLOT_HEAD, ITEM_SLOT_EYES, ITEM_SLOT_GLOVES, ITEM_SLOT_FEET, ITEM_SLOT_OCLOTHING, ITEM_SLOT_ICLOTHING)

/datum/antagonist/hatred/training/on_gain()
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body))
		return ..()
	clear_slots(body)
	var/list/carried = worn_items(body)
	var/list/quirks_before = body.roundstart_quirks.Copy()
	had_mood = !!body.GetComponent(/datum/component/mood)
	could_knock_down = !!(body.status_flags & CANKNOCKDOWN)
	was_unconvertable = owner.unconvertable
	previous_drag_slowdown = body.drag_slowdown
	. = ..()
	if(QDELETED(body))
		return
	UnregisterSignal(body, COMSIG_MOVABLE_PRE_MOVE)
	for(var/datum/action/hatred_deploy/deploy in body.actions)
		qdel(deploy)
	training_quirks = body.roundstart_quirks - quirks_before
	training_gear = list()
	for(var/obj/item/gear as anything in worn_items(body) - carried)
		training_gear += WEAKREF(gear)

/datum/antagonist/hatred/training/proc/worn_items(mob/living/carbon/human/body)
	. = list()
	for(var/obj/item/worn as anything in body.get_equipped_items(TRUE) + body.held_items)
		if(worn)
			. |= worn.GetAllContents(/obj/item)

/// Снаряжение участника уступает слоты набору: стандартное исчезает, остальное падает на пол.
/datum/antagonist/hatred/training/proc/clear_slots(mob/living/carbon/human/body)
	var/datum/outfit/participant = /datum/outfit/antag_training
	var/list/participant_kit = list(initial(participant.uniform), initial(participant.shoes), initial(participant.back), initial(participant.l_pocket))
	for(var/slot in kit_slots)
		var/obj/item/worn = body.get_item_by_slot(slot)
		if(!worn)
			continue
		if((worn.type in participant_kit) && !length(worn.contents))
			qdel(worn)
		else
			body.dropItemToGround(worn, TRUE)

/datum/antagonist/hatred/training/threat()
	return 0

/datum/antagonist/hatred/training/forge_objectives()
	return

/datum/antagonist/hatred/training/evaluate_security()
	gear_level = chosen_high_gear ? 2 : 1

/datum/antagonist/hatred/training/check_hatred_off_station()
	return

/datum/antagonist/hatred/training/appear_on_station()
	return

/datum/antagonist/hatred/training/alarm_station()
	return

/datum/antagonist/hatred/training/on_hatred_death()
	return

/datum/antagonist/hatred/training/leave_body(mob/living/body)
	return

/datum/antagonist/hatred/training/greet()
	antag_memory = briefing()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/hatred/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/hatred/training/proc/briefing()
	var/list/lines = list(
		span_boldnotice("Тренировка массового стрелка. Оружие: [gun_label], усиление: [gear_label]."),
		span_notice("Казнь: прицельтесь в рот и нажмите оружием на соседнюю цель - после долгого прицеливания выстрел в голову убивает. Нож в рот цели без сознания перерезает горло. Казнь живой цели лечит раны, на время ускоряет и даёт Поясу Ненависти место для сердца: вырежьте ножом сердце мёртвой цели прицелом в грудь и положите в пояс - оно станет гранатой или коктейлем Молотова. Обычная медицина вас не лечит, в критическом состоянии раны затягиваются сами."),
		span_notice("Пояс, Подсумок Ненависти, кобура и вуаль не снимаются и рассыпаются, если их сорвать."),
	)
	switch(chosen_gun)
		if("AK47")
			lines += span_notice("Пустой магазин, положенный в Подсумок Ненависти, наполняется.")
		if("Automatic Shotgun")
			lines += span_notice("Пустой магазин, положенный в Подсумок Ненависти, наполняется. Дробовик стреляет одной рукой, даже если вторая занята. На поясе - двустволка «План Б» с патронами, выбивающими двери и окна.")
		if("Pistols")
			lines += span_notice("Пистолеты стреляют с двух рук в боевом намерении. Пустой пистолет выбрасывается, кобура тут же воплощает новый. В подсумке для взлома - C4 на короткий таймер.")
	lines += span_notice("В раунде стрелок ждёт в закрытой комнате и сам отправляется на станцию, а через несколько секунд экипаж получает объявление с его приметами. Усиление дают только при сильной охране. Покинувшего станцию возвращает обратно. После смерти взрывается имплант, с тела падают плащ и оружие, а снятая роль обращает тело в прах. Здесь ничего этого нет: без высадки и объявления, без импланта, после смерти вы восстанавливаетесь со своим снаряжением.")
	lines += span_notice("«Пульт полигона», раздел «Моя роль»: смена оружия и усиления, «Пополнить магазины и C4», «Цель для казни». Учебные цели засчитываются для казни без игрока в теле, в раунде - только цели-игроки.")
	return jointext(lines, "<br>")

/datum/antagonist/hatred/training/proc/resupply()
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body))
		return FALSE
	var/list/carried = body.GetAllContents()
	for(var/obj/item/ammo_box/magazine/magazine in carried)
		for(var/obj/item/ammo_casing/casing as anything in magazine.stored_ammo.Copy())
			if(!casing.BB)
				magazine.stored_ammo -= casing
				qdel(casing)
		while(length(magazine.stored_ammo) < magazine.max_ammo)
			magazine.stored_ammo += new magazine.ammo_type(magazine)
		magazine.update_icon()
	for(var/obj/item/gun/ballistic/gun in carried)
		if(gun.chambered && (QDELETED(gun.chambered) || !gun.chambered.BB))
			if(gun.chambered.loc == gun)
				qdel(gun.chambered)
			gun.chambered = null
		gun.chamber_round()
		gun.update_icon()
	var/obj/item/storage/bag/ammo/hatred_c4/breaching = locate() in carried
	breaching?.create_c4()
	to_chat(body, span_notice("Магазины полны[breaching ? ", в подсумке для взлома заряд C4" : ""]."))
	return TRUE

/datum/antagonist/hatred/training/on_removal()
	strip_role()
	return ..()

/datum/antagonist/hatred/training/proc/strip_role()
	var/list/gear = list()
	for(var/datum/weakref/gear_ref as anything in training_gear)
		var/obj/item/item = gear_ref.resolve()
		if(item)
			gear += item
	training_gear = null
	for(var/obj/item/storage/backpack/satchel in gear)
		for(var/obj/item/stowed in satchel.contents - gear)
			stowed.forceMove(satchel.drop_location())
	QDEL_LIST(gear)
	QDEL_LIST(training_quirks)
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body))
		return
	REMOVE_TRAITS_IN(body, ANTAG_TRAINING_HATRED_SOURCE)
	body.remove_movespeed_modifier(/datum/movespeed_modifier/hatred)
	body.remove_movespeed_modifier(/datum/movespeed_modifier/hatred_glory_kill)
	for(var/slowdown in body.movespeed_mod_immunities?.Copy())
		body.remove_movespeed_mod_immunities(ANTAG_TRAINING_HATRED_SOURCE, slowdown, FALSE)
	body.update_movespeed()
	body.drag_slowdown = previous_drag_slowdown
	if(could_knock_down)
		body.status_flags |= CANKNOCKDOWN
	owner.unconvertable = was_unconvertable
	if(had_mood && !body.GetComponent(/datum/component/mood))
		body.AddComponent(/datum/component/mood)

/datum/antagonist/hatred/training/Destroy()
	training = null
	training_gear = null
	training_quirks = null
	return ..()

/datum/outfit/hatred/training
	name = "Hatred (training)"
	implants = null

/datum/outfit/hatred/training/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	var/datum/antagonist/hatred/shooter = H.mind?.has_antag_datum(/datum/antagonist/hatred)
	if(shooter)
		arm(H, shooter)

#undef ANTAG_TRAINING_HATRED_SOURCE
#undef ANTAG_TRAINING_HATRED_KNOCKOUT
