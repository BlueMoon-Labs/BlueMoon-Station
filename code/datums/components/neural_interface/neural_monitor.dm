// ============================================================================
// Neural Interface Auto-Monitor System
// ============================================================================
// Provides modular auto-monitoring capabilities that can be attached to
// neural interface component following OOP composition pattern
// ============================================================================

// ---------------------------------------------------------------------------
// Base Monitor - Abstract interface for all monitors
// ---------------------------------------------------------------------------
/datum/neural_monitor
	var/name = "DEFAULT MONITOR"
	var/datum/component/neural_interface/owner // datum/component/neural_interface
	var/atom/monitor_atom
	var/enabled = FALSE
	var/processing = FALSE
	var/next_activate
	var/periodic = 1 SECONDS
	var/source

/datum/neural_monitor/New(datum/component/neural_interface/owner_comp, atom/monitor_atom_p, source_p, ...)
	owner = owner_comp
	monitor_atom = monitor_atom_p
	source = source_p

	owner.system_log("INITIALIZE: [source]/[name]")

/datum/neural_monitor/Destroy(force, ...)
	disable()
	owner = null
	monitor_atom = null
	. = ..()

/datum/neural_monitor/process(delta_time)
	if(next_activate > world.time)
		return FALSE

	next_activate = world.time + periodic
	if(!enabled)
		return FALSE
	return TRUE

/datum/neural_monitor/proc/register_signals()
	// Override in child classes

/datum/neural_monitor/proc/unregister_signals()
	// Override in child classes

/datum/neural_monitor/proc/enable()
	if(enabled)
		return
	enabled = TRUE
	owner.system_log("[source]/[name]: ENABLED")
	if(processing)
		START_PROCESSING(SSfastprocess, src)
		next_activate = world.time + periodic
	if(monitor_atom)
		register_signals()

/datum/neural_monitor/proc/disable()
	if(!enabled)
		return
	enabled = FALSE
	owner.system_log("[source]/[name]: DISABLED")
	if(processing)
		STOP_PROCESSING(SSfastprocess, src)
	if(monitor_atom)
		unregister_signals()

// ---------------------------------------------------------------------------
// Health Monitor - Tracks damage, status effects, death/revive
// ---------------------------------------------------------------------------
/datum/neural_monitor/health
	name = "HEALTH MONITOR"
	var/last_brute_damage = 0
	var/last_tox_damage = 0
	var/last_fire_damage = 0
	var/last_oxy_damage = 0
	var/last_stat = 0

/datum/neural_monitor/health/register_signals()
	if(!monitor_atom)
		return

	if(ishuman(monitor_atom))
		RegisterSignal(monitor_atom, COMSIG_CARBON_UPDATEHEALTH, PROC_REF(on_carbon_health_update))

	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_STUN, PROC_REF(on_living_stunned))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_KNOCKDOWN, PROC_REF(on_living_knockdown))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_PARALYZE, PROC_REF(on_living_paralyzed))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_UNCONSCIOUS, PROC_REF(on_living_unconscious))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_SLEEP, PROC_REF(on_living_sleeping))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_DAZE, PROC_REF(on_living_dazed))
	RegisterSignal(monitor_atom, COMSIG_LIVING_STATUS_STAGGER, PROC_REF(on_living_staggered))

	RegisterSignal(monitor_atom, COMSIG_MOB_DEATH, PROC_REF(on_mob_death))
	RegisterSignal(monitor_atom, COMSIG_LIVING_REVIVE, PROC_REF(on_living_revive))
	RegisterSignal(monitor_atom, COMSIG_LIVING_DEATH, PROC_REF(on_living_death))
	RegisterSignal(monitor_atom, COMSIG_LIVING_PREDEATH, PROC_REF(on_living_predeath))
	RegisterSignal(monitor_atom, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_mob_apply_damage))

	RegisterSignal(monitor_atom, COMSIG_MOB_GHOSTIZE, PROC_REF(on_mob_ghostize))

