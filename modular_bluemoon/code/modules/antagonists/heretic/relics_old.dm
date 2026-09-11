/// Реликвии расходуют общий запас пути; смена предмета не обходит его задержку.
/obj/item/heretic_relic
	icon = 'modular_bluemoon/icons/obj/heretic_relics.dmi'
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_relics_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_relics_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	force = 5
	item_flags = NOBLUDGEON
	var/knowledge_type

/obj/item/heretic_relic/proc/get_path(mob/living/user, chargecost = 1)
	if(!isliving(user) || user.incapacitated() || !user.is_holding(src) || user.anti_magic_check(chargecost = chargecost))
		return null
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	return heretic?.get_knowledge(knowledge_type)

/obj/item/heretic_relic/censer
	name = "кадильница углей"
	desc = "Костяная кадильница с тлеющей пастью. Коснитесь горящего существа, чтобы погасить его и сохранить пламя (до трёх зарядов). Используйте в руке, чтобы после короткого замаха выдохнуть весь запас конусом на три клетки перед собой. Нужен один уголёк; между выдохами — 12 секунд."
	icon_state = "crucible_empty"
	knowledge_type = /datum/eldritch_knowledge/base_ash
	var/stored_fire = 0
	var/max_fire = 3

/obj/item/heretic_relic/censer/examine(mob/user)
	. = ..()
	. += span_notice("Сохранено пламени: [stored_fire] из [max_fire].")

/obj/item/heretic_relic/censer/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(proximity_flag && isliving(target))
		capture_fire(user, target)

/obj/item/heretic_relic/censer/proc/capture_fire(mob/living/user, mob/living/target)
	if(!get_path(user) || !user.Adjacent(target) || !target.on_fire || target.anti_magic_check() || stored_fire >= max_fire)
		return FALSE
	target.ExtinguishMob()
	stored_fire++
	icon_state = "crucible"
	user.update_inv_hands()
	set_light(2, 1, "#ff8633")
	new /obj/effect/temp_visual/heretic_oldpath/ash/trail(get_turf(target))
	playsound(src, 'sound/effects/wounds/sizzle1.ogg', 45, TRUE)
	return TRUE

/obj/item/heretic_relic/censer/attack_self(mob/living/user)
	if(!get_path(user) || !stored_fire)
		return
	user.visible_message(span_warning("[user] заносит [src]; из пасти кадильницы сыплются искры!"))
	new /obj/effect/temp_visual/heretic_oldpath/ash(get_turf(user))
	if(do_after(user, 0.8 SECONDS, target = user))
		release_fire(user)

/obj/item/heretic_relic/censer/proc/release_fire(mob/living/user)
	var/datum/eldritch_knowledge/path = get_path(user)
	if(!path || !stored_fire || !COOLDOWN_FINISHED(path, relic_cooldown) || !path.spend_combat_resource())
		return FALSE
	var/fire_strength = stored_fire
	stored_fire = 0
	icon_state = "crucible_empty"
	user.update_inv_hands()
	set_light(0)
	COOLDOWN_START(path, relic_cooldown, 12 SECONDS)
	var/direction = user.dir
	if(direction & NORTH)
		direction = NORTH
	else if(direction & SOUTH)
		direction = SOUTH
	for(var/turf/open/floor/floor in view(3, user))
		var/forward = (direction == NORTH || direction == SOUTH) ? abs(floor.y - user.y) : abs(floor.x - user.x)
		var/sideways = (direction == NORTH || direction == SOUTH) ? abs(floor.x - user.x) : abs(floor.y - user.y)
		if(!(get_dir(user, floor) & direction) || forward < 1 || sideways > round(forward / 2))
			continue
		new /obj/effect/temp_visual/heretic_oldpath/ash(floor)
		for(var/mob/living/victim in floor)
			if(!heretic_can_affect(user, victim))
				continue
			victim.adjustFireLoss(6 * fire_strength)
			victim.adjust_fire_stacks(fire_strength + 1)
			victim.IgniteMob()
	playsound(user, 'modular_bluemoon/sound/heretic/ash_burst.ogg', 75, TRUE)
	return TRUE

/obj/item/heretic_relic/rust_seed
	name = "семя ржавчины"
	desc = "Колючее семя с живыми корешками, пахнущее мокрым железом. Используйте в руке на открытом полу: за три секунды и один нарост оно прорастёт в разрушаемый очаг на минуту. Очаг распространяет ржавчину в области 5×5 и лечит вас и вашу свиту. У каждого хозяина может быть только один посаженный очаг."
	icon_state = "rust_seed"
	knowledge_type = /datum/eldritch_knowledge/base_rust

