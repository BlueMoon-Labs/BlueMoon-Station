#define HERETIC_RUST_INK heretic_path_ink(PATH_RUST, TRUE)
#define HERETIC_RUST_DARK_SHARE 0.5
#define HERETIC_RUST_DARK_INK BlendRGB(HERETIC_RUST_INK, COLOR_BLACK, HERETIC_RUST_DARK_SHARE)
#define HERETIC_RUST_HEART_SCALE 1.25
#define HERETIC_RUST_HEART_SWELL 1.07
#define HERETIC_RUST_HEART_ECHO 1.03
#define HERETIC_RUST_HEART_FLUSH_SHARE 0.5
#define HERETIC_RUST_HEART_GLOW 150
#define HERETIC_RUST_HEART_VEINS 120
#define HERETIC_RUST_HEART_RISE 8
#define HERETIC_RUST_HEART_EMERGE (0.8 SECONDS)
#define HERETIC_RUST_HEART_BEAT (0.15 SECONDS)
#define HERETIC_RUST_HEART_REST (0.8 SECONDS)
#define HERETIC_RUST_HEART_SHUDDER 2
#define HERETIC_RUST_HEART_SHUDDER_STEP (0.1 SECONDS)
#define HERETIC_RUST_HEART_WOUND_COOLDOWN (0.4 SECONDS)
#define HERETIC_RUST_HEART_WOUND_PULSE (0.3 SECONDS)
#define HERETIC_RUST_HEART_COLLAPSE (0.9 SECONDS)
#define HERETIC_RUST_HEART_DEATH_WAVE (0.6 SECONDS)
#define HERETIC_RUST_HEART_DEATH_FLASH (0.5 SECONDS)
#define HERETIC_RUST_HEART_DEATH_RADIUS 2
#define HERETIC_RUST_HEART_DEATH_POWER 2
#define HERETIC_RUST_COLLAPSE_SPREAD 1.3
#define HERETIC_RUST_COLLAPSE_SQUASH 0.15
#define HERETIC_RUST_COLLAPSE_SINK 10
#define HERETIC_RUST_RIPPLE_STEP (0.08 SECONDS)
#define HERETIC_RUST_RIPPLE_DISSOLVE (0.25 SECONDS)
#define HERETIC_RUST_RIPPLE_REVEAL (0.3 SECONDS)
#define HERETIC_RUST_CREEP_HOLD (0.7 SECONDS)
#define HERETIC_RUST_CREEP_FADE (0.5 SECONDS)
#define HERETIC_RUST_WAVE_TIME (0.8 SECONDS)
#define HERETIC_RUST_WAVE_FLASH_RANGE 3
#define HERETIC_RUST_WAVE_FLASH_POWER 1.5
#define HERETIC_RUST_WAVE_QUAKE 0.12
#define HERETIC_RUST_WAVE_QUAKE_TIME (0.3 SECONDS)
#define HERETIC_RUST_HEART_RISE_VOLUME 70
#define HERETIC_RUST_HEART_HIT_VOLUME 60
#define HERETIC_RUST_HEART_BREAK_VOLUME 85
#define HERETIC_RUST_HEART_BREAK_SOUND_RANGE 10
#define HERETIC_RUST_WAVE_VOLUME 80
#define HERETIC_RUST_WAVE_SOUND_RANGE 5
#define HERETIC_RUST_WAVE_COLLAPSE_VOLUME 70
#define HERETIC_RUST_ROOTS_RELEASE_VOLUME 45
#define HERETIC_RUST_FX_ICON 'modular_bluemoon/icons/obj/heretic_rust_fx.dmi'
#define HERETIC_RUST_ROOTS_GROW (1 SECONDS)
#define HERETIC_RUST_ROOTS_VOLUME 50
#define HERETIC_RUST_PRY_VOLUME 50
#define HERETIC_RUST_FORMATION_VOLUME 60
#define HERETIC_RUST_FORMATION_FALL (1 SECONDS)
#define HERETIC_RUST_HINT_COLOR "#e7ad64"
#define HERETIC_RUST_HINT_ALPHA 170
#define HERETIC_RUST_CHAIN_VOLUME 60
#define HERETIC_RUST_CHAIN_STEP (0.1 SECONDS)
#define HERETIC_RUST_CHAIN_BEAM_TAIL (1 SECONDS)

GLOBAL_LIST_INIT(heretic_rust_heart_rise_sounds, list(
	'modular_bluemoon/sound/heretic/rust_heart_rise_1.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_rise_2.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_rise_3.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_heart_hit_sounds, list(
	'modular_bluemoon/sound/heretic/rust_heart_hit_1.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_hit_2.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_hit_3.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_heart_break_sounds, list(
	'modular_bluemoon/sound/heretic/rust_heart_break_1.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_break_2.ogg',
	'modular_bluemoon/sound/heretic/rust_heart_break_3.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_grasp_sounds, list(
	'modular_bluemoon/sound/heretic/rust_grasp_1.ogg',
	'modular_bluemoon/sound/heretic/rust_grasp_2.ogg',
	'modular_bluemoon/sound/heretic/rust_grasp_3.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_root_sounds, list(
	'modular_bluemoon/sound/heretic/rust_root_1.ogg',
	'modular_bluemoon/sound/heretic/rust_root_2.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_mark_sounds, list(
	'modular_bluemoon/sound/heretic/rust_mark_1.ogg',
	'modular_bluemoon/sound/heretic/rust_mark_2.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_formation_sounds, list(
	'modular_bluemoon/sound/heretic/rust_formation_1.ogg',
	'modular_bluemoon/sound/heretic/rust_formation_2.ogg',
))
GLOBAL_LIST_INIT(heretic_rust_wave_sounds, list(
	'modular_bluemoon/sound/heretic/rust_wave_1.ogg',
	'modular_bluemoon/sound/heretic/rust_wave_2.ogg',
	'modular_bluemoon/sound/heretic/rust_wave_3.ogg',
))

/turf/open/floor
	var/heretic_rustable = FALSE

/turf/open/floor/plating
	heretic_rustable = TRUE

/turf/open/floor/plasteel
	heretic_rustable = TRUE

/turf/open/floor/wood
	heretic_rustable = TRUE

/turf/open/floor/mineral/titanium
	heretic_rustable = TRUE

/turf/open/floor/mineral/plastitanium
	heretic_rustable = TRUE

/turf/open/floor/engine
	heretic_rustable = TRUE

/turf/open/floor/engine/hull
	heretic_rustable = FALSE

/turf/open/floor/engine/cult
	heretic_rustable = FALSE

/turf/open/floor/plasteel/elevated
	heretic_rustable = FALSE

/turf/open/floor/plasteel/lowered
	heretic_rustable = FALSE

/turf/open/floor/rust_heretic_act()
	if(!heretic_rustable)
		return
	if(prob(70))
		new /obj/effect/temp_visual/glowing_rune(src)
	var/turf/after = ChangeTurf(/turf/open/floor/plating/rust, flags = CHANGETURF_INHERIT_AIR)
	after?.AddElement(/datum/element/heretic_rust)
	return after

#define HERETIC_RUST_HEALING_ALERT "heretic_rust_healing"

/datum/heretic_innate/rust/bind(mob/living/user)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/unbind()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
	return ..()

/datum/heretic_innate/rust/on_move(mob/living/source, atom/old_loc, direction, forced)
	. = ..()
	update_healing_alert()

/datum/heretic_innate/rust/on_death()
	. = ..()
	body?.clear_alert(HERETIC_RUST_HEALING_ALERT)

/datum/heretic_innate/rust/proc/update_healing_alert()
	if(!valid())
		body?.clear_alert(HERETIC_RUST_HEALING_ALERT)
		return
	var/on_rust = istype(body.loc, /turf/open/floor/plating/rust)
	var/in_grove = FALSE
	var/datum/eldritch_knowledge/knowledge = knowledge_ref.resolve()
	if(on_rust)
		for(var/obj/effect/heretic_combat_zone/rust/zone in list(knowledge.combat_zone, knowledge.relic_zone))
			if(!QDELETED(zone) && (body.loc in zone.field_turfs))
				in_grove = TRUE
				break
	var/atom/movable/screen/alert/heretic_rust_healing/indicator = body.throw_alert(HERETIC_RUST_HEALING_ALERT, /atom/movable/screen/alert/heretic_rust_healing, no_anim = TRUE)
	indicator.update_healing(on_rust, in_grove)

