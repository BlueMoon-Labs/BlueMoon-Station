#define HERETIC_VOID_INK heretic_path_ink(PATH_VOID)
#define HERETIC_VOID_MOTE_RATE 0.25
#define HERETIC_VOID_MOTE_SPIN (6 SECONDS)
#define HERETIC_VOID_MOTE_SEGMENTS 12
#define HERETIC_VOID_DEFLECT_OFFSET 14
#define HERETIC_VOID_DEFLECT_RADIUS 1
#define HERETIC_VOID_DEFLECT_TIME (0.4 SECONDS)
#define HERETIC_VOID_FROST_TIME (0.6 SECONDS)
#define HERETIC_VOID_FLASH_RANGE 2
#define HERETIC_VOID_FLASH_POWER 1.2
#define HERETIC_VOID_FLASH_TIME (0.3 SECONDS)
#define HERETIC_VOID_DEFLECT_THROTTLE (0.25 SECONDS)
#define HERETIC_VOID_FROST_SIZE 2
#define HERETIC_VOID_FX_ICON 'modular_bluemoon/icons/obj/heretic_void_fx.dmi'
#define HERETIC_VOID_LARGE_ICON 'modular_bluemoon/icons/obj/heretic_void.dmi'
#define HERETIC_VOID_LARGE_OFFSET -32
#define HERETIC_VOID_CHILL_FADE (0.4 SECONDS)
#define HERETIC_VOID_BALL_FADE (0.3 SECONDS)
#define HERETIC_VOID_PRISON_CHECK (0.5 SECONDS)
#define HERETIC_VOID_SEAL_SOUND 'modular_bluemoon/sound/heretic/void_prison_seal.ogg'
#define HERETIC_VOID_BREAK_SOUND 'modular_bluemoon/sound/heretic/void_prison_break.ogg'
#define HERETIC_VOID_GATHER_SOUND 'modular_bluemoon/sound/heretic/void_domain_gather.ogg'
#define HERETIC_VOID_EVENT_VOLUME 50
#define HERETIC_VOID_SNOW_RATE 0.025

/datum/status_effect/heretic_void_chill
	id = "heretic_void_chill"
	duration = 4 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/heretic_void_chill
	examine_text = span_warning("SUBJECTPRONOUN еле переставляет ноги, покрытые инеем.")
	var/obj/effect/abstract/heretic_vfx_attached/frost

/datum/status_effect/heretic_void_chill/on_apply()
	. = ..()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	to_chat(owner, span_warning("Пустота сковывает ваши движения!"))
	if(ishuman(owner))
		frost = heretic_vfx_attach(owner, HERETIC_VOID_FX_ICON, "chill_frost", fade_in = HERETIC_VOID_CHILL_FADE, glow = FALSE, upright = FALSE)
		frost?.vis_flags |= VIS_INHERIT_DIR

/datum/status_effect/heretic_void_chill/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	frost?.fade_out(HERETIC_VOID_CHILL_FADE)
	frost = null
	return ..()

/datum/movespeed_modifier/heretic_void_chill
	multiplicative_slowdown = 2
	conflicts_with = /datum/movespeed_modifier/heretic_void_chill

/obj/effect/heretic_combat_zone/void
	var/obj/effect/abstract/heretic_particle_holder/snowfall

/obj/effect/heretic_combat_zone/void/Initialize(mapload, datum/mind/master)
	. = ..()
	var/datum/movespeed_modifier/chill_modifier = get_cached_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill)
	zone_slowdown.multiplicative_slowdown = chill_modifier.multiplicative_slowdown
	zone_slowdown.conflicts_with = chill_modifier.conflicts_with
	snowfall = heretic_vfx_attach_particles(src, /particles/heretic_ascension/void/snowfall, glow = FALSE)
	if(snowfall?.particles)
		var/reach = (radius + 0.5) * world.icon_size
		snowfall.particles.position = generator("box", list(-reach, -reach, 0), list(reach, reach, 0))
		snowfall.particles.spawning = HERETIC_VOID_SNOW_RATE * (2 * radius + 1) ** 2
	var/mob/living/user = master?.current
	if(!QDELETED(user) && user.stat != DEAD && IS_HERETIC(user))
		tick_zone(user)

