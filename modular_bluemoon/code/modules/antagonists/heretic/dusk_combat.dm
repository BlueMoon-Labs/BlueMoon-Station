#define HERETIC_DUSK_COMBAT_ICON 'modular_bluemoon/icons/obj/heretic_dusk_combat.dmi'
#define HERETIC_DUSK_COMBAT_LARGE_ICON 'modular_bluemoon/icons/obj/heretic_dusk_combat_large.dmi'
#define HERETIC_DUSK_LIT_COLOR "#f2dc9a"

/datum/eldritch_knowledge/base_dusk
	var/halo_timer
	var/datum/weakref/combo_ref
	var/combo_hits = 0
	var/combo_last = 0
	var/datum/weakref/drag_ref
	/// Попадания по еретику за время добивания: второе срывает его.
	var/drag_hits = 0
	var/drag_broken = FALSE
	var/drag_failure
	/// Бившие еретика: weakref -> world.time, до которого смена облика в «Обезоружить» бьёт их.
	var/list/grudges = list()
	/// Брошенное Перо, не вернувшееся в руку: его зовёт кнопка «Позвать Перо».
	var/datum/weakref/stray_quill_ref
	var/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call/quill_call
	COOLDOWN_DECLARE(form_strike)
	COOLDOWN_DECLARE(light_drink)

/datum/eldritch_knowledge/base_dusk/proc/combat_body_gain(mob/living/user)
	RegisterSignals(user, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE), PROC_REF(on_body_staggered))
	RegisterSignal(user, COMSIG_HUMAN_DISARM_HIT, PROC_REF(on_body_shoved))

/datum/eldritch_knowledge/base_dusk/proc/combat_body_lose(mob/living/body)
	if(body)
		UnregisterSignal(body, list(COMSIG_LIVING_STATUS_STUN, COMSIG_LIVING_STATUS_KNOCKDOWN, COMSIG_LIVING_STATUS_PARALYZE, COMSIG_HUMAN_DISARM_HIT))
	deltimer(halo_timer)
	halo_timer = null
	combo_reset()
	drag_broken = TRUE

