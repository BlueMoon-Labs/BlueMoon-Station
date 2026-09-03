#define SPIDER_IDLE 0
#define SPINNING_WEB 1
#define LAYING_EGGS 2
#define MOVING_TO_TARGET 3
#define SPINNING_COCOON 4

/mob/living/simple_animal/hostile/poison
	var/poison_per_bite = 5
	var/poison_type = /datum/reagent/toxin

/mob/living/simple_animal/hostile/poison/AttackingTarget()
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		if(L.reagents)
			L.reagents.add_reagent(poison_type, poison_per_bite)

//basic spider mob, these generally guard nests
/mob/living/simple_animal/hostile/poison/giant_spider
	name = "giant spider"
	desc = "Furry and black, it makes you shudder to look at it. This one has deep red eyes."
	icon_state = "guard"
	icon_living = "guard"
	icon_dead = "guard_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	speak_emote = list("chitters")
	emote_hear = list("chitters")
	speak_chance = 5
	turns_per_move = 5
	see_in_dark = 10
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/spider = 2, /obj/item/reagent_containers/food/snacks/spiderleg = 8)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	maxHealth = 200
	health = 200
	obj_damage = 60
	melee_damage_lower = 15
	melee_damage_upper = 20
	faction = list("spiders")
	var/busy = SPIDER_IDLE
	pass_flags = PASSTABLE
	move_to_delay = 6
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	unique_name = 1
	gold_core_spawnable = HOSTILE_SPAWN
	see_in_dark = 4
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	footstep_type = FOOTSTEP_MOB_CLAW
	has_field_of_vision = FALSE // 360° vision.
	var/playable_spider = FALSE
	var/datum/action/innate/spider/lay_web/lay_web
	var/directive = "" //Message passed down to children, to relay the creator's orders

/mob/living/simple_animal/hostile/poison/giant_spider/Initialize(mapload)
	. = ..()
	lay_web = new
	lay_web.Grant(src)

	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)

/mob/living/simple_animal/hostile/poison/giant_spider/Destroy()
	QDEL_NULL(lay_web)
	return ..()

/mob/living/simple_animal/hostile/poison/giant_spider/Topic(href, href_list)
	if(href_list["activate"])
		var/mob/dead/observer/ghost = usr
		if(istype(ghost) && playable_spider)
			humanize_spider(ghost)

/mob/living/simple_animal/hostile/poison/giant_spider/Login()
	..()
	if(directive)
		to_chat(src, "<span class='notice'>Your mother left you a directive! Follow it at all costs.</span>")
		to_chat(src, "<span class='spider'><b>[directive]</b></span>")

/mob/living/simple_animal/hostile/poison/giant_spider/attack_ghost(mob/user)
	. = ..()
	if(.)
		return
	humanize_spider(user)

/mob/living/simple_animal/hostile/poison/giant_spider/proc/humanize_spider(mob/user)
	if(key || !playable_spider || stat)//Someone is in it, it's dead, or the fun police are shutting it down
		return FALSE
	if(isobserver(user))
		var/mob/dead/observer/O = user
		if(!O.can_reenter_round())
			return FALSE
	var/spider_ask = alert("Become a spider?", "Are you australian?", "Yes", "No")
	if(spider_ask == "No" || !src || QDELETED(src))
		return TRUE
	if(key)
		to_chat(user, "<span class='notice'>Someone else already took this spider.</span>")
		return TRUE
	user.transfer_ckey(src, FALSE)
	return TRUE

