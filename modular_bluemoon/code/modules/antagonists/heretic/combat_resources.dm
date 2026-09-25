#define HERETIC_VOID_SHARD_INTERVAL (20 SECONDS)
#define HERETIC_VOID_WARM_SHARD_INTERVAL (30 SECONDS)
#define HERETIC_VOID_WARM_SHARD_CAP 2

/obj/effect/proc_holder/spell
	COOLDOWN_DECLARE(heretic_failure_log)
	var/heretic_failure_reason
	/// Одна строка для списка способностей в кодексе.
	var/summary
	/// Еретик до вознесения не колдует это под оглушением, в стамкрите и в чужой хватке.
	var/heretic_stun_check = FALSE
	var/usable_while_grabbed = FALSE

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

/obj/effect/proc_holder/spell/proc/heretic_check(mob/user, condition, silent, reason, mob/living/target)
	if(condition)
		heretic_failure_reason = null
		return TRUE
	var/containment_reason = heretic_containment_reason(user)
	if(containment_reason)
		reason = containment_reason
	else if(user?.incapacitated(ignore_grab = usable_while_grabbed))
		reason = "Вы не можете действовать: дождитесь окончания оглушения или освободитесь."
	else if(user && !isturf(user.loc))
		reason = "Сначала выйдите из контейнера или укрытия на пол."
	else if(isliving(target) && target != user && (IS_HERETIC(target) || IS_HERETIC_MONSTER(target)))
		reason = "Это союзник Мансуса: еретики и их слуги защищены от этой способности."
		var/datum/antag_training_session/training = GLOB.antag_training_sessions[user?.ckey]
		if(training && training.current_body == user)
			reason += " Для проверки урона на полигоне соперник должен выбрать роль «Снаряжение и бой»; дуэль сохраняет иммунитеты."
	heretic_failure_reason = reason
	if(!silent && user)
		to_chat(user, span_warning("[name]: [reason]"))
		var/datum/antag_training_session/session = GLOB.antag_training_sessions[user.ckey]
		if(session?.current_body == user)
			session.last_feedback = "[name]: [reason]"
		if(COOLDOWN_FINISHED(src, heretic_failure_log))
			COOLDOWN_START(src, heretic_failure_log, 5 SECONDS)
			var/charge_state = charge_type == "recharge" && charge_counter < charge_max ? " charge=[charge_counter]/[charge_max], recharging=[recharging], processing=[src in SSfastprocess.processing]." : ""
			log_game("[key_name(user)] не применяет [name] ([type]): [reason] в [AREACOORD(user)].[charge_state]")
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
	/// Правила запаса по одному на строку; без них кодекс показывает combat_resource_desc.
	var/list/resource_rules
	var/combat_resource_action
	var/grasp_visual
	var/grasp_sound
	var/grasp_catchphrase
	var/grasp_failure_reason
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
	return combat_resource_payload(combat_resource_name, combat_resource, combat_resource_max)

/datum/eldritch_knowledge/proc/combat_resource_payload(name, value, max, rules_text = combat_resource_desc)
	var/list/rules = length(resource_rules) ? resource_rules.Copy() : list(rules_text)
	var/state = combat_resource_state()
	var/description = jointext(rules, " ")
	if(state)
		description += " [state]"
	return list("name" = name, "value" = value, "max" = max, "rules" = rules, "state" = state, "description" = description)

/// Живое состояние запаса одной строкой: счётчики построек, режимы, текущие цели.
/datum/eldritch_knowledge/proc/combat_resource_state()
	return ""

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
/proc/heretic_can_affect(mob/user, atom/target, chargecost = 1, tinfoil = TRUE)
	if(!isliving(target) || target == user || QDELETED(target))
		return FALSE
	var/mob/living/victim = target
	return victim.stat != DEAD && !IS_HERETIC(victim) && !IS_HERETIC_MONSTER(victim) && !victim.check_magic_resistance(tinfoil = tinfoil, chargecost = chargecost)