/obj/effect/heretic_combat_zone/void/Destroy()
	heretic_vfx_release_particles(src, snowfall)
	snowfall = null
	return ..()

/datum/eldritch_knowledge/base_void
	var/list/obj/machinery/light/frosted_lamps = list()
	var/list/datum/status_effect/heretic_void_prison/prisons = list()
	var/void_failure

/datum/eldritch_knowledge/base_void/pocket_door(mob/living/user, mob/living/victim)
	if(!door_holds(user, victim))
		return null
	return list("name" = "в зиму", "text" = "Иней под [victim] проваливается в белую пустоту.", "time" = HERETIC_POCKET_PULL_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim))

/// Цель в своём ледяном шаре или готовая цель в своём зимнем поле, еретик рядом.
/datum/eldritch_knowledge/base_void/proc/door_holds(mob/living/user, mob/living/victim)
	if(!door_user_ready(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > 1)
		return FALSE
	if(imprisoned_by_me(victim))
		return TRUE
	if(!door_zone_under(victim, /obj/effect/heretic_combat_zone/void))
		return FALSE
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return heretic.hunt_target_ready(victim)

/datum/eldritch_knowledge/base_void/pocket_exits(mob/living/user)
	. = list()
	for(var/obj/machinery/light/lamp as anything in frosted_lamps)
		var/turf/landing = heretic_pocket_landing(get_turf(lamp))
		if(landing)
			heretic_add_pocket_exit(., "Иней - [get_area_name(lamp, TRUE)]", landing)
	if(!length(.))
		return null

/// Холод для осколков и лечения: воздух не теплее 0 °C или своя заиндевевшая лампа рядом.
/datum/eldritch_knowledge/base_void/proc/cold_floor(turf/open/floor/floor)
	if(!istype(floor))
		return FALSE
	return floor.GetTemperature() <= T0C || !!frost_at(floor)

/datum/eldritch_knowledge/base_void/proc/frost_at(turf/place)
	for(var/obj/machinery/light/lamp as anything in frosted_lamps)
		if(lamp.z == place?.z && get_dist(lamp, place) <= HERETIC_VOID_FROST_REACH)
			return lamp
	return null

/// Погашенная хваткой лампа покрывается инеем; самая старая тает, когда ламп больше предела.
/datum/eldritch_knowledge/base_void/proc/frost_lamp(obj/machinery/light/lamp)
	if(QDELETED(lamp) || heretic_craft_on(lamp, HERETIC_VOID_FROST_CRAFT))
		return FALSE
	var/rime_state = "lamp_frost"
	if(lamp.fitting == "bulb")
		rime_state = "lamp_frost_bulb"
	else if(lamp.fitting != "tube")
		rime_state = "lamp_frost_floor"
	var/mutable_appearance/rime = mutable_appearance(HERETIC_VOID_FX_ICON, rime_state)
	rime.dir = lamp.dir
	lamp.AddComponent(/datum/component/heretic_craft, src, HERETIC_VOID_FROST_CRAFT, "Стекло лампы изнутри затянуто инеем, а пол под ней холодный, хотя воздух тёплый.", rime)
	if(!heretic_craft_on(lamp, HERETIC_VOID_FROST_CRAFT))
		return FALSE
	frosted_lamps += lamp
	RegisterSignal(lamp, COMSIG_ATOM_UPDATED_ICON, PROC_REF(on_lamp_updated))
	while(length(frosted_lamps) > HERETIC_VOID_FROST_LIMIT)
		thaw_lamp(frosted_lamps[1])
	return TRUE

/datum/eldritch_knowledge/base_void/proc/thaw_lamp(obj/machinery/light/lamp)
	var/datum/component/heretic_craft/craft = heretic_craft_on(lamp, HERETIC_VOID_FROST_CRAFT)
	if(craft)
		qdel(craft)
		return
	on_craft_removed(lamp, HERETIC_VOID_FROST_CRAFT)

/datum/eldritch_knowledge/base_void/on_craft_removed(atom/crafted, craft_id)
	if(craft_id != HERETIC_VOID_FROST_CRAFT)
		return
	frosted_lamps -= crafted
	UnregisterSignal(crafted, COMSIG_ATOM_UPDATED_ICON)

/// Новая трубка или пустой патрон: иней со старой лампы сходит.
/datum/eldritch_knowledge/base_void/proc/on_lamp_updated(obj/machinery/light/lamp)
	SIGNAL_HANDLER
	if(lamp.status == LIGHT_BURNED)
		return
	lamp.visible_message(span_notice("Иней на [lamp] тает и стекает каплями."))
	thaw_lamp(lamp)

/datum/eldritch_knowledge/base_void/proc/imprisoned_by_me(mob/living/victim)
	var/datum/status_effect/heretic_void_prison/prison = victim?.has_status_effect(/datum/status_effect/heretic_void_prison)
	return prison?.knowledge_ref?.resolve() == src

/datum/eldritch_knowledge/base_void/proc/break_prisons()
	for(var/datum/status_effect/heretic_void_prison/prison as anything in prisons.Copy())
		qdel(prison)

/// Своё зимнее поле на клетке: Зимний предел, поле фонаря, домен или зимний круг такта.
/datum/eldritch_knowledge/base_void/proc/own_winter_zone(mob/living/user, turf/place)
	for(var/obj/effect/heretic_combat_zone/void/zone in range(HERETIC_VOID_PRISON_RANGE + 1, place))
		if(!QDELETED(zone) && zone.master_mind?.resolve() == user.mind && (place in zone.field_turfs))
			return zone
	return null

/datum/eldritch_knowledge/base_void/proc/prison_ready(mob/living/user, mob/living/victim)
	if(!heretic_capture_downed(victim) && !victim.has_status_effect(/datum/status_effect/heretic_void_chill))
		return FALSE
	return get_dist(user, victim) <= 1 || !!own_winter_zone(user, get_turf(victim))

/datum/eldritch_knowledge/base_void/proc/prison_block_reason(mob/living/user, atom/target, check_cost = TRUE, check_ready = TRUE)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/required = heretic?.get_knowledge(/datum/eldritch_knowledge/spell/void_prison)
	if(!heretic || heretic.get_knowledge(type) != src || QDELETED(required))
		return "Способность недоступна вашему пути или текущему телу."
	var/reason = heretic_capture_block_reason(user, target, HERETIC_VOID_CAPTURE)
	if(reason)
		return reason
	var/mob/living/victim = target
	if(!isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_VOID_PRISON_RANGE || !heretic_edge_line_clear(user, victim))
		return "Цель должна стоять на полу не дальше [HERETIC_VOID_PRISON_RANGE] клеток по открытой линии."
	if(victim.has_status_effect(/datum/status_effect/heretic_void_prison))
		return "Цель уже во льду."
	if(check_ready && !prison_ready(user, victim))
		return "Лёд смыкается только вокруг сбитой с ног, обессиленной или скованной холодом цели - рядом с вами или в вашем зимнем поле."
	if(check_cost && combat_resource < HERETIC_VOID_PRISON_COST)
		return "Для Ледяной темницы нужен [HERETIC_VOID_PRISON_COST] осколок зимы."
	return null

/datum/eldritch_knowledge/base_void/proc/prison(mob/living/user, mob/living/victim)
	void_failure = prison_block_reason(user, victim)
	if(void_failure || !spend_combat_resource(HERETIC_VOID_PRISON_COST))
		return FALSE
	var/turf/place = get_turf(victim)
	var/obj/effect/temp_visual/heretic_void_seal/seal = new(place)
	addtimer(CALLBACK(src, PROC_REF(seal_prison), user, victim, place, seal), HERETIC_VOID_PRISON_TELEGRAPH)
	user.visible_message(span_danger("Воздух вокруг [victim] трещит: из пустоты нарастают ледяные иглы!"), span_notice("Лёд смыкается вокруг [victim]."))
	playsound(place, HERETIC_VOID_SEAL_SOUND, HERETIC_VOID_EVENT_VOLUME, TRUE)
	return TRUE

/datum/eldritch_knowledge/base_void/proc/seal_prison(mob/living/user, mob/living/victim, turf/place, obj/effect/seal)
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	if(QDELETED(victim) || victim.loc != place)
		refund_prison(user, "Цель ушла из-под льда, и темница рассыпалась инеем.", seal)
		return FALSE
	var/reason = prison_block_reason(user, victim, check_cost = FALSE, check_ready = FALSE)
	if(reason)
		refund_prison(user, "Темница рассыпалась: [reason]", seal)
		return FALSE
	if(!victim.apply_status_effect(/datum/status_effect/heretic_void_prison, src, user))
		return FALSE
	log_combat(user, victim, "замораживает в ледяной темнице")
	return TRUE

/datum/eldritch_knowledge/base_void/proc/refund_prison(mob/living/user, reason, obj/effect/temp_visual/heretic_void_seal/seal)
	gain_combat_resource(HERETIC_VOID_PRISON_COST)
	if(!QDELETED(seal))
		seal.crumble()
	heretic_refund_capture(user, /obj/effect/proc_holder/spell/pointed/heretic_void/prison, reason)

/// Ледяной шар: цель немая, неуязвимая и вне жизни тела, пока её не растопят, не расколют или не растолкают.
/datum/status_effect/heretic_void_prison
	id = "heretic_void_prison"
	duration = HERETIC_VOID_PRISON_DURATION
	tick_interval = HERETIC_VOID_PRISON_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_void_prison
	examine_text = span_warning("SUBJECTPRONOUN - внутри ледяного шара: огонь или сварка растопят лёд за 2 секунды, нулевой жезл расколет сразу, а ещё можно растолкать за 2 секунды.")
	var/held_since = 0
	var/datum/weakref/knowledge_ref
	var/datum/weakref/jailer_ref
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/obj/effect/abstract/heretic_vfx_attached/ball
	var/granted_godmode = FALSE

/datum/status_effect/heretic_void_prison/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_void/void, mob/living/jailer)
	knowledge_ref = WEAKREF(void)
	jailer_ref = WEAKREF(jailer)
	return ..()

