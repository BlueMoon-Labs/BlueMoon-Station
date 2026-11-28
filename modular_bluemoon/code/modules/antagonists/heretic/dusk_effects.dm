#define HERETIC_DUSK_BURNT_TINT "#e0b25a"
#define HERETIC_DUSK_SHADOW_OFFSET 10
#define HERETIC_DUSK_GRIP_LIGHT_GAP (2 SECONDS)
#define HERETIC_DUSK_GRIP_CHECK (0.5 SECONDS)
#define HERETIC_DUSK_BEACON_TIME (2 SECONDS)
#define HERETIC_DUSK_ECLIPSED_TIME (3 SECONDS)
#define HERETIC_DUSK_CRACKS_TIME (2 SECONDS)
#define HERETIC_DUSK_PART_LAYER_STEP 0.001
#define HERETIC_DUSK_JERK_TIME (0.05 SECONDS)
#define HERETIC_DUSK_JERK_HOLD (0.1 SECONDS)
#define HERETIC_DUSK_DRIP_TIME (2.2 SECONDS)
#define HERETIC_DUSK_DRIP_FALL 22
#define HERETIC_DUSK_ECLIPSE_MOON_START -18
#define HERETIC_DUSK_ECLIPSE_FLASH (1 SECONDS)
#define HERETIC_DUSK_SHADOW_DIM 1
#define HERETIC_DUSK_WING_ALPHA 200
#define HERETIC_DUSK_HANDS_BREATH (1.6 SECONDS)
#define HERETIC_DUSK_HANDS_IN 2
#define HERETIC_DUSK_HANDS_OUT 1
#define HERETIC_DUSK_HANDS_ENTER 8
#define HERETIC_DUSK_HANDS_RETURN 5
#define HERETIC_DUSK_HANDS_GONE 10
#define HERETIC_DUSK_WORLD_FADE (1 SECONDS)
#define HERETIC_DUSK_SOFT_CRACKS 120
#define HERETIC_DUSK_MARK_DIM_ALPHA 150
#define HERETIC_DUSK_MARK_STREAK_ALPHA 120
#define HERETIC_DUSK_MARK_SHADOW "#0a0612"
#define HERETIC_DUSK_HUD_FACE "#ffefc4"
#define HERETIC_DUSK_HUD_WING "#b6a8f0"
#define HERETIC_DUSK_HUD_STRIKE "#6b1732"
#define HERETIC_DUSK_HUD_HOLY "#8fdcff"

/// Гасит целую горящую лампу на время; выключатель или починка зажигают её раньше.
/proc/heretic_dusk_dim_lamp(obj/machinery/light/lamp, time)
	if(QDELETED(lamp) || lamp.status != LIGHT_OK || !lamp.on)
		return FALSE
	lamp.on = FALSE
	lamp.update(FALSE, TRUE)
	if(time)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_dusk_restore_lamp), WEAKREF(lamp)), time)
	return TRUE

/proc/heretic_dusk_restore_lamp(datum/weakref/lamp_ref)
	var/obj/machinery/light/lamp = lamp_ref?.resolve()
	if(QDELETED(lamp) || lamp.status != LIGHT_OK || lamp.on)
		return FALSE
	lamp.on = lamp.has_power()
	lamp.update(FALSE, TRUE)
	return lamp.on

/// Ближайшие целые горящие лампы в радиусе, не больше cap.
/proc/heretic_dusk_nearest_lamps(atom/center, radius, cap)
	. = list()
	var/turf/origin = get_turf(center)
	if(!origin)
		return
	var/list/candidates = list()
	for(var/obj/machinery/light/lamp in range(radius, origin))
		if(lamp.status == LIGHT_OK && lamp.on)
			candidates[lamp] = get_dist(lamp, origin)
	sortTim(candidates, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	for(var/obj/machinery/light/lamp as anything in candidates)
		if(length(.) >= cap)
			break
		. += lamp

/// Один кадр сбоя экрана и трещины света по краю, гаснущие за пару секунд; мягкий - только бледные трещины.
/proc/heretic_dusk_screen_glitch(mob/living/viewer, soft = FALSE)
	if(!viewer?.client)
		return
	if(!soft)
		viewer.overlay_fullscreen("heretic_dusk_glitch", /atom/movable/screen/fullscreen/scaled/heretic_dusk/glitch)
		viewer.clear_fullscreen("heretic_dusk_glitch", 0.2 SECONDS)
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks/cracks = viewer.overlay_fullscreen("heretic_dusk_cracks", /atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks)
	viewer.clear_fullscreen("heretic_dusk_cracks", HERETIC_DUSK_CRACKS_TIME)
	cracks.burn_out(HERETIC_DUSK_CRACKS_TIME, soft ? HERETIC_DUSK_SOFT_CRACKS : 255)

/// Цвет мира облика ставится сразу, а глаз видит переход: клиент доигрывает его от прежнего цвета.
/proc/heretic_dusk_fade_world(client/viewer, previous_colour)
	if(!viewer)
		return
	var/static/list/plain = list(1,0,0, 0,1,0, 0,0,1, 0,0,0)
	var/target = viewer.color || plain
	viewer.color = previous_colour || plain
	animate(viewer, color = target, time = HERETIC_DUSK_WORLD_FADE, easing = SINE_EASING)

/// Заговор лампы: она мигает на прохожих, принимает Шаг в тень и бьёт лучом.
/datum/component/heretic_dusk_lamp
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/dusk_ref
	var/mutable_appearance/hex_overlay
	var/static/list/sense_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	/// Гнилая лампа Скверны: ступень порчи света, 0 - лампа не гниёт.
	var/rot_stage = 0
	var/clean_power
	var/rot_timer
	COOLDOWN_DECLARE(flicker_cooldown)

/datum/component/heretic_dusk_lamp/Initialize(datum/eldritch_knowledge/base_dusk/dusk)
	if(!istype(parent, /obj/machinery/light) || QDELETED(dusk))
		return COMPONENT_INCOMPATIBLE
	dusk_ref = WEAKREF(dusk)
	dusk.lamps += src
	hex_overlay = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_lamp_hex")
	hex_overlay.appearance_flags = RESET_COLOR | KEEP_APART
	AddComponent(/datum/component/connect_range, parent, sense_connections, HERETIC_DUSK_LAMP_SENSE, FALSE)

/datum/component/heretic_dusk_lamp/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	var/atom/lamp = parent
	lamp.update_icon()

/datum/component/heretic_dusk_lamp/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_UPDATE_OVERLAYS, COMSIG_PARENT_EXAMINE, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_EXPOSE_REAGENTS))
	var/atom/lamp = parent
	if(!QDELETED(lamp))
		lamp.update_icon()

/datum/component/heretic_dusk_lamp/Destroy()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	dusk?.on_lamp_removed(src)
	set_rot(FALSE)
	qdel(GetComponent(/datum/component/connect_range))
	dusk_ref = null
	hex_overlay = null
	return ..()

/datum/component/heretic_dusk_lamp/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	overlays += hex_overlay
	var/obj/machinery/light/lamp = parent
	if(rot_stage && lamp.status != LIGHT_OK)
		addtimer(CALLBACK(src, PROC_REF(rot_replaced)), 1, TIMER_UNIQUE)

/// Скверна гноит лампу: свет тускнеет ступенями, пока экипаж не сменит трубку.
/datum/component/heretic_dusk_lamp/proc/set_rot(enabled)
	var/obj/machinery/light/lamp = parent
	if(!enabled)
		if(!rot_stage)
			return
		deltimer(rot_timer)
		rot_timer = null
		rot_stage = 0
		lamp.bulb_power = clean_power
		if(!QDELETED(lamp))
			lamp.update(FALSE, TRUE)
		hex_overlay = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_lamp_hex")
		hex_overlay.appearance_flags = RESET_COLOR | KEEP_APART
		if(!QDELETED(lamp))
			lamp.update_icon()
		return
	if(rot_stage)
		return
	clean_power = lamp.bulb_power
	hex_overlay = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_rot_lamp")
	hex_overlay.appearance_flags = RESET_COLOR | KEEP_APART
	rot_deeper()

