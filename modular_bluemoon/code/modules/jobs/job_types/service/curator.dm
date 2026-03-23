/proc/_iscuratorjob(mob/curator)
	var/datum/job/curatorcheck = SSjob.GetJob(curator.job)
	return istype(curatorcheck, /datum/job/curator)
