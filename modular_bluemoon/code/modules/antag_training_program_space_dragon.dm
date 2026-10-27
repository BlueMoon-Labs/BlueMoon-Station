#define TRAINING_RIFT_CHARGE_FINALWARNING 1
#define TRAINING_RIFT_CHARGE_COMPLETED 2

/datum/antag_training_program/creature/space_dragon
	name = "Космический дракон"
	category = "Существа"
	desc = "Тело космического дракона в станционном макете: огненное дыхание, порыв крыльев, разрыв стен и три разлома карпов до учебной победы."
	icon = "dragon"
	color = "purple"
	learn = "Огненное дыхание|Порыв крыльев|Разрыв стен|Три разлома карпов"
	difficulty = 2
	sector = "station"
	mob_type = /mob/living/simple_animal/hostile/space_dragon/training
	antag_type = /datum/antagonist/space_dragon/training
	options = list("Отдых", "Зарядить разлом", "Цели")

/datum/antag_training_program/creature/space_dragon/New()
	. = ..()
	var/obj/structure/carp_rift/training/rift_type = /obj/structure/carp_rift/training
	var/mob/living/simple_animal/hostile/space_dragon/training/dragon_type = mob_type
	option_hints = list(
		"Отдых" = "Полное здоровье, сброс усталости от порывов крыльев и снятие замедления после уничтоженного разлома. Если разлом сейчас не заряжается, возвращает действие «Summon Rift». В раунде дракон лечится поеданием трупов, рядом со своим разломом и при его полном заряде, а уничтоженный разлом навсегда замедляет его, сильнее утомляет порывы и лишает новых разломов.",
		"Зарядить разлом" = "Заряжающийся разлом сразу получает полный заряд, а вы - действие для следующего. После [initial(dragon_type.rifts_to_win)] заряженных разломов пульт объявит учебную победу. До неё каждый заряженный разлом выпускает не больше [initial(rift_type.carp_limit)] ИИ-карпов. В раунде разлом заряжается [initial(rift_type.max_charge) / 60] мин, и его надо защищать: на половине и на полном заряде ЦК объявляет станции, где он, а призраки входят в него разумными карпами. На полигоне объявлений и призраков нет.",
		"Цели" = "Рядом с вами встанет учебный манекен: цель для огненного дыхания (клик по дальней цели), порыва крыльев (Alt+клик) и укуса. Мёртвого можно проглотить атакой - это лечит. Манекены и карпы из заряженных разломов входят в общий лимит целей полигона. В безопасном центре и переходах кнопка не работает.",
	)

/datum/antag_training_program/creature/space_dragon/refill(mob/living/simple_animal/hostile/space_dragon/training/body)
	body.revive(full_heal = TRUE, admin_revive = TRUE)
	body.tiredness = 0
	body.tiredness_mult = 1
	body.last_gust_use = 0
	if(body.using_special)
		body.reset_status()
	body.remove_movespeed_modifier(/datum/movespeed_modifier/dragon_depression)
	if(charging_rift(body))
		return
	body.riftTimer = 0
	if(!body.objective_complete && body.rifts_charged < body.rifts_to_win)
		body.grant_training_rift()

/datum/antag_training_program/creature/space_dragon/proc/charging_rift(mob/living/simple_animal/hostile/space_dragon/body)
	for(var/obj/structure/carp_rift/training/opened in body.rift_list)
		if(!QDELETED(opened) && opened.charge_state != TRAINING_RIFT_CHARGE_COMPLETED)
			return opened
	return null

/datum/antag_training_program/creature/space_dragon/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	var/mob/living/simple_animal/hostile/space_dragon/training/body = user
	if(!istype(body) || body != body_ref?.resolve())
		to_chat(user, span_warning("Вы не в теле дракона. Начните программу заново, чтобы вернуть его."))
		return FALSE
	switch(option)
		if("Отдых")
			refill(body)
			to_chat(body, span_notice((body.rift ? "Силы восстановлены, можно открывать разлом." : "Силы восстановлены. Новый разлом откроется, когда зарядится нынешний.")))
		if("Зарядить разлом")
			return charge_rift(body)
		if("Цели")
			return !!spawn_prey_near(session, body, "human", "Манекен встаёт рядом с вами, а в центре и переходах его нет: перейдите в станционный макет или на площадку.")
	return TRUE