/datum/component/heretic_dusk_lamp/proc/rot_deeper()
	rot_timer = null
	var/obj/machinery/light/lamp = parent
	rot_stage = min(rot_stage + 1, HERETIC_DUSK_ROT_LAMP_STAGES)
	lamp.bulb_power = clean_power * (1 - rot_stage * HERETIC_DUSK_ROT_LAMP_DIM / 100)
	lamp.update(FALSE, TRUE)
	lamp.update_icon()
	heretic_dusk_sound(lamp, "rot_lamp", 40, TRUE)
	if(rot_stage < HERETIC_DUSK_ROT_LAMP_STAGES)
		rot_timer = addtimer(CALLBACK(src, PROC_REF(rot_deeper)), HERETIC_DUSK_ROT_LAMP_STEP, TIMER_STOPPABLE)

/// Трубку гнилой лампы сняли: скверна и заговор уходят вместе с ней.
/datum/component/heretic_dusk_lamp/proc/rot_replaced()
	var/obj/machinery/light/lamp = parent
	if(QDELETED(src) || !rot_stage || lamp.status == LIGHT_OK)
		return
	lamp.visible_message(span_notice("Вместе с трубкой из [lamp] осыпается зелёная гниль, и копоть в форме пера тает."))
	heretic_dusk_sound(lamp, "rot_cleanse", 50, TRUE)
	log_game("Гнилая лампа Сумрака очищена заменой трубки в [AREACOORD(lamp)].")
	qdel(src)

/datum/component/heretic_dusk_lamp/proc/on_examine(atom/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("На плафоне чёрная копоть в форме пера: эту лампу кто-то трогал, и она мигает, когда рядом проходят.")
	if(rot_stage)
		examine_list += span_warning("Трубку затянула зелёная гниль, свет мутный и с каждой минутой тусклее. Смените трубку: гниль уйдёт вместе с ней.")
	if(IS_HERETIC(user) || user.mind?.isholy)
		examine_list += span_notice("Лампа помнит падшего Сумрака: он уходит в её тень и бьёт её светом. Нулевой жезл или святая вода снимут заговор.")

/datum/component/heretic_dusk_lamp/proc/on_attackby(atom/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod))
		return NONE
	user.visible_message(span_notice("[user] касается лампы нулевым жезлом, и копоть в форме пера осыпается."), span_notice("Копоть осыпается: лампа больше не помнит еретика."))
	log_game("[key_name(user)] снимает заговор Сумрака с лампы в [AREACOORD(source)].")
	qdel(src)
	return COMPONENT_NO_AFTERATTACK

/datum/component/heretic_dusk_lamp/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			source.visible_message(span_notice("Святая вода шипит на плафоне, и копоть в форме пера смывается."))
			qdel(src)
			return

/datum/component/heretic_dusk_lamp/proc/on_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/passerby = arrived
	var/obj/machinery/light/lamp = parent
	if(!isliving(passerby) || !passerby.mind || passerby.stat == DEAD || IS_HERETIC(passerby) || IS_HERETIC_MONSTER(passerby))
		return
	if(lamp.status != LIGHT_OK || !lamp.on || !COOLDOWN_FINISHED(src, flicker_cooldown))
		return
	COOLDOWN_START(src, flicker_cooldown, HERETIC_DUSK_LAMP_FLICKER_COOLDOWN)
	INVOKE_ASYNC(lamp, TYPE_PROC_REF(/obj/machinery/light, flicker), 2)
	heretic_dusk_sound(lamp, "flicker", 30, TRUE)
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	dusk?.on_lamp_flicker(lamp, passerby)

/// Отнятая тень: в темноте цель почти ничего не видит, а её тень тянется к еретику.
/datum/status_effect/heretic_dusk_shadow
	id = "heretic_dusk_shadow"
	duration = HERETIC_DUSK_SHADOW_TIME
	tick_interval = HERETIC_DUSK_LIGHT_CHECK
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_shadow
	examine_text = span_warning("SUBJECTPRONOUN стоит без своей тени: чужая тёмная фигура тянется по полу в сторону. Свет не даёт ей схватить; святая вода в крови вернёт тень.")
	var/datum/weakref/dusk_ref
	var/applied = FALSE
	var/dark = FALSE
	var/shadow_dir
	var/mutable_appearance/silhouette
	var/mutable_appearance/blinded

/datum/status_effect/heretic_dusk_shadow/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dusk/dusk)
	dusk_ref = WEAKREF(dusk)
	return ..()

/datum/status_effect/heretic_dusk_shadow/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!. || !dusk || owner.stat == DEAD)
		return FALSE
	applied = TRUE
	dusk.shadows += src
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	var/previous_colour = owner.client?.color
	owner.add_client_colour(/datum/client_colour/heretic_dusk_faded)
	heretic_dusk_fade_world(owner.client, previous_colour)
	heretic_dusk_sound(owner, "shadow", 50, TRUE)
	owner.visible_message(span_warning("Тень [owner] отрывается от ног и тянется по полу прочь, будто её накрыло чужое крыло."), span_userdanger("Вашу тень отняли! В темноте вы почти ничего не увидите - держитесь света."))
	dusk.feed_on_shadow()
	dusk.lesson_event("shadow", owner)
	tick()
	return TRUE

/datum/status_effect/heretic_dusk_shadow/tick()
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		owner.visible_message(span_notice("Тень возвращается к ногам [owner]."), span_notice("Святая вода в крови возвращает вам тень."))
		qdel(src)
		return
	set_dark(!heretic_dusk_lit(get_turf(owner)))
	point_shadow()

/datum/status_effect/heretic_dusk_shadow/proc/set_dark(value)
	if(dark == value)
		return
	dark = value
	if(dark)
		var/atom/movable/screen/fullscreen/impaired = owner.overlay_fullscreen("heretic_dusk_blind", /atom/movable/screen/fullscreen/scaled/impaired, HERETIC_DUSK_SHADOW_DIM)
		impaired.alpha = 0
		animate(impaired, alpha = 255, time = 0.5 SECONDS, easing = SINE_EASING | EASE_OUT)
		owner.overlay_fullscreen("heretic_dusk_blind_fx", /atom/movable/screen/fullscreen/scaled/heretic_dusk/vignette)
		blinded = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_blind", ABOVE_MOB_LAYER)
		blinded.appearance_flags = RESET_COLOR | KEEP_APART
	else
		owner.clear_fullscreen("heretic_dusk_blind", 0.5 SECONDS)
		owner.clear_fullscreen("heretic_dusk_blind_fx", 0.5 SECONDS)
		blinded = null
	owner.update_icon()

/// Тень лежит на полу со стороны еретика.
/datum/status_effect/heretic_dusk_shadow/proc/point_shadow()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	var/mob/living/heretic = dusk?.dusk_body
	var/direction = heretic && heretic.z == owner.z && heretic != owner ? get_dir(owner, heretic) : SOUTH
	if(!direction)
		direction = SOUTH
	if(direction == shadow_dir && silhouette)
		return
	shadow_dir = direction
	silhouette = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_shadow", BELOW_MOB_LAYER)
	silhouette.appearance_flags = RESET_COLOR | KEEP_APART
	silhouette.pixel_x = ((direction & EAST) ? 1 : ((direction & WEST) ? -1 : 0)) * HERETIC_DUSK_SHADOW_OFFSET
	silhouette.pixel_y = ((direction & NORTH) ? 1 : ((direction & SOUTH) ? -1 : 0)) * HERETIC_DUSK_SHADOW_OFFSET
	owner.update_icon()

/datum/status_effect/heretic_dusk_shadow/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(silhouette)
		overlays += silhouette
	if(blinded)
		overlays += blinded

/datum/status_effect/heretic_dusk_shadow/on_remove()
	if(applied)
		UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
		var/previous_colour = owner.client?.color
		owner.remove_client_colour(/datum/client_colour/heretic_dusk_faded)
		heretic_dusk_fade_world(owner.client, previous_colour)
		var/fade = QDELETED(owner) ? 0 : 0.5 SECONDS
		owner.clear_fullscreen("heretic_dusk_blind", fade)
		owner.clear_fullscreen("heretic_dusk_blind_fx", fade)
		var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
		dusk?.shadows -= src
		silhouette = null
		blinded = null
		owner.update_icon()
	dusk_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dusk_shadow
	name = "Отнятая тень"
	desc = "Вашу тень отняли: в темноте вы почти ничего не видите. Держитесь света; святая вода в крови вернёт тень, а через 20 секунд она вернётся сама."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_blinded"

