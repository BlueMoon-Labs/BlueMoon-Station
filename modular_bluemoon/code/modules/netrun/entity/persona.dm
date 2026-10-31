/// An identity owns its presentation; definitions and network privileges never depend on it.
/datum/netrun_persona
	var/avatar = "cipher"
	var/accent = "cyan"
	var/tagline = ""
	var/alias = ""
	var/theme = "ion"
	var/datum/weakref/identity_ref

/datum/netrun_persona/New(datum/identity)
	. = ..()
	bind_identity(identity)

/datum/netrun_persona/Destroy()
	var/datum/identity = identity_ref?.resolve()
	if(identity)
		UnregisterSignal(identity, COMSIG_PARENT_QDELETING)
		if(istype(identity, /datum/mind))
			var/datum/mind/identity_mind = identity
			if(identity_mind.netrun_persona == src)
				identity_mind.netrun_persona = null
	identity_ref = null
	return ..()

/datum/netrun_persona/proc/bind_identity(datum/identity)
	var/datum/previous = identity_ref?.resolve()
	if(previous)
		UnregisterSignal(previous, COMSIG_PARENT_QDELETING)
	identity_ref = QDELETED(identity) ? null : WEAKREF(identity)
	if(identity_ref)
		RegisterSignal(identity, COMSIG_PARENT_QDELETING, PROC_REF(on_identity_deleted))

/datum/netrun_persona/proc/on_identity_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_persona/proc/copy_style(datum/netrun_persona/other)
	if(QDELETED(other))
		return
	avatar = other.avatar
	accent = other.accent
	tagline = other.tagline
	alias = other.alias
	theme = other.theme

/// Curated assets cannot load external URLs, HTML, shaders or arbitrary styles.
/proc/netrun_avatar_options()
	return list(
		list("id" = "cipher", "name" = "Шифр", "icon" = "fingerprint"),
		list("id" = "ghost", "name" = "Призрак", "icon" = "ghost"),
		list("id" = "moth", "name" = "Мотылёк", "icon" = "feather-pointed"),
		list("id" = "fox", "name" = "Лис", "icon" = "cat"),
		list("id" = "eye", "name" = "Око", "icon" = "eye"),
		list("id" = "orb", "name" = "Сфера", "icon" = "atom"),
	)

/proc/netrun_accent_options()
	return list(
		list("id" = "cyan", "name" = "Лёд", "color" = "#72ddea"),
		list("id" = "mint", "name" = "Мята", "color" = "#77d9ad"),
		list("id" = "amber", "name" = "Янтарь", "color" = "#f5c477"),
		list("id" = "rose", "name" = "Роза", "color" = "#eb9ac4"),
		list("id" = "violet", "name" = "Ирис", "color" = "#b7a0ff"),
		list("id" = "silver", "name" = "Серебро", "color" = "#c9d4e0"),
	)

/proc/netrun_theme_ids()
	return list("ion", "phosphor", "amber", "noir", "synthwave")

/proc/netrun_option_valid(id, list/options)
	if(!istext(id))
		return FALSE
	for(var/list/entry as anything in options)
		if(entry["id"] == id)
			return TRUE
	return FALSE

/datum/netrun_persona/proc/ui_payload(include_options = TRUE)
	. = list("avatar" = avatar, "accent" = accent, "tagline" = tagline, "alias" = alias, "theme" = theme)
	if(include_options)
		.["options"] = list("avatars" = netrun_avatar_options(), "accents" = netrun_accent_options(), "themes" = netrun_theme_ids())

/// A mind carries its style across dives and physical clients, but never carries routing grants.
/datum/mind
	var/datum/netrun_persona/netrun_persona
	var/netrun_ui_theme = "ion"

/mob/camera/netrun_entity
	var/datum/netrun_persona/persona

/mob/camera/netrun_entity/proc/get_persona()
	RETURN_TYPE(/datum/netrun_persona)
	if(QDELETED(persona))
		persona = new(src)
	var/datum/identity = persona.identity_ref?.resolve()
	if(istype(identity, /datum/mind) && identity != mind)
		// An abandoned avatar keeps a snapshot, not write access to its former player's profile.
		var/datum/netrun_persona/previous = persona
		persona = new(src)
		persona.copy_style(previous)
	if(!QDELETED(mind))
		bind_persona(mind)
	return persona

