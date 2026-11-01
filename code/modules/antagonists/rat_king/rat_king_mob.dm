/mob/living/simple_animal/hostile/regalrat
	name = "Король крыс"
	desc = "Эволюционировавшая крыса, созданная блюспейс разломом. Она ведёт окрестных крыс с убийственной эффективностью, защищая своё королевство. Формально не король."
	icon_state = "regalrat"
	icon_living = "regalrat"
	icon_dead = "regalrat_dead"
	gender = NEUTER
	speak_chance = 0
	turns_per_move = 5
	maxHealth = 70
	health = 70
	see_in_dark = 5
	obj_damage = 10
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES | ENVIRONMENT_SMASH_WALLS
	butcher_results = list(/obj/item/clothing/head/crown = 1,)
	response_help_continuous = "смотрит на"
	response_help_simple = "посмотреть на"
	response_disarm_continuous = "фыркает на"
	response_disarm_simple = "фыркнуть на"
	response_harm_continuous = "полосует"
	response_harm_simple = "полоснуть"
	melee_damage_lower = 10
	melee_damage_upper = 12
	attack_verb_continuous = "полосует"
	attack_verb_simple = "полоснуть"
	attack_sound = 'sound/weapons/punch1.ogg'
	unique_name = TRUE
	faction = list("rat")
	uses_custom_environment_handling = TRUE
	var/datum/action/cooldown/coffer
	var/datum/action/cooldown/riot
	var/poll_ghosts = FALSE
	///Титул, выданный при вселении игрока.
	var/special_moniker = ""
	///Текущая орда.
	var/datum/rat_horde/horde
	var/soft_horde = FALSE
	var/datum/action/cooldown/rat_domain/domain
	var/datum/action/cooldown/rat_order/order_action
	var/datum/action/cooldown/rat_lick/lick_action
	/// Текущий королевский облик.
	var/datum/rat_fashion/current_look
	/// Экшен смены облика.
	var/datum/action/cooldown/rat_fashion/fashion_select

/mob/living/simple_animal/hostile/regalrat/Initialize(mapload)
	. = ..()
	if(!soft_horde)
		coffer = new /datum/action/cooldown/coffer
		coffer.Grant(src)
		riot = new /datum/action/cooldown/riot
		riot.Grant(src)
		domain = new /datum/action/cooldown/rat_domain
		domain.Grant(src)
		lick_action = new /datum/action/cooldown/rat_lick
		lick_action.Grant(src)
		fashion_select = new /datum/action/cooldown/rat_fashion
		fashion_select.Grant(src)
		pick_random_look()
	order_action = new /datum/action/cooldown/rat_order
	order_action.Grant(src)
	if(soft_horde)
		var/datum/action/cooldown/rat_order/call_mice/call_action = new
		call_action.Grant(src)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	AddComponent(/datum/component/waddling)
	RegisterSignal(src, COMSIG_MOB_LOGIN, PROC_REF(on_login))
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(rat_friend_attack_hand))
	RegisterSignal(src, COMSIG_PARENT_ATTACKBY, PROC_REF(rat_friend_attackby))
	if(poll_ghosts)
		INVOKE_ASYNC(src, PROC_REF(poll_for_player))

/mob/living/simple_animal/hostile/regalrat/proc/poll_for_player()
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Хотите сыграть за крысиного короля, да будет сырен его венец?", ROLE_RAT_KING, null, ROLE_RAT_KING, 30 SECONDS)
	if(LAZYLEN(candidates) && !mind)
		var/mob/dead/observer/chosen = pick(candidates)
		key = chosen.key
		notify_ghosts("Восстаньте: [name] взошёл на трон в \the [get_area(src)].", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE)

/mob/living/simple_animal/hostile/regalrat/Login()
	. = ..()
	if(mind && !mind.has_antag_datum(/datum/antagonist/rat_king))
		mind.add_antag_datum(soft_horde ? /datum/antagonist/rat_king/lust : /datum/antagonist/rat_king)
	if(!special_moniker)
		grant_titles()

/mob/living/simple_animal/hostile/regalrat/sentience_act()
	. = ..()
	if(mind && !mind.has_antag_datum(/datum/antagonist/rat_king))
		mind.add_antag_datum(soft_horde ? /datum/antagonist/rat_king/lust : /datum/antagonist/rat_king)
	if(!special_moniker)
		grant_titles()

/mob/living/simple_animal/hostile/regalrat/proc/on_login()
	SIGNAL_HANDLER
	if(!special_moniker)
		grant_titles()

/mob/living/simple_animal/hostile/regalrat/proc/grant_titles()
	var/static/list/titles = list("Боярин", "Император", "Король", "Господин", "Владыка", "Повелитель", "Принц", "Сёгун", "Царь")
	var/static/list/kingdoms = list("Сыра", "Мусора", "Техтоннелей", "Миазмов", "Чумы", "Отбросов", "Грызунов")
	var/static/list/descriptors = list("Большой Сыр", "Громила", "Чемпион Всех Потерянных Созданий", "Мерзкий", "Великий", "Серый", "Ужасный", "Размножитель", "Могучий", "Тихий", "Тщеславный")
	var/selected_title = pick(titles)
	var/selected_kingdom = pick(kingdoms)
	name = "[selected_title] [selected_kingdom], [pick(descriptors)]"
	special_moniker = "Лучше не связываться с [p_their()] [selected_kingdom]... Как вообще становятся [selected_title] этого?"