/// Выжженная тень: Лик ударил в спину, и Крыло находит такую цель на свету.
/datum/status_effect/heretic_dusk_burnt
	id = "heretic_dusk_burnt"
	duration = HERETIC_DUSK_BURNT_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	on_remove_on_mob_delete = TRUE
	alert_type = null
	examine_text = span_warning("На спине выжжен тёмный след, как тень от вспышки в упор.")
	var/datum/weakref/dusk_ref
	var/applied = FALSE
	var/mutable_appearance/scorch

/datum/status_effect/heretic_dusk_burnt/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dusk/dusk)
	dusk_ref = WEAKREF(dusk)
	return ..()

/datum/status_effect/heretic_dusk_burnt/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!. || !dusk || owner.stat == DEAD)
		return FALSE
	applied = TRUE
	dusk.burnt += src
	dusk.notify_resource_changed()
	scorch = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_shadow", BELOW_MOB_LAYER)
	scorch.appearance_flags = RESET_COLOR | KEEP_APART
	scorch.color = HERETIC_DUSK_BURNT_TINT
	scorch.alpha = 120
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	owner.update_icon()
	to_chat(owner, span_warning("Спину обжигает, как от вспышки, а тень под ногами чернеет."))
	return TRUE

/datum/status_effect/heretic_dusk_burnt/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(scorch)
		overlays += scorch

/datum/status_effect/heretic_dusk_burnt/on_remove()
	if(applied)
		UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
		var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
		dusk?.burnt -= src
		dusk?.notify_resource_changed()
		scorch = null
		owner.update_icon()
	dusk_ref = null
	return ..()

/// Удар из тени сбивает с шага: замедление, а не стан.
/datum/status_effect/heretic_dusk_slowed
	id = "heretic_dusk_slowed"
	duration = HERETIC_DUSK_STRIKE_SLOW
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_dusk_slowed/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_slowed)

/datum/status_effect/heretic_dusk_slowed/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_dusk_slowed)
	return ..()

/// Хватка тени: тень с крыльями прибивает цель к полу; руки на экране растут, свет отбрасывает их назад.
/datum/status_effect/heretic_dusk_grip
	id = "heretic_dusk_grip"
	duration = HERETIC_DUSK_GRIP_TIME
	tick_interval = HERETIC_DUSK_GRIP_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_dusk_gripped
	examine_text = span_warning("Собственная тень SUBJECTPRONOUN, раскинув крылья, прижимает его к полу. Святая вода, нулевой жезл или Библия капеллана сорвут её сразу, растолкать можно за 2 секунды, фонарик её ослабит.")
	var/datum/weakref/dusk_ref
	var/mob/living/holder
	var/applied = FALSE
	var/held_since = 0
	var/stage = 1
	var/next_stage_at = 0
	var/mutable_appearance/pinning
	COOLDOWN_DECLARE(light_gap)

/datum/status_effect/heretic_dusk_grip/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dusk/dusk)
	dusk_ref = WEAKREF(dusk)
	holder = dusk?.dusk_body
	if(dusk)
		duration = dusk.grip_time()
	. = ..()
	if(!QDELETED(src))
		refresh_alert_desc()

/// Значок прибитого называет срок именно этой Хватки.
/datum/status_effect/heretic_dusk_grip/proc/refresh_alert_desc()
	if(!linked_alert)
		return
	var/atom/movable/screen/alert/status_effect/heretic_dusk_gripped/base = /atom/movable/screen/alert/status_effect/heretic_dusk_gripped
	linked_alert.desc = "Эта Хватка держит ещё [heretic_dusk_seconds(max(0, duration - world.time))]; на свету Хватка вдвое короче. [initial(base.desc)]"

/datum/status_effect/heretic_dusk_grip/on_apply()
	. = ..()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!. || !dusk || QDELETED(holder) || owner.stat == DEAD)
		return FALSE
	applied = TRUE
	held_since = world.time
	next_stage_at = world.time + HERETIC_DUSK_GRIP_STAGE_TIME
	dusk.grips += src
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, PROC_REF(on_shaken))
	RegisterSignal(owner, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, PROC_REF(on_sacrifice_starting))
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_ATOM_EXPOSE_REAGENTS, PROC_REF(on_exposed))
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(on_overlays))
	RegisterSignal(holder, COMSIG_PARENT_QDELETING, PROC_REF(on_holder_deleted))
	heretic_capture_hold(owner, HERETIC_DUSK_CAPTURE)
	owner.Knockdown(duration)
	owner.Immobilize(duration)
	pinning = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_grip", BELOW_MOB_LAYER)
	pinning.appearance_flags = RESET_COLOR | KEEP_APART
	owner.update_icon()
	show_hands()
	heretic_dusk_sound(owner, "grip", 50, TRUE)
	owner.visible_message(span_danger("Тень [owner] раскидывает крылья и прибивает [owner] к полу!"), span_userdanger("Ваша тень держит вас! Святая вода, нулевой жезл, Библия капеллана или тот, кто растолкает вас за 2 секунды, освободят; фонарик её ослабит."))
	dusk.feed_on_shadow()
	return TRUE

/datum/status_effect/heretic_dusk_grip/tick()
	if(!still_held())
		release("Тень отпускает [owner]: хозяин тени слишком далеко.")
		return
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater))
		release("Святая вода в крови [owner] разжимает Хватку тени.")
		return
	if(world.time >= next_stage_at && stage < 3)
		stage++
		next_stage_at = world.time + HERETIC_DUSK_GRIP_STAGE_TIME
		show_hands()
	refresh_alert_desc()

/datum/status_effect/heretic_dusk_grip/proc/still_held()
	var/turf/holder_turf = get_turf(holder)
	var/turf/owner_turf = get_turf(owner)
	if(!holder_turf || !owner_turf || holder.stat == DEAD || holder_turf.z != owner_turf.z || get_dist(holder_turf, owner_turf) > HERETIC_DUSK_GRIP_BREAK_RANGE)
		return FALSE
	return heretic_can_affect(holder, owner, chargecost = 0, notify = FALSE)

/datum/status_effect/heretic_dusk_grip/proc/show_hands()
	owner.overlay_fullscreen("heretic_dusk_hands", /atom/movable/screen/fullscreen/scaled/heretic_dusk/hands, stage)

/// Фонарик по прибитой цели укорачивает Хватку вдвое и отбрасывает руки тени на ступень.
/datum/status_effect/heretic_dusk_grip/proc/weaken(mob/living/user)
	if(!COOLDOWN_FINISHED(src, light_gap))
		return FALSE
	COOLDOWN_START(src, light_gap, HERETIC_DUSK_GRIP_LIGHT_GAP)
	var/left = max(0, duration - world.time)
	duration = world.time + left / 2
	owner.SetKnockdown(left / 2)
	owner.SetImmobilized(left / 2)
	stage = max(1, stage - 1)
	next_stage_at = world.time + HERETIC_DUSK_GRIP_STAGE_TIME
	show_hands()
	refresh_alert_desc()
	owner.visible_message(span_notice("Луч света бьёт в тень под [owner], и её крылья съёживаются."), span_notice("Свет отбрасывает руки тени назад!"))
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	dusk?.lesson_event("grip_weakened", owner)
	log_combat(user, owner, "ослабляет светом Хватку тени на")
	return TRUE

