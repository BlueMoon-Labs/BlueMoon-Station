/obj/effect/proc_holder/spell/self/heretic_hammer
	clothes_req = FALSE
	invocation_type = "none"
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/self/heretic_hammer/proc/hammer_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)

/obj/effect/proc_holder/spell/self/heretic_hammer/can_cast(mob/user, skipcharge, silent)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	return ..() && heretic_check(user, hammer?.can_use(user, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/self/heretic_hammer/swing
	name = "Замах"
	desc = "Только Молотом изнанки в двух руках. Секунду Молот поднят над головой: идти можно, но медленнее, а опустив Молот, вы сорвёте замах. Затем 4 секунды следующий удар в двух руках - Сокрушающий: +20 урона и полёт цели на 3 клетки; врезавшись в стену, преграду или другого, она падает на 1,5 секунды и получает ещё 12, второй тоже падает. Сокрушающий удар даёт Накал. Перезарядка 4 секунды."
	summary = "Секунда замаха, затем удар в двух руках - Сокрушающий: +20 урона, полёт на 3 клетки."
	charge_max = HERETIC_HAMMER_SWING_COOLDOWN
	action_icon_state = "hammer_swing"

/obj/effect/proc_holder/spell/self/heretic_hammer/swing/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	var/reason = hammer.swing_block_reason(user)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_hammer/swing/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!hammer?.swing(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/self/heretic_hammer/quake
	name = "Сотрясение"
	desc = "За 3 Накала, только Молотом в двух руках: 0,6 секунды замаха, затем удар в пол. Враги рядом с вами падают на секунду и получают 15 урона, а в 2-3 клетках теряют 25 выносливости, отлетают на клетку и 2 секунды идут медленнее. Пол вокруг идёт трещинами на 20 секунд. Опустите Молот во время замаха - удар сорвётся, Накал не вернётся. Перезарядка 12 секунд."
	summary = "За 3 Накала удар в пол: рядом падение и 15 урона, в 3 клетках выносливость и отброс."
	charge_max = HERETIC_HAMMER_QUAKE_COOLDOWN
	action_icon_state = "hammer_quake"

/obj/effect/proc_holder/spell/self/heretic_hammer/quake/can_cast(mob/user, skipcharge, silent)
	if(!..())
		return FALSE
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	var/reason = hammer.wielded_cost_reason(user, HERETIC_HAMMER_QUAKE_COST, "Сотрясение")
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/self/heretic_hammer/quake/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!hammer?.quake(user))
		heretic_revert_cast(user)

/obj/effect/proc_holder/spell/pointed/heretic_hammer
	clothes_req = FALSE
	invocation_type = "none"
	selection_type = "view"
	aim_assist = FALSE
	heretic_stun_check = TRUE
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	active_msg = "Наведите прицел."
	deactive_msg = "Вы опускаете Молот."

/obj/effect/proc_holder/spell/pointed/heretic_hammer/proc/hammer_of(mob/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/can_cast(mob/user, skipcharge, silent)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	return ..() && heretic_check(user, hammer?.can_use(user, usable_while_grabbed), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_hammer/ram
	name = "Таран"
	desc = "За 2 Накала, а раз в 30 секунд даром, рвануть с Молотом изнанки в руке до 5 клеток по прямой в сторону клика. Рывок срывает с вас любую хватку, даже крепкую, но не наручники. Первое препятствие на пути он проламывает: окно, решётку, стол и балку сносит и летит дальше, обычную стену обрушает до балки, шлюз, винтдор и пожарную дверь бьёт и распахивает, если они не заварены и не на болтах, а бронестворки и ставни только бьёт. Укреплённая стена, машины, корпус шаттла и всё, за чем космос, останавливают; упёрлись сразу - Накал и даровой рывок целы. Первого врага на пути Таран валит на 1,5 секунды и отбрасывает вбок, вбитого в пол - выдёргивает. Перезарядка 6 секунд."
	summary = "За 2 Накала или даром раз в 30 секунд рывок на 5 клеток сквозь шлюз, окно или стену; рвёт хватку."
	charge_max = HERETIC_HAMMER_RAM_COOLDOWN
	range = 7
	usable_while_grabbed = TRUE
	action_icon_state = "hammer_ram"

/obj/effect/proc_holder/spell/pointed/heretic_hammer/ram/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	var/reason = hammer ? hammer.ram_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/ram/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!length(targets) || !hammer?.ram(user, targets[1]))
		heretic_revert_cast(user, hammer?.hammer_failure)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/anvil
	name = "Наковальня с неба"
	desc = "За 3 Накала выберите видимую клетку пола не дальше 7 клеток. 1,2 секунды на ней растёт тень, затем с потолка падает наковальня: тот, кто стоит на клетке, получает 35 урона и падает на 2 секунды, соседи теряют 10 выносливости. Наковальня 15 секунд стоит плотной преградой, её можно разбить. Тень видят все: из-под неё можно уйти. Молот для броска не нужен. Перезарядка 15 секунд."
	summary = "За 3 Накала через 1,2 секунды наковальня на клетку в 7: 35 урона и падение; стоит 15 секунд."
	charge_max = HERETIC_HAMMER_ANVIL_COOLDOWN
	range = HERETIC_HAMMER_ANVIL_RANGE
	aim_assist = TRUE
	aim_assist_turf = TRUE
	action_icon_state = "hammer_anvil"

/obj/effect/proc_holder/spell/pointed/heretic_hammer/anvil/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	var/reason = hammer ? hammer.anvil_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/anvil/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!length(targets) || !hammer?.drop_anvil(user, targets[1]))
		heretic_revert_cast(user, hammer?.hammer_failure)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/fissure
	name = "Раскол"
	desc = "За 4 Накала, только Молотом в двух руках: 0,8 секунды замаха, затем трещина бежит от вас по прямой на 6 клеток в сторону клика. Каждый враг на линии падает на 1,5 секунды и получает 20 урона, плитка пола по линии ломается до обшивки, обшивка цела. Стена или плотная преграда останавливает трещину. Опустите Молот во время замаха - удар сорвётся. Перезарядка 25 секунд."
	summary = "За 4 Накала трещина на 6 клеток: каждый на линии падает на 1,5 секунды и получает 20 урона."
	charge_max = HERETIC_HAMMER_FISSURE_COOLDOWN
	range = 7
	aim_assist = TRUE
	aim_assist_turf = TRUE
	action_icon_state = "hammer_fissure"

/obj/effect/proc_holder/spell/pointed/heretic_hammer/fissure/can_target(atom/target, mob/user, silent)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	var/reason = hammer ? hammer.wielded_cost_reason(user, HERETIC_HAMMER_FISSURE_COST, "Раскол") : "Способность недоступна вашему пути или текущему телу."
	if(!reason && !heretic_hammer_aim_dir(user, target))
		reason = "Укажите направление: трещина бежит от вас."
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/heretic_hammer/fissure/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_hammer/hammer = hammer_of(user)
	if(!length(targets) || !hammer?.fissure(user, targets[1]))
		heretic_revert_cast(user, hammer?.hammer_failure)

/datum/eldritch_knowledge/base_hammer
	var/hammer_failure

/datum/eldritch_knowledge/base_hammer/proc/wielded_cost_reason(mob/living/user, cost, what)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	if(!heretic_hammer_held(user, TRUE))
		return "[what] - только Молотом изнанки в двух руках: возьмите его и активируйте в руке."
	if(combat_resource < cost)
		return "Нужно [cost] Накала, сейчас [combat_resource]."
	return null

/datum/eldritch_knowledge/base_hammer/proc/ram_block_reason(mob/living/user, atom/target)
	if(!can_use(user, TRUE))
		return "Способность недоступна вашему пути или текущему телу."
	if(!heretic_hammer_held(user))
		return "Таран - только с Молотом изнанки в руке."
	if(!heretic_hammer_aim_dir(user, target))
		return "Укажите направление рывка."
	if(!COOLDOWN_FINISHED(src, free_ram) && combat_resource < HERETIC_HAMMER_RAM_COST)
		return "Нужно [HERETIC_HAMMER_RAM_COST] Накала, сейчас [combat_resource]; даром Таран будет через [DisplayTimeText(COOLDOWN_TIMELEFT(src, free_ram), 1)]."
	return null

#define HERETIC_HAMMER_RAM_CLEAR 1
#define HERETIC_HAMMER_RAM_STOP 2
#define HERETIC_HAMMER_RAM_BLOCKED 3

/// Таран: рывок по прямой; первое препятствие проламывается, первого врага валит.
/datum/eldritch_knowledge/base_hammer/proc/ram(mob/living/user, atom/target)
	hammer_failure = ram_block_reason(user, target)
	if(hammer_failure)
		return FALSE
	var/direction = heretic_hammer_aim_dir(user, target)
	var/free = COOLDOWN_FINISHED(src, free_ram)
	var/broke_free = FALSE
	if(user.pulledby)
		var/mob/living/holder = user.pulledby
		holder.stop_pulling()
		broke_free = TRUE
		user.visible_message(span_danger("[user] рвётся из хватки [holder]!"))
	var/smashed = FALSE
	var/hit = FALSE
	var/moved = 0
	for(var/step in 1 to HERETIC_HAMMER_RAM_RANGE)
		var/turf/next = get_step(user, direction)
		if(!next || isgroundlessturf(next))
			break
		if(!smashed)
			var/result = ram_smash(user, next, direction)
			if(result == HERETIC_HAMMER_RAM_BLOCKED)
				break
			if(result)
				smashed = TRUE
				if(result == HERETIC_HAMMER_RAM_STOP)
					break
		var/blocked = FALSE
		for(var/mob/living/blocker in next)
			var/datum/status_effect/heretic_hammer_nailed/nail = blocker.has_status_effect(/datum/status_effect/heretic_hammer_nailed)
			nail?.free("вас выдернул Таран", "[blocker.ru_ego()] выдернул Таран")
			if(hit || blocker == user || !heretic_can_affect(user, blocker, chargecost = 0, notify = FALSE))
				blocked = blocked || blocker.density
				continue
			hit = TRUE
			blocker.Knockdown(HERETIC_HAMMER_RAM_KNOCKDOWN)
			shake_camera(blocker, 2, 2)
			blocker.visible_message(span_danger("[user] сносит [blocker] с ног!"), span_userdanger("[user] сносит вас с ног!"))
			log_combat(user, blocker, "сбивает Тараном")
			if(heretic_hammer_movable(blocker))
				blocker.Move(get_step(blocker, turn(direction, pick(90, -90))))
			lesson_event("ram_hit", blocker)
		if(blocked || !user.Move(next, direction))
			break
		moved++
	if(!moved && !smashed && !hit && !broke_free)
		hammer_failure = "Путь закрыт: Таран упёрся в то, что не проломить. Накал и даровой рывок целы."
		return FALSE
	heretic_hammer_sound(user, "ram", 60, TRUE)
	if(free)
		COOLDOWN_START(src, free_ram, HERETIC_HAMMER_RAM_FREE_COOLDOWN)
	else
		spend_combat_resource(HERETIC_HAMMER_RAM_COST)
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	new /obj/effect/temp_visual/heretic_hammer/wall_impact(get_turf(user))
	shake_camera(user, 1, 1)
	log_combat(user, user, "бросается Тараном на [moved] клеток[free ? " даром" : ""]")
	lesson_event("ram", user, moved)
	return TRUE

/// Клетка снаружи: пустота, пропасть, лава или улица.
/proc/heretic_hammer_outside(turf/place)
	if(!place || isgroundlessturf(place))
		return TRUE
	var/area/zone = get_area(place)
	return zone.outdoors

/// Пролом в hole открыл бы станцию наружу: снаружи сама клетка или любая её соседка, кроме той, откуда бьют.
/proc/heretic_hammer_breach_unsafe(turf/hole, turf/from)
	if(heretic_hammer_outside(hole))
		return TRUE
	for(var/direction in GLOB.cardinals)
		var/turf/side = get_step(hole, direction)
		if(side != from && heretic_hammer_outside(side))
			return TRUE
	return FALSE

/// Корпус шаттла и спасательной капсулы Таран не ломает.
/proc/heretic_hammer_shuttle_hull(atom/obstacle)
	if(istype(get_area(obstacle), /area/shuttle))
		return TRUE
	return istype(obstacle, /turf/closed/wall/mineral/titanium) || istype(obstacle, /turf/closed/wall/mineral/plastitanium) || istype(obstacle, /obj/structure/window/shuttle) || istype(obstacle, /obj/structure/window/plastitanium)

/// Двери, которые Таран распахивает: шлюз и винтдор сами проверяют болты и сварку, пожарная - только незаваренная.
/proc/heretic_hammer_ram_opens(obj/machinery/door/door)
	if(istype(door, /obj/machinery/door/airlock) || istype(door, /obj/machinery/door/window))
		return TRUE
	return istype(door, /obj/machinery/door/firedoor) && !door.welded

/datum/eldritch_knowledge/base_hammer/proc/ram_door(mob/living/user, obj/machinery/door/door, turf/next, unsafe)
	if((door.resistance_flags & INDESTRUCTIBLE) || unsafe)
		return HERETIC_HAMMER_RAM_BLOCKED
	heretic_hammer_sound(next, "ram_smash", 70, TRUE)
	door.take_damage(HERETIC_HAMMER_RAM_DOOR_DAMAGE, BRUTE, MELEE, FALSE)
	if(!QDELETED(door) && door.density && heretic_hammer_ram_opens(door))
		INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open), 2)
	log_game("[key_name(user)] бьёт Тараном [door] в [AREACOORD(door)].")
	return HERETIC_HAMMER_RAM_STOP