/datum/neural_monitor/health/unregister_signals()
	if(!monitor_atom)
		return

	UnregisterSignal(monitor_atom, COMSIG_CARBON_UPDATEHEALTH)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_STUN)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_KNOCKDOWN)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_PARALYZE)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_UNCONSCIOUS)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_SLEEP)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_DAZE)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_STATUS_STAGGER)
	UnregisterSignal(monitor_atom, COMSIG_MOB_DEATH)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_REVIVE)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_DEATH)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_PREDEATH)
	UnregisterSignal(monitor_atom, COMSIG_MOB_APPLY_DAMAGE)
	UnregisterSignal(monitor_atom, COMSIG_MOB_GHOSTIZE)

/datum/neural_monitor/health/proc/on_carbon_health_update(mob/living/carbon/C)
	SIGNAL_HANDLER

	if(!monitor_atom || !isliving(monitor_atom) || !iscarbon(monitor_atom))
		return

	var/mob/living/carbon/user = monitor_atom

	var/oxy_loss = user.getOxyLoss()
	var/tox_loss = user.getToxLoss()
	var/fire_loss = user.getFireLoss()
	var/brute_loss = user.getBruteLoss()

	// Detect new damage
	var/new_brute = brute_loss > last_brute_damage
	var/new_tox = tox_loss > last_tox_damage
	var/new_fire = fire_loss > last_fire_damage
	var/new_oxy = oxy_loss > last_oxy_damage

	if(new_brute && (brute_loss - last_brute_damage) > 5)
		owner.write_log("Brute damage: [brute_loss]", "HEALTH")
	if(new_tox && (tox_loss - last_tox_damage) > 5)
		owner.write_log("Toxin damage: [tox_loss]", "HEALTH")
	if(new_fire && (fire_loss - last_fire_damage) > 5)
		owner.write_log("Burn damage: [fire_loss]", "HEALTH")
	if(new_oxy && (oxy_loss - last_oxy_damage) > 5)
		owner.write_log("Oxygen loss: [oxy_loss]", "HEALTH")

	// Update status display
	var/health_percent = user.health / user.maxHealth * 100
	var/status_text = "<b>[round(health_percent, 0.1)]</b>"

	if(user.stat == DEAD)
		status_text = "<span class='alert'><b>DESTROYED</b></span>"
	else if(health_percent < 25)
		status_text = "<span class='alert'><b>CRITICAL</b></span>"
	else if(health_percent < 50)
		status_text = "<span class='userdanger'><b>DANGER</b></span>"
	else if(health_percent < 75)
		status_text = "<span class='notice'><b>MINOR</b></span>"

	owner.write_data("STATUS", status_text, 30 SECONDS)
	owner.write_data("BRUTE", "[brute_loss]", 30 SECONDS)
	owner.write_data("TOX", "[tox_loss]", 30 SECONDS)
	owner.write_data("BURN", "[fire_loss]", 30 SECONDS)
	owner.write_data("OXYGEN", "[oxy_loss]", 30 SECONDS)

	// Store last values
	last_brute_damage = brute_loss
	last_tox_damage = tox_loss
	last_fire_damage = fire_loss
	last_oxy_damage = oxy_loss