/datum/antag_training_program/creature/space_dragon/proc/charge_rift(mob/living/simple_animal/hostile/space_dragon/training/body)
	var/obj/structure/carp_rift/training/charging = charging_rift(body)
	if(!charging)
		to_chat(body, span_warning("Сейчас ни один ваш разлом не заряжается. Откройте новый действием «Summon Rift»."))
		return FALSE
	charging.time_charged = charging.max_charge
	charging.update_check()
	return TRUE

/mob/living/simple_animal/hostile/space_dragon/training
	maxRiftTimer = INFINITY
	chosen_color = "#b48cff"
	butcher_results = null
	var/rifts_to_win = 3

/mob/living/simple_animal/hostile/space_dragon/training/Initialize(mapload)
	. = ..()
	QDEL_NULL(rift)
	grant_training_rift()
	add_atom_colour(chosen_color, FIXED_COLOUR_PRIORITY)
	add_dragon_overlay()

/mob/living/simple_animal/hostile/space_dragon/training/Destroy()
	for(var/obj/structure/carp_rift/opened as anything in rift_list)
		opened.dragon = null
		qdel(opened)
	rift_list.Cut()
	QDEL_NULL(rift)
	for(var/mob/living/eaten in src)
		eaten.forceMove(drop_location())
	return ..()

/mob/living/simple_animal/hostile/space_dragon/training/eat(atom/movable/A)
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	for(var/datum/antag_training_session/member as anything in arena?.members)
		if(member.current_body == A)
			to_chat(src, span_warning("Тело другого участника проглотить нельзя."))
			return FALSE
	return ..()

/// Разлом убран без поломки (уборка пульта, сброс сектора): без штрафа, учёт заряда и действие разлома возвращаются.
/mob/living/simple_animal/hostile/space_dragon/training/proc/rift_removed(obj/structure/carp_rift/training/removed)
	if(objective_complete)
		return
	if(removed.charge_state == TRAINING_RIFT_CHARGE_COMPLETED)
		rifts_charged = max(rifts_charged - 1, 0)
	for(var/obj/structure/carp_rift/training/opened in rift_list)
		if(opened.charge_state != TRAINING_RIFT_CHARGE_COMPLETED)
			return
	if(riftTimer == -1 && !has_movespeed_modifier(/datum/movespeed_modifier/dragon_depression))
		riftTimer = 0
	if(riftTimer != -1)
		grant_training_rift()

/mob/living/simple_animal/hostile/space_dragon/training/proc/grant_training_rift()
	if(!rift)
		rift = new /datum/action/innate/summon_rift/training
		rift.Grant(src)
	return rift

/mob/living/simple_animal/hostile/space_dragon/training/victory()
	if(objective_complete || rifts_charged < rifts_to_win)
		return
	objective_complete = TRUE
	permanant_empower()
	var/datum/antagonist/space_dragon/training/role = mind?.has_antag_datum(/datum/antagonist/space_dragon/training)
	for(var/datum/objective/antag_training/objective in role?.objectives)
		objective.completed = TRUE
	log_game("[key_name(src)] на тренировочном полигоне зарядил [rifts_to_win] учебных разлома.")
	role?.training?.practice_message("Учебная победа дракона: заряжены все [rifts_to_win] разлома. В раунде ЦК объявляет станции о стае карпов, рёв дракона слышат все, а разломы бесконечно выпускают карпов. Пройти заново - «Начать новым персонажем» в пульте.")

/datum/action/innate/summon_rift/training
	var/min_spacing = 10
	var/channel_time = 10 SECONDS

