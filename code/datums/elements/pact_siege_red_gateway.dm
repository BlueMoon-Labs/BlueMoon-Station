/// Applies / clears PACT siege red-channel visuals on the station gateway.
/datum/element/pact_siege_red_gateway/Attach(datum/target)
	if(!istype(target, /obj/machinery/gateway))
		return ELEMENT_INCOMPATIBLE
	. = ..()
	var/obj/machinery/gateway/G = target
	G.pact_siege_visual = GLOB.inteq_pact_siege?.gates_unlocked() ? "open" : "calibrating"
	G.update_appearance()

/datum/element/pact_siege_red_gateway/Detach(datum/target, force)
	. = ..()
	if(!istype(target, /obj/machinery/gateway))
		return
	var/obj/machinery/gateway/G = target
	G.pact_siege_visual = null
	G.update_appearance()

/datum/element/pact_siege_red_gateway/proc/sync_visual(obj/machinery/gateway/G)
	if(QDELETED(G))
		return
	G.pact_siege_visual = GLOB.inteq_pact_siege?.gates_unlocked() ? "open" : "calibrating"
	G.update_appearance()