/datum/neural_monitor/health/proc/on_living_stunned(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Stunned: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("STUN_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_knockdown(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Knocked down: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("KNOCKDOWN_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_paralyzed(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Paralyzed: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("PARALYZE_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_unconscious(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Unconscious: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("UNCONSCIOUS_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_sleeping(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Asleep: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("SLEEP_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_dazed(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Dazed: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("DAZE_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_living_staggered(mob/living/L, amount, update, ignore)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Staggered: [round(amount/10, 0.1)]s", "HEALTH")
	owner.write_data("STAGGER_REMAINING", "[round(amount/10, 0.1)]s")

/datum/neural_monitor/health/proc/on_mob_death(mob/M, gibbed)
	SIGNAL_HANDLER

	if(M != monitor_atom)
		return
	owner.error_log("Mob death signal received")

/datum/neural_monitor/health/proc/on_living_death(mob/living/L, gibbed)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.error_log("Living death signal received [gibbed ? "(gibbed)" : ""]")
	owner.write_data("DEATH_STATE", "DIED")
	owner.write_log("Vital signals TERMINATED", "ALERT")

/datum/neural_monitor/health/proc/on_living_predeath(mob/living/L, gibbed)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.warn_log("Pre-death state [gibbed == TRUE ? "(gibbed)" : ""]")
	owner.write_data("PREDEATH_STATE", "TRUE")

/datum/neural_monitor/health/proc/on_living_revive(mob/living/L, full_heal, admin_revive)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.info_log("Revived [full_heal == TRUE ? "(full heal)" : ""]")
	owner.write_data("DEATH_STATE", "ALIVE")
	owner.write_data("PREDEATH_STATE", "FALSE")
	owner.write_log("Vital signals RESTORED", "SYNC")

/datum/neural_monitor/health/proc/on_mob_ghostize(mob/M, can_reenter, special, penalize)
	SIGNAL_HANDLER

	if(M != monitor_atom)
		return
	owner.warn_log("Host ghostized [can_reenter == TRUE ? "(can re-enter)" : ""]")
	owner.write_data("GHOST_STATE", "TRUE")

/datum/neural_monitor/health/proc/on_mob_apply_damage(mob/living/L, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	var/damage_log = "Damage: [damage] [damagetype] on [def_zone]"
	owner.write_log(damage_log, "HEALTH")
	owner.write_data("LAST_DAMAGE", "[damage]")
	owner.write_data("LAST_DAMAGE_TYPE", "[damagetype]")
	owner.write_data("LAST_DAMAGE_ZONE", "[def_zone]")

	if(damage > 30)
		owner.write_log("Significant damage applied!", "ALERT")
	else if(damage > 15)
		owner.warn_log("Moderate damage applied")

// ---------------------------------------------------------------------------
// Wound Monitor - Tracks wounds gained/lost
// ---------------------------------------------------------------------------
/datum/neural_monitor/wound
	name = "WOUND MONITOR"

/datum/neural_monitor/wound/register_signals()
	if(!monitor_atom || !ishuman(monitor_atom))
		return
	RegisterSignal(monitor_atom, COMSIG_CARBON_GAIN_WOUND, PROC_REF(on_carbon_gain_wound))
	RegisterSignal(monitor_atom, COMSIG_CARBON_LOSE_WOUND, PROC_REF(on_carbon_lose_wound))

/datum/neural_monitor/wound/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_CARBON_GAIN_WOUND)
	UnregisterSignal(monitor_atom, COMSIG_CARBON_LOSE_WOUND)

/datum/neural_monitor/wound/proc/on_carbon_gain_wound(mob/living/carbon/C, datum/wound/W, obj/item/bodypart/L)
	SIGNAL_HANDLER

	var/wound_info = "Wound: [W.name] on [L.name]"
	owner.write_log(wound_info, "HEALTH")
	if(W.name)
		owner.write_data("ACTIVE_WOUND", W.name)

/datum/neural_monitor/wound/proc/on_carbon_lose_wound(mob/living/carbon/C, datum/wound/W, obj/item/bodypart/L)
	SIGNAL_HANDLER

	var/wound_info = "Healed: [W.name] on [L.name]"
	owner.write_log(wound_info, "HEALTH")

// ---------------------------------------------------------------------------
// Shock Monitor - Tracks electrical damage
// ---------------------------------------------------------------------------
/datum/neural_monitor/shock
	name = "SHOCK MONITOR"

/datum/neural_monitor/shock/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_LIVING_ELECTROCUTE_ACT, PROC_REF(on_living_electrocuted))
	RegisterSignal(monitor_atom, COMSIG_LIVING_MINOR_SHOCK, PROC_REF(on_living_minor_shock))

/datum/neural_monitor/shock/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_LIVING_ELECTROCUTE_ACT)
	UnregisterSignal(monitor_atom, COMSIG_LIVING_MINOR_SHOCK)

/datum/neural_monitor/shock/proc/on_living_electrocuted(mob/living/L, shock_damage, source, siemens_coeff, flags)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.write_log("Electrocuted: [shock_damage] damage [siemens_coeff ? "(siemens: [siemens_coeff])" : ""]", "HEALTH")
	owner.write_data("SHOCK_DAMAGE", "[shock_damage]")
	owner.write_log("Electrical damage applied", "ALERT")

/datum/neural_monitor/shock/proc/on_living_minor_shock(mob/living/L)
	SIGNAL_HANDLER

	if(L != monitor_atom)
		return
	owner.warn_log("Minor shock received")
	owner.write_data("MINOR_SHOCK", "TRUE")

// ---------------------------------------------------------------------------
// NTnet Monitor - Tracks NTNET packets
// ---------------------------------------------------------------------------
/datum/neural_monitor/nt_net
	name = "NTNET MONITOR"

/datum/neural_monitor/nt_net/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_COMPONENT_NTNET_RECEIVE, PROC_REF(on_packet_received))

/datum/neural_monitor/nt_net/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_COMPONENT_NTNET_RECEIVE)

/datum/neural_monitor/nt_net/proc/on_packet_received(datum/source, datum/netdata/packet)
	SIGNAL_HANDLER

	if(!enabled || !packet || !islist(packet.data) || isnull(packet.data["data"]))
		return
	owner.write_data("NTPACKET", "[packet.data["data"]]", 5 SECONDS)

// ---------------------------------------------------------------------------
// Nanite Monitor - Tracks nanite status
// ---------------------------------------------------------------------------
/datum/neural_monitor/nanite
	name = "NANITE MONITOR"
	processing = TRUE

/datum/neural_monitor/nanite/process(delta_time)
	if(!..())
		return FALSE

	if(!SEND_SIGNAL(monitor_atom, COMSIG_HAS_NANITES))
		return FALSE

	var/volume = SEND_SIGNAL(monitor_atom, COMSIG_NANITE_GET_VOLUME)
	owner.write_data("NANITE VOLUME", "[volume]", 5 SECONDS)
	return TRUE

// ---------------------------------------------------------------------------
// Observers Monitor - Tracks who examine you
// ---------------------------------------------------------------------------
/datum/neural_monitor/observers
	name = "OBSERVERS MONITOR"
	var/icon/overlay_observer

/datum/neural_monitor/observers/New(...)
	. = ..()
	overlay_observer = new(icon='icons/effects/neural_interface_overlays.dmi', icon_state="eye")

/datum/neural_monitor/observers/Destroy(force, ...)
	overlay_observer = null
	. = ..()

/datum/neural_monitor/observers/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/neural_monitor/observers/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_PARENT_EXAMINE)

/datum/neural_monitor/observers/proc/on_examine(datum/source, mob/user)
	SIGNAL_HANDLER

	var/image/overlay = image(icon = overlay_observer)
	owner.write_image_data("\ref[user];OBSERVER", overlay, user, "", 3 SECONDS)

// ---------------------------------------------------------------------------
// Health Scan Monitor - Scan Health marked with you
// ---------------------------------------------------------------------------
/datum/neural_monitor/health_scan
	name = "HEALTH SCAN MONITOR"
	processing = TRUE
	var/icon/overlay_observer
	var/mob/living/carbon/target

/datum/neural_monitor/health_scan/New(...)
	. = ..()
	overlay_observer = icon(icon='icons/effects/neural_interface_overlays.dmi', icon_state="circle")

/datum/neural_monitor/health_scan/Destroy(force, ...)
	overlay_observer = null
	. = ..()

/datum/neural_monitor/health_scan/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE, PROC_REF(on_examine_target))