/atom/movable/screen/alert/heretic_rust_healing
	name = "Лечение Ржавчины"
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "rust_heal"
	maptext_width = 32
	maptext_height = 12
	maptext_y = 1
	var/healing_state

/atom/movable/screen/alert/heretic_rust_healing/proc/update_healing(on_rust, in_grove)
	var/new_state = in_grove ? "grove" : (on_rust ? "floor" : "inactive")
	if(healing_state == new_state)
		return
	healing_state = new_state
	var/label
	switch(healing_state)
		if("grove")
			name = "Ржавчина: пол и очаг лечат"
			desc = "Вы стоите на ржавом полу внутри своего очага. Работают врождённое лечение и дополнительное лечение очага. Ржавая поступь добавляет лечение, если изучена."
			label = "ОЧАГ"
			color = "#b5ffc5"
		if("floor")
			name = "Ржавчина: пол лечит"
			desc = "Работает врождённое лечение. Ржавая поступь добавляет лечение, если изучена. Дополнительное лечение очага здесь не действует: вернитесь в его отмеченную область или создайте новый."
			label = "ПОЛ"
			color = "#e7ad64"
		else
			name = "Ржавчина: лечение не действует"
			desc = "Под ногами нет ржавого пола. Заржавьте подходящий пол Хваткой или Буйным разрастанием. Очаг тоже лечит только на ржавом полу; одного нахождения рядом с ним недостаточно."
			label = "НЕТ"
			color = "#ff9e88"
	desc += " Лечение постепенно восстанавливает здоровье, но само по себе не устраняет переломы, вывихи и другие раны."
	maptext = MAPTEXT("<div style='text-align:center;color:#ffffff;font-size:8px;background-color:#17111d'>[label]</div>")

#undef HERETIC_RUST_HEALING_ALERT

/datum/eldritch_knowledge/base_rust/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/effect/heretic_combat_zone/rust/hearth in list(combat_zone, relic_zone))
		if(!QDELETED(hearth))
			heretic_add_pocket_exit(., "Очаг - [get_area_name(hearth, TRUE)]", heretic_pocket_landing(get_turf(hearth)))

/datum/eldritch_knowledge/base_rust/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	var/list/door = list("name" = "в очаг", "text" = "Ржавый пол под [victim] расходится, как гнилая доска.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))
	if(rooted_hold(victim))
		door["remote"] = TRUE
	return door

/// Готовая цель на ржавом полу в границе своего очага; еретик рядом с ней, а с пленником корней - на любой клетке того же очага.
/datum/eldritch_knowledge/base_rust/proc/door_holds(mob/living/user, mob/living/victim)
	if(!door_user_ready(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z)
		return FALSE
	if(!istype(victim.loc, /turf/open/floor/plating/rust))
		return FALSE
	var/obj/effect/heretic_combat_zone/rust/hearth = door_zone_under(victim, /obj/effect/heretic_combat_zone/rust)
	if(!hearth)
		return FALSE
	if(get_dist(user, victim) > 1 && !(rooted_hold(victim) && (user.loc in hearth.field_turfs)))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic.hunt_target_ready(victim)

/// Хвост отказа Истории кузнеца, когда на руне нет мусора: что годится и что из лежащего рядом не годится.
/datum/eldritch_knowledge/base_rust/proc/trash_hint(list/available_atoms)
	if(locate(/obj/item/trash) in available_atoms)
		return ""
	var/static/list/near_misses = list(
		/obj/item/cigbutt = "окурок",
		/obj/item/reagent_containers/food/drinks/soda_cans = "несмятая банка",
		/obj/item/reagent_containers/food/drinks/bottle = "бутылка",
		/obj/item/broken_bottle = "разбитая бутылка",
		/obj/item/paper = "бумага",
		/obj/item/storage/box = "коробка",
		/obj/item/storage/fancy = "пачка",
	)
	var/list/seen = list()
	for(var/obj/item/candidate in available_atoms)
		for(var/miss_type in near_misses)
			if(istype(candidate, miss_type))
				seen |= near_misses[miss_type]
				break
	. = " Мусор - обёртка от съеденной закуски из торгомата, грязная тарелка или поднос, смятая банка; его полно и в техтоннелях."
	if(length(seen))
		. += " Не подходит: [jointext(seen, ", ")]."
	if("несмятая банка" in seen)
		. += " Пустую банку сомните о свою голову: «Вред» и прицел в голову."

/obj/item/trash/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(heretic && (!heretic.selected_path || heretic.selected_path == PATH_RUST))
		. += span_notice("Мансус примет это как мусор для обряда «История кузнеца»: нож и мусор на руне дают ржавый клинок.")

/datum/eldritch_knowledge/base_rust
	var/list/roots = list()
	var/roots_failure

/datum/eldritch_knowledge/base_rust/Destroy()
	release_roots()
	return ..()

/datum/eldritch_knowledge/base_rust/on_death(mob/user)
	release_roots()
	return ..()

/datum/eldritch_knowledge/base_rust/proc/release_roots()
	QDEL_LIST(roots)

/datum/eldritch_knowledge/base_rust/proc/rooted_hold(mob/living/victim)
	for(var/datum/status_effect/heretic_rust_roots/hold as anything in roots)
		if(hold.owner == victim)
			return hold
	return null

/datum/eldritch_knowledge/base_rust/proc/roots_block_reason(mob/living/user, atom/target, check_ready = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/rust_roots)
	if(!door_user_ready(user) || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_RUST_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_RUST_ROOTS_RANGE)
		return "Цель должна лежать на полу не дальше [HERETIC_RUST_ROOTS_RANGE] клеток."
	if(rooted_hold(victim))
		return "Цель уже в корнях."
	if(QDELETED(combat_zone) && QDELETED(relic_zone))
		return "Корни растут только из ржавого пола в рыжей кайме вашего очага: сначала поставьте очаг Укоренением."
	if(!istype(victim.loc, /turf/open/floor/plating/rust))
		return "Корни растут только из ржавого пола в рыжей кайме вашего очага, а цель лежит не на ржавчине."
	if(!door_zone_under(victim, /obj/effect/heretic_combat_zone/rust))
		return "Цель на ржавчине, но за рыжей каймой вашего очага: корни растут только внутри неё. Подтащите цель ближе."
	if(check_ready && !heretic_capture_downed(victim))
		return "Корни держат только сбитую с ног или обессиленную цель: сон и добровольный отдых сами по себе не в счёт."
	return null

/datum/eldritch_knowledge/base_rust/proc/start_roots(mob/living/user, mob/living/victim)
	roots_failure = roots_block_reason(user, victim)
	if(roots_failure)
		return FALSE
	var/turf/place = get_turf(victim)
	new /obj/effect/temp_visual/heretic_rust_roots_sprout(place)
	playsound(place, 'modular_bluemoon/sound/heretic/rust_roots.ogg', HERETIC_RUST_ROOTS_VOLUME, TRUE)
	user.visible_message(span_danger("Ржавый пол под [victim] трескается, и к ногам ползут корни!"), span_notice("Корни ползут к [victim]."))
	addtimer(CALLBACK(src, PROC_REF(seal_roots), user, victim, place), HERETIC_RUST_ROOTS_TELEGRAPH)
	return TRUE

/datum/eldritch_knowledge/base_rust/proc/seal_roots(mob/living/user, mob/living/victim, turf/place)
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/rust_roots, "Цель ушла с клетки, и корни опали.")
		return FALSE
	var/reason = roots_block_reason(user, victim, check_ready = FALSE)
	if(reason)
		heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/rust_roots, "Корни опали: [reason]")
		return FALSE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_rust_roots, src, door_zone_under(victim, /obj/effect/heretic_combat_zone/rust)))
		return FALSE
	log_combat(user, victim, "оплетает Ржавыми корнями")
	return TRUE

