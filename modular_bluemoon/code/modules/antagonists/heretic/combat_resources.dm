/obj/effect/proc_holder/spell
	COOLDOWN_DECLARE(heretic_failure_log)
	var/heretic_failure_reason

/mob/living/cancel_prepared_abilities(obj/effect/proc_holder/except)
	if(!IS_HERETIC(src))
		return FALSE
	. = FALSE
	if(ranged_ability && ranged_ability != except)
		ranged_ability.remove_ranged_ability(span_notice("Прицеливание отменено."))
		. = TRUE
	for(var/obj/item/melee/touch_attack/hand in held_items.Copy())
		if(hand.attached_spell && hand.attached_spell != except)
			. |= hand.attached_spell.cancel_cast(src)

/mob/living/carbon/prepare_ability(obj/effect/proc_holder/ability)
	..()
	if(IS_HERETIC(src) && throw_mode)
		throw_mode_off()
		update_mouse_pointer()
		to_chat(src, span_notice("Режим броска выключен для подготовки способности."))

/obj/effect/proc_holder/spell/proc/heretic_check(mob/user, condition, silent, reason)
	if(condition)
		heretic_failure_reason = null
		return TRUE
	if(user?.incapacitated())
		reason = "Вы не можете действовать: дождитесь окончания оглушения или освободитесь."
	else if(user && !isturf(user.loc))
		reason = "Сначала выйдите из контейнера или укрытия на пол."
	heretic_failure_reason = reason
	if(!silent && user)
		to_chat(user, span_warning("[name]: [reason]"))
		if(COOLDOWN_FINISHED(src, heretic_failure_log))
			COOLDOWN_START(src, heretic_failure_log, 5 SECONDS)
			log_game("[key_name(user)] не применяет [name] ([type]): [reason] в [AREACOORD(user)].")
	return FALSE

/obj/effect/proc_holder/spell/proc/heretic_require_knowledge(mob/user, silent, knowledge_type, resource_cost = 0)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/knowledge = heretic?.get_knowledge(knowledge_type)
	if(!heretic_check(user, isliving(user) && knowledge && !heretic.role_removed && heretic.owner?.current == user && !user.incapacitated(), silent, "Нужно изучить соответствующее знание своего пути."))
		return FALSE
	return heretic_check(user, knowledge.combat_resource >= resource_cost, silent, "Нужно [resource_cost] ед. ресурса «[knowledge.combat_resource_name]»; сейчас [knowledge.combat_resource].")

/obj/effect/proc_holder/spell/proc/heretic_revert_cast(mob/user, reason)
	heretic_check(user, FALSE, FALSE, reason || heretic_failure_reason || "Применение отменено. Условия способности: [desc]")
	revert_cast(user)

/proc/heretic_heal_damage(mob/living/target, brute = 0, burn = 0)
	if(QDELETED(target) || target.stat == DEAD)
		return 0
	var/before = target.getBruteLoss() + target.getFireLoss()
	target.adjustBruteLoss(-max(0, brute), only_organic = FALSE)
	if(QDELETED(target))
		return 0
	target.adjustFireLoss(-max(0, burn), only_organic = FALSE)
	return QDELETED(target) ? 0 : max(0, before - target.getBruteLoss() - target.getFireLoss())

/proc/heretic_heal_pool(mob/living/target, amount)
	if(QDELETED(target) || amount <= 0)
		return 0
	var/healed = heretic_heal_damage(target, amount)
	return healed + heretic_heal_damage(target, burn = max(0, amount - healed))

/proc/heretic_corrosion(mob/living/target, amount)
	if(QDELETED(target) || target.stat == DEAD || amount <= 0)
		return
	target.adjustFireLoss(amount / 3)
	if(QDELETED(target) || issilicon(target))
		return
	if(HAS_TRAIT(target, TRAIT_ROBOTIC_ORGANISM))
		target.adjustToxLoss(amount * 2 / 3, toxins_type = TOX_SYSCORRUPT)
	else if(!HAS_TRAIT(target, TRAIT_TOXINLOVER))
		target.adjustToxLoss(amount * 2 / 3)