/// Враги Сумрака: живые, не союзники Мансуса, не под защитой от чар.
/datum/eldritch_knowledge/base_dusk/proc/foes_near(mob/living/user, radius)
	. = list()
	for(var/mob/living/victim in heretic_field_view(radius, user))
		if(get_dist(user, victim) <= radius && heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
			. += victim

/datum/eldritch_knowledge/base_dusk/proc/note_attacker(mob/living/attacker)
	if(!isliving(attacker) || QDELETED(attacker) || attacker == dusk_body)
		return
	var/datum/weakref/attacker_ref = WEAKREF(attacker)
	if(attacker_ref)
		grudges[attacker_ref] = world.time + HERETIC_DUSK_GRUDGE_TIME

/// Бил еретика последние 10 секунд или держит его.
/datum/eldritch_knowledge/base_dusk/proc/holds_grudge(mob/living/victim)
	if(dusk_body?.pulledby == victim)
		return TRUE
	if(!victim.weak_reference)
		return FALSE
	var/until = grudges[victim.weak_reference]
	return !isnull(until) && world.time <= until

/// Цели удара смены облика: во «Вреде» - все враги рядом, в «Обезоружить» - только бившие еретика, в остальных намерениях - никто.
/datum/eldritch_knowledge/base_dusk/proc/strike_foes(mob/living/user, radius)
	. = list()
	if(user.a_intent != INTENT_HARM && user.a_intent != INTENT_DISARM)
		return
	for(var/datum/weakref/attacker_ref as anything in grudges.Copy())
		if(!istype(attacker_ref) || grudges[attacker_ref] < world.time || !attacker_ref.resolve())
			grudges -= attacker_ref
	for(var/mob/living/victim as anything in foes_near(user, radius))
		if(user.a_intent == INTENT_HARM || holds_grudge(victim))
			. += victim

/// Смена облика в бою бьёт сама: из Лика в Крыло - веер перьев, из Крыла в Лик - вспышка нимба.
/datum/eldritch_knowledge/base_dusk/proc/form_strike(mob/living/user)
	if(!COOLDOWN_FINISHED(src, form_strike) || !can_use(user, TRUE) || (ascension_active && heretic_dusk_holy_ground(user)))
		return FALSE
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		return FALSE
	if(form == HERETIC_DUSK_FORM_WING)
		if(!length(feather_fan(user)))
			return FALSE
	else if(!halo_charge(user))
		return FALSE
	COOLDOWN_START(src, form_strike, HERETIC_DUSK_FORM_COOLDOWN)
	return TRUE

/// Три пера в ближайших врагов в 4 клетках; на одного врага веер расходится.
/datum/eldritch_knowledge/base_dusk/proc/feather_fan(mob/living/user)
	. = list()
	var/list/foes = list()
	for(var/mob/living/victim as anything in strike_foes(user, HERETIC_DUSK_FAN_RANGE))
		if(heretic_dusk_line_clear(get_turf(user), get_turf(victim)))
			foes += victim
	if(!length(foes))
		return
	var/list/nearest = list()
	while(length(foes) && length(nearest) < HERETIC_DUSK_FAN_FEATHERS)
		var/mob/living/closest = foes[1]
		for(var/mob/living/victim as anything in foes)
			if(get_dist(user, victim) < get_dist(user, closest))
				closest = victim
		foes -= closest
		nearest += closest
	var/list/datum/weakref/marked = list()
	for(var/mob/living/victim as anything in nearest)
		marked += WEAKREF(victim)
	var/fan_open = user.a_intent == INTENT_HARM
	for(var/feather_index in 1 to HERETIC_DUSK_FAN_FEATHERS)
		var/target_index = (feather_index - 1) % length(nearest) + 1
		var/mob/living/victim = nearest[target_index]
		var/round_shot = (feather_index - 1) / length(nearest)
		var/spread = fan_open && round_shot >= 1 ? (round_shot % 2 ? HERETIC_DUSK_FAN_SPREAD : -HERETIC_DUSK_FAN_SPREAD) : 0
		var/obj/item/projectile/heretic_dusk_feather/feather = new(get_turf(user))
		feather.firer = user
		feather.fired_from = user
		feather.dusk_ref = WEAKREF(src)
		feather.marked = marked.Copy()
		feather.preparePixelProjectile(victim, user, null, spread)
		feather.fire()
		. += feather
	heretic_dusk_sound(user, "feather_fan", 50, TRUE)
	user.visible_message(span_danger("Раскрываясь, крылья [user] стряхивают веер острых перьев!"), span_notice("Крылья раскрываются и мечут перья во врагов."))
	log_combat(user, nearest[1], "мечет веер перьев Сумрака в", addition = "целей: [length(nearest)]")
	lesson_event("feather_fan", user, length(nearest))

/datum/eldritch_knowledge/base_dusk/proc/feather_bleed(mob/living/victim)
	var/mob/living/carbon/body = victim
	var/obj/item/bodypart/part = istype(body) ? (body.get_bodypart(BODY_ZONE_CHEST) || pick(body.bodyparts)) : null
	if(part)
		part.generic_bleedstacks += HERETIC_DUSK_FAN_BLEED

/// Знак нимба над головой: через полсекунды он вспыхнет в упор.
/datum/eldritch_knowledge/base_dusk/proc/halo_charge(mob/living/user)
	if(!length(strike_foes(user, HERETIC_DUSK_HALO_RANGE + 1)))
		return FALSE
	new /obj/effect/temp_visual/heretic_dusk_combat/halo_charge(get_turf(user))
	heretic_dusk_sound(user, "halo_charge", 50, TRUE)
	user.visible_message(span_warning("Нимб над [user] стягивает свет в белую точку - сейчас вспыхнет! Отвернитесь или отойдите."), span_notice("Нимб стягивает свет: через миг он вспыхнет в упор."))
	deltimer(halo_timer)
	halo_timer = addtimer(CALLBACK(src, PROC_REF(halo_flash), WEAKREF(user)), HERETIC_DUSK_HALO_TELEGRAPH, TIMER_STOPPABLE)
	return TRUE

/// Вспышка нимба в 1 клетке: короткое оглушение и путаница; очки и сварочные маски держат свет.
/datum/eldritch_knowledge/base_dusk/proc/halo_flash(datum/weakref/user_ref)
	halo_timer = null
	var/mob/living/user = user_ref?.resolve()
	if(!user || user != dusk_body || user.stat == DEAD || form != HERETIC_DUSK_FORM_FACE)
		return 0
	. = 0
	new /obj/effect/temp_visual/heretic_dusk_combat/halo_flash(get_turf(user))
	heretic_dusk_sound(user, "halo_flash", 60, TRUE)
	for(var/mob/living/victim as anything in strike_foes(user, HERETIC_DUSK_HALO_RANGE))
		if(!victim.flash_act(1, type = /atom/movable/screen/fullscreen/tiled/flash/heretic_dusk, duration = HERETIC_DUSK_HALO_STUN * 2))
			to_chat(victim, span_warning("Нимб вспыхивает в упор, но защита глаз держит свет."))
			continue
		victim.Stun(HERETIC_DUSK_HALO_STUN)
		victim.confused = max(victim.confused, HERETIC_DUSK_HALO_CONFUSION)
		to_chat(victim, span_userdanger("Нимб вспыхивает прямо в лицо: в глазах белым-бело, ноги путаются!"))
		log_combat(user, victim, "оглушает вспышкой нимба Сумрака")
		.++
	user.visible_message(span_danger("Нимб над [user] взрывается белым светом!"), span_notice("Нимб вспыхивает. Ослеплено: [.]."))
	lesson_event("halo_flash", user, .)

/// Серия Пера: третий удар по одной цели не позже 4 секунд после прошлого - световой разрез в Лике, теневой в Крыле.
/datum/eldritch_knowledge/base_dusk/proc/combo_hit(mob/living/user, mob/living/target)
	if(combo_ref?.resolve() != target || world.time - combo_last > HERETIC_DUSK_COMBO_WINDOW)
		combo_hits = 0
	combo_ref = WEAKREF(target)
	combo_last = world.time
	combo_hits++
	if(combo_hits < HERETIC_DUSK_COMBO_HITS)
		if(combo_hits == HERETIC_DUSK_COMBO_HITS - 1)
			user.balloon_alert(user, "ещё удар - разрез")
		return FALSE
	combo_reset()
	if(form == HERETIC_DUSK_FORM_FACE)
		light_slash(user, target)
	else
		shadow_slash(user, target)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/combo_reset()
	combo_ref = null
	combo_hits = 0
	combo_last = 0

/datum/eldritch_knowledge/base_dusk/proc/on_body_staggered(mob/living/source, amount)
	SIGNAL_HANDLER
	if(amount > 0 && combo_hits)
		combo_reset()
		to_chat(source, span_warning("Вас сбили: серия Пера прервана."))

/datum/eldritch_knowledge/base_dusk/proc/on_body_shoved(mob/living/source, mob/living/attacker, zone)
	SIGNAL_HANDLER
	note_attacker(attacker)
	if(combo_hits)
		combo_reset()
		to_chat(source, span_warning("Вас толкнули: серия Пера прервана."))

/datum/eldritch_knowledge/base_dusk/proc/light_slash(mob/living/user, mob/living/target)
	target.adjustFireLoss(HERETIC_DUSK_SLASH_BURN)
	if(QDELETED(target))
		return
	var/obj/effect/temp_visual/heretic_dusk_combat/slash_light/slash = new(get_turf(target))
	slash.setDir(get_dir(user, target) || user.dir)
	heretic_dusk_sound(target, "slash_light", 50, TRUE)
	target.apply_status_effect(/datum/status_effect/heretic_dusk_lit)
	target.visible_message(span_danger("Третий удар Пера оставляет на [target] светящийся разрез: теперь [target] светится и виден в темноте!"), span_userdanger("Разрез горит светом - вы светитесь и видны в темноте!"))
	log_combat(user, target, "бьёт световым разрезом Сумрака")
	lesson_event("slash", target, HERETIC_DUSK_FORM_FACE)

/datum/eldritch_knowledge/base_dusk/proc/shadow_slash(mob/living/user, mob/living/target)
	var/obj/effect/temp_visual/heretic_dusk_combat/slash_shadow/slash = new(get_turf(target))
	slash.setDir(get_dir(user, target) || user.dir)
	heretic_dusk_sound(target, "slash_shadow", 50, TRUE)
	target.apply_status_effect(/datum/status_effect/heretic_dusk_slowed)
	target.apply_status_effect(/datum/status_effect/heretic_dusk_tether, user)
	target.visible_message(span_danger("Третий удар Пера пришивает тень [target] к тени [user]!"), span_userdanger("Ваша тень пришита к нему: отступите в тени - она дёрнет вас назад. Свет её рвёт!"))
	log_combat(user, target, "пришивает теневым разрезом Сумрака")
	lesson_event("slash", target, HERETIC_DUSK_FORM_WING)

/// Луч лазера в Лик спереди не ранит, а поит его Сумраком раз в 4 секунды.
/datum/eldritch_knowledge/base_dusk/proc/drink_light(mob/living/source, atom/object, mob/living/attacker, attack_type, list/return_list)
	if(form != HERETIC_DUSK_FORM_FACE || !(attack_type & ATTACK_TYPE_PROJECTILE) || !heretic_dusk_drinkable(object) || !COOLDOWN_FINISHED(src, light_drink))
		return FALSE
	if(!attack_from_front(object, attacker) || (ascension_active && heretic_dusk_holy_ground(source)))
		return FALSE
	COOLDOWN_START(src, light_drink, HERETIC_DUSK_DRINK_COOLDOWN)
	return_list[HERETIC_BLOCK_ABSORBED] = TRUE
	gain_combat_resource()
	new /obj/effect/temp_visual/heretic_dusk_combat/drink(get_turf(source))
	heretic_dusk_sound(source, "drink", 50, TRUE)
	source.visible_message(span_warning("Луч входит в нимб [source] и гаснет: Лик пьёт свет!"), span_notice("Лик пьёт луч: +1 Сумрак. Следующий через [HERETIC_DUSK_DRINK_COOLDOWN / (1 SECONDS)] секунды."), vision_distance = COMBAT_MESSAGE_RANGE)
	lesson_event("drink", attacker)
	return TRUE

/// Лазер или энергетический луч с ожогом; станнеры и пули Лик не пьёт.
/proc/heretic_dusk_drinkable(atom/object)
	var/obj/item/projectile/shot = object
	if(!istype(shot) || shot.damage_type != BURN || shot.damage <= 0)
		return FALSE
	return shot.flag == LASER || shot.flag == ENERGY

/datum/eldritch_knowledge/base_dusk/proc/drag_block_reason(mob/living/user, mob/living/victim)
	var/reason = cast_block_reason(user, HERETIC_DUSK_FORM_WING)
	if(reason)
		return reason
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		return "Вы не хотите никого ранить."
	if(drag_ref?.resolve())
		return "Вы уже тянете тень."
	if(!door_holds(user, victim))
		return "Утянуть в тень можно только цель, прибитую вашей Хваткой тени, стоя вплотную."
	if(!heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return "Эту цель тень не берёт."
	return null

/// Добивание из тени: 2 секунды тень тянет прибитую цель вниз; свет в лицо, удар по еретику или «растолкать» срывают.
/datum/eldritch_knowledge/base_dusk/proc/shadow_drag(mob/living/user, mob/living/victim)
	dusk_failure = drag_block_reason(user, victim)
	if(dusk_failure)
		to_chat(user, span_warning(dusk_failure))
		return FALSE
	drag_ref = WEAKREF(victim)
	drag_broken = FALSE
	drag_failure = null
	drag_hits = 0
	new /obj/effect/temp_visual/heretic_dusk_combat/drag(get_turf(victim))
	heretic_dusk_sound(victim, "drag", 60, TRUE)
	victim.visible_message(span_danger("Тень под [victim] раскрывается чёрной пастью и тянет [victim] вниз! Посветите [user] в лицо, ударьте его дважды или сильно, растолкайте [victim]!"), span_userdanger("Тень тянет вас вниз! Пусть кто-нибудь посветит ему в лицо, ударит его дважды или сильно или растолкает вас!"))
	var/done = do_after(user, HERETIC_DUSK_DRAG_TIME, victim, extra_checks = CALLBACK(src, PROC_REF(drag_holds), user, victim))
	drag_ref = null
	if(!done || QDELETED(src))
		if(!QDELETED(victim))
			victim.visible_message(span_notice("Тень под [victim] захлопывается впустую."))
		if(!QDELETED(user))
			to_chat(user, span_warning("Тень выскользнула: [drag_failure || "вас сдвинули или прервали."] Добивание сорвано."))
		return FALSE
	return drag_finish(user, victim)

/// Держится ли добивание; иначе причина срыва остаётся в drag_failure.
/datum/eldritch_knowledge/base_dusk/proc/drag_holds(mob/living/user, mob/living/victim)
	if(drag_broken)
		return FALSE
	if(form != HERETIC_DUSK_FORM_WING)
		drag_failure = "вы сменили облик."
	else if(!door_holds(user, victim))
		drag_failure = "Хватка на цели сорвалась или вы отошли от неё."
	else
		return TRUE
	return FALSE

/// Попадание по еретику во время добивания: второе или одно от HERETIC_DUSK_DRAG_BREAK_DAMAGE урона срывает его; союзники Мансуса не в счёт.
/datum/eldritch_knowledge/base_dusk/proc/drag_hit(mob/living/attacker, damage, attack_type)
	if(drag_broken || !drag_ref?.resolve() || (isliving(attacker) && (IS_HERETIC(attacker) || IS_HERETIC_MONSTER(attacker))))
		return FALSE
	var/punch = (attack_type & ATTACK_TYPE_UNARMED) && isliving(attacker) && attacker.a_intent == INTENT_HARM
	if(damage <= 0 && !punch)
		return FALSE
	drag_hits++
	var/reason
	if(damage >= HERETIC_DUSK_DRAG_BREAK_DAMAGE)
		reason = "вас ранили на [HERETIC_DUSK_DRAG_BREAK_DAMAGE] и больше."
	else if(drag_hits >= HERETIC_DUSK_DRAG_BREAK_HITS)
		reason = "вас ударили второй раз."
	else
		return FALSE
	break_drag(reason)
	if(isliving(attacker))
		log_combat(attacker, dusk_body, "срывает добивание Сумрака у", addition = reason)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/drag_finish(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim) || !heretic_can_affect(user, victim, chargecost = 0, notify = FALSE))
		return FALSE
	victim.apply_damage(HERETIC_DUSK_DRAG_DAMAGE, BRUTE, BODY_ZONE_CHEST)
	var/healed = heretic_heal_pool(user, HERETIC_DUSK_DRAG_HEAL)
	heretic_dusk_sound(victim, "drag_done", 60, TRUE)
	new /obj/effect/temp_visual/heretic_dusk/grasp(get_turf(victim))
	var/datum/status_effect/heretic_dusk_grip/grip = victim.has_status_effect(/datum/status_effect/heretic_dusk_grip)
	grip?.release()
	victim.visible_message(span_danger("Тень смыкается над [victim] и рвёт его, а [user] будто пьёт её!"), span_userdanger("Тень рвёт вас изнутри!"))
	to_chat(user, span_notice("Вы утягиваете тень [victim]: +[round(healed)] здоровья."))
	log_combat(user, victim, "утягивает в тень Сумрака", addition = "вылечено: [round(healed)]")
	lesson_event("drag", victim)
	return TRUE

/datum/eldritch_knowledge/base_dusk/proc/break_drag(reason = "вам посветили фонарём в лицо.")
	if(drag_ref?.resolve())
		drag_broken = TRUE
		drag_failure = reason

/// Веер перьев смены облика: порез с кровью и короткое замедление.
/obj/item/projectile/heretic_dusk_feather
	name = "fallen feather"
	icon = HERETIC_DUSK_COMBAT_ICON
	icon_state = "dusk_feather"
	damage = HERETIC_DUSK_FAN_DAMAGE
	damage_type = BRUTE
	flag = MELEE
	range = HERETIC_DUSK_FAN_RANGE + 2
	hitsound = HERETIC_DUSK_HIT_SFX
	var/datum/weakref/dusk_ref
	/// Цели веера: остальных живых перо пролетает насквозь.
	var/list/datum/weakref/marked

/obj/item/projectile/heretic_dusk_feather/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(isliving(target) && marked && !(target.weak_reference in marked))
		return FALSE
	return ..()

/obj/item/projectile/heretic_dusk_feather/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	var/mob/living/victim = target
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!isliving(victim) || blocked >= 100 || !dusk || !heretic_can_affect(firer, victim, chargecost = 0, notify = FALSE))
		return
	victim.apply_status_effect(/datum/status_effect/heretic_dusk_slowed)
	dusk.feather_bleed(victim)

