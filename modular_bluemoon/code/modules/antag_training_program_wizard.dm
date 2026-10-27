#define ANTAG_TRAINING_ROD_LIFETIME (5 SECONDS)
/// Сколько после попадания заклинания крит цели ещё засчитывается ему: огонь от шара добивает не сразу.
#define ANTAG_TRAINING_WIZARD_SPELL_WINDOW (15 SECONDS)
/// Заклинание выучено в учебной книге, на покупателе: (datum/spellbook_entry/entry)
#define COMSIG_ANTAG_TRAINING_SPELL_LEARNED "antag_training_spell_learned"

/// Позиции книги заклинаний, которых нет в учебной книге: тип (с подтипами) -> причина.
GLOBAL_LIST_INIT(antag_training_closed_spellbook_entries, list(
	/datum/spellbook_entry/summon = "ритуалы действуют на всю станцию и раунд",
	/datum/spellbook_entry/item/contract = "ученика играет призрак",
	/datum/spellbook_entry/item/guardian = "стража заселяет призрак",
	/datum/spellbook_entry/item/soulstones = "в камни душ вселяют призраков",
	/datum/spellbook_entry/item/scryingorb = "шар выпускает призраком на станцию",
	/datum/spellbook_entry/item/warpwhistle = "свисток переносит на станцию",
	/datum/spellbook_entry/item/bloodbottle = "демона играет призрак",
	/datum/spellbook_entry/item/hugbottle = "демона играет призрак",
	/datum/spellbook_entry/item/staffnuclear = "покупка объявляется станции",
	/datum/spellbook_entry/item/staffchange = "превращение даёт киборга с бинарным каналом станции или ксеноморфа в улье раунда",
	/datum/spellbook_entry/item/staffchaos = "посох стреляет и превращениями",
	/datum/spellbook_entry/item/wands = "в наборе жезл превращения",
	/datum/spellbook_entry/lichdom = "филактерия меняет условие конца раунда и добавляет ему угрозу",
	/datum/spellbook_entry/alive_bones = "скелета играет призрак, а маг получает команду раунда",
))

/proc/antag_training_spellbook_closed(entry_type)
	for(var/closed_type in GLOB.antag_training_closed_spellbook_entries)
		if(ispath(entry_type, closed_type))
			return GLOB.antag_training_closed_spellbook_entries[closed_type]
	return null

/proc/antag_training_wizard_arena(atom/thing)
	var/area/antag_training/place = get_area(thing)
	return istype(place) && !place.arena?.finished ? place.arena : null

/// Зоны для учебного телепорта; чужие занятые сектора user не предлагаются.
/datum/antag_training_arena/proc/teleport_destinations(mob/user)
	. = list()
	var/datum/antag_training_session/session = session_of(user)
	for(var/zone_id in zones)
		var/datum/antag_training_sector/sector = sectors[zone_id]
		if(session && sector?.entry_refusal(session))
			continue
		.[zones[zone_id]["name"]] = zone_id

/datum/antag_training_arena/proc/teleport_turf(zone_id)
	var/list/zone = zones[zone_id]
	if(!zone || !private_level)
		return null
	var/list/bounds = zone["bounds"]
	var/list/spots = list()
	for(var/turf/open/spot in block(locate(bounds[1], bounds[3], private_level.z_value), locate(bounds[2], bounds[4], private_level.z_value)))
		if(!isspaceturf(spot) && !spot.is_blocked_turf(exclude_mobs = TRUE))
			spots += spot
	return length(spots) ? pick(spots) : zone["spawn"]

/datum/antag_training_program/antag/wizard
	name = "Маг Федерации"
	category = "Культы и магия"
	desc = "Мантия, посох, учебная книга заклинаний с возвратом очков в любом месте полигона, свиток телепортации по зонам полигона и манекены для касаний и проклятий. Упражнение «Книга и огненный шар» в тире: покупка заклинания и цель, сваленная им в крит."
	icon = "hat-wizard"
	color = "violet"
	learn = "Книга заклинаний с возвратом очков|Мантия и посох|Свиток телепортации по зонам|Огненный шар по цели в тире|Касания и проклятия на манекенах"
	difficulty = 2
	antag_type = /datum/antagonist/wizard/training
	options = list("Пополнить очки", "Новый свиток", "Цель для заклинаний")