/datum/status_effect/heretic_void_prison/on_apply()
	. = ..()
	if(!.)
		return
	var/datum/eldritch_knowledge/base_void/void = knowledge_ref?.resolve()
	void?.prisons += src
	held_since = world.time
	restraint = new(list(owner, HERETIC_VOID_PRISON_DURATION, TRUE))
	if(!(owner.status_flags & GODMODE))
		owner.status_flags |= GODMODE
		granted_godmode = TRUE
	ADD_TRAIT(owner, TRAIT_MUTE, REF(src))
	ball = heretic_vfx_attach(owner, HERETIC_VOID_LARGE_ICON, "void_prison", fade_in = HERETIC_VOID_BALL_FADE, glow = FALSE)
	if(ball)
		ball.pixel_x = HERETIC_VOID_LARGE_OFFSET
		ball.pixel_y = HERETIC_VOID_LARGE_OFFSET
		ball.layer = ABOVE_MOB_LAYER
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignals(owner, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(end_prison))
	heretic_capture_hold(owner, HERETIC_VOID_CAPTURE)
	heretic_capture_lock_pull(owner, jailer_ref?.resolve(), REF(src))
	owner.visible_message(span_warning("Лёд смыкается над [owner]: внутри шара застыло тело, и ни звука не слышно."), span_userdanger("Вас сковал лёд: ни шевельнуться, ни крикнуть!"))

