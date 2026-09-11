/// Запас силы принадлежит знанию и переживает смену тела.
/datum/eldritch_knowledge
	var/combat_resource = 1
	var/combat_resource_max = 4
	var/combat_resource_name = ""
	var/combat_resource_desc = ""
	var/combat_resource_action
	var/grasp_visual
	var/grasp_sound
	/// Обновления HUD следуют за ролью, а не за телом, в котором изучено знание.
	var/datum/weakref/combat_resource_owner
	var/obj/effect/proc_holder/spell/combat_power
	var/obj/effect/heretic_combat_zone/combat_zone
	var/obj/effect/heretic_combat_zone/relic_zone
	var/obj/structure/heretic_rust_heart/rust_heart
	COOLDOWN_DECLARE(resource_harvest)
	COOLDOWN_DECLARE(relic_cooldown)

/datum/eldritch_knowledge/proc/get_combat_resource_data()
	if(!combat_resource_name)
		return null
	return list("name" = combat_resource_name, "value" = combat_resource, "max" = combat_resource_max, "description" = combat_resource_desc)

/datum/eldritch_knowledge/proc/gain_combat_resource(amount = 1)
	var/previous = combat_resource
	combat_resource = clamp(combat_resource + amount, 0, combat_resource_max)
	if(combat_resource != previous)
		notify_resource_changed()

/datum/eldritch_knowledge/proc/spend_combat_resource(amount = 1)
	if(amount <= 0 || combat_resource < amount)
		return FALSE
	combat_resource -= amount
	notify_resource_changed()
	return TRUE

/datum/eldritch_knowledge/proc/notify_resource_changed()
	var/datum/antagonist/heretic/heretic = combat_resource_owner?.resolve()
	if(!QDELETED(heretic))
		heretic.update_combat_resource_alert(TRUE)
		heretic.refresh_book_ui()

/datum/eldritch_knowledge/proc/on_mark_detonated(mob/living/user, mob/living/target)
	if(combat_resource_name)
		gain_combat_resource()

/datum/eldritch_knowledge/proc/grant_combat_power(mob/living/user)
	if(!combat_resource_action || !user.mind || !QDELETED(combat_power))
		return
	combat_power = new combat_resource_action
	user.mind.AddSpell(combat_power)

/datum/eldritch_knowledge/proc/remove_combat_power()
	// Mind отслеживает удаление конкретного экземпляра через COMSIG_PARENT_QDELETING.
	QDEL_NULL(combat_power)
	QDEL_NULL(combat_zone)
	QDEL_NULL(rust_heart)
	QDEL_NULL(relic_zone)

/datum/eldritch_knowledge/proc/track_combat_effect(atom/effect)
	RegisterSignal(effect, COMSIG_PARENT_QDELETING, PROC_REF(on_combat_effect_deleted))

/datum/eldritch_knowledge/proc/on_combat_effect_deleted(atom/source)
	SIGNAL_HANDLER
	if(combat_zone == source)
		combat_zone = null
	if(relic_zone == source)
		relic_zone = null
	if(rust_heart == source)
		rust_heart = null
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)

/datum/eldritch_knowledge/Destroy()
	combat_resource_owner = null
	remove_combat_power()
	release_flesh_servants()
	return ..()

/// Единая проверка боевых эффектов: союзники и защита от магии остаются полезны на всех путях.
/proc/heretic_can_affect(mob/user, atom/target, chargecost = 1)
	if(!isliving(target) || target == user || QDELETED(target))
		return FALSE
	var/mob/living/victim = target
	return victim.stat != DEAD && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && !victim.anti_magic_check(chargecost = chargecost)

/datum/eldritch_knowledge/base_ash
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/ash
	grasp_sound = 'sound/effects/wounds/sizzle1.ogg'
	combat_resource_name = "Угольки"
	combat_resource_desc = "Активируйте метки клинком или схватите горящего противника. Угасание расходует уголёк: тушит вас, лечит ожоги и оставляет горящий след для отступления."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/ash

