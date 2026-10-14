#define HERETIC_FLESH_STITCH_DAMAGE 15
#define HERETIC_FLESH_STITCH_HEALING 15
#define HERETIC_FLESH_STITCH_STEPS 2
#define HERETIC_FLESHLING_COST 2
#define HERETIC_FLESHLING_LIFETIME (90 SECONDS)
#define HERETIC_FLESHLING_LEASH 9
#define HERETIC_FLESHLING_STEP_DELAY (0.4 SECONDS)
#define HERETIC_FLESHLING_PATH_DELAY (1 SECONDS)
#define HERETIC_FLESHLING_PATH_LIMIT 12
#define HERETIC_FLESHLING_KNIT_TIME (1.2 SECONDS)
#define HERETIC_FLESHLING_KNIT_SHOW (0.7 SECONDS)
#define HERETIC_FLESH_FX_ICON 'modular_bluemoon/icons/obj/heretic_flesh_fx.dmi'
#define HERETIC_FLESH_LARGE_ICON 'modular_bluemoon/icons/obj/heretic_flesh_effects.dmi'
#define HERETIC_FLESH_LARGE_OFFSET -16
#define HERETIC_FLESH_LATCH_CHECK (0.5 SECONDS)
#define HERETIC_FLESH_LATCH_FADE (0.3 SECONDS)
#define HERETIC_FLESH_LUNGE_TIME (0.15 SECONDS)
#define HERETIC_FLESH_BEAM_TIME (0.8 SECONDS)
#define HERETIC_FLESH_EVENT_VOLUME 50
#define HERETIC_FLESH_QUIET_VOLUME 35
#define HERETIC_FLESH_PUPPET_STEP (0.5 SECONDS)
#define HERETIC_FLESH_PUPPET_ATTACK (1.5 SECONDS)
#define HERETIC_FLESH_PUPPET_FOLLOW 2
#define HERETIC_FLESH_PUPPET_REACH 7
#define HERETIC_FLESH_REACH_SOUND 'modular_bluemoon/sound/heretic/flesh_stitch_1.ogg'
#define HERETIC_FLESH_TEAR_SOUND 'modular_bluemoon/sound/heretic/flesh_latch_tear.ogg'
#define HERETIC_FLESH_RISE_SOUND 'modular_bluemoon/sound/heretic/flesh_rise.ogg'
#define HERETIC_FLESH_KNIT_SOUND 'modular_bluemoon/sound/heretic/flesh_knit.ogg'
#define HERETIC_FLESH_EXCISE_SOUND 'modular_bluemoon/sound/heretic/flesh_excise.ogg'
#define HERETIC_FLESH_SHIFT_UNRAVEL_SOUND 'modular_bluemoon/sound/heretic/flesh_shift_unravel.ogg'
#define HERETIC_FLESH_SHIFT_KNIT_SOUND 'modular_bluemoon/sound/heretic/flesh_shift_knit.ogg'
#define HERETIC_FLESH_SHIFT_VOLUME 55
#define TRAIT_HERETIC_FLESH_LATCHING "heretic_flesh_latching"

/datum/eldritch_knowledge/base_flesh
	var/mob/living/simple_animal/heretic_fleshling/fleshling
	var/list/datum/status_effect/heretic_flesh_latch/latches = list()

/datum/eldritch_knowledge/base_flesh/Destroy()
	QDEL_NULL(fleshling)
	for(var/datum/status_effect/heretic_flesh_latch/latch as anything in latches.Copy())
		qdel(latch)
	return ..()

/datum/eldritch_knowledge/base_flesh/proc/grow_fleshling(mob/living/user, obj/item/organ/organ)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/eldritch_knowledge/command_knowledge = heretic?.get_knowledge(/datum/eldritch_knowledge/flesh_grasp) || heretic?.get_knowledge(/datum/eldritch_knowledge/flesh_ghoul)
	if(QDELETED(organ) || !isturf(organ.loc) || !user.Adjacent(organ) || user.incapacitated() || !heretic || heretic.role_removed || heretic.selected_path != PATH_FLESH || heretic.get_knowledge(type) != src || QDELETED(command_knowledge))
		return FALSE
	if(!QDELETED(fleshling) || !heretic.can_add_servant() || combat_resource < HERETIC_FLESHLING_COST)
		to_chat(user, span_warning("Нужны две биомассы и свободное место в свите. Можно удерживать только одного сшитого ползуна."))
		return FALSE
	if(!spend_combat_resource(HERETIC_FLESHLING_COST))
		return FALSE
	var/turf/place = get_turf(organ)
	fleshling = new(place, heretic, command_knowledge)
	fleshling.mind_initialize()
	var/datum/antagonist/heretic_monster/servant = new
	servant.set_master(heretic)
	fleshling.mind.add_antag_datum(servant)
	if(QDELETED(fleshling))
		return FALSE
	RegisterSignal(fleshling, COMSIG_PARENT_QDELETING, PROC_REF(on_fleshling_deleted))
	track_flesh_servant(servant)
	START_PROCESSING(SSfastprocess, fleshling)
	qdel(organ)
	new /obj/effect/temp_visual/heretic_flesh_knit(place)
	fleshling.alpha = 0
	animate(fleshling, alpha = 0, time = HERETIC_FLESHLING_KNIT_SHOW)
	animate(alpha = 255, time = HERETIC_FLESHLING_KNIT_TIME - HERETIC_FLESHLING_KNIT_SHOW, easing = SINE_EASING | EASE_OUT)
	playsound(place, HERETIC_FLESH_KNIT_SOUND, HERETIC_FLESH_EVENT_VOLUME, TRUE)
	user.visible_message(span_warning("[user] вытягивает из органа сухожилия: они сплетаются в лапы, и сшитый ползун поднимается."))
	return TRUE

/datum/eldritch_knowledge/base_flesh/proc/on_fleshling_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	fleshling = null

/datum/eldritch_knowledge/base_flesh/pocket_exits(mob/living/user)
	. = list()
	for(var/mob/living/servant as anything in door_servants(user))
		heretic_add_pocket_exit(., "Слуга - [servant.real_name]", heretic_pocket_landing(get_turf(servant)))

/datum/eldritch_knowledge/base_flesh/pocket_door(mob/living/user, mob/living/victim)
	var/mob/living/servant = door_servant(user, victim)
	if(!servant)
		return null
	return list("name" = "через слугу", "text" = "[servant] вцепляется в [victim] и тянет за собой сквозь завесу.", "time" = HERETIC_FLESH_DOOR_TIME, "check" = CALLBACK(src, PROC_REF(door_holds), user, victim), "remote" = TRUE)

/datum/eldritch_knowledge/base_flesh/proc/door_holds(mob/living/user, mob/living/victim)
	return !!door_servant(user, victim)

