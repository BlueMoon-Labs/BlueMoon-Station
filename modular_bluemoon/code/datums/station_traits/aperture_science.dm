/// Aperture Science station takeover — GLaDOS AI and Portal sentry turrets.
/datum/station_trait/aperture_science
	name = "Aperture Science"
	trait_type = STATION_TRAIT_NEUTRAL
	weight = 4
	show_in_report = TRUE
	report_message = "Станция была реквизирована Aperture Science. ИИ заменён на GLaDOS, турели — на испытательные образцы."
	trait_to_give = STATION_TRAIT_APERTURE_SCIENCE
	blacklist = list(/datum/station_trait/unique_ai)

/datum/station_trait/aperture_science/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_roundstart_spawn))
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN, PROC_REF(on_job_latejoin_spawn))

/datum/station_trait/aperture_science/Destroy()
	UnregisterSignal(SSdcs, list(COMSIG_GLOB_JOB_AFTER_SPAWN, COMSIG_GLOB_JOB_AFTER_LATEJOIN_SPAWN))
	return ..()
/datum/station_trait/aperture_science/on_round_start()
	. = ..()
	for(var/obj/machinery/porta_turret/turret in GLOB.machines)
		apply_aperture_turret_skin(turret)
	for(var/obj/structure/ai_core/core as anything in world)
		apply_glados_ai_core_skin(core)
	for(var/mob/living/silicon/ai/AI in GLOB.ai_list)
		apply_glados_theme(AI)

/datum/station_trait/aperture_science/proc/on_job_roundstart_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	schedule_glados_theme(job, spawned)

/datum/station_trait/aperture_science/proc/on_job_latejoin_spawn(datum/source, datum/job/job, mob/living/spawned)
	SIGNAL_HANDLER
	schedule_glados_theme(job, spawned)

/datum/station_trait/aperture_science/proc/schedule_glados_theme(datum/job/job, mob/living/spawned)
	if(job?.type != /datum/job/ai)
		return
	var/mob/living/silicon/ai/AI = spawned
	if(!istype(AI))
		return
	addtimer(CALLBACK(AI, TYPE_PROC_REF(/mob/living/silicon/ai, deferred_aperture_glados_theme)), 1, TIMER_UNIQUE)