/obj/item/projectile/heretic_dusk_feather/Destroy()
	dusk_ref = null
	marked = null
	return ..()

/// Световой разрез: цель светится и видна в темноте.
/datum/status_effect/heretic_dusk_lit
	id = "heretic_dusk_lit"
	on_remove_on_mob_delete = TRUE
	duration = HERETIC_DUSK_LIT_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_lit
	examine_text = span_warning("SUBJECTPRONOUN светится сквозь световой разрез: его видно и в темноте.")
	var/obj/effect/dummy/lighting_obj/moblight/glow
	var/mutable_appearance/sparks
	var/mutable_appearance/sparks_glow

/datum/status_effect/heretic_dusk_lit/on_apply()
	. = ..()
	glow = owner.mob_light(HERETIC_DUSK_LIT_COLOR, 2, 1)
	sparks = mutable_appearance(HERETIC_DUSK_COMBAT_ICON, "dusk_lit", ABOVE_MOB_LAYER)
	sparks.appearance_flags = RESET_COLOR | KEEP_APART
	sparks_glow = emissive_appearance(HERETIC_DUSK_COMBAT_ICON, "dusk_lit", ABOVE_MOB_LAYER, offset_spokesman = owner)
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	owner.update_icon()

/datum/status_effect/heretic_dusk_lit/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += sparks
	overlays += sparks_glow