//nursemaids - these create webs and eggs
/mob/living/simple_animal/hostile/poison/giant_spider/nurse
	desc = "Furry and black, it makes you shudder to look at it. This one has brilliant green eyes."
	icon_state = "nurse"
	icon_living = "nurse"
	icon_dead = "nurse_dead"
	gender = FEMALE
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/spider = 2, /obj/item/reagent_containers/food/snacks/spiderleg = 8, /obj/item/reagent_containers/food/snacks/spidereggs = 4)
	maxHealth = 40
	health = 40
	melee_damage_lower = 5
	melee_damage_upper = 10
	poison_per_bite = 3
	var/atom/movable/cocoon_target
	var/fed = 0
	var/obj/effect/proc_holder/wrap/wrap
	var/datum/action/innate/spider/lay_eggs/lay_eggs
	var/datum/action/innate/spider/set_directive/set_directive
	var/static/list/consumed_mobs = list() //the tags of mobs that have been consumed by nurse spiders to lay eggs

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/Initialize(mapload)
	. = ..()
	wrap = new
	AddAbility(wrap)
	lay_eggs = new
	lay_eggs.Grant(src)
	set_directive = new
	set_directive.Grant(src)

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/Destroy()
	RemoveAbility(wrap)
	QDEL_NULL(lay_eggs)
	QDEL_NULL(set_directive)
	return ..()

//hunters have the most poison and move the fastest, so they can find prey
/mob/living/simple_animal/hostile/poison/giant_spider/hunter
	desc = "Furry and black, it makes you shudder to look at it. This one has sparkling purple eyes."
	icon_state = "hunter"
	icon_living = "hunter"
	icon_dead = "hunter_dead"
	maxHealth = 320
	health = 320
	melee_damage_lower = 18
	melee_damage_upper = 29
	poison_per_bite = 5
	move_to_delay = 5

//vipers are the rare variant of the hunter, no IMMEDIATE damage but so much poison medical care will be needed fast.
/mob/living/simple_animal/hostile/poison/giant_spider/hunter/viper
	name = "viper"
	desc = "Furry and black, it makes you shudder to look at it. This one has effervescent purple eyes."
	icon_state = "viper"
	icon_living = "viper"
	icon_dead = "viper_dead"
	maxHealth = 240
	health = 240
	melee_damage_lower = 1
	melee_damage_upper = 1
	poison_per_bite = 12
	move_to_delay = 4
	poison_type = /datum/reagent/toxin/venom //all in venom, glass cannon. you bite 5 times and they are DEFINITELY dead, but 40 health and you are extremely obvious. Ambush, maybe?
	speed = 1
	gold_core_spawnable = NO_SPAWN

//tarantulas are really tanky, regenerating (maybe), hulky monster but are also extremely slow, so.
/mob/living/simple_animal/hostile/poison/giant_spider/tarantula
	name = "tarantula"
	desc = "Furry and black, it makes you shudder to look at it. This one has abyssal red eyes."
	icon_state = "tarantula"
	icon_living = "tarantula"
	icon_dead = "tarantula_dead"
	maxHealth = 300 // woah nelly
	health = 300
	melee_damage_lower = 35
	melee_damage_upper = 40
	poison_per_bite = 0
	move_to_delay = 8
	speed = 7
	status_flags = NONE
	mob_size = MOB_SIZE_LARGE
	gold_core_spawnable = NO_SPAWN
	var/slowed_by_webs = FALSE

/mob/living/simple_animal/hostile/poison/giant_spider/tarantula/Moved(atom/oldloc, dir)
	. = ..()
	if(slowed_by_webs)
		if(!(locate(/obj/structure/spider/stickyweb) in loc))
			remove_movespeed_modifier(/datum/movespeed_modifier/tarantula_web)
			slowed_by_webs = FALSE
	else if(locate(/obj/structure/spider/stickyweb) in loc)
		add_movespeed_modifier(/datum/movespeed_modifier/tarantula_web)
		slowed_by_webs = TRUE

//midwives are the queen of the spiders, can send messages to all them and web faster. That rare round where you get a queen spider and turn your 'for honor' players into 'r6siege' players will be a fun one.
/mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife
	name = "midwife"
	desc = "Furry and black, it makes you shudder to look at it. This one has scintillating green eyes."
	icon_state = "midwife"
	icon_living = "midwife"
	icon_dead = "midwife_dead"
	maxHealth = 40
	health = 40
	var/datum/action/innate/spider/comm/letmetalkpls
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife/Initialize(mapload)
	. = ..()
	letmetalkpls = new
	letmetalkpls.Grant(src)

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife/Destroy()
	QDEL_NULL(letmetalkpls)
	return ..()