/proc/heretic_rust_pry_tool(obj/item/tool)
	if(tool?.tool_behaviour == TOOL_CROWBAR)
		return TRUE
	var/obj/item/weldingtool/welder = tool
	return istype(welder) && welder.isOn()

/proc/heretic_rust_pry_sound(obj/item/tool)
	return tool.tool_behaviour == TOOL_CROWBAR ? 'sound/items/crowbar.ogg' : 'sound/items/welder.ogg'

/proc/heretic_rust_chain_block_reason(mob/living/user, mob/living/carbon/victim)
	if(!istype(user.loc, /turf/open/floor/plating/rust))
		return "Цепь растёт из ржавого пола: встаньте на ржавчину."
	if(victim.stat == DEAD)
		return "Цепь не тащит мёртвых."
	if(victim.alerts["antag_training_safe"])
		return "Цель в безопасном центре полигона."
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_RUST_CHAIN_RANGE || !can_see(user, victim, HERETIC_RUST_CHAIN_RANGE))
		return "Нужен враг на виду не дальше [HERETIC_RUST_CHAIN_RANGE] клеток."
	if(victim.anchored || victim.buckled || (victim.pulledby && victim.pulledby != user) || victim.move_resist > MOVE_FORCE_STRONG)
		return "Цель пристёгнута, вросла или её держат: цепь её не сдёрнет."
	return null

/obj/item/melee/touch_attack/grasp_of_decay
	var/mob/living/carbon/chain_target
	var/datum/beam/chain_beam

/obj/item/melee/touch_attack/grasp_of_decay/Destroy()
	chain_target = null
	QDEL_NULL(chain_beam)
	return ..()

/obj/item/melee/touch_attack/grasp_of_decay/proc/start_chain(atom/target, mob/living/user)
	if(chain_target || target == user)
		return FALSE
	if(!iscarbon(target))
		if(isliving(target))
			to_chat(user, span_warning("Цепь хватает только людей и других существ из плоти и крови. Хватка сохранена."))
		return FALSE
	var/mob/living/carbon/victim = target
	if(IS_HERETIC(victim) || IS_HERETIC_MONSTER(victim))
		to_chat(user, span_warning("Цепь не тронет своих. Хватка сохранена."))
		return FALSE
	var/reason = heretic_rust_chain_block_reason(user, victim)
	if(reason)
		to_chat(user, span_warning("[reason] Хватка сохранена."))
		return FALSE
	chain_target = victim
	chain_beam = user.Beam(victim, icon_state = "chain", time = HERETIC_RUST_CHAIN_WINDUP + HERETIC_RUST_CHAIN_BEAM_TAIL, maxdistance = HERETIC_RUST_CHAIN_RANGE + 2)
	playsound(user, pick(GLOB.heretic_rust_grasp_sounds), HERETIC_RUST_CHAIN_VOLUME, TRUE)
	playsound(victim, pick(GLOB.heretic_rust_grasp_sounds), HERETIC_RUST_CHAIN_VOLUME, TRUE)
	user.visible_message(span_danger("Из ржавого пола под [user] вырывается цепь и обвивает [victim]!"), span_notice("Цепь обвивает [victim]. Не сходите с ржавчины."), ignored_mobs = victim)
	to_chat(victim, span_userdanger("Ржавая цепь обвивает вас и вот-вот рванёт к [user]! Скройтесь из виду или пусть товарищ вас удержит."))
	addtimer(CALLBACK(src, PROC_REF(finish_chain), user, victim), HERETIC_RUST_CHAIN_WINDUP)
	return TRUE

/obj/item/melee/touch_attack/grasp_of_decay/proc/finish_chain(mob/living/user, mob/living/carbon/victim)
	if(QDELETED(src) || chain_target != victim)
		return
	chain_target = null
	var/reason = (QDELETED(user) || QDELETED(victim)) ? "Цель пропала." : heretic_rust_chain_block_reason(user, victim)
	if(!reason && heretic_incapacitated(user))
		reason = "Вы не в силах удержать цепь."
	if(reason)
		QDEL_NULL(chain_beam)
		if(!QDELETED(user))
			to_chat(user, span_warning("Цепь лопнула. [reason] Хватка сохранена."))
		return
	if(!heretic_can_affect(user, victim))
		QDEL_NULL(chain_beam)
		victim.visible_message(span_warning("Ржавая цепь рассыпается хлопьями, едва коснувшись [victim]."))
		spend_chain(user, victim)
		return
	victim.Knockdown(HERETIC_RUST_CHAIN_KNOCKDOWN)
	victim.apply_status_effect(/datum/status_effect/corrosion_curse/lesser)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(victim))
	playsound(victim, 'modular_bluemoon/sound/heretic/rust_decay.ogg', 70, TRUE)
	victim.visible_message(span_danger("Ржавая цепь рывком тащит [victim] по полу к [user], оставляя ржавую борозду!"), span_userdanger("Цепь рвёт вас с места и тащит к [user]!"))
	var/turf/start = victim.loc
	start.rust_heretic_act()
	heretic_rust_chain_drag(user, victim, HERETIC_RUST_CHAIN_RANGE)
	log_combat(user, victim, "подтаскивает Ржавой цепью Хватки распада")
	// Цепь видна весь рывок и гаснет по своему таймеру, а рука уходит сразу.
	chain_beam = null
	spend_chain(user, victim)

/// Цепь не сбрасывает в пропасть, лаву и провал на нижний уровень: рывок кончается у края.
/proc/heretic_rust_chain_hazard(turf/place)
	return istype(place, /turf/open/chasm) || islava(place) || istype(place, /turf/open/openspace)

/// Шаг за шагом, а не бросок: бросок без гравитации пролетает мимо еретика.
/proc/heretic_rust_chain_drag(mob/living/user, mob/living/victim, steps_left)
	if(QDELETED(user) || QDELETED(victim) || steps_left <= 0 || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) <= 1)
		return
	var/turf/next = get_step_towards(victim, user)
	var/direction = get_dir(victim, next)
	// Диагональный шаг Move делит на два прямых: опасной не должна быть ни одна промежуточная клетка.
	if(ISDIAGONALDIR(direction))
		var/turf/vertical = get_step(victim, direction & (NORTH|SOUTH))
		var/turf/horizontal = get_step(victim, direction & (EAST|WEST))
		var/vertical_hazard = heretic_rust_chain_hazard(vertical)
		var/horizontal_hazard = heretic_rust_chain_hazard(horizontal)
		if(vertical_hazard && horizontal_hazard)
			return
		if(vertical_hazard)
			next = horizontal
		else if(horizontal_hazard)
			next = vertical
	if(heretic_rust_chain_hazard(next))
		return
	victim.set_glide_size(DELAY_TO_GLIDE_SIZE(HERETIC_RUST_CHAIN_STEP))
	if(!victim.Move(next, get_dir(victim, next)))
		return
	next.rust_heretic_act()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_rust_chain_drag), user, victim, steps_left - 1), HERETIC_RUST_CHAIN_STEP)

/obj/item/melee/touch_attack/grasp_of_decay/proc/spend_chain(mob/living/user, mob/living/victim)
	user.say(catchphrase, forced = "spell")
	charges--
	charges_check()

/datum/status_effect/heretic_rust_roots
	id = "heretic_rust_roots"
	duration = HERETIC_RUST_ROOTS_DURATION
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_rust_roots
	examine_text = span_warning("SUBJECTPRONOUN врастает в ржавый пол: корни оплели ноги. Их рвёт нулевой жезл, а лом или зажжённая сварка - за 2 секунды; пленника можно растолкать.")
	var/datum/weakref/rust_ref
	var/obj/effect/heretic_combat_zone/rust/hearth
	var/turf/rooted_turf
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/obj/effect/abstract/heretic_vfx_attached/roots_visual
	var/held_since = 0
	var/was_anchored = FALSE
	var/applied = FALSE

/datum/status_effect/heretic_rust_roots/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_rust/rust, obj/effect/heretic_combat_zone/rust/hold_zone)
	rust_ref = WEAKREF(rust)
	hearth = hold_zone
	return ..()