/datum/status_effect/heretic_dusk_lit/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	QDEL_NULL(glow)
	sparks = null
	sparks_glow = null
	owner.update_icon()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dusk_lit
	name = "Световой разрез"
	desc = "Разрез Лика светится: вас видно в темноте 5 секунд."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_lit_cut"

/// Теневой разрез: тень цели пришита к Крылу; отступившего в тени дёргает назад, свет рвёт нить.
/datum/status_effect/heretic_dusk_tether
	id = "heretic_dusk_tether"
	on_remove_on_mob_delete = TRUE
	duration = HERETIC_DUSK_TETHER_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_tether
	examine_text = span_warning("Тень SUBJECTPRONOUN пришита к чужой тени чёрной нитью: шаг прочь в тени дёрнет назад, свет её порвёт.")
	var/mob/living/holder
	var/mutable_appearance/thread

/datum/status_effect/heretic_dusk_tether/on_creation(mob/living/new_owner, mob/living/new_holder)
	holder = new_holder
	return ..()

/datum/status_effect/heretic_dusk_tether/on_apply()
	. = ..()
	if(!. || QDELETED(holder))
		return FALSE
	thread = mutable_appearance(HERETIC_DUSK_COMBAT_ICON, "dusk_tether", BELOW_MOB_LAYER)
	thread.appearance_flags = RESET_COLOR | KEEP_APART
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))
	owner.update_icon()
	return TRUE