/// Дверь старого пути открывает еретик этого знания в своём теле, на полу и не скованный.
/datum/eldritch_knowledge/proc/door_user_ready(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && heretic && !heretic.role_removed && heretic.owner?.current == user && heretic.get_knowledge(type) == src && !user.incapacitated() && isturf(user.loc)

/datum/eldritch_knowledge/proc/door_zone_under(mob/living/victim, zone_type)
	for(var/obj/effect/heretic_combat_zone/zone in list(combat_zone, relic_zone))
		if(istype(zone, zone_type) && !QDELETED(zone) && (victim.loc in zone.field_turfs))
			return zone
	return null

/// view() от эффекта или турфа не видит неосвещённые турфы, поэтому центр на время подсвечивается, как в get_hear().
/proc/heretic_field_view(radius, atom/center)
	var/turf/center_turf = get_turf(center)
	if(!center_turf)
		return list()
	var/previous_luminosity = center_turf.luminosity
	center_turf.luminosity = radius + 1
	. = view(radius, center_turf)
	center_turf.luminosity = previous_luminosity

/// Линию магии не закрывают столы и то, над чем пролетают брошенные предметы; стены, двери, окна и машины закрывают.
/proc/heretic_line_tile_open(turf/tile)
	if(!isopenturf(tile) || tile.density)
		return FALSE
	for(var/atom/movable/obstacle as anything in tile)
		if(!obstacle.density || ismob(obstacle) || (obstacle.pass_flags_self & (PASSTABLE | LETPASSTHROW)))
			continue
		return FALSE
	return TRUE

/// Как heretic_line_tile_open, но направленные окна и двери не закрывают клетку целиком, а перила пропускают.
/proc/heretic_tile_passable(turf/tile)
	if(!isopenturf(tile) || tile.density)
		return FALSE
	for(var/atom/movable/obstacle as anything in tile)
		if(!obstacle.density || ismob(obstacle) || ((obstacle.flags_1 & ON_BORDER_1) && !ISDIAGONALDIR(obstacle.dir)))
			continue
		if((obstacle.pass_flags_self & (PASSTABLE | LETPASSTHROW)) || istype(obstacle, /obj/structure/railing))
			continue
		return FALSE
	return TRUE

/// Направленное окно или дверь закрывает только свою грань клетки.
/proc/heretic_edge_open(turf/from_turf, turf/to_turf)
	var/direction = get_dir(from_turf, to_turf)
	for(var/atom/movable/obstacle as anything in from_turf)
		if(obstacle.density && (obstacle.flags_1 & ON_BORDER_1) && obstacle.dir == direction)
			return FALSE
	var/reverse = REVERSE_DIR(direction)
	for(var/atom/movable/obstacle as anything in to_turf)
		if(obstacle.density && (obstacle.flags_1 & ON_BORDER_1) && obstacle.dir == reverse)
			return FALSE
	return TRUE

/proc/heretic_step_open(turf/from_turf, turf/to_turf)
	if(from_turf.x == to_turf.x || from_turf.y == to_turf.y)
		return heretic_edge_open(from_turf, to_turf)
	for(var/turf/corner as anything in list(locate(from_turf.x, to_turf.y, to_turf.z), locate(to_turf.x, from_turf.y, to_turf.z)))
		if(heretic_tile_passable(corner) && heretic_edge_open(from_turf, corner) && heretic_edge_open(corner, to_turf))
			return TRUE
	return FALSE

/// Стартовая клетка не проверяется целиком: преграда на ней закрывает только свою сторону.
/proc/heretic_edge_line_clear(atom/start, atom/end)
	var/turf/previous
	for(var/turf/tile as anything in get_line(get_turf(start), get_turf(end)))
		if(previous && (!heretic_tile_passable(tile) || !heretic_step_open(previous, tile)))
			return FALSE
		previous = tile
	return TRUE

/datum/eldritch_knowledge/base_ash
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/ash
	grasp_sound = 'sound/effects/wounds/sizzle1.ogg'
	grasp_catchphrase = "PE'LENAI ATSI'MENA"
	combat_resource_name = "Угольки"
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/ash

/datum/eldritch_knowledge/base_rust
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/rust
	grasp_sound = 'sound/effects/clangsmall1.ogg'
	grasp_catchphrase = "RU'DYS PRA'RYJA VISKA"
	combat_resource_name = "Наросты"
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/rust

/datum/eldritch_knowledge/base_flesh
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/flesh
	grasp_sound = 'sound/effects/wounds/blood1.ogg'
	grasp_catchphrase = "ME'SA TRO'KSTA ME'SOS"
	combat_resource_name = "Биомасса"
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/flesh

/datum/eldritch_knowledge/base_void
	grasp_visual = /obj/effect/temp_visual/heretic_oldpath/void
	grasp_sound = 'modular_bluemoon/sound/heretic/void_deflect1.ogg'
	grasp_catchphrase = "TY'LA UZ'GESINA"
	combat_resource_name = "Осколки зимы"
	combat_resource_action = /obj/effect/proc_holder/spell/self/heretic_power/void
	COOLDOWN_DECLARE(warm_shard_harvest)

/datum/eldritch_knowledge/base_blade
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/blade
	grasp_sound = 'modular_bluemoon/sound/heretic/blade_grasp.ogg'
	grasp_catchphrase = "A'SMUO NE'KLYSTA"

/datum/eldritch_knowledge/base_moon
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/moon
	grasp_sound = 'modular_bluemoon/sound/heretic/moon_grasp.ogg'
	grasp_catchphrase = "ME'NULIS JU'OKIASI"

/datum/eldritch_knowledge/base_cosmic
	grasp_visual = /obj/effect/temp_visual/heretic_grasp/cosmic
	grasp_sound = 'modular_bluemoon/sound/heretic/cosmic_energy.ogg'
	grasp_catchphrase = "ZVAI'GZDES MA'TO"

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
	if(user.a_intent == INTENT_DISARM && (heretic?.get_knowledge(/datum/eldritch_knowledge/flesh_grasp) || heretic?.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul)))
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
	if(!heretic || !proximity_flag)
		return FALSE
	var/held = target.loc == user
	if(!held && !isturf(target) && !isturf(target.loc))
		return FALSE
	var/turf/target_turf = get_turf(target)
	var/obj/effect/hotspot/floor_fire = locate() in target_turf
	if(!extinguish_flame(target) && (held || isliving(target) || !extinguish_flame(floor_fire)))
		return FALSE
	var/previous_resource = combat_resource
	if(!held)
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
	if(floor.GetTemperature() >= T0C)
		if(combat_resource >= HERETIC_VOID_WARM_SHARD_CAP)
			return
		if(combat_resource && !COOLDOWN_FINISHED(src, warm_shard_harvest))
			return
	gain_combat_resource()
	COOLDOWN_START(src, resource_harvest, HERETIC_VOID_SHARD_INTERVAL)
	COOLDOWN_START(src, warm_shard_harvest, HERETIC_VOID_WARM_SHARD_INTERVAL)

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
	desc = "Потратьте уголёк: погасите пламя на себе, восстановите 15 ожогов и 10 ушибов. Вокруг останется пепельный огонь на 6 секунд. Вода и пена гасят его сразу."
	summary = "За уголёк тушит вас, лечит 15 ожогов и 10 ушибов и зажигает огонь вокруг."
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
	desc = "Потратьте нарост: создайте очаг ржавчины на 30 секунд, новый заменяет прежний. Он ржавит пол 5×5 и лечит вас и ваших слуг на ржавом полу внутри границы."
	summary = "За нарост очаг на 30 секунд лечит вас и свиту на ржавчине."
	action_icon_state = "rust_root"
	knowledge_type = /datum/eldritch_knowledge/base_rust
	charge_max = 300