/// Первое препятствие Тарана: CLEAR - снёс и летит дальше, STOP - проломил и встал, BLOCKED - не тронул, null - ломать нечего.
/datum/eldritch_knowledge/base_hammer/proc/ram_smash(mob/living/user, turf/next, direction)
	var/turf/here = get_turf(user)
	for(var/obj/machinery/door/edge_door in here)
		if(edge_door.density && (edge_door.flags_1 & ON_BORDER_1) && (edge_door.dir & direction))
			return ram_door(user, edge_door, next, heretic_hammer_outside(next))
	for(var/obj/structure/window/edge in here)
		if(!edge.fulltile && (edge.dir & direction))
			if((edge.resistance_flags & INDESTRUCTIBLE) || heretic_hammer_shuttle_hull(edge) || heretic_hammer_outside(next))
				return HERETIC_HAMMER_RAM_BLOCKED
			heretic_hammer_sound(next, "ram_smash", 70, TRUE)
			edge.deconstruct(FALSE)
			return HERETIC_HAMMER_RAM_CLEAR
	if(iswallturf(next))
		if(istype(next, /turf/closed/wall/r_wall) || heretic_hammer_shuttle_hull(next) || heretic_hammer_breach_unsafe(next, here))
			return HERETIC_HAMMER_RAM_BLOCKED
		var/turf/closed/wall/wall = next
		heretic_hammer_sound(next, "ram_smash", 70, TRUE)
		log_game("[key_name(user)] проламывает Тараном стену в [AREACOORD(next)].")
		wall.dismantle_wall()
		return HERETIC_HAMMER_RAM_STOP
	if(next.density)
		return HERETIC_HAMMER_RAM_BLOCKED
	for(var/obj/obstacle in next)
		if(!obstacle.density && !istype(obstacle, /obj/structure/window))
			continue
		if(istype(obstacle, /obj/machinery/door) && (obstacle.flags_1 & ON_BORDER_1) && !(obstacle.dir & turn(direction, 180)))
			continue
		var/edge_only = FALSE
		if(istype(obstacle, /obj/structure/window))
			var/obj/structure/window/window = obstacle
			if(!window.fulltile && !(window.dir & turn(direction, 180)))
				continue
			edge_only = !window.fulltile
		if(obstacle.resistance_flags & INDESTRUCTIBLE)
			return HERETIC_HAMMER_RAM_BLOCKED
		if(istype(obstacle, /obj/machinery/door))
			return ram_door(user, obstacle, next, heretic_hammer_breach_unsafe(next, here))
		if(istype(obstacle, /obj/structure/window) || istype(obstacle, /obj/structure/grille))
			if(heretic_hammer_shuttle_hull(obstacle) || (edge_only ? heretic_hammer_outside(next) : heretic_hammer_breach_unsafe(next, here)))
				return HERETIC_HAMMER_RAM_BLOCKED
		if(istype(obstacle, /obj/structure/window) || istype(obstacle, /obj/structure/grille) || istype(obstacle, /obj/structure/table) || istype(obstacle, /obj/structure/girder))
			heretic_hammer_sound(next, "ram_smash", 70, TRUE)
			log_game("[key_name(user)] сносит Тараном [obstacle] в [AREACOORD(next)].")
			obstacle.deconstruct(FALSE)
			for(var/obj/structure/window/other in next)
				if((other.fulltile || (other.dir & turn(direction, 180))) && !(other.resistance_flags & INDESTRUCTIBLE))
					other.deconstruct(FALSE)
			return HERETIC_HAMMER_RAM_CLEAR
		return HERETIC_HAMMER_RAM_BLOCKED
	return null

