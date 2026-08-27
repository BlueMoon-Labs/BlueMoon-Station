/obj/machinery/door/poddoor/shutters/window/armory
	var/open_at_level = SEC_LEVEL_GREEN
	var/listen_to_security = TRUE
	max_integrity = 1000

/obj/machinery/door/poddoor/shutters/window/armory/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL || . == INITIALIZE_HINT_QDEL_FORCE)
		return .
	if(!listen_to_security)
		return
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door/poddoor/shutters/window/armory/LateInitialize()
	. = ..()
	if(!is_station_level(z))
		return
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(on_security_level_changed))
	if(GLOB.security_level >= open_at_level)
		INVOKE_ASYNC(src, PROC_REF(open))

/obj/machinery/door/poddoor/shutters/window/armory/Destroy()
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)
	return ..()

/obj/machinery/door/poddoor/shutters/window/armory/proc/on_security_level_changed(datum/source, level)
	SIGNAL_HANDLER
	if(isnull(level))
		level = GLOB.security_level
	if(level >= open_at_level && density)
		INVOKE_ASYNC(src, PROC_REF(open))
	else if(level < open_at_level && !density)
		INVOKE_ASYNC(src, PROC_REF(close))

/obj/machinery/door/poddoor/shutters/window/armory/warden
	name = "Blue Alert Shutters"
	open_at_level = SEC_LEVEL_BLUE
	id = "warden_shutters"

/obj/machinery/door/poddoor/shutters/window/armory/officers
	name = "Amber Alert Shutters"
	open_at_level = SEC_LEVEL_AMBER
	id = "officers_shutters"

// ─── Кнопки ────────────────────────────────────────────────────────────────

/obj/machinery/button/door/armory
	name = "armory shutter button"
	desc = "Панель управления ставнями арсенала."
	skin = "doorctrl"
	req_access = list(ACCESS_CAPTAIN, ACCESS_HOS)

/obj/machinery/button/door/armory/warden
	name = "Armory Blue Alert Shutter Button"
	id = "warden_shutters"

/obj/machinery/button/door/armory/officers
	name = "Armory Amber Alert Shutter Button"
	id = "officers_shutters"