/datum/neural_monitor/health_scan/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE)

/datum/neural_monitor/health_scan/process(delta_time)
	if(!..())
		return FALSE

	var/image/overlay = image(icon = overlay_observer)
	owner.write_image_data("HEALTH_SCAN", overlay, target, get_data(), 1 SECONDS, 32, -5)

	return TRUE

/datum/neural_monitor/health_scan/proc/on_examine_target(datum/source, mob/user)
	SIGNAL_HANDLER

	if(!iscarbon(user))
		return

	if(user == target)
		target = null
		return

	target = user

	var/image/overlay = image(icon = overlay_observer)
	owner.write_image_data("HEALTH_SCAN", overlay, user, get_data(), 1 SECONDS, 32, -5)

/datum/neural_monitor/health_scan/proc/get_data()
	if(QDELETED(target))
		target = null
		return FALSE

	var/health_percent = target.health / target.maxHealth * 100
	var/oxy_loss = target.getOxyLoss()
	var/tox_loss = target.getToxLoss()
	var/fire_loss = target.getFireLoss()
	var/brute_loss = target.getBruteLoss()

	return "HEALTH:[health_percent]\nOXY:[oxy_loss]\nTOX:[tox_loss]\nBURN:[fire_loss]\nBRUTE:[brute_loss]"

