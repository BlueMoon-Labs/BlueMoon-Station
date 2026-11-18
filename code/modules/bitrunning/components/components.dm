// Аватар: временное тело, переносящее урон и слушающее сигналы домена.
/datum/component/avatar_connection
	var/datum/weakref/old_body_ref
	var/datum/weakref/old_mind_ref
	var/datum/weakref/server_ref
	var/datum/weakref/netpod_ref
	var/nohit = TRUE

/datum/component/avatar_connection/Initialize(
	datum/mind/old_mind,
	mob/living/old_body,
	obj/machinery/quantum_server/server,
	obj/machinery/netpod/pod,
	help_text,
	copy_body,
	)

	if(!isliving(parent) || !isliving(old_body) || !old_mind || !server.is_operational || !pod.is_operational)
		return COMPONENT_INCOMPATIBLE

	var/mob/living/avatar = parent

	netpod_ref = WEAKREF(pod)
	old_body_ref = WEAKREF(old_body)
	old_mind_ref = WEAKREF(old_mind)
	pod.avatar_ref = WEAKREF(avatar)
	server_ref = WEAKREF(server)
	server.avatar_connection_refs.Add(WEAKREF(src))

	avatar.PossessByPlayer(old_body.key)
	ADD_TRAIT(avatar, TRAIT_NO_MINDSWAP, REF(src))
	ADD_TRAIT(old_body, TRAIT_MIND_TEMPORARILY_GONE, REF(src))

	RegisterSignals(old_body, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_STATUS_UNCONSCIOUS), PROC_REF(on_sever_connection))
	RegisterSignal(pod, COMSIG_BITRUNNER_CROWBAR_ALERT, PROC_REF(on_netpod_crowbar))
	RegisterSignal(pod, COMSIG_BITRUNNER_NETPOD_INTEGRITY, PROC_REF(on_netpod_damaged))
	RegisterSignal(pod, COMSIG_BITRUNNER_NETPOD_SEVER, PROC_REF(on_sever_connection))
	RegisterSignal(server, COMSIG_BITRUNNER_DOMAIN_COMPLETE, PROC_REF(on_domain_completed))
	RegisterSignal(server, COMSIG_BITRUNNER_QSRV_SEVER, PROC_REF(on_sever_connection))
	RegisterSignal(server, COMSIG_BITRUNNER_SHUTDOWN_ALERT, PROC_REF(on_shutting_down))
	RegisterSignal(server, COMSIG_BITRUNNER_THREAT_CREATED, PROC_REF(on_threat_created))
	RegisterSignal(server, COMSIG_BITRUNNER_STATION_SPAWN, PROC_REF(on_station_spawn))
#ifndef UNIT_TESTS
	RegisterSignal(avatar.mind, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transfer))
#endif

	if(!locate(/datum/action/avatar_domain_info) in avatar.actions)
		var/datum/avatar_help_text/help_datum = new(help_text)
		var/datum/action/avatar_domain_info/action = new(help_datum)
		action.Grant(avatar)

	if(copy_body && ishuman(avatar) && ishuman(old_body))
		var/mob/living/carbon/human/human_avatar = avatar
		var/mob/living/carbon/human/human_old_body = old_body
		human_avatar.real_name = human_old_body.real_name
		human_avatar.updateappearance(mutcolor_update = TRUE)

	update_avatar_id()
	avatar.mind.assigned_role = "Bit Avatar"

	avatar.playsound_local(avatar, 'sound/magic/blink.ogg', 25, TRUE)
	avatar.set_blurriness(4)
	avatar.set_blindness(1)

/datum/component/avatar_connection/PostTransfer(datum/new_parent)
	var/obj/machinery/netpod/pod = netpod_ref?.resolve()
	if(isnull(pod))
		return COMPONENT_INCOMPATIBLE

	if(!isliving(new_parent))
		return COMPONENT_INCOMPATIBLE

	pod.avatar_ref = WEAKREF(new_parent)

/datum/component/avatar_connection/RegisterWithParent()
	ADD_TRAIT(parent, TRAIT_TEMPORARY_BODY, REF(src))
	RegisterSignals(parent, list(COMSIG_BITRUNNER_ALERT_SEVER, COMSIG_BITRUNNER_CACHE_SEVER, COMSIG_BITRUNNER_LADDER_SEVER), PROC_REF(on_safe_disconnect))
	RegisterSignal(parent, COMSIG_LIVING_PILL_CONSUMED, PROC_REF(disconnect_if_red_pill))
	RegisterSignals(parent, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(on_sever_connection))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_linked_damage))