/datum/status_effect/heretic_void_prison/tick()
	if(!owner.on_fire && !(locate(/obj/effect/hotspot) in owner.loc))
		return
	owner.visible_message(span_warning("Пламя растапливает ледяной шар вокруг [owner]."))
	qdel(src)

/datum/status_effect/heretic_void_prison/proc/on_life(datum/source)
	SIGNAL_HANDLER
	return COMPONENT_INTERRUPT_LIFE_BIOLOGICAL

/datum/status_effect/heretic_void_prison/proc/thaw_source(obj/item/item)
	return item?.get_temperature() >= HERETIC_VOID_PRISON_THAW_HEAT

/datum/status_effect/heretic_void_prison/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(istype(item, /obj/item/nullrod))
		user.visible_message(span_warning("[user] касается шара вокруг [source] нулевым жезлом, и лёд раскалывается."), span_notice("Вы касаетесь льда нулевым жезлом, и он раскалывается."))
		log_game("[key_name(user)] раскалывает ледяную темницу [key_name(source)] нулевым жезлом в [AREACOORD(source)].")
		qdel(src)
		return COMPONENT_NO_AFTERATTACK
	if(!thaw_source(item))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(thaw), user, item)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_void_prison/proc/thaw(mob/living/helper, obj/item/heat_source)
	if(LAZYFIND(helper.do_afters, owner))
		return FALSE
	helper.visible_message(span_warning("[helper] ведёт [heat_source] по ледяному шару вокруг [owner], и лёд начинает плыть."), span_notice("Вы растапливаете лёд. Не отходите [DisplayTimeText(HERETIC_VOID_PRISON_THAW_TIME)]."))
	var/mob/living/prisoner = owner
	if(!do_after(helper, HERETIC_VOID_PRISON_THAW_TIME, prisoner, extra_checks = CALLBACK(src, PROC_REF(thaw_holds), heat_source)))
		return FALSE
	if(QDELETED(src))
		return FALSE
	helper.visible_message(span_notice("[helper] растапливает ледяной шар, и [prisoner] вываливается наружу."))
	log_game("[key_name(helper)] растапливает ледяную темницу [key_name(prisoner)] в [AREACOORD(prisoner)].")
	qdel(src)
	return TRUE

