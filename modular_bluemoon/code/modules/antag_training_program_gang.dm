GLOBAL_LIST_EMPTY(antag_training_gang_families)
GLOBAL_LIST_EMPTY(antag_training_gang_phones)

/// Семьи банды, которые выбираются в пульте полигона.
/proc/antag_training_gang_family_types()
	. = list()
	for(var/datum/antagonist/gang/family_type as anything in subtypesof(/datum/antagonist/gang))
		if(initial(family_type.show_in_antagpanel))
			. += family_type

/// Имя, сокращение, одежда и тема семьи. Списки типа initial() не читает, поэтому их берут с временного датума.
/proc/antag_training_gang_family(family_type)
	var/list/family = GLOB.antag_training_gang_families[family_type]
	if(family || !(family_type in antag_training_gang_family_types()))
		return family
	var/datum/antagonist/gang/sample = new family_type
	family = list(
		"gang_name" = sample.gang_name,
		"gang_id" = sample.gang_id,
		"hud" = sample.antag_hud_name,
		"acceptable_clothes" = sample.acceptable_clothes.Copy(),
		"free_clothes" = sample.free_clothes.Copy(),
	)
	sample.discarded_before_gain = TRUE
	qdel(sample)
	for(var/theme_type in subtypesof(/datum/gang_theme))
		var/datum/gang_theme/theme = new theme_type
		var/involved = (family_type in theme.involved_gangs)
		qdel(theme)
		if(involved)
			family["theme"] = theme_type
			break
	GLOB.antag_training_gang_families[family_type] = family
	return family

/datum/antag_training_program/antag/gang
	name = "Банда"
	category = "Команды"
	desc = "Семья на выбор: телефон своей учебной линии, одежда семьи, приём учебных целей тайным рукопожатием и метки баллоном на стенах станционного макета. Упражнение «Вербовка и метка» ведёт от формы семьи через приём цели до метки по шагам."
	icon = "spray-can"
	color = "pink"
	learn = "Выбор семьи и форма на теле|Телефон учебной линии|Приём в банду рукопожатием|Метки баллоном на стенах"
	difficulty = 2
	sector = "station"
	antag_type = /datum/antagonist/gang/training
	choice_prompt = "Семья"
	options = list("Индукция учебной цели", "Новый баллон")

/datum/antag_training_program/antag/gang/New()
	for(var/family_type in antag_training_gang_family_types())
		var/list/family = antag_training_gang_family(family_type)
		choices[family_type] = family["gang_name"]
	. = ..()
	var/datum/action/cooldown/spawn_induction_package/handshake = /datum/action/cooldown/spawn_induction_package
	option_hints = list(
		"Индукция учебной цели" = "Если рядом нет вашей учебной цели, кнопка её ставит. Встаньте к цели вплотную, нажмите способность «Induct via Secret Handshake» и держите рукопожатие в активной руке, затем нажмите кнопку снова - цель примет его и станет учебным членом семьи с телефоном и одеждой. В раунде рукопожатие принимает сам игрок, кликнув по уведомлению; без свободной руки или с имплантом защиты разума принять его нельзя. Способность перезаряжается [initial(handshake.cooldown_time) / (1 SECONDS)] с. С шагами и оценкой это упражнение «Вербовка и метка» в макете: пока оно идёт, кнопка новую цель не ставит и принимает только цель упражнения.",
		"Новый баллон" = "Полный баллон краски в руки. Снимите колпачок (Alt+клик) и распылите на стену или пол станционного макета - появится метка семьи. Весь макет - одна территория: уже стоящую метку, даже свою, сначала закрасьте новой. В раунде метки ставят только на станции, по одной на отсек.",
	)
	for(var/family_type in choices)
		var/list/family = antag_training_gang_family(family_type)
		var/list/clothes = list()
		for(var/obj/item/clothing_type as anything in family["free_clothes"])
			clothes |= initial(clothing_type.name)
		option_hints[choice_option(family_type)] = "[family["gang_name"]] ([family["gang_id"]]): [english_list(clothes)]. Смена семьи перевыдаёт роль: новая учебная семья, телефон на новой линии и одежда, прежние учебные члены семьи из неё выходят. В раунде телефоны семьи слышат друг друга по всей станции, а задачу семье даёт тема раунда."