/datum/status_effect/heretic_dusk_tether/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(thread)
		overlays += thread

/datum/status_effect/heretic_dusk_tether/proc/on_holder_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_dusk_tether/proc/on_moved(atom/movable/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/turf/here = get_turf(owner)
	var/turf/anchor = get_turf(holder)
	if(!here || !anchor || here.z != anchor.z || get_dist(here, anchor) <= 1 || holder.stat == DEAD)
		return
	if(heretic_dusk_lit(here))
		owner.visible_message(span_notice("Свет рвёт чёрную нить между тенью [owner] и [holder]."), span_notice("Свет рвёт нить: тень снова ваша."))
		heretic_dusk_sound(owner, "grip_break", 40, TRUE)
		qdel(src)
		return
	INVOKE_ASYNC(src, PROC_REF(yank), here, anchor)

/datum/status_effect/heretic_dusk_tether/proc/yank(turf/here, turf/anchor)
	if(QDELETED(src))
		return
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	var/turf/back = get_step(here, get_dir(here, anchor))
	if(back && !back.is_blocked_turf(exclude_mobs = FALSE))
		owner.forceMove(back)
		new /obj/effect/temp_visual/heretic_dusk/step_in(back)
	heretic_dusk_sound(owner, "tether", 50, TRUE)
	owner.visible_message(span_danger("Чёрная нить дёргает [owner] назад к [holder]!"), span_userdanger("Тень дёргает вас назад!"))
	log_combat(holder, owner, "дёргает теневой нитью Сумрака")
	qdel(src)

/datum/status_effect/heretic_dusk_tether/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOVABLE_MOVED, COMSIG_ATOM_UPDATE_OVERLAYS))
	if(holder)
		UnregisterSignal(holder, COMSIG_PARENT_QDELETING)
	holder = null
	thread = null
	owner.update_icon()
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dusk_tether
	name = "Пришитая тень"
	desc = "Ваша тень пришита к Крылу на 3 секунды: шаг прочь в тени дёрнет вас назад. Встаньте на свет - нить порвётся."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_pinned"