/mob/living/simple_animal/hostile/poison/giant_spider/ice //spiders dont usually like tempatures of 140 kelvin who knew
	name = "giant ice spider"
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	poison_type = /datum/reagent/consumable/frostoil
	color = rgb(114,228,250)
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/ice
	name = "giant ice spider"
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	poison_type = /datum/reagent/consumable/frostoil
	color = rgb(114,228,250)
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/poison/giant_spider/hunter/ice
	name = "giant ice spider"
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	poison_type = /datum/reagent/consumable/frostoil
	color = rgb(114,228,250)
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/proc/GiveUp(C)
	addtimer(CALLBACK(src, PROC_REF(giveup_delayed), C), 100, TIMER_DELETE_ME)

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/proc/giveup_delayed(C)
	if(busy == MOVING_TO_TARGET)
		if(cocoon_target == C && get_dist(src,cocoon_target) > 1)
			cocoon_target = null
		busy = FALSE
		stop_automated_movement = 0

/mob/living/simple_animal/hostile/poison/giant_spider/nurse/proc/cocoon()
	if(stat != DEAD && cocoon_target && !cocoon_target.anchored)
		if(cocoon_target == src)
			to_chat(src, "<span class='warning'>You can't wrap yourself!</span>")
			return
		if(istype(cocoon_target, /mob/living/simple_animal/hostile/poison/giant_spider))
			to_chat(src, "<span class='warning'>You can't wrap other spiders!</span>")
			return
		if(!Adjacent(cocoon_target))
			to_chat(src, "<span class='warning'>You can't reach [cocoon_target]!</span>")
			return
		if(busy == SPINNING_COCOON)
			to_chat(src, "<span class='warning'>You're already spinning a cocoon!</span>")
			return //we're already doing this, don't cancel out or anything
		busy = SPINNING_COCOON
		visible_message("<span class='notice'>[src] begins to secrete a sticky substance around [cocoon_target].</span>","<span class='notice'>You begin wrapping [cocoon_target] into a cocoon.</span>")
		stop_automated_movement = TRUE
		walk(src,0)
		if(do_after(src, 50, target = cocoon_target))
			if(busy == SPINNING_COCOON)
				var/obj/structure/spider/cocoon/C = new(cocoon_target.loc)
				if(isliving(cocoon_target))
					var/mob/living/L = cocoon_target
					if(L.blood_volume && (L.stat != DEAD || !consumed_mobs[L.tag])) //if they're not dead, you can consume them anyway
						consumed_mobs[L.tag] = TRUE
						fed++
						lay_eggs.UpdateButtons(TRUE)
						visible_message("<span class='danger'>[src] sticks a proboscis into [L] and sucks a viscous substance out.</span>","<span class='notice'>You suck the nutriment out of [L], feeding you enough to lay a cluster of eggs.</span>")
						L.death() //you just ate them, they're dead.
					else
						to_chat(src, "<span class='warning'>[L] cannot sate your hunger!</span>")
				cocoon_target.forceMove(C)

				if(cocoon_target.density || ismob(cocoon_target))
					C.icon_state = pick("cocoon_large1","cocoon_large2","cocoon_large3")
	cocoon_target = null
	busy = SPIDER_IDLE
	stop_automated_movement = FALSE

/datum/action/innate/spider
	icon_icon = 'icons/mob/actions/actions_animal.dmi'
	background_icon_state = "bg_alien"

/datum/action/innate/spider/lay_web
	name = "Spin Web"
	desc = "Spin a web to slow down potential prey."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "lay_web"

/datum/action/innate/spider/lay_web/Activate()
	if(!istype(owner, /mob/living/simple_animal/hostile/poison/giant_spider))
		return
	var/mob/living/simple_animal/hostile/poison/giant_spider/S = owner

	if(!isturf(S.loc))
		return
	var/turf/T = get_turf(S)

	var/obj/structure/spider/stickyweb/W = locate() in T
	var/obj/structure/spider/stickyweb/arachnid/W2 = locate() in T
	if(W || W2)
		to_chat(S, "<span class='warning'>There's already a web here!</span>")
		return

	if(S.busy != SPINNING_WEB)
		S.busy = SPINNING_WEB
		S.visible_message("<span class='notice'>[S] begins to secrete a sticky substance.</span>","<span class='notice'>You begin to lay a web.</span>")
		S.stop_automated_movement = TRUE
		if(do_after(S, 40, target = T))
			if(S.busy == SPINNING_WEB && S.loc == T)
				new /obj/structure/spider/stickyweb(T)
		S.busy = SPIDER_IDLE
		S.stop_automated_movement = FALSE
	else
		to_chat(S, "<span class='warning'>You're already spinning a web!</span>")

