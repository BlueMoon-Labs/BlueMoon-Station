/** Portable policies own mutable state per actor, never on registry profiles. */
/datum/netrun_agent_behavior/pattern
	var/datum/owner

/datum/netrun_agent_behavior/pattern/New(datum/owner)
	src.owner = owner

/datum/netrun_agent_behavior/pattern/bound_owner()
	return owner

/datum/netrun_agent_behavior/pattern/Destroy()
	. = ..()
	owner = null

/datum/netrun_agent_behavior/pattern/proc/mutate(list/changes)
	return FALSE

/datum/netrun_agent_behavior/pattern/temperament
	id = "temperament"
	priority = 90
	/// profile retains the archetype; other strategies can be selected at runtime.
	var/strategy = "profile"
	var/aggression = 100
	var/caution = 30
	var/cooperation = TRUE

/datum/netrun_agent_behavior/pattern/temperament/on_install()
	var/mob/camera/netrun_entity/bot/bot = owner
	if(istype(bot))
		caution = round(bot.program.flee_ratio * 100)
	return TRUE

/// Validate the whole mutation before changing any field.
/datum/netrun_agent_behavior/pattern/temperament/mutate(list/changes)
	if(!islist(changes) || !length(changes))
		return FALSE
	for(var/key in changes)
		var/value = changes[key]
		switch(key)
			if("strategy")
				if(!(value in list("profile", "patrol", "scavenge", "guard")))
					return FALSE
			if("aggression", "caution")
				if(!isnum(value) || !IS_FINITE(value) || value < 0 || value > 100)
					return FALSE
			if("cooperation")
				if(!(value in list(TRUE, FALSE)))
					return FALSE
			else
				return FALSE
	for(var/key in changes)
		vars[key] = changes[key]
	var/mob/camera/netrun_entity/bot/bot = owner
	if(istype(bot) && ("strategy" in changes))
		bot.brain?.clear_goals()
	return TRUE

/// Aggression is willingness to challenge a stronger opponent, rather than
/// a random roll repeated every think. Remembered attackers bypass this policy.
/datum/netrun_agent_behavior/pattern/temperament/proc/willing_to_engage(datum/target)
	if(aggression <= 0)
		return FALSE
	if(aggression >= 100)
		return TRUE
	var/list/own_health = owner.get_netrun_combatant()?.integrity_payload()
	var/list/target_health = target?.get_netrun_combatant()?.integrity_payload()
	return own_health && target_health && own_health["cur"] * aggression >= target_health["cur"] * (100 - aggression)

/datum/netrun_agent_behavior/pattern/temperament/proc/plan(datum/netrun_bot_brain/brain)
	if(!brain || brain.owner != owner)
		return
	var/mob/camera/netrun_entity/bot/bot = owner
	switch(strategy)
		if("guard")
			brain.push_goal(new /datum/netrun_bot_goal/guard(brain, bot.host_node))
		if("patrol")
			brain.push_goal(new /datum/netrun_bot_goal/patrol(brain, bot.program.patrol_networks(brain)))
		if("scavenge")
			var/datum/component/netrun_node/node = brain.find_salvage(bot.program.patrol_networks(brain))
			if(node)
				brain.push_goal(new /datum/netrun_bot_goal/salvage(brain, node))
			else
				brain.push_goal(new /datum/netrun_bot_goal/patrol(brain, bot.program.patrol_networks(brain)))
		else
			bot.program.plan(brain)

/proc/netrun_actor_temperament(datum/actor)
	RETURN_TYPE(/datum/netrun_agent_behavior/pattern/temperament)
	var/datum/netrun_module_host/controller = actor?.netrun_actor_modules()
	var/datum/netrun_agent_behavior/pattern/temperament/pattern = controller?.modules["temperament"]
	return controller?.entity_module_current(pattern) ? pattern : null

/// Messages are received as facts. Reply input is a delayed presence packet,
/// preventing automatic acknowledgement loops and arbitrary text-based orders.
/datum/netrun_agent_behavior/pattern/communication
	id = "communication"
	priority = 135
	var/datum/weakref/sender_ref
	var/reply_at = 0
	var/reply_timer
	var/next_reply = 0

/datum/netrun_agent_behavior/pattern/communication/on_install()
	listen(owner, COMSIG_NETRUN_ACTOR_CONTACT, PROC_REF(on_contact))
	listen(owner, COMSIG_NETRUN_ACTOR_DISTRESS, PROC_REF(on_distress))
	return TRUE