/// Запас силы принадлежит знанию и переживает смену тела.
/datum/eldritch_knowledge
	var/combat_resource = 2
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
	QDEL_NULL(innate)
	combat_resource_owner = null
	remove_combat_power()
	release_flesh_servants()
	return ..()

/// Единая проверка боевых эффектов: союзники и защита от магии остаются полезны на всех путях.
/proc/heretic_can_affect(mob/user, atom/target, chargecost = 1)
	if(!isliving(target) || target == user || QDELETED(target))
		return FALSE
	var/mob/living/victim = target
	return victim.stat != DEAD && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && !victim.check_magic_resistance(tinfoil = TRUE, chargecost = chargecost)

/datum/eldritch_knowledge/base_ash
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/ash
	grasp_sound = 'sound/effects/wounds/sizzle1.ogg'
	combat_resource_name = "Угольки"
	combat_resource_desc = "После изучения Власти Пепла хватка поджигает врага и даёт +1 уголёк, если он горит, не чаще раза в 15 секунд. После изучения Метки Пепла наложите её хваткой и ударьте пепельным клинком: +1 уголёк. Хватка также даёт уголёк за погашенную спичку, свечу, зажигалку или другой открытый огонь раз в 15 секунд. Обычный уголь не нужен. Угасание расходует уголёк: тушит вас, лечит ожоги и оставляет горящий след для отступления."
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
	combat_resource_desc = "Активируйте метки клинком или выходите на пол с воздухом холоднее 0 °C. Между пассивными пополнениями проходит 20 секунд: ждать всё это время в холоде не нужно. Клетка открытого космоса не подходит. При пустом запасе один осколок восстанавливается на полу даже в тепле с тем же интервалом. Зимний предел расходует осколок и создаёт область 5×5 на 15 секунд: враги замедляются независимо от температуры тела и теряют голос. Скованность проходит через 4 секунды после последнего воздействия. Само поле воздух не охлаждает."
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
	QDEL_NULL(fleshling)
	remove_combat_power()

/datum/eldritch_knowledge/base_void/on_body_gain(mob/living/user)
	grant_combat_power(user)

/datum/eldritch_knowledge/base_void/on_body_lose(mob/living/user)
	remove_combat_power()

/datum/eldritch_knowledge/base_flesh/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !istype(target, /obj/item/organ) || !isturf(target.loc))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(user.a_intent == INTENT_DISARM && heretic?.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul))
		return grow_fleshling(user, target)
	var/turf/target_turf = get_turf(target)
	gain_combat_resource()
	new /obj/effect/temp_visual/heretic_oldpath/flesh(target_turf)
	playsound(target, 'sound/effects/wounds/blood1.ogg', 50, TRUE)
	user.visible_message(span_warning("[user] растворяет [target] в багровой дымке."))
	heretic?.advance_deed("[target.type]", target_turf, silent = TRUE)
	qdel(target)
	return TRUE

/datum/eldritch_knowledge/base_ash/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic || !proximity_flag || !isturf(target.loc))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!extinguish_flame(target))
		return FALSE
	var/previous_resource = combat_resource
	heretic.advance_deed(heretic.deed_key_for(target_turf), target_turf)
	if(COOLDOWN_FINISHED(src, resource_harvest))
		if(combat_resource == previous_resource)
			gain_combat_resource()
		COOLDOWN_START(src, resource_harvest, 15 SECONDS)
	return TRUE

/datum/eldritch_knowledge/base_ash/proc/extinguish_flame(atom/target)
	if(istype(target, /obj/effect/hotspot))
		qdel(target)
		return TRUE
	if(istype(target, /obj/item/weldingtool))
		var/obj/item/weldingtool/welder = target
		if(!welder.welding)
			return FALSE
		welder.switched_off()
		return TRUE
	if(istype(target, /obj/item/lighter))
		var/obj/item/lighter/lighter = target
		if(!lighter.lit)
			return FALSE
		lighter.set_lit(FALSE)
		return TRUE
	if(istype(target, /obj/item/candle))
		var/obj/item/candle/candle = target
		return candle.put_out_candle()
	if(istype(target, /obj/item/flashlight/flare))
		var/obj/item/flashlight/flare/flare = target
		if(!flare.on)
			return FALSE
		flare.turn_off()
		return TRUE
	if(istype(target, /obj/item/match))
		var/obj/item/match/match = target
		if(!match.lit)
			return FALSE
		match.matchburnout()
		return TRUE
	return FALSE