/obj/effect/proc_holder/wrap
	name = "Wrap"
	panel = "Spider"
	active = FALSE
	desc = "Wrap something or someone in a cocoon. If it's a living being, you'll also consume them, allowing you to lay eggs."
	ranged_mousepointer = 'icons/effects/wrap_target.dmi'
	action_icon = 'icons/mob/actions/actions_animal.dmi'
	action_icon_state = "wrap_0"
	action_background_icon_state = "bg_alien"

/obj/effect/proc_holder/wrap/update_icon()
	. = ..()
	action.button_icon_state = "wrap_[active]"
	action.UpdateButtons()

/obj/effect/proc_holder/wrap/Trigger(mob/living/simple_animal/hostile/poison/giant_spider/nurse/user)
	if(!istype(user))
		return TRUE
	activate(user)
	return TRUE

/obj/effect/proc_holder/wrap/proc/activate(mob/living/user)
	var/message
	if(active)
		message = "<span class='notice'>You no longer prepare to wrap something in a cocoon.</span>"
		remove_ranged_ability(message)
	else
		message = "<span class='notice'>You prepare to wrap something in a cocoon. <B>Left-click your target to start wrapping!</B></span>"
		add_ranged_ability(user, message, TRUE)
		return TRUE

/obj/effect/proc_holder/wrap/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated() || !istype(ranged_ability_user, /mob/living/simple_animal/hostile/poison/giant_spider/nurse))
		remove_ranged_ability()
		return

	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/user = ranged_ability_user

	if(user.Adjacent(target) && (ismob(target) || isobj(target)))
		var/atom/movable/target_atom = target
		if(target_atom.anchored)
			return
		user.cocoon_target = target_atom
		INVOKE_ASYNC(user, TYPE_PROC_REF(/mob/living/simple_animal/hostile/poison/giant_spider/nurse, cocoon))
		remove_ranged_ability()
		return TRUE

/obj/effect/proc_holder/wrap/on_lose(mob/living/carbon/user)
	remove_ranged_ability()

/datum/action/innate/spider/lay_eggs
	name = "Lay Eggs"
	desc = "Lay a cluster of eggs, which will soon grow into more spiders. You must wrap a living being to do this."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "lay_eggs"

/datum/action/innate/spider/lay_eggs/IsAvailable(silent = FALSE)
	if(..())
		if(!istype(owner, /mob/living/simple_animal/hostile/poison/giant_spider/nurse))
			return FALSE
		var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/S = owner
		if(S.fed)
			return TRUE
		return FALSE

/datum/action/innate/spider/lay_eggs/Activate()
	if(!istype(owner, /mob/living/simple_animal/hostile/poison/giant_spider/nurse))
		return
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/S = owner

	var/obj/structure/spider/eggcluster/E = locate() in get_turf(S)
	if(E)
		to_chat(S, "<span class='warning'>There is already a cluster of eggs here!</span>")
	else if(!S.fed)
		to_chat(S, "<span class='warning'>You are too hungry to do this!</span>")
	else if(S.busy != LAYING_EGGS)
		S.busy = LAYING_EGGS
		S.visible_message("<span class='notice'>[S] begins to lay a cluster of eggs.</span>","<span class='notice'>You begin to lay a cluster of eggs.</span>")
		S.stop_automated_movement = TRUE
		if(do_after(S, 50, target = get_turf(S)))
			if(S.busy == LAYING_EGGS)
				E = locate() in get_turf(S)
				if(!E || !isturf(S.loc))
					var/obj/structure/spider/eggcluster/C = new /obj/structure/spider/eggcluster(get_turf(S))
					if(S.ckey)
						C.player_spiders = TRUE
					C.directive = S.directive
					C.poison_type = S.poison_type
					C.poison_per_bite = S.poison_per_bite
					C.faction = S.faction.Copy()
					S.fed--
					UpdateButtons(TRUE)
		S.busy = SPIDER_IDLE
		S.stop_automated_movement = FALSE