/datum/action/innate/summon_rift/training/Activate()
	var/mob/living/simple_animal/hostile/space_dragon/training/dragon = owner
	if(!istype(dragon) || dragon.using_special)
		return
	var/refusal = placement_refusal(dragon)
	if(refusal)
		to_chat(dragon, span_warning(refusal))
		return
	to_chat(dragon, span_notice("Вы открываете разлом..."))
	if(!do_after(dragon, channel_time, target = dragon) || QDELETED(src) || owner != dragon)
		return
	refusal = placement_refusal(dragon)
	if(refusal)
		to_chat(dragon, span_warning(refusal))
		return
	var/datum/antag_training_arena/arena = dragon.training_origin?.resolve()
	var/datum/antagonist/space_dragon/training/role = dragon.mind?.has_antag_datum(/datum/antagonist/space_dragon/training)
	var/obj/structure/carp_rift/training/opened = new(dragon.loc)
	if(!arena.claim_target(opened, role?.training))
		qdel(opened)
		return
	opened.dragon = dragon
	dragon.rift_list += opened
	dragon.riftTimer = -1
	playsound(dragon, 'sound/vehicles/rocketlaunch.ogg', 100, TRUE)
	to_chat(dragon, span_boldnotice("Разлом открыт и заряжается. Пока он не заряжен, нового не открыть; уничтоженный разлом лишит вас новых, пока не нажмёте «Отдых» в пульте."))
	log_game("[key_name(dragon)] на тренировочном полигоне открыл учебный разлом в [AREACOORD(opened)].")
	dragon.rift = null
	qdel(src)

/// Причина, по которой здесь нельзя открыть учебный разлом, иначе null.
/datum/action/innate/summon_rift/training/proc/placement_refusal(mob/living/simple_animal/hostile/space_dragon/training/dragon)
	if(dragon.riftTimer == -1)
		return "После уничтожения разлома новые не открываются. На полигоне это снимает кнопка «Отдых» в пульте."
	var/datum/antag_training_arena/arena = dragon.training_origin?.resolve()
	var/area/place = get_area(dragon)
	if(!isturf(dragon.loc) || !arena || arena.finished || !arena.owns_area(place) || !(place.area_flags & (VALID_TERRITORY | BLOBS_ALLOWED)))
		return "Разлом открывается только в станционном макете. В раунде - там, где мог бы вырасти блоб."
	for(var/obj/structure/carp_rift/other in arena.targets)
		var/distance = get_dist(other, dragon)
		if(distance < min_spacing)
			return "До другого разлома [max(distance, 0)] кл., а нужно не меньше [min_spacing]. В раунде правило другое: один разлом на отсек станции."
	if(!arena.has_target_room())
		return arena.target_limit_refusal()
	return null

/obj/structure/carp_rift/training
	desc = "Учебный разлом карпов. Призраки в него не входят, а заряд не слышит никто, кроме дракона."
	var/carp_limit = 2
	var/carp_spawned = 0
	var/destroyed_by_damage = FALSE

/obj/structure/carp_rift/training/obj_destruction(damage_flag)
	destroyed_by_damage = TRUE
	return ..()

/obj/structure/carp_rift/training/Destroy()
	var/mob/living/simple_animal/hostile/space_dragon/training/owner = dragon
	dragon = null
	if(istype(owner))
		owner.rift_list -= src
		var/datum/antag_training_arena/arena = training_origin?.resolve()
		if((destroyed_by_damage || obj_integrity <= 0) && arena && !arena.resetting && !arena.finished)
			owner.destroy_rifts()
			to_chat(owner, span_boldwarning("Разлом уничтожен: все ваши разломы исчезли, вы замедлены и не можете открыть новый. Кнопка «Отдых» в пульте вернёт силы и действие разлома."))
		else
			owner.rift_removed(src)
	return ..()

/obj/structure/carp_rift/training/attack_ghost(mob/user)
	return

/obj/structure/carp_rift/training/process(delta_time)
	if(charge_state != TRAINING_RIFT_CHARGE_COMPLETED)
		return ..()
	if(DT_PROB(1.25, delta_time))
		spawn_training_carp()
	if(DT_PROB(1.5, delta_time))
		var/direction = pick(GLOB.cardinals)
		var/turf/destination = get_step(src, direction)
		if(destination && get_area(destination) == get_area(src))
			Move(destination, direction)