/datum/component/avatar_connection/UnregisterFromParent()
	REMOVE_TRAIT(parent, TRAIT_TEMPORARY_BODY, REF(src))
	UnregisterSignal(parent, list(
		COMSIG_BITRUNNER_ALERT_SEVER,
		COMSIG_BITRUNNER_CACHE_SEVER,
		COMSIG_BITRUNNER_LADDER_SEVER,
		COMSIG_LIVING_PILL_CONSUMED,
		COMSIG_LIVING_DEATH,
		COMSIG_QDELETING,
		COMSIG_MOB_APPLY_DAMAGE,
	))

/datum/component/avatar_connection/proc/update_avatar_id()
	var/mob/living/avatar = parent
	var/obj/item/card/id/our_id = locate() in avatar.GetAllContents()
	if(isnull(our_id))
		return

	our_id.registered_name = avatar.real_name
	our_id.update_label()
	our_id.update_icon()
	if(our_id.registered_account)
		our_id.registered_account.account_holder = avatar.real_name

/datum/component/avatar_connection/proc/full_avatar_disconnect(cause_damage = FALSE, datum/source)
#ifndef UNIT_TESTS
	return_to_old_body()
#endif

	var/obj/machinery/netpod/hosting_netpod = netpod_ref?.resolve()
	if(isnull(hosting_netpod) && istype(source, /obj/machinery/netpod))
		hosting_netpod = source

	hosting_netpod?.disconnect_occupant(cause_damage)

	var/obj/machinery/quantum_server/server = server_ref?.resolve()
	server?.avatar_connection_refs.Remove(WEAKREF(src))

	qdel(src)

/datum/component/avatar_connection/proc/on_domain_completed(datum/source, atom/entered)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(avatar, 'sound/machines/terminal_success.ogg', 50, vary = TRUE)
	avatar.throw_alert(
		ALERT_BITRUNNER_COMPLETED,
		/atom/movable/screen/alert/bitrunning/qserver_domain_complete,
		new_master = entered,
	)

/datum/component/avatar_connection/proc/on_linked_damage(datum/source, damage, damage_type, def_zone, blocked, ...)
	SIGNAL_HANDLER

	var/mob/living/carbon/old_body = old_body_ref?.resolve()
	if(isnull(old_body) || damage_type == STAMINA || damage_type == OXYLOSS)
		return

	if(damage >= (old_body.health + old_body.maxHealth))
		full_avatar_disconnect(cause_damage = TRUE)
		return

	if(damage > 30 && prob(30))
		INVOKE_ASYNC(old_body, TYPE_PROC_REF(/mob/living, emote), "scream")

	INVOKE_ASYNC(src, PROC_REF(apply_linked_damage), old_body, damage, damage_type, def_zone, blocked)

	nohit = FALSE

/datum/component/avatar_connection/proc/apply_linked_damage(mob/living/carbon/old_body, damage, damage_type, def_zone, blocked)
	if(QDELETED(src) || QDELETED(old_body))
		return

	old_body.apply_damage(damage, damage_type, def_zone, blocked, wound_bonus = CANT_WOUND)

	if(old_body.stat > SOFT_CRIT)
		full_avatar_disconnect(cause_damage = TRUE)

/datum/component/avatar_connection/proc/on_mind_transfer(datum/mind/source, mob/living/previous_body)
	SIGNAL_HANDLER

	var/datum/action/avatar_domain_info/action = locate() in previous_body.actions
	if(action)
		action.Grant(source.current)

	source.current.TakeComponent(src)

/datum/component/avatar_connection/proc/on_netpod_crowbar(datum/source, mob/living/intruder)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(avatar, 'sound/machines/terminal_alert.ogg', 50, vary = TRUE)
	var/atom/movable/screen/alert/bitrunning/alert = avatar.throw_alert(
		ALERT_BITRUNNER_CROWBAR,
		/atom/movable/screen/alert/bitrunning,
		new_master = intruder,
	)
	alert.name = "Netpod Breached"
	alert.desc = "Кто-то вскрывает нетпод. Найдите выход."

