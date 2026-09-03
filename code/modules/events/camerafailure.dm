/datum/round_event_control/camera_failure
	name = "Camera Failure"
	typepath = /datum/round_event/camera_failure
	weight = 30
	max_occurrences = 25
	alert_observers = TRUE
	category = EVENT_CATEGORY_ENGINEERING
	severity = DIRECTOR_SEVERITY_MINOR

/datum/round_event/camera_failure
	fakeable = FALSE

/datum/round_event/camera_failure/start()
	var/iterations = 1
	var/list/cameras = GLOB.cameranet.cameras.Copy()
	while(prob(round(100/iterations)))
		var/obj/machinery/camera/C = pick_n_take(cameras)
		if (!C)
			break
		if (!("ss13" in C.network))
			continue
		if(C.status)
			C.toggle_cam(null, 0)
		iterations *= 2.5