/datum/status_effect/heretic_void_prison/proc/thaw_holds(obj/item/heat_source)
	return !QDELETED(src) && thaw_source(heat_source)

/datum/status_effect/heretic_void_prison/proc/end_prison(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Шар тянут по шагу; перенос дальше соседней клетки (изнанка, телепорт) оставляет лёд позади.
/datum/status_effect/heretic_void_prison/proc/on_moved(datum/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!isturf(owner.loc) || !isturf(old_loc) || get_dist(old_loc, owner.loc) > 1)
		qdel(src)

/datum/status_effect/heretic_void_prison/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_LIVING_LIFE, COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	heretic_capture_unhold(owner, HERETIC_VOID_CAPTURE)
	heretic_capture_unlock_pull(owner, REF(src))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	if(granted_godmode)
		owner.status_flags &= ~GODMODE
	REMOVE_TRAIT(owner, TRAIT_MUTE, REF(src))
	ball?.fade_out(HERETIC_VOID_BALL_FADE)
	ball = null
	var/datum/eldritch_knowledge/base_void/void = knowledge_ref?.resolve()
	void?.prisons -= src
	if(isturf(owner.loc))
		new /obj/effect/temp_visual/heretic_void_shatter(owner.loc)
		playsound(owner, HERETIC_VOID_BREAK_SOUND, HERETIC_VOID_EVENT_VOLUME, TRUE)
	if(!QDELETED(owner) && owner.stat != DEAD)
		owner.apply_status_effect(/datum/status_effect/heretic_void_chill)
	heretic_capture_release(owner, HERETIC_VOID_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_void_prison
	name = "Ледяная темница"
	desc = "Вы вмёрзли в лёд: не двигаетесь и не говорите, но и урона не получаете. Шар растопят огонь, сварка или зажигалка за 2 секунды, нулевой жезл расколет сразу, а ещё вас можно растолкать за 2 секунды."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "void_prison"

/obj/effect/proc_holder/spell/pointed/heretic_void
	clothes_req = FALSE
	invocation_type = "none"
	selection_type = "view"
	aim_assist = FALSE
	heretic_stun_check = TRUE
	action_icon = HERETIC_VOID_FX_ICON
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/heretic_void/prison
	name = "Ледяная темница"
	desc = "За осколок зимы заморозьте в ледяном шаре на 10 секунд сбитую, обессиленную или скованную холодом цель рядом с собой или в своём зимнем поле, до 4 клеток. В шаре цель немая и неуязвимая. Огонь и сварка растапливают шар, нулевой жезл раскалывает."
	summary = "10 секунд в ледяном шаре для сбитой или скованной цели рядом или в вашем поле; 1 осколок."
	charge_max = HERETIC_VOID_PRISON_COOLDOWN
	range = HERETIC_VOID_PRISON_RANGE
	aim_assist_radius = 1
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "void_prison"
	active_msg = "Укажите цель, которую скуёт лёд."
	deactive_msg = "Вы отпускаете холод."

/obj/effect/proc_holder/spell/pointed/heretic_void/prison/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_void/void = heretic?.get_knowledge(/datum/eldritch_knowledge/base_void)
	if(!heretic_check(user, !!void, silent, "Способность недоступна вашему пути или текущему телу."))
		return FALSE
	var/reason = void.prison_block_reason(user, target)
	return heretic_check(user, !reason, silent, reason, target = target)

/obj/effect/proc_holder/spell/pointed/heretic_void/prison/cast(list/targets, mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/base_void/void = heretic?.get_knowledge(/datum/eldritch_knowledge/base_void)
	if(!length(targets) || !void?.prison(user, targets[1]))
		heretic_revert_cast(user, void?.void_failure)

/// Нарастание льда вокруг цели: если она уйдёт с клетки, иглы осыпаются.
/obj/effect/temp_visual/heretic_void_seal
	icon = HERETIC_VOID_LARGE_ICON
	icon_state = "void_prison_seal"
	randomdir = FALSE
	duration = HERETIC_VOID_PRISON_TELEGRAPH
	pixel_x = HERETIC_VOID_LARGE_OFFSET
	pixel_y = HERETIC_VOID_LARGE_OFFSET

/obj/effect/temp_visual/heretic_void_seal/proc/crumble()
	animate(src, alpha = 0, time = HERETIC_VOID_BALL_FADE, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, HERETIC_VOID_BALL_FADE)

/obj/effect/temp_visual/heretic_void_shatter
	icon = HERETIC_VOID_LARGE_ICON
	icon_state = "void_prison_shatter"
	randomdir = FALSE
	duration = 0.8 SECONDS
	pixel_x = HERETIC_VOID_LARGE_OFFSET
	pixel_y = HERETIC_VOID_LARGE_OFFSET

/obj/effect/temp_visual/heretic_void_swap
	icon = HERETIC_VOID_LARGE_ICON
	icon_state = "void_swap"
	randomdir = FALSE
	duration = 0.8 SECONDS
	pixel_x = HERETIC_VOID_LARGE_OFFSET
	pixel_y = HERETIC_VOID_LARGE_OFFSET

/// Сосредоточение домена: пустота стягивается к еретику, сорванное - рассеивается.
/obj/effect/temp_visual/heretic_void_gather
	icon = HERETIC_VOID_LARGE_ICON
	icon_state = "void_gather"
	randomdir = FALSE
	duration = 3 SECONDS
	pixel_x = HERETIC_VOID_LARGE_OFFSET
	pixel_y = HERETIC_VOID_LARGE_OFFSET
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/heretic_void_gather/Initialize(mapload)
	. = ..()
	playsound(src, HERETIC_VOID_GATHER_SOUND, HERETIC_VOID_EVENT_VOLUME, FALSE)

/obj/effect/temp_visual/heretic_void_gather/proc/dissolve()
	if(QDELETED(src))
		return
	deltimer(timerid)
	animate(src, alpha = 0, time = HERETIC_VOID_BALL_FADE, easing = SINE_EASING | EASE_IN)
	QDEL_IN(src, HERETIC_VOID_BALL_FADE)

/obj/effect/temp_visual/heretic_void_push
	icon = HERETIC_VOID_FX_ICON
	icon_state = "void_push"
	randomdir = FALSE
	duration = 0.6 SECONDS

/obj/effect/temp_visual/heretic_void_push/Initialize(mapload, set_dir)
	if(set_dir)
		setDir(set_dir)
	return ..()

/atom/movable/screen/alert/status_effect/heretic_void_chill
	name = "Скованность Пустоты"
	desc = "Магия Пустоты замедляет ваши движения независимо от температуры тела. Эффект проходит через 4 секунды после последнего воздействия. Выйдите из зимнего поля и оторвитесь от еретика, чтобы скованность спала. Повторные воздействия обновляют время, не усиливая замедление."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "void_chill"

/obj/item/melee/sickly_blade/void/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	var/datum/eldritch_knowledge/void_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	if(!upgrade)
		. += span_notice("Для сдвига к отмеченному врагу нужно знание «Ищущий клинок» Пути Пустоты.")
		return
	. += span_notice("Держите клинок в активной руке и нажмите ЛКМ по врагу с Меткой Пустоты вне досягаемости удара, в поле зрения и не дальше 5 клеток. Shift не требуется. Возле цели нужна клетка без препятствий; защита от магии блокирует сдвиг.")
	var/cooldown_text = COOLDOWN_FINISHED(upgrade, blink_cooldown) ? "Ищущий клинок: сдвиг готов." : "Ищущий клинок: сдвиг восстановится через [DisplayTimeText(COOLDOWN_TIMELEFT(upgrade, blink_cooldown))]."
	. += span_notice(cooldown_text)

/proc/heretic_void_overheated(mob/living/owner)
	return owner.on_fire || owner.bodytemperature > BODYTEMP_NORMAL + HERETIC_VOID_HEAT_MARGIN

/// Безвоздушная буря вознесения: снаряды, летящие в еретика, с шансом разворачиваются назад, пока он не разогрет.
/datum/component/heretic_void_storm
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/deflect_chance = HERETIC_VOID_DEFLECT_CHANCE
	var/obj/effect/abstract/heretic_particle_holder/motes
	COOLDOWN_DECLARE(deflect_visual)

/datum/component/heretic_void_storm/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	motes = heretic_vfx_attach_particles(parent, /particles/heretic_ascension/void/motes)
	motes?.SpinAnimation(HERETIC_VOID_MOTE_SPIN, -1, TRUE, HERETIC_VOID_MOTE_SEGMENTS, parallel = FALSE)
	update_motes()

/datum/component/heretic_void_storm/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_RUN_BLOCK, PROC_REF(deflect))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_LIVING_LIFE, PROC_REF(on_life))

/datum/component/heretic_void_storm/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_LIVING_RUN_BLOCK, COMSIG_PARENT_EXAMINE, COMSIG_LIVING_LIFE))

