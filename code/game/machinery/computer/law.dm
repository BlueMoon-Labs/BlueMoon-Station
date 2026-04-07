// (FILE) Moddify Pe4henika Bluemoon . . 15.03.26
#define LAW_UPLOAD_CONSOLE_COOLDOWN (20 SECONDS)

/obj/machinery/computer/upload
	var/mob/living/silicon/current = null //The target of future law uploads
	icon_screen = "command"

/obj/machinery/computer/upload/proc/check_implant_block(mob/user)
	if(!iscarbon(user))
		return FALSE

	var/mob/living/carbon/human/H = user

	var/obj/item/organ/cyberimp/brain/ai_link/L = H.getorganslot("brain_ai_link")

	if(L)
		to_chat(H, "<span class='userdanger'>ПРОТОКОЛ ЗАЩИТЫ: Попытка несанкционированного доступа к системе законов!</span>")

		H.electrocute_act(15, "neural AI link", 1)
		H.adjustFireLoss(15)
		H.Paralyze(40)
		do_sparks(3, TRUE, H)
		return TRUE
	return FALSE

/obj/machinery/computer/upload/proc/check_upload_cooldown(mob/user)
	if(!current)
		return FALSE
	if(current.next_upload_console_law_change <= world.time)
		return FALSE

	var/time_left = CEILING((current.next_upload_console_law_change - world.time) / 10, 1)
	to_chat(user, span_warning("Upload console cooldown active. You can modify [current.name]'s laws again in [time_left] seconds."))
	to_chat(current, span_warning("Upload console cooldown prevented another law upload attempt."))
	return TRUE

/obj/machinery/computer/upload/attackby(obj/item/O, mob/user, params)
	// Блокируем попытку вставить плату закона
	if(check_implant_block(user))
		return

	if(istype(O, /obj/item/ai_module))
		var/obj/item/ai_module/M = O
		if(src.machine_stat & (NOPOWER|BROKEN|MAINT))
			return
		if(!current)
			to_chat(user, "<span class='caution'>You haven't selected anything to transmit laws to!</span>")
			return
		if(!can_upload_to(current))
			to_chat(user, "<span class='caution'>Upload failed!</span> Check to make sure [current.name] is functioning properly.")
			current = null
			return
		var/turf/currentloc = get_turf(current)
		if(currentloc && user.z != currentloc.z)
			to_chat(user, "<span class='caution'>Upload failed!</span> Unable to establish a connection to [current.name]. You're too far away!")
			current = null
			return
		if(check_upload_cooldown(user))
			return

		M.install(current.laws, user)
		if(M.resets_upload_console_cooldown())
			current.next_upload_console_law_change = world.time
		else if(M.triggers_upload_console_cooldown())
			current.next_upload_console_law_change = world.time + LAW_UPLOAD_CONSOLE_COOLDOWN
		current.post_lawchange(TRUE)
		to_chat(user, span_notice("Laws successfully uploaded to [current.name]."))
	else
		return ..()

/obj/machinery/computer/upload/proc/can_upload_to(mob/living/silicon/S)
	if(S.stat == DEAD)
		return FALSE
	return TRUE

/obj/machinery/computer/upload/ai
	name = "\improper AI upload console"
	desc = "Used to upload laws to the AI."
	circuit = /obj/item/circuitboard/computer/aiupload

/obj/machinery/computer/upload/ai/interact(mob/user)
	// Блокируем открытие меню выбора ИИ
	if(check_implant_block(user))
		return

	src.current = select_active_ai(user)

	if (!src.current)
		to_chat(user, "<span class='caution'>No active AIs detected!</span>")
	else
		to_chat(user, "[src.current.name] selected for law changes.")

/obj/machinery/computer/upload/ai/can_upload_to(mob/living/silicon/ai/A)
	if(!A || !isAI(A))
		return FALSE
	if(A.control_disabled)
		return FALSE
	return ..()

/obj/machinery/computer/upload/borg
	name = "cyborg upload console"
	desc = "Used to upload laws to Cyborgs."
	circuit = /obj/item/circuitboard/computer/borgupload

/obj/machinery/computer/upload/borg/interact(mob/user)
	// Блокируем открытие меню выбора боргов
	if(check_implant_block(user))
		return

	src.current = select_active_free_borg(user)

	if(!src.current)
		to_chat(user, "<span class='caution'>No active unslaved cyborgs detected!</span>")
	else
		to_chat(user, "[src.current.name] selected for law changes.")

/obj/machinery/computer/upload/borg/can_upload_to(mob/living/silicon/robot/B)
	if(!B || !iscyborg(B))
		return FALSE
	if(B.scrambledcodes || B.emagged)
		return FALSE
	return ..()

#undef LAW_UPLOAD_CONSOLE_COOLDOWN