// ---------------------------------------------------------------------------
// Cyborg Monitor - Tracks cyborg status when examined
// ---------------------------------------------------------------------------
/datum/neural_monitor/cyborg_scan
	name = "CYBORG MONITOR"
	processing = TRUE
	var/icon/overlay_borg
	var/mob/living/silicon/robot/borg_target

/datum/neural_monitor/cyborg_scan/New(...)
	. = ..()
	overlay_borg = new(icon = 'icons/effects/neural_interface_overlays.dmi', icon_state = "target")

/datum/neural_monitor/cyborg_scan/Destroy(force, ...)
	overlay_borg = null
	borg_target = null
	. = ..()

/datum/neural_monitor/cyborg_scan/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE, PROC_REF(on_examine_target))

/datum/neural_monitor/cyborg_scan/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE)

/datum/neural_monitor/cyborg_scan/process(delta_time)
	if(!..())
		return FALSE

	var/image/overlay = image(icon = overlay_borg)
	owner.write_image_data("CYBORG_SCAN", overlay, borg_target, get_data(), 1 SECONDS, 32, -5)

	return TRUE

/datum/neural_monitor/cyborg_scan/proc/on_examine_target(datum/source, mob/user)
	SIGNAL_HANDLER

	if(user == borg_target)
		borg_target = null
		return

	if(!ismob(user))
		return

	if(!istype(user, /mob/living/silicon/robot))
		return

	borg_target = user

	var/image/overlay = image(icon = overlay_borg)
	owner.write_image_data("CYBORG_SCAN", overlay, user, get_data(), 1 SECONDS, 32, -5)

/datum/neural_monitor/cyborg_scan/proc/get_data()
	if(QDELETED(borg_target))
		borg_target = null
		return FALSE

	if(!ismob(borg_target))
		borg_target = null
		return FALSE

	var/mob/living/silicon/robot/R = borg_target
	var/health_percent = R.health / R.maxHealth * 100

	var/damage_text = ""
	if(R.getBruteLoss() > 0)
		damage_text += "BR:[round(R.getBruteLoss())] "
	if(R.getFireLoss() > 0 || R.getToxLoss() > 0)
		damage_text += "BRN:[round(R.getFireLoss() + R.getToxLoss())] "

	var/stat_text = ""
	switch(R.stat)
		if(CONSCIOUS)
			stat_text = "ONLINE"
		if(UNCONSCIOUS)
			stat_text = "OFFLINE"
		if(DEAD)
			stat_text = "OFFLINE"

	var/cell_text = ""
	if(R.cell)
		cell_text = "[R.cell.charge]/[R.cell.maxcharge]"
	else
		cell_text = "NONE"

	var/module_type = "UNKNOWN"
	if(R.module)
		module_type = R.module.name

	return "MODULE:[module_type]\nHEALTH:[round(health_percent, 0.1)]%\nCELL:[cell_text]\nSTAT:[stat_text]\n[length(damage_text) > 0 ? "DAMAGE:[damage_text]" : ""]"

// ---------------------------------------------------------------------------
// Crime Monitor - Tracks criminal status and arrest articles
// ---------------------------------------------------------------------------
/datum/neural_monitor/crime
	name = "CRIME MONITOR"
	processing = TRUE
	var/mob/living/carbon/human/crime_target
	var/datum/data/record/crime_record
	var/list/crime_articles
	var/icon/overlay_sec

/datum/neural_monitor/crime/New(datum/component/neural_interface/owner_comp, atom/monitor_atom_p, source_p, ...)
	. = ..()
	overlay_sec = new(icon = 'icons/effects/neural_interface_overlays.dmi', icon_state = "circle")

