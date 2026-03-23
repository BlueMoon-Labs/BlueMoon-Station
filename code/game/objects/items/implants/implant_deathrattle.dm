/datum/deathrattle_group
	var/name
	var/list/datum/weakref/implant_refs = list()

/datum/deathrattle_group/New()
	// Give the group a unique name for debugging, and possible future
	// use for making custom linked groups.
	name = "[rand(100,999)] [pick(GLOB.phonetic_alphabet)]"

/datum/deathrattle_group/proc/rattle(obj/item/implant/deathrattle/origin, mob/living/owner)
	var/name = owner.mind ? owner.mind.name : owner.real_name
	var/turf/T = get_turf(owner)

	for(var/r in implant_refs)
		var/datum/weakref/R = r

		var/obj/item/implant/deathrattle/implant = R.resolve()
		if(!implant || implant == origin)
			continue

		// Not all the implants may be actually implanted in people.
		if(!implant.imp_in)
			continue


		// Deliberately the same message framing as nanite message + ghost deathrattle
		var/mob/living/recipient = implant.imp_in
		to_chat(recipient, "<i>Вы слышите странный механический голос в голове...</i>\"<span class='robot'><b>[name]</b> был[owner.ru_a()] убит[owner.ru_a()] по координатам: [AREACOORD(T)].</span>\"")
		SEND_SOUND(recipient, pick(
		'sound/items/knell1.ogg',
		'sound/items/knell2.ogg',
		'sound/items/knell3.ogg',
		'sound/items/knell4.ogg',
		))

/datum/deathrattle_group/proc/register(obj/item/implant/deathrattle/implant)
	implant.group = src
	implant_refs += WEAKREF(implant)


/obj/item/implant/deathrattle
	name = "deathrattle implant"
	desc = "Hope no one else dies, prepare for when they do."

	activated = FALSE

	var/datum/deathrattle_group/group = null

/obj/item/implant/deathrattle/Destroy()
	if(imp_in)
		UnregisterSignal(imp_in, COMSIG_LIVING_PREDEATH)
	group = null
	return ..()

/obj/item/implant/deathrattle/can_be_implanted_in(mob/living/target)
	// Can be implanted in anything that's a mob. Syndicate cyborgs, talking fish, humans...
	return TRUE

/obj/item/implant/deathrattle/proc/on_predeath(datum/source, gibbed)
	SIGNAL_HANDLER

	if(group)
		group.rattle(origin = src, owner = source)

/obj/item/implant/deathrattle/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(.)
		RegisterSignal(target, COMSIG_LIVING_PREDEATH, PROC_REF(on_predeath))

		if(!group)
			to_chat(target, "<i>Вы слышите странный механический голос в голове...</i> \"<span class='robot'>Внимание: Не выявлены другие подключенные импланты.</span>\"")

/obj/item/implant/deathrattle/removed(mob/living/source, silent = FALSE, special = 0)
	UnregisterSignal(source, COMSIG_LIVING_PREDEATH)
	return ..()

/obj/item/implantcase/deathrattle
	name = "implant case - 'Deathrattle'"
	desc = "A glass case containing a deathrattle implant."
	imp_type = /obj/item/implant/deathrattle

GLOBAL_DATUM_INIT(centcom_deathrattle_group, /datum/deathrattle_group, new)

/obj/item/implant/deathrattle/centcom
	name = "centcom deathrattle implant"
	desc = "Hope no one else dies, prepare for when they do"

/obj/item/implant/deathrattle/centcom/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	group = GLOB.centcom_deathrattle_group
	group.register(src)

/obj/item/implant/death_alert
	name = "death alert implant"
	desc = "Hope no one else dies, prepare for when they do"
	var/obj/item/radio/radio = null

/obj/item/implant/death_alert/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(!.)
		return

	if(radio)
		radio.forceMove(target)
	else
		radio = new(target)
		// almost like an internal headset, but without the
		// "must be in ears to hear" restriction.
		radio.name = "death alert system"
		radio.subspace_transmission = TRUE
		radio.canhear_range = 0


	RegisterSignal(target, COMSIG_LIVING_PREDEATH, PROC_REF(on_predeath))

/obj/item/implant/death_alert/removed(mob/living/source, silent = FALSE, special = 0)
	UnregisterSignal(source, COMSIG_LIVING_PREDEATH)
	return ..()

/obj/item/implant/death_alert/Destroy()
	if(imp_in)
		UnregisterSignal(imp_in, COMSIG_LIVING_PREDEATH)
	QDEL_NULL(radio)
	return ..()

/obj/item/implant/death_alert/proc/on_predeath(datum/source, gibbed)
	SIGNAL_HANDLER
	var/mob/living/owner = source
	var/turf/T = get_turf(owner)

	radio.talk_into(src, "[owner.real_name] был[owner.ru_a()] убит[owner.ru_a()] по координатам: [AREACOORD(T)] ")

/obj/item/implantcase/death_alert
	name = "implant case - 'death alert'"
	desc = "A glass case containing a death alert implant."
	imp_type = /obj/item/implant/death_alert

/obj/item/implanter/death_alert
	name = "implanter (death alert)"
	imp_type = /obj/item/implant/death_alert

GLOBAL_DATUM_INIT(deepspacecrew_deathrattle_group, /datum/deathrattle_group, new)

/obj/item/implant/deathrattle/deepspacecrew
	name = "deep space crew deathrattle implant"
	desc = "Hope no one else dies, prepare for when they do"

/obj/item/implant/deathrattle/deepspacecrew/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	group = GLOB.deepspacecrew_deathrattle_group
	group.register(src)