/datum/eldritch_knowledge/base_void/on_mansus_grasp(atom/target, mob/user, proximity_flag, click_parameters)
	if(!proximity_flag || !istype(target, /obj/machinery/light))
		return FALSE
	var/obj/machinery/light/lamp = target
	if(lamp.status != initial(lamp.status) || !lamp.on)
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return FALSE
	lamp.flicker()
	lamp.burn_out()
	user.visible_message(span_warning("[lamp] мигает и гаснет, стекло покрывается инеем."))
	heretic.advance_deed(heretic.deed_key_for(lamp), get_turf(user))
	return TRUE

/datum/eldritch_knowledge/base_void/on_life(mob/user)
	var/turf/open/floor/floor = get_turf(user)
	if(!istype(floor) || user.stat == DEAD || !COOLDOWN_FINISHED(src, resource_harvest))
		return
	if(combat_resource >= 1 && floor.GetTemperature() >= T0C)
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
	return ..() && heretic_require_knowledge(user, silent, knowledge_type, 1)

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
	heretic_heal_damage(user, 10, 15)
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
	heretic_heal_damage(user, 10)
	new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(user))
	for(var/mob/living/servant in view(5, user))
		var/datum/antagonist/heretic_monster/monster = servant.mind?.has_antag_datum(/datum/antagonist/heretic_monster)
		if(!monster || monster.master?.owner != user.mind || servant.stat == DEAD || servant.check_magic_resistance(chargecost = 0))
			continue
		heretic_heal_damage(servant, 25, 25)
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
	desc = "Потратьте осколок зимы: создайте область 5×5 на 15 секунд. Противники сразу замедляются независимо от температуры тела, охлаждаются и теряют голос; скованность проходит через 4 секунды после последнего воздействия. Поле не охлаждает воздух, но позволяет изготовить на руне внутри него клинок Пустоты. Одновременно существует одна область."
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
	var/expires_at

/obj/effect/heretic_combat_zone/Initialize(mapload, datum/mind/master)
	. = ..()
	master_mind = WEAKREF(master)
	zone_slowdown = new
	zone_slowdown.id = REF(src)
	zone_slowdown.multiplicative_slowdown = 1
	refresh_boundary()
	START_PROCESSING(SSprocessing, src)
	expires_at = world.time + duration
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
	var/list/claimed = list()

/obj/effect/heretic_combat_zone/rust/tick_zone(mob/living/user, list/visible)
	var/remaining = 3
	for(var/turf/open/floor/floor as anything in field_turfs - claimed)
		claimed += floor
		floor.rust_heretic_act()
		new /obj/effect/temp_visual/heretic_oldpath/rust(floor)
		if(!--remaining)
			break
	if(!visible)
		visible = view(radius, src)
	for(var/mob/living/ally in visible)
		if(ally.stat == DEAD || !(ally.loc in field_turfs) || !istype(get_turf(ally), /turf/open/floor/plating/rust))
			continue
		var/datum/antagonist/heretic_monster/monster = ally.mind?.has_antag_datum(/datum/antagonist/heretic_monster)
		if(ally != user && monster?.master?.owner != user.mind)
			continue
		if(ally != user && ally.check_magic_resistance(chargecost = 0))
			continue
		heretic_heal_damage(ally, 3, 3)

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
		victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
		if(iscarbon(victim))
			var/mob/living/carbon/carbon_victim = victim
			carbon_victim.silent = max(carbon_victim.silent, 2)
	release_affected(affected - present)
	affected = present