/obj/effect/proc_holder/spell/self/heretic_power/rust/can_cast(mob/user, skipcharge, silent)
	var/turf/open/floor/floor = user.loc
	return ..() && heretic_check(user, istype(floor) && floor.heretic_rustable, silent, "Для очага встаньте на пол, поддающийся ржавчине: металлические плиты, обшивку или дерево.")

/obj/effect/proc_holder/spell/self/heretic_power/rust/cast(list/targets, mob/living/user)
	var/turf/open/floor/floor = user.loc
	if(!istype(floor) || !floor.heretic_rustable)
		heretic_revert_cast(user, "Этот пол не поддаётся ржавчине; нарост сохранён.")
		return
	return ..()

/obj/effect/proc_holder/spell/self/heretic_power/rust/activate_power(mob/living/user, datum/eldritch_knowledge/knowledge)
	QDEL_NULL(knowledge.combat_zone)
	knowledge.combat_zone = new /obj/effect/heretic_combat_zone/rust(get_turf(user), user.mind)
	knowledge.track_combat_effect(knowledge.combat_zone)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(user))
	playsound(user, 'sound/effects/clangsmall1.ogg', 65, TRUE)

/obj/effect/proc_holder/spell/self/heretic_power/flesh
	name = "Сшивание"
	desc = "Потратьте биомассу: восстановите себе 10 ушибов, а своим слугам в поле зрения на расстоянии до 5 клеток - по 25 ушибов и ожогов. Кровотечение из ран ослабеет вдвое."
	summary = "За биомассу лечит вас и своих слуг в 5 клетках."
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
	desc = "Потратьте осколок зимы: создайте поле 5×5 на 15 секунд, новое заменяет прежнее. Враги в нём замедляются, охлаждаются и теряют голос."
	summary = "За осколок поле 5×5 на 15 секунд сковывает, холодит и глушит врагов."
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
	name = "Mansus echo"
	desc = "Воздух дрожит над незнакомой печатью. Сила её создателя удерживает здесь частицу Мансуса."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
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
	var/applies_slowdown = TRUE
	var/expiry_timer
	var/expires_at

/obj/effect/heretic_combat_zone/Initialize(mapload, datum/mind/master)
	. = ..()
	master_mind = WEAKREF(master)
	if(applies_slowdown)
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
	var/list/visible = heretic_field_view(radius, src)
	refresh_boundary(visible)
	tick_zone(user, visible)

