/// One packet is one budgeted task. A yielding native callback does not hold the worker.
/datum/netrun_task/delivery
	delivery = TRUE

/datum/netrun_task/delivery/execute(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_delivery/packet = target()
	if(QDELETED(packet))
		return FALSE
	packet.deliver()
	return TRUE

/datum/netrun_task/request_delivery
	parent_type = /datum/netrun_task/delivery
	kind = "request_delivery"

/datum/netrun_task/machine_delivery
	parent_type = /datum/netrun_task/delivery
	kind = "machine_delivery"