/datum/eldritch_knowledge/base_rust
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/rust
	grasp_sound = 'sound/effects/clangsmall1.ogg'
	combat_resource_name = "Наросты"
	combat_resource_desc = "Активируйте метки клинком или покройте новую поверхность ржавчиной хваткой (раз в 15 секунд). Укоренение расходует нарост и создаёт на 30 секунд ржавый очаг, лечащий вас и вашу свиту."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/rust

/datum/eldritch_knowledge/base_flesh
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/flesh
	grasp_sound = 'sound/effects/wounds/blood1.ogg'
	combat_resource_name = "Биомасса"
	combat_resource_desc = "Активируйте метки клинком или поглотите хваткой извлечённый орган. Сшивание расходует биомассу: лечит вас и ближайших слуг, ослабляет их кровотечение."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/flesh

/datum/eldritch_knowledge/base_void
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/void
	grasp_sound = 'modular_bluemoon/sound/heretic/void_deflect1.ogg'
	combat_resource_name = "Осколки зимы"
	combat_resource_desc = "Активируйте метки клинком или стойте на открытом полу холоднее нуля (раз в 20 секунд). Зимний предел расходует осколок и оставляет на 15 секунд область 5×5: враги в ней замедляются и теряют голос."
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/void

/datum/eldritch_knowledge/base_blade
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/blade
	grasp_sound = 'modular_bluemoon/sound/heretic/blade_grasp.ogg'

/datum/eldritch_knowledge/base_moon
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/moon
	grasp_sound = 'modular_bluemoon/sound/heretic/moon_grasp.ogg'

/datum/eldritch_knowledge/base_cosmic
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/cosmic
	grasp_sound = 'modular_bluemoon/sound/heretic/cosmic_energy.ogg'

/datum/eldritch_knowledge/base_ash/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_ash/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/base_rust/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_rust/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/base_flesh/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_flesh/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/base_void/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_void/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/base_flesh/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!istype(target, /obj/item/organ) || !isturf(target.loc) || combat_resource >= combat_resource_max)
		return FALSE
	gain_combat_resource()
	new /obj/effect/temp_visual/heretic_oldpath/flesh(get_turf(target))
	playsound(target, 'sound/effects/wounds/blood1.ogg', 50, TRUE)
	user.visible_message(span_warning("[user] растворяет [target] в багровой дымке."))
	qdel(target)
	return TRUE

/datum/eldritch_knowledge/base_void/on_life(mob/user)
	var/turf/open/floor/floor = get_turf(user)
	if(!istype(floor) || user.stat == DEAD || !COOLDOWN_FINISHED(src, resource_harvest) || floor.GetTemperature() >= T0C)
		return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, 20 SECONDS)

/obj/effect/proc_holder/spell/self/heretic_power
	clothes_req = FALSE
	invocation_type = "none"
	charge_max = 200
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_background_icon_state = "bg_ecult"
	var/knowledge_type

/obj/effect/proc_holder/spell/self/heretic_power/can_cast(mob/user, skipcharge, silent)
	if(!..() || !isliving(user))
		return FALSE
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/knowledge = heretic?.get_knowledge(knowledge_type)
	if(!knowledge || knowledge.combat_resource < 1)
		if(!silent)
			to_chat(user, span_warning("Недостаточно силы пути. Запас указан на индикаторе рядом с предупреждениями."))
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/self/heretic_power/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	var/datum/eldritch_knowledge/knowledge = heretic?.get_knowledge(knowledge_type)
	if(!knowledge || !knowledge.spend_combat_resource())
		return
	activate_power(user, knowledge)

/obj/effect/proc_holder/spell/self/heretic_power/proc/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	return

