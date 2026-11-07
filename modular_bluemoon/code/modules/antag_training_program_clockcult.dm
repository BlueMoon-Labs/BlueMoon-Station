/datum/antag_training_program/antag/clockcult
	name = "Слуга Ратвара"
	category = "Культы и магия"
	desc = "Учебный слейт без расхода общей энергии культа, сигил подчинения для учебных целей, сеть Иерофанта только внутри полигона и учебный Ковчег в станционном макете: пробуждение Ратвара за минуту, только как эффект."
	icon = "gears"
	color = "yellow"
	learn = "Учебный слейт|Сигил подчинения|Сеть Иерофанта|Ковчег и пробуждение Ратвара"
	difficulty = 3
	sector = "station"
	antag_type = /datum/antagonist/clockcult/training
	options = list("Латунь", "Цель для обращения", "Слуги для Ковчега")

/datum/antag_training_program/antag/clockcult/New()
	. = ..()
	var/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/ark = /datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar
	var/obj/effect/clockwork/sigil/submission/sigil = /obj/effect/clockwork/sigil/submission
	option_hints = list(
		"Латунь" = "Рядом появятся [ANTAG_TRAINING_BRASS_SHEETS] листов латуни, а потерянный слейт выдаётся заново. Из латуни слуга строит шестерни стен, двери, отражатели, ловушки и мебель Ратвара. В раунде латунь делает фабрикатор реплик из металла, расходуя общую энергию культа.",
		"Цель для обращения" = "Рядом встанет учебная цель, из безопасного центра - в лаборатории. Прочтите слейтом «Sigil of Submission» и перетащите цель на сигил: через [initial(sigil.convert_time) / (1 SECONDS)] с она станет учебным слугой, если рядом стоит слуга. В раунде сигил не обращает капитана, капеллана, носителей импланта защиты разума и культистов Нар'Си, а первое обращение открывает новые писания всему культу.",
		"Слуги для Ковчега" = "Вокруг вас встанут [initial(ark.invokers_required) - 1] учебных слуг, а если вы не в станционном макете - в его ритуальном зале. Вместе с вами их хватает, чтобы прочесть «Ark of the Clockwork Justiciar» в станционном макете. Коснитесь Ковчега, чтобы запустить его: учебный Ратвар пробудится через [ANTAG_TRAINING_ARK_DELAY / (1 SECONDS)] с. В раунде Ковчег стоит [DisplayPower(initial(ark.power_cost))] общей энергии, ставится только на станции, о нём узнаёт вся станция, а через [DisplayTimeText(GATEWAY_RATVAR_ARRIVAL SECONDS)] настоящий Ратвар заканчивает раунд.",
	)

/datum/antag_training_program/antag/clockcult/apply_choice(datum/antagonist/clockcult/training/role)
	role.leader = TRUE

/datum/antag_training_program/antag/clockcult/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/datum/antagonist/clockcult/training/servant = role(session)
	if(!servant)
		to_chat(user, span_warning("Роль слуги Ратвара снята. Начните новым персонажем, чтобы вернуть её."))
		return FALSE
	switch(option)
		if("Латунь")
			servant.resupply()
		if("Цель для обращения")
			place_convert(session, user)
		if("Слуги для Ковчега")
			place_invokers(session, user, servant.training_team)
	return TRUE

