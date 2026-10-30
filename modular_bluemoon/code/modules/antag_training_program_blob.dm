#define ANTAG_TRAINING_BLOBBERNAUT_COST 40

/datum/antag_training_program/creature/blob
	name = "Блоб"
	category = "Станционные угрозы"
	desc = "Разум блоба в станционном макете или на своей площадке хаба: установка ядра, рост, ресурсные блобы, узлы, фабрики со спорами, блобберноут и смена штамма. Учебная критическая масса - рост до порога клеток макета без угрозы станции."
	icon = "bacterium"
	color = "olive"
	learn = "Установка ядра и рост|Ресурсные блобы, узлы и фабрики|Споры и блобберноут|Смена штамма|Критическая масса в макете"
	difficulty = 2
	order = 7
	sector = "station"
	mob_type = /mob/camera/blob/training
	antag_type = /datum/antagonist/blob/training
	options = list("Ресурсы до максимума", "Сменить штамм", "Учебная победа: показать порог")

/datum/antag_training_program/creature/blob/New()
	. = ..()
	var/mob/camera/blob/station_blob = /mob/camera/blob
	option_hints = list(
		"Ресурсы до максимума" = "Ресурсы сразу до предела, [initial(station_blob.max_blob_points)]. В раунде их копят ядро и ресурсные блобы рядом с узлом или ядром.",
		"Сменить штамм" = "Бесплатно выбрать любой штамм из списка. В раунде смена платная, кроме одной бесплатной раз в [BLOB_REROLL_TIME / (1 MINUTES)] мин, и выбирать приходится из четырёх случайных. Зомбирующих стручков на полигоне нет: их споры обходят лимит целей и забирают тела участников.",
		"Учебная победа: показать порог" = "Сколько клеток макета уже занято и сколько нужно до учебной критической массы ([ANTAG_TRAINING_BLOB_TILES]). На пороге блоб перестаёт расти, тревоги и конца раунда нет. В раунде порог - [initial(station_blob.blobwincount)] клеток станции.",
	)

/datum/antag_training_program/creature/blob/spawn_creature_body(datum/antag_training_session/session, turf/where)
	. = ..()
	var/mob/camera/blob/training/overmind = .
	if(istype(overmind))
		overmind.training = session

/datum/antag_training_program/creature/blob/refill(mob/camera/blob/training/body)
	body.add_points(body.max_blob_points)

/// Восстановление не пересоздаёт разум: блоб, ресурсы и штамм остаются, ядро чинится до полной прочности.
/datum/antag_training_program/creature/blob/rebuild_body(datum/antag_training_session/session)
	var/mob/camera/blob/training/overmind = session.current_body
	if(!istype(overmind) || QDELETED(overmind) || overmind != body_ref?.resolve())
		return ..()
	var/obj/structure/blob/core/core = overmind.blob_core
	if(!core)
		if(!overmind.is_valid_turf(get_turf(overmind)))
			overmind.forceMove(creature_spawn_turf(session))
		to_chat(overmind, span_notice("Ядро ещё не поставлено, чинить нечего. Поставьте его на пол станционного макета или своей площадки хаба, а в сценарии - на место партии."))
		return TRUE
	core.obj_integrity = core.max_integrity
	core.update_icon()
	overmind.update_health_hud()
	to_chat(overmind, span_notice("Ядро восстановлено до [core.max_integrity] прочности. Блоб, ресурсы и штамм на месте."))
	return TRUE

/datum/antag_training_program/creature/blob/rebirth_message(datum/antag_training_session/session)
	var/datum/antag_training_sector/home = session.arena.sectors[sector]
	if(home?.bounds && session.arena.inside_bounds(get_turf(session.current_body), home.bounds))
		return "Прежний разум исчез вместе со своим блобом. Новый разум - в станционном макете: поставьте ядро заново."
	return "Прежний разум исчез вместе со своим блобом. Новый разум - в вестибюле хаба полигона: перейдите в станционный макет или на свою площадку хаба и поставьте ядро там."

