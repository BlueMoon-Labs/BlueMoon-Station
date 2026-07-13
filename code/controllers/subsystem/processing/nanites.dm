PROCESSING_SUBSYSTEM_DEF(nanites)
	name = "Nanites"
	flags = SS_BACKGROUND|SS_POST_FIRE_TIMING|SS_NO_INIT
	wait = 1 SECONDS

	var/list/datum/nanite_cloud_backup/cloud_backups = list()
	var/list/mob/living/nanite_monitored_mobs = list()
	var/list/mob/living/nanite_host_mobs = list()
	var/list/datum/nanite_program/relay/nanite_relays = list()
	var/neural_network_count = 0

/datum/controller/subsystem/processing/nanites/proc/check_hardware(datum/nanite_cloud_backup/backup)
	if(QDELETED(backup.storage) || (backup.storage.machine_stat & (NOPOWER|BROKEN)))
		return FALSE
	return TRUE

/datum/controller/subsystem/processing/nanites/proc/get_cloud_backup(cloud_id, force = FALSE)
	for(var/I in cloud_backups)
		var/datum/nanite_cloud_backup/backup = I
		if(!force && !check_hardware(backup))
			return
		if(backup.cloud_id == cloud_id)
			return backup

/datum/controller/subsystem/processing/nanites/proc/sync_hosts(cloud_id)
	for(var/mob/living/host in nanite_host_mobs)
		var/cloud = SEND_SIGNAL(host, COMSIG_NANITE_GET_CLOUD)
		if(cloud && cloud == cloud_id)
			SEND_SIGNAL(host, COMSIG_NANITE_SET_NEED_SYNC, cloud_id)