/datum/status_effect/heretic_dusk_grip/proc/on_attackby(datum/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!isliving(user) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	if(istype(item, /obj/item/nullrod))
		release("[user] касается [owner] нулевым жезлом, и тень с крыльями рассыпается.")
		return COMPONENT_NO_AFTERATTACK
	if(istype(item, /obj/item/storage/book/bible) && user.mind?.isholy)
		release("[user] читает над [owner] молитву, и тень разжимает крылья.")
		return NONE
	if(heretic_dusk_light_item(item))
		weaken(user)
		return COMPONENT_NO_AFTERATTACK
	return NONE

/datum/status_effect/heretic_dusk_grip/proc/on_exposed(atom/source, list/reagents, datum/reagents/holder_reagents, method, volume_modifier, show_message)
	SIGNAL_HANDLER
	if(method != TOUCH && method != VAPOR)
		return
	for(var/datum/reagent/reagent as anything in reagents)
		if(istype(reagent, /datum/reagent/water/holywater))
			release("Святая вода шипит на тени под [owner], и Хватка рвётся.")
			return

/datum/status_effect/heretic_dusk_grip/proc/on_overlays(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(pinning)
		overlays += pinning

/datum/status_effect/heretic_dusk_grip/proc/on_shaken(datum/source)
	SIGNAL_HANDLER
	release("Тень отпускает [owner].")

/datum/status_effect/heretic_dusk_grip/proc/on_sacrifice_starting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_dusk_grip/proc/on_holder_deleted(datum/source)
	SIGNAL_HANDLER
	release()

/datum/status_effect/heretic_dusk_grip/proc/release(message)
	if(QDELETED(src))
		return
	if(message)
		owner.visible_message(span_notice(message), span_notice("Тень отпускает вас."))
	heretic_dusk_sound(owner, "grip_break", 50, TRUE)
	owner.SetKnockdown(0)
	owner.SetImmobilized(0)
	qdel(src)

/datum/status_effect/heretic_dusk_grip/on_remove()
	if(applied)
		UnregisterSignal(owner, list(COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_PARENT_ATTACKBY, COMSIG_ATOM_EXPOSE_REAGENTS, COMSIG_ATOM_UPDATE_OVERLAYS))
		if(holder)
			UnregisterSignal(holder, COMSIG_PARENT_QDELETING)
		var/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/hands = LAZYACCESS(owner.fullscreens, "heretic_dusk_hands")
		hands?.recoil()
		owner.clear_fullscreen("heretic_dusk_hands", 0.5 SECONDS)
		pinning = null
		owner.update_icon()
		var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
		dusk?.grips -= src
		heretic_capture_unhold(owner, HERETIC_DUSK_CAPTURE)
		heretic_capture_release(owner, HERETIC_DUSK_CAPTURE, 0, heretic_capture_held_for(held_since))
	holder = null
	dusk_ref = null
	return ..()

/atom/movable/screen/alert/status_effect/heretic_dusk_gripped
	name = "Хватка тени"
	desc = "Ваша собственная тень прижимает вас к полу до 10 секунд, если хозяин принёс Завет Крыла - до 13. Святая вода, нулевой жезл или Библия капеллана сорвут её сразу, растолкать вас можно за 2 секунды, фонарик укорачивает Хватку вдвое. Уйдите дальше 9 клеток от хозяина тени, если сможете. Крыло с Пером может за 2 секунды утянуть вас в тень: пусть кто-нибудь посветит ему в лицо, ударит его дважды или сильно или растолкает вас."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "dusk_gripped"

/// Перевёрнутый нимб: в тени еретик видит меченого сквозь стены, удар Пера ослепляет.
/datum/status_effect/eldritch/dusk
	id = "dusk_mark"
	mark_name = "Перевёрнутый нимб"
	mark_alert_state = "sigil_dusk"
	effect_sprite_icon = HERETIC_DUSK_FX_ICON
	effect_sprite = "dusk_mark"
	effect_sprite_layer = ABOVE_MOB_LAYER
	detonation_sound = 'modular_bluemoon/sound/heretic/dusk_mark_burst.ogg'
	detonation_visual = /obj/effect/temp_visual/heretic_dusk/mark_burst
	examine_text = span_warning("Над головой висит перевёрнутый нимб, и свет вокруг тускнеет. Удар Пера падшего ослепит меченого: держите его на свету и уведите от еретика.")
	var/datum/weakref/dusk_ref
	var/mutable_appearance/halo
	var/mutable_appearance/dim
	var/mutable_appearance/streak
	var/applied = FALSE

/datum/status_effect/eldritch/dusk/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_dusk/dusk)
	dusk_ref = WEAKREF(dusk)
	halo = mutable_appearance(HERETIC_DUSK_FX_ICON, "dusk_halo", BELOW_MOB_LAYER)
	halo.appearance_flags = RESET_COLOR | KEEP_APART
	// Тень на игровом плане видна и под лампами: тёмное пятно вокруг меченого и вытянутый язык тени, падающий вверх, к свету.
	dim = heretic_dusk_mark_shadow(HERETIC_DUSK_MARK_DIM_ALPHA)
	streak = heretic_dusk_mark_shadow(HERETIC_DUSK_MARK_STREAK_ALPHA)
	streak.transform = matrix(0.55, 0.2, 0, 0, 1.3, world.icon_size * 0.6)
	return ..()

/proc/heretic_dusk_mark_shadow(alpha)
	var/mutable_appearance/shadow = mutable_appearance('icons/effects/light_overlays/light_96.dmi', "light", BELOW_MOB_LAYER)
	shadow.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | PIXEL_SCALE
	shadow.color = HERETIC_DUSK_MARK_SHADOW
	shadow.alpha = alpha
	shadow.pixel_x = -world.icon_size
	shadow.pixel_y = -world.icon_size
	return shadow

/datum/status_effect/eldritch/dusk/on_apply()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(!dusk || !..())
		return FALSE
	applied = TRUE
	dusk.marks += src
	heretic_dusk_sound(owner, "mark", 40, TRUE)
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse/disc = owner.overlay_fullscreen("heretic_dusk_eclipse", /atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse)
	disc.close_over(duration)
	return TRUE

/datum/status_effect/eldritch/dusk/update_owner_underlay(atom/source, list/overlays)
	. = ..()
	overlays += dim
	overlays += streak
	overlays += halo

/datum/status_effect/eldritch/dusk/on_effect()
	var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
	if(dusk?.can_use(dusk.dusk_body) && isturf(owner.loc) && heretic_can_affect(dusk.dusk_body, owner, chargecost = 0))
		owner.adjustBruteLoss(HERETIC_DUSK_MARK_DAMAGE)
		if(!QDELETED(owner))
			owner.blind_eyes(1)
			owner.visible_message(span_danger("Перевёрнутый нимб над [owner] гаснет вспышкой тьмы!"), span_userdanger("Нимб над вами гаснет - и вместе с ним гаснет всё вокруг!"))
	return ..()

/datum/status_effect/eldritch/dusk/on_remove()
	if(applied)
		var/datum/eldritch_knowledge/base_dusk/dusk = dusk_ref?.resolve()
		dusk?.marks -= src
		owner.clear_fullscreen("heretic_dusk_eclipse", 0.5 SECONDS)
	dusk_ref = null
	return ..()

/datum/status_effect/eldritch/dusk/Destroy()
	halo = null
	dim = null
	streak = null
	return ..()

/// Выжженное послесвечение нимба после взгляда Лика или перегрузки фонарика.
/datum/status_effect/heretic_dusk_afterglow
	id = "heretic_dusk_afterglow"
	duration = HERETIC_DUSK_GLARE_BLIND
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_dusk_afterglow/on_creation(mob/living/new_owner, time)
	if(time)
		duration = time
	return ..()

/datum/status_effect/heretic_dusk_afterglow/on_apply()
	. = ..()
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow/glow = owner.overlay_fullscreen("heretic_dusk_afterglow", /atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow)
	glow.burn(duration)

/datum/status_effect/heretic_dusk_afterglow/refresh(effect, ...)
	. = ..()
	var/atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow/glow = LAZYACCESS(owner.fullscreens, "heretic_dusk_afterglow")
	glow?.burn(duration - world.time)

/datum/status_effect/heretic_dusk_afterglow/on_remove()
	owner.clear_fullscreen("heretic_dusk_afterglow", 1 SECONDS)
	return ..()

/// Виньетка затмения и Долгой ночи у экипажа внутри зоны.
/datum/status_effect/heretic_dusk_eclipsed
	id = "heretic_dusk_eclipsed"
	duration = HERETIC_DUSK_ECLIPSED_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/heretic_dusk_eclipsed/on_apply()
	. = ..()
	owner.overlay_fullscreen("heretic_dusk_vignette", /atom/movable/screen/fullscreen/scaled/heretic_dusk/vignette)

/datum/status_effect/heretic_dusk_eclipsed/on_remove()
	owner.clear_fullscreen("heretic_dusk_vignette", 1 SECONDS)
	return ..()

/datum/movespeed_modifier/heretic_dusk_face
	multiplicative_slowdown = -0.15

/datum/movespeed_modifier/heretic_dusk_wing
	multiplicative_slowdown = -0.25

/datum/movespeed_modifier/heretic_dusk_slowed
	multiplicative_slowdown = 1

/// Лик на свету: мир выбелен и чуть приглушён, тени тянутся к тёплому белёсому; цвета узнаются, но с Ликом что-то не так.
/datum/client_colour/heretic_dusk_face
	colour = list(0.735,0.082,0.076, 0.165,0.806,0.149, 0.031,0.03,0.663, 0.065,0.06,0.045)

/// Крыло в тени: мир холодеет и выцветает к лиловому, но красное остаётся красным.
/datum/client_colour/heretic_dusk_wing
	colour = list(0.75,0.24,0.275, 0.18,0.7,0.23, 0.07,0.07,0.62, 0,0,0.015)

/datum/client_colour/heretic_dusk_faded
	colour = list(0.7,0.18,0.18, 0.18,0.7,0.18, 0.12,0.12,0.64, 0,0,0)

/// Кадр 336x240 (21x15 клеток по 16 px) по центру экрана, растянутый на текущий вид, как штатные /scaled.
/// Подвижные части - слои в vis_contents: дыхание, сдвиги, появление и гашение делает animate(), а не кадры.
/// На виде не 21:15 (квадратный 15x15) растягиваются только размытые слои; рисунок держит пропорции и свой край.
/atom/movable/screen/fullscreen/scaled/heretic_dusk
	icon = HERETIC_DUSK_FULLSCREEN_ICON
	icon_state = "dusk_fs_vignette"
	layer = FULLSCREEN_LAYER
	screen_loc = "CENTER:-152,CENTER:-104"
	size_x = 10.5
	size_y = 7.5
	/// Плавное появление; у ударных эффектов ноль, они начинаются вспышкой.
	var/fade_in = 0.5 SECONDS
	/// Не null - весь кадр держит пропорции и прижат к этому краю (0 - по центру), а не растягивается.
	var/fit_anchor
	var/list/atom/movable/screen/heretic_dusk_part/parts

/atom/movable/screen/fullscreen/scaled/heretic_dusk/Initialize(mapload)
	. = ..()
	build()
	if(fade_in)
		alpha = 0
		animate(src, alpha = 255, time = fade_in, easing = SINE_EASING | EASE_OUT)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/Destroy()
	QDEL_LIST(parts)
	return ..()

/atom/movable/screen/fullscreen/scaled/heretic_dusk/SetSeverity(severity)
	src.severity = severity
	icon_state = initial(icon_state)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/SetView(client_view)
	if(view_current == client_view)
		return
	view_current = client_view
	var/list/view_size = getviewsize(client_view)
	var/stretch_x = view_size[1] / size_x
	var/stretch_y = view_size[2] / size_y
	var/even = max(stretch_x, stretch_y)
	var/half_x = size_x * world.icon_size / 2
	var/half_y = size_y * world.icon_size / 2
	if(!isnull(fit_anchor))
		var/shift_x = view_size[1] * world.icon_size / 2 - half_x * even
		var/shift_y = view_size[2] * world.icon_size / 2 - half_y * even
		transform = matrix(even, 0, heretic_dusk_anchor_shift(fit_anchor, EAST, WEST, shift_x), 0, even, heretic_dusk_anchor_shift(fit_anchor, NORTH, SOUTH, shift_y))
		return
	transform = matrix(stretch_x, 0, 0, 0, stretch_y, 0)
	for(var/atom/movable/screen/heretic_dusk_part/part as anything in parts)
		part.fit(even / stretch_x, even / stretch_y, half_x, half_y)

/// Сдвиг к краю: к toward - плюс, к away - минус, иначе ноль.
/proc/heretic_dusk_anchor_shift(anchor, toward, away, shift)
	if(anchor & toward)
		return shift
	if(anchor & away)
		return -shift
	return 0

/// Слои эффекта и их движение.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/proc/build()
	return

/// Слой поверх кадра; anchor - край, у которого рисунок держится на любом виде (null - растягивается с кадром); holder - чей vis_contents.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/proc/add_part(state, alpha = 255, anchor, atom/movable/holder, part_type = /atom/movable/screen/heretic_dusk_part)
	var/atom/movable/screen/heretic_dusk_part/part = new part_type(null, state, length(parts))
	part.alpha = alpha
	part.anchor = anchor
	if(!holder)
		holder = src
	holder.vis_contents += part
	LAZYADD(parts, part)
	return part

/atom/movable/screen/fullscreen/scaled/heretic_dusk/feathers
	icon_state = "dusk_fs_feathers"
	fade_in = 0.8 SECONDS

/atom/movable/screen/fullscreen/scaled/heretic_dusk/feathers/build()
	var/atom/movable/screen/heretic_dusk_part/part = add_part("dusk_fs_feathers_t", anchor = NORTH)
	part.sway(0, -1, 2.8 SECONDS)
	part = add_part("dusk_fs_feathers_b", anchor = SOUTH)
	part.sway(0, 1, 3.3 SECONDS)
	part = add_part("dusk_fs_feathers_l", anchor = WEST)
	part.sway(2, 0, 2.6 SECONDS)
	part.jerk(4, 1, 5.3 SECONDS)
	part = add_part("dusk_fs_feathers_r", anchor = EAST)
	part.sway(-2, 0, 3 SECONDS)
	for(var/side in list(WEST, EAST))
		part = add_part(side == WEST ? "dusk_fs_feathers_eyes_l" : "dusk_fs_feathers_eyes_r", 0, anchor = side)
		animate(part, alpha = 0, time = 3.4 SECONDS, loop = -1)
		animate(alpha = 255, time = 0.4 SECONDS, easing = SINE_EASING)
		animate(time = 0.9 SECONDS)
		animate(alpha = 0, time = 0.5 SECONDS, easing = SINE_EASING)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/glare
	icon_state = "dusk_fs_glare"
	blend_mode = BLEND_ADD
	fade_in = 0.6 SECONDS

/atom/movable/screen/fullscreen/scaled/heretic_dusk/glare/build()
	var/atom/movable/screen/heretic_dusk_part/part = add_part("dusk_fs_glare_rays1")
	part.blend_mode = BLEND_ADD
	part.pulse(40, 4.4 SECONDS)
	part = add_part("dusk_fs_glare_rays2", 40)
	part.blend_mode = BLEND_ADD
	part.pulse(40, 4.4 SECONDS, rising = TRUE)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/glitch
	icon_state = "dusk_fs_glitch"
	fade_in = 0

/atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks
	icon_state = "dusk_fs_cracks"
	fade_in = 0
	var/atom/movable/screen/heretic_dusk_part/embers

/atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks/build()
	embers = add_part("dusk_fs_cracks_embers", 0)
	embers.appearance_flags |= RESET_ALPHA

/atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks/Destroy()
	embers = null
	return ..()

/// Вспышка до peak, одно заикание лампы и гашение за time; угли по трещинам остывают последними.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/cracks/proc/burn_out(time, peak = 255)
	animate(src, alpha = peak, time = 0.1 SECONDS)
	animate(alpha = peak * 0.27, time = 0.05 SECONDS)
	animate(alpha = peak * 0.92, time = 0.08 SECONDS)
	animate(time = 0.25 SECONDS)
	animate(alpha = 0, time = time - 0.48 SECONDS, easing = SINE_EASING | EASE_IN)
	animate(embers, alpha = 0, time = 0.35 SECONDS)
	animate(alpha = 255, time = 0.45 SECONDS, easing = SINE_EASING)
	animate(time = 0.2 SECONDS)
	animate(alpha = 0, time = time - 1 SECONDS, easing = SINE_EASING)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo
	icon_state = "dusk_fs_wings_halo"
	fade_in = 0.8 SECONDS

/atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo/build()
	var/atom/movable/screen/heretic_dusk_part/part = add_part("dusk_fs_wings_halo_l", HERETIC_DUSK_WING_ALPHA, anchor = NORTHWEST)
	part.sway(-1, 2, 3.2 SECONDS)
	part = add_part("dusk_fs_wings_halo_r", HERETIC_DUSK_WING_ALPHA, anchor = NORTHEAST)
	part.sway(1, 2, 3.6 SECONDS)
	part.jerk(-3, 2, 6.1 SECONDS)
	part = add_part("dusk_fs_wings_halo_ring", anchor = NORTH)
	part.sway(0, 1, 4 SECONDS)
	part.jerk(4, 0, 4.7 SECONDS)
	part = add_part("dusk_fs_wings_halo_glow", anchor = NORTH)
	part.pulse(90, 2.2 SECONDS)
	drip(add_part("dusk_fs_wings_halo_drip", anchor = NORTH), FALSE)
	drip(add_part("dusk_fs_wings_halo_drip", 128, anchor = NORTH), TRUE)

/// Капля света стекает из трещины нимба и гаснет; вторая отстаёт на полпути.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/wings_halo/proc/drip(atom/movable/screen/heretic_dusk_part/drop, late)
	var/half = HERETIC_DUSK_DRIP_TIME / 2
	if(late)
		drop.pixel_y = -HERETIC_DUSK_DRIP_FALL / 2
		animate(drop, pixel_y = -HERETIC_DUSK_DRIP_FALL, alpha = 0, time = half, loop = -1)
		animate(pixel_y = 0, alpha = 255, time = 0)
		animate(pixel_y = -HERETIC_DUSK_DRIP_FALL / 2, alpha = 128, time = half)
		return
	animate(drop, pixel_y = -HERETIC_DUSK_DRIP_FALL / 2, alpha = 128, time = half, loop = -1)
	animate(pixel_y = -HERETIC_DUSK_DRIP_FALL, alpha = 0, time = half)
	animate(pixel_y = 0, alpha = 255, time = 0)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse
	icon_state = "dusk_fs_eclipse"
	fade_in = 0.6 SECONDS
	fit_anchor = NORTHEAST
	var/atom/movable/screen/heretic_dusk_part/corona
	var/atom/movable/screen/heretic_dusk_part/moon
	var/atom/movable/screen/heretic_dusk_part/flash

/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse/build()
	corona = add_part("dusk_fs_eclipse_corona", 0)
	var/atom/movable/screen/heretic_dusk_part/disc = add_part("dusk_fs_eclipse_disc")
	disc.appearance_flags |= KEEP_TOGETHER
	moon = add_part("dusk_fs_eclipse_moon", holder = disc)
	moon.blend_mode = BLEND_INSET_OVERLAY
	moon.pixel_x = HERETIC_DUSK_ECLIPSE_MOON_START
	flash = add_part("dusk_fs_eclipse_flash", 0)
	flash.blend_mode = BLEND_ADD

/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse/Destroy()
	corona = null
	moon = null
	flash = null
	return ..()

/// Луна закрывает диск за секунду до конца метки, и последняя секунда - вспышка кольца с бусиной.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/eclipse/proc/close_over(time)
	var/closing = max(time - HERETIC_DUSK_ECLIPSE_FLASH, 0)
	animate(moon, pixel_x = 0, time = closing)
	animate(corona, alpha = 200, time = closing, easing = SINE_EASING | EASE_IN)
	animate(alpha = 0, time = HERETIC_DUSK_ECLIPSE_FLASH, easing = SINE_EASING)
	animate(flash, alpha = 0, time = closing)
	animate(alpha = 255, time = 0.1 SECONDS)
	animate(time = 0.15 SECONDS)
	animate(alpha = 0, time = HERETIC_DUSK_ECLIPSE_FLASH - 0.25 SECONDS, easing = SINE_EASING)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow
	icon_state = "dusk_fs_afterglow"
	layer = BLIND_LAYER + HERETIC_DUSK_PART_LAYER_STEP
	fade_in = 0.15 SECONDS
	fit_anchor = 0

/// Выжженный нимб гаснет за time и дважды дёргается не в такт.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/afterglow/proc/burn(time)
	animate(src, alpha = 255, time = 0.15 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 230, time = time / 4)
	animate(alpha = 50, time = max(time * 3 / 4 - 0.15 SECONDS, 0.1 SECONDS), easing = SINE_EASING)
	animate(src, pixel_x = 0, time = 0.6 SECONDS, flags = ANIMATION_PARALLEL)
	animate(pixel_x = 8, pixel_y = -6, time = HERETIC_DUSK_JERK_TIME)
	animate(time = HERETIC_DUSK_JERK_HOLD)
	animate(pixel_x = 0, pixel_y = 0, time = HERETIC_DUSK_JERK_TIME)
	animate(time = 1.4 SECONDS)
	animate(pixel_x = -6, pixel_y = 4, time = HERETIC_DUSK_JERK_TIME)
	animate(time = HERETIC_DUSK_JERK_HOLD)
	animate(pixel_x = 0, pixel_y = 0, time = HERETIC_DUSK_JERK_TIME)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/vignette
	icon_state = "dusk_fs_vignette"
	fade_in = 0.8 SECONDS

/// Три фазы света по трещинам сменяют друг друга: свет лампы бежит по ним волной.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/vignette/build()
	var/atom/movable/screen/heretic_dusk_part/part = add_part("dusk_fs_vignette_glow1")
	part.cycle_alpha(list(64, 64, 255), 0.8 SECONDS)
	part = add_part("dusk_fs_vignette_glow2", 64)
	part.cycle_alpha(list(255, 64, 64), 0.8 SECONDS)
	part = add_part("dusk_fs_vignette_glow3", 64)
	part.cycle_alpha(list(64, 255, 64), 0.8 SECONDS)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands
	icon_state = "dusk_fs_hands"
	fade_in = 0.4 SECONDS
	severity_min = 1
	severity_max = 3
	var/atom/movable/screen/heretic_dusk_part/veil
	var/list/atom/movable/screen/heretic_dusk_part/hand/hands
	/// Края экрана: шаг от края к центру и сам край.
	var/static/list/side_dirs = list("l" = list(1, 0, WEST), "r" = list(-1, 0, EAST), "t" = list(0, -1, NORTH), "b" = list(0, 1, SOUTH))
	var/static/list/veil_alpha = list(0, 140, 255)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/build()
	veil = add_part("dusk_fs_hands_veil", 0)
	for(var/stage in 1 to 3)
		var/breath = HERETIC_DUSK_HANDS_BREATH
		for(var/side in side_dirs)
			var/list/inward = side_dirs[side]
			var/atom/movable/screen/heretic_dusk_part/hand/hand = add_part("dusk_fs_hands[stage]_[side]", 0, anchor = inward[3], part_type = /atom/movable/screen/heretic_dusk_part/hand)
			hand.stage = stage
			hand.dx = inward[1]
			hand.dy = inward[2]
			hand.breath = breath
			breath += 0.2 SECONDS
			LAZYADD(hands, hand)

/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/Destroy()
	veil = null
	hands = null
	return ..()

/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/SetSeverity(severity)
	if(QDELETED(src))
		return
	var/old_stage = src.severity
	src.severity = clamp(severity, severity_min, severity_max)
	icon_state = initial(icon_state)
	if(src.severity != old_stage)
		show_stage(old_stage, src.severity)

/// Руки новой ступени выползают из-за края, прежние уходят; свет отбрасывает их рывком.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/proc/show_stage(old_stage, new_stage)
	var/thrown_back = new_stage < old_stage
	animate(veil, alpha = veil_alpha[new_stage], time = 0.6 SECONDS, easing = SINE_EASING)
	var/twitching = 0
	for(var/atom/movable/screen/heretic_dusk_part/hand/hand as anything in hands)
		if(hand.stage == new_stage)
			hand.creep_in(thrown_back ? HERETIC_DUSK_HANDS_RETURN : HERETIC_DUSK_HANDS_ENTER, ++twitching == new_stage)
		else if(hand.stage == old_stage)
			hand.withdraw(HERETIC_DUSK_HANDS_GONE, thrown_back ? 0.25 SECONDS : 0.6 SECONDS)

/// Хватка разжата: руки отлетают за край, пока экран гаснет.
/atom/movable/screen/fullscreen/scaled/heretic_dusk/hands/proc/recoil()
	for(var/atom/movable/screen/heretic_dusk_part/hand/hand as anything in hands)
		if(hand.stage == severity)
			hand.withdraw(HERETIC_DUSK_HANDS_GONE * 1.5, 0.3 SECONDS)

/// Слой полноэкранного эффекта Сумрака: тот же кадр 336x240 поверх основы, со своим движением.
/atom/movable/screen/heretic_dusk_part
	icon = HERETIC_DUSK_FULLSCREEN_ICON
	plane = FULLSCREEN_PLANE
	appearance_flags = PIXEL_SCALE | NO_CLIENT_COLOR | TILE_BOUND
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// Край, у которого рисунок держится на виде не 21:15; null - растягивается вместе с кадром.
	var/anchor

/atom/movable/screen/heretic_dusk_part/Initialize(mapload, state, order)
	. = ..(mapload)
	icon_state = state
	layer = FULLSCREEN_LAYER + (order + 1) * HERETIC_DUSK_PART_LAYER_STEP

/// Возвращает рисунку пропорции под растянутым кадром и прижимает его к своему краю.
/atom/movable/screen/heretic_dusk_part/proc/fit(scale_x, scale_y, half_x, half_y)
	if(isnull(anchor))
		return
	transform = matrix(scale_x, 0, heretic_dusk_anchor_shift(anchor, WEST, EAST, half_x * (scale_x - 1)), 0, scale_y, heretic_dusk_anchor_shift(anchor, SOUTH, NORTH, half_y * (scale_y - 1)))

/// Дышит сдвигом: к (dx, dy) пикселей кадра и обратно за period.
/atom/movable/screen/heretic_dusk_part/proc/sway(dx, dy, period)
	animate(src, pixel_x = dx, pixel_y = dy, time = period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_x = 0, pixel_y = 0, time = period / 2, easing = SINE_EASING)

/// Намеренный сбой пути: раз в period слой на миг дёргается на (dx, dy).
/atom/movable/screen/heretic_dusk_part/proc/jerk(dx, dy, period)
	animate(src, pixel_w = 0, pixel_z = 0, time = period - HERETIC_DUSK_JERK_TIME * 2 - HERETIC_DUSK_JERK_HOLD, loop = -1, flags = ANIMATION_PARALLEL)
	animate(pixel_w = dx, pixel_z = dy, time = HERETIC_DUSK_JERK_TIME)
	animate(time = HERETIC_DUSK_JERK_HOLD)
	animate(pixel_w = 0, pixel_z = 0, time = HERETIC_DUSK_JERK_TIME)

/// Пульс прозрачности между low и полной; rising - начинает с low.
/atom/movable/screen/heretic_dusk_part/proc/pulse(low, period, rising = FALSE)
	animate(src, alpha = rising ? 255 : low, time = period / 2, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	animate(alpha = rising ? low : 255, time = period / 2, easing = SINE_EASING)

/// Прозрачность по кругу значений, по step на каждое.
/atom/movable/screen/heretic_dusk_part/proc/cycle_alpha(list/values, step)
	animate(src, alpha = values[1], time = step, easing = SINE_EASING, loop = -1, flags = ANIMATION_PARALLEL)
	for(var/i in 2 to length(values))
		animate(alpha = values[i], time = step, easing = SINE_EASING)

/atom/movable/screen/heretic_dusk_part/hand
	var/stage
	/// Шаг к центру экрана от края, из-за которого рука тянется.
	var/dx = 0
	var/dy = 0
	/// Полный цикл дыхания руки; у краёв разный, чтобы руки не ходили строем.
	var/breath

/// Выползает из-за края с from пикселей кадра и дышит к центру; twitch - раз в два вдоха дёргается.
/atom/movable/screen/heretic_dusk_part/hand/proc/creep_in(from, twitch)
	pixel_x = -dx * from
	pixel_y = -dy * from
	pixel_w = 0
	pixel_z = 0
	animate(src, pixel_x = dx * HERETIC_DUSK_HANDS_IN, pixel_y = dy * HERETIC_DUSK_HANDS_IN, alpha = 255, time = breath / 2, easing = SINE_EASING, loop = -1)
	animate(pixel_x = -dx * HERETIC_DUSK_HANDS_OUT, pixel_y = -dy * HERETIC_DUSK_HANDS_OUT, time = breath / 2, easing = SINE_EASING)
	if(!twitch)
		return
	animate(pixel_x = dx * HERETIC_DUSK_HANDS_IN, pixel_y = dy * HERETIC_DUSK_HANDS_IN, time = breath / 2, easing = SINE_EASING)
	animate(pixel_x = -dx * HERETIC_DUSK_HANDS_OUT, pixel_y = -dy * HERETIC_DUSK_HANDS_OUT, time = breath / 2, easing = SINE_EASING)
	animate(pixel_w = dx * 3, pixel_z = dy * 3, time = HERETIC_DUSK_JERK_TIME)
	animate(time = HERETIC_DUSK_JERK_HOLD)
	animate(pixel_w = 0, pixel_z = 0, time = HERETIC_DUSK_JERK_TIME)

/atom/movable/screen/heretic_dusk_part/hand/proc/withdraw(distance, time)
	animate(src, pixel_x = -dx * distance, pixel_y = -dy * distance, pixel_w = 0, pixel_z = 0, alpha = 0, time = time, easing = SINE_EASING | EASE_OUT)

/// Вспышка Лика: слепит тьмой - сквозь слепоту не светит белым и, отпуская, не застилает экран серым.
/atom/movable/screen/fullscreen/tiled/flash/heretic_dusk
	color = "#050409"

/// Отблеск сквозь стены: облик цели в той клетке экрана, где она стоит, гаснет за 2 секунды.
/atom/movable/screen/heretic_dusk_beacon
	name = "glimpse"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/datum/eldritch_knowledge/base_dusk/dusk

/atom/movable/screen/heretic_dusk_beacon/Initialize(mapload, datum/eldritch_knowledge/base_dusk/dusk, mob/living/target, mob/living/viewer, tint)
	. = ..(mapload)
	src.dusk = dusk
	if(target)
		appearance = target.appearance
	name = "glimpse"
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART | TILE_BOUND
	color = tint
	alpha = 170
	var/dx = target && viewer ? target.x - viewer.x : 0
	var/dy = target && viewer ? target.y - viewer.y : 0
	screen_loc = "CENTER[dx >= 0 ? "+[dx]" : "[dx]"],CENTER[dy >= 0 ? "+[dy]" : "[dy]"]"
	animate(src, alpha = 0, time = HERETIC_DUSK_BEACON_TIME, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, HERETIC_DUSK_BEACON_TIME)

/atom/movable/screen/heretic_dusk_beacon/Destroy()
	if(dusk)
		dusk.dusk_body?.client?.screen -= src
		dusk.beacons -= src
		dusk = null
	return ..()

/obj/effect/temp_visual/heretic_dusk
	icon = HERETIC_DUSK_FX_ICON
	icon_state = "dusk_glare"
	duration = 0.5 SECONDS
	randomdir = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_dusk/grasp
	icon_state = "dusk_shadow"

/obj/effect/temp_visual/heretic_dusk/stance_switch
	icon_state = "dusk_stance_switch"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_dusk/holy_burn
	name = "holy smoke"
	icon_state = "dusk_holy_burn"
	duration = 0.8 SECONDS

/obj/effect/temp_visual/heretic_dusk/wing_guard
	icon_state = "dusk_wing_guard"
	duration = 0.5 SECONDS

/obj/effect/temp_visual/heretic_dusk/grip_rise
	icon_state = "dusk_grip"
	duration = HERETIC_DUSK_GRIP_TELEGRAPH
	layer = BELOW_MOB_LAYER

/// Чернильная лужа на конце Шага: видно, куда ушёл и откуда вышел.
/obj/effect/temp_visual/heretic_dusk/puddle
	name = "ink puddle"
	icon_state = "dusk_ink_puddle"
	duration = HERETIC_DUSK_PUDDLE_TIME
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_dusk/step_out
	icon_state = "dusk_step_out"
	duration = 1.1 SECONDS

/obj/effect/temp_visual/heretic_dusk/step_in
	icon_state = "dusk_step_in"
	duration = 1.1 SECONDS

/obj/effect/temp_visual/heretic_dusk/glare
	icon_state = "dusk_glare"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_dusk/overload
	icon_state = "dusk_overload"

/obj/effect/temp_visual/heretic_dusk/pillar
	name = "pillar of light"
	icon_state = "dusk_pillar"
	duration = HERETIC_DUSK_DESCENT_TELEGRAPH
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_dusk/mark_burst
	icon_state = "dusk_mark"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_dusk/sun_broken
	name = "shattered black sun"
	icon_state = "dusk_black_sun_broken"
	duration = 4 SECONDS

/obj/effect/temp_visual/heretic_dusk/sun_broken/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration, easing = SINE_EASING | EASE_IN)

/// Тьма Локального затмения: один объект с плитками-оверлеями на круг, а не эффект на каждую клетку.
/obj/effect/heretic_dusk_eclipse
	name = "eclipse"
	icon = HERETIC_DUSK_FX_ICON
	icon_state = null
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/heretic_dusk_eclipse/Initialize(mapload, radius)
	. = ..()
	var/list/tiles = list()
	for(var/dx in -radius to radius)
		for(var/dy in -radius to radius)
			if(dx * dx + dy * dy > radius * radius + radius)
				continue
			var/mutable_appearance/tile = mutable_appearance(icon, "dusk_eclipse")
			tile.pixel_x = dx * world.icon_size
			tile.pixel_y = dy * world.icon_size
			tiles += tile
	add_overlay(tiles)
	alpha = 0
	animate(src, alpha = 200, time = 1 SECONDS)

/datum/eldritch_knowledge/base_dusk
	/// Копился ли Сумрак при прошлой проверке света: значок перерисовывается, когда это меняется.
	var/hud_gathering
	COOLDOWN_DECLARE(forced_glitch)

/// Горящий фонарь, который человек держит в руке или носит на каске: им светят туда, куда смотрят.
/proc/heretic_dusk_aimed_light(mob/living/carbon/human/bearer)
	for(var/obj/item/item in bearer.held_items)
		if(heretic_dusk_light_item(item))
			return item
	return heretic_dusk_light_item(bearer.head) ? bearer.head : null

/// Луч фонаря в лицо издалека: человек в 5 клетках смотрит на Крыло с горящим фонарём, а Крыло - на него.
/datum/eldritch_knowledge/base_dusk/proc/torch_in_face_check()
	if(!dusk_body || dusk_body.stat == DEAD || (form != HERETIC_DUSK_FORM_WING && !ascension_active))
		return FALSE
	var/turf/here = get_turf(dusk_body)
	if(!here)
		return FALSE
	for(var/mob/living/carbon/human/bearer as anything in GLOB.human_list)
		if(bearer == dusk_body || bearer.z != here.z || bearer.stat != CONSCIOUS || !GET_CLIENT(bearer) || get_dist(bearer, here) > HERETIC_DUSK_SIGHT_FLASH_RANGE)
			continue
		if(IS_HERETIC(bearer) || IS_HERETIC_MONSTER(bearer) || !is_A_facing_B(bearer, dusk_body) || !is_A_facing_B(dusk_body, bearer))
			continue
		if(!heretic_dusk_aimed_light(bearer) || !(here in heretic_field_view(HERETIC_DUSK_SIGHT_FLASH_RANGE, bearer)))
			continue
		break_drag()
		var/was_dark = world.time >= sight_snuffed_until
		. = snuff_sight(bearer)
		if(. && was_dark)
			dusk_body.balloon_alert(bearer, "луч слепит его")
		return
	return FALSE

/// Значок Сумрака: оттенок облика, буква облика (яркая, пока Сумрак копится), заряды Шага и Нисхождения, багровый фон в окне Удара из тени.
/datum/eldritch_knowledge/base_dusk/style_resource_alert(atom/movable/screen/alert/heretic_resource/indicator, list/resource)
	var/face = form == HERETIC_DUSK_FORM_FACE
	var/value = resource["value"]
	var/strike = world.time < strike_until
	indicator.base_color = face ? HERETIC_DUSK_HUD_FACE : HERETIC_DUSK_HUD_WING
	var/holy_block = holy_gather_block()
	var/letter_color = can_gather() ? (face ? "#ffd479" : "#c2b0ff") : (holy_block ? HERETIC_DUSK_HUD_HOLY : "#8d8794")
	var/static/list/charge_letters = list("step" = "Ш", "descent" = "Н")
	var/list/counters = list()
	for(var/key in charge_letters)
		if(charge_cap(key))
			counters += "<span style='color:[charges[key] ? "#ffffff" : "#ff9e88"]'>[charge_letters[key]][charges[key]]</span>"
	var/locked = world.time < form_locked_until
	if(locked)
		counters += "<span style='color:[HERETIC_DUSK_HUD_HOLY]'>[heretic_capture_seconds_left(form_locked_until)]с</span>"
	var/top = length(counters) ? "[jointext(counters, " ")]<br>" : ""
	indicator.maptext_height = top ? 24 : 12
	indicator.maptext = MAPTEXT("<div style='text-align:center;font-size:8px;color:[value ? "#ffffff" : "#ff9e88"];background-color:[strike ? HERETIC_DUSK_HUD_STRIKE : "#17111d"]'>[top]<span style='color:[letter_color]'>[face ? "Л" : "К"]</span>[value]/[resource["max"]]</div>")
	var/next_change = INFINITY
	if(strike)
		next_change = strike_until
	if(!COOLDOWN_FINISHED(src, light_drink))
		next_change = min(next_change, light_drink)
	if(locked)
		next_change = min(next_change, form_locked_until, world.time + 1 SECONDS)
	if(world.time < holy_silence_until)
		next_change = min(next_change, holy_silence_until, world.time + 1 SECONDS)
	if(next_change != INFINITY)
		addtimer(CALLBACK(src, PROC_REF(notify_resource_changed)), next_change - world.time + 1, TIMER_UNIQUE | TIMER_OVERRIDE)

/// Что святое мешает копить: святая земля, святая вода в крови или на коже; null - не мешает.
/datum/eldritch_knowledge/base_dusk/proc/holy_gather_block()
	if(!dusk_body || dusk_body.stat == DEAD)
		return null
	if(in_holy_ground)
		return "вы на святой земле"
	if(holy_blood)
		return "святая вода в крови"
	if(world.time < holy_silence_until)
		return "святая вода на коже, ещё [heretic_capture_seconds_left(holy_silence_until)] с"
	return null

/// Шаг открывает окно Удара из тени, удар его закрывает: значок узнаёт об этом из тех же событий пути.
/datum/eldritch_knowledge/base_dusk/lesson_event(event, atom/subject, value)
	. = ..()
	if(event == "step" || event == "strike" || event == "holy")
		notify_resource_changed()

#undef HERETIC_DUSK_BURNT_TINT
#undef HERETIC_DUSK_SHADOW_OFFSET
#undef HERETIC_DUSK_GRIP_LIGHT_GAP
#undef HERETIC_DUSK_GRIP_CHECK
#undef HERETIC_DUSK_BEACON_TIME
#undef HERETIC_DUSK_ECLIPSED_TIME
#undef HERETIC_DUSK_CRACKS_TIME
#undef HERETIC_DUSK_PART_LAYER_STEP
#undef HERETIC_DUSK_JERK_TIME
#undef HERETIC_DUSK_JERK_HOLD
#undef HERETIC_DUSK_DRIP_TIME
#undef HERETIC_DUSK_DRIP_FALL
#undef HERETIC_DUSK_ECLIPSE_MOON_START
#undef HERETIC_DUSK_ECLIPSE_FLASH
#undef HERETIC_DUSK_SHADOW_DIM
#undef HERETIC_DUSK_WING_ALPHA
#undef HERETIC_DUSK_HANDS_BREATH
#undef HERETIC_DUSK_HANDS_IN
#undef HERETIC_DUSK_HANDS_OUT
#undef HERETIC_DUSK_HANDS_ENTER
#undef HERETIC_DUSK_HANDS_RETURN
#undef HERETIC_DUSK_HANDS_GONE
#undef HERETIC_DUSK_WORLD_FADE
#undef HERETIC_DUSK_SOFT_CRACKS
#undef HERETIC_DUSK_MARK_DIM_ALPHA
#undef HERETIC_DUSK_MARK_STREAK_ALPHA
#undef HERETIC_DUSK_MARK_SHADOW
#undef HERETIC_DUSK_HUD_FACE
#undef HERETIC_DUSK_HUD_WING
#undef HERETIC_DUSK_HUD_STRIKE
#undef HERETIC_DUSK_HUD_HOLY
