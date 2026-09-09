/mob/living/simple_animal/hostile/regalrat
	name = "regal rat"
	desc = "An evolved rat, created through some strange science. It leads nearby rats with deadly efficiency to protect its kingdom. Not technically a king."
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
	butcher_results = list(/obj/item/clothing/head/crown = 1,)
	response_help_continuous = "glares at"
	response_help_simple = "glare at"
	response_disarm_continuous = "skoffs at"
	response_disarm_simple = "skoff at"
	response_harm_continuous = "slashes"
	response_harm_simple = "slash"
	melee_damage_lower = 10
	melee_damage_upper = 12
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/punch1.ogg'
	unique_name = TRUE
	faction = list("rat")
	var/datum/action/cooldown/coffer
	var/datum/action/cooldown/riot
	///Number assigned to rats and mice, checked when determining infighting.

/mob/living/simple_animal/hostile/regalrat/Initialize(mapload)
	. = ..()
	coffer = new /datum/action/cooldown/coffer
	coffer.Grant(src)
	riot = new /datum/action/cooldown/riot
	riot.Grant(src)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	INVOKE_ASYNC(src, PROC_REF(poll_for_player))

/mob/living/simple_animal/hostile/regalrat/proc/poll_for_player()
	var/list/mob/dead/observer/candidates = pollGhostCandidates("Do you want to play as the Royal Rat, cheesey be his crown?", ROLE_SENTIENCE, null, FALSE, 100, POLL_IGNORE_SENTIENCE_POTION)
	if(LAZYLEN(candidates) && !mind)
		var/mob/dead/observer/C = pick(candidates)
		key = C.key
		notify_ghosts("All rise for the rat king, ascendant to the throne in \the [get_area(src)].", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE)

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
	return ..()

/mob/living/simple_animal/hostile/regalrat/examine(mob/user)
	. = ..()
	if(istype(user,/mob/living/simple_animal/hostile/rat))
		var/mob/living/simple_animal/hostile/rat/ratself = user
		if(ratself.faction_check_mob(src, TRUE))
			. += "<span class='notice'>This is your king. Long live his majesty!</span>"
		else
			. += "<span class='warning'>This is a false king! Strike him down!</span>"
	else if(istype(user,/mob/living/simple_animal/hostile/regalrat))
		. += "<span class='warning'>Who is this foolish false king? This will not stand!</span>"

/**
  *This action creates trash, money, dirt, and cheese.
  */

/datum/action/cooldown/coffer
	name = "Fill Coffers"
	desc = "Your newly granted regality and poise let you scavenge for lost junk, but more importantly, cheese."
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
			to_chat(owner, "<span class='notice'>Score! You find some cheese!</span>")
			new /obj/item/reagent_containers/food/snacks/cheesewedge(T)
		if(6 to 10)
			var/pickedcoin = pick(GLOB.ratking_coins)
			to_chat(owner, "<span class='notice'>You find some leftover coins. More for the royal treasury!</span>")
			for(var/i = 1 to rand(1,3))
				new pickedcoin(T)
		if(11)
			to_chat(owner, "<span class='notice'>You find a... Hunh. This coin doesn't look right.</span>")
			var/rarecoin = rand(1,2)
			if (rarecoin == 1)
				new /obj/item/coin/twoheaded(T)
			else
				new /obj/item/coin/antagtoken(T)
		if(12 to 40)
			var/pickedtrash = pick(GLOB.ratking_trash)
			to_chat(owner, "<span class='notice'>You just find more garbage and dirt. Lovely, but beneath you now.</span>")
			new /obj/effect/decal/cleanable/dirt(T)
			new pickedtrash(T)
		if(41 to 100)
			to_chat(owner, "<span class='notice'>Drat. Nothing.</span>")
			new /obj/effect/decal/cleanable/dirt(T)
	StartCooldown()

/**
  *This action checks all nearby mice, and converts them into hostile rats. If no mice are nearby, creates a new one.
  */

/datum/action/cooldown/riot
	name = "Raise Army"
	desc = "Raise an army out of the hordes of mice and pests crawling around the maintenance shafts."
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	button_icon_state = "riot"
	background_icon_state = "bg_clock"
	cooldown_time = 80
	check_flags = AB_CHECK_CONSCIOUS
	///Checks to see if there are any nearby mice. Does not count Rats.

/datum/action/cooldown/riot/Activate()
	var/cap = CONFIG_GET(number/ratcap)
	var/something_from_nothing = FALSE
	for(var/mob/living/simple_animal/mouse/M in oview(owner, 5))
		var/mob/living/simple_animal/hostile/rat/new_rat = new(get_turf(M))
		something_from_nothing = TRUE
		if(M.mind && M.stat == CONSCIOUS)
			M.mind.transfer_to(new_rat)
		if(istype(owner,/mob/living/simple_animal/hostile/regalrat))
			var/mob/living/simple_animal/hostile/regalrat/giantrat = owner
			new_rat.faction = giantrat.faction
		qdel(M)
	if(!something_from_nothing)
		if(LAZYLEN(SSmobs.cheeserats) >= cap)
			to_chat(owner,"<span class='warning'>There's too many mice on this station to beckon a new one! Find them first!</span>")
			return
		new /mob/living/simple_animal/mouse(owner.loc)
		owner.visible_message("<span class='warning'>[owner] commands a mouse to its side!</span>")
	else
		owner.visible_message("<span class='warning'>[owner] commands its army to action, mutating them into rats!</span>")
	StartCooldown()