/datum/status_effect/heretic_rust_roots/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_rust/rust = rust_ref?.resolve()
	if(!. || !rust || QDELETED(hearth) || !isturf(owner.loc))
		return FALSE
	rust.roots += src
	applied = TRUE
	held_since = world.time
	rooted_turf = owner.loc
	owner.pulledby?.stop_pulling()
	owner.buckled?.unbuckle_mob(owner, TRUE)
	owner.stop_pulling()
	was_anchored = owner.anchored
	owner.set_anchored(TRUE)
	// Свой экземпляр не продлевает и не снимает чужой паралич.
	restraint = new(list(owner, HERETIC_RUST_ROOTS_DURATION, TRUE))
	roots_visual = heretic_vfx_attach(owner, HERETIC_RUST_FX_ICON, "rust_roots_grow", fade_in = 0, glow = FALSE, upright = FALSE)
	if(roots_visual)
		roots_visual.vis_flags |= VIS_INHERIT_DIR
		addtimer(CALLBACK(src, PROC_REF(settle_roots)), HERETIC_RUST_ROOTS_GROW)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_owner_moved))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignals(owner, list(COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_DEATH), PROC_REF(end_roots))
	RegisterSignal(hearth, COMSIG_PARENT_QDELETING, PROC_REF(end_roots))
	heretic_capture_hold(owner, HERETIC_RUST_CAPTURE)
	owner.visible_message(span_danger("Ржавые корни оплетают ноги [owner] и врастают в пол!"), span_userdanger("Ржавчина ползёт по ногам: вы вросли в пол!"))

/datum/status_effect/heretic_rust_roots/proc/settle_roots()
	if(!QDELETED(roots_visual))
		roots_visual.icon_state = "rust_roots"

/datum/status_effect/heretic_rust_roots/proc/on_owner_moved(datum/source)
	SIGNAL_HANDLER
	if(owner.loc != rooted_turf)
		qdel(src)

/datum/status_effect/heretic_rust_roots/proc/end_roots(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_rust_roots/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(istype(item, /obj/item/nullrod))
		user.visible_message(span_warning("[user] касается [source] нулевым жезлом, и ржавые корни рассыпаются трухой."), span_notice("Вы касаетесь [source] нулевым жезлом, и корни рассыпаются."))
		log_game("[key_name(user)] снимает Ржавые корни с [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
		qdel(src)
		return COMPONENT_NO_AFTERATTACK
	if(!heretic_rust_pry_tool(item) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(pry), user, item)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_rust_roots/proc/pry(mob/living/user, obj/item/tool)
	if(LAZYFIND(user.do_afters, owner))
		return FALSE
	user.visible_message(span_warning("[user] поддевает [tool] ржавые корни на ногах [owner]."), span_notice("Вы рвёте корни. Не отходите [DisplayTimeText(HERETIC_RUST_PRY_TIME)]."))
	playsound(owner, heretic_rust_pry_sound(tool), HERETIC_RUST_PRY_VOLUME, TRUE)
	if(!do_after(user, HERETIC_RUST_PRY_TIME, owner, extra_checks = CALLBACK(src, PROC_REF(still_rooted))))
		return FALSE
	if(QDELETED(src))
		return FALSE
	user.visible_message(span_notice("[user] выдирает корни из пола, и [owner] снова может двигаться."))
	log_game("[key_name(user)] вырывает [key_name(owner)] из Ржавых корней в [AREACOORD(owner)].")
	qdel(src)
	return TRUE

/datum/status_effect/heretic_rust_roots/proc/still_rooted()
	return !QDELETED(src)

/datum/status_effect/heretic_rust_roots/on_remove()
	var/datum/eldritch_knowledge/base_rust/rust = rust_ref?.resolve()
	rust?.roots -= src
	if(applied)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_DEATH))
		if(hearth)
			UnregisterSignal(hearth, COMSIG_PARENT_QDELETING)
		heretic_capture_unhold(owner, HERETIC_RUST_CAPTURE)
		// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
		if(!QDELETED(restraint) && restraint.duration <= duration)
			qdel(restraint)
		owner.set_anchored(was_anchored)
		if(QDELETED(owner))
			qdel(roots_visual)
		else
			roots_visual?.fade_out()
			heretic_vfx_burst(owner, /particles/heretic_ascension/rust/heart_wound)
			if(isturf(owner.loc))
				playsound(owner, HERETIC_RUST_ROOTS_RELEASE_SOUND, HERETIC_RUST_ROOTS_RELEASE_VOLUME, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
		heretic_capture_release(owner, HERETIC_RUST_CAPTURE, held_for = heretic_capture_held_for(held_since))
	restraint = null
	roots_visual = null
	hearth = null
	rooted_turf = null
	rust_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_rust_roots
	name = "Ржавые корни"
	desc = "Корни вросли в ноги: до 10 секунд вы не двигаетесь. Товарищ сорвёт их нулевым жезлом сразу, ломом или зажжённой сваркой за 2 секунды или растолкает вас. Если очаг угаснет или его разобьют, корни отпустят."
	icon = HERETIC_RUST_FX_ICON
	icon_state = "rust_roots_alert"

/// Пол трескается, и корни тянутся к цели всю секунду телеграфа.
/obj/effect/temp_visual/heretic_rust_roots_sprout
	icon = HERETIC_RUST_FX_ICON
	icon_state = "rust_roots_sprout"
	layer = BELOW_MOB_LAYER
	randomdir = FALSE
	duration = HERETIC_RUST_ROOTS_TELEGRAPH

/obj/effect/proc_holder/spell/pointed/rust_roots
	name = "Ржавые корни"
	desc = "Сбитый с ног или обессиленный враг в 5 клетках на ржавом полу вашего очага через секунду врастает в пол: до 10 секунд он не действует и его не сдвинуть, а сердце уводит его в изнанку из любой клетки очага. Корни рвёт нулевой жезл, лом или зажжённая сварка за 2 секунды, пленника можно растолкать. Перезарядка 40 секунд."
	summary = "Сбитый враг на ржавчине очага на 10 секунд врастает в пол; увод из любой клетки очага."
	school = "transmutation"
	charge_max = HERETIC_RUST_ROOTS_COOLDOWN
	range = HERETIC_RUST_ROOTS_RANGE
	clothes_req = FALSE
	heretic_stun_check = TRUE
	selection_type = "view"
	aim_assist = FALSE
	invocation = "SAK'NYS LAI'KO"
	invocation_type = "whisper"
	action_icon = HERETIC_RUST_FX_ICON
	action_icon_state = "rust_roots_action"
	action_background_icon_state = "bg_ecult"
	active_msg = "Вы слушаете корни под ржавым полом. Укажите сбитого врага."
	deactive_msg = "Корни затихают."

/obj/effect/proc_holder/spell/pointed/rust_roots/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_rust/rust = heretic?.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/reason = rust ? rust.roots_block_reason(user, target) : "Способность недоступна вашему пути или текущему телу."
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/rust_roots/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_rust/rust = heretic?.get_knowledge(/datum/eldritch_knowledge/base_rust)
	if(!length(targets) || !rust?.start_roots(user, targets[1]))
		heretic_revert_cast(user, rust?.roots_failure)

/obj/effect/proc_holder/spell/pointed/rust_formation
	name = "Ржавая формация"
	desc = "Поднимите стену в 4 клетках из ржавого пола или клетки вплотную к нему - та сначала ржавеет; пока способность выбрана, годные клетки обведены рыжим. 20 секунд стена держит пули и закрывает обзор, а вы и ваши слуги проходите сквозь неё. Врага на этой клетке отбросит в сторону: 10 ушибов и 2 секунды на полу. Стену разбивают оружием, а ломом или зажжённой сваркой разбирают за 2 секунды. Перезарядка 15 секунд."
	summary = "Стена из ржавого пола или рядом с ним на 20 секунд: держит пули, пропускает своих, врага отбрасывает."
	school = "transmutation"
	charge_max = HERETIC_RUST_FORMATION_COOLDOWN
	range = HERETIC_RUST_FORMATION_RANGE
	clothes_req = FALSE
	heretic_stun_check = TRUE
	selection_type = "view"
	aim_assist = FALSE
	invocation = "SIE'NA RU'DIS"
	invocation_type = "whisper"
	action_icon = HERETIC_RUST_FX_ICON
	action_icon_state = "rust_formation_action"
	action_background_icon_state = "bg_ecult"
	active_msg = "Вы тянете ржавчину из пола. Укажите клетку в рыжей обводке: ржавую или вплотную к ржавчине."
	deactive_msg = "Ржавчина оседает обратно в пол."
	var/list/hint_images = list()
	var/datum/weakref/hinted_user

/obj/effect/proc_holder/spell/pointed/rust_formation/Destroy()
	clear_hints()
	return ..()

/obj/effect/proc_holder/spell/pointed/rust_formation/on_activation(mob/user)
	show_hints(user)

/obj/effect/proc_holder/spell/pointed/rust_formation/on_deactivation(mob/user)
	clear_hints()

/obj/effect/proc_holder/spell/pointed/rust_formation/proc/hint_tiles(mob/living/user)
	. = list()
	for(var/turf/place as anything in RANGE_TURFS(HERETIC_RUST_FORMATION_RANGE, user))
		if(heretic_rust_formation_ground(place) && !place.is_blocked_turf(exclude_mobs = TRUE) && can_see(user, place, HERETIC_RUST_FORMATION_RANGE))
			. += place

/// Годные клетки видит только сам еретик: обводка по краю области, как у очага.
/obj/effect/proc_holder/spell/pointed/rust_formation/proc/show_hints(mob/living/user)
	clear_hints()
	if(!isliving(user))
		return
	hinted_user = WEAKREF(user)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_hinted_moved), override = TRUE)
	var/list/tiles = hint_tiles(user)
	var/static/list/edge_states = list("[NORTH]" = "space_protection_south", "[SOUTH]" = "space_protection_north", "[EAST]" = "space_protection_west", "[WEST]" = "space_protection_east")
	var/edge_icon = 'modular_bluemoon/icons/obj/heretic_oldpath_effects.dmi'
	var/list/tint = color_matrix_multiply(color_matrix_saturation(0), color_hex2color_matrix(HERETIC_RUST_HINT_COLOR))
	for(var/turf/place as anything in tiles)
		var/image/hint = image(edge_icon, place, null, ABOVE_MOB_LAYER)
		hint.color = tint
		hint.alpha = HERETIC_RUST_HINT_ALPHA
		for(var/direction in GLOB.cardinals)
			if(get_step(place, direction) in tiles)
				continue
			hint.overlays += edge_states["[direction]"]
			hint.overlays += emissive_appearance(edge_icon, edge_states["[direction]"], offset_spokesman = place)
		hint_images += hint
	user.client?.images += hint_images