#undef HERETIC_HAMMER_RAM_CLEAR
#undef HERETIC_HAMMER_RAM_STOP
#undef HERETIC_HAMMER_RAM_BLOCKED

/// Почему отложенный удар сорвался в момент удара.
/datum/eldritch_knowledge/base_hammer/proc/strike_break_reason(mob/living/user)
	if(user != hammer_body || !owner_heretic())
		return "сила пути недоступна этому телу"
	if(heretic_incapacitated(user))
		return user.restrained() ? "вас связали или держат" : "вас сбили или оглушили"
	if(!isturf(user.loc))
		return "под вами нет пола"
	return "Молот должен быть в двух руках"

/datum/eldritch_knowledge/base_hammer/proc/quake(mob/living/user)
	if(wielded_cost_reason(user, HERETIC_HAMMER_QUAKE_COST, "Сотрясение") || !spend_combat_resource(HERETIC_HAMMER_QUAKE_COST))
		return FALSE
	user.visible_message(span_warning("[user] вскидывает молот, чтобы ударить в пол!"), span_notice("Вы вскидываете Молот."))
	heretic_hammer_sound(user, "windup", 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(quake_strike), WEAKREF(user)), HERETIC_HAMMER_QUAKE_WINDUP)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/quake_strike(datum/weakref/user_ref)
	var/mob/living/user = user_ref?.resolve()
	if(!user || !can_use(user) || !heretic_hammer_held(user, TRUE))
		if(user)
			to_chat(user, span_warning("Сотрясение сорвалось: [strike_break_reason(user)]."))
		return FALSE
	var/turf/center = get_turf(user)
	heretic_hammer_sound(center, "quake", 80, TRUE, 3)
	new /obj/effect/temp_visual/heretic_hammer/quake_ring(center)
	for(var/turf/open/floor in range(1, center))
		new /obj/effect/temp_visual/heretic_hammer/floor_crack(floor)
	shake_camera(user, 2, 1)
	for(var/mob/living/victim in range(HERETIC_HAMMER_QUAKE_RANGE, center))
		if(victim == user || victim.stat == DEAD || !heretic_hammer_reaches(center, victim) || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			continue
		shake_camera(victim, 3, 2)
		if(get_dist(center, victim) <= 1)
			victim.apply_damage(HERETIC_HAMMER_QUAKE_NEAR_DAMAGE, BRUTE)
			victim.Knockdown(HERETIC_HAMMER_QUAKE_NEAR_KNOCKDOWN)
		else
			victim.adjustStaminaLoss(HERETIC_HAMMER_QUAKE_STAMINA)
			victim.apply_status_effect(/datum/status_effect/heretic_hammer_dazed)
			if(heretic_hammer_movable(victim) && !victim.has_status_effect(/datum/status_effect/heretic_hammer_nailed))
				victim.Move(get_step(victim, get_dir(center, victim)), get_dir(center, victim))
		log_combat(user, victim, "бьёт Сотрясением")
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	user.visible_message(span_danger("[user] обрушивает молот в пол, и палуба вздрагивает!"))
	lesson_event("quake", user)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/anvil_block_reason(mob/living/user, atom/target)
	if(!can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	var/turf/place = get_turf(target)
	if(!isopenturf(place) || isgroundlessturf(place))
		return "Наковальне нужен пол."
	if(place.z != user.z || get_dist(user, place) > HERETIC_HAMMER_ANVIL_RANGE)
		return "Наковальня падает не дальше [HERETIC_HAMMER_ANVIL_RANGE] клеток."
	if(!(place in view(HERETIC_HAMMER_ANVIL_RANGE, user)))
		return "Клетку надо видеть."
	if(locate(/obj/structure/heretic_hammer_anvil) in place)
		return "Там уже стоит наковальня."
	if(combat_resource < HERETIC_HAMMER_ANVIL_COST)
		return "Нужно [HERETIC_HAMMER_ANVIL_COST] Накала, сейчас [combat_resource]."
	return null

/datum/eldritch_knowledge/base_hammer/proc/drop_anvil(mob/living/user, atom/target)
	hammer_failure = anvil_block_reason(user, target)
	if(hammer_failure || !spend_combat_resource(HERETIC_HAMMER_ANVIL_COST))
		return FALSE
	var/turf/place = get_turf(target)
	new /obj/effect/temp_visual/heretic_hammer/anvil_shadow(place)
	heretic_hammer_sound(place, "anvil_fall", 60, TRUE, 2)
	addtimer(CALLBACK(src, PROC_REF(anvil_land), WEAKREF(user), place), HERETIC_HAMMER_ANVIL_TELEGRAPH)
	log_combat(user, user, "бросает Наковальню с неба в [AREACOORD(place)]")
	lesson_event("anvil_cast", place)
	return TRUE

/datum/eldritch_knowledge/base_hammer/proc/anvil_land(datum/weakref/user_ref, turf/place)
	var/mob/living/user = user_ref?.resolve()
	if(QDELETED(src) || !place)
		return
	heretic_hammer_sound(place, "anvil_land", 80, TRUE, 3)
	new /obj/effect/temp_visual/heretic_hammer/anvil_land(place)
	for(var/mob/living/victim in range(1, place))
		if(victim == user || victim.stat == DEAD || !heretic_hammer_reaches(place, victim) || (user && !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE)))
			continue
		shake_camera(victim, 3, 2)
		if(get_turf(victim) == place)
			victim.apply_damage(HERETIC_HAMMER_ANVIL_DAMAGE, BRUTE, BODY_ZONE_HEAD)
			victim.Knockdown(HERETIC_HAMMER_ANVIL_KNOCKDOWN)
			victim.visible_message(span_danger("На [victim] с потолка рушится наковальня!"), span_userdanger("На вас падает наковальня!"))
			if(user)
				log_combat(user, victim, "роняет Наковальню с неба на")
			lesson_event("anvil_hit", victim)
		else
			victim.adjustStaminaLoss(HERETIC_HAMMER_ANVIL_SPLASH_STAMINA)
	if(!place.is_blocked_turf(exclude_mobs = TRUE))
		new /obj/structure/heretic_hammer_anvil(place)

/datum/eldritch_knowledge/base_hammer/proc/fissure(mob/living/user, atom/target)
	hammer_failure = wielded_cost_reason(user, HERETIC_HAMMER_FISSURE_COST, "Раскол")
	var/direction = heretic_hammer_aim_dir(user, target)
	if(!hammer_failure && !direction)
		hammer_failure = "Укажите направление: трещина бежит от вас."
	if(hammer_failure || !spend_combat_resource(HERETIC_HAMMER_FISSURE_COST))
		return FALSE
	user.visible_message(span_warning("[user] заносит молот, целясь в пол!"), span_notice("Вы заносите Молот."))
	heretic_hammer_sound(user, "windup", 50, TRUE)
	addtimer(CALLBACK(src, PROC_REF(fissure_strike), WEAKREF(user), direction), HERETIC_HAMMER_FISSURE_WINDUP)
	return TRUE

/// Плитку снимает до обшивки, только если под ней обшивка; иначе плитка трескается на месте, дыр в космос нет.
/proc/heretic_hammer_crack_tile(turf/open/floor/tile)
	if(istype(tile, /turf/open/floor/holofloor))
		return
	var/below = islist(tile.baseturfs) ? tile.baseturfs[length(tile.baseturfs)] : tile.baseturfs
	if(ispath(below, /turf/open/floor/plating))
		tile.break_tile_to_plating()
	else if(length(tile.broken_states))
		tile.break_tile()

/datum/eldritch_knowledge/base_hammer/proc/fissure_strike(datum/weakref/user_ref, direction)
	var/mob/living/user = user_ref?.resolve()
	if(!user || !can_use(user) || !heretic_hammer_held(user, TRUE))
		if(user)
			to_chat(user, span_warning("Раскол сорвался: [strike_break_reason(user)]."))
		return FALSE
	var/turf/origin = get_turf(user)
	heretic_hammer_sound(origin, "fissure", 80, TRUE, 3)
	shake_camera(user, 2, 1)
	cool_at = world.time + HERETIC_HAMMER_COOL_TIME
	user.visible_message(span_danger("[user] бьёт молотом в пол, и по палубе бежит трещина!"))
	fissure_step(user_ref, origin, direction, 1)
	return TRUE

/// Трещина доходит до следующей клетки: раскрывается, ломает плитку, валит тех, кто стоит там сейчас, и через шаг бежит дальше.
/datum/eldritch_knowledge/base_hammer/proc/fissure_step(datum/weakref/user_ref, turf/from, direction, step)
	var/mob/living/user = user_ref?.resolve()
	var/turf/current = get_step(from, direction)
	if(!user || !isopenturf(current) || current.is_blocked_turf(exclude_mobs = TRUE))
		if(user)
			lesson_event("fissure", user, step - 1)
		return
	var/obj/effect/temp_visual/heretic_hammer/fissure/crack = new(current)
	crack.setDir(direction)
	if(istype(current, /turf/open/floor) && !istype(current, /turf/open/floor/plating))
		heretic_hammer_crack_tile(current)
	for(var/mob/living/victim in current)
		if(victim.stat == DEAD || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			continue
		victim.apply_damage(HERETIC_HAMMER_FISSURE_DAMAGE, BRUTE)
		victim.Knockdown(HERETIC_HAMMER_FISSURE_KNOCKDOWN)
		shake_camera(victim, 3, 2)
		log_combat(user, victim, "бьёт Расколом")
		lesson_event("fissure_hit", victim)
	if(step >= HERETIC_HAMMER_FISSURE_LENGTH)
		lesson_event("fissure", user, step)
		return
	addtimer(CALLBACK(src, PROC_REF(fissure_step), user_ref, current, direction, step + 1), HERETIC_HAMMER_FISSURE_STEP_DELAY)

/datum/eldritch_knowledge/spell/hammer_ram
	name = "Таран"
	summary = "Рывок с Молотом на 5 клеток сквозь окно, шлюз или стену; рвёт хватку; 2 Накала или даром раз в 30 секунд."
	details = list(
		"Нужен Молот в руке, можно одной; рывок до 5 клеток по прямой в сторону клика, перезарядка 6 секунд.",
		"Срывает с вас любую хватку, даже крепкую; наручники и оглушение до вознесения не пускают.",
		"Окно, решётку, стол и балку сносит и летит дальше; обычную стену рушит до балки и встаёт.",
		"Шлюз, винтдор и пожарную дверь бьёт на 60 и распахивает, если не заварены и не на болтах; бронестворки только бьёт.",
		"Укреплённую стену, корпус шаттла и то, за чем космос, не ломает; упёрся сразу - Накал не тратится.",
		"Первого врага валит на 1,5 секунды и отбрасывает вбок; вбитого в пол выдёргивает.",
	)
	role = HERETIC_ROLE_ESCAPE
	gain_text = "Я перестал обходить стены. Стена - это просто металл, который ещё не понял, что он мой."
	cost = 1
	route = PATH_HAMMER
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_hammer/ram

/datum/eldritch_knowledge/hammer_nail
	name = "Вбить в пол"
	summary = "Молот в двух руках в «Схватить» по лежащему за 2 Накала вбивает его в пол на 12 секунд."
	details = list(
		"Цель должна лежать: сбейте её Сокрушающим ударом, Сотрясением, Тараном или Наковальней.",
		"Вбитый не встаёт, не ходит и не тащится никем, кроме вас; руки у него свободны.",
		"Член экипажа с ломом выдёргивает его за 3 секунды, растолкать можно за 2; удары растолкать мешают.",
		"Каждый ваш удар Молотом по вбитому сокращает вбивку на 2 секунды; тащить его можете только вы.",
		"Взрыв, Таран и нулевой жезл тоже освобождают; живое сердце уводит вбитого в изнанку.",
	)
	role = HERETIC_ROLE_CAPTURE
	gain_text = "Гвоздь не спорит с молотом. Человек, как оказалось, тоже."
	cost = 2
	route = PATH_HAMMER

/datum/eldritch_knowledge/hammer_nail/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	if(hammer)
		QDEL_LIST(hammer.nailed)

/datum/eldritch_knowledge/hammer_nail/proc/nail_block_reason(mob/living/user, mob/living/victim, datum/eldritch_knowledge/base_hammer/hammer)
	if(!hammer.can_use(user))
		return "Способность недоступна вашему пути или текущему телу."
	if(victim.stat == DEAD)
		return "Мёртвого вбивать незачем."
	if(victim.has_status_effect(/datum/status_effect/heretic_hammer_nailed))
		return "[victim] уже вбит в пол."
	if(!isturf(victim.loc) || victim.buckled)
		return "Вбить можно только того, кто лежит на полу."
	var/reason = heretic_capture_block_reason(user, victim, HERETIC_HAMMER_CAPTURE)
	if(reason)
		return reason
	if(!heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return "[victim] под защитой от магии."
	if(hammer.combat_resource < HERETIC_HAMMER_NAIL_COST)
		return "Нужно [HERETIC_HAMMER_NAIL_COST] Накала, сейчас [hammer.combat_resource]."
	return null

/// Удар в «Схватить» по лежащему: вбить в пол. FALSE - цель стоит, удар обычный.
/datum/eldritch_knowledge/hammer_nail/proc/try_nail(mob/living/user, mob/living/victim, datum/eldritch_knowledge/base_hammer/hammer, obj/item/melee/sickly_blade/hammer/weapon)
	if(!isliving(victim) || victim == user || !heretic_capture_downed(victim))
		return FALSE
	var/reason = nail_block_reason(user, victim, hammer)
	if(reason)
		to_chat(user, span_warning(reason))
		return TRUE
	user.do_attack_animation(victim)
	user.changeNext_move(weapon.attack_speed)
	if(!hammer.spend_combat_resource(HERETIC_HAMMER_NAIL_COST))
		return TRUE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_hammer_nailed, hammer))
		hammer.gain_combat_resource(HERETIC_HAMMER_NAIL_COST)
		return TRUE
	var/datum/antagonist/heretic/heretic = hammer.owner_heretic()
	heretic?.advance_combat_deed(victim, PATH_HAMMER)
	heretic_hammer_sound(victim, "nail", 70, TRUE, 2)
	shake_camera(victim, 3, 2)
	shake_camera(user, 2, 1)
	victim.visible_message(span_danger("[user] вбивает [victim] молотом в пол!"), span_userdanger("[user] вбивает вас молотом в пол: не встать!"))
	log_combat(user, victim, "вбивает Молотом в пол", weapon)
	hammer.lesson_event("nail", victim)
	return TRUE

/datum/eldritch_knowledge/spell/hammer_quake
	name = "Сотрясение"
	summary = "За 3 Накала удар Молотом в пол: рядом падение и 15 урона, в 3 клетках выносливость и отброс."
	details = list(
		"Только Молотом в двух руках; 0,6 секунды замаха, опущенный Молот срывает удар.",
		"Враги рядом падают на секунду и получают 15 урона.",
		"В 2-3 клетках - минус 25 выносливости, отброс на клетку и 2 секунды медленного шага.",
		"Стены, закрытые двери, окна и фальшстены держат волну; решётка и открытая дверь - нет.",
		"Пол вокруг идёт трещинами на 20 секунд. Перезарядка 12 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Я ударил не по врагу, а по полу под ним. Пол оказался честнее: он сразу признал удар."
	cost = 2
	route = PATH_HAMMER
	spell_to_add = /obj/effect/proc_holder/spell/self/heretic_hammer/quake

/datum/eldritch_knowledge/hammer_grasp
	name = "Хватка кузни"
	summary = "Хватка отбрасывает врага на 2 клетки; взяв Молот в две руки за 3 секунды, бьёте Сокрушающим."
	details = list(
		"Для Хватки Молот надо отпустить хотя бы одной рукой; Хватка по врагу всё так же даёт 2 Накала.",
		"Подхват: снова возьмите Молот в две руки за 3 секунды после Хватки - следующий удар Сокрушающий.",
		"Подхват держится 4 секунды и показан значком; Замах для этого не нужен.",
		"Отброс упирается в стены и двери: человек, врезавшись в стену, падает и получает 12 урона.",
		"Союзники и защита от магии отброс не принимают.",
	)
	role = HERETIC_ROLE_GRASP
	gain_text = "Отпустить молот - не слабость. Это вдох перед ударом."
	cost = 1
	route = PATH_HAMMER

/datum/eldritch_knowledge/hammer_grasp/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	if(!proximity_flag || !hammer?.can_use(user) || !isliving(target) || !isturf(target.loc) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	var/mob/living/smith = user
	smith.apply_status_effect(/datum/status_effect/heretic_hammer_catch)
	if(heretic_hammer_movable(victim) && !victim.has_status_effect(/datum/status_effect/heretic_hammer_nailed))
		var/turf/landing = get_ranged_target_turf(victim, get_dir(user, victim), HERETIC_HAMMER_GRASP_THROW)
		RegisterSignal(victim, COMSIG_MOVABLE_IMPACT, PROC_REF(on_throw_impact), TRUE)
		if(!victim.safe_throw_at(landing, HERETIC_HAMMER_GRASP_THROW, 1, user, force = MOVE_FORCE_STRONG, callback = CALLBACK(src, PROC_REF(throw_landed), victim)))
			UnregisterSignal(victim, COMSIG_MOVABLE_IMPACT)
	log_combat(user, victim, "отбрасывает Хваткой кузни")
	hammer.lesson_event("grasp_throw", victim)
	return TRUE

/datum/eldritch_knowledge/hammer_grasp/proc/throw_landed(mob/living/victim)
	if(!QDELETED(victim))
		UnregisterSignal(victim, COMSIG_MOVABLE_IMPACT)

/// Человек, отброшенный в стену или в другого, получает не меньше HERETIC_HAMMER_SLAM_DAMAGE, даже если лёгкому движок дал меньше.
/datum/eldritch_knowledge/hammer_grasp/proc/on_throw_impact(mob/living/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!heretic_hammer_own_throw(src, throwingdatum))
		UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
		return
	if(!heretic_hammer_engine_slam(source, hit_atom))
		return
	UnregisterSignal(source, COMSIG_MOVABLE_IMPACT)
	var/extra = heretic_hammer_slam_extra(source, hit_atom, throwingdatum)
	if(extra)
		source.apply_damage(extra, BRUTE)

/datum/eldritch_knowledge/hammer_grasp/on_body_lose(mob/living/user)
	user?.remove_status_effect(/datum/status_effect/heretic_hammer_catch)

/datum/eldritch_knowledge/hammer_mark
	name = "Звон наковальни"
	summary = "Хватка вешает Звон на 15 секунд; удары Молотом в двух руках дают трещины, третья раскалывает броню."
	details = list(
		"Хватка метку не взрывает: каждый удар Молотом в двух руках по меченому - трещина, до трёх.",
		"Третья трещина: 10 секунд броня цели против ударов, пуль и лазеров на 40 хуже, падение на секунду.",
		"Трещины видны на цели; удар одной рукой метку не трогает.",
		"Ответ на бронированную охрану: сначала Хватка, затем три удара.",
	)
	role = HERETIC_ROLE_MARK
	gain_text = "Броня - это тоже металл. А металл я слышу: он звенит перед тем, как треснуть."
	cost = 1
	route = PATH_HAMMER

/datum/eldritch_knowledge/hammer_mark/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	if(!proximity_flag || !hammer?.can_use(user) || !isliving(target) || !heretic_can_affect(user, target, chargecost = 0, notify = FALSE))
		return FALSE
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/eldritch/hammer, hammer)
	hammer.lesson_event("mark", victim)
	return TRUE

/datum/eldritch_knowledge/hammer_mark/on_body_lose(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	if(hammer)
		QDEL_LIST(hammer.marks)

/datum/eldritch_knowledge/spell/hammer_anvil
	name = "Наковальня с неба"
	summary = "За 3 Накала через 1,2 секунды на клетку в 7 падает наковальня: 35 урона и падение на 2 секунды."
	details = list(
		"Видимая клетка пола не дальше 7; Молот в руках не нужен - это единственный дальний удар пути.",
		"1,2 секунды на клетке растёт тень, её видят все: из-под неё можно уйти.",
		"Соседи теряют 10 выносливости, если их не прикрыла стена, закрытая дверь или окно.",
		"Сама наковальня 15 секунд стоит плотной преградой.",
		"Наковальню можно разбить: 100 прочности. Перезарядка 15 секунд.",
	)
	role = HERETIC_ROLE_ATTACK
	gain_text = "Кузня изнанки большая. И у неё есть лишние наковальни, которые тоже хотят работать."
	cost = 1
	route = PATH_HAMMER
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_hammer/anvil

/datum/eldritch_knowledge/hammer_unbroken
	name = "Несокрушимый"
	summary = "С Молотом в двух руках толчок и подкат не валят, Молот не выбить, урон выносливости по вам на 40% слабее."
	details = list(
		"Пока Молот в двух руках, толчок и подкат не сбивают с ног, а обезоруживание не выбивает Молот.",
		"Урон выносливости по вам на 40% слабее; одной рукой ничего из этого не работает.",
		"Ярость кузни: падение или паралич дольше секунды сокращаются до секунды падения и дают 3 Накала.",
		"Ярость приходит раз в 60 / 50 / 40 секунд по ступени улучшения.",
		"Оглушение и падение с Молотом в двух руках короче уже не на 30%, а на 50%.",
	)
	role = HERETIC_ROLE_DEFENSE
	gain_text = "Меня толкнули. Я не упал. Это было удивительно для нас обоих."
	cost = 2
	route = PATH_HAMMER
	passive_values = list(60 SECONDS, 50 SECONDS, 40 SECONDS)
	passive_desc = "Ярость кузни: раз в 60 / 50 / 40 секунд падение или паралич дольше секунды сокращаются до секунды падения и дают 3 Накала, пока Молот в двух руках."

/datum/eldritch_knowledge/hammer_unbroken/proc/rage_cooldown()
	return passive_values[clamp(passive_level, 1, length(passive_values))]

/datum/eldritch_knowledge/hammer_unbroken/on_body_gain(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	var/obj/item/melee/sickly_blade/hammer/held = heretic_hammer_held(user, TRUE)
	if(hammer && held && hammer.hammer_body == user)
		hammer.brace(held)

/datum/eldritch_knowledge/hammer_unbroken/on_lose(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_hammer/hammer = heretic?.get_knowledge(/datum/eldritch_knowledge/base_hammer)
	hammer?.unbrace()

/datum/eldritch_knowledge/spell/hammer_fissure
	name = "Раскол"
	summary = "За 4 Накала трещина на 6 клеток вперёд: каждый на линии падает на 1,5 секунды и получает 20 урона."
	details = list(
		"Только Молотом в двух руках; 0,8 секунды замаха, опущенный Молот срывает удар.",
		"Трещина бежит по прямой в сторону клика; стена или плотная преграда её останавливает.",
		"Плитка пола по линии ломается до обшивки; обшивка цела, дыр в космос нет.",
		"Перезарядка 25 секунд.",
	)
	role = HERETIC_ROLE_CONTROL
	gain_text = "Я ударил, и станция раскололась ровно туда, куда я смотрел. Она уже привыкает слушаться."
	cost = 2
	sacs_needed = HERETIC_PENULTIMATE_SACRIFICES
	route = PATH_HAMMER
	spell_to_add = /obj/effect/proc_holder/spell/pointed/heretic_hammer/fissure
