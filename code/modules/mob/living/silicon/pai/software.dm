// TODO:
//	- Additional radio modules
//	- Potentially roll HUDs and Records into one
//	- Shock collar/lock system for prisoner pAIs?
//  - Put cable in user's hand instead of on the ground

/mob/living/silicon/pai/var/list/available_software = list(
															"crew manifest" = 5,
															//"digital messenger" = 5, // PAI uses the new TGUI messenger program on its PDA instead
															"medical records" = 15,
															"security records" = 15,
															"camera jack" = 10,
															"door jack" = 30,
															"atmosphere sensor" = 5,
															"heartbeat sensor" = 10,
															"security HUD" = 20,
															"medical HUD" = 20,
															"universal translator" = 35,
															"projection array" = 15,
															"remote signaller" = 5,
															"loudness booster" = 25,
															"encryption keys" = 20
															)

/mob/living/silicon/pai/Topic(href, href_list)
	..()
	if(usr != src)
		return
	if(!canUseTopic(src, be_close=FALSE))
		return
	var/soft = href_list["software"]
	var/sub = href_list["sub"]
	if(soft)
		screen = soft
	if(sub)
		subscreen = text2num(sub)
	switch(soft)
		// Purchasing new software
		if("buy")
			if(subscreen == 1)
				var/target = href_list["buy"]
				if(available_software.Find(target) && !software.Find(target))
					var/cost = available_software[target]
					if(ram >= cost)
						software.Add(target)
						ram -= cost
					else
						temp = "Insufficient RAM available."
				else
					temp = "Trunk <TT> \"[target]\"</TT> not found."

		// Configuring onboard radio
		if("radio")
			radio.attack_self(src)

		if("image")
			var/newImage = tgui_input_list(src, "Select your new display image.", "Display Image", list("Happy", "Cat", "Extremely Happy", "Face", "Laugh", "Off", "Sad", "Angry", "What", "Exclamation", "Question", "Sunglasses", "Mal-0"))
			var/pID = 1

			switch(newImage)
				if("Happy")
					pID = 1
				if("Cat")
					pID = 2
				if("Extremely Happy")
					pID = 3
				if("Face")
					pID = 4
				if("Laugh")
					pID = 5
				if("Off")
					pID = 6
				if("Sad")
					pID = 7
				if("Angry")
					pID = 8
				if("What")
					pID = 9
				if("Null")
					pID = 10
				if("Exclamation")
					pID = 11
				if("Question")
					pID = 12
				if("Sunglasses")
					pID = 13
				if("Mal-0")
					pID = 14
			card.setEmotion(pID)

		if("signaller")

			if(href_list["send"])
				signaler.send_activation()
				audible_message("[icon2html(src, hearers(src))] *beep* *beep* *beep*")
				playsound(src, 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)

			if(href_list["freq"])
				var/new_frequency = (signaler.frequency + text2num(href_list["freq"]))
				if(new_frequency < MIN_FREE_FREQ || new_frequency > MAX_FREE_FREQ)
					new_frequency = sanitize_frequency(new_frequency)
				signaler.set_frequency(new_frequency)

			if(href_list["code"])
				signaler.code += text2num(href_list["code"])
				signaler.code = round(signaler.code)
				signaler.code = min(100, signaler.code)
				signaler.code = max(1, signaler.code)



		if("directive")
			if(href_list["getdna"])
				var/mob/living/M = card.loc
				var/count = 0
				while(!isliving(M))
					if(!M || !M.loc)
						return FALSE //For a runtime where M ends up in nullspace (similar to bluespace but less colourful)
					M = M.loc
					count++
					if(count >= 6)
						to_chat(src, "You are not being carried by anyone!")
						return FALSE
				INVOKE_ASYNC(src, PROC_REF(CheckDNA), M)

		//if("pdamessage") // Removed - PAI uses TGUI messenger on its PDA instead
		//	if(!isnull(pda))
		//		if(href_list["toggler"])
		//			pda.toff = !pda.toff
		//		else if(href_list["ringer"])
		//			pda.silent = !pda.silent
		//		else if(href_list["target"])
		//			if(silent)
		//				return alert("Communications circuits remain uninitialized.")
		//			var/target = locate(href_list["target"])
		//			pda.create_message(src, target)

		// Accessing medical records
		if("medicalrecord")
			if(subscreen == 1)
				medicalActive1 = GLOB.data_core.general_by_id[href_list["med_rec"]]
				if(medicalActive1)
					medicalActive2 = GLOB.data_core.medical_by_id[href_list["med_rec"]]
				if(!medicalActive2)
					medicalActive1 = null
					temp = "Unable to locate requested security record. Record may have been deleted, or never have existed."

		if("securityrecord")
			if(subscreen == 1)
				securityActive1 = GLOB.data_core.general_by_id[href_list["sec_rec"]]
				if(securityActive1)
					securityActive2 = GLOB.data_core.security_by_id[href_list["sec_rec"]]
				if(!securityActive2)
					securityActive1 = null
					temp = "Unable to locate requested security record. Record may have been deleted, or never have existed."
		if("securityhud")
			if(href_list["toggle"])
				secHUD = !secHUD
				if(secHUD)
					var/datum/atom_hud/sec = GLOB.huds[sec_hud]
					sec.add_hud_to(src)
				else
					var/datum/atom_hud/sec = GLOB.huds[sec_hud]
					sec.remove_hud_from(src)
		if("medicalhud")
			if(href_list["toggle"])
				medHUD = !medHUD
				if(medHUD)
					var/datum/atom_hud/med = GLOB.huds[med_hud]
					med.add_hud_to(src)
				else
					var/datum/atom_hud/med = GLOB.huds[med_hud]
					med.remove_hud_from(src)
		if("encryptionkeys")
			if(href_list["toggle"])
				encryptmod = TRUE
		if("translator")
			if(href_list["toggle"])	//This is permanent.
				grant_all_languages(source = LANGUAGE_SOFTWARE)
		if("doorjack")
			if(href_list["jack"])
				if(cable && cable.machine)
					hackdoor = cable.machine
					hackloop()
			if(href_list["cancel"])
				hackdoor = null
			if(href_list["cable"])
				var/turf/T = get_turf(loc)
				cable = new /obj/item/pai_cable(T)
				T.visible_message("<span class='warning'>A port on [src] opens to reveal [cable], which promptly falls to the floor.</span>", "<span class='italics'>You hear the soft click of something light and hard falling to the ground.</span>")
		if("loudness")
			if(subscreen == 1) // Open Instrument
				internal_instrument.ui_interact(src)

	//updateUsrDialog()		We only need to account for the single mob this is intended for, and he will *always* be able to call this window
	paiInterface()		 // So we'll just call the update directly rather than doing some default checks
	return