/obj/effect/proc_holder/spell/pointed/rust_formation/proc/clear_hints()
	var/mob/living/user = hinted_user?.resolve()
	hinted_user = null
	if(user)
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		user.client?.images -= hint_images
	hint_images.Cut()

/obj/effect/proc_holder/spell/pointed/rust_formation/proc/on_hinted_moved(mob/living/source)
	SIGNAL_HANDLER
	if(active && ranged_ability_user == source)
		show_hints(source)
	else
		clear_hints()

/obj/effect/proc_holder/spell/pointed/rust_formation/can_target(atom/target, mob/user, silent)
	var/reason = heretic_rust_formation_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason)

/obj/effect/proc_holder/spell/pointed/rust_formation/cast(list/targets, mob/living/user)
	if(!length(targets) || !heretic_rust_raise_formation(user, get_turf(targets[1])))
		heretic_revert_cast(user, heretic_rust_formation_block_reason(user, length(targets) ? targets[1] : null))

/// Ржавый пол или поддающийся ржавчине пол вплотную к нему.
/proc/heretic_rust_formation_ground(turf/place)
	if(istype(place, /turf/open/floor/plating/rust))
		return TRUE
	var/turf/open/floor/floor = place
	if(!istype(floor) || !floor.heretic_rustable)
		return FALSE
	for(var/turf/open/floor/plating/rust/neighbor in RANGE_TURFS(1, floor))
		return TRUE
	return FALSE

/proc/heretic_rust_formation_block_reason(mob/living/user, atom/target)
	var/turf/place = get_turf(target)
	if(!heretic_rust_formation_ground(place))
		return "Стена встаёт из ржавого пола или из клетки вплотную к нему: годные клетки обведены рыжим."
	if(place.z != user.z || get_dist(user, place) > HERETIC_RUST_FORMATION_RANGE || !can_see(user, place, HERETIC_RUST_FORMATION_RANGE))
		return "Нужна видимая клетка не дальше [HERETIC_RUST_FORMATION_RANGE] клеток."
	if(place.is_blocked_turf(exclude_mobs = TRUE))
		return "Клетку уже занимает что-то плотное."
	for(var/mob/living/stander in place)
		if(!heretic_rust_formation_spares(stander) && !heretic_rust_formation_aside(user, place))
			return "[stander] некуда отбросить."
	return null

/proc/heretic_rust_formation_spares(mob/living/stander)
	return IS_HERETIC(stander) || IS_HERETIC_MONSTER(stander)

/// Свободная клетка рядом с местом стены, сначала - прочь от еретика.
/proc/heretic_rust_formation_aside(mob/living/user, turf/place)
	var/list/directions = list(get_dir(user, place)) | GLOB.alldirs
	for(var/direction in directions)
		if(!direction)
			continue
		var/turf/aside = get_step(place, direction)
		if(isopenturf(aside) && !aside.is_blocked_turf(exclude_mobs = TRUE) && heretic_step_open(place, aside))
			return aside
	return null

/proc/heretic_rust_raise_formation(mob/living/user, turf/place)
	if(heretic_rust_formation_block_reason(user, place))
		return null
	if(!istype(place, /turf/open/floor/plating/rust))
		place = place.rust_heretic_act()
		if(!place)
			return null
	for(var/mob/living/stander in place)
		if(heretic_rust_formation_spares(stander))
			continue
		stander.forceMove(heretic_rust_formation_aside(user, place))
		if(!heretic_can_affect(user, stander))
			continue
		stander.apply_damage(HERETIC_RUST_FORMATION_DAMAGE, BRUTE)
		stander.Knockdown(HERETIC_RUST_FORMATION_KNOCKDOWN)
		stander.visible_message(span_danger("Ржавая глыба вырывается из пола и отшвыривает [stander]!"), span_userdanger("Из пола под вами вырывается ржавая глыба и отшвыривает вас!"))
		log_combat(user, stander, "отбрасывает Ржавой формацией")
	user.visible_message(span_danger("[user] тянет руку вверх, и из ржавого пола встаёт глыба!"), span_notice("Вы поднимаете ржавую стену."))
	return new /obj/structure/heretic_rust_formation(place)

/obj/structure/heretic_rust_formation
	name = "rust formation"
	desc = "Глыба ржавых листов, вырванная из пола. Простоит 20 секунд и осыплется; её можно разбить оружием, а ломом или зажжённой сваркой разобрать за 2 секунды. Еретик и его слуги проходят сквозь неё."
	icon = HERETIC_RUST_FX_ICON
	icon_state = "rust_formation"
	density = TRUE
	opacity = TRUE
	anchored = TRUE
	max_integrity = HERETIC_RUST_FORMATION_INTEGRITY
	armor_type = /datum/armor/heretic_rust
	var/prying = FALSE

/obj/structure/heretic_rust_formation/Initialize(mapload)
	. = ..()
	flick("rust_formation_rise", src)
	playsound(src, pick(GLOB.heretic_rust_formation_sounds), HERETIC_RUST_FORMATION_VOLUME, TRUE)
	heretic_vfx_burst(src, /particles/heretic_ascension/rust/heart_wound)
	QDEL_IN(src, HERETIC_RUST_FORMATION_LIFETIME)

/obj/structure/heretic_rust_formation/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(isliving(mover) && heretic_rust_formation_spares(mover))
		return TRUE