/mob/living/simple_animal/hostile/rat
	name = "rat"
	desc = "It's a nasty, ugly, evil, disease-ridden rodent with anger issues."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	speak = list("Skree!","SKREEE!","Squeak?")
	speak_emote = list("squeaks")
	emote_hear = list("Hisses.")
	emote_see = list("runs in a circle.", "stands on its hind legs.")
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

/mob/living/simple_animal/hostile/rat/Initialize(mapload)
	. = ..()
	SSmobs.cheeserats += src
	AddComponent(/datum/component/swarming)
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/hostile/rat/Destroy()
	SSmobs.cheeserats -= src
	return ..()

/mob/living/simple_animal/hostile/rat/examine(mob/user)
	. = ..()
	if(istype(user,/mob/living/simple_animal/hostile/rat))
		var/mob/living/simple_animal/hostile/rat/ratself = user
		if(ratself.faction_check_mob(src, TRUE))
			. += "<span class='notice'>You both serve the same king.</span>"
		else
			. += "<span class='warning'>This fool serves a different king!</span>"
	else if(istype(user,/mob/living/simple_animal/hostile/regalrat))
		var/mob/living/simple_animal/hostile/regalrat/ratking = user
		if(ratking.faction_check_mob(src, TRUE))
			. += "<span class='notice'>This rat serves under you.</span>"
		else
			. += "<span class='warning'>This peasant serves a different king! Strike him down!</span>"

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
	return ..()

///Грызня кабеля под открытым полом (зовёт сабтри rat_gnaw_cables).
///shock_roll форсит/запрещает разряд (null = легаси prob(15)).
///TRUE = кабель перегрызен.
/mob/living/simple_animal/hostile/rat/proc/try_chew_cables(shock_roll = null)
	var/turf/open/floor/floor = get_turf(src)
	if(!istype(floor) || (floor.turf_flags & TURF_INTACT))
		return FALSE
	var/obj/structure/cable/wire = locate() in floor
	//обесточенный кабель не грызём вовсе: обе легаси-ветки требуют avail()
	if(!wire || !wire.avail())
		return FALSE
	if(isnull(shock_roll))
		shock_roll = prob(15)
	if(shock_roll)
		visible_message("<span class='warning'>[src] chews through the [wire]. It's toast!</span>")
		playsound(src, 'sound/effects/sparks2.ogg', 100, TRUE)
		wire.deconstruct()
		death()
		return TRUE
	visible_message("<span class='warning'>[src] chews through the [wire]. It looks unharmed!</span>")
	playsound(src, 'sound/effects/sparks2.ogg', 100, TRUE)
	wire.deconstruct()
	return TRUE

// ===== Адаптер-профили крысиного королевства =====
// Вражда королей и фракционные гейты крыс целиком живут в CanAttack обоих
// типов - стратегия hostile_legacy зовёт их делегацией, отдельная стратегия
// не нужна. Особости кластера: король ведёт королевские дела (riot/coffer),
// крысы стягиваются на цель своего короля наводкой-контактом и грызут кабели.

///Легаси-каденс NPC-пула 2с: prob(20) риота = 10%/с, else prob(50) коффера = 20%/с
#define REGALRAT_RIOT_PROB_PER_SECOND 10
#define REGALRAT_COFFER_PROB_PER_SECOND 20
///Легаси prob(40) на 2с тик = 20%/с
#define RAT_GNAW_PROB_PER_SECOND 20
///Радиус, в котором крыса слышит приказы короля (легаси vision_range короля)
#define RAT_KING_ORDER_RANGE 9

///Профиль короля: обычный мили-чейзер + королевские дела
/datum/ai_controller/hostile_adapter/melee_chaser/regalrat
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/regalrat_royal_duties,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Профиль крысы: мили-чейзер + служба королю + грызня кабелей
/datum/ai_controller/hostile_adapter/melee_chaser/rat
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/rat_serve_king,
		/datum/ai_planning_subtree/rat_gnaw_cables,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Королевские дела: как в легаси, роллятся каждый тик планирования даже в бою
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

///Королевское дело: дёргает легаси-действие (само проверит свой кулдаун)
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

///Какое из легаси-действий короля дёргает это дело
/datum/ai_behavior/regalrat_royal_duty/proc/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return null

/datum/ai_behavior/regalrat_royal_duty/riot/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return king.riot

/datum/ai_behavior/regalrat_royal_duty/coffer/royal_action(mob/living/simple_animal/hostile/regalrat/king)
	return king.coffer

///Служба королю: свободная крыса изредка сверяется с целью своего короля.
///Приказ приходит НАВОДКОЙ (combat contact: точка и приметы), не самим атомом -
///крыса захватит цель только собственным восприятием, как и по докладу стаи.
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

///Поиск короля своей фракции с живой целью; каденс держит action_cooldown
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
		//верность как в CanAttack крысы: точное совпадение фракций
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

///Грызня кабелей: легаси-шанс из handle_automated_action, исполнение общим процем
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