/obj/effect/proc_holder/spell/self/heretic_power/ash
	name = "Угасание"
	desc = "Потратьте уголёк: погасите пламя на себе, восстановите 15 ожогов и 10 ушибов. Вокруг останется пепельный огонь на 6 секунд."
	action_icon_state = "ash_rekindle"
	knowledge_type = /datum/eldritch_knowledge/base_ash

/obj/effect/proc_holder/spell/self/heretic_power/ash/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	user.ExtinguishMob()
	user.adjustFireLoss(-15)
	user.adjustBruteLoss(-10)
	QDEL_NULL(knowledge.combat_zone)
	knowledge.combat_zone = new /obj/effect/heretic_combat_zone/ash(get_turf(user), user.mind)
	knowledge.track_combat_effect(knowledge.combat_zone)
	new /obj/effect/temp_visual/heretic_oldpath/ash/trail(get_turf(user))
	playsound(user, 'modular_bluemoon/sound/heretic/ash_burst.ogg', 60, TRUE)

/obj/effect/proc_holder/spell/self/heretic_power/rust
	name = "Укоренение"
	desc = "Потратьте нарост: создайте очаг ржавчины на 30 секунд. Он расширяется до области 5×5 и лечит вас и ваших слуг на своей территории. Одновременно существует один очаг."
	action_icon_state = "rust_root"
	knowledge_type = /datum/eldritch_knowledge/base_rust
	charge_max = 300

/obj/effect/proc_holder/spell/self/heretic_power/rust/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	QDEL_NULL(knowledge.combat_zone)
	knowledge.combat_zone = new /obj/effect/heretic_combat_zone/rust(get_turf(user), user.mind)
	knowledge.track_combat_effect(knowledge.combat_zone)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(user))
	playsound(user, 'sound/effects/clangsmall1.ogg', 65, TRUE)

/obj/effect/proc_holder/spell/self/heretic_power/flesh
	name = "Сшивание"
	desc = "Потратьте биомассу: восстановите себе 10 ушибов, а своим слугам в поле зрения на расстоянии до 5 клеток — по 25 ушибов и ожогов. Кровотечение из ран ослабеет вдвое."
	action_icon_state = "flesh_mend"
	knowledge_type = /datum/eldritch_knowledge/base_flesh
	charge_max = 150

/obj/effect/proc_holder/spell/self/heretic_power/flesh/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	user.adjustBruteLoss(-10)
	new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(user))
	for(var/mob/living/servant in view(5, user))
		var/datum/antagonist/heretic_monster/monster = servant.mind?.has_antag_datum(/datum/antagonist/heretic_monster)
		if(!monster || monster.master?.owner != user.mind || servant.stat == DEAD || servant.anti_magic_check())
			continue
		servant.adjustBruteLoss(-25)
		servant.adjustFireLoss(-25)
		if(iscarbon(servant))
			var/mob/living/carbon/carbon_servant = servant
			for(var/obj/item/bodypart/limb as anything in carbon_servant.bodyparts)
				limb.generic_bleedstacks = 0
				for(var/datum/wound/wound as anything in limb.wounds)
					wound.blood_flow *= 0.5
				limb.update_part_wound_overlay()
		user.Beam(servant, icon_state = "drainbeam", time = 8)
		new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(servant))
	playsound(user, 'sound/effects/wounds/blood2.ogg', 60, TRUE)

/obj/effect/proc_holder/spell/self/heretic_power/void
	name = "Зимний предел"
	desc = "Потратьте осколок зимы: создайте область холода 5×5 на 15 секунд. Противники замедляются и теряют голос, пока остаются внутри. Одновременно существует одна область."
	action_icon_state = "void_boundary"
	knowledge_type = /datum/eldritch_knowledge/base_void

/obj/effect/proc_holder/spell/self/heretic_power/void/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	QDEL_NULL(knowledge.combat_zone)
	knowledge.combat_zone = new /obj/effect/heretic_combat_zone/void(get_turf(user), user.mind)
	knowledge.track_combat_effect(knowledge.combat_zone)
	new /obj/effect/temp_visual/heretic_oldpath/void(get_turf(user))
	playsound(user, pick('modular_bluemoon/sound/heretic/void_deflect1.ogg', 'modular_bluemoon/sound/heretic/void_deflect2.ogg'), 60, TRUE)