/datum/action/innate/spider/set_directive
	name = "Set Directive"
	desc = "Set a directive for your children to follow."
	check_flags = AB_CHECK_CONSCIOUS
	button_icon_state = "directive"

/datum/action/innate/spider/set_directive/Activate()
	if(!istype(owner, /mob/living/simple_animal/hostile/poison/giant_spider/nurse))
		return
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/S = owner
	S.directive = stripped_input(S, "Enter the new directive", "Create directive", "[S.directive]")

/mob/living/simple_animal/hostile/poison/giant_spider/Login()
	. = ..()
	GLOB.spidermobs[src] = TRUE

/mob/living/simple_animal/hostile/poison/giant_spider/Destroy()
	GLOB.spidermobs -= src
	return ..()

/datum/action/innate/spider/comm
	name = "Command"
	desc = "Send a command to all living spiders."
	button_icon_state = "command"

/datum/action/innate/spider/comm/IsAvailable(silent = FALSE)
	if(!istype(owner, /mob/living/simple_animal/hostile/poison/giant_spider/nurse/midwife))
		return FALSE
	return TRUE

/datum/action/innate/spider/comm/Trigger()
	var/input = stripped_input(owner, "Input a command for your legions to follow.", "Command", "")
	if(QDELETED(src) || !input || !IsAvailable())
		return FALSE
	spider_command(owner, input)
	return TRUE

/datum/action/innate/spider/comm/proc/spider_command(mob/living/user, message)
	if(!message)
		return
	var/my_message
	my_message = "<span class='spider'><b>Command from [user]:</b> [message]</span>"
	for(var/mob/living/simple_animal/hostile/poison/giant_spider/M in GLOB.spidermobs)
		to_chat(M, my_message)
	for(var/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, user)
		to_chat(M, "[link] [my_message]")
	usr.log_talk(message, LOG_SAY, tag="spider command")

/mob/living/simple_animal/hostile/poison/giant_spider/handle_temperature_damage()
	if(bodytemperature < minbodytemp)
		adjustBruteLoss(20)
	else if(bodytemperature > maxbodytemp)
		adjustBruteLoss(20)

// ===== Адаптер-профиль =====
// Легаси handle_automated_action декомпозирован: 1%-перебежка (idle-skitter) -
// сабтри spider_idle_skitter, цикл няньки (кокон беспомощных, паутина, яйца,
// обмотка предметов) - сабтри spider_nurse_cycle с гейтом "нет цели" (бой
// важнее плетения: легаси-else точно так же сбрасывал busy при активном AI).
// Шансы, кулдауны и сообщения сохранены: решения ставятся с каденсом NPC-пула,
// исполнение - делегацией легаси-прокам (cocoon/GiveUp/Activate).

///Легаси prob(1) на 2-секундный тик NPC-пула = 0.5%/с планировщика
#define GIANT_SPIDER_SKITTER_PROB_PER_SECOND 0.5
///Легаси prob(30) на 2-секундный тик NPC-пула = 15%/с планировщика
#define GIANT_SPIDER_NURSE_PROB_PER_SECOND 15
///Легаси-таймер resume_spider_movement: перебежка длится не дольше 50дс
#define GIANT_SPIDER_SKITTER_TIME (5 SECONDS)
///Легаси-радиус перебежки: pick(urange(20, src, 1))
#define GIANT_SPIDER_SKITTER_RANGE 20
///Дедлайн текущей перебежки (world.time)
#define BB_SPIDER_SKITTER_UNTIL "BB_spider_skitter_until"

///Профиль обычного паука: мили-погоня + случайные перебежки
/datum/ai_controller/hostile_adapter/melee_chaser/giant_spider
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/spider_idle_skitter,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_dodge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