/datum/antag_training_program/creature/blob/handle_choice(datum/antag_training_session/session, mob/user, option)
	if(..())
		return TRUE
	var/mob/camera/blob/training/overmind = user
	if(!istype(overmind) || overmind != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле блоба. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Ресурсы до максимума")
			refill(overmind)
			to_chat(overmind, span_notice("Ресурсы восполнены: [round(overmind.blob_points)]."))
		if("Сменить штамм")
			INVOKE_ASYNC(overmind, TYPE_PROC_REF(/mob/camera/blob/training, choose_strain))
		if("Учебная победа: показать порог")
			to_chat(overmind, span_notice(overmind.mass_report()))
	return TRUE

/// Штаммы учебного блоба: зомбирующие стручки выпускают споры мимо лимита целей и забирают тела участников.
/proc/antag_training_blob_strains()
	return GLOB.valid_blobstrains - typesof(/datum/blobstrain/reagent/zombifying_pods)

/proc/antag_training_blob_strain_name(datum/blobstrain/strain_type)
	. = initial(strain_type.name)
	if(. || !ispath(strain_type, /datum/blobstrain/reagent))
		return
	var/datum/blobstrain/reagent/reagent_strain = strain_type
	var/datum/reagent/strain_reagent = initial(reagent_strain.reagent)
	return initial(strain_reagent.name)

/// Блоб полигона растёт только по клеткам своего макета и только до учебной критической массы.
/proc/antag_training_blob_may_grow(mob/camera/blob/training/grower, turf/target)
	return istype(grower) && grower.is_valid_turf(target) && length(grower.blobs_legit) < grower.blobwincount

/datum/antagonist/blob/training
	name = "Учебный блоб"
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
	var/datum/antag_training_session/training

/datum/antagonist/blob/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/blob/training/threat()
	return 0

/datum/antagonist/blob/training/create_objectives()
	var/datum/objective/blob_takeover/goal = new
	goal.owner = owner
	goal.explanation_text = "Учебная критическая масса: [ANTAG_TRAINING_BLOB_TILES] клеток станционного макета."
	objectives += goal

/datum/antagonist/blob/training/apply_innate_effects(mob/living/mob_override)
	return

/datum/antagonist/blob/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/blob/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/blob/training/proc/briefing()
	return jointext(list(
		span_boldnotice("Тренировка блоба."),
		span_notice("Вы - разум блоба. Ядро ставит кнопка Place Blob Core в правом нижнем углу: только на пол станционного макета, если его не заняла чужая группа, или своей площадки хаба (в сценарии - только на месте партии) и когда рядом не стоят другие участники. Клик по клетке рядом с блобом - рост за [BLOB_SPREAD_COST] ресурса или удар по тому, кто там стоит."),
		span_notice("Ресурсы копят ядро и ресурсные блобы рядом с узлом или ядром. Фабрика выпускает споры, а за [ANTAG_TRAINING_BLOBBERNAUT_COST] ресурсов выращивает блобберноута. На полигоне блобберноут действует сам, призраков не зовут. Споры и блобберноуты входят в общий лимит целей полигона ([ANTAG_TRAINING_TARGET_LIMIT])."),
		span_notice("Учебная критическая масса - [ANTAG_TRAINING_BLOB_TILES] клеток макета: блоб дальше не растёт, станции ничего не грозит. Зомбирующих стручков на полигоне нет."),
		span_notice("«Пульт полигона», раздел «Моя роль»: ресурсы до максимума, любой штамм бесплатно и счёт до порога. «Восстановиться» чинит ядро. Если ядро разрушено, вы появитесь новым разумом в макете."),
	), "<br>")

/datum/antagonist/blob/training/Destroy()
	QDEL_LIST(objectives)
	training = null
	return ..()

/mob/camera/blob/training
	core_type = /obj/structure/blob/core/training
	blobwincount = ANTAG_TRAINING_BLOB_TILES
	var/datum/antag_training_session/training
	var/training_won = FALSE

/mob/camera/blob/training/Initialize(mapload, starting_points = 60)
	. = ..()
	manualplace_min_time = 0
	autoplace_max_time = INFINITY

/mob/camera/blob/training/validate_location()
	return

/// Пол станционного макета или площадки хаба своего полигона. Во время партии - только её место, без партии - своя площадка или макет, не занятый чужой группой.
/mob/camera/blob/training/is_valid_turf(turf/T)
	var/area/antag_training/place = get_area(T)
	if(!(istype(place, /area/antag_training/sector/station) || istype(place, /area/antag_training/hub/pad)) || !place.arena || place.arena != training_origin?.resolve() || isspaceturf(T))
		return FALSE
	if(!training)
		return TRUE
	var/datum/antag_training_scenario/current = training.scenario_in_play()
	if(current)
		return current.venue.contains(T)
	if(istype(place, /area/antag_training/hub/pad))
		return !!place.arena.hub?.pad_at(T)?.manages(training)
	var/datum/antag_training_sector/station = place.arena.sectors["station"]
	return !station?.entry_refusal(training)

/mob/camera/blob/training/process()
	if(QDELETED(src))
		return
	if(!blob_core)
		if(placed)
			qdel(src)
		return
	var/mass = length(blobs_legit)
	max_count = max(max_count, mass)
	if(mass >= blobwincount && !training_won)
		training_victory()
	if(!free_strain_rerolls && last_reroll_time + BLOB_REROLL_TIME < world.time)
		to_chat(src, span_notice("Снова доступна бесплатная смена штамма."))
		free_strain_rerolls = 1

/mob/camera/blob/training/proc/training_victory()
	training_won = TRUE
	victory_in_progress = TRUE
	var/datum/antagonist/blob/training/role = mind?.has_antag_datum(/datum/antagonist/blob/training)
	for(var/datum/objective/blob_takeover/goal in role?.objectives)
		goal.completed = TRUE
	log_game("[key_name(src)] на тренировочном полигоне доводит учебного блоба до критической массы: [length(blobs_legit)] клеток.")
	var/mob/camera/blob/station_blob = /mob/camera/blob
	to_chat(src, span_boldnotice("Учебная критическая масса: блоб занял [blobwincount] клеток макета и дальше не растёт. В раунде на пороге в [initial(station_blob.blobwincount)] клеток станция объявляет тревогу «Дельта», ресурсы становятся бесконечными, а вскоре блоб поглощает станцию и раунд заканчивается."))
	training?.play_training_sound(ANTAG_TRAINING_SOUND_SUCCESS)

/mob/camera/blob/training/proc/mass_report()
	var/mob/camera/blob/station_blob = /mob/camera/blob
	if(!placed)
		return "Ядро ещё не поставлено. Учебная критическая масса - [blobwincount] клеток макета, в раунде - [initial(station_blob.blobwincount)] клеток станции."
	return "Критическая масса: [length(blobs_legit)] из [blobwincount] клеток макета. На пороге блоб перестаёт расти. В раунде порог - [initial(station_blob.blobwincount)] клеток станции."

/mob/camera/blob/training/place_blob_core(placement_override, pop_override = FALSE)
	if(!placed && (placement_override == 1 || !is_valid_turf(get_turf(src))))
		to_chat(src, span_warning("Учебное ядро ставится только на пол станционного макета, если его не заняла чужая группа, или своей площадки хаба. Во время сценария - только на месте партии."))
		return FALSE
	. = ..()
	blobs_legit -= src

/mob/camera/blob/training/add_points(points)
	if(hud_used?.blobpwrdisplay)
		return ..()
	blob_points = clamp(blob_points + points, 0, max_blob_points)

/mob/camera/blob/training/update_health_hud()
	if(hud_used?.healths)
		return ..()

/mob/camera/blob/training/set_strain(datum/blobstrain/new_strain)
	if(ispath(new_strain, /datum/blobstrain/reagent/zombifying_pods))
		new_strain = pick(antag_training_blob_strains())
	return ..(new_strain)

/// Имя -> тип штамма для выбора: count случайных или все по алфавиту.
/mob/camera/blob/training/proc/strain_choices(count)
	var/list/pool = antag_training_blob_strains()
	. = list()
	while(length(pool) && (!count || length(.) < count))
		var/datum/blobstrain/strain = count ? pick_n_take(pool) : pool[1]
		pool -= strain
		.[antag_training_blob_strain_name(strain)] = strain
	if(!count)
		. = sort_list(.)

/mob/camera/blob/training/reroll_strain()
	if(!client)
		return
	var/list/choices = strain_choices(4)
	var/choice = tgui_input_list(src, "Выберите новый штамм.", "Штамм", choices)
	if(choice && choices[choice] && !QDELETED(src))
		set_strain(choices[choice])

/// Бесплатный выбор любого штамма из пульта полигона.
/mob/camera/blob/training/proc/choose_strain()
	if(rerolling)
		return
	if(!client)
		return
	rerolling = TRUE
	var/list/choices = strain_choices()
	var/choice = tgui_input_list(src, "Штамм задаёт урон, реакцию на атаки и особые свойства блоба.", "Смена штамма", choices)
	rerolling = FALSE
	if(!choice || !choices[choice] || QDELETED(src))
		return
	set_strain(choices[choice])
	log_game("[key_name(src)] на тренировочном полигоне выбирает штамм блоба «[choice]».")

/mob/camera/blob/training/createSpecial(price, blobstrain, nearEquals, needsNode, turf/T)
	if(blobstrain == /obj/structure/blob/factory)
		blobstrain = /obj/structure/blob/factory/training
	return ..(price, blobstrain, nearEquals, needsNode, T)

/mob/camera/blob/training/create_blobbernaut()
	var/obj/structure/blob/factory/factory = locate(/obj/structure/blob/factory) in get_turf(src)
	if(!factory)
		to_chat(src, span_warning("Встаньте на фабрику блоба."))
		return
	if(factory.naut)
		to_chat(src, span_warning("Эта фабрика уже держит блобберноута."))
		return
	if(factory.obj_integrity < factory.max_integrity * 0.5)
		to_chat(src, span_warning("Фабрика слишком повреждена, чтобы вырастить блобберноута."))
		return
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena?.has_target_room())
		to_chat(src, span_warning((arena ? arena.target_limit_refusal() : "Блобберноут растёт только на полигоне.")))
		return
	if(!can_buy(ANTAG_TRAINING_BLOBBERNAUT_COST))
		return
	var/mob/living/simple_animal/hostile/blob/blobbernaut/blobber = new(get_turf(factory))
	if(!arena.claim_target(blobber, training))
		qdel(blobber)
		add_points(ANTAG_TRAINING_BLOBBERNAUT_COST)
		return
	factory.max_integrity = initial(factory.max_integrity) * 0.25
	factory.obj_integrity = min(factory.obj_integrity, factory.max_integrity)
	factory.update_icon()
	factory.visible_message(span_warning("<b>Из фабрики блоба вырывается блобберноут!</b>"))
	playsound(factory.loc, 'sound/effects/splat.ogg', 50, TRUE)
	flick("blobbernaut_produce", blobber)
	factory.naut = blobber
	blobber.factory = factory
	blobber.overmind = src
	blobber.update_icons()
	blobber.adjustHealth(blobber.maxHealth * 0.5)
	blob_mobs += blobber
	RegisterSignal(blobber, COMSIG_PARENT_QDELETING, PROC_REF(blobbernaut_deleted))
	to_chat(src, span_notice("Блобберноут вырос и действует сам: на полигоне призраков не зовут. Вдали от блоба и без своей фабрики он медленно гибнет."))

