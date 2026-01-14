/obj/structure/closet/secure_closet/genpop
	desc = "It's a secure locker for inmates's personal belongings."
	var/default_desc = "It's a secure locker for the storage inmates's personal belongings during their time in prison."
	name = "prisoner closet"
	var/default_name = "prisoner closet"
	req_access = list(ACCESS_BRIG)
	var/obj/item/card/id/prisoner/registered_id = null
	icon_state = "secure"
	locked = FALSE
	anchored = TRUE
	opened = TRUE
	density = FALSE

	var/prisoner_name	= ""
	var/crimes			= ""
	var/report_text		= ""
	var/sentence_length
	var/filteredsentlength
	var/datum/data/record/target_record

/obj/structure/closet/secure_closet/genpop/attackby(obj/item/W, mob/user, params)
	if(!broken && locked && W == registered_id) //Prisoner opening
		handle_prisoner_id(user)
		return

	return ..()

/obj/structure/closet/secure_closet/genpop/proc/handle_prisoner_id(mob/user)
	if(!(ACCESS_LEAVE_GENPOP in registered_id.GetAccess()) && !allowed(user))
		to_chat(user, "<span class='danger'>The time of imprisonment has not yet come to an end.</span>")
		return FALSE

	qdel(registered_id)
	locked = FALSE
	open(user)
	to_chat(user, "<span class='notice'>You insert prisoner id into \the [src] and it springs open!</span>")
	generate_log_release()
	set_security_status(SEC_RECORD_STATUS_RELEASED)
	reset()
	return TRUE

/obj/structure/closet/secure_closet/genpop/proc/handle_edit_sentence(mob/user)
	prisoner_name = sanitize(input(user, "Please input the name of the prisoner.", "Prisoner Name", registered_id.registered_name) as text|null)
	if(prisoner_name == null | !user.Adjacent(src))
		return FALSE
	sentence_length = input(user, "Please input the length of their sentence in minutes (0 for perma).", "Sentence Length", registered_id.sentence) as num|null
	if(sentence_length == null | !user.Adjacent(src))
		return FALSE
	crimes = sanitize(input(user, "Please input their crimes.", "Crimes", registered_id.crime) as text|null)
	if(crimes == null | !user.Adjacent(src))
		return FALSE

	registered_id.registered_name = prisoner_name
	filteredsentlength = text2num(sentence_length)
	registered_id.sentence = filteredsentlength ? (filteredsentlength MINUTES) + world.time : 0
	registered_id.crime = crimes
	registered_id.update_label()
	if(registered_id.sentence)
		START_PROCESSING(SSobj, registered_id)
	else
		STOP_PROCESSING(SSobj, registered_id)

	print_report()
	report_text = null

	target_record = find_security_record("name", prisoner_name)
	set_security_status(SEC_RECORD_STATUS_INCARCERATED)

	name = "[default_name] ([prisoner_name])"
	desc = "[default_desc] It contains the personal effects of [prisoner_name]."
	desc += "<br>[registered_id.sentence ? "Imprisoned until: [STATION_TIME_TIMESTAMP("hh:mm:ss", registered_id.sentence)]." : "Imprisoned permanently."]"
	desc += "<br>Imprisoned under the following crimes: [crimes]."
	return TRUE

/obj/structure/closet/secure_closet/genpop/togglelock(mob/living/user)
	if(!allowed(user))
		return ..()

	if(!broken && locked && registered_id != null)
		var/name = registered_id.registered_name
		var/result = alert(user, "This locker currently contains [name]'s personal belongings ","Locker In Use","Reset","Amend ID", "Open")
		if(!user.Adjacent(src))
			return
		if(result == "Reset")
			generate_log_reset()
			reset()
		if(result == "Open" | result == "Reset")
			locked = FALSE
			open(user)
		if(result == "Amend ID")
			handle_edit_sentence(user)
	else
		return ..()

/obj/structure/closet/secure_closet/genpop/close(mob/living/user)
	if(registered_id != null && !broken)
		locked = TRUE
	return ..()