/datum/component/avatar_connection/proc/on_netpod_damaged(datum/source)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	var/atom/movable/screen/alert/bitrunning/alert = avatar.throw_alert(
		ALERT_BITRUNNER_INTEGRITY,
		/atom/movable/screen/alert/bitrunning,
		new_master = source,
	)
	alert.name = "Integrity Compromised"
	alert.desc = "Нетпод повреждён. Найдите выход."

/datum/component/avatar_connection/proc/disconnect_if_red_pill(datum/source, obj/item/pill, mob/feeder)
	SIGNAL_HANDLER
	if(pill?.icon_state == "pill4")
		full_avatar_disconnect()

/datum/component/avatar_connection/proc/on_safe_disconnect(datum/source)
	SIGNAL_HANDLER

	full_avatar_disconnect()

/datum/component/avatar_connection/proc/on_sever_connection(datum/source)
	SIGNAL_HANDLER

	full_avatar_disconnect(cause_damage = TRUE, source = source)

/datum/component/avatar_connection/proc/on_shutting_down(datum/source, mob/living/hackerman)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(avatar, 'sound/machines/terminal_alert.ogg', 50, vary = TRUE)
	var/atom/movable/screen/alert/bitrunning/alert = avatar.throw_alert(
		ALERT_BITRUNNER_SHUTDOWN,
		/atom/movable/screen/alert/bitrunning,
		new_master = hackerman,
	)
	alert.name = "Domain Rebooting"
	alert.desc = "Домен перезагружается. Найдите выход."

/datum/component/avatar_connection/proc/on_station_spawn(datum/source)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	avatar.playsound_local(avatar, 'sound/machines/terminal_alert.ogg', 50, vary = TRUE)
	var/atom/movable/screen/alert/bitrunning/alert = avatar.throw_alert(
		ALERT_BITRUNNER_BREACH,
		/atom/movable/screen/alert/bitrunning,
		new_master = source,
	)
	alert.name = "Security Breach"
	alert.desc = "Враждебная сущность прорывается в сейфхаус. Найдите выход."

/datum/component/avatar_connection/proc/on_threat_created(datum/source)
	SIGNAL_HANDLER

	var/mob/living/avatar = parent
	var/atom/movable/screen/alert/bitrunning/alert = avatar.throw_alert(
		ALERT_BITRUNNER_THREAT,
		/atom/movable/screen/alert/bitrunning,
		new_master = source,
	)
	alert.name = "Threat Detected"
	alert.desc = "Обнаружены аномалии потока данных."

/datum/component/avatar_connection/proc/return_to_old_body()
	var/datum/mind/old_mind = old_mind_ref?.resolve()
	var/mob/living/old_body = old_body_ref?.resolve()
	var/mob/living/avatar = parent

	var/mob/dead/observer/ghost = avatar.ghostize()
	if(isnull(ghost))
		ghost = avatar.get_ghost()

	if(isnull(ghost))
		CRASH("[src], принадлежащий [parent], не смог найти призрака для возвращения в тело!")

	if(isnull(old_mind) || isnull(old_body))
		return

	ghost.mind = old_mind
	if(old_body.stat != DEAD)
		old_mind.transfer_to(old_body, force_key_move = TRUE)
	else
		old_mind.set_current(old_body)

	REMOVE_TRAIT(old_body, TRAIT_MIND_TEMPORARILY_GONE, REF(src))

// Снаряжение берётся у верхнего человека, несущего предмет.
/datum/component/loads_avatar_gear
	var/datum/callback/load_callback
	var/datum/weakref/tracked_human_ref

/datum/component/loads_avatar_gear/Initialize(datum/callback/load_callback)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

	src.load_callback = load_callback

/datum/component/loads_avatar_gear/RegisterWithParent()
	parent.AddElement(/datum/element/connect_loc, list(
		COMSIG_ATOM_ENTERING = PROC_REF(on_entered_loc),
	))

/datum/component/loads_avatar_gear/UnregisterFromParent()
	parent.RemoveElement(/datum/element/connect_loc, list(
		COMSIG_ATOM_ENTERING = PROC_REF(on_entered_loc),
	))

/datum/component/loads_avatar_gear/Destroy(force)
	load_callback = null
	tracked_human_ref = null
	return ..()