/obj/structure/heretic_rust_formation/attackby(obj/item/tool, mob/living/user, params)
	if(!heretic_rust_pry_tool(tool) || heretic_rust_formation_spares(user))
		return ..()
	INVOKE_ASYNC(src, PROC_REF(pry), user, tool)
	return TRUE

/obj/structure/heretic_rust_formation/proc/pry(mob/living/user, obj/item/tool)
	if(prying)
		return FALSE
	prying = TRUE
	user.visible_message(span_warning("[user] поддевает [tool] ржавые листы [src]."), span_notice("Вы разбираете ржавую глыбу. Не отходите [DisplayTimeText(HERETIC_RUST_PRY_TIME)]."))
	playsound(src, heretic_rust_pry_sound(tool), HERETIC_RUST_PRY_VOLUME, TRUE)
	. = do_after(user, HERETIC_RUST_PRY_TIME, src)
	if(QDELETED(src))
		return
	prying = FALSE
	if(!.)
		return
	user.visible_message(span_notice("[user] разбирает ржавую глыбу."))
	qdel(src)

/obj/structure/heretic_rust_formation/rust_heretic_act()
	return

/obj/structure/heretic_rust_formation/Destroy()
	var/turf/place = get_turf(src)
	if(place)
		new /obj/effect/temp_visual/heretic_rust_formation_fall(place)
		playsound(place, HERETIC_RUST_COLLAPSE_SOUND, HERETIC_RUST_FORMATION_VOLUME, TRUE)
	return ..()

/// Глыба оседает трухой в пол.
/obj/effect/temp_visual/heretic_rust_formation_fall
	icon = HERETIC_RUST_FX_ICON
	icon_state = "rust_formation_fall"
	randomdir = FALSE
	duration = HERETIC_RUST_FORMATION_FALL

/atom/movable/screen/alert/status_effect/heretic_rust_corrosion
	name = "Ржавый пол"
	desc = "Ржавчина еретика под ногами разъедает вас: 2 урона коррозией в секунду, тошнота, химия вымывается из крови, протезы ржавеют, а ботов и роботов пол ломает. Сойдите с ржавого пола; защита от магии спасает."
	icon = HERETIC_RUST_FX_ICON
	icon_state = "rust_corrosion_alert"

/// Ржавчина: пыль у ног того, кого разъедает ржавый пол.
/particles/heretic_ascension/rust/dust
	count = 8
	spawning = 0.35
	position = generator("box", list(-9, -15, 0), list(9, -11, 0))
	velocity = generator("box", list(-0.25, 0.2, 0), list(0.25, 0.6, 0))
	gravity = list(0, -0.04)
	friction = 0.04
	lifespan = 1.4 SECONDS
	fade = 0.6 SECONDS
	fadein = 0.2 SECONDS

/// Пока сердце вознесения цело, ржавый пол вдвое снижает урон выносливости вознесённому.
/datum/component/heretic_rust_ascension
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/knowledge_ref
	var/stamina_applied = FALSE

/datum/component/heretic_rust_ascension/Initialize(datum/eldritch_knowledge/final_eldritch/rust_final/knowledge)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	knowledge_ref = WEAKREF(knowledge)
	update_stamina()

/datum/component/heretic_rust_ascension/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/heretic_rust_ascension/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_EXAMINE))
	set_stamina(FALSE)

/datum/component/heretic_rust_ascension/proc/rust_empowered()
	var/mob/living/owner = parent
	var/datum/eldritch_knowledge/final_eldritch/rust_final/knowledge = knowledge_ref?.resolve()
	return knowledge?.heart_alive() && owner.stat != DEAD && istype(get_turf(owner), /turf/open/floor/plating/rust)

/datum/component/heretic_rust_ascension/proc/update_stamina()
	set_stamina(rust_empowered())

/datum/component/heretic_rust_ascension/proc/set_stamina(active)
	active = !!active
	if(active == stamina_applied || !ishuman(parent))
		return
	var/mob/living/carbon/human/owner = parent
	stamina_applied = active
	if(!owner.physiology)
		return
	if(active)
		owner.physiology.heretic_stamina_mod *= HERETIC_RUST_ASCENDED_STAMINA_MOD
	else
		owner.physiology.heretic_stamina_mod /= HERETIC_RUST_ASCENDED_STAMINA_MOD

/datum/component/heretic_rust_ascension/proc/on_moved(mob/living/source, atom/old_loc, movement_dir, forced)
	SIGNAL_HANDLER
	update_stamina()

/datum/component/heretic_rust_ascension/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/datum/eldritch_knowledge/final_eldritch/rust_final/knowledge = knowledge_ref?.resolve()
	if(knowledge?.heart_alive())
		examine_list += span_warning("Ржавчина под ногами кормит это тело. Выманите его с ржавого пола или разбейте Ржавое сердце.")
	else
		examine_list += span_notice("Ржавчина под ногами больше не отзывается: сердце разбито.")

/obj/structure/heretic_rust_ascension_heart
	name = "heart of the rusted garden"
	desc = "Ржавое сердце: огромный пульсирующий ком металла, вросший в пол на месте вознесения еретика. Пока оно бьётся, ржавчина расползается по станции, а вознесённый лечится на ржавом полу и получает там вдвое меньше урона выносливости. Разбейте его обычным оружием, и ржавчина остановится навсегда."
	icon = 'modular_bluemoon/icons/obj/heretic_rust_heart.dmi'
	icon_state = "tumor"
	pixel_x = -16
	color = COLOR_WHITE
	anchored = TRUE
	density = FALSE
	max_integrity = HERETIC_RUST_HEART_INTEGRITY
	armor_type = /datum/armor/heretic_rust_reinforced
	appearance_flags = PIXEL_SCALE
	var/obj/effect/abstract/heretic_particle_holder/flakes
	COOLDOWN_DECLARE(wound_cooldown)

/obj/structure/heretic_rust_ascension_heart/Initialize(mapload)
	. = ..()
	transform = matrix() * HERETIC_RUST_HEART_SCALE
	var/mutable_appearance/veins = mutable_appearance(icon, "tumor_glow")
	veins.color = HERETIC_RUST_INK
	veins.alpha = HERETIC_RUST_HEART_VEINS
	veins.appearance_flags = RESET_COLOR
	add_overlay(veins)
	add_overlay(emissive_appearance(icon, "tumor_glow", alpha = HERETIC_RUST_HEART_GLOW, offset_spokesman = src))
	flakes = heretic_vfx_attach_particles(src, /particles/heretic_ascension/rust/heart, FALSE)
	if(flakes)
		flakes.pixel_x = -pixel_x
	beat()
	var/rest_y = pixel_y
	alpha = 0
	pixel_y = rest_y - HERETIC_RUST_HEART_RISE
	animate(src, alpha = 255, pixel_y = rest_y, time = HERETIC_RUST_HEART_EMERGE, easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	new /obj/effect/temp_visual/heretic_oldpath/rust(get_turf(src))
	heretic_vfx_burst(src, /particles/heretic_ascension/rust)
	playsound(src, pick(GLOB.heretic_rust_heart_rise_sounds), HERETIC_RUST_HEART_RISE_VOLUME, FALSE)

/// Медленный двойной удар: сердце набухает и темнеет в такт, свечение дышит вместе с ним.
/obj/structure/heretic_rust_ascension_heart/proc/beat()
	var/matrix/rest = matrix() * HERETIC_RUST_HEART_SCALE
	var/flush = BlendRGB(initial(color), HERETIC_RUST_INK, HERETIC_RUST_HEART_FLUSH_SHARE)
	animate(src, transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_SWELL), color = flush, time = HERETIC_RUST_HEART_BEAT, easing = SINE_EASING | EASE_OUT, loop = -1)
	animate(transform = rest, color = initial(color), time = HERETIC_RUST_HEART_BEAT * 2, easing = SINE_EASING | EASE_IN)
	animate(transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_ECHO), color = flush, time = HERETIC_RUST_HEART_BEAT, easing = SINE_EASING | EASE_OUT)
	animate(transform = rest, color = initial(color), time = HERETIC_RUST_HEART_BEAT * 2, easing = SINE_EASING | EASE_IN)
	animate(transform = rest, time = HERETIC_RUST_HEART_REST)