/datum/antag_training_program/antag/clockcult/proc/place_convert(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
	if(!dummy)
		return null
	to_chat(user, span_notice("[dummy.real_name] встал[dummy.ru_a()] в зоне «[dummy_zone_name(session, dummy)]». Прочтите сигил подчинения и перетащите [dummy.ru_ego()] на него."))
	return dummy

/datum/antag_training_program/antag/clockcult/proc/place_invokers(datum/antag_training_session/session, mob/living/user, datum/team/clockcult/training/team)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/station = arena.sectors["station"]
	if(station?.state != ANTAG_TRAINING_SECTOR_READY || QDELETED(team))
		to_chat(user, span_warning("Слуги встают в станционном макете. Дождитесь его загрузки или откройте сектор во вкладке «Зоны» и нажмите кнопку снова."))
		return 0
	if(world.time < arena.next_spawn_at)
		to_chat(user, span_warning("Подождите секунду перед следующей расстановкой."))
		return 0
	arena.next_spawn_at = world.time + 1 SECONDS
	var/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/ark = /datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar
	var/needed = initial(ark.invokers_required) - 1
	if(!arena.has_target_room(needed))
		to_chat(user, span_warning(arena.target_limit_refusal()))
		return 0
	var/turf/center = get_turf(user)
	if(arena.match_zone(user) != "station")
		center = station.landmark_turf("ritual")
	var/list/spots = list()
	for(var/turf/open/spot in orange(1, center))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE))
			spots += spot
	var/placed = 0
	for(var/index in 1 to needed)
		var/turf/near = center
		if(length(spots))
			near = spots[1]
			spots.Cut(1, 2)
		var/mob/living/carbon/human/invoker = arena.spawn_creature("human", "station", FALSE, session, near)
		if(!invoker)
			break
		if(near != center)
			invoker.forceMove(near)
		if(!team.add_servant(invoker.mind))
			QDEL_NULL(invoker.mind)
			qdel(invoker)
			break
		placed++
	if(placed < needed)
		to_chat(user, span_warning("Встало слуг: [placed] из [needed]. Освободите место в лимите целей и нажмите кнопку снова."))
	else
		to_chat(user, span_notice("Учебные слуги встали [center == get_turf(user) ? "вокруг вас" : "в ритуальном зале станционного макета"]. Встаньте так, чтобы все [needed] стояли вплотную к вам, и прочтите «Ark of the Clockwork Justiciar»."))
	return placed

/proc/antag_training_clock_team(mob/living/servant)
	var/datum/antagonist/clockcult/training/role = servant?.mind?.has_antag_datum(/datum/antagonist/clockcult/training)
	return role?.training_team

/datum/antagonist/clockcult/training
	name = "Учебный слуга Ратвара"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	ui_name = null
	ignore_eligibility_check = TRUE
	var/datum/antag_training_session/training
	var/datum/team/clockcult/training/training_team
	var/leader = FALSE
	var/owns_team = FALSE
	var/datum/weakref/slab_ref

/datum/antagonist/clockcult/training/create_team(datum/team/clockcult/new_team)
	if(istype(new_team, /datum/team/clockcult/training))
		training_team = new_team
		return
	training_team = new
	training_team.training = training
	owns_team = TRUE

/datum/antagonist/clockcult/training/get_team()
	return training_team

/datum/antagonist/clockcult/training/on_gain()
	. = ..()
	SSticker.mode.servants_of_ratvar -= owner
	if(leader)
		issue_slab()

/datum/antagonist/clockcult/training/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = istype(mob_override) ? mob_override : owner.current
	current.clear_alert("clockinfo")
	var/obj/structure/destructible/clockwork/massive/celestial_gateway/round_ark = GLOB.ark_of_the_clockwork_justiciar
	if(istype(round_ark) && round_ark.active && ishuman(current))
		current.cut_overlay(mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER))

/datum/antagonist/clockcult/training/threat()
	return 0

/datum/antagonist/clockcult/training/get_admin_commands()
	. = ..()
	. -= "Give slab"

/datum/antagonist/clockcult/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/clockcult/training/proc/brief()
	to_chat(owner.current, jointext(list(
		span_boldnotice("Тренировка слуги Ратвара."),
		span_notice("Учебный слейт в руках: писания на нём не тратят общую энергию культа и не открываются ступенями. Тут собраны сигилы, оглушение, оковы, защитные писания, снаряжение и учебный Ковчег; писания, которые качают энергию или зовут конструктов, на полигоне не читаются."),
		span_notice("Сеть Иерофанта слышат только слуги этого полигона. Общей энергии, жизненной силы и разблокировок писаний полигон не трогает."),
		span_notice("«Пульт полигона», раздел «Моя роль»: латунь, цель для обращения и слуги для Ковчега. Учебный Ковчег встаёт только в станционном макете, а учебный Ратвар - лишь образ для участников."),
	), "<br>"))