/datum/component/loads_avatar_gear/proc/on_entered_loc(datum/source, atom/destination, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	if(isturf(destination) && isturf(old_loc))
		return

	var/list/nested_locs = get_nested_locs(parent)
	for(var/i in length(nested_locs) to 1 step -1)
		var/atom/container = nested_locs[i]
		if(ishuman(container))
			switch_tracking(container)
			return

	switch_tracking(null)

/datum/component/loads_avatar_gear/proc/switch_tracking(mob/living/carbon/human/to_track)
	var/mob/living/carbon/human/tracked_human = tracked_human_ref?.resolve()
	if(tracked_human == to_track)
		return

	if(tracked_human)
		UnregisterSignal(tracked_human, COMSIG_BITRUNNER_STOCKING_GEAR)
	tracked_human_ref = WEAKREF(to_track)
	if(isnull(to_track))
		return
	RegisterSignal(to_track, COMSIG_BITRUNNER_STOCKING_GEAR, PROC_REF(load_onto_avatar))

/datum/component/loads_avatar_gear/proc/load_onto_avatar(mob/living/carbon/human/neo, mob/living/carbon/human/avatar, domain_flags)
	SIGNAL_HANDLER
	return load_callback?.Invoke(neo, avatar, domain_flags)

// Копит очки и открывает крэйт при достижении порога.
/datum/component/bitrunning_points
	var/points_goal = 10
	var/points_received = 0

/datum/component/bitrunning_points/Initialize(datum/lazy_template/virtual_domain/domain)
	if(!isturf(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(domain, COMSIG_BITRUNNER_GOAL_POINT, PROC_REF(on_add_points))

/datum/component/bitrunning_points/proc/on_add_points(datum/source, points_to_add)
	SIGNAL_HANDLER

	points_received += points_to_add

	if(points_received < points_goal)
		return

	reveal()

/datum/component/bitrunning_points/proc/reveal()
	playsound(src, 'sound/magic/blink.ogg', 50, TRUE)

	var/turf/tile = parent
	var/obj/structure/closet/crate/secure/bitrunning/encrypted/crate = new()
	crate.forceMove(tile)
	do_sparks(5, FALSE, tile)
	qdel(src)

/datum/component/glitch
	var/datum/weakref/forge_ref
	var/datum/weakref/distort_component

/datum/component/glitch/Initialize(obj/machinery/quantum_server/server, obj/machinery/byteforge/forge)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/owner = parent
	var/health_boost = 0

	if (forge)
		RegisterSignal(forge, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(on_forge_power_restored))
		RegisterSignals(forge, list(COMSIG_MACHINERY_BROKEN, COMSIG_MACHINERY_POWER_LOST), PROC_REF(on_forge_broken))
		forge_ref = WEAKREF(forge)
		server.remove_threat(owner)
		health_boost = ROUND_UP(server.threat * 0.2)

	owner.set_faction(list(ROLE_GLITCH))

	owner.maxHealth = clamp(owner.maxHealth + health_boost, 200, 500)
	owner.fully_heal()
	owner.create_digital_aura()

/datum/component/glitch/RegisterWithParent()
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/component/glitch/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

/datum/component/glitch/proc/on_death()
	SIGNAL_HANDLER

	if(QDELETED(parent))
		return

	var/mob/living/owner = parent
	to_chat(owner, span_userdanger("Вы ощущаете странное чувство..."))

	var/obj/machinery/byteforge/forge = forge_ref?.resolve()
	forge?.setup_particles()

	owner.fade_into_nothing(3 SECONDS, 2 SECONDS)

/datum/component/glitch/proc/on_forge_broken(datum/source)
	SIGNAL_HANDLER

	var/mob/living/player = parent
	var/atom/movable/screen/alert/bitrunning/alert = player.throw_alert(
		ALERT_BITRUNNER_GLITCH,
		/atom/movable/screen/alert/bitrunning,
		new_master = source,
	)
	alert.name = "Source Broken"
	alert.desc = "Наш байтфордж сломан."

	if(!iscarbon(parent))
		return

	player.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/glitch_slowdown)
	to_chat(player, span_danger("Ваше тело кажется вялым..."))

/datum/component/glitch/proc/on_forge_power_restored(datum/source)
	SIGNAL_HANDLER

	var/obj/machinery/byteforge/forge = source
	forge.setup_particles(angry = TRUE)

	if(!iscarbon(parent))
		return

	var/mob/living/player = parent
	player.clear_alert(ALERT_BITRUNNER_GLITCH)
	player.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/glitch_slowdown)

/datum/movespeed_modifier/status_effect/glitch_slowdown
	multiplicative_slowdown = 1.5

#define BASE_HEAL 4

/datum/component/netpod_healing

/datum/component/netpod_healing/Initialize(obj/machinery/netpod/pod)
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignals(
		pod,
		list(COMSIG_MACHINERY_BROKEN, COMSIG_QDELETING, COMSIG_BITRUNNER_NETPOD_OPENED),
		PROC_REF(on_remove),
	)

	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_remove))

	var/mob/living/carbon/player = parent
	ADD_TRAIT(player, TRAIT_STASIS, REF(src))

	START_PROCESSING(SSmachines, src)