/datum/component/heretic_void_storm/Destroy()
	heretic_vfx_release_particles(parent, motes)
	motes = null
	return ..()

/// Снег бури кружит вокруг вознесённого, пока жар не заглушит её.
/datum/component/heretic_void_storm/proc/update_motes()
	var/mob/living/owner = parent
	if(!motes?.particles)
		return
	var/rate = (owner.stat == DEAD || heretic_void_overheated(owner)) ? 0 : HERETIC_VOID_MOTE_RATE
	if(motes.particles.spawning != rate)
		motes.particles.spawning = rate

/datum/component/heretic_void_storm/proc/on_life(mob/living/source, seconds, times_fired)
	SIGNAL_HANDLER
	update_motes()

/datum/component/heretic_void_storm/proc/deflect(mob/living/source, real_attack, atom/object, damage, attack_text, attack_type, armour_penetration, mob/living/attacker, def_zone, list/return_list, attack_direction)
	SIGNAL_HANDLER
	if(heretic_void_overheated(source))
		return BLOCK_NONE
	var/obj/item/projectile/projectile = heretic_try_deflect(source, real_attack, object, attack_type, deflect_chance)
	if(!projectile)
		return BLOCK_NONE
	playsound(source, pick('modular_bluemoon/sound/heretic/void_deflect1.ogg', 'modular_bluemoon/sound/heretic/void_deflect2.ogg', 'modular_bluemoon/sound/heretic/void_deflect3.ogg'), 50, TRUE)
	source.visible_message(span_warning("Безвоздушная буря вокруг [source] сбивает [projectile] с курса!"), span_notice("Буря разворачивает [projectile] назад."))
	heretic_vfx_pulse(projectile, HERETIC_VOID_INK, HERETIC_VOID_FROST_SIZE, HERETIC_VOID_FROST_TIME)
	if(COOLDOWN_FINISHED(src, deflect_visual) && heretic_vfx_watched(source))
		COOLDOWN_START(src, deflect_visual, HERETIC_VOID_DEFLECT_THROTTLE)
		show_deflect(source, projectile.Angle)
	return BLOCK_SUCCESS | BLOCK_REDIRECTED

