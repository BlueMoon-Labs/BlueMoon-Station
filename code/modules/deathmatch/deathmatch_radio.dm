// Team callout implants for TDM.
//
// Modelled on the security hailer: one action button, one radial menu, three
// fixed phrases with the current callout zone filled in. Unlike a station
// headset the radio is issued by the lobby on a frequency unique to that match,
// so two TDM lobbies can run at once without hearing each other, and Terrorists
// can never hear Counter-Terrorists (or the other way round).
//
// The zone name comes from the area the wearer is standing in, not from a
// hardcoded list of coordinates: see the /area/deathmatch/tdm/de_dust2/* types
// in deathmatch_mapping.dm.

/datum/action/item_action/deathmatch_callout
	name = "Командная рация"
	desc = "Отправить союзникам сообщение с названием текущей зоны."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "dispatch"

/obj/item/implant/radio/deathmatch
	name = "TDM team radio implant"
	desc = "Внутренняя рация с тремя быстрыми сообщениями о зоне."
	actions_types = list(/datum/action/item_action/deathmatch_callout)
	/// Set by the lobby before implanting. 0 is only a safety fallback.
	var/frequency = 0
	var/callout_cooldown = 2 SECONDS
	var/last_callout = 0

/obj/item/implant/radio/deathmatch/implant(mob/living/target, mob/user, silent = FALSE)
	. = ..()
	if(!.)
		return
	if(!istype(radio))
		return
	if(frequency)
		radio.set_frequency(frequency)
	radio.freqlock = TRUE
	radio.listening = TRUE
	radio.canhear_range = 0
	radio.name = "TDM team radio"

/obj/item/implant/radio/deathmatch/ui_action_click(mob/user, action)
	report(user)

/obj/item/implant/radio/deathmatch/proc/report(mob/living/user)
	if(!istype(user) || isnull(radio))
		return FALSE
	if(world.time < last_callout + callout_cooldown)
		to_chat(user, span_warning("Рация ещё перезаряжается."))
		return FALSE

	var/zone = zone_name(user)
	var/list/options = list()
	var/image/callout_icon = image(icon = 'icons/mob/actions/actions.dmi', icon_state = "dispatch")
	options["Помогите пушить [zone]"] = callout_icon
	options["Враг на [zone]"] = callout_icon
	options["Иду на [zone]"] = callout_icon

	var/selection = show_radial_menu(user, user, options, radius = 36)
	if(!selection)
		return FALSE
	last_callout = world.time
	radio.talk_into(user, selection)
	return TRUE

/// The area's name is the callout shown in chat. replacetext() is a safety net
/// for an area named from a type path rather than one of the callout types.
/obj/item/implant/radio/deathmatch/proc/zone_name(atom/movable/user)
	var/zone = get_area_name(user)
	if(!zone)
		return "неизвестной зоне"
	return replacetext(zone, "_", " ")

/obj/item/implant/radio/deathmatch/terror
	name = "Terrorist radio implant"
	desc = "Командная рация террористов: союзники слышат только вас."

/obj/item/implant/radio/deathmatch/counter_terror
	name = "Counter-Terrorist radio implant"
	desc = "Командная рация контр-террористов: союзники слышат только вас."