/// Хозяин брошенного Пера: еретик Сумрака в своём теле.
/proc/heretic_dusk_quill_owner(mob/living/thrower)
	if(!isliving(thrower))
		return null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(thrower)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	return dusk?.can_use(thrower, TRUE) ? dusk : null

/// Святое в руке: нулевой жезл или Библия, кроме осквернённой часовни.
/proc/heretic_dusk_holds_holy(mob/living/bearer)
	if(!isliving(bearer) || (GLOB.heretic_dusk_chapel_desecrated && istype(get_area(bearer), /area/service/chapel)))
		return FALSE
	for(var/obj/item/item in bearer.held_items)
		if(istype(item, /obj/item/nullrod) || istype(item, /obj/item/storage/book/bible))
			return TRUE
	return FALSE

/obj/item/melee/sickly_blade/dusk
	var/return_timer
	/// Кто бросил Перо: только он, подняв его, отменяет возврат.
	var/datum/weakref/thrower_ref
	var/holy_dropped_until = 0
	/// Знание хозяина, у которого это Перо числится застрявшим.
	var/datum/weakref/stray_of

/obj/item/melee/sickly_blade/dusk/Destroy()
	deltimer(return_timer)
	return_timer = null
	var/datum/eldritch_knowledge/base_dusk/dusk = stray_of?.resolve()
	if(dusk?.stray_quill_ref && dusk.stray_quill_ref == weak_reference)
		dusk.forget_stray_quill()
	stray_of = null
	return ..()