/mob/living/silicon/pai/proc/CheckDNA(mob/living/carbon/M, mob/living/silicon/pai/P)
	var/answer = tgui_alert(M, "[P] is requesting a DNA sample from you. Will you allow it to confirm your identity?", "[P] Check DNA", list("Yes", "No"))
	if(answer == "Yes")
		M.visible_message("<span class='notice'>[M] presses [M.ru_ego()] thumb against [P].</span>",\
						"<span class='notice'>You press your thumb against [P].</span>",\
						"<span class='notice'>[P] makes a sharp clicking sound as it extracts DNA material from [M].</span>")
		if(!M.has_dna()) // TODO BLUEMOON - сделать флафовое описание поинтереснее для синтетиков?
			to_chat(P, "<b>No DNA detected</b>")
			return
		to_chat(P, "<font color = red><h3>[M]'s UE string : [M.dna.unique_enzymes]</h3></font>")
		if(M.dna.unique_enzymes == P.master_dna)
			to_chat(P, "<b>DNA is a match to stored Master DNA.</b>")
		else
			to_chat(P, "<b>DNA does not match stored Master DNA.</b>")
	else
		to_chat(P, "[M] does not seem like [M.ru_who()] going to provide a DNA sample willingly.")

// Door Jack - supporting proc
/mob/living/silicon/pai/proc/hackloop()
	var/turf/T = get_turf(src)
	for(var/mob/living/silicon/ai/AI in GLOB.player_list)
		if(T.loc)
			to_chat(AI, "<font color = red><b>Network Alert: Brute-force encryption crack in progress in [T.loc].</b></font>")
		else
			to_chat(AI, "<font color = red><b>Network Alert: Brute-force encryption crack in progress. Unable to pinpoint location.</b></font>")
	hacking = TRUE