/datum/antagonist/clockcult/training/proc/issue_slab()
	var/mob/living/carbon/human/body = owner.current
	if(!istype(body) || !training?.arena)
		return null
	var/obj/item/clockwork/slab/training/slab = training.arena.issue_item(/obj/item/clockwork/slab/training, get_turf(body), 1, training)
	if(!slab)
		return null
	slab_ref = WEAKREF(slab)
	body.put_in_hands(slab)
	return slab

/datum/antagonist/clockcult/training/proc/resupply()
	var/mob/living/body = owner.current
	if(!body || !training?.arena)
		return FALSE
	if(world.time < training.next_supply_at)
		to_chat(body, span_warning("Подождите несколько секунд перед следующей выдачей."))
		return FALSE
	training.next_supply_at = world.time + 1 SECONDS
	var/obj/item/clockwork/slab/training/slab = slab_ref?.resolve()
	if(QDELETED(slab) || !body.contains_atom(slab))
		if(issue_slab())
			to_chat(body, span_notice("Прежнего слейта при вас нет - выдан новый."))
	var/obj/item/stack/tile/brass/brass = training.arena.issue_item(/obj/item/stack/tile/brass, get_turf(body), ANTAG_TRAINING_BRASS_SHEETS, training)
	if(!brass)
		to_chat(body, span_warning("Достигнут лимит выданных предметов. Уберите лишнее очисткой своих объектов в пульте."))
		return FALSE
	body.put_in_hands(brass)
	to_chat(body, span_notice("Выдано [ANTAG_TRAINING_BRASS_SHEETS] листов латуни. Используйте их в руке, чтобы строить."))
	return TRUE

/datum/antagonist/clockcult/training/Destroy()
	var/datum/team/clockcult/training/team = owns_team ? training_team : null
	. = ..()
	training_team = null
	training = null
	slab_ref = null
	qdel(team)

/// Учебная команда слуг: вне списка команд раунда, без подсчёта экипажа и объявлений.
/datum/team/clockcult/training
	name = "Training Clockcult"
	show_roundend_report = FALSE
	var/datum/antag_training_session/training
	var/obj/structure/destructible/antag_training_ark/ark
	var/ratvar_awakened = FALSE
	var/converts = 0

/datum/team/clockcult/training/New(starting_members)
	. = ..()
	GLOB.antagonist_teams -= src

/datum/team/clockcult/training/check_size()
	return

/datum/team/clockcult/training/check_clockwork_victory()
	return FALSE

/datum/team/clockcult/training/roundend_report()
	return

/datum/team/clockcult/training/proc/add_servant(datum/mind/convert)
	if(!convert || QDELETED(src))
		return null
	var/datum/antagonist/clockcult/training/servant = new
	servant.training = training
	servant.silent = TRUE
	if(!convert.add_antag_datum(servant, src))
		return null
	converts++
	return servant

/datum/team/clockcult/training/proc/notify(message)
	for(var/datum/mind/member as anything in members)
		if(member.current)
			to_chat(member.current, message)

/datum/team/clockcult/training/Destroy(force, ...)
	if(ark)
		ark.team = null
		QDEL_NULL(ark)
	for(var/datum/mind/member as anything in members.Copy())
		var/datum/antagonist/clockcult/training/servant = member.has_antag_datum(/datum/antagonist/clockcult/training)
		if(servant && !QDELETED(servant))
			servant.silent = TRUE
			member.remove_antag_datum(/datum/antagonist/clockcult/training)
	training = null
	return ..()