/// Небольшая видимая область: её работа ограничена радиусом и временем жизни.
/obj/effect/heretic_combat_zone
	name = "эхо Мансуса"
	desc = "Воздух дрожит над незнакомой печатью. Сила её создателя удерживает здесь частицу Мансуса."
	icon = 'modular_bluemoon/icons/obj/heretic_feedback.dmi'
	icon_state = "sigil_ash"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 170
	var/datum/weakref/master_mind
	var/radius = 2
	var/duration = 15 SECONDS
	var/list/affected = list()
	var/list/field_turfs = list()
	var/list/boundary = list()
	var/boundary_color = "#ffffff"
	var/datum/movespeed_modifier/zone_slowdown
	var/expiry_timer

/obj/effect/heretic_combat_zone/Initialize(mapload, datum/mind/master)
	. = ..()
	master_mind = WEAKREF(master)
	zone_slowdown = new
	zone_slowdown.id = REF(src)
	zone_slowdown.multiplicative_slowdown = 1
	refresh_boundary()
	START_PROCESSING(SSprocessing, src)
	expiry_timer = QDEL_IN_STOPPABLE(src, duration)

/obj/effect/heretic_combat_zone/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	deltimer(expiry_timer)
	expiry_timer = null
	QDEL_LIST(boundary)
	field_turfs.Cut()
	release_affected(affected.Copy())
	QDEL_NULL(zone_slowdown)
	master_mind = null
	return ..()

/obj/effect/heretic_combat_zone/process()
	var/datum/mind/master = master_mind?.resolve()
	var/mob/living/user = master?.current
	if(QDELETED(user) || user.stat == DEAD || !IS_HERETIC(user))
		qdel(src)
		return
	var/list/visible = view(radius, src)
	refresh_boundary(visible)
	tick_zone(user, visible)

/// Видимость учитывается и при отрисовке, и при воздействии: за стеной нет невидимого поля.
/obj/effect/heretic_combat_zone/proc/refresh_boundary(list/visible)
	if(!visible)
		visible = view(radius, src)
	var/repair_boundary = FALSE
	for(var/obj/effect/heretic_field_edge/edge as anything in boundary.Copy())
		if(QDELETED(edge))
			boundary -= edge
			repair_boundary = TRUE
	var/list/new_field = list()
	for(var/turf/open/floor/floor in visible)
		new_field += floor
	if(!repair_boundary && length(new_field) == length(field_turfs) && !length(new_field - field_turfs))
		return
	field_turfs = new_field
	var/list/unused_edges = boundary.Copy()
	boundary.Cut()
	for(var/turf/floor as anything in field_turfs)
		for(var/direction in GLOB.cardinals)
			if(!(get_step(floor, direction) in field_turfs))
				var/obj/effect/heretic_field_edge/edge
				if(length(unused_edges))
					edge = unused_edges[1]
					unused_edges.Cut(1, 2)
					edge.forceMove(floor)
					edge.refresh_edges(field_turfs)
				else
					edge = new(floor, field_turfs, boundary_color)
				boundary += edge
				break
	QDEL_LIST(unused_edges)

/obj/effect/heretic_combat_zone/proc/release_affected(list/victims)
	for(var/mob/living/victim as anything in victims)
		UnregisterSignal(victim, list(COMSIG_PARENT_QDELETING, COMSIG_MOVABLE_MOVED))
		if(!QDELETED(victim))
			victim.remove_movespeed_modifier(REF(src))
		affected -= victim

/obj/effect/heretic_combat_zone/proc/on_victim_deleted(mob/living/source)
	SIGNAL_HANDLER
	release_affected(list(source))