/mob/camera/netrun_entity/proc/bind_persona(datum/mind/identity)
	if(QDELETED(identity))
		return
	if(QDELETED(persona))
		persona = new(src)
	var/datum/previous_identity = persona.identity_ref?.resolve()
	if(istype(previous_identity, /datum/mind) && previous_identity != identity)
		// A new mind can arrive before any UI read notices that the previous one left.
		// Never rebind the departed mind's owned profile, even on this direct signal path.
		var/datum/netrun_persona/previous_profile = persona
		persona = new(src)
		persona.copy_style(previous_profile)
	if(persona == identity.netrun_persona && persona.identity_ref?.resolve() == identity)
		return
	if(QDELETED(identity.netrun_persona))
		identity.netrun_persona = persona
		persona.bind_identity(identity)
		persona.theme = identity.netrun_ui_theme
	else if(persona != identity.netrun_persona)
		if(persona.identity_ref?.resolve() == src)
			qdel(persona)
		persona = identity.netrun_persona
	if(length(persona.alias))
		set_net_name(persona.alias)

/mob/camera/netrun_entity/proc/on_persona_mind_changed(datum/source)
	SIGNAL_HANDLER
	bind_persona(mind)
	console?.invalidate_ui()

/mob/camera/netrun_entity/proc/persona_changed()
	host_node?.notify_changed(NETRUN_CHANGED_OCCUPANTS)
	console?.invalidate_ui()

/mob/camera/netrun_entity/proc/rename_persona(new_name)
	if(!istext(new_name) || length_char(new_name) > 42)
		return FALSE
	new_name = reject_bad_name(new_name, allow_numbers = TRUE)
	if(!new_name)
		return FALSE
	var/datum/netrun_persona/profile = get_persona()
	profile.alias = new_name
	set_net_name(new_name)
	persona_changed()
	return TRUE

/datum/netrun_console
	/// Mindless clients retain their theme for the lifetime of this console only.
	var/ui_theme = "ion"

/datum/netrun_console/proc/theme_id(mob/user = operator)
	if(istype(host, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = host
		return entity.get_persona().theme
	if(!QDELETED(user?.mind) && (user.mind.netrun_ui_theme in netrun_theme_ids()))
		return user.mind.netrun_ui_theme
	return (ui_theme in netrun_theme_ids()) ? ui_theme : "ion"

/datum/netrun_console/proc/cosmetic_user(mob/user)
	if(QDELETED(user) || user != operator)
		return FALSE
	if(istype(host, /mob/camera/netrun_entity))
		return host == user
	if(istype(host, /obj/item/organ/cyberimp/brain/netlink))
		var/obj/item/organ/cyberimp/brain/netlink/implant = host
		return implant.owner == user
	if(ismob(host))
		return host == user
	return TRUE

/datum/netrun_console/proc/set_ui_theme(id, mob/user)
	if(!cosmetic_user(user) || !istext(id) || !(id in netrun_theme_ids()))
		return FALSE
	ui_theme = id
	if(!QDELETED(user.mind))
		user.mind.netrun_ui_theme = id
		if(!QDELETED(user.mind.netrun_persona))
			user.mind.netrun_persona.theme = id
	if(istype(host, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = host
		entity.get_persona().theme = id
	for(var/datum/netrun_console/client as anything in SSnetrun.consoles)
		if(client == src || client.operator == user)
			client.invalidate_ui()
	return TRUE

/// Validate the complete patch first: one invalid field must not partly change an identity.
/datum/netrun_console/proc/update_persona(list/params, mob/user)
	if(!cosmetic_user(user) || !istype(host, /mob/camera/netrun_entity) || !islist(params))
		return FALSE
	var/mob/camera/netrun_entity/entity = host
	var/datum/netrun_persona/profile = entity.get_persona()
	var/new_avatar = profile.avatar
	var/new_accent = profile.accent
	var/new_tagline = profile.tagline
	var/new_name
	if("avatar" in params)
		new_avatar = params["avatar"]
		if(!netrun_option_valid(new_avatar, netrun_avatar_options()))
			return FALSE
	if("accent" in params)
		new_accent = params["accent"]
		if(!netrun_option_valid(new_accent, netrun_accent_options()))
			return FALSE
	if("tagline" in params)
		if(!istext(params["tagline"]) || length_char(params["tagline"]) > 80)
			return FALSE
		new_tagline = trim(strip_html_tags(params["tagline"], TRUE))
	if("name" in params)
		if(!istext(params["name"]) || length_char(params["name"]) > 42)
			return FALSE
		new_name = reject_bad_name(params["name"], allow_numbers = TRUE)
		if(!new_name)
			return FALSE
	profile.avatar = new_avatar
	profile.accent = new_accent
	profile.tagline = new_tagline
	if(new_name)
		profile.alias = new_name
		entity.set_net_name(new_name)
	entity.persona_changed()
	return TRUE

/datum/component/netrun_combatant/entity/ui_entry()
	. = ..()
	var/mob/camera/netrun_entity/entity = parent
	.["persona"] = entity.get_persona().ui_payload(FALSE)