/datum/netrun_agent_behavior/pattern/communication/on_remove()
	if(reply_timer)
		deltimer(reply_timer)
	reply_timer = null
	sender_ref = null

/datum/netrun_agent_behavior/pattern/communication/proc/on_contact(datum/source, datum/netrun_console/sender, message)
	SIGNAL_HANDLER
	if(!installed || !enabled || !owner.netrun_actor_autonomous() || isnull(message) || sender_ref || world.time < next_reply || netrun_turn_encounter(owner)?.active)
		return
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	if(policy && !policy.cooperation)
		return
	var/datum/actor = sender.netrun_actor()
	if(actor && netrun_bot_factions_hostile(owner.netrun_actor_faction(), actor.netrun_actor_faction()))
		return
	sender_ref = WEAKREF(sender)
	reply_at = world.time + 1 SECONDS
	reply_timer = addtimer(CALLBACK(src, PROC_REF(reply_due)), 1 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_agent_behavior/pattern/communication/proc/reply_due()
	reply_timer = null
	if(netrun_turn_encounter(owner)?.active)
		sender_ref = null
		return
	if(installed && enabled && !QDELETED(owner))
		owner.netrun_actor_wake()

/datum/netrun_agent_behavior/pattern/communication/behavior_step(datum/netrun_bot_brain/brain)
	if(!sender_ref || world.time < reply_at || !owner.netrun_actor_autonomous())
		return FALSE
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	if(netrun_turn_encounter(owner)?.active || (policy && !policy.cooperation))
		sender_ref = null
		return FALSE
	var/datum/netrun_console/sender = sender_ref.resolve()
	sender_ref = null
	var/datum/recipient = sender?.netrun_actor()
	var/datum/component/netrun_node/node = recipient?.netrun_actor_node()
	if(QDELETED(recipient) || QDELETED(node) || netrun_bot_factions_hostile(owner.netrun_actor_faction(), recipient.netrun_actor_faction()))
		return FALSE
	var/datum/netrun_console/console = owner.netrun_actor_console()
	if(QDELETED(console))
		return FALSE
	next_reply = world.time + 5 SECONDS
	return console.signal_entity(node, REF(recipient), null)

/// Trusted combat events, rather than message text, drive allied assistance.
/datum/netrun_agent_behavior/pattern/communication/proc/on_distress(datum/source, datum/victim, datum/attacker)
	SIGNAL_HANDLER
	if(!installed || !enabled || !owner.netrun_actor_autonomous() || QDELETED(victim) || QDELETED(attacker) || victim == owner || attacker == owner)
		return
	var/datum/netrun_agent_behavior/pattern/temperament/policy = netrun_actor_temperament(owner)
	if(policy && !policy.cooperation)
		return
	if(owner.netrun_actor_faction() != victim.netrun_actor_faction() || owner.netrun_actor_node() != victim.netrun_actor_node() || attacker.netrun_actor_node() != victim.netrun_actor_node())
		return
	owner.netrun_actor_remember_enemy(attacker)
	owner.netrun_actor_wake()

/datum/proc/netrun_actor_remember_enemy(datum/attacker)
	return

/mob/camera/netrun_entity/bot/netrun_actor_remember_enemy(datum/attacker)
	brain?.mark_enemy(attacker)

/datum/netrun_ice/netrun_actor_remember_enemy(datum/attacker)
	if(istype(attacker, /mob/camera/netrun_entity) || istype(attacker, /datum/netrun_ice))
		enemy_ref = WEAKREF(attacker)

/datum/proc/netrun_actor_attacked(datum/attacker)
	var/datum/component/netrun_node/node = netrun_actor_node()
	if(QDELETED(attacker) || attacker == src || QDELETED(node))
		return
	netrun_actor_remember_enemy(attacker)
	SEND_SIGNAL(src, COMSIG_NETRUN_ACTOR_ATTACKED, attacker)
	var/list/occupants = list()
	occupants |= node.entities
	occupants |= node.netrun_ice
	var/count = 0
	for(var/datum/ally as anything in occupants)
		if(++count > 16)
			break
		if(!QDELETED(ally) && ally != src)
			SEND_SIGNAL(ally, COMSIG_NETRUN_ACTOR_DISTRESS, src, attacker)