/// ИИ-карп заряженного разлома, если в общем лимите целей полигона есть место.
/obj/structure/carp_rift/training/proc/spawn_training_carp()
	var/datum/antag_training_arena/arena = training_origin?.resolve()
	if(carp_spawned >= carp_limit || dragon?.objective_complete || !arena || arena.finished || !arena.has_target_room())
		return null
	var/mob/living/simple_animal/hostile/carp/carp = new(loc)
	if(!arena.claim_target(carp, training_owner?.resolve(), TRUE))
		qdel(carp)
		return null
	carp_spawned++
	return carp

/obj/structure/carp_rift/training/update_check()
	if(charge_state == TRAINING_RIFT_CHARGE_COMPLETED)
		return
	var/mob/living/simple_animal/hostile/space_dragon/training/owner = dragon
	if(time_charged >= max_charge)
		charge_state = TRAINING_RIFT_CHARGE_COMPLETED
		icon_state = "carp_rift_charged"
		light_color = LIGHT_COLOR_YELLOW
		update_light()
		armor = new_tg_get_armor_by_type(/datum/armor/secure_and_special_objects)
		resistance_flags = INDESTRUCTIBLE
		if(!istype(owner))
			return
		owner.rifts_charged++
		if(owner.rifts_charged >= owner.rifts_to_win)
			owner.victory()
			return
		owner.riftTimer = 0
		owner.grant_training_rift()
		owner.rift_empower()
		to_chat(owner, span_boldnotice("Разлом заряжен ([owner.rifts_charged] из [owner.rifts_to_win]): здоровье восполнено, на время вы быстрее. Откройте следующий разлом."))
		return
	if(charge_state < TRAINING_RIFT_CHARGE_FINALWARNING && time_charged >= max_charge / 2)
		charge_state = TRAINING_RIFT_CHARGE_FINALWARNING
		to_chat(owner, span_warning("Разлом заряжен наполовину. В раунде сейчас ЦК объявила бы станции, где он стоит."))

/datum/antagonist/space_dragon/training
	name = "Учебный космический дракон"
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
	ui_name = null
	var/datum/antag_training_session/training

/datum/antagonist/space_dragon/training/attach_training(datum/antag_training_session/session)
	training = session
	return TRUE

/datum/antagonist/space_dragon/training/threat()
	return 0

/datum/antagonist/space_dragon/training/forge_objectives()
	var/mob/living/simple_animal/hostile/space_dragon/training/dragon_type = /mob/living/simple_animal/hostile/space_dragon/training
	var/datum/objective/antag_training/rifts = new
	rifts.owner = owner
	rifts.explanation_text = "Откройте [initial(dragon_type.rifts_to_win)] разлома в станционном макете и доведите каждый до полного заряда."
	objectives += rifts

/datum/antagonist/space_dragon/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/space_dragon/training/proc/brief()
	var/datum/action/innate/summon_rift/training/action_type = /datum/action/innate/summon_rift/training
	var/mob/living/simple_animal/hostile/space_dragon/training/dragon_type = /mob/living/simple_animal/hostile/space_dragon/training
	to_chat(owner.current, jointext(list(
		span_boldnotice("Тренировка космического дракона."),
		span_notice("Клик по дальней цели - огненное дыхание, Alt+клик - порыв крыльев: отбрасывает всех рядом, но каждый раз утомляет сильнее. Атака по стене рвёт её за несколько секунд, по трупу - проглатывает его и лечит."),
		span_notice("Действие «Summon Rift» открывает разлом карпов в станционном макете: [initial(action_type.channel_time) / (1 SECONDS)] с без движения, не ближе [initial(action_type.min_spacing)] клеток к другому разлому. Пока разлом заряжается, нового не открыть; полный заряд лечит, ускоряет и возвращает действие. [initial(dragon_type.rifts_to_win)] заряженных разлома - учебная победа."),
		span_notice("В раунде время на первый разлом ограничено, в каждом отсеке станции - один разлом, а уничтоженный разлом навсегда лишает новых. «Пульт полигона», раздел «Моя роль»: отдых, мгновенный заряд и манекены. После смерти вы появитесь новым драконом в макете."),
	), "<br>"))

/datum/antagonist/space_dragon/training/Destroy()
	QDEL_LIST(objectives)
	training = null
	return ..()

#undef TRAINING_RIFT_CHARGE_FINALWARNING
#undef TRAINING_RIFT_CHARGE_COMPLETED