/// Удалённый с пульта блобберноут отпускает фабрику так же, как погибший.
/mob/camera/blob/training/proc/blobbernaut_deleted(mob/living/simple_animal/hostile/blob/blobbernaut/source)
	SIGNAL_HANDLER
	var/obj/structure/blob/factory/factory = source.factory
	if(factory?.naut != source)
		return
	factory.naut = null
	factory.max_integrity = initial(factory.max_integrity)
	factory.update_icon()

/mob/camera/blob/training/get_status_tab_items()
	. = list()
	if(blob_core)
		. += "Прочность ядра: [round(blob_core.obj_integrity)]/[blob_core.max_integrity]"
	. += "Ресурсы: [round(blob_points)]/[max_blob_points]"
	. += "Критическая масса: [length(blobs_legit)]/[blobwincount]"
	if(free_strain_rerolls)
		. += "Бесплатных смен штамма: [free_strain_rerolls]"
	if(!placed)
		. += "Ядро можно поставить сразу: кнопка Place Blob Core в правом нижнем углу."

/mob/camera/blob/training/Destroy()
	training = null
	for(var/atom/movable/remains as anything in blobs_legit + blob_mobs)
		if(remains != src && !QDELETED(remains))
			qdel(remains)
	return ..()

/obj/structure/blob/core/training

