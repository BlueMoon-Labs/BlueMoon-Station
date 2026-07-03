GLOBAL_LIST_EMPTY(mentor_datums)
GLOBAL_PROTECT(mentor_datums)

GLOBAL_VAR_INIT(mentor_href_token, GenerateToken())
GLOBAL_PROTECT(mentor_href_token)

/datum/mentors
	var/name = "someone's mentor datum"
	var/client/owner // the actual mentor, client type
	var/target // the mentor's ckey
	var/href_token // href token for mentor commands, uses the same token used by admins.
	var/mob/following
	/// Super mentors receive mentorhelp pings and can spawn mentor drones.
	var/is_super = FALSE

/datum/mentors/New(ckey, super = FALSE)
	if(!ckey)
		QDEL_IN(src, 0)
		CRASH("Mentor datum created without a ckey")
	target = ckey(ckey)
	name = "[ckey]'s mentor datum"
	href_token = GenerateToken()
	is_super = super
	GLOB.mentor_datums[target] = src
	//set the owner var and load commands
	owner = GLOB.directory[ckey]
	if(owner)
		owner.mentor_datum = src
		owner.add_mentor_verbs()
		if(is_super && !check_rights_for(owner, R_ADMIN, 0))
			GLOB.mentors += owner

/datum/mentors/proc/promote_super_mentor()
	if(is_super)
		return
	is_super = TRUE
	if(owner)
		owner.add_mentor_verbs()
		if(!check_rights_for(owner, R_ADMIN, 0))
			GLOB.mentors += owner
	log_admin_private("[target] was promoted to super mentor.")

/datum/mentors/proc/demote_super_mentor()
	if(!is_super)
		return
	is_super = FALSE
	if(owner)
		GLOB.mentors -= owner
		owner.add_mentor_verbs()
	log_admin_private("[target] was removed from the rank of super mentor.")

/// Legacy name used by admin tooling; only strips super mentor status.
/datum/mentors/proc/remove_mentor()
	demote_super_mentor()

/datum/mentors/proc/CheckMentorHREF(href, href_list)
	var/auth = href_list["mentor_token"]
	. = auth && (auth == href_token || auth == GLOB.mentor_href_token)
	if(.)
		return
	var/msg = !auth ? "no" : "a bad"
	message_admins("[key_name_admin(usr)] clicked an href with [msg] authorization key!")
	if(CONFIG_GET(flag/debug_admin_hrefs))
		message_admins("Debug mode enabled, call not blocked. Please ask your coders to review this round's logs.")
		log_world("UAH: [href]")
		return TRUE
	log_admin_private("[key_name(usr)] clicked an href with [msg] authorization key! [href]")

/proc/RawMentorHrefToken(forceGlobal = FALSE)
	var/tok = GLOB.mentor_href_token
	if(!forceGlobal && usr)
		var/client/C = usr.client
		to_chat(world, C)
		to_chat(world, usr)
		if(!C)
			CRASH("No client for HrefToken()!")
		var/datum/mentors/holder = C.mentor_datum
		if(holder)
			tok = holder.href_token
	return tok

/proc/MentorHrefToken(forceGlobal = FALSE)
	return "mentor_token=[RawMentorHrefToken(forceGlobal)]"

// new client var: mentor_datum. Acts the same way holder does towards admin: it holds the mentor datum. if set, the guy's a mentor.
/client
	/// Acts the same way holder does towards admin: it holds the mentor datum. if set, the guy's a mentor.
	var/datum/mentors/mentor_datum