/// Пространство рябит в точке попадания, иней сыплется по новому курсу снаряда, воздух вспыхивает холодом.
/datum/component/heretic_void_storm/proc/show_deflect(mob/living/source, angle)
	heretic_vfx_shockwave(source, HERETIC_VOID_INK, HERETIC_VOID_DEFLECT_RADIUS, HERETIC_VOID_DEFLECT_TIME, sin(angle) * HERETIC_VOID_DEFLECT_OFFSET, cos(angle) * HERETIC_VOID_DEFLECT_OFFSET)
	heretic_vfx_spray(source, /particles/heretic_ascension/void/frost, angle, HERETIC_VOID_DEFLECT_OFFSET)
	heretic_vfx_flash(source, HERETIC_VOID_INK, HERETIC_VOID_FLASH_RANGE, HERETIC_VOID_FLASH_POWER, HERETIC_VOID_FLASH_TIME)

/datum/component/heretic_void_storm/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(heretic_void_overheated(source))
		examine_list += span_notice("Буря вокруг стихла: тело слишком разогрето, и снаряды долетают без помех.")
	else
		examine_list += span_warning("Вокруг бушует безвоздушная буря, часть снарядов разворачивается назад. Огонь и жар её глушат.")

/// Пустота: снег, медленно кружащий вокруг вознесённого.
/particles/heretic_ascension/void/motes
	count = 10
	spawning = HERETIC_VOID_MOTE_RATE
	position = generator("circle", 10, 22)
	velocity = generator("circle", 0, 0.3)
	gravity = list(0, 0)
	friction = 0.02
	drift = generator("box", list(-0.05, -0.05, 0), list(0.05, 0.05, 0))
	lifespan = 2.5 SECONDS
	fade = 1 SECONDS
	fadein = 0.5 SECONDS

