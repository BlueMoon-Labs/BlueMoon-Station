/// A combatant supplies one interface regardless of whether its owner is a mob or ICE.
/datum/proc/get_netrun_combatant()
	RETURN_TYPE(/datum/component/netrun_combatant)
	return null

/mob/camera/netrun_entity/get_netrun_combatant()
	RETURN_TYPE(/datum/component/netrun_combatant)
	return LoadComponent(/datum/component/netrun_combatant/entity)

/datum/netrun_ice/get_netrun_combatant()
	RETURN_TYPE(/datum/component/netrun_combatant)
	return LoadComponent(/datum/component/netrun_combatant/ice)

/datum/component/netrun_combatant
	var/kind
	var/hostile = FALSE

/datum/component/netrun_combatant/proc/node()
	return null

/datum/component/netrun_combatant/proc/display_name()
	return "?"

/datum/component/netrun_combatant/proc/integrity_payload()
	return null

/datum/component/netrun_combatant/proc/damage(amount, reason, datum/netrun_console/attacker)
	return

/datum/component/netrun_combatant/proc/stun(duration)
	return

/datum/component/netrun_combatant/proc/shield(pct, duration)
	return

/datum/component/netrun_combatant/proc/heal(amount)
	return

/// Structures can be engaged from outside their node (fortress outer works from a neighbour).
/datum/component/netrun_combatant/proc/allows_remote_attack(datum/netrun_console/console, datum/component/netrun_node/local_node)
	return FALSE

/// Attacking this target is an incident for the network police (station defenses).
/datum/component/netrun_combatant/proc/protected_by_station()
	return FALSE

/datum/component/netrun_combatant/proc/ui_entry()
	var/list/hp = integrity_payload()
	var/datum/component/netrun_node/host_node = node()
	return list("ref" = REF(parent), "name" = display_name(), "kind" = kind,
		"hostile" = hostile, "integrity" = hp["cur"], "max_integrity" = hp["max"],
		"stunned" = hp["stunned"], "shielded" = hp["shielded"],
		"node" = host_node?.address, "node_name" = host_node?.get_name(), "unavailable_reason" = null)

/datum/component/netrun_combatant/entity
	kind = "entity"

/datum/component/netrun_combatant/entity/Initialize()
	if(!istype(parent, /mob/camera/netrun_entity))
		return COMPONENT_INCOMPATIBLE

/datum/component/netrun_combatant/entity/node()
	var/mob/camera/netrun_entity/entity = parent
	return entity.host_node

/datum/component/netrun_combatant/entity/display_name()
	var/mob/camera/netrun_entity/entity = parent
	return entity.combat_name()

/datum/component/netrun_combatant/entity/ui_entry()
	. = ..()
	var/mob/camera/netrun_entity/entity = parent
	var/datum/netrun_faction/faction = SSnetrun.get_netrun_faction(entity.netrun_faction())
	.["faction_name"] = faction?.name
	.["faction_color"] = faction?.color

/datum/component/netrun_combatant/entity/integrity_payload()
	var/mob/camera/netrun_entity/entity = parent
	return list("cur" = round(entity.integrity), "max" = entity.max_integrity,
		"stunned" = entity.is_stunned(), "shielded" = world.time < entity.combat_shield_until)

/datum/component/netrun_combatant/entity/damage(amount, reason, datum/netrun_console/attacker)
	var/mob/camera/netrun_entity/entity = parent
	entity.apply_damage(amount, reason, attacker)

/datum/component/netrun_combatant/entity/stun(duration)
	var/mob/camera/netrun_entity/entity = parent
	entity.apply_stun(duration)

/datum/component/netrun_combatant/entity/shield(pct, duration)
	var/mob/camera/netrun_entity/entity = parent
	entity.apply_shield(pct, duration)

/datum/component/netrun_combatant/entity/heal(amount)
	var/mob/camera/netrun_entity/entity = parent
	entity.apply_heal(amount)

/datum/component/netrun_combatant/ice
	kind = "ice"
	hostile = TRUE

/datum/component/netrun_combatant/ice/Initialize()
	if(!istype(parent, /datum/netrun_ice))
		return COMPONENT_INCOMPATIBLE

/datum/component/netrun_combatant/ice/node()
	var/datum/netrun_ice/ice = parent
	return ice.node

/datum/component/netrun_combatant/ice/display_name()
	var/datum/netrun_ice/ice = parent
	return ice.combat_name()

/datum/component/netrun_combatant/ice/integrity_payload()
	var/datum/netrun_ice/ice = parent
	return list("cur" = round(ice.integrity), "max" = ice.max_integrity,
		"stunned" = ice.is_stunned(), "shielded" = world.time < ice.combat_shield_until)

/datum/component/netrun_combatant/ice/damage(amount, reason, datum/netrun_console/attacker)
	var/datum/netrun_ice/ice = parent
	ice.apply_damage(amount, reason, attacker)

/datum/component/netrun_combatant/ice/stun(duration)
	var/datum/netrun_ice/ice = parent
	ice.apply_stun(duration)

/datum/component/netrun_combatant/ice/shield(pct, duration)
	var/datum/netrun_ice/ice = parent
	ice.apply_shield(pct, duration)

/datum/component/netrun_combatant/ice/heal(amount)
	var/datum/netrun_ice/ice = parent
	ice.apply_heal(amount)

/datum/component/netrun_combatant/ice/protected_by_station()
	var/datum/netrun_ice/ice = parent
	return !ice.agent?.profile.illegal

/datum/component/netrun_combatant/ice/ui_entry()
	. = ..()
	var/datum/netrun_ice/ice = parent
	.["programs"] = ice.program_payload()
	.["casting"] = ice.casting_payload()
	.["ice_kind"] = ice.kind
	.["state"] = ice.agent?.state

/// Compatibility helpers route effects through the owner's polymorphic component.
/proc/netrun_combatant_integrity(datum/thing)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	return combatant?.integrity_payload()

/proc/netrun_combatant_name(datum/thing)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	return combatant?.display_name() || "?"

/proc/netrun_combatant_in_node(datum/thing, datum/component/netrun_node/node)
	if(!node || QDELETED(thing))
		return FALSE
	var/datum/component/netrun_combatant/combatant = thing.get_netrun_combatant()
	return combatant?.node() == node

/proc/netrun_combatant_hit(datum/thing, amount, reason, datum/netrun_console/attacker)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	combatant?.damage(amount, reason, attacker)

/proc/netrun_combatant_stun(datum/thing, duration)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	combatant?.stun(duration)

/proc/netrun_combatant_shield(datum/thing, pct, duration)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	combatant?.shield(pct, duration)

/proc/netrun_combatant_heal(datum/thing, amount)
	var/datum/component/netrun_combatant/combatant = thing?.get_netrun_combatant()
	combatant?.heal(amount)