/// Видимость учитывается и при отрисовке, и при воздействии: за стеной нет невидимого поля.
/obj/effect/heretic_combat_zone/proc/refresh_boundary(list/visible)
	if(!visible)
		visible = heretic_field_view(radius, src)
	var/repair_boundary = FALSE
	for(var/obj/effect/heretic_field_edge/edge as anything in boundary.Copy())
		if(QDELETED(edge))
			boundary -= edge
			repair_boundary = TRUE
	var/list/new_field = list()
	for(var/turf/open/floor/floor in visible)
		if(!accepts_field_turf(floor))
			continue
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
				var/reused = length(unused_edges)
				if(reused)
					edge = unused_edges[1]
					unused_edges.Cut(1, 2)
					edge.forceMove(floor)
					edge.refresh_edges(field_turfs)
				else
					edge = new(floor, field_turfs, boundary_color)
				style_edge(edge, reused)
				boundary += edge
				break
	QDEL_LIST(unused_edges)

/obj/effect/heretic_combat_zone/proc/accepts_field_turf(turf/open/floor/floor)
	return TRUE

/// Оформление края при создании; перенесённый со старого места край (reused) уже оформлен.
/obj/effect/heretic_combat_zone/proc/style_edge(obj/effect/heretic_field_edge/edge, reused = FALSE)
	return

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
	name = "ember trail"
	desc = "Угольки тлеют без топлива. Кто войдёт в эту печать, подставится пламени. Вода и пена гасят её сразу."
	boundary_color = "#ff9b43"
	icon_state = "sigil_ash"
	radius = 1
	duration = 6 SECONDS

/obj/effect/heretic_combat_zone/ash/tick_zone(mob/living/user, list/visible)
	if(!visible)
		visible = heretic_field_view(radius, src)
	for(var/mob/living/victim in visible)
		if(!(victim.loc in field_turfs) || !heretic_can_affect(user, victim, chargecost = 0))
			continue
		var/was_on_fire = victim.on_fire
		victim.adjust_fire_stacks(1)
		victim.IgniteMob()
		if(victim.on_fire)
			var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
			heretic?.advance_combat_deed(victim, PATH_ASH)
		if(!was_on_fire && victim.on_fire)
			new /obj/effect/temp_visual/heretic_oldpath/ash(get_turf(victim))
			playsound(victim, 'sound/effects/wounds/sizzle1.ogg', 35, TRUE)

/datum/eldritch_knowledge/base_rust/on_eldritch_blade(atom/target, mob/living/user, proximity_flag, click_parameters)
	if(proximity_flag && isliving(target) && istype(user.loc, /turf/open/floor/plating/rust))
		var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
		heretic?.advance_combat_deed(target, PATH_RUST)

/obj/effect/heretic_combat_zone/rust
	name = "rust hearth"
	desc = "В центре ржавого пятна бьётся живой нарост. Чужая плоть рядом с ним затягивает раны."
	boundary_color = "#e7ad64"
	icon_state = "sigil_rust"
	duration = 30 SECONDS

/obj/effect/heretic_combat_zone/rust/accepts_field_turf(turf/open/floor/floor)
	return istype(floor, /turf/open/floor/plating/rust)

/obj/effect/heretic_combat_zone/rust/tick_zone(mob/living/user, list/visible)
	visible = visible ? visible.Copy() : heretic_field_view(radius, src)
	var/remaining = 3
	for(var/turf/open/floor/floor in visible.Copy())
		if(!floor.heretic_rustable || istype(floor, /turf/open/floor/plating/rust))
			continue
		var/turf/changed = floor.rust_heretic_act()
		visible -= floor
		if(!changed)
			continue
		visible |= changed
		new /obj/effect/temp_visual/heretic_oldpath/rust(changed)
		if(!--remaining)
			break
	refresh_boundary(visible)
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
	name = "winter's edge"
	desc = "Белая печать приглушает шаги и голоса. Её холод держится в нескольких шагах от центра."
	boundary_color = "#b7edff"
	icon_state = "sigil_void"

/obj/effect/heretic_combat_zone/void/tick_zone(mob/living/user, list/visible)
	if(!visible)
		visible = heretic_field_view(radius, src)
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
		if(victim.apply_status_effect(/datum/status_effect/heretic_void_chill))
			var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
			heretic?.advance_combat_deed(victim, PATH_VOID)
		if(iscarbon(victim))
			var/mob/living/carbon/carbon_victim = victim
			carbon_victim.silent = max(carbon_victim.silent, 2)
	release_affected(affected - present)
	affected = present

#undef HERETIC_VOID_SHARD_INTERVAL
#undef HERETIC_VOID_WARM_SHARD_INTERVAL
#undef HERETIC_VOID_WARM_SHARD_CAP
