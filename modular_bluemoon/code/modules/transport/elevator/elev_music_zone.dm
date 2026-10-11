GLOBAL_LIST_EMPTY(elevator_music)

/obj/effect/abstract/elevator_music_zone
	name = "elevator music speaker"
	desc = "Вы этого не видите: динамик закреплён на крыше кабины."
	anchored = TRUE
	invisibility = INVISIBILITY_MAXIMUM // Setting this to ABSTRACT means it isn't moved by the lift
	icon = 'icons/obj/musician.dmi'
	icon_state = "piano"
	/// What specific_transport_id do we link with?
	var/linked_elevator_id = ""
	/// Radius around this map helper in which to play the sound
	var/range = 1
	/// Sound loop type to use
	var/soundloop_type = /datum/looping_sound/local_forecast
	/// Are we currently playing sounds?
	var/enabled = TRUE
	/// Assoc list of mobs to sound loops currently playing
	var/list/tracked_mobs = list()
	var/static/list/range_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_EXITED = PROC_REF(on_exited),
	)

/obj/effect/abstract/elevator_music_zone/Initialize(mapload)
	. = ..()
	if(!linked_elevator_id)
		log_mapping("No elevator ID for elevator music provided at [AREACOORD(src)].")
		return INITIALIZE_HINT_QDEL

	GLOB.elevator_music[linked_elevator_id] = src
	AddComponent(/datum/component/connect_range, src, range_connections, range, FALSE)

/obj/effect/abstract/elevator_music_zone/Destroy(force)
	if(GLOB.elevator_music[linked_elevator_id] == src)
		GLOB.elevator_music -= linked_elevator_id
	QDEL_LIST_ASSOC_VAL(tracked_mobs)
	return ..()

/obj/effect/abstract/elevator_music_zone/proc/link_to_panel(atom/elevator_panel)
	RegisterSignal(elevator_panel, COMSIG_MACHINERY_POWER_RESTORED, PROC_REF(on_panel_powered))
	RegisterSignal(elevator_panel, COMSIG_MACHINERY_POWER_LOST, PROC_REF(on_panel_depowered))
	RegisterSignal(elevator_panel, COMSIG_PARENT_QDELETING, PROC_REF(on_panel_destroyed))

/// Start sound loops when power is restored
/obj/effect/abstract/elevator_music_zone/proc/on_panel_powered(datum/source)
	SIGNAL_HANDLER
	enabled = TRUE
	for(var/mob/listener as anything in tracked_mobs)
		var/datum/looping_sound/loop = tracked_mobs[listener]
		loop?.start()

/// Stop sound loops if power is lost
/obj/effect/abstract/elevator_music_zone/proc/on_panel_depowered(datum/source)
	SIGNAL_HANDLER
	enabled = FALSE
	for(var/mob/listener as anything in tracked_mobs)
		var/datum/looping_sound/loop = tracked_mobs[listener]
		loop?.stop()

/// Die if panel is destroyed, although currently they are invincible
/obj/effect/abstract/elevator_music_zone/proc/on_panel_destroyed(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/effect/abstract/elevator_music_zone/proc/on_entered(turf/source, mob/entered)
	SIGNAL_HANDLER
	if(!istype(entered) || !entered.mind || (entered in tracked_mobs))
		return

	if(entered.client?.prefs && (entered.client.prefs.toggles & SOUND_AMBIENCE))
		tracked_mobs[entered] = new soundloop_type(entered, enabled, TRUE)
	else
		tracked_mobs[entered] = null
	RegisterSignal(entered, COMSIG_PARENT_QDELETING, PROC_REF(mob_destroyed))

/obj/effect/abstract/elevator_music_zone/proc/on_exited(turf/source, mob/exited)
	SIGNAL_HANDLER
	if(!(exited in tracked_mobs))
		return
	if(get_dist(src, exited) <= range)
		return
	qdel(tracked_mobs[exited])
	tracked_mobs -= exited
	UnregisterSignal(exited, COMSIG_PARENT_QDELETING)

/// Remove references on mob deletion
/obj/effect/abstract/elevator_music_zone/proc/mob_destroyed(mob/former_mob)
	SIGNAL_HANDLER
	if(former_mob in tracked_mobs)
		qdel(tracked_mobs[former_mob])
		tracked_mobs -= former_mob

/datum/looping_sound/local_forecast
	mid_sounds = list('modular_bluemoon/sound/music/elevator/robocop-short.ogg' = 1)
	mid_length = 61 SECONDS
	volume = 20
	vary = FALSE
	direct = TRUE

/datum/looping_sound/local_forecast/play(soundfile, volume_override)
	if(!parent)
		return
	var/sound/music = sound(soundfile)
	music.channel = CHANNEL_ELEVATOR
	music.volume = volume_override || volume
	SEND_SOUND(parent, music)

/datum/looping_sound/local_forecast/stop(null_parent)
	if(parent && timerid)
		var/sound/silence = sound(null)
		silence.channel = CHANNEL_ELEVATOR
		SEND_SOUND(parent, silence)
	return ..()