/datum/antag_training_program/antag/gang/apply_choice(datum/antagonist/gang/training/role)
	role.adopt_family(choice)

/datum/antag_training_program/antag/gang/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/gang/training/gangster = role(session)
	if(!gangster)
		to_chat(user, span_warning("Роль бандита снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Индукция учебной цели")
			induct_target(session, user, gangster)
		if("Новый баллон")
			session.issue_to_hands(/obj/item/toy/crayon/spraycan, user)
	return TRUE

/// Учебная цель принимает рукопожатие, которое участник ей протягивает: манекен сам не кликает по уведомлению.
/datum/antag_training_program/antag/gang/proc/induct_target(datum/antag_training_session/session, mob/living/carbon/human/user, datum/antagonist/gang/training/gangster)
	var/datum/status_effect/offering/secret_handshake/offer = user.has_status_effect(STATUS_EFFECT_HANDSHAKE)
	var/mob/living/carbon/human/drill_target = drill_recruit(session)
	if(drill_target)
		if(!offer || !(drill_target in offer.possible_takers))
			to_chat(user, span_warning("Идёт упражнение «Вербовка и метка»: подойдите вплотную к его цели, [drill_target.real_name], нажмите способность «Induct via Secret Handshake» рядом с ней и нажмите кнопку снова."))
			return FALSE
		return accept_handshake(session, user, gangster, offer, drill_target)
	if(!offer)
		for(var/mob/living/carbon/human/candidate in orange(1, user))
			if(practice_dummy(session, candidate) && !candidate.mind.has_antag_datum(/datum/antagonist/gang))
				to_chat(user, span_warning("Нажмите способность «Induct via Secret Handshake» рядом с учебной целью, затем нажмите кнопку снова."))
				return FALSE
		var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
		if(dummy)
			to_chat(user, span_notice("[dummy.real_name] ждёт в зоне «[dummy_zone_name(session, dummy)]»: встаньте к цели вплотную, нажмите способность «Induct via Secret Handshake» и нажмите кнопку снова."))
		return FALSE
	var/mob/living/carbon/human/recent = recent_target(session)
	var/mob/living/carbon/human/recruit
	for(var/mob/living/carbon/human/candidate in offer.possible_takers)
		if(!practice_dummy(session, candidate) || candidate.mind.has_antag_datum(/datum/antagonist/gang))
			continue
		recruit = candidate
		if(candidate == recent)
			break
	if(!recruit)
		to_chat(user, span_warning("Рядом нет вашей живой учебной цели вне семьи. Создайте человека в разделе «Цели» и встаньте вплотную к нему."))
		return FALSE
	return accept_handshake(session, user, gangster, offer, recruit)

/// Цель упражнения «Вербовка и метка», пока она не в семье: кнопка индукции работает только с ней.
/datum/antag_training_program/antag/gang/proc/drill_recruit(datum/antag_training_session/session)
	var/datum/antag_training_exercise_run/run = session.exercise_run
	if(!run || run.ended || !istype(run.exercise, /datum/antag_training_exercise/drill/gang_recruit))
		return null
	var/mob/living/carbon/human/target = run.find_prop(/mob/living/carbon/human)
	if(!target?.mind || target.mind.has_antag_datum(/datum/antagonist/gang))
		return null
	return target

/datum/antag_training_program/antag/gang/proc/accept_handshake(datum/antag_training_session/session, mob/living/carbon/human/user, datum/antagonist/gang/training/gangster, datum/status_effect/offering/secret_handshake/offer, mob/living/carbon/human/recruit)
	if(user.get_active_held_item() != offer.offered_item)
		to_chat(user, span_warning("Возьмите рукопожатие в активную руку: принять можно только его."))
		return FALSE
	var/atom/movable/screen/alert/give/secret_handshake/invitation = recruit.alerts["[user]"]
	if(!istype(invitation))
		to_chat(user, span_warning("[recruit.real_name] не видит рукопожатия. Протяните его снова."))
		return FALSE
	if(!(null in recruit.held_items))
		to_chat(user, span_warning("У [recruit.real_name] заняты обе руки: рукопожатие принимают свободной рукой."))
		return FALSE
	if(HAS_TRAIT(recruit, TRAIT_MINDSHIELD))
		to_chat(user, span_warning("У [recruit.real_name] имплант защиты разума: в семью такую цель не принять."))
		return FALSE
	invitation.handle_transfer()
	var/datum/antagonist/gang/training/recruited = recruit.mind.has_antag_datum(/datum/antagonist/gang/training)
	if(recruited?.my_gang != gangster.my_gang)
		to_chat(user, span_warning("[recruit.real_name] не принимает рукопожатие."))
		return FALSE
	target_created(session, recruit)
	to_chat(user, span_notice("[recruit.real_name] принимает рукопожатие и теперь в учебной семье «[gangster.gang_name]»."))
	return TRUE

/datum/antagonist/gang/proc/can_induct(mob/living/carbon/taker)
	return TRUE

/datum/antagonist/gang/training
	name = "Учебный бандит"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	gang_team_type = /datum/team/gang/training
	var/datum/antag_training_session/training
	var/family_type
	var/datum/weakref/phone_ref

/datum/antagonist/gang/training/proc/adopt_family(new_family_type)
	var/list/family = antag_training_gang_family(new_family_type)
	if(!family)
		return FALSE
	family_type = new_family_type
	gang_name = family["gang_name"]
	gang_id = family["gang_id"]
	antag_hud_name = family["hud"]
	var/list/worn = family["acceptable_clothes"]
	var/list/given = family["free_clothes"]
	acceptable_clothes = worn.Copy()
	free_clothes = given.Copy()
	return TRUE

/datum/antagonist/gang/training/create_team(datum/team/gang/training/team_given)
	if(istype(team_given))
		my_gang = team_given
		training = team_given.training
		adopt_family(team_given.family_type)
		return
	var/datum/team/gang/training/team = new gang_team_type
	team.training = training
	team.family_type = family_type
	team.name = gang_name
	team.gang_id = gang_id
	team.acceptable_clothes = acceptable_clothes.Copy()
	team.free_clothes = free_clothes.Copy()
	team.my_gang_datum = src
	var/list/family = antag_training_gang_family(family_type)
	var/theme_type = family?["theme"]
	if(theme_type)
		team.current_theme = new theme_type
	team.phone_line = "[gang_name], учебная линия [++team.lines_opened]"
	my_gang = team
	starter_gangster = TRUE

/datum/antagonist/gang/training/threat()
	return 0

/datum/antagonist/gang/training/can_induct(mob/living/carbon/taker)
	if(training?.can_manage_target(taker) && (taker.mind in training.arena.target_minds))
		return TRUE
	to_chat(owner.current, span_warning("На полигоне в учебную семью принимают только ваши учебные цели."))
	to_chat(taker, span_warning("Это учебное рукопожатие не для вас: в семью принимают только учебные цели."))
	return FALSE

/datum/antagonist/gang/training/greet()
	if(starter_gangster)
		antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/gang/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/gang/training/proc/briefing()
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/gang_recruit
	return jointext(list(
		span_boldnotice("Тренировка бандита: семья «[gang_name]»."),
		span_notice("Телефон семьи при вас: включите его в руке, и всё, что вы говорите, держа его при себе, услышат телефоны вашей учебной линии. Со станцией линия не связана."),
		span_notice("Способность «Induct via Secret Handshake» протягивает тайное рукопожатие тем, кто стоит вплотную. Кнопка «Индукция учебной цели» в «Моей роли» пульта заставляет вашу учебную цель его принять."),
		span_notice("Баллон из одежды семьи ставит метку семьи на стене или полу станционного макета. Новый баллон - кнопкой «Новый баллон»."),
		span_notice("Упражнение «[initial(exercise.name)]» в макете проводит через форму семьи, приём цели и метку с подсказками и оценкой: пульт, вкладка «Упражнения»."),
	), "<br>")

/datum/antagonist/gang/training/farewell()
	return

/datum/antagonist/gang/training/equip_gangster_in_inventory()
	var/mob/living/carbon/human/body = owner.current
	var/datum/team/gang/training/team = my_gang
	if(!istype(body) || !istype(team) || !training?.arena)
		return
	var/obj/item/gangster_cellphone/antag_training/phone = issue_gear(/obj/item/gangster_cellphone/antag_training)
	if(phone)
		phone.gang_id = team.phone_line
		phone.name = "[gang_name] training cell phone"
		phone_ref = WEAKREF(phone)
	for(var/clothing_type in team.free_clothes)
		issue_gear(clothing_type)

/datum/antagonist/gang/training/proc/issue_gear(item_type)
	var/mob/living/carbon/human/body = owner.current
	var/obj/item/gear = training.arena.issue_item(item_type, get_turf(body), 1, training)
	if(gear && !body.equip_to_appropriate_slot(gear) && !(body.back && SEND_SIGNAL(body.back, COMSIG_TRY_STORAGE_INSERT, gear, body, TRUE)))
		body.put_in_hands(gear)
	return gear

/datum/antagonist/gang/training/ui_static_data(mob/user)
	. = ..()
	var/datum/gang_theme/theme = my_gang?.current_theme
	.["gang_objective"] = theme?.gang_objectives[family_type]

/datum/antagonist/gang/training/on_removal()
	if(my_gang?.my_gang_datum == src)
		my_gang.my_gang_datum = null
	return ..()

/datum/antagonist/gang/training/Destroy()
	var/datum/team/gang/training/team = starter_gangster ? my_gang : null
	var/obj/item/stale_phone = phone_ref?.resolve()
	. = ..()
	my_gang = null
	training = null
	phone_ref = null
	qdel(stale_phone)
	qdel(team)

/// Учебная семья: вне списка команд раунда, без хендлера раунда, телефоны на своей линии.
/datum/team/gang/training
	name = "Training Family"
	show_roundend_report = FALSE
	var/datum/antag_training_session/training
	var/family_type
	var/phone_line
	var/static/lines_opened = 0

/datum/team/gang/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/gang/training/roundend_report()
	return

/datum/team/gang/training/Destroy(force, ...)
	for(var/obj/effect/decal/cleanable/crayon/gang/tag as anything in GLOB.gang_tags)
		if(tag.my_gang == src)
			qdel(tag)
	for(var/datum/mind/member as anything in members.Copy())
		var/datum/antagonist/gang/training/recruit = member.has_antag_datum(/datum/antagonist/gang/training)
		if(recruit?.my_gang == src)
			recruit.silent = TRUE
			member.remove_antag_datum(/datum/antagonist/gang/training)
	QDEL_NULL(current_theme)
	my_gang_datum = null
	training = null
	return ..()

/obj/item/gangster_cellphone/antag_training
	name = "training cell phone"
	desc = "Телефон учебной семьи. Включите его в руке, и всё, что вы говорите, держа его при себе, услышат телефоны той же учебной линии. Со станцией он не связан."
	item_state = "radio"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'

/obj/item/gangster_cellphone/antag_training/Initialize(mapload)
	. = ..()
	GLOB.gangster_cell_phones -= src
	GLOB.antag_training_gang_phones += src

/obj/item/gangster_cellphone/antag_training/Destroy()
	GLOB.antag_training_gang_phones -= src
	return ..()

/obj/item/gangster_cellphone/antag_training/broadcast_message(message, atom/movable/speaker)
	for(var/obj/item/gangster_cellphone/antag_training/brick as anything in GLOB.antag_training_gang_phones)
		if(brick.gang_id == gang_id)
			brick.say_message(message, speaker)

/datum/antag_training_exercise/drill/gang_recruit
	id = "gang_recruit"
	name = "Вербовка и метка"
	desc = "Учебная цель встаёт рядом с вами в станционном макете. Наденьте форму своей семьи, примите цель в семью тайным рукопожатием и поставьте метку семьи баллоном на стене или полу макета."
	sector = "station"
	program = /datum/antag_training_program/antag/gang
	difficulty = 1
	par_time = 90 SECONDS
	steps = list(/datum/antag_training_exercise_step/drill/checked/gang/dress, /datum/antag_training_exercise_step/drill/checked/gang/induct, /datum/antag_training_exercise_step/drill/checked/gang/tag)

/datum/antag_training_exercise/drill/gang_recruit/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	prepare_target(session, "human", get_turf(session.current_body))
	return TRUE

/// Цель упражнения - та, кого кнопка «Индукция учебной цели» выберет первой.
/datum/antag_training_exercise/drill/gang_recruit/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	var/datum/antag_training_program/antag/gang/program = run.session.program
	if(istype(program) && ishuman(target))
		program.target_created(run.session, target)

/// Форма, приём и метка сигналов не шлют: шаг проверяет их сам раз в секунду.
/datum/antag_training_exercise_step/drill/checked/gang
	target_death = "цель погибла раньше, чем вы приняли её в семью"

/datum/antag_training_exercise_step/drill/checked/gang/proc/gangster()
	var/datum/antag_training_program/antag/gang/program = run?.session?.program
	return istype(program) ? program.role(run.session) : null

/datum/antag_training_exercise_step/drill/checked/gang/dress
	name = "Наденьте форму своей семьи"
	hint = "Форма семьи выдана вместе с ролью и лежит в рюкзаке. Снимите свой комбинезон: пустой рукой щёлкните по слоту формы, карта и вещи из карманов упадут на пол. Достаньте форму семьи и наденьте её: возьмите в руку и нажмите E или щёлкните ею по слоту формы."

/datum/antag_training_exercise_step/drill/checked/gang/dress/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/datum/antagonist/gang/training/gangster = gangster()
	for(var/obj/item/clothing/under/uniform_type as anything in gangster?.free_clothes)
		if(ispath(uniform_type, /obj/item/clothing/under))
			hint = "Форма семьи «[gangster.gang_name]» - [initial(uniform_type.name)] - выдана вместе с ролью и лежит в рюкзаке. Снимите свой комбинезон: пустой рукой щёлкните по слоту формы, карта и вещи из карманов упадут на пол. Достаньте форму семьи и наденьте её: возьмите в руку и нажмите E или щёлкните ею по слоту формы."
			break

/datum/antag_training_exercise_step/drill/checked/gang/dress/check()
	var/mob/living/carbon/human/body = participant()
	var/datum/antagonist/gang/training/gangster = gangster()
	var/worn_type = istype(body) ? body.w_uniform?.type : null
	return gangster && worn_type && ((worn_type in gangster.free_clothes) || (worn_type in gangster.acceptable_clothes))

/datum/antag_training_exercise_step/drill/checked/gang/induct
	name = "Примите цель в семью рукопожатием"
	hint = "Встаньте к цели упражнения вплотную и нажмите способность «Induct via Secret Handshake»: рукопожатие окажется в активной руке. Не убирая его, нажмите «Индукция учебной цели» в «Моей роли» пульта - цель примет рукопожатие, как принял бы игрок, кликнув по уведомлению. Пока идёт упражнение, кнопка работает только с его целью."

/datum/antag_training_exercise_step/drill/checked/gang/induct/check()
	var/mob/living/target = exercise_target()
	var/datum/antagonist/gang/training/gangster = gangster()
	var/datum/antagonist/gang/training/recruit = target?.mind?.has_antag_datum(/datum/antagonist/gang/training)
	return gangster && recruit && recruit != gangster && recruit.my_gang == gangster.my_gang && target.stat != DEAD

/datum/antag_training_exercise_step/drill/checked/gang/tag
	name = "Поставьте метку семьи в макете"
	hint = "Возьмите баллон семьи из рюкзака или кнопкой «Новый баллон», снимите колпачок Alt+кликом и щёлкните баллоном по стене или полу макета рядом с собой. Метка ложится две секунды, не двигайтесь. Ваши прежние метки в макете убраны."
	target_death = null
	/// Слабые ссылки на метки других семей в макете: весь макет - одна территория, новую метку ставят поверх них.
	var/list/foreign_tags
	var/base_hint

/// Свои прежние метки убираются, над чужими встают маяки: иначе макет занят, и метку не поставить.
/datum/antag_training_exercise_step/drill/checked/gang/tag/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	if(!isnull(foreign_tags))
		return
	foreign_tags = list()
	base_hint = hint
	var/datum/antagonist/gang/training/gangster = gangster()
	for(var/obj/effect/decal/cleanable/crayon/gang/tag as anything in mockup_tags())
		if(tag.my_gang == gangster?.my_gang)
			qdel(tag)
			continue
		run.add_prop(new /obj/effect/antag_training_beacon/lit(get_turf(tag)), FALSE)
		foreign_tags += WEAKREF(tag)
	update_hint()

/datum/antag_training_exercise_step/drill/checked/gang/tag/proc/mockup_tags()
	. = list()
	var/datum/antag_training_arena/arena = run.session.arena
	var/list/bounds = arena.zones[run.exercise.sector]?["bounds"]
	if(!bounds)
		return
	for(var/obj/effect/decal/cleanable/crayon/gang/tag as anything in GLOB.gang_tags)
		if(tag.training_origin?.resolve() == arena && arena.inside_bounds(get_turf(tag), bounds))
			. += tag

/datum/antag_training_exercise_step/drill/checked/gang/tag/proc/update_hint()
	var/mob/living/body = participant()
	var/obj/effect/decal/cleanable/crayon/gang/nearest
	for(var/datum/weakref/tag_ref as anything in foreign_tags)
		var/obj/effect/decal/cleanable/crayon/gang/tag = tag_ref.resolve()
		if(body && tag && (!nearest || get_dist(body, tag) < get_dist(body, nearest)))
			nearest = tag
	if(!nearest)
		hint = base_hint
		return
	var/distance = get_dist(body, nearest)
	var/where = distance ? "в [distance] кл. от вас, направление - [dir2text_ru(get_dir(body, nearest))]" : "прямо под вами"
	hint = "[base_hint] В макете стоит метка другой семьи ([nearest.name]): весь макет - одна территория, поэтому новую метку можно поставить только поверх неё. Её отмечает зелёный маяк [where]. Встаньте рядом и распылите баллон прямо по ней."

/datum/antag_training_exercise_step/drill/checked/gang/tag/check()
	var/datum/antagonist/gang/training/gangster = gangster()
	if(!gangster)
		return FALSE
	for(var/obj/effect/decal/cleanable/crayon/gang/tag as anything in mockup_tags())
		if(tag.my_gang == gangster.my_gang)
			run.add_prop(tag, FALSE)
			return TRUE
	update_hint()
	return FALSE

/datum/antag_training_exercise_step/drill/checked/gang/tag/Destroy()
	foreign_tags = null
	return ..()