/datum/antag_training_program/antag/wizard/New()
	. = ..()
	var/obj/item/spellbook/training/book_type = /obj/item/spellbook/training
	var/obj/item/teleportation_scroll/training/scroll_type = /obj/item/teleportation_scroll/training
	option_hints = list(
		"Пополнить очки" = "В книге снова будет [initial(book_type.uses)] очков, разовые покупки вернутся, выученное останется. В раунде очки не пополняются, а вернуть их за заклинание можно только в логове Федерации.",
		"Новый свиток" = "Учебный свиток телепортации на [initial(scroll_type.uses)] переноса в руки. Он переносит по зонам полигона, в раунде свиток один и ведёт в отсеки станции.",
		"Цель для заклинаний" = "Рядом встанет манекен с разумом - цель для касаний, Flesh to Stone и проклятий. Mindswap действует только на другого участника. Из безопасного центра манекен встаёт в лаборатории. Покупку заклинания и цель, сваленную им в крит, с шагами и оценкой проходят в упражнении «Книга и огненный шар» в тире.",
	)

/datum/antag_training_program/antag/wizard/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/wizard/training/wizard = role(session)
	if(!wizard)
		to_chat(user, span_warning("Роль мага снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Пополнить очки")
			wizard.refill_book(user)
		if("Новый свиток")
			issue_scroll(session, user)
		if("Цель для заклинаний")
			place_spell_target(session, user)
	return TRUE

/datum/antag_training_program/antag/wizard/proc/issue_scroll(datum/antag_training_session/session, mob/living/user)
	if(world.time < session.next_supply_at)
		to_chat(user, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return null
	session.next_supply_at = world.time + 1 SECONDS
	var/obj/item/teleportation_scroll/training/scroll = session.arena.issue_item(/obj/item/teleportation_scroll/training, get_turf(user), 1, session)
	if(!scroll)
		to_chat(user, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return null
	user.put_in_hands(scroll)
	to_chat(user, span_notice("Новый учебный свиток телепортации у вас: [scroll.uses] переноса по зонам полигона."))
	return scroll

/datum/antag_training_program/antag/wizard/proc/place_spell_target(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
	if(dummy)
		to_chat(user, span_notice("[dummy.real_name] встал[dummy.ru_a()] в зоне «[dummy_zone_name(session, dummy)]»."))
	return dummy

/datum/antagonist/wizard/training
	name = "Учебный маг"
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
	silent = TRUE
	give_objectives = FALSE
	allow_rename = FALSE
	move_to_lair = FALSE
	change_species = FALSE
	outfit_type = /datum/outfit/wizard/training
	var/datum/antag_training_session/training
	var/datum/weakref/book_ref

/datum/antagonist/wizard/training/on_gain()
	. = ..()
	greet()

/datum/antagonist/wizard/training/register()
	return

/datum/antagonist/wizard/training/unregister()
	return

/datum/antagonist/wizard/training/threat()
	return 0

/datum/antagonist/wizard/training/equip_wizard()
	. = ..()
	var/mob/living/body = owner.current
	book_ref = WEAKREF(locate(/obj/item/spellbook/training) in body?.held_items)

/datum/antagonist/wizard/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/wizard/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/wizard/training/proc/briefing()
	var/obj/item/spellbook/training/book_type = /obj/item/spellbook/training
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/wizard_fireball
	return jointext(list(
		span_boldnotice("Тренировка мага Федерации."),
		span_notice("Книга заклинаний в руке: [initial(book_type.uses)] очков. Кнопка Refund возвращает очки за выученное заклинание в любом месте полигона, в раунде - только в логове Федерации. На полигоне книга открыта целиком, в раунде часть позиций появляется лишь при высокой угрозе смены. Большинство заклинаний требует мантию и шляпу."),
		span_notice("В учебной книге нет ритуалов, контракта ученика, колоды стража, камней душ, шара провидения, свистка, бутылок с демонами, Bind Soul, Alive bones, ядерного посоха, посохов и жезлов превращения: они зовут призраков или действуют на станцию и раунд."),
		span_notice("Свиток телепортации и заклинание Teleport переносят по зонам полигона, в раунде - по отсекам станции. Стержень Rod Form на полигоне живёт не дольше [DisplayTimeText(ANTAG_TRAINING_ROD_LIFETIME)] и у края арены отпускает мага."),
		span_notice("«Пульт полигона», раздел «Моя роль»: пополнить очки книги, новый свиток и манекен для заклинаний."),
		span_notice("Упражнение «[initial(exercise.name)]» в тире: выучите заклинание в книге и сведите им учебную цель в крит, с подсказками и оценкой. Пульт, вкладка «Упражнения»."),
	), "<br>")

/datum/antagonist/wizard/training/proc/refill_book(mob/living/user)
	var/obj/item/spellbook/training/book = book_ref?.resolve()
	if(QDELETED(book))
		book = training?.arena?.issue_item(/obj/item/spellbook/training, get_turf(user), 1, training)
		if(!book)
			to_chat(user, span_warning("Книга потеряна, а новую выдать нельзя: достигнут лимит выданных предметов."))
			return FALSE
		book.owner = user
		book_ref = WEAKREF(book)
		user.put_in_hands(book)
		to_chat(user, span_notice("Прежняя книга потеряна - у вас новая, выученное осталось."))
	book.uses = initial(book.uses)
	for(var/datum/spellbook_entry/entry as anything in book.entries)
		entry.limit = initial(entry.limit)
	to_chat(user, span_notice("В книге [book.uses] очков. Выученные заклинания остались."))
	return TRUE

/datum/antagonist/wizard/training/Destroy()
	training = null
	book_ref = null
	return ..()

/datum/outfit/wizard/training
	name = "Training Wizard"
	ears = null
	r_pocket = /obj/item/teleportation_scroll/training
	r_hand = /obj/item/spellbook/training

/obj/item/spellbook/training
	desc = "Учебная книга заклинаний полигона: без ритуалов и того, что зовёт призраков, очки возвращаются в любом месте полигона."

/obj/item/spellbook/training/prepare_spells()
	for(var/entry_type in subtypesof(/datum/spellbook_entry) - /datum/spellbook_entry/item - /datum/spellbook_entry/summon)
		if(antag_training_spellbook_closed(entry_type))
			continue
		var/datum/spellbook_entry/entry = new entry_type
		if(entry.spell_type == /obj/effect/proc_holder/spell/targeted/area_teleport/teleport)
			entry.spell_type = /obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training
		else if(entry.spell_type == /obj/effect/proc_holder/spell/targeted/rod_form)
			entry.spell_type = /obj/effect/proc_holder/spell/targeted/rod_form/training
		entries += entry
		categories |= entry.category
	tab = categories[1]

/obj/item/spellbook/training/Topic(href, href_list)
	var/points_before = uses
	var/mob/buyer = usr
	. = ..()
	if(href_list["buy"] && uses < points_before && ismob(buyer))
		SEND_SIGNAL(buyer, COMSIG_ANTAG_TRAINING_SPELL_LEARNED, entries[text2num(href_list["buy"])])

/obj/item/teleportation_scroll/training
	desc = "Учебный свиток телепортации: переносит в выбранную зону тренировочного полигона."

/obj/item/teleportation_scroll/training/teleportscroll(mob/user)
	var/datum/antag_training_arena/arena = antag_training_wizard_arena(user)
	if(!arena)
		to_chat(user, span_warning("Учебный свиток действует только на тренировочном полигоне."))
		return
	var/list/destinations = arena.teleport_destinations(user)
	var/choice = pick_destination(user, destinations)
	if(QDELETED(src) || QDELETED(user) || !user.is_holding(src) || user.incapacitated() || !choice || !uses || arena.finished)
		return
	var/turf/destination = arena.teleport_turf(destinations[choice])
	if(!destination)
		to_chat(user, span_warning("Зоны «[choice]» больше нет."))
		return
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(2, user.loc)
	smoke.attach(user)
	smoke.start()
	if(!do_teleport(user, destination, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC, forced = TRUE))
		to_chat(user, span_warning("Перенос сорвался: зона «[choice]» закрыта на сброс, занята дуэлью или чужой группой."))
		return
	smoke.start()
	uses--

/obj/item/teleportation_scroll/training/proc/pick_destination(mob/user, list/destinations)
	return tgui_input_list(user, "Куда перенестись?", "Свиток телепортации", destinations)

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training
	desc = "Переносит в выбранную зону тренировочного полигона."

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training/before_cast(list/targets)
	var/datum/antag_training_arena/arena = antag_training_wizard_arena(usr)
	if(!arena)
		to_chat(usr, span_warning("Учебный телепорт действует только на тренировочном полигоне."))
		return null
	var/list/destinations = arena.teleport_destinations(usr)
	var/choice = tgui_input_list(usr, "Куда перенестись?", "Телепорт", destinations)
	return choice ? destinations[choice] : null

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training/invocation(zone_id, mob/user = usr)
	var/datum/antag_training_arena/arena = antag_training_wizard_arena(user)
	var/list/zone = arena?.zones[zone_id]
	if(!zone)
		return ..(null, user)
	switch(invocation_type)
		if("shout")
			user.say("[invocation] [uppertext(zone["name"])]", forced = "spell")
		if("whisper")
			user.whisper("[invocation] [uppertext(zone["name"])]")

/obj/effect/proc_holder/spell/targeted/area_teleport/teleport/training/cast(list/targets, zone_id, mob/user = usr)
	var/datum/antag_training_arena/arena = antag_training_wizard_arena(user)
	playsound(get_turf(user), sound1, 50, TRUE)
	for(var/mob/living/target in targets)
		var/turf/destination = arena?.teleport_turf(zone_id)
		target.buckled?.unbuckle_mob(target, force = TRUE)
		if(!destination || !do_teleport(target, destination, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC, forced = TRUE))
			to_chat(user, span_warning("Перенос сорвался: зона закрыта на сброс, занята дуэлью или чужой группой, или пропала."))
			continue
		playsound(get_turf(target), sound2, 50, TRUE)

/obj/effect/proc_holder/spell/targeted/rod_form/training

/obj/effect/proc_holder/spell/targeted/rod_form/training/Initialize(mapload)
	desc = "Превращает в неудержимый стержень, сносящий всё на пути. На полигоне стержень живёт не дольше [DisplayTimeText(ANTAG_TRAINING_ROD_LIFETIME)]: упёршись в край арены или в закрытую зону, он отпускает мага."
	return ..()

/obj/effect/proc_holder/spell/targeted/rod_form/training/cast(list/targets, mob/user = usr)
	. = ..()
	for(var/mob/living/caster in targets)
		var/obj/effect/immovablerod/wizard/rod = caster.loc
		if(istype(rod))
			QDEL_IN(rod, ANTAG_TRAINING_ROD_LIFETIME)

/datum/antag_training_exercise/drill/wizard_fireball
	id = "wizard_fireball"
	name = "Книга и огненный шар"
	desc = "В дальнем конце тира встаёт учебная цель. Выучите в книге заклинаний заклинание-снаряд, например Fireball, и сведите им цель в крит или убейте. Засчитывается только урон заклинаний."
	sector = "range"
	program = /datum/antag_training_program/antag/wizard
	difficulty = 1
	par_time = 1 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/checked/wizard_learn, /datum/antag_training_exercise_step/drill/checked/wizard_strike)

/datum/antag_training_exercise/drill/wizard_fireball/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	prepare_target(session, "human", session.arena.zones[sector]["target"])
	return TRUE

/// Шаг 2 засчитывает урон снарядов, а не любое заклинание: учить надо заклинание-снаряд.
/proc/antag_training_wizard_strike_spell(datum/spellbook_entry/entry)
	return entry && !istype(entry, /datum/spellbook_entry/item) && ispath(entry.spell_type, /obj/effect/proc_holder/spell/aimed)

/// Снаряд заклинания, а не посоха или жезла из книги: они стреляют как оружие.
/proc/antag_training_wizard_spell_projectile(obj/item/projectile/projectile)
	return (istype(projectile, /obj/item/projectile/magic) || istype(projectile, /obj/item/projectile/spellcard)) && !istype(projectile.fired_from, /obj/item/gun)

/// Цель в крите раньше, чем выучено заклинание: шаг 2 не узнает, чем её свалили.
/datum/antag_training_exercise_step/drill/checked/wizard_learn
	name = "Выучите заклинание-снаряд в книге"
	hint = "Откройте книгу заклинаний в руке, вкладка Offensive, и нажмите Learn у Fireball: огненный шар появится кнопкой на панели действий. Lightning Bolt и Spell Cards тоже подойдут; Blink, Knock, Magic Missile, посохи и другие предметы из книги - нет. Цель пока не трогайте. Не хватает очков - «Пополнить очки» в «Моей роли»."
	target_death = "цель погибла раньше, чем вы выучили заклинание"

/datum/antag_training_exercise_step/drill/checked/wizard_learn/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/body = participant()
	if(body)
		RegisterSignal(body, COMSIG_ANTAG_TRAINING_SPELL_LEARNED, PROC_REF(on_learned))

/datum/antag_training_exercise_step/drill/checked/wizard_learn/proc/on_learned(mob/living/source, datum/spellbook_entry/entry)
	SIGNAL_HANDLER
	if(antag_training_wizard_strike_spell(entry))
		complete()

/datum/antag_training_exercise_step/drill/checked/wizard_learn/check()
	var/mob/living/target = exercise_target()
	if(target && target.health <= target.crit_threshold)
		run.finish(FALSE, "цель свалена раньше, чем вы выучили заклинание в книге: сначала Learn, потом удар")
	return FALSE

/// Крит и смерть засчитываются, только если незадолго до них цель поймала снаряд заклинания участника.
/datum/antag_training_exercise_step/drill/checked/wizard_strike
	name = "Сведите цель в крит заклинанием"
	hint = "Нажмите кнопку огненного шара на панели действий и щёлкните по цели: шар летит по прямой и взрывается при попадании. Обычно хватает двух-трёх попаданий, между ними заклинание перезаряжается. Не подходите к цели ближе трёх клеток, взрыв заденет и вас. Кулаки, оружие, посохи и жезлы не в счёт: цель, сваленная не заклинанием, проваливает упражнение."
	target_death = null
	var/last_spell_hit = 0

/datum/antag_training_exercise_step/drill/checked/wizard_strike/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/target = exercise_target()
	if(target)
		RegisterSignal(target, COMSIG_LIVING_HIT_BY_PROJECTILE, PROC_REF(on_projectile))
		RegisterSignal(target, COMSIG_MOB_DEATH, PROC_REF(recheck))

/datum/antag_training_exercise_step/drill/checked/wizard_strike/proc/on_projectile(mob/living/source, obj/item/projectile/projectile, def_zone)
	SIGNAL_HANDLER
	if(projectile.firer == participant() && antag_training_wizard_spell_projectile(projectile))
		last_spell_hit = world.time

/datum/antag_training_exercise_step/drill/checked/wizard_strike/check()
	var/mob/living/target = exercise_target()
	if(!target || (target.stat != DEAD && target.health > target.crit_threshold))
		return FALSE
	if(last_spell_hit && world.time - last_spell_hit <= ANTAG_TRAINING_WIZARD_SPELL_WINDOW)
		return TRUE
	run.finish(FALSE, "цель свалена не заклинанием: в зачёт идёт только урон снарядов ваших заклинаний")
	return FALSE

#undef COMSIG_ANTAG_TRAINING_SPELL_LEARNED
#undef ANTAG_TRAINING_WIZARD_SPELL_WINDOW
#undef ANTAG_TRAINING_ROD_LIFETIME