/// Учебный слейт: писания без расхода общей энергии и без ступеней, только из своего списка.
/obj/item/clockwork/slab/training
	name = "training clockwork slab"
	clockwork_desc = "Учебный слейт полигона. Писания на нём не тратят общую энергию культа, не открываются ступенями и не дают энергии сами."
	no_cost = TRUE
	quickbound = list(
		/datum/clockwork_scripture/create_object/sigil_of_submission/training,
		/datum/clockwork_scripture/ranged_ability/kindle,
		/datum/clockwork_scripture/ranged_ability/hateful_manacles)
	var/static/list/training_scriptures = list(
		/datum/clockwork_scripture/create_object/sigil_of_transgression,
		/datum/clockwork_scripture/create_object/sigil_of_submission/training,
		/datum/clockwork_scripture/ranged_ability/kindle,
		/datum/clockwork_scripture/ranged_ability/hateful_manacles,
		/datum/clockwork_scripture/channeled/belligerent,
		/datum/clockwork_scripture/vanguard,
		/datum/clockwork_scripture/ranged_ability/sentinels_compromise,
		/datum/clockwork_scripture/create_object/wraith_spectacles,
		/datum/clockwork_scripture/create_object/judicial_visor,
		/datum/clockwork_scripture/create_object/nezberes_shield,
		/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training,
	)

/obj/item/clockwork/slab/training/Initialize(mapload)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/clockwork/slab/training/process()
	return PROCESS_KILL

/obj/item/clockwork/slab/training/recite_scripture(datum/clockwork_scripture/scripture, mob/living/user)
	if(!(scripture in training_scriptures))
		if(ispath(scripture) && user?.canUseTopic(src))
			to_chat(user, span_warning("На полигоне недоступно: [initial(scripture.name)]. Это писание тратит или копит общую энергию культа, тянет других слуг станции или зовёт конструктов."))
		return FALSE
	return ..()

/obj/item/clockwork/slab/training/ui_data(mob/user)
	. = list()
	.["recollection"] = recollecting
	.["power"] = "Сколько угодно"
	.["power_unformatted"] = 0
	.["HONOR_RATVAR"] = FALSE
	.["scripture"] = list(
		SCRIPTURE_CATEGORY_STRUCTURE = list(),
		SCRIPTURE_CATEGORY_ATTACK = list(),
		SCRIPTURE_CATEGORY_SUPPORT = list(),
		SCRIPTURE_CATEGORY_EQUIPMENT = list(),
		SCRIPTURE_CATEGORY_MOBS = list(),
	)
	.["rec_binds"] = list()
	for(var/index in 1 to maximum_quickbound)
		var/datum/clockwork_scripture/bound = LAZYLEN(quickbound) >= index ? quickbound[index] : null
		if(!bound)
			.["rec_binds"] += list(list())
			continue
		.["rec_binds"] += list(list(
			"name" = initial(bound.name),
			"color" = get_component_color_bright(initial(bound.primary_component)),
		))
	for(var/path in training_scriptures)
		var/datum/clockwork_scripture/scripture = GLOB.all_scripture[path]
		if(!scripture)
			continue
		var/list/entry = list(
			"name" = scripture.name,
			"descname" = scripture.descname,
			"tip" = "[scripture.desc]\n[scripture.usage_tip]",
			"required" = "(без затрат на полигоне)",
			"required_unformatted" = 0,
			"type" = "[scripture.type]",
			"tier" = scripture.tier,
			"quickbind" = scripture.quickbind,
			"fontcolor" = get_component_color_bright(scripture.primary_component),
			"important" = scripture.important,
		)
		var/found = quickbound.Find(scripture.type)
		if(found)
			entry["bound"] = found
		if(scripture.invokers_required > 1)
			entry["invokers"] = "Призывающих: [scripture.invokers_required]"
		.["scripture"][scripture.category] += list(entry)

/obj/item/clockwork/slab/training/ui_static_data(mob/user)
	. = ..()
	var/list/tiers = .["tier_infos"]
	for(var/tier in tiers)
		tiers[tier] = list("requirement" = "На полигоне писания открыты без условий.", "ready" = TRUE)

/datum/clockwork_scripture/create_object/sigil_of_submission/training
	hidden_from_ui = TRUE
	object_path = /obj/effect/clockwork/sigil/submission/training
	usage_tip = "На полигоне сигил обращает только учебные цели и только в слуг вашей учебной команды."

/datum/clockwork_scripture/create_object/sigil_of_submission/training/can_recite()
	if(!istype(slab, /obj/item/clockwork/slab/training) || !antag_training_clock_team(invoker))
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/sigil_of_submission/training/scripture_effects()
	var/datum/team/clockcult/training/team = antag_training_clock_team(invoker)
	if(!team)
		return FALSE
	to_chat(invoker, creator_message)
	new object_path(get_turf(invoker), team)
	return TRUE