/obj/item/melee/sickly_blade/dusk/pickup(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(!dusk || dusk.dusk_body != user)
		return
	if(!thrower_ref || thrower_ref.resolve() == user)
		deltimer(return_timer)
		return_timer = null
	if(dusk.stray_quill_ref?.resolve() == src)
		dusk.forget_stray_quill()

/obj/item/melee/sickly_blade/dusk/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		. += span_notice("Каждый [HERETIC_DUSK_COMBO_HITS]-й удар по одной цели не позже [HERETIC_DUSK_COMBO_WINDOW / (1 SECONDS)] секунд после прошлого - разрез: в Лике светом (+[HERETIC_DUSK_SLASH_BURN] ожогов, цель светится [HERETIC_DUSK_LIT_TIME / (1 SECONDS)] секунд), в Крыле тень цели пришита на [HERETIC_DUSK_TETHER_TIME / (1 SECONDS)] секунды. Оглушение или толчок сбивают серию. Брошенное Перо через [replacetext("[HERETIC_DUSK_QUILL_RETURN_DELAY / (1 SECONDS)]", ".", ",")] секунды летит назад в руку и режет врагов на пути, а не долетевшее зовёт кнопка «Позвать Перо»; нулевой жезл или Библия в руке задетого роняют его на [HERETIC_DUSK_QUILL_HOLY_DROP / (1 SECONDS)] секунд. В облике Крыла Перо в намерении «Схватить» по цели под вашей Хваткой тени за [HERETIC_DUSK_DRAG_TIME / (1 SECONDS)] секунды утягивает её в тень.")
	else
		. += span_warning("Перо будто тянется к руке хозяина: брошенное, оно вернётся к нему, а нулевой жезл или Библия в руке его сбивают.")

/// Перо в намерении «Схватить» по цели под своей Хваткой тени утягивает её в тень.
/obj/item/melee/sickly_blade/dusk/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(user.a_intent == INTENT_GRAB && isliving(target))
		var/datum/eldritch_knowledge/base_dusk/dusk = heretic_dusk_quill_owner(user)
		if(dusk?.door_holds(user, target))
			INVOKE_ASYNC(dusk, TYPE_PROC_REF(/datum/eldritch_knowledge/base_dusk, shadow_drag), user, target)
			return
	return ..()

/obj/item/melee/sickly_blade/dusk/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/thrower = throwingdatum?.thrower
	. = ..()
	if(QDELETED(src) || !heretic_dusk_quill_owner(thrower))
		return
	if(isliving(hit_atom) && heretic_dusk_holds_holy(hit_atom))
		holy_drop(hit_atom, thrower)
		return
	schedule_return(thrower, HERETIC_DUSK_QUILL_RETURN_DELAY)

/obj/item/melee/sickly_blade/dusk/proc/schedule_return(mob/living/thrower, delay)
	deltimer(return_timer)
	thrower_ref = WEAKREF(thrower)
	return_timer = addtimer(CALLBACK(src, PROC_REF(fly_back), thrower_ref), delay, TIMER_STOPPABLE)

/// Святое сбивает Перо на пол на 5 секунд, потом оно снова рвётся к хозяину.
/obj/item/melee/sickly_blade/dusk/proc/holy_drop(mob/living/bearer, mob/living/thrower)
	holy_dropped_until = world.time + HERETIC_DUSK_QUILL_HOLY_DROP
	new /obj/effect/temp_visual/heretic_dusk/holy_burn(get_turf(src))
	heretic_dusk_sound(src, "holy", 40, TRUE)
	visible_message(span_warning("Перо падшего ударяется о святое в руках [bearer], шипит и падает, погаснув."))
	schedule_return(thrower, HERETIC_DUSK_QUILL_HOLY_DROP)

/obj/item/melee/sickly_blade/dusk/proc/return_block_reason(mob/living/thrower)
	var/turf/start = get_turf(src)
	var/turf/finish = get_turf(thrower)
	if(!isturf(loc))
		return "Перо в чужих руках или заперто."
	if(world.time < holy_dropped_until)
		return "Святое ещё держит Перо на полу: [heretic_capture_seconds_left(holy_dropped_until)] с."
	if(!start || !finish || start.z != finish.z || get_dist(start, finish) > HERETIC_DUSK_QUILL_RETURN_RANGE)
		return "Перо лежит дальше [HERETIC_DUSK_QUILL_RETURN_RANGE] клеток от вас."
	if(!heretic_dusk_line_clear(start, finish))
		return "Между вами и Пером стена, окно или дверь."
	return null

/// Где Перо относительно хозяина: сторона света и отсек или другой этаж; кто его держит, не называется.
/obj/item/melee/sickly_blade/dusk/proc/whereabouts(mob/living/thrower)
	var/turf/spot = get_turf(src)
	var/turf/from = get_turf(thrower)
	if(!spot || !from || spot.z != from.z)
		return "Перо на другом этаже."
	var/side = get_dist(from, spot) <= 1 ? "совсем рядом" : GLOB.heretic_mansus_directions["[get_dir(from, spot)]"]
	return "Перо [side || "совсем рядом"] - [get_area_name(spot, TRUE)]."

/// Почему хозяин не может поймать Перо: в укрытии оно до него не долетит, оглушённый его не удержит.
/proc/heretic_dusk_catch_block_reason(mob/living/thrower)
	if(!isturf(thrower.loc))
		return "Вы в шкафу, мехе или другом укрытии: Перо до вас не долетит."
	return "Вы оглушены или скованы и не поймаете Перо."

/// Перо летит назад в руку хозяина и режет врагов на пути; заняты руки - падает к ногам; не долетело - хозяин узнаёт причину и получает «Позвать Перо».
/obj/item/melee/sickly_blade/dusk/proc/fly_back(datum/weakref/thrower_ref, called = FALSE)
	deltimer(return_timer)
	return_timer = null
	var/mob/living/thrower = thrower_ref?.resolve()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(thrower)
	var/datum/eldritch_knowledge/base_dusk/dusk = heretic?.get_knowledge(/datum/eldritch_knowledge/base_dusk)
	if(!dusk || dusk.dusk_body != thrower)
		return FALSE
	if(get(loc, /mob/living) == thrower)
		if(dusk.stray_quill_ref?.resolve() == src)
			dusk.forget_stray_quill()
		if(called)
			dusk.dusk_failure = "Перо уже у вас."
		return FALSE
	var/reason = dusk.can_use(thrower, TRUE) ? return_block_reason(thrower) : heretic_dusk_catch_block_reason(thrower)
	if(reason)
		reason = "[reason] [whereabouts(thrower)]"
		if(called)
			dusk.dusk_failure = reason
		else
			dusk.stray_quill(thrower, src, reason)
		return FALSE
	var/turf/start = get_turf(src)
	var/turf/finish = get_turf(thrower)
	var/turf/stop = finish
	var/cut = 0
	for(var/turf/spot as anything in get_line(start, finish))
		var/blocked = FALSE
		for(var/mob/living/victim in spot)
			if(victim == thrower || victim.stat == DEAD)
				continue
			if(heretic_dusk_holds_holy(victim))
				stop = spot
				blocked = victim
				break
			if(!heretic_can_affect(thrower, victim, chargecost = 0, notify = FALSE))
				continue
			victim.apply_damage(HERETIC_DUSK_QUILL_PASS_DAMAGE, BRUTE, BODY_ZONE_CHEST)
			to_chat(victim, span_userdanger("Возвращаясь к хозяину, Перо падшего режет вас на лету!"))
			log_combat(thrower, victim, "режет возвращающимся Пером Сумрака")
			cut++
		if(blocked)
			break
	new /obj/effect/temp_visual/heretic_dusk_quill_flight(start, stop)
	heretic_dusk_sound(start, "quill_return", 45, TRUE)
	forceMove(stop)
	if(stop != finish)
		holy_drop(locate(/mob/living) in stop, thrower)
		dusk.dusk_failure = "Перо ударилось о святое в чужих руках и упало."
		return FALSE
	if(dusk.stray_quill_ref?.resolve() == src)
		dusk.forget_stray_quill()
	if(thrower.put_in_hands(src))
		to_chat(thrower, span_notice("Перо падшего возвращается в руку[cut ? ", по пути порезав врагов: [cut]" : ""]."))
	else
		to_chat(thrower, span_warning("Руки заняты: Перо падшего падает к вашим ногам[cut ? ", по пути порезав врагов: [cut]" : ""]."))
	dusk.lesson_event("quill_return", thrower, cut)
	return TRUE

/// Перо не вернулось: хозяин узнаёт причину, а кнопка «Позвать Перо» зовёт его снова.
/datum/eldritch_knowledge/base_dusk/proc/stray_quill(mob/living/user, obj/item/melee/sickly_blade/dusk/quill, reason)
	stray_quill_ref = WEAKREF(quill)
	quill.stray_of = WEAKREF(src)
	to_chat(user, span_warning("Перо падшего не вернулось: [reason] Подойдите ближе и нажмите «Позвать Перо»."))
	if(QDELETED(quill_call) && user.mind)
		quill_call = new
		user.mind.AddSpell(quill_call)

/datum/eldritch_knowledge/base_dusk/proc/forget_stray_quill()
	var/obj/item/melee/sickly_blade/dusk/quill = stray_quill_ref?.resolve()
	if(quill)
		quill.stray_of = null
	stray_quill_ref = null
	QDEL_NULL(quill_call)

/datum/eldritch_knowledge/base_dusk/proc/call_quill(mob/living/user)
	dusk_failure = null
	var/obj/item/melee/sickly_blade/dusk/quill = stray_quill_ref?.resolve()
	if(!quill)
		forget_stray_quill()
		dusk_failure = "Пера больше нет."
		return FALSE
	return quill.fly_back(WEAKREF(user), TRUE)

/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call
	name = "Позвать Перо"
	desc = "Брошенное Перо падшего не долетело до руки. Встаньте не дальше 10 клеток от него, чтобы между вами не было стен, окон и дверей, и позовите: оно рванётся в руку и порежет врагов на пути. Святое в руках задетого сбивает его на 5 секунд. Кнопка уходит, когда Перо снова у вас."
	charge_max = HERETIC_DUSK_QUILL_CALL_COOLDOWN
	usable_while_grabbed = TRUE
	action_icon = HERETIC_DUSK_ICON
	action_icon_state = "dusk_blade"

/obj/effect/proc_holder/spell/self/heretic_dusk/quill_call/cast(list/targets, mob/living/user)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_of(user)
	if(!dusk?.call_quill(user))
		heretic_revert_cast(user, dusk?.dusk_failure)

/obj/effect/temp_visual/heretic_dusk_combat
	icon = HERETIC_DUSK_COMBAT_ICON
	icon_state = "dusk_slash_light"
	duration = 0.5 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_dusk_combat/slash_light
	icon_state = "dusk_slash_light"

/obj/effect/temp_visual/heretic_dusk_combat/slash_shadow
	icon_state = "dusk_slash_shadow"

/obj/effect/temp_visual/heretic_dusk_combat/halo_charge
	icon_state = "dusk_halo_charge"
	duration = HERETIC_DUSK_HALO_TELEGRAPH

/obj/effect/temp_visual/heretic_dusk_combat/halo_flash
	icon = HERETIC_DUSK_COMBAT_LARGE_ICON
	icon_state = "dusk_halo_flash"
	duration = 0.6 SECONDS
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/heretic_dusk_combat/drink
	icon_state = "dusk_drink"
	duration = 0.7 SECONDS

/obj/effect/temp_visual/heretic_dusk_combat/drag
	icon_state = "dusk_drag"
	duration = HERETIC_DUSK_DRAG_TIME
	layer = BELOW_MOB_LAYER

/// Перо летит от точки падения к хозяину, вращаясь.
/obj/effect/temp_visual/heretic_dusk_quill_flight
	icon = HERETIC_DUSK_ICON
	icon_state = "dusk_blade"
	duration = 0.4 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_dusk_quill_flight/Initialize(mapload, turf/finish)
	var/turf/start = get_turf(src)
	if(start && finish)
		duration = clamp(get_dist(start, finish) * 0.5, 1, 6)
	. = ..()
	if(!start || !finish)
		return
	animate(src, pixel_x = (finish.x - start.x) * world.icon_size, pixel_y = (finish.y - start.y) * world.icon_size, transform = matrix(720, MATRIX_ROTATE), time = duration)

#undef HERETIC_DUSK_COMBAT_ICON
#undef HERETIC_DUSK_COMBAT_LARGE_ICON
#undef HERETIC_DUSK_LIT_COLOR