/obj/structure/heretic_rust_ascension_heart/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(!damage_amount || (damage_type != BRUTE && damage_type != BURN))
		return ..()
	playsound(src, pick(GLOB.heretic_rust_heart_hit_sounds), HERETIC_RUST_HEART_HIT_VOLUME, TRUE, MEDIUM_RANGE_SOUND_EXTRARANGE)

/obj/structure/heretic_rust_ascension_heart/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir, armour_penetration = 0)
	. = ..()
	if(!. || QDELETED(src) || !COOLDOWN_FINISHED(src, wound_cooldown))
		return
	COOLDOWN_START(src, wound_cooldown, HERETIC_RUST_HEART_WOUND_COOLDOWN)
	shudder()
	heretic_vfx_burst(src, /particles/heretic_ascension/rust/heart_wound)
	heretic_vfx_pulse(src, HERETIC_RUST_DARK_INK, 1, HERETIC_RUST_HEART_WOUND_PULSE)

/// Дрожь сдвигом, а не поворотом: поворот сбил бы такт сердца.
/obj/structure/heretic_rust_ascension_heart/proc/shudder()
	var/rest_x = initial(pixel_x)
	animate(src, pixel_x = rest_x + HERETIC_RUST_HEART_SHUDDER, time = HERETIC_RUST_HEART_SHUDDER_STEP / 2, flags = ANIMATION_PARALLEL)
	animate(pixel_x = rest_x - HERETIC_RUST_HEART_SHUDDER, time = HERETIC_RUST_HEART_SHUDDER_STEP)
	animate(pixel_x = rest_x + HERETIC_RUST_HEART_SHUDDER / 2, time = HERETIC_RUST_HEART_SHUDDER_STEP)
	animate(pixel_x = rest_x, time = HERETIC_RUST_HEART_SHUDDER_STEP, easing = SINE_EASING | EASE_OUT)

/obj/structure/heretic_rust_ascension_heart/rust_heretic_act()
	return

/obj/structure/heretic_rust_ascension_heart/Destroy()
	visible_message(span_danger("[src] лопается, осыпаясь ржавой трухой!"))
	var/turf/place = get_turf(src)
	if(place)
		new /obj/effect/temp_visual/heretic_oldpath/rust(place)
		new /obj/effect/temp_visual/heretic_rust_heart_collapse(place)
		heretic_vfx_burst(place, /particles/heretic_ascension/rust/collapse)
		heretic_vfx_shockwave(place, HERETIC_RUST_DARK_INK, HERETIC_RUST_HEART_DEATH_RADIUS, HERETIC_RUST_HEART_DEATH_WAVE)
		heretic_vfx_flash(place, HERETIC_RUST_DARK_INK, HERETIC_RUST_HEART_DEATH_RADIUS + 1, HERETIC_RUST_HEART_DEATH_POWER, HERETIC_RUST_HEART_DEATH_FLASH)
	playsound(src, pick(GLOB.heretic_rust_heart_break_sounds), HERETIC_RUST_HEART_BREAK_VOLUME, FALSE, HERETIC_RUST_HEART_BREAK_SOUND_RANGE)
	heretic_vfx_release_particles(src, flakes)
	flakes = null
	return ..()

/// Разбитое сердце вздрагивает последний раз и оседает в пол, темнея.
/obj/effect/temp_visual/heretic_rust_heart_collapse
	icon = 'modular_bluemoon/icons/obj/heretic_rust_heart.dmi'
	icon_state = "tumor"
	pixel_x = -16
	layer = OBJ_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_RUST_HEART_COLLAPSE

/obj/effect/temp_visual/heretic_rust_heart_collapse/Initialize(mapload)
	. = ..()
	var/obj/structure/heretic_rust_ascension_heart/heart_type = /obj/structure/heretic_rust_ascension_heart
	color = initial(heart_type.color)
	transform = matrix() * HERETIC_RUST_HEART_SCALE
	animate(src, transform = matrix() * (HERETIC_RUST_HEART_SCALE * HERETIC_RUST_HEART_SWELL * HERETIC_RUST_HEART_SWELL), time = duration / 6, easing = SINE_EASING | EASE_OUT)
	animate(transform = matrix(HERETIC_RUST_HEART_SCALE * HERETIC_RUST_COLLAPSE_SPREAD, 0, 0, 0, HERETIC_RUST_HEART_SCALE * HERETIC_RUST_COLLAPSE_SQUASH, -HERETIC_RUST_COLLAPSE_SINK), color = HERETIC_RUST_DARK_INK, alpha = 0, time = duration * 5 / 6, easing = QUAD_EASING | EASE_IN)

/obj/effect/proc_holder/spell/self/rust_corrosive_wave
	name = "Коррозийный вал"
	desc = "Волна ржавчины бьёт всё, что видно в 5 клетках: 20 урона коррозией врагам, полы ржавеют, внутренние стены рушатся. Наружные стены и корпус шаттла она не трогает, укреплённые только ржавит, стены и двери её держат; не оглушает, перезарядка 40 секунд."
	summary = "20 урона коррозией врагам в 5 клетках, полы ржавеют, внутренние стены рушатся."
	school = "transmutation"
	charge_max = HERETIC_RUST_WAVE_COOLDOWN
	clothes_req = FALSE
	invocation = "FERR'UM UN'DA"
	invocation_type = "shout"
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "rust_corrosive_wave"
	action_background_icon_state = "bg_ecult"
	var/static/list/hull_walls = typecacheof(list(/turf/closed/wall/mineral/titanium, /turf/closed/wall/mineral/plastitanium))

/obj/effect/proc_holder/spell/self/rust_corrosive_wave/cast(list/targets, mob/living/user)
	var/turf/origin = get_turf(user)
	if(!origin)
		return
	heretic_sky_event_for(user, /datum/eldritch_knowledge/final_eldritch/rust_final)
	var/list/field = heretic_field_view(HERETIC_RUST_WAVE_RANGE, origin)
	for(var/mob/living/victim in field)
		if(!heretic_can_affect(user, victim))
			continue
		heretic_corrosion(victim, HERETIC_RUST_WAVE_CORROSION)
		log_combat(user, victim, "поражает Коррозийным валом")
	var/list/rings = list()
	var/walls_fell = FALSE
	for(var/turf/surface in field)
		if(istype(surface, /turf/closed/wall/r_wall/rust) || is_type_in_typecache(surface, hull_walls) || (iswallturf(surface) && faces_void(surface)))
			continue
		if(iswallturf(surface) && !istype(surface, /turf/closed/wall/r_wall))
			var/turf/closed/wall/wall = surface
			wall.dismantle_wall(silent = TRUE)
			walls_fell = TRUE
			heretic_vfx_burst(surface, /particles/heretic_ascension/rust/heart_wound)
			continue
		var/was_rust = is_heretic_rust_turf(surface)
		var/mutable_appearance/old_look = (isopenturf(surface) && !was_rust) ? new /mutable_appearance(surface) : null
		var/surface_x = surface.x
		var/surface_y = surface.y
		var/surface_z = surface.z
		surface.rust_heretic_act()
		var/turf/changed = locate(surface_x, surface_y, surface_z)
		if(was_rust || !is_heretic_rust_turf(changed))
			continue
		var/distance = max(0, get_dist(origin, changed))
		var/delay = distance * HERETIC_RUST_RIPPLE_STEP
		if(old_look)
			new /obj/effect/temp_visual/heretic_rust_veil(changed, old_look, delay)
			LAZYADDASSOCLIST(rings, "[distance]", changed)
		for(var/obj/effect/temp_visual/glowing_rune/rune in changed)
			rune.alpha = 0
			animate(rune, alpha = 255, time = HERETIC_RUST_RIPPLE_REVEAL, delay = delay, easing = SINE_EASING | EASE_OUT)
	for(var/distance in rings)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_rust_creep_ring), rings[distance]), text2num(distance) * HERETIC_RUST_RIPPLE_STEP)
	new /obj/effect/temp_visual/heretic_oldpath/rust(origin)
	heretic_vfx_shockwave(origin, HERETIC_RUST_INK, HERETIC_RUST_WAVE_RANGE, HERETIC_RUST_WAVE_TIME)
	heretic_vfx_burst(origin, /particles/heretic_ascension/rust)
	heretic_vfx_flash(origin, HERETIC_RUST_INK, HERETIC_RUST_WAVE_FLASH_RANGE, HERETIC_RUST_WAVE_FLASH_POWER)
	heretic_vfx_quake(origin, HERETIC_RUST_WAVE_RANGE, HERETIC_RUST_WAVE_QUAKE, HERETIC_RUST_WAVE_QUAKE_TIME)
	playsound(origin, pick(GLOB.heretic_rust_wave_sounds), HERETIC_RUST_WAVE_VOLUME, TRUE, HERETIC_RUST_WAVE_SOUND_RANGE)
	if(walls_fell)
		playsound(origin, HERETIC_RUST_COLLAPSE_SOUND, HERETIC_RUST_WAVE_COLLAPSE_VOLUME, TRUE, HERETIC_RUST_WAVE_SOUND_RANGE)
	user.visible_message(span_danger("От [user] расходится волна ржавчины, разъедая всё вокруг!"))