/// Учебный сигил подчинения: обращает учебную цель в слугу своей команды, без разблокировок писаний и оповещений раунда.
/obj/effect/clockwork/sigil/submission/training
	var/datum/weakref/team_ref

/obj/effect/clockwork/sigil/submission/training/Initialize(mapload, datum/team/clockcult/training/owner_team)
	team_ref = WEAKREF(owner_team)
	return ..()

/obj/effect/clockwork/sigil/submission/training/sigil_effects(mob/living/convert)
	var/datum/team/clockcult/training/team = team_ref?.resolve()
	var/datum/antag_training_arena/arena = team?.training?.arena
	if(!arena || !(convert.mind in arena.target_minds))
		visible_message(span_warning("[src] вспыхивает и гаснет: учебный сигил обращает только учебные цели полигона."))
		return
	var/servant_near = !!(locate(/obj/effect/clockwork/sigil/transgression) in loc)
	for(var/mob/living/servant in range(3, src))
		if(!servant.stat && antag_training_clock_team(servant) == team)
			servant_near = TRUE
			break
	if(!servant_near)
		visible_message(span_danger("[src] переходит в нежный фиолетовый оттенок, но постепенно блекнет..."))
		return
	convert.visible_message(span_warning("[src] начинает светиться ярким пурпурным светом!"), "<span class='sevtug'>Вы чувствуете, как что-то начинает проникать в ваш разум...</span>")
	var/old_color = color
	animate(src, color = "#AF0AAF", time = convert_time, flags = ANIMATION_END_NOW)
	var/obj/effect/temp_visual/ratvar/sigil/glow = new glow_type(get_turf(src))
	animate(glow, alpha = 255, time = convert_time)
	var/end_time = world.time + convert_time
	while(world.time < end_time && get_turf(convert) == get_turf(src))
		stoplag(1)
	animate(src, color = old_color, time = 2 SECONDS, flags = ANIMATION_END_NOW)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, update_atom_colour)), 2 SECONDS)
	if(get_turf(convert) != get_turf(src))
		qdel(glow)
		visible_message(span_warning("[src] постепенно перестает светиться!"))
		return
	team = team_ref?.resolve()
	if(!team || !(convert.mind in team.training?.arena?.target_minds) || is_servant_of_ratvar(convert) || !is_eligible_servant(convert) || !team.add_servant(convert.mind))
		convert.visible_message(span_boldwarning("[convert] словно сопротивляется незримой силе!"))
		return
	convert.log_message("conversion was done with a training [sigil_name]", LOG_ATTACK, color = "BE8700")
	if(iscarbon(convert))
		var/mob/living/carbon/carbon_convert = convert
		carbon_convert.uncuff()
	convert.adjustBruteLoss(-(convert.getBruteLoss() * 0.75))
	convert.adjustFireLoss(-(convert.getFireLoss() * 0.75))
	team.notify("<span class='heavy_brass'>[sigil_name] в [get_area(src)] обратил [convert.real_name] в учебного слугу.</span>")

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training
	descname = "Учебная победа"
	hidden_from_ui = TRUE
	object_path = /obj/structure/destructible/antag_training_ark
	creator_message = "<span class='heavy_brass'>Учебный Ковчег встаёт перед вами. Коснитесь его, чтобы запустить пробуждение.</span>"

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training/New()
	. = ..()
	desc = "Учебный Ковчег в станционном макете полигона. Через [ANTAG_TRAINING_ARK_DELAY / (1 SECONDS)] с после запуска пробуждает учебного Ратвара - только образ для участников полигона."
	usage_tip = "Читается в станционном макете, когда вплотную к вам стоят ещё [invokers_required - 1] слуг вашей команды. В раунде Ковчег стоит [DisplayPower(power_cost)] общей энергии и призывает Ратвара через [DisplayTimeText(GATEWAY_RATVAR_ARRIVAL SECONDS)]."

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training/can_recite()
	if(!istype(slab, /obj/item/clockwork/slab/training) || !antag_training_clock_team(invoker))
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training/check_special_requirements()
	var/datum/team/clockcult/training/team = antag_training_clock_team(invoker)
	var/datum/antag_training_arena/arena = team?.training?.arena
	if(!arena)
		return FALSE
	if(arena.match_zone(invoker) != "station")
		to_chat(invoker, span_warning("Учебный Ковчег встаёт только в станционном макете."))
		return FALSE
	if(!QDELETED(team.ark))
		to_chat(invoker, span_warning("Учебный Ковчег вашей команды уже стоит в [get_area_name(team.ark)]."))
		return FALSE
	var/servants = 0
	for(var/mob/living/servant in range(1, get_turf(invoker)))
		if(antag_training_clock_team(servant) == team && can_recite_scripture(servant))
			servants++
	if(servants < invokers_required)
		to_chat(invoker, span_warning("Вплотную к вам должно стоять больше слуг вашей команды в сознании ([servants]/[invokers_required]). Кнопка «Слуги для Ковчега» в пульте ставит недостающих."))
		return FALSE
	return ..()