/obj/effect/heretic_combat_zone/proc/on_victim_moved(mob/living/source)
	SIGNAL_HANDLER
	if(!(source.loc in field_turfs))
		release_affected(list(source))

/obj/effect/heretic_combat_zone/proc/tick_zone(mob/living/user, list/visible)
	return

/obj/effect/heretic_combat_zone/ash
	name = "угольный след"
	desc = "Угольки тлеют без топлива. Войти в эту печать — значит подставиться пламени."
	boundary_color = "#ff9b43"
	icon_state = "sigil_ash"
	radius = 1
	duration = 6 SECONDS

/obj/effect/heretic_combat_zone/ash/tick_zone(mob/living/user, list/visible)
	if(!visible)
		visible = view(radius, src)
	for(var/mob/living/victim in visible)
		if(!(victim.loc in field_turfs) || !heretic_can_affect(user, victim, chargecost = 0))
			continue
		var/was_on_fire = victim.on_fire
		victim.adjust_fire_stacks(1)
		victim.IgniteMob()
		if(!was_on_fire && victim.on_fire)
			new /obj/effect/temp_visual/heretic_oldpath/ash(get_turf(victim))
			playsound(victim, 'sound/effects/wounds/sizzle1.ogg', 35, TRUE)

/obj/effect/heretic_combat_zone/rust
	name = "очаг ржавчины"
	desc = "В центре ржавого пятна бьётся живой нарост. Чужая плоть рядом с ним затягивает раны."
	boundary_color = "#e7ad64"
	icon_state = "sigil_rust"
	duration = 30 SECONDS
	var/list/unclaimed

/obj/effect/heretic_combat_zone/rust/Initialize(mapload, datum/mind/master)
	. = ..()
	unclaimed = list()
	for(var/turf/floor as anything in field_turfs)
		unclaimed += floor

/obj/effect/heretic_combat_zone/rust/tick_zone(mob/living/user, list/visible)
	for(var/i in 1 to min(3, length(unclaimed)))
		var/turf/floor = unclaimed[1]
		unclaimed.Cut(1, 2)
		if(isfloorturf(floor) && (floor in field_turfs))
			floor.rust_heretic_act()
			new /obj/effect/temp_visual/heretic_oldpath/rust(floor)
	if(!visible)
		visible = view(radius, src)
	for(var/mob/living/ally in visible)
		if(ally.stat == DEAD || !(ally.loc in field_turfs) || !istype(get_turf(ally), /turf/open/floor/plating/rust) || ally.anti_magic_check(chargecost = 0))
			continue
		var/datum/antagonist/heretic_monster/monster = ally.mind?.has_antag_datum(/datum/antagonist/heretic_monster)
		if(ally != user && monster?.master?.owner != user.mind)
			continue
		ally.adjustBruteLoss(-3)
		ally.adjustFireLoss(-3)

/obj/effect/heretic_combat_zone/void
	name = "зимний предел"
	desc = "Белая печать приглушает шаги и голоса. Её холод держится в нескольких шагах от центра."
	boundary_color = "#b7edff"
	icon_state = "sigil_void"

/obj/effect/heretic_combat_zone/void/tick_zone(mob/living/user, list/visible)
	if(!visible)
		visible = view(radius, src)
	var/list/present = list()
	for(var/mob/living/victim in visible)
		if(!(victim.loc in field_turfs) || !heretic_can_affect(user, victim, chargecost = 0))
			continue
		if(!(victim in affected))
			RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_victim_deleted))
			RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(on_victim_moved))
			new /obj/effect/temp_visual/heretic_oldpath/void(get_turf(victim))
			victim.add_movespeed_modifier(zone_slowdown)
		present += victim
		victim.adjust_bodytemperature(-10)
		if(iscarbon(victim))
			var/mob/living/carbon/carbon_victim = victim
			carbon_victim.silent = max(carbon_victim.silent, 2)
	release_affected(affected - present)
	affected = present