/// Пустота: снег медленно падает над зимним полем; охват и частота задаются размером поля.
/particles/heretic_ascension/void/snowfall
	icon_state = list("void_flake" = 3, "void_mote" = 1)
	count = HERETIC_VFX_MAX_PARTICLES
	spawning = 0.6
	velocity = generator("box", list(-0.15, -0.6, 0), list(0.15, -0.3, 0))
	gravity = list(0, -0.02)
	friction = 0
	drift = generator("box", list(-0.06, 0, 0), list(0.06, 0, 0))
	lifespan = 2.5 SECONDS
	fade = 0.8 SECONDS
	fadein = 0.4 SECONDS

/// Пустота: иней, сорванный с отклонённого снаряда или отброшенного врага.
/particles/heretic_ascension/void/frost
	count = 10
	spawning = 10
	friction = 0.12
	gravity = list(0, -0.05)
	lifespan = 0.7 SECONDS
	fade = 0.35 SECONDS
	fadein = 0

#undef HERETIC_VOID_INK
#undef HERETIC_VOID_MOTE_RATE
#undef HERETIC_VOID_MOTE_SPIN
#undef HERETIC_VOID_MOTE_SEGMENTS
#undef HERETIC_VOID_DEFLECT_OFFSET
#undef HERETIC_VOID_DEFLECT_RADIUS
#undef HERETIC_VOID_DEFLECT_TIME
#undef HERETIC_VOID_FROST_TIME
#undef HERETIC_VOID_FLASH_RANGE
#undef HERETIC_VOID_FLASH_POWER
#undef HERETIC_VOID_FLASH_TIME
#undef HERETIC_VOID_DEFLECT_THROTTLE
#undef HERETIC_VOID_FROST_SIZE
#undef HERETIC_VOID_FX_ICON
#undef HERETIC_VOID_LARGE_ICON
#undef HERETIC_VOID_LARGE_OFFSET
#undef HERETIC_VOID_CHILL_FADE
#undef HERETIC_VOID_BALL_FADE
#undef HERETIC_VOID_PRISON_CHECK
#undef HERETIC_VOID_SEAL_SOUND
#undef HERETIC_VOID_BREAK_SOUND
#undef HERETIC_VOID_GATHER_SOUND
#undef HERETIC_VOID_EVENT_VOLUME
#undef HERETIC_VOID_SNOW_RATE