/datum/clockwork_scripture/create_object/ark_of_the_clockwork_justiciar/training/scripture_effects()
	var/datum/team/clockcult/training/team = antag_training_clock_team(invoker)
	if(!team)
		return FALSE
	to_chat(invoker, creator_message)
	var/obj/structure/destructible/antag_training_ark/ark = new object_path(get_turf(invoker), team)
	return !QDELETED(ark)

/// Учебный Ковчег: не регистрируется как Ковчег раунда, не держит шаттл и не объявляет себя станции.
/obj/structure/destructible/antag_training_ark
	name = "training Ark of the Clockwork Justiciar"
	desc = "Массивное, неповоротливое собрание латунных частей вокруг мерцающей аномалии. Учебный макет: станция о нём не знает."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "clockwork_gateway_components"
	pixel_x = -32
	pixel_y = -32
	layer = BELOW_OPEN_DOOR_LAYER
	anchored = TRUE
	density = TRUE
	max_integrity = 500
	resistance_flags = FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	light_range = 2
	light_power = 4
	light_color = "#6A4D2F"
	break_message = "<span class='warning'>Учебный Ковчег рассыпается латунной пылью.</span>"
	break_sound = 'sound/magic/clockwork/anima_fragment_death.ogg'
	var/datum/team/clockcult/training/team
	var/active = FALSE
	var/awakened = FALSE
	var/awaken_delay = ANTAG_TRAINING_ARK_DELAY
	var/awaken_at = 0
	var/awaken_timer
	var/stage_timer

/obj/structure/destructible/antag_training_ark/Initialize(mapload, datum/team/clockcult/training/owner_team)
	. = ..()
	team = owner_team
	if(team)
		team.ark = src
	var/list/open_turfs = list()
	for(var/turf/open/spot in orange(1, loc))
		if(!spot.is_blocked_turf(TRUE))
			open_turfs += spot
	if(length(open_turfs))
		for(var/mob/living/standing in loc)
			standing.forceMove(pick(open_turfs))
	playsound(src, 'sound/magic/clockwork/invoke_general.ogg', 60, FALSE)

/obj/structure/destructible/antag_training_ark/examine(mob/user)
	. = ..()
	if(active)
		. += "<span class='brass'>До пробуждения учебного Ратвара: [DisplayTimeText(max(awaken_at - world.time, 0))].</span>"
	else
		. += "<span class='brass'>Ковчег не запущен: слуга его команды запускает его касанием.</span>"

/obj/structure/destructible/antag_training_ark/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(active || awakened || !team || team.training?.finished)
		return ..()
	if(antag_training_clock_team(user) != team || !user.canUseTopic(src, !issilicon(user), NO_DEXTERY))
		to_chat(user, span_warning("[src] не отзывается на ваше касание."))
		return TRUE
	activate(user)
	return TRUE

