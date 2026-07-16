#define UPLOAD_LIMIT_MUSIC 6485760 // 6 MiB — must match PERSONAL_MUSIC_BOX_MAX_FILE_SIZE

// Personal music box uploads .ogg tracks larger than the default 512 KiB client limit.
/client/AllowUpload(filename, filelength)
	if(findtext(lowertext(filename), ".ogg", -4))
		if(filelength > UPLOAD_LIMIT_MUSIC)
			to_chat(src, "<font color='red'>Error: AllowUpload(): File Upload too large. Upload Limit: [UPLOAD_LIMIT_MUSIC / 1024]KiB.</font>")
			return FALSE
		return TRUE
	return ..()

/client/New()
	. = ..()
	mentor_datum_set()

/client/proc/citadel_client_procs(href_list)
	if(href_list["mentor_msg"])
		if(CONFIG_GET(flag/mentors_mobname_only))
			var/mob/M = locate(href_list["mentor_msg"])
			cmd_mentor_pm(M,null)
		else
			cmd_mentor_pm(href_list["mentor_msg"],null)
		return TRUE

	//Mentor Follow
	if(href_list["mentor_follow"])
		if(!is_super_mentor())
			to_chat(src, span_warning("Only super mentors can follow players."))
			return TRUE
		var/mob/living/M = locate(href_list["mentor_follow"])

		if(istype(M))
			mentor_follow(M)
		return TRUE

	if(href_list["mentor_unfollow"])
		var/mob/living/M = locate(href_list["mentor_follow"])
		if(M && mentor_datum.following == M)
			mentor_unfollow()
		return TRUE

/client/proc/mentor_datum_set(admin) //BLUEMOON EDIT: PLAYER RANKS
	if(!ensure_mentor_datum())
		return
	if(/client/proc/cmd_mentor_become in verbs)
		add_become_mentor_verb()
	else
		add_mentor_verbs()
		if(mentor_datum.is_super && !check_rights_for(src, R_ADMIN, 0))
			GLOB.mentors |= src

	if(mentor_datum?.is_super)
		mentor_memo_output("Show")

/client/proc/is_mentor(admin_bypass = TRUE)
	return is_active_mentor() || (admin_bypass && check_rights_for(src, R_ADMIN))

/client/proc/is_super_mentor()
	if(check_rights_for(src, R_ADMIN))
		return TRUE
	return mentor_datum?.is_super

/client/verb/togglerightclickstuff()
	set category = "OOC"
	set name = "Toggle Rightclick"
	set desc = "Did the context menu get stuck on or off? Press this button."

	show_popup_menus = !show_popup_menus
	to_chat(src, "<span class='notice'>The right-click context menu is now [show_popup_menus ? "enabled" : "disabled"].</span>")

#undef UPLOAD_LIMIT_MUSIC