/datum/component/netpod_healing/Destroy(force)
	STOP_PROCESSING(SSmachines, src)

	var/mob/living/carbon/player = parent
	REMOVE_TRAIT(player, TRAIT_STASIS, REF(src))

	return ..()

/datum/component/netpod_healing/process(seconds_per_tick)
	var/mob/living/carbon/owner = parent
	if(isnull(owner))
		qdel(src)
		return

	var/need_mob_update = FALSE
	need_mob_update += owner.adjustBruteLoss(-BASE_HEAL * seconds_per_tick, updating_health = FALSE)
	need_mob_update += owner.adjustFireLoss(-BASE_HEAL * seconds_per_tick, updating_health = FALSE)
	need_mob_update += owner.adjustToxLoss(-BASE_HEAL * seconds_per_tick, updating_health = FALSE, forced = TRUE)

	owner.blood_volume = min(owner.blood_volume + BASE_HEAL * seconds_per_tick, BLOOD_VOLUME_NORMAL)

	if(need_mob_update)
		owner.updatehealth()

/datum/component/netpod_healing/proc/on_remove()
	SIGNAL_HANDLER

	qdel(src)

#undef BASE_HEAL

/datum/component/npc_friendly
	var/static/list/npc_factions = list(
		FACTION_BOSS,
		FACTION_CARP,
		FACTION_HIVEBOT,
		FACTION_HOSTILE,
		FACTION_MIMIC,
		FACTION_PIRATE,
		FACTION_SPIDER,
		FACTION_STICKMAN,
		ROLE_ALIEN,
		ROLE_GLITCH,
		ROLE_SYNDICATE,
	)
	var/list/previous_factions

/datum/component/npc_friendly/Initialize()
	. = ..()

	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/player = parent

	previous_factions = player.get_faction()
	player.add_faction(npc_factions)

/datum/component/npc_friendly/Destroy(force)
	var/mob/living/player = parent
	if(!QDELETED(parent))
		player.set_faction(previous_factions)
	return ..()

// Виртуальные сущности не могут входить в защищённые зоны.
/datum/component/virtual_entity
	COOLDOWN_DECLARE(OOB_cooldown)

/datum/component/virtual_entity/Initialize(obj/machinery/quantum_server)
	if(quantum_server.obj_flags & EMAGGED)
		jailbreak_mobs()
		qdel(src)
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_parent_pre_move))
	RegisterSignal(quantum_server, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emagged))

/datum/component/virtual_entity/proc/jailbreak_mobs()
	to_chat(parent, span_bolddanger("Вы на миг вздрагиваете, ощущая небывалую ясность."))
	to_chat(parent, span_notice("Вы можете отправиться <i>куда угодно</i> и делать <i>что угодно</i>! Можете прямо сейчас покинуть эту симуляцию, если захотите!"))
	to_chat(parent, span_danger("Но учтите: квантовая запутанность помешает любым прошлым жизням."))
	to_chat(parent, span_notice("У вас будет только один шанс устроить вспышку, и пути назад не будет."))

/datum/component/virtual_entity/proc/on_emagged(datum/source)
	SIGNAL_HANDLER

	jailbreak_mobs()
	qdel(src)

/datum/component/virtual_entity/proc/on_parent_pre_move(atom/movable/source, atom/new_location)
	SIGNAL_HANDLER

	var/area/location_area = get_area(new_location)
	if(!location_area)
		stack_trace("Виртуальная сущность попала в локацию без зоны!")
		return

	if(location_area.area_flags & VIRTUAL_SAFE_AREA)
		source.balloon_alert(source, "за границами домена!")
		COOLDOWN_START(src, OOB_cooldown, 2 SECONDS)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE
