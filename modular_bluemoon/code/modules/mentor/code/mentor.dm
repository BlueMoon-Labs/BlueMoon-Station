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

/datum/mentors/New(ckey)
	if(!ckey)
		QDEL_IN(src, 0)
		CRASH("Mentor datum created without a ckey")
	target = ckey(ckey)
	name = "[ckey]'s mentor datum"
	href_token = GenerateToken()
	GLOB.mentor_datums[target] = src
	//set the owner var and load commands
	owner = GLOB.directory[ckey]
	if(owner)
		owner.mentor_datum = src
		owner.add_mentor_verbs()
		if(!check_rights_for(owner, R_ADMIN,0)) // don't add admins to mentor list.
			GLOB.mentors += owner

/datum/mentors/Destroy()
	set_following(null)
	if(owner)
		owner.mentor_datum = null
		GLOB.mentors -= owner
	owner = null
	GLOB.mentor_datums -= target
	return ..()

/datum/mentors/proc/set_following(mob/new_following)
	if(following == new_following)
		return
	if(following)
		UnregisterSignal(following, COMSIG_PARENT_QDELETING)
	following = new_following
	if(following)
		RegisterSignal(following, COMSIG_PARENT_QDELETING, PROC_REF(on_followed_qdeleting))

/datum/mentors/proc/on_followed_qdeleting(datum/source)
	SIGNAL_HANDLER
	if(source != following)
		return
	following = null
	var/mob/mentor_mob = owner?.mob
	mentor_mob?.reset_perspective()
	if(mentor_mob)
		remove_verb(mentor_mob, /client/proc/mentor_unfollow)

/datum/mentors/proc/remove_mentor()
	if(owner)
		owner.remove_mentor_verbs()
		GLOB.mentors -= owner
		owner.mentor_datum = null
		owner = null
	log_admin_private("[target] was removed from the rank of mentor.")
	GLOB.mentor_datums -= target
	qdel(src)

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
	/// Нажал Dementor и не хочет получать менторский трафик (mhelp, msay, ментор-PM).
	/// Для менторов дублирует выход из GLOB.mentors, для админов - единственный механизм:
	/// рассылки идут и по GLOB.admins, откуда Dementor убрать не может.
	var/dementored = FALSE

/// Получатели менторского трафика: менторы и админы, кроме нажавших Dementor.
/// Все рассылки mhelp/msay/ментор-PM обязаны идти через этот прок, а не по
/// GLOB.mentors | GLOB.admins напрямую - иначе Dementor не работает для админов.
/proc/mentor_traffic_recipients()
	var/list/recipients = list()
	for(var/client/staff in GLOB.mentors | GLOB.admins)
		if(staff.dementored)
			continue
		recipients += staff
	return recipients