/// Слуга в сознании, не скованный и не оглушённый, рядом с готовой целью; еретик не дальше HERETIC_FLESH_DOOR_RANGE клеток на том же уровне.
/datum/eldritch_knowledge/base_flesh/proc/door_servant(mob/living/user, mob/living/victim)
	if(!door_user_ready(user) || QDELETED(victim) || !isturf(victim.loc) || victim.z != user.z || get_dist(user, victim) > HERETIC_FLESH_DOOR_RANGE)
		return null
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic.hunt_target_ready(victim))
		return null
	for(var/mob/living/servant as anything in door_servants(user))
		if(servant.stat == CONSCIOUS && !servant.incapacitated() && servant.z == victim.z && get_dist(servant, victim) <= 1)
			return servant
	return null

/// Живые гули, Безмолвные мертвецы и ползун еретика на полу.
/datum/eldritch_knowledge/base_flesh/proc/door_servants(mob/living/user)
	. = list()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	for(var/knowledge_type in heretic.researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = heretic.researched_knowledge[knowledge_type]
		for(var/datum/antagonist/heretic_monster/monster as anything in knowledge.flesh_servants)
			var/mob/living/body = monster.owner?.current
			if(QDELETED(body) || body.stat == DEAD || !isturf(body.loc))
				continue
			if(body == fleshling || istype(monster, /datum/antagonist/heretic_monster/ghoul) || istype(monster, /datum/antagonist/heretic_monster/voiceless_dead))
				. |= body

/// Ближайший свой гуль, мертвец или ползун не дальше HERETIC_FLESH_LATCH_REACH клеток от цели, которому ничто не мешает броситься.
/datum/eldritch_knowledge/base_flesh/proc/latch_servant(mob/living/user, mob/living/victim)
	var/best_distance = INFINITY
	for(var/mob/living/servant as anything in door_servants(user))
		if(!servant_can_latch(servant, victim))
			continue
		var/distance = get_dist(servant, victim)
		if(distance < best_distance)
			. = servant
			best_distance = distance

/datum/eldritch_knowledge/base_flesh/proc/servant_can_latch(mob/living/servant, mob/living/victim)
	if(QDELETED(servant) || QDELETED(victim) || servant.stat != CONSCIOUS || servant.incapacitated() || HAS_TRAIT(servant, TRAIT_HERETIC_FLESH_LATCHING) || !isturf(servant.loc) || !isturf(victim.loc) || servant.z != victim.z)
		return FALSE
	var/distance = get_dist(servant, victim)
	return distance <= 1 || (distance <= HERETIC_FLESH_LATCH_REACH && heretic_edge_line_clear(servant, victim) && !!latch_landing(servant, victim))

/// Свободная клетка рядом с целью, ближайшая к слуге: туда он прыгает, чтобы вцепиться.
/datum/eldritch_knowledge/base_flesh/proc/latch_landing(mob/living/servant, mob/living/victim)
	var/best_distance = INFINITY
	for(var/turf/open/spot in orange(1, victim))
		if(!heretic_tile_passable(spot) || !heretic_step_open(spot, get_turf(victim)))
			continue
		var/occupied = FALSE
		for(var/mob/living/other in spot)
			if(other != servant && other.density)
				occupied = TRUE
				break
		if(occupied)
			continue
		var/distance = get_dist(servant, spot)
		if(distance < best_distance)
			. = spot
			best_distance = distance

/// Касание безумия сбило цель: ближайший слуга выбрасывает к ней жилы и через миг вцепляется.
/datum/eldritch_knowledge/base_flesh/proc/start_latch(mob/living/user, mob/living/victim)
	if(QDELETED(victim) || victim.stat == DEAD)
		return FALSE
	var/reason = heretic_capture_block_reason(user, victim, HERETIC_FLESH_CAPTURE)
	if(!reason && victim.has_status_effect(/datum/status_effect/heretic_flesh_latch))
		reason = "Цель уже держат."
	if(reason)
		to_chat(user, span_warning("Слуга не вцепится: [reason]"))
		return FALSE
	var/mob/living/servant = latch_servant(user, victim)
	if(!servant)
		to_chat(user, span_warning("В [HERETIC_FLESH_LATCH_REACH] клетках от [victim] нет вашего свободного слуги: держать цель некому."))
		return FALSE
	ADD_TRAIT(servant, TRAIT_HERETIC_FLESH_LATCHING, REF(victim))
	servant.face_atom(victim)
	servant.Beam(victim, icon_state = "tendon", icon = HERETIC_FLESH_FX_ICON, time = HERETIC_FLESH_LATCH_TELEGRAPH, maxdistance = HERETIC_FLESH_LATCH_REACH + 2)
	servant.visible_message(span_danger("[servant] выбрасывает к [victim] пучок сухожилий!"))
	playsound(servant, HERETIC_FLESH_REACH_SOUND, HERETIC_FLESH_QUIET_VOLUME, TRUE)
	addtimer(CALLBACK(src, PROC_REF(seal_latch), user, victim, servant), HERETIC_FLESH_LATCH_TELEGRAPH)
	return TRUE

/datum/eldritch_knowledge/base_flesh/proc/seal_latch(mob/living/user, mob/living/victim, mob/living/servant)
	if(!QDELETED(servant))
		REMOVE_TRAIT(servant, TRAIT_HERETIC_FLESH_LATCHING, REF(victim))
	if(QDELETED(src) || QDELETED(user))
		return FALSE
	var/reason = latch_failure_reason(user, victim, servant)
	if(reason)
		refund_latch(user, reason)
		return FALSE
	lunge(servant, victim)
	if(!victim.apply_status_effect(/datum/status_effect/heretic_flesh_latch, src, user, servant))
		return FALSE
	log_combat(user, victim, "держит через слугу [key_name(servant)]")
	return TRUE

/datum/eldritch_knowledge/base_flesh/proc/latch_failure_reason(mob/living/user, mob/living/victim, mob/living/servant)
	if(QDELETED(victim) || !isturf(victim.loc))
		return "Цель ускользнула от сухожилий."
	var/reason = heretic_capture_block_reason(user, victim, HERETIC_FLESH_CAPTURE)
	if(reason)
		return "Слуга не вцепился: [reason]"
	if(victim.has_status_effect(/datum/status_effect/heretic_flesh_latch))
		return "Цель уже держат."
	if(!(servant in door_servants(user)) || !servant_can_latch(servant, victim))
		return "Слуга не дотянулся: его сбили, сковали или увели."
	return null

/// Касание уже свалило цель, поэтому сорванная хватка возвращает перезарядку не целиком.
/datum/eldritch_knowledge/base_flesh/proc/refund_latch(mob/living/user, reason)
	for(var/obj/effect/proc_holder/spell/targeted/touch/mad_touch/madness in user?.mind?.spell_list)
		madness.charge_counter = max(madness.charge_counter, madness.charge_max - HERETIC_FLESH_LATCH_RETRY)
		madness.action?.UpdateButtons()
		to_chat(user, span_warning("[reason] Касание вернётся через [DisplayTimeText(madness.charge_max - madness.charge_counter)]."))
		return TRUE
	to_chat(user, span_warning(reason))
	return FALSE

/datum/eldritch_knowledge/base_flesh/proc/lunge(mob/living/servant, mob/living/victim)
	servant.face_atom(victim)
	if(get_dist(servant, victim) <= 1)
		return
	var/turf/origin = get_turf(servant)
	var/turf/landing = latch_landing(servant, victim)
	if(!landing)
		return
	servant.forceMove(landing)
	servant.face_atom(victim)
	servant.pixel_x = servant.base_pixel_x + (origin.x - landing.x) * world.icon_size
	servant.pixel_y = servant.base_pixel_y + (origin.y - landing.y) * world.icon_size
	animate(servant, pixel_x = servant.base_pixel_x, pixel_y = servant.base_pixel_y, time = HERETIC_FLESH_LUNGE_TIME, easing = QUAD_EASING | EASE_IN)

/datum/eldritch_knowledge/base_flesh/proc/holds_latch(mob/living/victim)
	var/datum/status_effect/heretic_flesh_latch/latch = victim?.has_status_effect(/datum/status_effect/heretic_flesh_latch)
	return latch?.knowledge_ref?.resolve() == src

/// Вязание плоти: хватка на «Разоружении» вскрывает труп и вынимает один орган; второй раз тело не откроется.
/datum/eldritch_knowledge/base_flesh/proc/excise_organ(mob/living/user, mob/living/carbon/human/corpse)
	if(corpse.heretic_flesh_excised)
		grasp_failure_reason = "Это тело уже вскрыто: Мансус взял из него своё."
		return FALSE
	if(!length(excisable_organs(corpse)))
		grasp_failure_reason = "В этом теле не осталось органов, которые можно вынуть."
		return FALSE
	user.visible_message(span_danger("[user] запускает руку в грудь [corpse], и плоть расходится по швам."), span_notice("Вы вскрываете [corpse]. Не отходите [DisplayTimeText(HERETIC_FLESH_EXCISE_TIME)]."))
	playsound(corpse, HERETIC_FLESH_EXCISE_SOUND, HERETIC_FLESH_QUIET_VOLUME, TRUE, SILENCED_SOUND_EXTRARANGE)
	if(!do_after(user, HERETIC_FLESH_EXCISE_TIME, corpse, extra_checks = CALLBACK(src, PROC_REF(excision_holds), corpse)))
		grasp_failure_reason = "Вскрытие сорвалось."
		return FALSE
	var/list/organs = excisable_organs(corpse)
	if(!length(organs) || corpse.heretic_flesh_excised)
		return FALSE
	var/turf/place = get_turf(corpse)
	var/obj/item/organ/organ = pick(organs)
	organ.Remove()
	organ.forceMove(place)
	corpse.heretic_flesh_excised = TRUE
	corpse.AddElement(/datum/element/heretic_flesh_excised)
	corpse.add_splatter_floor(place)
	heretic_vfx_burst(corpse, /particles/heretic_ascension/flesh/excise, glow = FALSE)
	user.visible_message(span_danger("[user] вынимает из [corpse] [organ.name], а края раны стягиваются жилами."), span_notice("Вы вынимаете [organ.name]. Тело больше ничего не даст."))
	log_game("[key_name(user)] вскрывает труп [key_name(corpse)] хваткой Плоти и вынимает [organ.type] в [AREACOORD(place)].")
	return TRUE

/datum/eldritch_knowledge/base_flesh/proc/excision_holds(mob/living/carbon/human/corpse)
	return !QDELETED(corpse) && corpse.stat == DEAD && !corpse.heretic_flesh_excised

/datum/eldritch_knowledge/base_flesh/proc/excisable_organs(mob/living/carbon/human/corpse)
	. = list()
	for(var/obj/item/organ/organ as anything in corpse.internal_organs)
		if(organ.organ_flags & (ORGAN_VITAL | ORGAN_SYNTHETIC))
			continue
		. += organ

/mob/living/carbon/human
	var/heretic_flesh_excised = FALSE

/// Улика вскрытия: экипаж видит грудь, стянутую жилами вместо швов.
/datum/element/heretic_flesh_excised
	element_flags = ELEMENT_DETACH

/datum/element/heretic_flesh_excised/Attach(datum/target)
	. = ..()
	if(!ishuman(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/element/heretic_flesh_excised/Detach(datum/source, ...)
	UnregisterSignal(source, COMSIG_PARENT_EXAMINE)
	return ..()

/datum/element/heretic_flesh_excised/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Грудь вскрыта без инструмента: края раны стянуты живыми жилами, а одного органа внутри нет.")

/// Тело поднятого слуги бьётся в судорогах, хрустит и делает первый вдох.
/proc/heretic_flesh_rise_fx(mob/living/body, corpse_look)
	if(QDELETED(body) || !isturf(body.loc))
		return
	if(corpse_look)
		new /obj/effect/temp_visual/heretic_flesh_husk/rise(body.loc, corpse_look)
	heretic_vfx_burst(body, /particles/heretic_ascension/flesh/rise, glow = FALSE)
	playsound(body, HERETIC_FLESH_RISE_SOUND, HERETIC_FLESH_EVENT_VOLUME, TRUE)

/// Тело без души: голод Мансуса водит его за хозяином и бросает на его врагов.
/proc/heretic_flesh_make_puppet(mob/living/body, datum/antagonist/heretic/master)
	if(QDELETED(body) || !master)
		return null
	return body.AddComponent(/datum/component/heretic_flesh_puppet, master)

/datum/component/heretic_flesh_puppet
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/weakref/master_ref
	var/datum/weakref/prey_ref
	var/datum/weakref/guarded_ref
	var/list/movement_path = list()
	var/pathfinding = FALSE
	COOLDOWN_DECLARE(attack_cooldown)
	COOLDOWN_DECLARE(step_cooldown)
	COOLDOWN_DECLARE(path_cooldown)

/datum/component/heretic_flesh_puppet/Initialize(datum/antagonist/heretic/master)
	if(!isliving(parent) || !istype(master))
		return COMPONENT_INCOMPATIBLE
	master_ref = WEAKREF(master)
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	START_PROCESSING(SSfastprocess, src)

/datum/component/heretic_flesh_puppet/Destroy(force, silent)
	STOP_PROCESSING(SSfastprocess, src)
	unguard()
	if(parent)
		UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)
	master_ref = null
	prey_ref = null
	movement_path = null
	return ..()

/datum/component/heretic_flesh_puppet/proc/master_body()
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	return master?.owner?.current

/datum/component/heretic_flesh_puppet/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_warning("Взгляд пустой: телом движет чужой голод, а не душа.")
	if(user == master_body())
		examine_list += span_notice("Пустой слуга идёт за вами, бьёт цель Живого шва и тех, кто ранит вас; Касание безумия рядом с ним заставит его вцепиться.")

/// Слуга бросается на того, кто ранит хозяина.
/datum/component/heretic_flesh_puppet/proc/guard(mob/living/user)
	var/mob/living/guarded = guarded_ref?.resolve()
	if(guarded == user)
		return
	unguard()
	if(QDELETED(user))
		return
	guarded_ref = WEAKREF(user)
	RegisterSignal(user, COMSIG_LIVING_ATTACKER_SET, PROC_REF(on_master_attacked))

/datum/component/heretic_flesh_puppet/proc/unguard()
	var/mob/living/guarded = guarded_ref?.resolve()
	if(guarded)
		UnregisterSignal(guarded, COMSIG_LIVING_ATTACKER_SET)
	guarded_ref = null

/datum/component/heretic_flesh_puppet/proc/on_master_attacked(mob/living/source, mob/living/attacker)
	SIGNAL_HANDLER
	if(isliving(attacker) && !prey_ref?.resolve())
		command_prey(source, attacker)

/datum/component/heretic_flesh_puppet/proc/command_prey(mob/living/user, mob/living/victim)
	if(user != master_body() || !prey_valid(user, victim))
		return FALSE
	prey_ref = WEAKREF(victim)
	movement_path.Cut()
	return TRUE

/datum/component/heretic_flesh_puppet/proc/prey_valid(mob/living/user, mob/living/victim)
	return isturf(victim?.loc) && victim.z == user?.z && get_dist(user, victim) <= HERETIC_FLESH_PUPPET_REACH && heretic_can_affect(user, victim, chargecost = 0, notify = FALSE)

/datum/component/heretic_flesh_puppet/process()
	var/mob/living/body = parent
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(body)
	if(QDELETED(body) || body.stat == DEAD || !master || master.role_removed || servant?.master != master)
		qdel(src)
		return
	var/mob/living/user = master.owner?.current
	guard(user)
	if(body.client || QDELETED(user) || !isturf(body.loc) || !isturf(user.loc) || user.z != body.z || body.incapacitated() || HAS_TRAIT(body, TRAIT_HERETIC_FLESH_LATCHING))
		return
	var/mob/living/prey = prey_ref?.resolve()
	if(prey && !prey_valid(user, prey))
		prey_ref = null
		prey = null
		movement_path.Cut()
	if(prey && body.Adjacent(prey))
		if(COOLDOWN_FINISHED(src, attack_cooldown))
			COOLDOWN_START(src, attack_cooldown, HERETIC_FLESH_PUPPET_ATTACK)
			strike(body, prey)
		return
	if((!prey && get_dist(body, user) <= HERETIC_FLESH_PUPPET_FOLLOW) || body.anchored || body.buckled || body.pulledby || !COOLDOWN_FINISHED(src, step_cooldown))
		return
	var/atom/destination = prey || user
	if(!pathfinding && COOLDOWN_FINISHED(src, path_cooldown))
		pathfinding = TRUE
		COOLDOWN_START(src, path_cooldown, HERETIC_FLESHLING_PATH_DELAY)
		INVOKE_ASYNC(src, PROC_REF(plan_path), destination)
	if(!length(movement_path))
		return
	var/turf/next_step = movement_path[1]
	if(get_dist(body, next_step) != 1 || body.z != next_step.z)
		movement_path.Cut()
		return
	COOLDOWN_START(src, step_cooldown, HERETIC_FLESH_PUPPET_STEP)
	if(step_towards(body, next_step) && get_turf(body) == next_step)
		movement_path.Cut(1, 2)
	else
		movement_path.Cut()

/datum/component/heretic_flesh_puppet/proc/plan_path(atom/destination)
	var/mob/living/body = parent
	var/turf/origin = get_turf(body)
	var/list/new_path = get_path_to(body, destination, HERETIC_FLESHLING_PATH_LIMIT, 1, cancel_source = body)
	if(QDELETED(src))
		return
	pathfinding = FALSE
	if(QDELETED(body) || body.loc != origin || QDELETED(destination) || (prey_ref?.resolve() || master_body()) != destination)
		return
	movement_path = new_path

/datum/component/heretic_flesh_puppet/proc/strike(mob/living/body, mob/living/prey)
	body.face_atom(prey)
	var/health_before = prey.health
	if(isanimal(body))
		prey.attack_animal(body)
	else
		body.UnarmedAttack(prey, TRUE, INTENT_HARM)
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(!QDELETED(prey) && prey.health < health_before)
		master?.advance_combat_deed(prey, PATH_FLESH)

/// Живой шов: всем пустым слугам и ползуну - одна цель.
/datum/eldritch_knowledge/base_flesh/proc/command_servants(mob/living/user, mob/living/victim)
	fleshling?.command_prey(user, victim)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!heretic)
		return
	for(var/knowledge_type in heretic.researched_knowledge)
		var/datum/eldritch_knowledge/knowledge = heretic.researched_knowledge[knowledge_type]
		for(var/datum/antagonist/heretic_monster/monster as anything in knowledge.flesh_servants)
			var/datum/component/heretic_flesh_puppet/puppet = monster.owner?.current?.GetComponent(/datum/component/heretic_flesh_puppet)
			puppet?.command_prey(user, victim)

/mob/living/simple_animal/heretic_fleshling
	name = "stitched crawler"
	desc = "Паук из сшитых органов на тонких сухожильных лапах. Живёт полторы минуты и слушается указаний хозяина через Живой шов. Хозяин может коснуться его на помощи, чтобы вернуть к себе, или на разоружении, чтобы оставить ждать. Живой шов за биомассу обновляет срок жизни до полутора минут. Дальше девяти клеток от хозяина распадается."
	icon = 'modular_bluemoon/icons/mob/heretic_flesh_mobs.dmi'
	icon_state = "crawler"
	icon_living = "crawler"
	health = 40
	maxHealth = 40
	melee_damage_lower = 6
	melee_damage_upper = 6
	attack_verb_continuous = "терзает"
	attack_verb_simple = "терзает"
	attack_sound = 'sound/effects/wounds/blood1.ogg'
	faction = list("heretics")
	wander = FALSE
	del_on_death = TRUE
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	var/datum/weakref/master_ref
	var/datum/weakref/prey_ref
	var/datum/weakref/knowledge_ref
	var/list/movement_path = list()
	var/pathfinding = FALSE
	var/expires_at
	var/holding_position = FALSE
	COOLDOWN_DECLARE(attack_cooldown)
	COOLDOWN_DECLARE(step_cooldown)
	COOLDOWN_DECLARE(path_cooldown)

/mob/living/simple_animal/heretic_fleshling/Initialize(mapload, datum/antagonist/heretic/master, datum/eldritch_knowledge/required)
	. = ..()
	if(QDELETED(master) || QDELETED(required))
		return INITIALIZE_HINT_QDEL
	master_ref = WEAKREF(master)
	knowledge_ref = WEAKREF(required)
	RegisterSignal(required, COMSIG_PARENT_QDELETING, PROC_REF(on_knowledge_deleted))
	expires_at = world.time + HERETIC_FLESHLING_LIFETIME

/mob/living/simple_animal/heretic_fleshling/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	if(required)
		UnregisterSignal(required, COMSIG_PARENT_QDELETING)
	if(isturf(loc))
		new /obj/effect/temp_visual/heretic_flesh_unravel(loc)
	master_ref = null
	prey_ref = null
	knowledge_ref = null
	movement_path = null
	return ..()

/mob/living/simple_animal/heretic_fleshling/proc/on_knowledge_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/mob/living/simple_animal/heretic_fleshling/proc/command_prey(mob/living/user, mob/living/victim)
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(master?.owner?.current != user || !isturf(user.loc) || !isturf(victim?.loc) || user.incapacitated() || !heretic_can_affect(user, victim, chargecost = 0) || get_dist(user, victim) > 5 || user.z != victim.z || !can_see(user, victim, 5))
		return FALSE
	prey_ref = WEAKREF(victim)
	holding_position = FALSE
	movement_path.Cut()
	return TRUE

/mob/living/simple_animal/heretic_fleshling/examine(mob/user)
	. = ..()
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(master?.owner?.current == user)
		. += span_notice("Приказ: [holding_position ? "ждать на месте" : prey_ref?.resolve() ? "преследовать цель" : "следовать за вами"]. До распада: [DisplayTimeText(max(0, expires_at - world.time))]. Касание в «Помощи» зовёт его за вами, в «Разоружении» велит ждать. Живой шов продлевает ему жизнь и даёт новую цель, а Касание безумия рядом с ним заставит его вцепиться.")

/mob/living/simple_animal/heretic_fleshling/attack_hand(mob/living/carbon/human/user)
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(master?.owner?.current == user && (user.a_intent in list(INTENT_HELP, INTENT_DISARM)) && !user.incapacitated() && user.Adjacent(src))
		prey_ref = null
		holding_position = user.a_intent == INTENT_DISARM
		movement_path.Cut()
		to_chat(user, span_notice((holding_position ? "Ползун остаётся ждать здесь. Живой шов по врагу отправит его в погоню." : "Ползун прекращает преследование и возвращается к вам.")))
		return
	return ..()

/mob/living/simple_animal/heretic_fleshling/process()
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	var/mob/living/user = master?.owner?.current
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(src)
	var/datum/eldritch_knowledge/required = knowledge_ref?.resolve()
	var/turf/master_turf = get_turf(user)
	var/turf/crawler_turf = get_turf(src)
	if(QDELETED(user) || QDELETED(required) || !master_turf || !crawler_turf || master.role_removed || master.get_knowledge(required.type) != required || user.stat == DEAD || stat == DEAD || servant?.master != master || world.time >= expires_at || master_turf.z != crawler_turf.z || get_dist(master_turf, crawler_turf) > HERETIC_FLESHLING_LEASH)
		qdel(src)
		return
	if(client || !isturf(loc) || !isturf(user.loc) || incapacitated() || user.incapacitated() || !CHECK_MOBILITY(src, MOBILITY_USE) || HAS_TRAIT(src, TRAIT_HERETIC_FLESH_LATCHING))
		return
	var/mob/living/prey = prey_ref?.resolve()
	if(!isturf(prey?.loc) || !heretic_can_affect(user, prey, chargecost = 0) || prey.z != user.z || get_dist(user, prey) > 5 || !can_see(user, prey, 5))
		if(prey_ref)
			movement_path.Cut()
		prey_ref = null
		prey = null
	if(holding_position)
		return
	if(prey && Adjacent(prey))
		if(COOLDOWN_FINISHED(src, attack_cooldown) && heretic_can_affect(user, prey))
			COOLDOWN_START(src, attack_cooldown, 2 SECONDS)
			var/health_before = prey.health
			prey.attack_animal(src)
			if(!QDELETED(prey) && prey.health < health_before)
				master?.advance_combat_deed(prey, PATH_FLESH)
		return
	var/atom/destination = prey || user
	if(Adjacent(destination) || anchored || buckled || pulledby || !CHECK_MULTIPLE_BITFIELDS(mobility_flags, MOBILITY_STAND | MOBILITY_MOVE) || !COOLDOWN_FINISHED(src, step_cooldown))
		return
	if(!pathfinding && COOLDOWN_FINISHED(src, path_cooldown))
		pathfinding = TRUE
		COOLDOWN_START(src, path_cooldown, HERETIC_FLESHLING_PATH_DELAY)
		INVOKE_ASYNC(src, PROC_REF(plan_path), destination)
	if(!length(movement_path))
		return
	var/turf/next_step = movement_path[1]
	if(get_dist(src, next_step) != 1 || z != next_step.z)
		movement_path.Cut()
		return
	COOLDOWN_START(src, step_cooldown, HERETIC_FLESHLING_STEP_DELAY)
	if(step_towards(src, next_step) && get_turf(src) == next_step)
		movement_path.Cut(1, 2)
	else
		movement_path.Cut()

/mob/living/simple_animal/heretic_fleshling/proc/plan_path(atom/destination)
	var/turf/origin = get_turf(src)
	var/list/new_path = get_path_to(src, destination, HERETIC_FLESHLING_PATH_LIMIT, 1, cancel_source = src)
	if(QDELETED(src))
		return
	pathfinding = FALSE
	var/datum/antagonist/heretic/master = master_ref?.resolve()
	if(loc != origin || QDELETED(destination) || (prey_ref?.resolve() || master?.owner?.current) != destination)
		return
	movement_path = new_path

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch
	name = "Живой шов"
	desc = "Протяните сухожилие на 5 клеток: враг получает 15 ушибов и замедление, а ползун и пустые слуги бросаются на него. Свой слуга за 1 биомассу лечится и подтягивается к вам."
	summary = "Удар врагу на 5 клеток или лечение своего слуги за биомассу."
	clothes_req = FALSE
	charge_max = 15 SECONDS
	range = 5
	invocation = "S'UT'RE"
	invocation_type = "whisper"
	action_icon = HERETIC_FLESH_FX_ICON
	action_icon_state = "flesh_stitch"
	action_background_icon_state = "bg_ecult"

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/proc/valid_user(mob/living/user)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	return !QDELETED(src) && isliving(user) && heretic && !heretic.role_removed && heretic.selected_path == PATH_FLESH && heretic.owner?.current == user && user.stat == CONSCIOUS && !user.incapacitated() && heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh) && heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/can_cast(mob/user, skipcharge, silent)
	return ..() && heretic_check(user, valid_user(user), silent, "Способность недоступна вашему пути или текущему телу.")

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/can_target(atom/target, mob/user, silent)
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	if(!valid_user(user) || !isliving(target) || QDELETED(target) || target == user || !isturf(user.loc) || !isturf(target.loc))
		return heretic_check(user, FALSE, silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")
	var/mob/living/victim = target
	if(victim.stat == DEAD || user.z != victim.z || get_dist(user, victim) > range)
		return heretic_check(user, FALSE, silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")
	var/turf/previous
	for(var/turf/tile as anything in get_line(user, victim))
		if(!isopenturf(tile) || tile.is_blocked_turf(exclude_mobs = TRUE))
			return heretic_check(user, FALSE, silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")
		if(previous && previous.x != tile.x && previous.y != tile.y)
			var/turf/side_horizontal = locate(previous.x, tile.y, tile.z)
			var/turf/side_vertical = locate(tile.x, previous.y, tile.z)
			if(!isopenturf(side_horizontal) || !isopenturf(side_vertical) || side_horizontal.is_blocked_turf(exclude_mobs = TRUE) || side_vertical.is_blocked_turf(exclude_mobs = TRUE))
				return heretic_check(user, FALSE, silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")
		previous = tile
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(victim)
	if(servant?.master == heretic)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		var/needs_healing = victim.getBruteLoss() > 0 || victim.getFireLoss() > 0
		var/mob/living/simple_animal/heretic_fleshling/crawler = victim
		if(istype(crawler) && world.time >= crawler.expires_at)
			return heretic_check(user, FALSE, silent, "Ползун уже распадается: срок его жизни истёк.")
		if(istype(crawler) && crawler.expires_at < world.time + HERETIC_FLESHLING_LIFETIME - 30 SECONDS)
			needs_healing = TRUE
		var/can_reposition = get_dist(user, victim) > 1 && !victim.anchored && !victim.buckled
		return heretic_check(user, path?.combat_resource > 0 && (needs_healing || can_reposition) && !victim.check_magic_resistance(chargecost = 0), silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")
	return heretic_check(user, heretic_can_affect(user, victim, chargecost = 0), silent, "Нужна видимая живая цель без защиты от магии. Слуге шов поможет, если есть биомасса и слуга ранен, стоит дальше клетки от вас или это ползун старше 30 секунд.")

/obj/effect/proc_holder/spell/pointed/heretic_flesh_stitch/cast(list/targets, mob/user)
	if(!length(targets) || !can_target(targets[1], user, TRUE))
		heretic_revert_cast(user)
		return
	var/mob/living/victim = targets[1]
	var/datum/antagonist/heretic/heretic = IS_HERETIC(user)
	var/datum/antagonist/heretic_monster/servant = IS_HERETIC_MONSTER(victim)
	if(servant?.master == heretic)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		if(!path?.spend_combat_resource())
			heretic_revert_cast(user)
			return
		heretic_heal_damage(victim, HERETIC_FLESH_STITCH_HEALING, HERETIC_FLESH_STITCH_HEALING)
		var/mob/living/simple_animal/heretic_fleshling/crawler = victim
		if(istype(crawler))
			crawler.expires_at = world.time + HERETIC_FLESHLING_LIFETIME
			crawler.holding_position = FALSE
			crawler.prey_ref = null
			crawler.movement_path.Cut()
		if(!victim.anchored && !victim.buckled)
			for(var/step_index in 1 to HERETIC_FLESH_STITCH_STEPS)
				if(get_dist(user, victim) <= 1 || !step_towards(victim, user))
					break
		new /obj/effect/temp_visual/heretic_oldpath/flesh/mend(get_turf(victim))
		to_chat(victim, span_notice("Живой шов затягивает ваши раны и тянет к хозяину."))
	else
		if(!heretic_can_affect(user, victim))
			heretic_revert_cast(user, "Цель защищена от магии: шов её не достанет.")
			return
		victim.adjustBruteLoss(HERETIC_FLESH_STITCH_DAMAGE)
		victim.apply_status_effect(/datum/status_effect/heretic_flesh_stitch)
		var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
		path?.command_servants(user, victim)
		new /obj/effect/temp_visual/heretic_oldpath/flesh(get_turf(victim))
		to_chat(victim, span_warning("Сухожилие впивается в вас и стягивает движения!"))
	user.Beam(victim, icon_state = "tendon", icon = HERETIC_FLESH_FX_ICON, time = HERETIC_FLESH_BEAM_TIME)
	playsound(user, pick('modular_bluemoon/sound/heretic/flesh_stitch_1.ogg', 'modular_bluemoon/sound/heretic/flesh_stitch_2.ogg'), 60, TRUE)

/datum/status_effect/heretic_flesh_stitch
	id = "heretic_flesh_stitch"
	duration = 3 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	on_remove_on_mob_delete = TRUE

/datum/status_effect/heretic_flesh_stitch/on_apply()
	. = ..()
	if(!.)
		return FALSE
	owner.add_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch)
	return TRUE

/datum/status_effect/heretic_flesh_stitch/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/heretic_flesh_stitch)
	return ..()

/datum/movespeed_modifier/heretic_flesh_stitch
	multiplicative_slowdown = 1

/// Хватка слуги: цель в сухожилиях не двигается, пока слуга рядом, в сознании и не скован.
/datum/status_effect/heretic_flesh_latch
	id = "heretic_flesh_latch"
	duration = HERETIC_FLESH_LATCH_DURATION
	tick_interval = HERETIC_FLESH_LATCH_CHECK
	status_type = STATUS_EFFECT_UNIQUE
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/heretic_flesh_latch
	examine_text = span_warning("SUBJECTPRONOUN опутан сухожилиями чужого слуги: острое на «Помощи» срежет жилы за 2 секунды, нулевой жезл порвёт их сразу, а ещё можно растолкать за 2 секунды или сбить и оттащить слугу.")
	var/held_since = 0
	var/datum/weakref/knowledge_ref
	var/datum/weakref/master_ref
	var/mob/living/servant
	var/datum/status_effect/incapacitating/paralyzed/heretic_ritual/restraint
	var/datum/beam/sinew
	var/obj/effect/abstract/heretic_vfx_attached/binding

/datum/status_effect/heretic_flesh_latch/on_creation(mob/living/new_owner, datum/eldritch_knowledge/base_flesh/flesh, mob/living/master, mob/living/holder)
	knowledge_ref = WEAKREF(flesh)
	master_ref = WEAKREF(master)
	servant = holder
	return ..()

/datum/status_effect/heretic_flesh_latch/on_apply()
	. = ..()
	if(!.)
		return
	var/datum/eldritch_knowledge/base_flesh/flesh = knowledge_ref?.resolve()
	if(!flesh || QDELETED(servant))
		servant = null
		return FALSE
	flesh.latches += src
	held_since = world.time
	restraint = new(list(owner, HERETIC_FLESH_LATCH_DURATION, TRUE))
	ADD_TRAIT(servant, TRAIT_HERETIC_FLESH_LATCHING, REF(src))
	heretic_capture_hold(owner, HERETIC_FLESH_CAPTURE)
	heretic_capture_lock_pull(owner, servant, REF(src))
	sinew = servant.Beam(owner, icon_state = "tendon", icon = HERETIC_FLESH_FX_ICON, time = HERETIC_FLESH_LATCH_DURATION + HERETIC_FLESH_LATCH_FADE, maxdistance = HERETIC_FLESH_LATCH_REACH)
	binding = heretic_vfx_attach(owner, HERETIC_FLESH_FX_ICON, "latch_bind", fade_in = HERETIC_FLESH_LATCH_FADE, glow = FALSE, upright = FALSE)
	binding?.vis_flags |= VIS_INHERIT_DIR
	RegisterSignal(owner, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(servant, COMSIG_PARENT_ATTACKBY, PROC_REF(on_servant_attackby))
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(servant, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignals(owner, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN), PROC_REF(end_latch))
	RegisterSignals(servant, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_DEATH, COMSIG_MOVABLE_Z_CHANGED), PROC_REF(end_latch))
	owner.visible_message(span_danger("[servant] вцепляется в [owner], и сухожилия намертво стягивают тело!"), span_userdanger("[servant] вцепился в вас: сухожилия стянули руки и ноги!"))

/datum/status_effect/heretic_flesh_latch/tick()
	if(servant_holds())
		return
	owner.visible_message(span_warning("Сухожилия вокруг [owner] обвисают: слуга больше не держит."))
	qdel(src)

/datum/status_effect/heretic_flesh_latch/proc/servant_holds()
	return !QDELETED(servant) && servant.stat == CONSCIOUS && !servant.incapacitated() && isturf(servant.loc) && servant.z == owner.z && get_dist(servant, owner) <= 1

/datum/status_effect/heretic_flesh_latch/proc/end_latch(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/heretic_flesh_latch/proc/on_moved(datum/source)
	SIGNAL_HANDLER
	if(!isturf(owner.loc) || QDELETED(servant) || !isturf(servant.loc) || servant.z != owner.z || get_dist(servant, owner) > 1)
		qdel(src)

/datum/status_effect/heretic_flesh_latch/proc/on_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	if(istype(item, /obj/item/nullrod))
		tear_by_rod(user, source)
		return COMPONENT_NO_AFTERATTACK
	if(user.a_intent == INTENT_HARM || !item.get_sharpness())
		return NONE
	INVOKE_ASYNC(src, PROC_REF(cut_sinews), user, item)
	return COMPONENT_NO_AFTERATTACK

/datum/status_effect/heretic_flesh_latch/proc/on_servant_attackby(mob/living/source, obj/item/item, mob/living/user, params)
	SIGNAL_HANDLER
	if(!istype(item, /obj/item/nullrod) || IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		return NONE
	tear_by_rod(user, source)
	return NONE

/datum/status_effect/heretic_flesh_latch/proc/tear_by_rod(mob/living/user, atom/touched)
	user.visible_message(span_warning("[user] касается [touched] нулевым жезлом, и сухожилия рвутся с мокрым треском."), span_notice("Вы касаетесь [touched] нулевым жезлом, и сухожилия рвутся."))
	log_game("[key_name(user)] рвёт хватку слуги еретика на [key_name(owner)] нулевым жезлом в [AREACOORD(owner)].")
	qdel(src)

/datum/status_effect/heretic_flesh_latch/proc/cut_sinews(mob/living/helper, obj/item/blade)
	if(LAZYFIND(helper.do_afters, owner))
		return FALSE
	helper.visible_message(span_warning("[helper] режет [blade] сухожилия, опутавшие [owner]."), span_notice("Вы срезаете жилы. Не отходите [DisplayTimeText(HERETIC_FLESH_LATCH_CUT_TIME)]."))
	var/mob/living/held = owner
	if(!do_after(helper, HERETIC_FLESH_LATCH_CUT_TIME, held, extra_checks = CALLBACK(src, PROC_REF(cut_holds), helper, blade)))
		return FALSE
	if(QDELETED(src))
		return FALSE
	helper.visible_message(span_notice("[helper] перерезает последнюю жилу, и [held] свободен."))
	log_game("[key_name(helper)] срезает хватку слуги еретика с [key_name(held)] в [AREACOORD(held)].")
	qdel(src)
	return TRUE

/datum/status_effect/heretic_flesh_latch/proc/cut_holds(mob/living/helper, obj/item/blade)
	return !QDELETED(src) && helper.is_holding(blade)

/datum/status_effect/heretic_flesh_latch/on_remove()
	UnregisterSignal(owner, list(COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_Z_CHANGED, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN))
	if(servant)
		UnregisterSignal(servant, list(COMSIG_PARENT_ATTACKBY, COMSIG_MOVABLE_MOVED, COMSIG_PARENT_QDELETING, COMSIG_MOB_DEATH, COMSIG_MOVABLE_Z_CHANGED))
		REMOVE_TRAIT(servant, TRAIT_HERETIC_FLESH_LATCHING, REF(src))
	servant = null
	heretic_capture_unhold(owner, HERETIC_FLESH_CAPTURE)
	heretic_capture_unlock_pull(owner, REF(src))
	// Чужой Paralyze мог продлить этот экземпляр: тогда он остаётся.
	if(!QDELETED(restraint) && restraint.duration <= duration)
		qdel(restraint)
	restraint = null
	QDEL_NULL(sinew)
	binding?.fade_out(HERETIC_FLESH_LATCH_FADE)
	binding = null
	var/datum/eldritch_knowledge/base_flesh/flesh = knowledge_ref?.resolve()
	flesh?.latches -= src
	if(isturf(owner.loc))
		new /obj/effect/temp_visual/heretic_flesh_tear(owner.loc)
		playsound(owner, HERETIC_FLESH_TEAR_SOUND, HERETIC_FLESH_EVENT_VOLUME, TRUE)
	heretic_capture_release(owner, HERETIC_FLESH_CAPTURE, held_for = heretic_capture_held_for(held_since))
	return ..()

/atom/movable/screen/alert/status_effect/heretic_flesh_latch
	name = "Хватка слуги"
	desc = "Слуга еретика вцепился в вас сухожилиями: вы не можете двигаться, пока он рядом. Друзья срежут жилы ножом или другим острым на «Помощи» за 2 секунды, порвут их нулевым жезлом, растолкают вас за 2 секунды, а ещё могут сбить, сковать или оттащить слугу."
	icon = 'modular_bluemoon/icons/obj/heretic_alerts.dmi'
	icon_state = "flesh_latch"

/// Касание безумия: фобия держится 5 минут, повторное касание продлевает её, а не добавляет новую.
/datum/status_effect/heretic_flesh_phobia
	id = "heretic_flesh_phobia"
	duration = HERETIC_FLESH_MADNESS_PHOBIA_TIME
	tick_interval = -1
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	var/datum/brain_trauma/phobia

/datum/status_effect/heretic_flesh_phobia/on_apply()
	. = ..()
	if(!. || !iscarbon(owner))
		return FALSE
	var/mob/living/carbon/victim = owner
	phobia = victim.gain_trauma(/datum/brain_trauma/mild/phobia)
	return !!phobia

/datum/status_effect/heretic_flesh_phobia/refresh()
	. = ..()
	if(QDELETED(phobia) && iscarbon(owner))
		var/mob/living/carbon/victim = owner
		phobia = victim.gain_trauma(/datum/brain_trauma/mild/phobia)

/datum/status_effect/heretic_flesh_phobia/on_remove()
	if(!QDELETED(phobia))
		qdel(phobia)
	phobia = null
	return ..()

/// Узел органа расплетается в сухожильные лапы.
/obj/effect/temp_visual/heretic_flesh_knit
	icon = HERETIC_FLESH_LARGE_ICON
	icon_state = "crawler_knit"
	duration = HERETIC_FLESHLING_KNIT_TIME
	randomdir = FALSE
	pixel_x = HERETIC_FLESH_LARGE_OFFSET
	pixel_y = HERETIC_FLESH_LARGE_OFFSET
	layer = ABOVE_MOB_LAYER

/// Ползун распадается обратно в клубок жил.
/obj/effect/temp_visual/heretic_flesh_unravel
	icon = HERETIC_FLESH_LARGE_ICON
	icon_state = "crawler_unravel"
	duration = 0.8 SECONDS
	randomdir = FALSE
	pixel_x = HERETIC_FLESH_LARGE_OFFSET
	pixel_y = HERETIC_FLESH_LARGE_OFFSET

/datum/sound_effect/heretic_flesh_grasp
	key = HERETIC_FLESH_GRASP_SFX
	file_paths = list(
		'modular_bluemoon/sound/heretic/flesh_grasp_1.ogg',
		'modular_bluemoon/sound/heretic/flesh_grasp_2.ogg',
		'modular_bluemoon/sound/heretic/flesh_grasp_3.ogg',
	)

/// Переход слуг Плоти: тело оседает клубком жил и сшивается заново.
/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh
	heretic_stun_check = TRUE
	usable_while_grabbed = TRUE
	name = "Ползучий переход"
	desc = "Ненадолго распадитесь клубком жил, чтобы проползти сквозь стены. Работает в чужой хватке, но не под оглушением."
	summary = "1,5 секунды ползёте клубком жил сквозь стены, затем 2,5 секунды сшиваетесь на месте."
	school = "transmutation"
	invocation = "ME'SA SLIN'KA"
	invocation_type = "whisper"
	charge_max = 150
	range = -1
	action_icon = 'modular_bluemoon/icons/obj/heretic_actions.dmi'
	action_icon_state = "flesh_shift"
	action_background_icon_state = "bg_ecult"
	jaunt_in_time = 20
	jaunt_duration = 15
	jaunt_in_type = /obj/effect/temp_visual/dir_setting/flesh_shift
	jaunt_out_type = /obj/effect/temp_visual/dir_setting/flesh_shift/unravel

/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh/long
	summary = "7,5 секунды ползёте клубком жил сквозь стены, затем 2,5 секунды сшиваетесь на месте."
	jaunt_duration = 75

/obj/effect/proc_holder/spell/targeted/ethereal_jaunt/shift/flesh/play_sound(type, mob/living/target)
	playsound(target, type == "enter" ? HERETIC_FLESH_SHIFT_UNRAVEL_SOUND : HERETIC_FLESH_SHIFT_KNIT_SOUND, HERETIC_FLESH_SHIFT_VOLUME, TRUE)
	heretic_vfx_burst(target, /particles/heretic_ascension/flesh/rupture, glow = FALSE)

/// Клубок жил поднимается из пола и сшивается в тело слуги.
/obj/effect/temp_visual/dir_setting/flesh_shift
	name = "sinew knot"
	icon = HERETIC_FLESH_FX_ICON
	icon_state = "flesh_shift_knit"
	duration = 20

/// Тело слуги оседает клубком жил и уползает в пол.
/obj/effect/temp_visual/dir_setting/flesh_shift/unravel
	icon_state = "flesh_shift_unravel"
	duration = 12

/// Порванные жилы хлещут в стороны и опадают.
/obj/effect/temp_visual/heretic_flesh_tear
	icon = HERETIC_FLESH_LARGE_ICON
	icon_state = "latch_tear"
	duration = 0.7 SECONDS
	randomdir = FALSE
	pixel_x = HERETIC_FLESH_LARGE_OFFSET
	pixel_y = HERETIC_FLESH_LARGE_OFFSET
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/heretic_flesh_tear/Initialize(mapload)
	. = ..()
	animate(src, alpha = 255, time = duration - HERETIC_FLESH_LATCH_FADE)
	animate(alpha = 0, time = HERETIC_FLESH_LATCH_FADE, easing = SINE_EASING | EASE_IN)

#undef HERETIC_FLESH_STITCH_DAMAGE
#undef HERETIC_FLESH_STITCH_HEALING
#undef HERETIC_FLESH_STITCH_STEPS
#undef HERETIC_FLESHLING_COST
#undef HERETIC_FLESHLING_LIFETIME
#undef HERETIC_FLESHLING_LEASH
#undef HERETIC_FLESHLING_STEP_DELAY
#undef HERETIC_FLESHLING_PATH_DELAY
#undef HERETIC_FLESHLING_PATH_LIMIT
#undef HERETIC_FLESHLING_KNIT_TIME
#undef HERETIC_FLESHLING_KNIT_SHOW
#undef HERETIC_FLESH_FX_ICON
#undef HERETIC_FLESH_LARGE_ICON
#undef HERETIC_FLESH_LARGE_OFFSET
#undef HERETIC_FLESH_LATCH_CHECK
#undef HERETIC_FLESH_LATCH_FADE
#undef HERETIC_FLESH_LUNGE_TIME
#undef HERETIC_FLESH_BEAM_TIME
#undef HERETIC_FLESH_EVENT_VOLUME
#undef HERETIC_FLESH_QUIET_VOLUME
#undef HERETIC_FLESH_PUPPET_STEP
#undef HERETIC_FLESH_PUPPET_ATTACK
#undef HERETIC_FLESH_PUPPET_FOLLOW
#undef HERETIC_FLESH_PUPPET_REACH
#undef HERETIC_FLESH_REACH_SOUND
#undef HERETIC_FLESH_TEAR_SOUND
#undef HERETIC_FLESH_RISE_SOUND
#undef HERETIC_FLESH_KNIT_SOUND
#undef HERETIC_FLESH_EXCISE_SOUND
#undef HERETIC_FLESH_SHIFT_UNRAVEL_SOUND
#undef HERETIC_FLESH_SHIFT_KNIT_SOUND
#undef HERETIC_FLESH_SHIFT_VOLUME
#undef TRAIT_HERETIC_FLESH_LATCHING
