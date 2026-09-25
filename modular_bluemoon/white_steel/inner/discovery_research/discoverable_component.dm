/datum/component/discoverable
	dupe_mode = COMPONENT_DUPE_UNIQUE
	//Amount of discovery points awarded when researched.
	var/scanned = FALSE
	var/unique = FALSE
	var/point_reward = 0

/datum/component/discoverable/Initialize(_point_reward, _unique = FALSE)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/examine)
	RegisterSignal(parent, COMSIG_CLICK, .proc/tryScan)

	point_reward = _point_reward
	unique = _unique

/datum/component/discoverable/proc/tryScan(datum/source, location, control, params, mob/user)
	SIGNAL_HANDLER
	if(!isliving(user))
		return
	var/mob/living/L = user
	if(istype(L.get_active_held_item(), /obj/item/discovery_scanner))
		INVOKE_ASYNC(L.get_active_held_item(), /obj/item/discovery_scanner.proc/begin_scanning, user, src)

/datum/component/discoverable/proc/examine(datum/source, mob/user, atom/thing)
	SIGNAL_HANDLER
	if(!user.research_scanner)
		return
	to_chat(user, span_notice("Научная ценность обнаружена."))
	to_chat(user, span_notice("Сканирование: [scanned ? "Истина" : "Ложь"]."))
	to_chat(user, span_notice("Награда: [point_reward]."))

/datum/component/discoverable/proc/discovery_scan(datum/techweb/linked_techweb, mob/user)
	//Already scanned our atom.
	var/atom/A = parent
	if(scanned)
		to_chat(user, span_warning("[A] уже было проанализировано."))
		return
	//Already scanned another of this type.
	if(GLOB.scanned_atom_types[A.type] && !unique)
		to_chat(user, span_warning("Мы уже знаем про тип [A]."))
		return
	scanned = TRUE
	linked_techweb.research_points[TECHWEB_POINT_TYPE_GENERIC] += point_reward
	GLOB.scanned_atom_types[A.type] = TRUE
	playsound(user, 'sound/machines/terminal_success.ogg', 60)
	to_chat(user, span_notice("Новый тип отсканирован, [point_reward] очков было получено."))
	pulse_effect(get_turf(A), 4)