/datum/neural_monitor/crime/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE, PROC_REF(on_examine_crime))

/datum/neural_monitor/crime/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_MOB_EXAMINATE)

/datum/neural_monitor/crime/process(delta_time)
	if(!..())
		return FALSE

	var/image/overlay = image(icon = overlay_sec)
	owner.write_image_data("\ref[crime_target]:CRIME_MONITOR", overlay, crime_target, get_data(), 1 SECONDS, 32, -5)

	return TRUE

/datum/neural_monitor/crime/proc/on_examine_crime(datum/source, mob/user)
	SIGNAL_HANDLER

	if(crime_target == user)
		crime_target = null
		return

	if(!ismob(user) || !ishuman(user))
		return

	crime_target = user

	var/image/overlay = image(icon = overlay_sec)
	owner.write_image_data("\ref[crime_target]:CRIME_MONITOR", overlay, crime_target, get_data(), 1 SECONDS, 32, -5)

/datum/neural_monitor/crime/proc/get_data()
	if(QDELETED(crime_target))
		crime_target = null
		crime_record = null
		crime_articles = null
		return FALSE

	if(!ismob(crime_target) || !ishuman(crime_target))
		crime_target = null
		crime_record = null
		crime_articles = null
		return FALSE

	var/mob/living/carbon/human/H = crime_target

	var/datum/data/record/R = GLOB.data_core.security_by_name[H.real_name]
	if(R)
		crime_record = R
		crime_articles = R.fields["mi_crim"]
		crime_articles += R.fields["ma_crim"]
	else
		crime_record = null
		crime_articles = null

	var/status = "НЕТ ЗАПИСИ"
	if(crime_record)
		status = crime_record.fields["criminal"]

	var/articles_text = "НЕТ СТАТЕЙ"
	if(crime_articles && length(crime_articles) > 0)
		var/list/articles = list()
		for(var/datum/data/crime/C in crime_articles)
			articles += "[C.crimeName]: [C.crimeDetails] (CENTCOM: [C.centcom_enforced]) - [C.penalties_incurred ? "Понес наказание" : "Не понес наказание"]"
		if(articles.len > 0)
			var/max_articles = min(articles.len, 5)
			for(var/i in 1 to max_articles)
				if(i == 1)
					articles_text = articles[i]
				else
					articles_text += "\n[articles[i]]"
			if(max_articles < articles.len)
				articles_text += "\n...и ещё [articles.len - max_articles]"

	return "STATUS:[status]\nARTICLES:[articles_text]"


// ---------------------------------------------------------------------------
// Integral Monitor - usage from visual integral signals
// ---------------------------------------------------------------------------
/datum/neural_monitor/integral_visual
	name = "INTEGRAL MONITOR"

/datum/neural_monitor/integral_visual/register_signals()
	if(!monitor_atom)
		return
	RegisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_LOG, PROC_REF(write_log))
	RegisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_DATA, PROC_REF(write_data))
	RegisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA, PROC_REF(write_image_data))

/datum/neural_monitor/integral_visual/unregister_signals()
	if(!monitor_atom)
		return
	UnregisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_LOG)
	UnregisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_DATA)
	UnregisterSignal(monitor_atom, COMSIG_NEURAL_INTERFACE_WRITE_IMAGE_DATA)

/datum/neural_monitor/integral_visual/proc/write_log(datum/source, text, key="LOG", color="#4ad1fa86", size=12, speed=0)
	var/list/arguments = args.Copy()
	arguments.Cut(1, 2)
	return owner.write_log(arglist(arguments))

/datum/neural_monitor/integral_visual/proc/write_data(datum/source, key, value, decay_duration=3 SECONDS, priority=0)
	var/list/arguments = args.Copy()
	arguments.Cut(1, 2)
	return owner.write_data(arglist(arguments))

/datum/neural_monitor/integral_visual/proc/write_image_data(datum/source, key, image/overlay, text, decay_duration=30 SECONDS, pixel_x_text = 0, pixel_y_text = 0, text_size=12)
	var/list/arguments = args.Copy()
	arguments.Cut(1, 2)
	return owner.write_image_data(arglist(arguments))
