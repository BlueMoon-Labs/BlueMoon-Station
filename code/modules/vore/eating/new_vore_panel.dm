#define STATE_UNSAVED_CHANGES (1 << 1)
#define STATE_SHOW_PICTURES (1 << 2)

/datum/vore_panel_ui
	var/mob/living/host

	var/states = NONE

	var/static/list/local_icon_cashe

/datum/vore_panel_ui/New(mob/living/new_host)
	if(istype(new_host))
		host = new_host
	. = ..()

/datum/vore_panel_ui/Destroy()
	host = null
	. = ..()

/datum/vore_panel_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VorePanel", "Vore Panel")
		ui.open()

/datum/vore_panel_ui/ui_host(mob/user)
	return host

/datum/vore_panel_ui/ui_state(mob/user)
	return GLOB.ui_vorepanel_state

/datum/vore_panel_ui/proc/get_key_for_atom(atom/target)
	return "\ref[target][target.name][target.type]"

/datum/vore_panel_ui/proc/get_or_cashe_icon(atom/target)
	LAZYINITLIST(local_icon_cashe)
	var/key
	if(isobj(target))
		key = "[target.type][target.icon_state]"
	else if(ismob(target))
		var/mob/mob = target
		key = "\ref[target][mob.real_name]"

	if(local_icon_cashe?[key])
		. = local_icon_cashe[key]
	else
		. = icon2base64(getFlatIcon(target,defdir=SOUTH,no_anim=TRUE))
		local_icon_cashe[key] = .

/*
	belly_contents:
		name : string
		health_percent : number
		stat : number
		absorbed : bool/number
		outside : bool/number
		icon : string

*/
/datum/vore_panel_ui/proc/get_belly_contents(obj/belly/inside_belly)
	var/list/belly_contents = list()

	for(var/atom/movable/prey_atom in inside_belly.contents)
		var/list/info = list()

		info["name"] = prey_atom
		if(isobj(prey_atom))
			var/obj/atom_obj = prey_atom
			info["health_percent"] = round((atom_obj.obj_integrity / atom_obj.max_integrity) * 100)
		else if(isliving(prey_atom))
			var/mob/living/atom_living = prey_atom
			info["health_percent"] = round((atom_living.health / atom_living.maxHealth) * 100)
		else
			info["health_percent"] = 100

		if(isliving(prey_atom))
			var/mob/living/atom_mob = prey_atom
			info["stat"] = atom_mob.stat
			if(atom_mob.vore_flags & ABSORBED)
				info["absorbed"] = TRUE
			else
				info["absorbed"] = FALSE
		else
			info["stat"] = 0
			info["absorbed"] = FALSE

		info["outside"] = inside_belly.owner == host ? TRUE : FALSE
		info["icon"] = states & STATE_SHOW_PICTURES ? get_or_cashe_icon(prey_atom) : ""

		belly_contents += info

	return belly_contents

/*
	pred_belly:
		belly_name : string
		belly_mode : string
		desc : string
		pred : string
		ref : string
		contents : belly_contents[]

*/

/datum/vore_panel_ui/proc/try_get_pred_belly_data()
	var/list/inside = list()
	if(!isbelly(host.loc))
		return inside

	var/obj/belly/pred_belly = host.loc

	inside["belly_name"] 	= pred_belly.name
	inside["belly_mode"] 	= pred_belly.digest_mode
	inside["desc"] 			= pred_belly.desc || null
	inside["pred"]			= pred_belly.owner
	inside["ref"]			= "\ref[pred_belly]"
	inside["contents"]		= get_belly_contents(pred_belly)

	return inside

/*
	description_my_belly:
		struggle_messages_outside : string[]
		struggle_messages_inside : string[]
*/

/datum/vore_panel_ui/proc/get_my_belly_desc(obj/belly/my_belly)
	var/list/description_my_belly = list()

	description_my_belly[""]



/*
	my_belly:
		digest_mode : string
		belly_flags : numberц
		desc : string
		pred : string
		ref : string
		contents : belly_contents[]
		more_desc : description_my_belly


*/

/datum/vore_panel_ui/proc/get_my_belly_data(obj/belly/me_belly)
	var/list/my_belly = list()

	my_belly[""]

/datum/vore_panel_ui/proc/build_data()
	var/list/data = list()
	if(!host)
		return data

	data["stateUI"] = states
	data["host_vore_flags"] = host.vore_flags
	data["inside"] = try_get_pred_belly_data()