/obj/structure/closet/secure_closet/genpop/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(user.lying && get_dist(src, user) > 0)
		return

	if(!broken && registered_id != null && (registered_id in user.held_items))
		handle_prisoner_id(user)
		return

	if(!broken && opened && !locked && allowed(user) && !registered_id) //Genpop setup

		registered_id = new /obj/item/card/id/prisoner/(src.contents)
		if(handle_edit_sentence(user))
			close(user)
			locked = TRUE
			update_icon()
			registered_id.forceMove(src.loc)
			new /obj/item/clothing/under/rank/prisoner(src.loc)
			new /obj/item/clothing/shoes/sneakers/orange(src.loc)
			new /obj/item/radio/headset/headset_prisoner(src.loc)
		else
			qdel(registered_id)
			registered_id = null

		return

	..()

/obj/structure/closet/secure_closet/genpop/proc/print_report()
	for(var/obj/machinery/computer/prisoner/management/C in GLOB.prisoncomputer_list)
		var/obj/item/paper/P = new /obj/item/paper(C.loc)
		P.name = "PermaBrig log - [prisoner_name] [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]"
		generate_report()
		P.add_raw_text(report_text)
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
		P.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 1, "stamp-machine")
		P.update_appearance()

		playsound(C.loc, "sound/goonstation/machines/printer_dotmatrix.ogg", 50, 1)
		GLOB.cell_logs += P
	return

/obj/structure/closet/secure_closet/genpop/proc/generate_report()
	report_text =	"<center><b>PermaBrig - Brig record</b></center><br><hr><br>"
	report_text +=	"<center>[station_name()] - Security Department</center><br>"
	report_text +=	"<center><small><b>Admission data:</b></small></center><br>"
	report_text +=	"<small><b>Log generated at:</b>		[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)]<br>"
	report_text +=	"<b>Detainee:</b>		[prisoner_name]<br>"
	report_text +=	"<b>Duration:</b>		[filteredsentlength ? "[filteredsentlength] minutes" : "Permanent"]<br>"
	report_text +=	"<b>Charge(s):</b>		[crimes]<br>"
	report_text +=	"<b>Arresting Officer:</b>		[usr.name]<br></small><hr><br>"
	report_text +=	"<small>This log file was generated automatically upon activation of the term of imprisonment.</small>"
	return

/obj/structure/closet/secure_closet/genpop/proc/set_security_status(status2set)
	if(target_record)
		target_record.fields["criminal"] = status2set
		var/rank = select_rank_do_stuff(usr)
		if(!isnull(rank))
			target_record.fields["actions_logs"] +=	"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] Sentenced to PermaBrig [filteredsentlength ? "at [filteredsentlength] minutes" : ""] for the charges of \"[crimes]\" by [rank] [usr.name];</u>"
		update_all_mob_security_hud()
	return

/obj/structure/closet/secure_closet/genpop/proc/generate_log_release()
	if(target_record)
		target_record.fields["actions_logs"] +=	"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] Released from PermaBrig;</u>"
	return

/obj/structure/closet/secure_closet/genpop/proc/generate_log_reset()
	if(target_record)
		target_record.fields["actions_logs"] +=	"<u>[GLOB.current_date_string] | [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] PermaBrig Locker resetted;</u>"
	return

/obj/structure/closet/secure_closet/genpop/proc/select_rank_do_stuff(mob/living/carbon/human/M)
	if(target_record)
		var/rank = "UNKNOWN RANK"
		if(istype(M))
			var/obj/item/card/id/I = M.get_id_card()
			if(I)
				rank = I.get_assignment_name()
		if(!target_record.fields["actions_logs"] || !islist(target_record.fields["actions_logs"]))
			target_record.fields["actions_logs"] = list()
		return rank
	return null

/obj/structure/closet/secure_closet/genpop/proc/reset()
	name = default_name
	desc = default_desc
	prisoner_name		= null
	crimes				= null
	sentence_length		= null
	filteredsentlength	= null
	target_record		= null
	registered_id 		= null
	return