/obj/structure/blob/core/training/generate_announcement()
	return

/obj/structure/blob/core/training/ComponentInitialize()
	return

/obj/structure/blob/factory/training

/obj/structure/blob/factory/training/Be_Pulsed()
	var/ready = !naut && length(spores) < max_spores && spore_delay <= world.time
	if(ready)
		spore_delay = world.time + spore_cooldown
	. = ..()
	if(ready)
		release_spore()

/// Спора фабрики учебного блоба встаёт в общий лимит целей полигона или не появляется.
/obj/structure/blob/factory/training/proc/release_spore()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(!arena?.has_target_room())
		return
	var/mob/camera/blob/training/owner = overmind
	flick("blob_factory_glow", src)
	var/mob/living/simple_animal/hostile/blob/blobspore/training/spore = new(loc, src)
	if(!arena.claim_target(spore, istype(owner) ? owner.training : null, TRUE))
		qdel(spore)
		return
	if(owner)
		spore.overmind = owner
		spore.update_icons()
		owner.blob_mobs += spore

/mob/living/simple_animal/hostile/blob/blobspore/training
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/blob/blobspore/training/Zombify(mob/living/carbon/human/H)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(arena?.session_of(H))
		return
	. = ..()
	if(oldguy == H)
		RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(corpse_deleted))
		RegisterSignal(H, COMSIG_LIVING_REVIVE, PROC_REF(corpse_revived))

/// Труп-цель, удалённый с пульта, уносит с собой и спору. Спора уходит после трупа: её Destroy удаляет содержимое.
/mob/living/simple_animal/hostile/blob/blobspore/training/proc/corpse_deleted(datum/source)
	SIGNAL_HANDLER
	oldguy = null
	QDEL_IN(src, 0)

/// Ожившая цель не остаётся внутри споры: спора распадается и выпускает её.
/mob/living/simple_animal/hostile/blob/blobspore/training/proc/corpse_revived(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_REVIVE))
	qdel(src)

#undef ANTAG_TRAINING_BLOBBERNAUT_COST