/mob/living/simple_animal/hostile/regalrat/proc/pick_random_look()
	var/list/valid_styles = list()
	for(var/style_path in subtypesof(/datum/rat_fashion))
		var/datum/rat_fashion/style = new style_path()
		if(!style.allow_random)
			qdel(style)
			continue
		valid_styles += style
	if(!length(valid_styles))
		return
	var/datum/rat_fashion/chosen = pick(valid_styles)
	valid_styles -= chosen
	for(var/datum/rat_fashion/style as anything in valid_styles)
		qdel(style)
	current_look = chosen
	current_look.apply(src)

/mob/living/simple_animal/hostile/regalrat/Destroy()
	QDEL_NULL(fashion_select)
	QDEL_NULL(current_look)
	return ..()

/mob/living/simple_animal/hostile/regalrat/proc/get_rat_horde()
	if(!horde || QDELETED(horde))
		horde = new(src, soft_horde ? RAT_HORDE_SOFT : RAT_HORDE_HARD)
	return horde

/mob/living/simple_animal/hostile/regalrat/proc/allowed_to_attack(atom/the_target)
	if(QDELETED(the_target))
		return FALSE
	if(!isliving(the_target))
		return TRUE
	var/mob/living/living_target = the_target
	if(living_target.stat == DEAD)
		balloon_alert(src, "уже мёртв!")
		return FALSE
	if(istype(living_target, /mob/living/simple_animal/hostile/regalrat))
		return TRUE
	if(istype(living_target, /mob/living/simple_animal/hostile/rat) || istype(living_target, /mob/living/simple_animal/hostile/plaguerat))
		if(faction_check_mob(living_target, TRUE))
			balloon_alert(src, "это свой!")
			return FALSE
		return TRUE
	if(faction_check_mob(living_target))
		balloon_alert(src, "это свой!")
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/regalrat/AttackingTarget()
	if(!target || QDELETED(target))
		return
	if(!allowed_to_attack(target))
		return FALSE
	if(istype(target, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/airlock_target = target
		var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(/datum/obstacle_policy/forceful)
		if(policy && policy.try_airlock(src, airlock_target))
			return FALSE
	if(!isliving(target) && (istype(target, /obj/item/reagent_containers/food) || istype(target, /obj/item/reagent_containers)))
		if(poison_target(target))
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/regalrat/proc/poison_target(atom/target)
	if(!target || QDELETED(target) || isnull(target.reagents))
		return FALSE
	if(!target.is_injectable(TRUE) && !istype(target, /obj/item/reagent_containers/food) && !istype(target, /obj/item/reagent_containers) && !isliving(target))
		return FALSE
	visible_message(
		span_warning("[src] начинает страстно облизывать [target]!"),
		span_notice("Вы начинаете облизывать [target]..."),
		span_warning("Вы слышите отвратительное чавканье..."),
	)
	if(!do_after(src, 2 SECONDS, target))
		return TRUE
	if(QDELETED(target) || isnull(target.reagents))
		return TRUE
	target.reagents.add_reagent(/datum/reagent/rat_spit, rand(1, 3), no_react = TRUE)
	balloon_alert(src, "облизано")
	return TRUE

/mob/living/simple_animal/hostile/regalrat/death(gibbed)
	if(domain)
		domain.set_active(FALSE)
	if(horde)
		QDEL_NULL(horde)
	return ..()

/mob/living/simple_animal/hostile/regalrat/handle_environment(datum/gas_mixture/environment)
	. = ..()
	if(stat == DEAD || isnull(environment))
		return
	var/miasma = environment.get_moles(GAS_MIASMA)
	if(!miasma)
		return
	var/total = environment.total_moles()
	if(total <= 0)
		return
	if((miasma / total) >= 0.25)
		heal_bodypart_damage(1)

/mob/living/simple_animal/hostile/regalrat/CanAttack(atom/the_target)
	if(istype(the_target,/mob/living/simple_animal))
		var/mob/living/A = the_target
		if(istype(the_target, /mob/living/simple_animal/hostile/regalrat) && A.stat == CONSCIOUS)
			return TRUE
		if(istype(the_target, /mob/living/simple_animal/hostile/rat) && A.stat == CONSCIOUS)
			var/mob/living/simple_animal/hostile/rat/R = the_target
			if(R.faction_check_mob(src, TRUE))
				return FALSE
			else
				return TRUE
		if(istype(the_target, /mob/living/simple_animal/hostile/plaguerat) && A.stat == CONSCIOUS)
			var/mob/living/simple_animal/hostile/plaguerat/R = the_target
			if(R.faction_check_mob(src, TRUE))
				return FALSE
			else
				return TRUE
	if(isliving(the_target) && faction_check_mob(the_target))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/regalrat/examine(mob/user)
	. = ..()
	if(istype(user,/mob/living/simple_animal/hostile/rat))
		var/mob/living/simple_animal/hostile/rat/ratself = user
		if(ratself.faction_check_mob(src, TRUE))
			. += "<span class='notice'>Это ваш король. Да здравствует его величество!</span>"
		else
			. += "<span class='warning'>Это ложный король! Свергните его!</span>"
	else if(istype(user,/mob/living/simple_animal/hostile/regalrat))
		. += "<span class='warning'>Что за жалкий самозванец? Этого не потерпят!</span>"
	if(special_moniker)
		. += special_moniker
	if(isliving(user))
		var/mob/living/living_user = user
		if(living_user.has_status_effect(/datum/status_effect/rat_friend))
			. += span_notice("Эта крыса считает вас своим.")

/mob/living/simple_animal/hostile/regalrat/controlled
	poll_ghosts = TRUE

/datum/action/cooldown/coffer
	name = "Наполнить казну"
	desc = "Королевская стать позволяет находить потерянный хлам, а главное — сыр."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	background_icon_state = "bg_clock"
	button_icon_state = "coffer"
	cooldown_time = 50
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/coffer/Activate()
	var/turf/T = get_turf(owner)
	var/loot = rand(1,100)
	switch(loot)
		if(1 to 5)
			to_chat(owner, "<span class='notice'>Удача! Вы находите сыр!</span>")
			new /obj/item/reagent_containers/food/snacks/cheesewedge(T)
		if(6 to 10)
			var/pickedcoin = pick(GLOB.ratking_coins)
			to_chat(owner, "<span class='notice'>Вы находите забытые монеты. В королевскую казну!</span>")
			for(var/i = 1 to rand(1,3))
				new pickedcoin(T)
		if(11)
			to_chat(owner, "<span class='notice'>Вы находите... Хм. Эта монета выглядит странно.</span>")
			var/rarecoin = rand(1,2)
			if (rarecoin == 1)
				new /obj/item/coin/twoheaded(T)
			else
				new /obj/item/coin/antagtoken(T)
		if(12 to 40)
			var/pickedtrash = pick(GLOB.ratking_trash)
			to_chat(owner, "<span class='notice'>Вы находите лишь мусор и грязь. Мило, но теперь это ниже вашего достоинства.</span>")
			new /obj/effect/decal/cleanable/dirt(T)
			new pickedtrash(T)
		if(41 to 100)
			to_chat(owner, "<span class='notice'>Пусто. Ничего.</span>")
			new /obj/effect/decal/cleanable/dirt(T)
	StartCooldown()

/datum/action/cooldown/riot
	name = "Мобилизировать крысят"
	desc = "Соберите армию из мышей и вредителей, кишащих в техтоннелях."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "riot"
	background_icon_state = "bg_clock"
	cooldown_time = 80
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/riot/Activate()
	var/mob/living/simple_animal/hostile/regalrat/king = owner
	if(!istype(king))
		return
	var/datum/rat_horde/horde = king.get_rat_horde()
	var/converted = 0
	var/cap = CONFIG_GET(number/ratcap)
	playsound(king, 'sound/effects/mousesqueek.ogg', 100, TRUE)
	for(var/mob/living/simple_animal/mouse/M in oview(king, RAT_KING_RIOT_RANGE))
		if(length(horde.minions) >= horde.max_minions)
			break
		var/new_name = (M.name == "mouse") ? null : M.name
		var/mob/living/simple_animal/hostile/rat/new_rat = M.change_mob_type(/mob/living/simple_animal/hostile/rat, get_turf(M), new_name, TRUE)
		if(!new_rat)
			new_rat = new /mob/living/simple_animal/hostile/rat(get_turf(M))
			qdel(M)
		if(!new_rat)
			continue
		new_rat.faction = king.faction.Copy()
		if(horde.register_minion(new_rat))
			converted++
	for(var/mob/living/simple_animal/hostile/plaguerat/plague in oview(king, RAT_KING_RIOT_RANGE))
		if(length(horde.minions) >= horde.max_minions)
			break
		plague.faction = king.faction.Copy()
		if(horde.register_minion(plague))
			converted++
	if(converted < 3)
		var/turf/spawn_turf = get_turf(king)
		var/cap_left = cap - LAZYLEN(SSmobs.cheeserats)
		var/horde_left = horde.max_minions - length(horde.minions)
		var/to_spawn = min(3 - converted, cap_left, horde_left)
		if(!spawn_turf || to_spawn <= 0)
			if(!converted)
				to_chat(king, span_warning("На станции и так слишком много грызунов. Найдите их сами!"))
				return
		else
			for(var/i in 1 to to_spawn)
				var/mob/living/simple_animal/mouse/new_mouse = new(spawn_turf)
				var/mob/living/simple_animal/hostile/rat/new_rat = new_mouse.change_mob_type(/mob/living/simple_animal/hostile/rat, spawn_turf, null, TRUE)
				if(!new_rat)
					new_rat = new /mob/living/simple_animal/hostile/rat(spawn_turf)
					qdel(new_mouse)
				if(!new_rat)
					continue
				new_rat.faction = king.faction.Copy()
				if(horde.register_minion(new_rat))
					converted++
	if(converted)
		king.visible_message(span_warning("[king] поднимает армию! [converted] грызунов встают под его знамёна."))
		horde.issue_order(RAT_ORDER_FOLLOW, null, get_turf(king))
	else
		new /mob/living/simple_animal/mouse(get_turf(king))
		king.visible_message(span_warning("[king] зовёт мышь к себе!"))
	StartCooldown()

/mob/living/simple_animal/hostile/rat
	name = "Крыса"
	desc = "Мерзкий, уродливый, злой, заразный грызун с проблемами с гневом."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	speak = list("Скрии!","СКРИИИ!","Писк?")
	speak_emote = list("пищит")
	emote_hear = list("шипит.")
	emote_see = list("бегает по кругу.", "встаёт на задние лапы.")
	melee_damage_lower = 3
	melee_damage_upper = 5
	obj_damage = 5
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	maxHealth = 15
	health = 15
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	density = FALSE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	faction = list("rat")
	can_buckle = TRUE
	max_buckled_mobs = 1
	tame = TRUE

/mob/living/simple_animal/hostile/rat/Initialize(mapload)
	. = ..()
	SSmobs.cheeserats += src
	AddComponent(/datum/component/swarming)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(rat_friend_attack_hand))
	RegisterSignal(src, COMSIG_PARENT_ATTACKBY, PROC_REF(rat_friend_attackby))

/mob/living/simple_animal/hostile/rat/Destroy()
	SSmobs.cheeserats -= src
	return ..()

/mob/living/simple_animal/hostile/rat/examine(mob/user)
	. = ..()
	if(istype(user,/mob/living/simple_animal/hostile/rat))
		var/mob/living/simple_animal/hostile/rat/ratself = user
		if(ratself.faction_check_mob(src, TRUE))
			. += "<span class='notice'>Вы оба служите одному королю.</span>"
		else
			. += "<span class='warning'>Этот глупец служит другому королю!</span>"
	else if(istype(user,/mob/living/simple_animal/hostile/regalrat))
		var/mob/living/simple_animal/hostile/regalrat/ratking = user
		if(ratking.faction_check_mob(src, TRUE))
			. += "<span class='notice'>Эта крыса служит вам.</span>"
		else
			. += "<span class='warning'>Этот крестьянин служит другому королю! Свергните его!</span>"
	. += span_notice("Можно оседлать.")

/mob/living/simple_animal/hostile/rat/CanAttack(atom/the_target)
	if(istype(the_target,/mob/living/simple_animal))
		var/mob/living/A = the_target
		if(istype(the_target, /mob/living/simple_animal/hostile/regalrat) && A.stat == CONSCIOUS)
			var/mob/living/simple_animal/hostile/regalrat/ratking = the_target
			if(ratking.faction_check_mob(src, TRUE))
				return FALSE
			else
				return TRUE
		if(istype(the_target, /mob/living/simple_animal/hostile/rat) && A.stat == CONSCIOUS)
			var/mob/living/simple_animal/hostile/rat/R = the_target
			if(R.faction_check_mob(src, TRUE))
				return FALSE
			else
				return TRUE
	if(isliving(the_target) && faction_check_mob(the_target))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rat/proc/try_chew_cables(shock_roll = null)
	var/turf/open/floor/floor = get_turf(src)
	if(!istype(floor) || (floor.turf_flags & TURF_INTACT))
		return FALSE
	var/obj/structure/cable/wire = locate() in floor
	if(!wire || !wire.avail())
		return FALSE
	if(isnull(shock_roll))
		shock_roll = prob(15)
	if(shock_roll)
		visible_message("<span class='warning'>[src] перегрызает [wire]. Кабель мёртв!</span>")
		playsound(src, 'sound/effects/sparks2.ogg', 100, TRUE)
		wire.deconstruct()
		death()
		return TRUE
	visible_message("<span class='warning'>[src] перегрызает [wire]. Выглядит целым!</span>")
	playsound(src, 'sound/effects/sparks2.ogg', 100, TRUE)
	wire.deconstruct()
	return TRUE

// Знаю что это когда-то сломается, но мне лень фиксить.
#define REGALRAT_RIOT_PROB_PER_SECOND 10
#define REGALRAT_COFFER_PROB_PER_SECOND 20
#define RAT_GNAW_PROB_PER_SECOND 20
#define RAT_KING_ORDER_RANGE 9

/datum/ai_controller/hostile_adapter/melee_chaser/regalrat
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/regalrat_royal_duties,
		/datum/ai_planning_subtree/opportunistic_ventcrawler,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

/// Профиль крыс
/datum/ai_controller/hostile_adapter/melee_chaser/rat
	planning_subtrees = list(
		/datum/ai_planning_subtree/rat_horde_orders,
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/rat_serve_king,
		/datum/ai_planning_subtree/rat_gnaw_cables,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

/datum/ai_planning_subtree/regalrat_royal_duties

/datum/ai_planning_subtree/regalrat_royal_duties/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/regalrat/king = controller.pawn
	if(!istype(king) || !king.riot || !king.coffer)
		return
	//легаси-структура ролла: сперва шанс риота, иначе шанс коффера
	if(SPT_PROB(REGALRAT_RIOT_PROB_PER_SECOND, delta_time))
		controller.queue_behavior(/datum/ai_behavior/regalrat_royal_duty/riot)
	else if(SPT_PROB(REGALRAT_COFFER_PROB_PER_SECOND, delta_time))
		controller.queue_behavior(/datum/ai_behavior/regalrat_royal_duty/coffer)

/datum/ai_behavior/regalrat_royal_duty
	action_cooldown = 2 SECONDS

/datum/ai_behavior/regalrat_royal_duty/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/regalrat/king = controller.pawn
	if(!istype(king))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/datum/action/cooldown/duty = royal_action(king)
	if(!duty)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	duty.Trigger()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/regalrat_royal_duty/proc/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return null

/datum/ai_behavior/regalrat_royal_duty/riot/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return king.riot

/datum/ai_behavior/regalrat_royal_duty/coffer/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return king.coffer

/datum/ai_planning_subtree/rat_serve_king

/datum/ai_planning_subtree/rat_serve_king/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/rat/soldier = controller.pawn
	if(!istype(soldier))
		return
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return //своя цель важнее приказов
	if(controller.has_fresh_contact())
		return //уже идём по наводке
	controller.queue_behavior(/datum/ai_behavior/rat_heed_the_king)

// Поиск короля
/datum/ai_behavior/rat_heed_the_king
	action_cooldown = 4 SECONDS

/datum/ai_behavior/rat_heed_the_king/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/rat/soldier = controller.pawn
	if(!istype(soldier))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	for(var/mob/living/simple_animal/hostile/regalrat/king in SSspatial_grid.orthogonal_range_search(soldier, SPATIAL_GRID_CONTENTS_TYPE_AI_TARGETS, RAT_KING_ORDER_RANGE))
		if(QDELETED(king) || king.stat != CONSCIOUS)
			continue
		if(get_dist(soldier, king) > RAT_KING_ORDER_RANGE)
			continue
		if(!king.faction_check_mob(soldier, TRUE))
			continue
		var/atom/royal_target = king.target
		if(QDELETED(royal_target) || !soldier.CanAttack(royal_target))
			continue
		var/turf/royal_turf = get_turf(royal_target)
		if(!royal_turf)
			continue
		controller.receive_combat_contact(royal_target, royal_turf, AI_CONTACT_ALLY)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

/// Грызня кабелей
/datum/ai_planning_subtree/rat_gnaw_cables

/datum/ai_planning_subtree/rat_gnaw_cables/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/rat/vermin = controller.pawn
	if(!istype(vermin))
		return
	if(!SPT_PROB(RAT_GNAW_PROB_PER_SECOND, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/rat_gnaw_cables)

/datum/ai_behavior/rat_gnaw_cables
	action_cooldown = 2 SECONDS

/datum/ai_behavior/rat_gnaw_cables/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/rat/vermin = controller.pawn
	if(!istype(vermin))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(!vermin.try_chew_cables())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

#undef REGALRAT_RIOT_PROB_PER_SECOND
#undef REGALRAT_COFFER_PROB_PER_SECOND
#undef RAT_GNAW_PROB_PER_SECOND
#undef RAT_KING_ORDER_RANGE

// Способности короля остальные
/datum/action/cooldown/rat_domain
	name = "Владения крысиного короля"
	desc = "Пока включено, вокруг расползаются миазмы и грязь, подходящие для крысиной армии."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "expand"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 10 SECONDS
	click_to_activate = FALSE
	var/active = FALSE
	var/mess_timer

/datum/action/cooldown/rat_domain/Activate(atom/target)
	if(!owner)
		return
	var/mob/living/simple_animal/hostile/regalrat/king = owner
	if(!istype(king))
		return
	if(king.movement_type & VENTCRAWLING)
		king.balloon_alert(king, "не в вентиляции!")
		return
	set_active(!active)
	StartCooldown()

/datum/action/cooldown/rat_domain/Remove(mob/remove_from)
	set_active(FALSE)
	return ..()

/datum/action/cooldown/rat_domain/proc/set_active(new_active)
	if(active == new_active)
		return
	active = new_active
	button_icon_state = active ? "coffer" : "expand"
	UpdateButtons()
	deltimer(mess_timer)
	mess_timer = null
	if(active)
		spread_domain()

/datum/action/cooldown/rat_domain/proc/spread_domain()
	if(!active || !owner)
		return
	if(owner.stat == DEAD)
		set_active(FALSE)
		return
	var/turf/our_turf = get_turf(owner)
	if(our_turf)
		our_turf.atmos_spawn_air("miasma=[RAT_KING_DOMAIN_MIASMA_MOLES];TEMP=293.15")
		var/list/spots = list(our_turf) + get_adjacent_open_turfs(owner)
		var/turf/mess_turf = pick(spots)
		switch(rand(1, 10))
			if(8)
				new /obj/effect/decal/cleanable/vomit(mess_turf)
			if(9)
				new /obj/effect/decal/cleanable/vomit/old(mess_turf)
			if(10)
				new /obj/effect/decal/cleanable/oil/slippery(mess_turf)
			else
				new /obj/effect/decal/cleanable/dirt(mess_turf)
	mess_timer = addtimer(CALLBACK(src, PROC_REF(spread_domain)), RAT_KING_DOMAIN_INTERVAL, TIMER_STOPPABLE)

/datum/action/cooldown/rat_order
	name = "Приказ орде"
	desc = "Отдайте приказ крысам: следовать, собраться, атаковать, охранять, держать позицию или разбежаться."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "command"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_CONSCIOUS
	click_to_activate = FALSE
	cooldown_time = 2 SECONDS
	var/datum/rat_horde/horde

/datum/action/cooldown/rat_order/Activate(atom/target)
	if(!owner)
		return
	owner.click_intercept = null
	INVOKE_ASYNC(src, PROC_REF(open_menu))

/datum/action/cooldown/rat_order/proc/open_menu()
	if(!owner || QDELETED(owner))
		return
	var/datum/rat_horde/horde = get_horde()
	if(!horde)
		return
	var/mob/living/action_owner = owner
	var/mob/living/order_target
	if(istype(action_owner, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/hostile_owner = action_owner
		if(isliving(hostile_owner.target))
			order_target = hostile_owner.target
		if(!order_target)
			for(var/mob/living/candidate in oview(RAT_HORDE_ORDER_RANGE, owner))
				if(candidate == owner || !hostile_owner.CanAttack(candidate))
					continue
				order_target = candidate
				break
	if(!order_target && horde.mode == RAT_HORDE_SOFT)
		for(var/mob/living/carbon/human/human in oview(3, owner))
			order_target = human
			break
	var/list/choices = list()
	var/list/order_by_choice = list()
	var/list/order_info = list(
		list(RAT_ORDER_FOLLOW, "Следовать", "command"),
		list(RAT_ORDER_GATHER, "Собраться", "expand"),
		list(RAT_ORDER_ATTACK, "Атаковать", "riot"),
		list(RAT_ORDER_GUARD, "Охранять", "directive"),
		list(RAT_ORDER_HOLD, "Держать позицию", "coffer"),
		list(RAT_ORDER_SCATTER, "Разбежаться", "command"),
		list(RAT_ORDER_PLAY, "Играть", "riot"),
	)
	for(var/list/info as anything in order_info)
		var/order_id = info[1]
		if(!horde.is_order_allowed(order_id))
			continue
		if(order_id == RAT_ORDER_ATTACK && !order_target)
			continue
		if(order_id == RAT_ORDER_PLAY && !order_target)
			continue
		var/image/choice_icon = image(icon = 'icons/mob/actions/actions_animal.dmi', icon_state = info[3])
		choices[info[2]] = choice_icon
		order_by_choice[info[2]] = order_id
	if(!length(choices))
		return
	var/choice = show_radial_menu(owner, owner, choices, radius = 42)
	if(!choice || QDELETED(src) || !owner)
		return
	var/order = order_by_choice[choice]
	var/turf/order_turf = get_turf(order_target || owner)
	var/duration = RAT_HORDE_ORDER_DURATION
	switch(order)
		if(RAT_ORDER_ATTACK, RAT_ORDER_GUARD, RAT_ORDER_PLAY)
			horde.issue_order(order, order_target, order_turf, duration)
		else
			horde.issue_order(order, null, get_turf(owner), duration)
	StartCooldown()

/datum/action/cooldown/rat_order/proc/get_horde()
	if(horde && !QDELETED(horde))
		return horde
	if(!owner)
		return null
	if(istype(owner, /mob/living/simple_animal/hostile/regalrat))
		var/mob/living/simple_animal/hostile/regalrat/king = owner
		return king.get_rat_horde()
	var/mob/living/living_owner = owner
	if(!istype(living_owner))
		return null
	var/datum/quirk/rat_whisperer/quirk = locate(/datum/quirk/rat_whisperer) in living_owner.roundstart_quirks
	if(quirk)
		return quirk.get_horde()
	return null

/datum/action/cooldown/rat_order/call_mice
	name = "Созвать мышей"
	desc = "Собрать ближайших мышей и позвать ещё 3–5, после чего приказать орде следовать за вами."
	button_icon_state = "directive"
	click_to_activate = FALSE
	cooldown_time = 45 SECONDS

/datum/action/cooldown/rat_order/call_mice/Activate(atom/target)
	if(!owner)
		return
	var/datum/rat_horde/horde = get_horde()
	if(!horde || horde.mode != RAT_HORDE_SOFT)
		return
	var/called = 0
	for(var/mob/living/simple_animal/mouse/mouse in oview(owner, RAT_HORDE_CALL_RANGE))
		if(horde.register_minion(mouse))
			called++
	if(called < horde.max_minions)
		var/turf/spawn_turf = get_turf(owner)
		var/cap = CONFIG_GET(number/ratcap)
		var/to_spawn = min(rand(3, 5), horde.max_minions - length(horde.minions), cap - LAZYLEN(SSmobs.cheeserats))
		if(spawn_turf && to_spawn > 0)
			for(var/i in 1 to to_spawn)
				var/mob/living/simple_animal/mouse/new_mouse = new(spawn_turf)
				SSmobs.cheeserats += new_mouse
				if(horde.register_minion(new_mouse))
					called++
	if(!called)
		if(length(horde.minions) >= horde.max_minions)
			to_chat(owner, span_warning("Орда уже полна."))
		else
			to_chat(owner, span_warning("Рядом нет мышей, которых можно позвать."))
		return
	horde.issue_order(RAT_ORDER_FOLLOW, null, get_turf(owner))
	owner.visible_message(span_notice("[owner] тихо свистит, и мыши собираются вокруг."), span_notice("Вы созываете [called] мышей."))
	StartCooldown()

/mob/living/simple_animal/proc/rat_friend_attack_hand(datum/source, mob/living/user)
	SIGNAL_HANDLER
	if(rat_friend_harm_intercept(user, src))
		return COMPONENT_NO_ATTACK_HAND

/mob/living/simple_animal/proc/rat_friend_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(rat_friend_harm_intercept(user, src))
		return COMPONENT_NO_AFTERATTACK

/datum/action/cooldown/rat_lick
	name = "Лизнуть"
	desc = "Облизать текущую цель, оставив на ней крысиную слюну."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "coffer"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 2 SECONDS

/datum/action/cooldown/rat_lick/Activate(atom/target)
	if(!owner)
		return
	var/mob/living/simple_animal/hostile/regalrat/king = owner
	if(!istype(king))
		return
	var/atom/lick_target = king.target
	if(!lick_target || QDELETED(lick_target))
		to_chat(king, span_warning("Нет цели для облизывания."))
		return
	if(!king.poison_target(lick_target))
		to_chat(king, span_warning("Это не получится облизать."))
		return
	StartCooldown()


// Внешность короля

/datum/rat_fashion
	var/name = "".
	var/allow_random = TRUE
	var/icon = 'icons/mob/rat.dmi'
	var/icon_state_living
	var/icon_state_dead

/datum/rat_fashion/proc/get_radial_select()
	return image(icon = icon, icon_state = icon_state_living)

/datum/rat_fashion/proc/apply(mob/living/simple_animal/hostile/regalrat/rat_target)
	if(QDELETED(rat_target))
		return
	rat_target.icon = icon
	rat_target.icon_living = icon_state_living
	rat_target.icon_dead = icon_state_dead
	rat_target.icon_state = (rat_target.stat == DEAD) ? icon_state_dead : icon_state_living
	rat_target.update_appearance(UPDATE_ICON)

/datum/rat_fashion/default
	name = "Королевская крыса"
	icon = 'icons/mob/animal.dmi'
	icon_state_living = "regalrat"
	icon_state_dead = "regalrat_dead"

/datum/rat_fashion/classic
	name = "Ретро-крыса"
	icon_state_living = "classic"
	icon_state_dead = "classic_dead"

/// *buff
/datum/rat_fashion/swole
	name = "Крыса-качок"
	allow_random = FALSE
	icon_state_living = "buffking"
	icon_state_dead = "buffking_dead"

/datum/rat_fashion/rat_queen
	name = "Крысиная королева"
	allow_random = FALSE
	icon_state_living = "ratqueen"
	icon_state_dead = "ratqueen_dead"

/datum/rat_fashion/rat_queen_alt
	name = "Толстая королева"
	allow_random = FALSE
	icon_state_living = "ratqueen_fat"
	icon_state_dead = "ratqueen_dead"

/datum/rat_fashion/ringmaster
	name = "цирковой мастер"
	allow_random = FALSE
	icon_state_living = "ringmaster"
	icon_state_dead = "ratqueen_dead"

/datum/action/cooldown/rat_fashion
	name = "Королевский облик"
	desc = "Сменить облик крысиного короля."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "exit_possession"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 10 SECONDS

/datum/action/cooldown/rat_fashion/Activate(atom/target)
	if(!owner)
		return
	var/mob/living/simple_animal/hostile/regalrat/rat_owner = owner
	if(!istype(rat_owner))
		return
	INVOKE_ASYNC(src, PROC_REF(open_menu), rat_owner)

/datum/action/cooldown/rat_fashion/proc/open_menu(mob/living/simple_animal/hostile/regalrat/rat_owner)
	if(QDELETED(src) || QDELETED(rat_owner) || owner != rat_owner)
		return
	var/list/options = list()
	var/list/styles_by_choice = list()
	for(var/style_path in subtypesof(/datum/rat_fashion))
		var/datum/rat_fashion/style = new style_path()
		options[style.name] = style.get_radial_select()
		styles_by_choice[style.name] = style
	var/choice = show_radial_menu(rat_owner, rat_owner, options, radius = 42)
	if(!choice)
		QDEL_LIST_ASSOC_VAL(styles_by_choice)
		return
	if(QDELETED(src) || QDELETED(rat_owner) || owner != rat_owner)
		QDEL_LIST_ASSOC_VAL(styles_by_choice)
		return
	var/datum/rat_fashion/chosen = styles_by_choice[choice]
	for(var/style_name in styles_by_choice)
		var/datum/rat_fashion/style = styles_by_choice[style_name]
		if(style != chosen)
			qdel(style)
	if(!chosen)
		return
	if(rat_owner.current_look?.name == chosen.name)
		rat_owner.balloon_alert(rat_owner, "это уже ваш облик!")
		qdel(chosen)
		return
	var/turf/origin = get_turf(rat_owner)
	if(!origin)
		qdel(chosen)
		return
	rat_owner.balloon_alert_to_viewers("дрожит...")
	if(!do_after(rat_owner, 3 SECONDS, target = origin))
		rat_owner.balloon_alert(rat_owner, "прервано!")
		qdel(chosen)
		return
	if(QDELETED(src) || QDELETED(rat_owner))
		qdel(chosen)
		return
	QDEL_NULL(rat_owner.current_look)
	rat_owner.current_look = chosen
	chosen.apply(rat_owner)
	StartCooldown()


// Ерп версия короля крыс.

/datum/action/cooldown/rat_pheromones
	name = "Феромоны"
	desc = "Испускать сладковатый запах, будоражащий существ рядом."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "biohazard"
	background_icon_state = "bg_clock"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 10 SECONDS
	var/active = FALSE
	var/pulse_timer

/datum/action/cooldown/rat_pheromones/Activate(atom/target)
	if(!owner)
		return
	if(owner.movement_type & VENTCRAWLING)
		owner.balloon_alert(owner, "не в вентиляции!")
		return
	set_active(!active)
	StartCooldown()

/datum/action/cooldown/rat_pheromones/Remove(mob/remove_from)
	set_active(FALSE)
	return ..()

/datum/action/cooldown/rat_pheromones/proc/set_active(new_active)
	if(active == new_active)
		return
	active = new_active
	button_icon_state = active ? "heal" : "biohazard"
	UpdateButtons()
	deltimer(pulse_timer)
	pulse_timer = null
	if(active)
		pulse()

/datum/action/cooldown/rat_pheromones/proc/pulse()
	if(!active || QDELETED(owner))
		return
	if(owner.stat == DEAD)
		set_active(FALSE)
		return
	for(var/mob/living/carbon/human/human in oview(3, owner))
		if(!human.client || !human.client.prefs)
			continue
		var/datum/preferences/prefs = human.client.prefs
		if(prefs.erppref != "Yes" || prefs.nonconpref == "No" || prefs.mobsexpref == "No")
			continue
		if(!(prefs.toggles & VERB_CONSENT))
			continue
		human.adjust_arousal(1, "феромоны крысиной королевы", aphro = TRUE)
		new /obj/effect/temp_visual/heart(get_turf(human))
	pulse_timer = addtimer(CALLBACK(src, PROC_REF(pulse)), 5 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/regalrat/lust
	name = "Крысиная королева"
	desc = "Огромная ухоженная крыса с вкрадчивым взглядом. Её свита из мышей слушается каждого писка."
	icon = 'icons/mob/rat.dmi'
	icon_state = "ratqueen"
	icon_living = "ratqueen"
	icon_dead = "ratqueen_dead"
	gender = FEMALE
	soft_horde = TRUE
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_sound = null
	attack_verb_continuous = "ластится к"
	attack_verb_simple = "ластится к"
	density = FALSE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	playable_by_ghost = TRUE
	AIStatus = AI_OFF
	can_buckle = TRUE
	max_buckled_mobs = 1
	tame = TRUE

/mob/living/simple_animal/hostile/regalrat/lust/Initialize(mapload)
	. = ..()
	var/datum/action/cooldown/rat_pheromones/pheromones = new
	pheromones.Grant(src)
	var/static/list/skins = list("ratqueen", "ratqueen_fat", "ringmaster", "buffking")
	var/skin = pick(skins)
	icon_state = skin
	icon_living = skin
	icon_dead = (skin == "buffking") ? "buffking_dead" : "ratqueen_dead"

/mob/living/simple_animal/hostile/regalrat/lust/grant_titles()
	name = "Крысиная королева"
	special_moniker = "От неё пахнет сыром, мышью и чем-то опасным."

/mob/living/simple_animal/hostile/regalrat/lust/examine(mob/user)
	. = ..()
	. += span_notice("Можно оседлать.")

/mob/living/simple_animal/hostile/regalrat/lust/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/regalrat/lust/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/regalrat/lust/verb/switch_gender()
	set name = "Сменить облик"
	set desc = "Каждый день я немножечко меняюсь."
	set category = "Крысиная королева"

	if(stat != CONSCIOUS)
		to_chat(usr, span_warning("Нельзя менять облик без сознания!"))
		return
	var/choice = tgui_alert(usr, "Выберите облик.", "Облик", list("Королева", "Король", "Толстая королева", "Цирковой мастер"))
	if(!choice)
		return
	switch(choice)
		if("Королева")
			gender = FEMALE
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = TRUE
			has_breasts = TRUE
			icon_state = "ratqueen"
			icon_living = "ratqueen"
			icon_dead = "ratqueen_dead"
		if("Король")
			gender = MALE
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = FALSE
			has_breasts = FALSE
			icon_state = "buffking"
			icon_living = "buffking"
			icon_dead = "buffking_dead"
		if("Толстая королева")
			gender = FEMALE
			has_penis = FALSE
			has_balls = FALSE
			has_vagina = TRUE
			has_breasts = TRUE
			icon_state = "ratqueen_fat"
			icon_living = "ratqueen_fat"
			icon_dead = "ratqueen_dead"
		if("Цирковой мастер")
			gender = PLURAL
			has_penis = TRUE
			has_balls = TRUE
			has_vagina = TRUE
			has_breasts = TRUE
			icon_state = "ringmaster"
			icon_living = "ringmaster"
			icon_dead = "ratqueen_dead"
	update_appearance(UPDATE_ICON)

/obj/effect/mob_spawn/rat_queen
	name = "Крысиная королева"
	desc = "Старое логово, выстланное тряпками и погрызенными проводами. Здесь пахнет сыром и чем-то ещё."
	mob_name = "Крысиная королева"
	mob_type = /mob/living/simple_animal/hostile/regalrat/lust
	mob_gender = FEMALE
	short_desc = "Вы — крысиная королева."
	flavour_text = "Ваша власть — не когти, а очарование и мягкая лапа, ведущая мышей. Собирайте свиту, вейте гнездо и наслаждайтесь. Вы не обязаны никого убивать."
	important_info = "НЕ ГРИФЕРИТЬ. Это ЕРП-антагонист."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	death = FALSE
	roundstart = FALSE
	random = FALSE
	uses = 1
	category = "special"
	ghost_usable = TRUE

/obj/effect/mob_spawn/rat_queen/allow_spawn(mob/user, silent = FALSE)
	if(!(GLOB.round_type in list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)))
		if(!silent)
			to_chat(user, span_warning("Игра за ЕРП-антагонистов допускается лишь в режимах Extended или Dynamic Light!"))
		return FALSE
	return ..()