/obj/structure/destructible/antag_training_ark/proc/activate(mob/living/user)
	active = TRUE
	icon_state = "clockwork_gateway_charging"
	awaken_at = world.time + awaken_delay
	awaken_timer = addtimer(CALLBACK(src, PROC_REF(awaken)), awaken_delay, TIMER_STOPPABLE)
	stage_timer = addtimer(CALLBACK(src, PROC_REF(next_stage), "clockwork_gateway_active"), awaken_delay * 0.5, TIMER_STOPPABLE)
	playsound(src, 'sound/effects/clockcult_gateway_charging.ogg', 50, FALSE)
	log_game("[key_name(user)] на тренировочном полигоне запускает учебный Ковчег в [AREACOORD(src)].")
	team.notify("<span class='large_brass'>Учебный Ковчег запущен: Ратвар пробудится через [awaken_delay / (1 SECONDS)] с. Защищайте Ковчег.</span>")
	team.training?.practice_message("Учебный Ковчег запущен, пробуждение через [awaken_delay / (1 SECONDS)] с. В раунде Ковчег открывается [DisplayTimeText(GATEWAY_RATVAR_ARRIVAL SECONDS)], станции объявляют тревогу «Дельта», а всех слуг стягивает к нему.")

/obj/structure/destructible/antag_training_ark/proc/next_stage(state)
	if(QDELETED(src) || !active)
		return
	icon_state = state
	if(state == "clockwork_gateway_active")
		stage_timer = addtimer(CALLBACK(src, PROC_REF(next_stage), "clockwork_gateway_closing"), awaken_delay * 0.3, TIMER_STOPPABLE)
		playsound(src, 'sound/effects/clockcult_gateway_active.ogg', 50, FALSE)
	else
		playsound(src, 'sound/effects/clockcult_gateway_closing.ogg', 50, FALSE)

/obj/structure/destructible/antag_training_ark/proc/awaken()
	if(QDELETED(src) || !active || awakened || !team || team.training?.finished)
		return FALSE
	awakened = TRUE
	team.ratvar_awakened = TRUE
	new /obj/effect/temp_visual/antag_training_ratvar(get_turf(src))
	playsound(src, 'sound/effects/ratvar_reveal.ogg', 80, FALSE)
	log_game("[key_name(team.training?.current_body)] на тренировочном полигоне пробуждает учебного Ратвара в [AREACOORD(src)].")
	team.notify("<span class='large_brass'>Учебный Ратвар пробуждён!</span>")
	team.training?.practice_message("Учебный Ратвар пробуждён. В раунде пробуждённый Ратвар обращает всё вокруг себя, об этом узнаёт вся станция, и раунд заканчивается.")
	qdel(src)
	return TRUE

/obj/structure/destructible/antag_training_ark/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && !QDELETED(src))
		flick("clockwork_gateway_damaged", src)
		playsound(src, 'sound/machines/clockcult/ark_damage.ogg', 75, FALSE)

/obj/structure/destructible/antag_training_ark/Destroy()
	deltimer(awaken_timer)
	deltimer(stage_timer)
	if(team)
		if(active && !awakened)
			team.notify("<span class='large_brass'>Учебный Ковчег разрушен до пробуждения Ратвара.</span>")
			team.training?.practice_message("Учебный Ковчег разрушен до пробуждения. В раунде это поражение культа: Ратвар остаётся в изгнании.")
		if(team.ark == src)
			team.ark = null
		team = null
	return ..()

/obj/effect/temp_visual/antag_training_ratvar
	name = "Ratvar, the Clockwork Justiciar"
	desc = "Образ пробуждённого Ратвара. Учебный: он ничего не трогает и скоро растает."
	icon = 'icons/effects/512x512.dmi'
	icon_state = "ratvar"
	pixel_x = -235
	pixel_y = -248
	layer = MASSIVE_OBJ_LAYER
	light_range = 6
	light_power = 0.7
	light_color = "#BE8700"
	duration = 10 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/antag_training_ratvar/Initialize(mapload)
	. = ..()
	alpha = 0
	animate(src, alpha = 255, time = 2 SECONDS)
	animate(time = 6 SECONDS)
	animate(alpha = 0, time = 2 SECONDS)