///Профиль няньки: цикл коконов важнее перебежек, бой важнее всего
/datum/ai_controller/hostile_adapter/melee_chaser/giant_spider/nurse
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/spider_nurse_cycle,
		/datum/ai_planning_subtree/spider_idle_skitter,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_dodge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/take_cover_when_pinned,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)

// ===== Перебежка (idle-skitter) =====

///Случайная перебежка: без цели, без занятости, легаси-шанс. Сабтри стоит
///ПЕРЕД hostile_fsm: начатую перебежку он удерживает в плане (FINISH), чтобы
///патруль-возврат FSM не отменял её на полпути.
/datum/ai_planning_subtree/spider_idle_skitter

/datum/ai_planning_subtree/spider_idle_skitter/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/giant_spider/spider = controller.pawn
	if(!istype(spider))
		return
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		return
	//дожать начатую перебежку: держим поведение в плане до дедлайна
	if(world.time < (controller.blackboard[BB_SPIDER_SKITTER_UNTIL] || 0))
		controller.queue_behavior(/datum/ai_behavior/spider_skitter)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(spider.busy) //легаси: перебежка только когда паук ничем не занят
		return
	if(!SPT_PROB(GIANT_SPIDER_SKITTER_PROB_PER_SECOND, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/spider_skitter)
	return SUBTREE_RETURN_FINISH_PLANNING

///Сама перебежка: бросок к случайной точке в радиусе 20 не дольше 5 секунд
///(легаси Goto + таймер resume_spider_movement)
/datum/ai_behavior/spider_skitter
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 0
	action_cooldown = 1 SECONDS

/datum/ai_behavior/spider_skitter/setup(datum/ai_controller/controller)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/giant_spider/spider = controller.pawn
	if(!istype(spider))
		return FALSE
	//легаси-выбор точки: pick(urange(20, src, 1)) мог вернуть и атом - берём его турф
	var/turf/destination = get_turf(pick(urange(GIANT_SPIDER_SKITTER_RANGE, spider, 1)))
	if(!destination)
		return FALSE
	controller.blackboard[BB_SPIDER_SKITTER_UNTIL] = world.time + GIANT_SPIDER_SKITTER_TIME
	set_movement_target(controller, destination)

/datum/ai_behavior/spider_skitter/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/poison/giant_spider/spider = controller.pawn
	if(!istype(spider))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(world.time >= (controller.blackboard[BB_SPIDER_SKITTER_UNTIL] || 0) || get_turf(spider) == controller.current_movement_target)
		//перебежка окончена: как легаси-разбредание, новое место становится
		//домом - мирный якорь переезжает (следующий idle-тик поставит его здесь)
		controller.clear_blackboard_key(BB_AI_PATROL_ANCHOR)
		controller.blackboard[BB_AI_PATROL_RETURN_FAILS] = 0
		controller.clear_blackboard_key(BB_AI_PATROL_RETURN_FROM)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_INSTANT //ещё бежим

/datum/ai_behavior/spider_skitter/finish_action(datum/ai_controller/controller, succeeded)
	. = ..()
	controller.blackboard[BB_SPIDER_SKITTER_UNTIL] = null

// ===== Цикл няньки =====

///Цикл няньки: работает строго без боевой цели. Стоит ПЕРЕД hostile_fsm, чтобы
///подход к кокону (может быть за мирным поводком) не отменялся патруль-возвратом.
/datum/ai_planning_subtree/spider_nurse_cycle

/datum/ai_planning_subtree/spider_nurse_cycle/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/nurse = controller.pawn
	if(!istype(nurse))
		return
	if(controller.blackboard_key_exists(BB_AI_CURRENT_TARGET))
		//бой прерывает плетение, как легаси-else (сброс busy при активном AI);
		//cocoon_target не трогаем - его чистит легаси-таймер GiveUp
		if(nurse.busy)
			nurse.busy = SPIDER_IDLE
			nurse.stop_automated_movement = FALSE
		return
	switch(nurse.busy)
		if(SPINNING_WEB, LAYING_EGGS, SPINNING_COCOON)
			//легаси do_after в процессе: не мешаем и не бродим
			return SUBTREE_RETURN_FINISH_PLANNING
		if(MOVING_TO_TARGET)
			if(QDELETED(nurse.cocoon_target))
				return //GiveUp/чужой сброс докрутит состояние сам
			controller.queue_behavior(/datum/ai_behavior/spider_wrap_target)
			return SUBTREE_RETURN_FINISH_PLANNING
	if(!SPT_PROB(GIANT_SPIDER_NURSE_PROB_PER_SECOND, delta_time))
		return
	controller.queue_behavior(/datum/ai_behavior/spider_nurse_weave)
	return SUBTREE_RETURN_FINISH_PLANNING

///Решение няньки - легаси-приоритеты в том же порядке: кокон беспомощного ->
///паутина на своём турфе -> кладка яиц (если сыта) -> обмотка предмета.
///Сообщения и do_after идут делегацией легаси-прокам.
/datum/ai_behavior/spider_nurse_weave
	action_cooldown = 2 SECONDS

/datum/ai_behavior/spider_nurse_weave/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/nurse = controller.pawn
	if(!istype(nurse) || nurse.busy || nurse.stat == DEAD)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/list/can_see = view(nurse, 10)
	//first, check for potential food nearby to cocoon
	for(var/mob/living/C in can_see)
		if(C.stat && !istype(C, /mob/living/simple_animal/hostile/poison/giant_spider) && !C.anchored)
			nurse.cocoon_target = C
			nurse.busy = MOVING_TO_TARGET
			//give up if we can't reach them after 10 seconds (легаси-таймер)
			nurse.GiveUp(C)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	//second, spin a sticky spiderweb on this tile
	var/obj/structure/spider/stickyweb/W = locate() in get_turf(nurse)
	if(!W)
		//Activate спит в do_after - детачимся
		INVOKE_ASYNC(nurse.lay_web, TYPE_PROC_REF(/datum/action/innate, Activate))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	//third, lay an egg cluster there
	if(nurse.fed)
		INVOKE_ASYNC(nurse.lay_eggs, TYPE_PROC_REF(/datum/action/innate, Activate))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	//fourthly, cocoon any nearby items so those pesky pinkskins can't use them
	for(var/obj/O in can_see)
		if(O.anchored)
			continue
		if(isitem(O) || isstructure(O) || ismachinery(O))
			nurse.cocoon_target = O
			nurse.busy = MOVING_TO_TARGET
			nurse.stop_automated_movement = TRUE
			nurse.GiveUp(O)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

///Подход к цели кокона и обмотка вплотную (легаси-порог get_dist <= 1;
///cocoon() сам перепроверит Adjacent и отыграет сообщения/do_after)
/datum/ai_behavior/spider_wrap_target
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1
	action_cooldown = 1 SECONDS

/datum/ai_behavior/spider_wrap_target/setup(datum/ai_controller/controller)
	. = ..()
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/nurse = controller.pawn
	if(!istype(nurse) || QDELETED(nurse.cocoon_target))
		return FALSE
	set_movement_target(controller, nurse.cocoon_target)

/datum/ai_behavior/spider_wrap_target/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/simple_animal/hostile/poison/giant_spider/nurse/nurse = controller.pawn
	if(!istype(nurse) || nurse.busy != MOVING_TO_TARGET || QDELETED(nurse.cocoon_target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(get_dist(nurse, nurse.cocoon_target) <= 1)
		//cocoon() спит в do_after - детачимся, как милишка от MeleeAction
		INVOKE_ASYNC(nurse, TYPE_PROC_REF(/mob/living/simple_animal/hostile/poison/giant_spider/nurse, cocoon))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_INSTANT //ещё идём

#undef GIANT_SPIDER_SKITTER_PROB_PER_SECOND
#undef GIANT_SPIDER_NURSE_PROB_PER_SECOND
#undef GIANT_SPIDER_SKITTER_TIME
#undef GIANT_SPIDER_SKITTER_RANGE

#undef SPIDER_IDLE
#undef SPINNING_WEB
#undef LAYING_EGGS
#undef MOVING_TO_TARGET
#undef SPINNING_COCOON
