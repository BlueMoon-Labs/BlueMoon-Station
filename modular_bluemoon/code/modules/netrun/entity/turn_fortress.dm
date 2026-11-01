/// A fortress has one battery turn, regardless of its number of passive works.
/datum/netrun_fortress
	var/datum/weakref/combat_encounter_ref
	var/list/turn_siege_leases = list()
	var/turn_regen_at = 0
	var/datum/netrun_program/turn_volley_definition
	var/list/turn_jammed_modules = list()

/datum/netrun_fortress/proc/get_combat_encounter()
	RETURN_TYPE(/datum/netrun_combat_encounter)
	return combat_encounter_ref?.resolve()

/datum/netrun_fortress/proc/has_turn_battery()
	return !QDELETED(node) && slots_max() > 0 && (intact_count(NETRUN_FORT_TURRET) || intact_count(NETRUN_FORT_REGEN))

/// Admission records no alarm, damage or permission. Actual hits still note_attack().
/datum/netrun_fortress/proc/authorize_turn_siege(datum/netrun_console/console, datum/netrun_fortress_module/module)
	var/mob/camera/netrun_entity/entity = console?.combat_self()
	if(!istype(entity) || QDELETED(entity) || module?.fortress != src || !has_turn_battery())
		return FALSE
	if(entity.host_node == node)
		return TRUE
	if(!module.get_netrun_combatant().allows_remote_attack(console, entity.host_node))
		return FALSE
	turn_siege_leases[WEAKREF(entity)] = list("source" = WEAKREF(entity.host_node), "until" = world.time + 20 SECONDS)
	while(length(turn_siege_leases) > 8)
		turn_siege_leases.Cut(1, 2)
	return TRUE

/datum/netrun_fortress/proc/valid_turn_siege(mob/camera/netrun_entity/entity)
	if(QDELETED(entity) || QDELETED(entity.host_node) || QDELETED(node))
		return FALSE
	var/list/lease = turn_siege_leases[WEAKREF(entity)]
	var/datum/weakref/source_ref = lease?["source"]
	if(!lease || source_ref?.resolve() != entity.host_node)
		return FALSE
	if(world.time >= lease["until"])
		return besieging(entity)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	return (node.address in graph.neighbors(entity.host_node.address, FALSE)) && netrun_link_available(entity.host_node, node)

/datum/netrun_fortress/proc/turn_volley_program()
	if(!turn_volley_definition)
		turn_volley_definition = new
		turn_volley_definition.id = "fortress.volley"
		turn_volley_definition.hostile = TRUE
		turn_volley_definition.ap_cost = 2
		turn_volley_definition.cooldown_turns = 1
	return turn_volley_definition

/datum/netrun_fortress/proc/apply_turn_stun(datum/netrun_program/program, datum/target, datum/netrun_turn_participant/participant)
	var/datum/netrun_fortress_module/module = target
	if(!istype(module) || module.fortress != src || module.kind != NETRUN_FORT_TURRET || program.stun_turns <= 0)
		return FALSE
	participant.stun_turns = max(participant.stun_turns, program.stun_turns)
	turn_jammed_modules[WEAKREF(module)] = TRUE
	module.jammed_until = INFINITY
	changed()
	return TRUE

/datum/netrun_fortress/proc/clear_turn_stuns()
	if(!length(turn_jammed_modules))
		return
	for(var/datum/weakref/reference as anything in turn_jammed_modules)
		var/datum/netrun_fortress_module/module = reference.resolve()
		if(module?.fortress == src && module.jammed_until == INFINITY)
			module.jammed_until = world.time
	turn_jammed_modules.Cut()
	changed()

/// Controller notifications suspend only combat deadlines; construction remains native.
/datum/netrun_fortress/proc/on_turn_changed(datum/source, datum/netrun_combat_encounter/encounter)
	SIGNAL_HANDLER
	if(get_combat_encounter()?.active && !get_combat_encounter().has_turn(src))
		cancel_turret(FALSE)
	schedule()

/datum/netrun_fortress/proc/process_turn_battery()
	var/datum/netrun_combat_encounter/encounter = get_combat_encounter()
	if(!encounter?.active || !encounter.has_turn(src))
		return
	if(turret_fire_at)
		process_turret()
		return
	if(!pick_turret_target())
		encounter.remove(encounter.member(src))
		return
	var/datum/netrun_turn_participant/participant = encounter.member(src)
	if(intact_count(NETRUN_FORT_REGEN) && needs_regen() && turn_regen_at != participant.own_turn && encounter.remaining_ap(src) >= 1 && encounter.spend(src, 1, TRUE))
		turn_regen_at = participant.own_turn
		regenerate()
		changed()
		encounter.resolve(src)
	if(QDELETED(encounter) || !encounter.has_turn(src))
		return
	process_turret()
	if(!turret_fire_at && encounter.has_turn(src) && !encounter.deferred)
		encounter.pass(src)