/obj/item/heretic_relic/rust_seed/attack_self(mob/living/user)
	if(!get_path(user) || !isfloorturf(user.loc))
		return
	user.visible_message(span_warning("[user] вдавливает [src] в пол. Из сердца тянутся ржавые корни."))
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(user))
	if(do_after(user, 3 SECONDS, target = user))
		plant(user)

/obj/item/heretic_relic/rust_seed/proc/plant(mob/living/user)
	var/datum/eldritch_knowledge/path = get_path(user)
	if(!path || !isfloorturf(user.loc) || (locate(/obj/structure/heretic_rust_heart) in user.loc))
		return FALSE
	if(!COOLDOWN_FINISHED(path, relic_cooldown) || !path.spend_combat_resource())
		return FALSE
	QDEL_NULL(path.rust_heart)
	COOLDOWN_START(path, relic_cooldown, 20 SECONDS)
	path.rust_heart = new(get_turf(user), user.mind, path)
	path.track_combat_effect(path.rust_heart)
	qdel(src)
	return TRUE

/obj/structure/heretic_rust_heart
	name = "укоренившееся сердце ржавчины"
	desc = "Вросший в пол очаг ржавчины. Пульсирующие корни кормят его хозяина и свиту. Уничтожение сердца немедленно гасит окружающую область; без хозяина оно тоже увядает."
	icon = 'modular_bluemoon/icons/obj/heretic_rust_heart.dmi'
	icon_state = "tumor"
	pixel_x = -16
	color = "#cfad7a"
	anchored = TRUE
	density = FALSE
	max_integrity = 90
	var/obj/effect/heretic_combat_zone/rust/rooted/zone

/obj/structure/heretic_rust_heart/Initialize(mapload, datum/mind/master, datum/eldritch_knowledge/path)
	. = ..()
	zone = new(get_turf(src), master)
	if(path)
		QDEL_NULL(path.relic_zone)
		path.relic_zone = zone
		path.track_combat_effect(zone)
	RegisterSignal(zone, COMSIG_PARENT_QDELETING, PROC_REF(on_zone_lost))
	playsound(src, 'sound/effects/clangsmall1.ogg', 70, TRUE)

/obj/structure/heretic_rust_heart/proc/on_zone_lost()
	SIGNAL_HANDLER
	zone = null
	qdel(src)

/obj/structure/heretic_rust_heart/Destroy()
	if(zone)
		UnregisterSignal(zone, COMSIG_PARENT_QDELETING)
		QDEL_NULL(zone)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(src))
	playsound(src, 'sound/effects/clangsmall2.ogg', 55, TRUE)
	return ..()

/obj/effect/heretic_combat_zone/rust/rooted
	duration = 60 SECONDS

/obj/item/heretic_relic/suture_needle
	name = "сшивающая игла"
	desc = "Инструмент, который сшивает воспоминание тела с его плотью. Коснитесь своего живого слуги: за три секунды и одну единицу биомассы вырастет одна утраченная рука или нога. Если конечности целы, инструмент остановит кровотечение. Не действует на посторонних и защищённых от магии; задержка — 10 секунд."
	icon_state = "suture_needle"
	knowledge_type = /datum/eldritch_knowledge/base_flesh

/obj/item/heretic_relic/suture_needle/proc/can_mend(mob/living/user, mob/living/carbon/target)
	if(!get_path(user) || !iscarbon(target) || !user.Adjacent(target) || target.stat == DEAD || target.anti_magic_check())
		return FALSE
	var/datum/antagonist/heretic_monster/servant = target.mind?.has_antag_datum(/datum/antagonist/heretic_monster)
	return servant?.master?.owner == user.mind

/obj/item/heretic_relic/suture_needle/afterattack(atom/target, mob/living/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag || !can_mend(user, target))
		return
	user.visible_message(span_warning("[user] протягивает алую нить от [src] к [target]."))
	user.Beam(target, icon_state = "drainbeam", time = 30)
	if(do_after(user, 3 SECONDS, target = target))
		mend_servant(user, target)

/obj/item/heretic_relic/suture_needle/proc/mend_servant(mob/living/user, mob/living/carbon/target)
	if(!can_mend(user, target))
		return FALSE
	var/datum/eldritch_knowledge/path = get_path(user)
	var/list/missing = target.get_missing_limbs(TRUE)
	var/needs_stitches = FALSE
	for(var/obj/item/bodypart/limb as anything in target.bodyparts)
		if(limb.generic_bleedstacks > 0)
			needs_stitches = TRUE
		for(var/datum/wound/wound as anything in limb.wounds)
			if(wound.blood_flow > 0)
				needs_stitches = TRUE
	if((!length(missing) && !needs_stitches) || !COOLDOWN_FINISHED(path, relic_cooldown) || !path.spend_combat_resource())
		return FALSE
	if(length(missing))
		if(!target.regenerate_limb(pick(missing)))
			path.gain_combat_resource()
			return FALSE
	else
		for(var/obj/item/bodypart/limb as anything in target.bodyparts)
			limb.generic_bleedstacks = 0
			for(var/datum/wound/wound as anything in limb.wounds)
				wound.blood_flow = 0
			limb.update_part_wound_overlay()
	COOLDOWN_START(path, relic_cooldown, 10 SECONDS)
	new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(target))
	playsound(target, 'sound/effects/wounds/blood2.ogg', 60, TRUE)
	return TRUE

/obj/item/heretic_relic/hush_lantern
	name = "фонарь тишины"
	desc = "За синим стеклом горит беззвучная зима. Используйте в руке: один осколок зимы питает на 15 секунд переносное поле 3×3, охлаждающее противников и лишающее их голоса. Поле видно на полу и гаснет, если выпустить фонарь. Между включениями — 25 секунд."
	icon_state = "lantern-blue"
	knowledge_type = /datum/eldritch_knowledge/base_void
	var/obj/effect/heretic_combat_zone/void/lantern/zone
	var/datum/weakref/holder

/obj/item/heretic_relic/hush_lantern/attack_self(mob/living/user)
	if(zone)
		deactivate()
		return
	activate(user)

/obj/item/heretic_relic/hush_lantern/proc/activate(mob/living/user)
	var/datum/eldritch_knowledge/path = get_path(user)
	if(!path || zone || !COOLDOWN_FINISHED(path, relic_cooldown) || !path.spend_combat_resource())
		return FALSE
	QDEL_NULL(path.relic_zone)
	zone = new(get_turf(user), user.mind)
	zone.lantern = WEAKREF(src)
	path.relic_zone = zone
	path.track_combat_effect(zone)
	RegisterSignal(zone, COMSIG_PARENT_QDELETING, PROC_REF(on_zone_lost))
	holder = WEAKREF(user)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_holder_moved))
	RegisterSignal(user, list(COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(on_holder_lost))
	COOLDOWN_START(path, relic_cooldown, 25 SECONDS)
	icon_state = "lantern-blue-on"
	user.update_inv_hands()
	set_light(3, 1, "#b9efff")
	new /obj/effect/temp_visual/heretic_oldpath/void(get_turf(user))
	playsound(user, pick('modular_bluemoon/sound/heretic/void_deflect1.ogg', 'modular_bluemoon/sound/heretic/void_deflect2.ogg'), 60, TRUE)
	return TRUE

/obj/item/heretic_relic/hush_lantern/proc/on_holder_moved(mob/living/source)
	SIGNAL_HANDLER
	if(!zone)
		return
	if(!source.is_holding(src) || !isturf(source.loc))
		deactivate()
		return
	zone.forceMove(get_turf(source))
	zone.refresh_boundary()
	// Передвижение освобождает вышедших из поля, но не ускоряет периодическое охлаждение.
	for(var/mob/living/departed as anything in zone.affected.Copy())
		if(QDELETED(departed) || !(departed.loc in zone.field_turfs))
			zone.release_affected(list(departed))

/obj/item/heretic_relic/hush_lantern/proc/on_holder_lost()
	SIGNAL_HANDLER
	deactivate()

/obj/item/heretic_relic/hush_lantern/proc/on_zone_lost()
	SIGNAL_HANDLER
	var/mob/living/user = holder?.resolve()
	if(user)
		UnregisterSignal(user, list(COMSIG_MOVABLE_MOVED, COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))
	holder = null
	zone = null
	icon_state = "lantern-blue"
	user?.update_inv_hands()
	set_light(0)

/obj/item/heretic_relic/hush_lantern/proc/deactivate()
	QDEL_NULL(zone)

/obj/item/heretic_relic/hush_lantern/dropped(mob/user, silent = FALSE)
	deactivate()
	return ..()

/obj/item/heretic_relic/hush_lantern/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!user.is_holding(src))
		deactivate()

/obj/item/heretic_relic/hush_lantern/Destroy()
	deactivate()
	return ..()

/obj/effect/heretic_combat_zone/void/lantern
	name = "беззвучная зима"
	radius = 1
	var/datum/weakref/lantern

/obj/effect/heretic_combat_zone/void/lantern/process()
	var/obj/item/heretic_relic/hush_lantern/source = lantern?.resolve()
	var/datum/mind/master = master_mind?.resolve()
	if(!source || !source.get_path(master?.current, chargecost = 0))
		qdel(src)
		return PROCESS_KILL
	return ..()

/obj/effect/heretic_combat_zone/void/lantern/Initialize(mapload, datum/mind/master)
	. = ..()
	// Переносной фонарь глушит голос; удержание противника остаётся задачей стационарной печати.
	zone_slowdown.multiplicative_slowdown = 0