/obj/effect/proc_holder/spell/self/rust_corrosive_wave/proc/faces_void(turf/wall)
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(wall, direction)
		if(!neighbor || isgroundlessturf(neighbor))
			return TRUE
	return FALSE

/proc/heretic_rust_creep_ring(list/turfs)
	for(var/turf/place as anything in turfs)
		new /obj/effect/temp_visual/heretic_rust_creep(place)

/// Прежний пол держится поверх ржавого и растворяется, когда до клетки доходит волна вала.
/obj/effect/temp_visual/heretic_rust_veil
	randomdir = FALSE
	duration = HERETIC_RUST_RIPPLE_DISSOLVE

/obj/effect/temp_visual/heretic_rust_veil/Initialize(mapload, mutable_appearance/old_look, delay = 0)
	duration = delay + HERETIC_RUST_RIPPLE_DISSOLVE
	. = ..()
	if(!old_look)
		return INITIALIZE_HINT_QDEL
	appearance = old_look
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FLOOR_PLANE
	layer = TURF_LAYER
	animate(src, alpha = 255, time = delay)
	animate(alpha = 0, time = HERETIC_RUST_RIPPLE_DISSOLVE, easing = SINE_EASING | EASE_IN)

/// Ржавчина проедает клетку пятнами от нескольких очагов, хлопья приподнимаются и гаснут.
/obj/effect/temp_visual/heretic_rust_creep
	icon = 'modular_bluemoon/icons/effects/heretic_vfx.dmi'
	icon_state = "rust_creep"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	randomdir = FALSE
	appearance_flags = PIXEL_SCALE
	duration = HERETIC_RUST_CREEP_HOLD + HERETIC_RUST_CREEP_FADE

/obj/effect/temp_visual/heretic_rust_creep/Initialize(mapload)
	. = ..()
	transform = matrix(pick(-1, 1), 0, 0, 0, pick(-1, 1), 0)
	animate(src, alpha = 255, time = HERETIC_RUST_CREEP_HOLD)
	animate(alpha = 0, time = HERETIC_RUST_CREEP_FADE, easing = SINE_EASING | EASE_IN)

/// Ржавчина: хлопья лениво осыпаются с бьющегося сердца.
/particles/heretic_ascension/rust/heart
	count = 8
	spawning = 0.15
	position = generator("box", list(-18, 0, 0), list(18, 14, 0))
	velocity = generator("box", list(-0.3, -0.2, 0), list(0.3, 0.3, 0))
	gravity = list(0, -0.08)
	friction = 0.02
	lifespan = 2.2 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.3 SECONDS

/// Ржавчина: горсть хлопьев от удара по сердцу или рухнувшей стены.
/particles/heretic_ascension/rust/heart_wound
	count = 10
	spawning = 10
	velocity = generator("circle", 1.5, 3.5)
	gravity = list(0, -0.25)
	lifespan = 0.9 SECONDS
	fade = 0.4 SECONDS

/// Ржавчина: обвал хлопьев на месте разбитого сердца.
/particles/heretic_ascension/rust/collapse
	count = HERETIC_VFX_MAX_PARTICLES
	spawning = HERETIC_VFX_MAX_SPAWNING
	position = generator("box", list(-16, -4, 0), list(16, 12, 0))
	velocity = generator("circle", 2, 5)
	gravity = list(0, -0.25)
	lifespan = 1.6 SECONDS
	fade = 0.6 SECONDS

#undef HERETIC_RUST_INK
#undef HERETIC_RUST_DARK_SHARE
#undef HERETIC_RUST_DARK_INK
#undef HERETIC_RUST_HEART_SCALE
#undef HERETIC_RUST_HEART_SWELL
#undef HERETIC_RUST_HEART_ECHO
#undef HERETIC_RUST_HEART_FLUSH_SHARE
#undef HERETIC_RUST_HEART_GLOW
#undef HERETIC_RUST_HEART_VEINS
#undef HERETIC_RUST_HEART_RISE
#undef HERETIC_RUST_HEART_EMERGE
#undef HERETIC_RUST_HEART_BEAT
#undef HERETIC_RUST_HEART_REST
#undef HERETIC_RUST_HEART_SHUDDER
#undef HERETIC_RUST_HEART_SHUDDER_STEP
#undef HERETIC_RUST_HEART_WOUND_COOLDOWN
#undef HERETIC_RUST_HEART_WOUND_PULSE
#undef HERETIC_RUST_HEART_COLLAPSE
#undef HERETIC_RUST_HEART_DEATH_WAVE
#undef HERETIC_RUST_HEART_DEATH_FLASH
#undef HERETIC_RUST_HEART_DEATH_RADIUS
#undef HERETIC_RUST_HEART_DEATH_POWER
#undef HERETIC_RUST_COLLAPSE_SPREAD
#undef HERETIC_RUST_COLLAPSE_SQUASH
#undef HERETIC_RUST_COLLAPSE_SINK
#undef HERETIC_RUST_RIPPLE_STEP
#undef HERETIC_RUST_RIPPLE_DISSOLVE
#undef HERETIC_RUST_RIPPLE_REVEAL
#undef HERETIC_RUST_CREEP_HOLD
#undef HERETIC_RUST_CREEP_FADE
#undef HERETIC_RUST_WAVE_TIME
#undef HERETIC_RUST_WAVE_FLASH_RANGE
#undef HERETIC_RUST_WAVE_FLASH_POWER
#undef HERETIC_RUST_WAVE_QUAKE
#undef HERETIC_RUST_WAVE_QUAKE_TIME
#undef HERETIC_RUST_HEART_RISE_VOLUME
#undef HERETIC_RUST_HEART_HIT_VOLUME
#undef HERETIC_RUST_HEART_BREAK_VOLUME
#undef HERETIC_RUST_HEART_BREAK_SOUND_RANGE
#undef HERETIC_RUST_WAVE_VOLUME
#undef HERETIC_RUST_WAVE_SOUND_RANGE
#undef HERETIC_RUST_WAVE_COLLAPSE_VOLUME
#undef HERETIC_RUST_ROOTS_RELEASE_VOLUME
#undef HERETIC_RUST_FX_ICON
#undef HERETIC_RUST_ROOTS_GROW
#undef HERETIC_RUST_ROOTS_VOLUME
#undef HERETIC_RUST_PRY_VOLUME
#undef HERETIC_RUST_FORMATION_VOLUME
#undef HERETIC_RUST_FORMATION_FALL
#undef HERETIC_RUST_HINT_COLOR
#undef HERETIC_RUST_HINT_ALPHA
#undef HERETIC_RUST_CHAIN_VOLUME
#undef HERETIC_RUST_CHAIN_STEP
#undef HERETIC_RUST_CHAIN_BEAM_TAIL
