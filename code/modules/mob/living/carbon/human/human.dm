/mob/living/carbon/human
	name = "Unknown"
	real_name = "Unknown"
	icon = 'icons/mob/human.dmi'
	icon_state = "caucasian_m"
	SET_APPEARANCE_FLAGS(KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE)

/mob/living/carbon/human/Initialize(mapload)
	add_verb(src, /mob/living/proc/mob_sleep)
	add_verb(src, /mob/living/proc/lay_down)
	//initialize limbs first
	create_bodyparts()

	setup_human_dna()

	if(dna.species)
		set_species(dna.species.type)

	//initialise organs
	create_internal_organs() //most of it is done in set_species now, this is only for parent call
	physiology = new()

	AddComponent(/datum/component/personal_crafting)
	AddComponent(/datum/component/footstep, FOOTSTEP_MOB_HUMAN, 1, 2)
	. = ..()

	if(CONFIG_GET(flag/disable_stambuffer))
		enable_intentional_sprint_mode()

	RegisterSignal(src, COMSIG_COMPONENT_CLEAN_ACT, TYPE_PROC_REF(/atom, clean_blood))
	GLOB.human_list += src
	set_jump_component()

/mob/living/carbon/human/proc/setup_human_dna()
	//initialize dna. for spawned humans; overwritten by other code
	create_dna(src)
	randomize_human(src)
	dna.initialize_dna()

/mob/living/carbon/human/ComponentInitialize()
	. = ..()
	if(!CONFIG_GET(flag/disable_human_mood))
		AddComponent(/datum/component/mood)
/*	AddComponent(/datum/component/combat_mode) / BLUEMOON REMOVAL - боевые индикаторы присваиваются всем мобам в другом файле */
	AddElement(/datum/element/flavor_text/carbon/temporary, "", "Set Pose (Temporary Flavor Text)", "This should be used only for things pertaining to the current round!", _save_key = null)
	AddElement(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human, should_strip))

/mob/living/carbon/human/Destroy()
	QDEL_NULL(physiology)
	QDEL_NULL_LIST(vore_organs) // CITADEL EDIT belly stuff
	GLOB.human_list -= src
	return ..()

/mob/living/carbon/human/prepare_data_huds()
	//Update med hud images...
	..()
	//...sec hud images...
	sec_hud_set_ID()
	sec_hud_set_implants()
	sec_hud_set_security_status()
	//...and display them.
	add_to_all_human_data_huds()

/proc/update_all_mob_security_hud()
	for(var/thing in GLOB.human_list)
		var/mob/living/carbon/human/H = thing
		H.sec_hud_set_security_status()

/mob/living/carbon/human/get_status_tab_items()
	. = ..()
	. += "Intent: [a_intent]"
	. += "Move Mode: [m_intent]"
	if(internal)
		if(istype(internal, /obj/item/tank))
			if(!internal.air_contents)
				qdel(internal)
			else
				. += ""
				. += "Internal Atmosphere Info: [internal.name]"
				. += "Tank Pressure: [internal.air_contents.return_pressure()]"
				. += "Distribution Pressure: [internal.distribute_pressure]"
	if(mind)
		var/datum/antagonist/changeling/changeling = mind.has_antag_datum(/datum/antagonist/changeling)
		if(changeling)
			. += ""
			. += "Chemical Storage: [changeling.chem_charges]/[changeling.chem_storage]"
			. += "Absorbed DNA: [changeling.absorbedcount]"


// called when something steps onto a human
// this could be made more general, but for now just handle mulebot
/mob/living/carbon/human/Crossed(atom/movable/AM)
	SEND_SIGNAL(src, COMSIG_MOVABLE_CROSSED, AM)
	var/mob/living/simple_animal/bot/mulebot/MB = AM
	if(istype(MB))
		MB.RunOver(src)

	//Hyper Change - Step on people
	var/mob/living/carbon/human/H = AM
	if(istype(H) && lying && H.a_intent != INTENT_HELP)
		H.handle_micro_bump_other(src)

	spreadFire(AM)

/mob/living/carbon/human/Topic(href, href_list)
	if(href_list["embedded_object"])
		if(usr.canUseTopic(src, BE_CLOSE, NO_DEXTERY, check_resting = FALSE))
			var/obj/item/bodypart/L = locate(href_list["embedded_limb"]) in bodyparts
			if(!L)
				return
			var/obj/item/I = locate(href_list["embedded_object"]) in L.embedded_objects
			if(!I || I.loc != src) //no item, no limb, or item is not in limb or in the person anymore
				return
			SEND_SIGNAL(src, COMSIG_CARBON_EMBED_RIP, I, L)
			return

	else if(href_list["character_profile"])
		if(!profile)
			profile = new(src)
		profile.ui_interact(usr)

///////HUDs///////
	if(href_list["hud"])
		if(ishuman(usr))
			var/mob/living/carbon/human/H = usr
			var/perpname = get_face_name(get_id_name(""))
			if(istype(H.glasses, /obj/item/clothing/glasses/hud) || istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud))
				var/datum/data/record/R = find_record("name", perpname, GLOB.data_core.general)
				if(href_list["photo_front"] || href_list["photo_side"])
					if(R)
						if(!H.canUseHUD())
							return
						else if(!istype(H.glasses, /obj/item/clothing/glasses/hud) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/medical))
							return
						var/obj/item/photo/P = null
						if(href_list["photo_front"])
							P = R.fields["photo_front"]
						else if(href_list["photo_side"])
							P = R.fields["photo_side"]
						if(P)
							P.show(H)
				if(href_list["hud"] == "s")
					if(istype(H.glasses, /obj/item/clothing/glasses/hud/security) || istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
						if(usr.stat || usr == src) //|| !usr.canmove || usr.restrained()) Fluff: Sechuds have eye-tracking technology and sets 'arrest' to people that the wearer looks and blinks at.
							return													  //Non-fluff: This allows sec to set people to arrest as they get disarmed or beaten
						// Checks the user has security clearence before allowing them to change arrest status via hud, comment out to enable all access
						var/allowed_access = null
						var/obj/item/clothing/glasses/G = H.glasses
						if (!(G.obj_flags & EMAGGED))
							if(H.wear_id)
								var/list/access = H.wear_id.GetAccess()
								if(ACCESS_SEC_DOORS in access)
									allowed_access = H.get_authentification_name()
						else
							allowed_access = "@%&ERROR_%$*"
						if(!allowed_access)
							to_chat(H, "<span class='warning'>ERROR: Invalid Access</span>")
							return
						if(perpname)
							R = find_record("name", perpname, GLOB.data_core.security)
							if(R)
								if(href_list["status"])
									var/setcriminal = input(usr, "Specify a new criminal status for this person.", "Security HUD", R.fields["criminal"]) in list(SEC_RECORD_STATUS_NONE, SEC_RECORD_STATUS_ARREST, SEC_RECORD_STATUS_EXECUTE, SEC_RECORD_STATUS_INCARCERATED, SEC_RECORD_STATUS_RELEASED, SEC_RECORD_STATUS_PAROLLED, SEC_RECORD_STATUS_DEMOTE, SEC_RECORD_STATUS_SEARCH, SEC_RECORD_STATUS_MONITOR, SEC_RECORD_STATUS_DISCHARGED, "Отмена")
									if(setcriminal != "Отмена")
										if(R)
											if(H.canUseHUD())
												if(istype(H.glasses, /obj/item/clothing/glasses/hud/security) || istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
													investigate_log("[key_name(src)] has been set from [R.fields["criminal"]] to [setcriminal] by [key_name(usr)].", INVESTIGATE_RECORDS)
													R.fields["criminal"] = setcriminal
													sec_hud_set_security_status()
									return
								if(href_list["view"])
									if(R)
										if(!H.canUseHUD())
											return
										else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
											return
										to_chat(usr, "<b>Name:</b> [R.fields["name"]]	<b>Criminal Status:</b> [R.fields["criminal"]]")
										to_chat(usr, "<b>Minor Crimes:</b>")
										for(var/datum/data/crime/c in R.fields["mi_crim"])
											to_chat(usr, "<b>Crime:</b> [c.crimeName]")
											to_chat(usr, "<b>Details:</b> [c.crimeDetails]")
											to_chat(usr, "Added by [c.author] at [c.time]")
											to_chat(usr, "----------")
										to_chat(usr, "<b>Major Crimes:</b>")
										for(var/datum/data/crime/c in R.fields["ma_crim"])
											to_chat(usr, "<b>Crime:</b> [c.crimeName]")
											to_chat(usr, "<b>Details:</b> [c.crimeDetails]")
											to_chat(usr, "Added by [c.author] at [c.time]")
											to_chat(usr, "----------")
										to_chat(usr, "<b>Notes:</b> [R.fields["notes"]]")
									return
								if(href_list["add_crime"])
									switch(alert("What crime would you like to add?","Security HUD","Minor Crime","Major Crime","Cancel"))
										if("Minor Crime")
											if(R)
												var/t1 = stripped_input("Please input minor crime names:", "Security HUD", "", null)
												var/t2 = stripped_multiline_input("Please input minor crime details:", "Security HUD", "", null)
												if(R)
													if (!t1 || !t2 || !allowed_access)
														return
													else if(!H.canUseHUD())
														return
													else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
														return
													var/crime = GLOB.data_core.createCrimeEntry(t1, t2, allowed_access, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time))
													GLOB.data_core.addMinorCrime(R.fields["id"], crime)
													investigate_log("New Minor Crime: <strong>[t1]</strong>: [t2] | Added to [R.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
													to_chat(usr, "<span class='notice'>Successfully added a minor crime.</span>")
													return
										if("Major Crime")
											if(R)
												var/t1 = stripped_input("Please input major crime names:", "Security HUD", "", null)
												var/t2 = stripped_multiline_input("Please input major crime details:", "Security HUD", "", null)
												if(R)
													if (!t1 || !t2 || !allowed_access)
														return
													else if (!H.canUseHUD())
														return
													else if (!istype(H.glasses, /obj/item/clothing/glasses/hud/security) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
														return
													var/crime = GLOB.data_core.createCrimeEntry(t1, t2, allowed_access, STATION_TIME_TIMESTAMP("hh:mm:ss", world.time))
													GLOB.data_core.addMajorCrime(R.fields["id"], crime)
													investigate_log("New Major Crime: <strong>[t1]</strong>: [t2] | Added to [R.fields["name"]] by [key_name(usr)]", INVESTIGATE_RECORDS)
													to_chat(usr, "<span class='notice'>Successfully added a major crime.</span>")
									return
								if(href_list["view_comment"])
									if(R)
										if(!H.canUseHUD())
											return
										else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
											return
										to_chat(usr, "<b>Comments/Log:</b>")
										var/counter = 1
										while(R.fields[text("com_[]", counter)])
											to_chat(usr, R.fields[text("com_[]", counter)])
											to_chat(usr, "----------")
											counter++
										return
								if(href_list["add_comment"])
									if(R)
										var/t1 = stripped_multiline_input("Add Comment:", "Secure. records", null, null)
										if(R)
											if (!t1 || !allowed_access)
												return
											else if(!H.canUseHUD())
												return
											else if(!istype(H.glasses, /obj/item/clothing/glasses/hud/security) && !istype(H.getorganslot(ORGAN_SLOT_HUD), /obj/item/organ/cyberimp/eyes/hud/security))
												return
											var/counter = 1
											while(R.fields[text("com_[]", counter)])
												counter++
											R.fields["com_[counter]"] = "Made by [allowed_access] on [STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [time2text(world.realtime, "MMM DD")], [GLOB.year_integer]<BR>[t1]"
											to_chat(usr, "<span class='notice'>Successfully added comment.</span>")
											return
							to_chat(usr, "<span class='warning'>Unable to locate a data core entry for this person.</span>")

	if(href_list["medical"])
		if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
			if(usr.incapacitated())
				return
			var/modified = 0
			var/perpname = get_visible_name(TRUE)

			for(var/datum/data/record/E in GLOB.data_core.general)
				if(E.fields["name"] == perpname)
					for(var/datum/data/record/R in GLOB.data_core.general)
						if(R.fields["id"] == E.fields["id"])
							var/setmedical = input(usr, "Specify a new medical status for this person.", "Medical HUD", R.fields["p_stat"]) in list("Идеальное Здоровье", "*Космическое Расстройство Сна (ССД)*", "*Мёртв*", "Физически Непригодный", "Инвалид", "Присматривать", "Нестабильный", "Безумный", "Отменить")

							if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
								if(setmedical != "Отменить")
									R.fields["p_stat"] = setmedical
									modified = 1

									spawn()
										sec_hud_set_security_status()

			if(!modified)
				to_chat(usr, "<span class='warning'>Unable to locate a data core entry for this person.</span>")

	if(href_list["medrecord"])
		if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
			if(usr.incapacitated())
				return
			var/read = 0
			var/perpname = get_visible_name(TRUE)

			for(var/datum/data/record/E in GLOB.data_core.general)
				if(E.fields["name"] == perpname)
					for(var/datum/data/record/R in GLOB.data_core.medical)
						if(R.fields["id"] == E.fields["id"])
							if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
								to_chat(usr, "<b>Name:</b> [R.fields["name"]]	<b>Blood Type:</b> [R.fields["b_type"]]")
								to_chat(usr, "<b>DNA:</b> [R.fields["b_dna"]]")
								to_chat(usr, "<b>Minor Disabilities:</b> [R.fields["mi_dis"]]")
								to_chat(usr, "<b>Details:</b> [R.fields["mi_dis_d"]]")
								to_chat(usr, "<b>Major Disabilities:</b> [R.fields["ma_dis"]]")
								to_chat(usr, "<b>Details:</b> [R.fields["ma_dis_d"]]")
								to_chat(usr, "<b>Notes:</b> [R.fields["notes"]]")
								to_chat(usr, "<a href='?src=[UID()];medrecordComment=`'>\[View Comment Log\]</a>")
								read = 1

			if(!read)
				to_chat(usr, "<span class='warning'>Unable to locate a data core entry for this person.</span>")

	if(href_list["medrecordComment"])
		if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
			if(usr.incapacitated())
				return
			var/perpname = get_visible_name(TRUE)
			var/read = FALSE

			for(var/datum/data/record/E in GLOB.data_core.general)
				if(E.fields["name"] == perpname)
					for(var/datum/data/record/R in GLOB.data_core.medical)
						if(R.fields["id"] == E.fields["id"])
							if(hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
								read = TRUE
								if(LAZYLEN(R.fields["comments"]))
									for(var/c in R.fields["comments"])
										to_chat(usr, c)
								else
									to_chat(usr, "<span class='warning'>No comment found</span>")
								to_chat(usr, "<a href='?src=[UID()];medrecordadd=`'>\[Add comment\]</a>")

			if(!read)
				to_chat(usr, "<span class='warning'>Unable to locate a data core entry for this person.</span>")

	if(href_list["medrecordadd"])
		if(usr.incapacitated() || !hasHUD(usr, DATA_HUD_MEDICAL_BASIC))
			return
		var/raw_input = input("Add Comment:", "Medical records", null, null) as message
		var/sanitized = copytext(trim(sanitize(raw_input)), 1, MAX_MESSAGE_LEN)
		if(!sanitized || usr.stat || usr.restrained() || !hasHUD(usr,  DATA_HUD_MEDICAL_BASIC))
			return
		add_comment(usr, "medical", sanitized)

	if(href_list["lookitem"]) //It's for the show item at modular_sand/code/modules/mob/living/carbon/show.dm
		var/obj/item/I = locate(href_list["lookitem"])
		if(I.loc in view(4))
			examinate(I)
		else
			to_chat(usr, "<span class='warning'>You need to get closer to examine that!</span>")

/mob/living/carbon/human/proc/canUseHUD()
	return CHECK_MOBILITY(src, MOBILITY_UI)

/mob/living/carbon/human/can_inject(mob/user, error_msg, target_zone, penetrate_thick = FALSE, bypass_immunity = FALSE)
	. = 1 // Default to returning true.
	if(user && !target_zone)
		target_zone = user.zone_selected
	if(HAS_TRAIT(src, TRAIT_PIERCEIMMUNE) && !bypass_immunity)
		. = 0
	// If targeting the head, see if the head item is thin enough.
	// If targeting anything else, see if the wear suit is thin enough.
	if (!penetrate_thick)
		if(above_neck(target_zone))
			if(head && istype(head, /obj/item/clothing))
				var/obj/item/clothing/CH = head
				if (CH.clothing_flags & THICKMATERIAL)
					. = 0
		else
			var/obj/item/bodypart/BP = get_bodypart(target_zone)
			var/obj/item/clothing/CS = get_bodypart_protecting_clothing_by_coverage(src, BP)
			if(CS && (CS.clothing_flags & THICKMATERIAL))
				. = 0
	if(!. && error_msg && user)
		// Might need re-wording.
		to_chat(user, "<span class='alert'>Участок тела на [above_neck(target_zone) ? "вашей голове" : "вашем теле"] скрыт или на нём слишком толстый слой одежды!</span>")

/mob/living/carbon/human/check_obscured_slots()
	. = ..()
	if(wear_suit)
		if(wear_suit.flags_inv & HIDEGLOVES)
			LAZYOR(., ITEM_SLOT_GLOVES)
			LAZYOR(., ITEM_SLOT_WRISTS)
		if(wear_suit.flags_inv & HIDEJUMPSUIT)
			LAZYOR(., ITEM_SLOT_ICLOTHING)
			LAZYOR(., ITEM_SLOT_SHIRT)
			LAZYOR(., ITEM_SLOT_UNDERWEAR)
		if(wear_suit.flags_inv & HIDESHOES)
			LAZYOR(., ITEM_SLOT_FEET)
			LAZYOR(., ITEM_SLOT_SOCKS)
	if(w_uniform)
		if(underwear_hidden())
			LAZYOR(., ITEM_SLOT_UNDERWEAR)
		if(undershirt_hidden())
			LAZYOR(., ITEM_SLOT_SHIRT)
	if(shoes)
		if(socks_hidden())
			LAZYOR(., ITEM_SLOT_SOCKS)

/mob/living/carbon/human/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null)
	if(judgement_criteria & JUDGE_EMAGGED)
		return 10 //Everyone is a criminal!

	var/threatcount = 0

	//Lasertag bullshit
	if(lasercolor)
		if(lasercolor == "b")//Lasertag turrets target the opposing team, how great is that? -Sieve
			if(istype(wear_suit, /obj/item/clothing/suit/redtag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/redtag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/redtag))
				threatcount += 2

		if(lasercolor == "r")
			if(istype(wear_suit, /obj/item/clothing/suit/bluetag))
				threatcount += 4
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/bluetag))
				threatcount += 4
			if(istype(belt, /obj/item/gun/energy/laser/bluetag))
				threatcount += 2

		return threatcount

	//Check for ID
	var/obj/item/card/id/idcard = get_idcard(FALSE)
	if( (judgement_criteria & JUDGE_IDCHECK) && !idcard && name=="Unknown")
		threatcount += 4

	//Check for weapons
	if( (judgement_criteria & JUDGE_WEAPONCHECK) && weaponcheck)
	// BLUEMOON EDIT START - пермиты теперь типо работают
		var/list/accesses = list()
		if(idcard)
			accesses += idcard.access
		var/obj/item/clothing/under/U = w_uniform
		if(U && U.attached_accessories)
			for(var/obj/item/clothing/accessory/accs in U.attached_accessories)
				accesses += accs.access
	// BLUEMOON EDIT END
		if(!(ACCESS_WEAPONS in accesses))
			for(var/obj/item/I in held_items) //if they're holding a gun
				if(weaponcheck.Invoke(I))
					threatcount += 4
			if(weaponcheck.Invoke(belt) || weaponcheck.Invoke(back)) //if a weapon is present in the belt or back slot
				threatcount += 2 //not enough to trigger look_for_perp() on it's own unless they also have criminal status.

	//Check for arrest warrant
	if(judgement_criteria & JUDGE_RECORDCHECK)
		var/perpname = get_face_name(get_id_name())
		var/datum/data/record/R = find_record("name", perpname, GLOB.data_core.security)
		if(R && R.fields["criminal"])
			switch(R.fields["criminal"])
				if(SEC_RECORD_STATUS_EXECUTE)
					threatcount += 12
				if(SEC_RECORD_STATUS_ARREST)
					threatcount += 6
				if(SEC_RECORD_STATUS_INCARCERATED)
					threatcount += 4
				if(SEC_RECORD_STATUS_DEMOTE)
					threatcount += 2

	//Check for dresscode violations
	// BLUEMOON EDIT START
	var/static/list/equip_checks = list(
		/obj/item/clothing/head/helmet/space/hardsuit/wizard,
		/obj/item/clothing/head/helmet/space/hardsuit/shielded/wizard,
		/obj/item/clothing/head/helmet/space/hardsuit/syndi,
		/obj/item/clothing/head/helmet/space/hardsuit/shielded/syndi,
		/obj/item/clothing/head/helmet/swat/inteq,
		/obj/item/clothing/suit/armor/inteq,
		/obj/item/storage/belt/military/inteq,
		/obj/item/clothing/glasses/hud/security/sunglasses/inteq,
		/obj/item/clothing/mask/gas/inteq,
		/obj/item/storage/backpack/security/inteq,
		/obj/item/clothing/under/inteq
	)

	var/static/list/special_equip_checks = list(/obj/item/clothing/head/wizard = "check_magic_flag")

	// main check
	var/illegal_equipment = FALSE
	var/list/equipped_items = get_equipped_items(FALSE)
	var/list/obscured_slots = check_obscured_slots()
	for(var/obj/item/I in equipped_items)
		if(I.current_equipped_slot in obscured_slots)
			continue
		for(var/T in equip_checks)
			if(istype(I, T))
				illegal_equipment = TRUE
				break
		for(var/T in special_equip_checks)
			if(istype(I, T))
				var/proc_to_call = special_equip_checks[T]
				if(!proc_to_call || call(I, proc_to_call)())
					illegal_equipment = TRUE
					break
		if(illegal_equipment)
			break

	if(illegal_equipment)
		threatcount += 4 //fuk u antags <3			//no you
	// BLUEMOON EDIT END

	//mindshield implants imply trustworthyness
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		threatcount -= 1

	//Agent cards lower threatlevel.
	if(istype(idcard, /obj/item/card/id/syndicate))
		threatcount -= 2

	return threatcount


//Used for new human mobs created by cloning/goleming/podding
/mob/living/carbon/human/proc/set_cloned_appearance()
	if(dna.features["body_model"] == MALE)
		facial_hair_style = "Full Beard"
	else
		facial_hair_style = "Shaved"
	hair_style = pick("Bedhead", "Bedhead 2", "Bedhead 3")
	underwear = "Nude"
	undershirt = "Nude"
	socks = "Nude"
	update_body(TRUE)
	update_hair()

/mob/living/carbon/human/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_THREE)
		for(var/obj/item/hand in held_items)
			if(prob(current_size * 5) && hand.w_class >= ((11-current_size)/2)  && dropItemToGround(hand))
				step_towards(hand, src)
				to_chat(src, "<span class='warning'>\The [S] pulls \the [hand] from your grip!</span>")
	rad_act(current_size * 3)
	if(mob_negates_gravity())
		return

/mob/living/carbon/human/proc/do_cpr(mob/living/carbon/C)
	CHECK_DNA_AND_SPECIES(C)

	if(C.stat == DEAD || (HAS_TRAIT(C, TRAIT_FAKEDEATH)))
		to_chat(src, "<span class='warning'>[C.name] is dead!</span>")
		return
	if(is_mouth_covered())
		to_chat(src, "<span class='warning'>Remove your mask first!</span>")
		return FALSE
	if(C.is_mouth_covered())
		to_chat(src, "<span class='warning'>Remove [p_their()] mask first!</span>")
		return FALSE

	if(C.cpr_time < world.time + 30)
		visible_message("<span class='notice'>[src] is trying to perform CPR on [C.name]!</span>", \
						"<span class='notice'>You try to perform CPR on [C.name]... Hold still!</span>")
		if(!do_mob(src, C))
			to_chat(src, "<span class='warning'>You fail to perform CPR on [C]!</span>")
			return FALSE

		var/they_breathe = !HAS_TRAIT(C, TRAIT_NOBREATH)
		var/they_lung = C.getorganslot(ORGAN_SLOT_LUNGS)

		if(C.health > C.crit_threshold)
			return

		src.visible_message("[src] performs CPR on [C.name]!", "<span class='notice'>You perform CPR on [C.name].</span>")
		SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "perform_cpr", /datum/mood_event/perform_cpr)
		C.cpr_time = world.time
		log_combat(src, C, "CPRed")

		if(they_breathe && they_lung)
			var/suff = min(C.getOxyLoss(), 7)
			C.adjustOxyLoss(-suff)
			C.updatehealth()
			to_chat(C, "<span class='unconscious'>Вы ощущаете поток свежеого воздуха... Как же хорошо...</span>")
		else if(they_breathe && !they_lung)
			to_chat(C, "<span class='unconscious'>Вы ощущаете поток свежого воздуха... Но вам едва ли становится лучше..</span>")
		else
			to_chat(C, "<span class='unconscious'>Вы ощущаете поток свежего воздуха... неизвестно, откуда...</span>")

/mob/living/carbon/human/cuff_resist(obj/item/I)
	if(dna && dna.check_mutation(HULK) || istype(mind.martial_art, /datum/martial_art/nanosuit))
		say(pick(";РАААААААААРГ!", ";ХНННННННГГГГГГГ!", ";ГВААААРРХХ!", "ННННННГГГГГГХ!", ";ААААААРРГГ!" ), forced = "hulk")
		if(..(I, cuff_break = FAST_CUFFBREAK))
			dropItemToGround(I)
	else
		if(..())
			dropItemToGround(I)

/**
 * Used to update the makeup on a human and apply/remove lipstick traits, then store/unstore them on the head object in case it gets severed
 */
/mob/living/carbon/human/proc/update_lips(new_style, new_colour, apply_trait)
	lip_style = new_style
	lip_color = new_colour
	update_body()

	var/obj/item/bodypart/head/hopefully_a_head = get_bodypart(BODY_ZONE_HEAD)
	REMOVE_TRAITS_IN(src, LIPSTICK_TRAIT)
	hopefully_a_head?.stored_lipstick_trait = null

	if(new_style && apply_trait)
		ADD_TRAIT(src, apply_trait, LIPSTICK_TRAIT)
		hopefully_a_head?.stored_lipstick_trait = apply_trait

/**
 * A wrapper for [mob/living/carbon/human/proc/update_lips] that tells us if there were lip styles to change
 */

/mob/living/carbon/human/proc/clean_lips()
	if(isnull(lip_style) && lip_color == initial(lip_color))
		return FALSE
	update_lips(null)
	return TRUE

/mob/living/carbon/human/clean_blood()
	var/mob/living/carbon/human/H = src
	if(H.gloves)
		if(H.gloves.clean_blood())
			H.update_inv_gloves()
	else
		..() // Clear the Blood_DNA list
		if(H.bloody_hands)
			H.bloody_hands = 0
			H.update_inv_gloves()
	update_icons()	//apply the now updated overlays to the mob

/mob/living/carbon/human/wash_cream()
	if(creamed) //clean both to prevent a rare bug
		cut_overlay(mutable_appearance('icons/effects/creampie.dmi', "creampie_snout"))
		cut_overlay(mutable_appearance('icons/effects/creampie.dmi', "creampie_human"))
		creamed = FALSE

//Turns a mob black, flashes a skeleton overlay
//Just like a cartoon!
/mob/living/carbon/human/proc/electrocution_animation(anim_duration)
	//Handle mutant parts if possible
	if(dna && dna.species)
		add_atom_colour("#000000", TEMPORARY_COLOUR_PRIORITY)
		var/static/mutable_appearance/electrocution_skeleton_anim
		if(!electrocution_skeleton_anim)
			electrocution_skeleton_anim = mutable_appearance(icon, "electrocuted_base")
			electrocution_skeleton_anim.appearance_flags |= RESET_COLOR|KEEP_APART
		add_overlay(electrocution_skeleton_anim)
		addtimer(CALLBACK(src, PROC_REF(end_electrocution_animation), electrocution_skeleton_anim), anim_duration)

	else //or just do a generic animation
		flick_overlay_view(image(icon,src,"electrocuted_generic",ABOVE_MOB_LAYER), src, anim_duration)

/mob/living/carbon/human/proc/end_electrocution_animation(mutable_appearance/MA)
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#000000")
	cut_overlay(MA)

/mob/living/carbon/human/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting = TRUE, silent = FALSE)
	if(incapacitated() || (check_resting && !CHECK_MOBILITY(src, MOBILITY_STAND)))
		if(!silent)
			to_chat(src, "<span class='warning'>You can't do that right now!</span>")
		return FALSE
	if(!Adjacent(M) && (M.loc != src))
		if((be_close == 0) || (!no_tk && (dna.check_mutation(TK) && tkMaxRangeCheck(src, M))))
			return TRUE
		if(!silent)
			to_chat(src, "<span class='warning'>You are too far away!</span>")
		return FALSE
	return TRUE

/mob/living/carbon/human/resist_restraints()
	if(wear_suit && wear_suit.breakouttime)
		MarkResistTime()
		cuff_resist(wear_suit)
	else
		..()

/mob/living/carbon/human/replace_records_name(oldname,newname) // Only humans have records right now, move this up if changed.
	for(var/list/L in list(GLOB.data_core.general,GLOB.data_core.medical,GLOB.data_core.security,GLOB.data_core.locked))
		var/datum/data/record/R = find_record("name", oldname, L)
		if(R)
			R.fields["name"] = newname

/mob/living/carbon/human/get_total_tint()
	. = ..()
	if(glasses)
		. += glasses.tint

/mob/living/carbon/human/update_health_hud()
	if(!client || !hud_used)
		return
	if(dna.species.update_health_hud())
		return
	else
		if(hud_used.healths)
			var/health_amount = min(health, maxHealth - clamp(getStaminaLoss()-50, 0, 80))//CIT CHANGE - makes staminaloss have less of an impact on the health hud
			if(..(health_amount)) //not dead
				switch(hal_screwyhud)
					if(SCREWYHUD_CRIT)
						hud_used.healths.icon_state = "health6"
					if(SCREWYHUD_DEAD)
						hud_used.healths.icon_state = "health7"
					if(SCREWYHUD_HEALTHY)
						hud_used.healths.icon_state = "health0"
		if(hud_used.healthdoll)
			hud_used.healthdoll.cut_overlays()
			if(stat != DEAD)
				hud_used.healthdoll.icon_state = "healthdoll_OVERLAY"
				for(var/X in bodyparts)
					var/obj/item/bodypart/BP = X
					var/damage = BP.burn_dam + BP.brute_dam
					var/comparison = (BP.max_damage/5)
					var/icon_num = 0
					if(damage)
						icon_num = 1
					if(damage > (comparison))
						icon_num = 2
					if(damage > (comparison*2))
						icon_num = 3
					if(damage > (comparison*3))
						icon_num = 4
					if(damage > (comparison*4))
						icon_num = 5
					if(hal_screwyhud == SCREWYHUD_HEALTHY)
						icon_num = 0
					if(icon_num)
						hud_used.healthdoll.add_overlay(mutable_appearance(ui_style_modular(hud_used.ui_style, "health"), "[BP.body_zone][icon_num]"))
				for(var/t in get_missing_limbs()) //Missing limbs
					hud_used.healthdoll.add_overlay(mutable_appearance(ui_style_modular(hud_used.ui_style, "health"), "[t]6"))
				for(var/t in get_disabled_limbs()) //Disabled limbs
					hud_used.healthdoll.add_overlay(mutable_appearance(ui_style_modular(hud_used.ui_style, "health"), "[t]7"))
			else
				hud_used.healthdoll.icon_state = "healthdoll_DEAD"

		hud_used.staminas?.update_icon_state()
		hud_used.staminabuffer?.mark_dirty()

/mob/living/carbon/human/fully_heal(admin_revive = FALSE)
	if(admin_revive)
		regenerate_limbs()
		regenerate_organs()
	remove_all_embedded_objects()
	set_heartattack(FALSE)
	drunkenness = 0
	for(var/datum/mutation/human/HM in dna.mutations)
		if(HM.quality != POSITIVE)
			dna.remove_mutation(HM.name)
	if(blood_volume < (BLOOD_VOLUME_NORMAL*blood_ratio))
		blood_volume = (BLOOD_VOLUME_NORMAL*blood_ratio)
	integrating_blood = 0
	..()

/mob/living/carbon/human/check_weakness(obj/item/weapon, mob/living/attacker)
	. = ..()
	if (dna && dna.species)
		. += dna.species.check_weakness(weapon, attacker)

/mob/living/carbon/human/is_literate()
	if(HAS_TRAIT(src, TRAIT_ILLITERATE))
		return FALSE
	return TRUE

/**
 * Proc that returns TRUE if the mob can write using the writing_instrument, FALSE otherwise.
 *
 * This proc a side effect, outputting a message to the mob's chat with a reason if it returns FALSE.
 */
/mob/proc/can_write(obj/item/writing_instrument)
	if(!istype(writing_instrument))
		to_chat(src, span_warning("You can't write with the [writing_instrument]!"))
		return FALSE

	if(!is_literate())
		to_chat(src, span_warning("You try to write, but don't know how to spell anything!"))
		return FALSE

	var/pen_info = writing_instrument.get_writing_implement_details()
	if(!pen_info || (pen_info["interaction_mode"] != MODE_WRITING))
		to_chat(src, span_warning("You can't write with the [writing_instrument]!"))
		return FALSE

	return TRUE

/mob/living/carbon/human/update_gravity(has_gravity,override = 0)
	if(dna && dna.species) //prevents a runtime while a human is being monkeyfied
		override = dna.species.override_float
	..()

/mob/living/carbon/human/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	// BLUEMOON ADD START - роботы не блюют
	if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
		return TRUE
	// BLUEMOON ADD END

	if(blood && dna?.species && (NOBLOOD in dna.species.species_traits))
		if(message)
			visible_message("<span class='warning'>[src] dry heaves!</span>", \
							"<span class='userdanger'>You try to throw up, but there's nothing in your stomach!</span>")
		if(stun)
			DefaultCombatKnockdown(200)
		return TRUE
	..()

/mob/living/carbon/human/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_COPY_OUTFIT, "Copy Outfit")
	VV_DROPDOWN_OPTION(VV_HK_MOD_QUIRKS, "Add/Remove Quirks")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_MONKEY, "Make Monkey")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_CYBORG, "Make Cyborg")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_SLIME, "Make Slime")
	VV_DROPDOWN_OPTION(VV_HK_MAKE_ALIEN, "Make Alien")
	VV_DROPDOWN_OPTION(VV_HK_SET_SPECIES, "Set Species")
	VV_DROPDOWN_OPTION(VV_HK_PURRBATION, "Toggle Purrbation")
	VV_DROPDOWN_OPTION(VV_HK_APPLY_PREFS, "Apply preferences")

/mob/living/carbon/human/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_COPY_OUTFIT])
		if(!check_rights(R_SPAWN))
			return
		copy_outfit()
	if(href_list[VV_HK_MOD_QUIRKS])
		usr.client.toggle_quirk(src)
	if(href_list[VV_HK_MAKE_MONKEY])
		if(!check_rights(R_SPAWN))
			return
		if(alert("Confirm mob type change?",,"Transform","Cancel") != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("monkeyone"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_CYBORG])
		if(!check_rights(R_SPAWN))
			return
		if(alert("Confirm mob type change?",,"Transform","Cancel") != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makerobot"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_ALIEN])
		if(!check_rights(R_SPAWN))
			return
		if(alert("Confirm mob type change?",,"Transform","Cancel") != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makealien"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_MAKE_SLIME])
		if(!check_rights(R_SPAWN))
			return
		if(alert("Confirm mob type change?",,"Transform","Cancel") != "Transform")
			return
		usr.client.holder.Topic("vv_override", list("makeslime"=href_list[VV_HK_TARGET]))
	if(href_list[VV_HK_SET_SPECIES])
		if(!check_rights(R_SPAWN))
			return
		var/result = input(usr, "Please choose a new species","Species") as null|anything in GLOB.species_list
		if(result)
			var/newtype = GLOB.species_list[result]
			admin_ticket_log("[key_name_admin(usr)] has modified the bodyparts of [src] to [result]")
			set_species(newtype)
	if(href_list[VV_HK_PURRBATION])
		if(!check_rights(R_SPAWN))
			return
		if(!ishumanbasic(src))
			to_chat(usr, "This can only be done to the basic human species at the moment.")
			return
		var/success = purrbation_toggle(src)
		if(success)
			to_chat(usr, "Put [src] on purrbation.")
			log_admin("[key_name(usr)] has put [key_name(src)] on purrbation.")
			var/msg = "<span class='notice'>[key_name_admin(usr)] has put [key_name(src)] on purrbation.</span>"
			message_admins(msg)
			admin_ticket_log(src, msg)

		else
			to_chat(usr, "Removed [src] from purrbation.")
			log_admin("[key_name(usr)] has removed [key_name(src)] from purrbation.")
			var/msg = "<span class='notice'>[key_name_admin(usr)] has removed [key_name(src)] from purrbation.</span>"
			message_admins(msg)
			admin_ticket_log(src, msg)
	if(href_list[VV_HK_APPLY_PREFS])
		if(!check_rights(R_SPAWN))
			return
		if(!client)
			var/bigtext = {"This action requires a client, if you need to do anything special, follow this short guide:
<blockquote class="info">
Mark this mob, then navigate to the preferences of the client you desire and call copy_to() with one argument, when it asks for the argument, browse to the bottom of the list and select marked datum, if you've followed this guide correctly, the mob will be turned into the character from the preferences you used.
</blockquote>
			"}
			to_chat(usr, bigtext)
			return

		var/datum/preferences/copying_this_one = client.prefs // turns out that prefs always exist if the client leaves, i'm not checking for client again
		var/is_this_guy_trolling_the_admin = copying_this_one.default_slot

		if(alert(usr, "Confirm reapply preferences?", "", "I'm sure", "Cancel") != "I'm sure")
			return

		if(is_this_guy_trolling_the_admin != copying_this_one.default_slot) // why would you do this, broooo
			if(alert(usr, "The user changed their character slot while you were deciding, are you sure you want to do this? They might change their mind again and i will not protect again this time", "Uh oh", "I'm sure", "They did what?") != "I'm sure")
				return

		copying_this_one.copy_to(src)
		var/change_text = "reapplied [key_name(src, TRUE)]'s preferences, [(is_this_guy_trolling_the_admin != copying_this_one.default_slot) ? "changing their character" : "resetting their character"]."
		to_chat(usr, capitalize(change_text))
		log_admin("[key_name(usr)] has [change_text]")
		message_admins(span_notice("[key_name_admin(usr)] has [change_text]"))
		admin_ticket_log(src, span_notice("[key_name_admin(usr, FALSE)] has [change_text]")) // In case they complained in an ahelp, we'll let them know anything happened

/mob/living/carbon/human/MouseDrop_T(mob/living/target, mob/living/user)
	var/GS_needed = istype(target, /mob/living/silicon/pai)? GRAB_PASSIVE : GRAB_AGGRESSIVE
	if(pulling == target && grab_state >= GS_needed && stat == CONSCIOUS)
		//If they dragged themselves and we're currently aggressively grabbing them try to piggyback
		if(user == target && can_piggyback(target))
			piggyback(target)
			return
		//If you dragged them to you and you're aggressively grabbing try to fireman carry them
		else if(user == src)
			if(user.a_intent == INTENT_GRAB)
				if(istype(belt, /obj/item/storage/belt/belly_riding))
					belly_ride(target)
				else
					fireman_carry(target)
				return
	. = ..()

//src is the user that will be carrying, target is the mob to be carried
/mob/living/carbon/human/proc/can_piggyback(mob/living/target)
	return !incapacitated(ignore_restraints = TRUE) && (istype(target) && target.stat == CONSCIOUS && CHECK_MOBILITY(src, MOBILITY_STAND))

/mob/living/carbon/human/proc/can_be_firemanned(mob/living/carbon/target)
	return (ishuman(target) && (!CHECK_MOBILITY(target, MOBILITY_STAND) || target.mob_weight < MOB_WEIGHT_NORMAL)) || ispAI(target)

/mob/living/carbon/human/proc/can_belly_ride(mob/living/carbon/target)
	return (ishuman(target) && target.mob_weight <= max(mob_weight, MOB_WEIGHT_NORMAL)) && !incapacitated(ignore_restraints = TRUE) && istype(belt, /obj/item/storage/belt/belly_riding) && target.stat != DEAD

/mob/living/carbon/human/proc/belly_ride(mob/living/carbon/target)
	if(target.stat == DEAD)
		to_chat(src, span_warning("Я не буду переносить труп на животе!"))
		return
	if(target.mob_weight > max(mob_weight, MOB_WEIGHT_NORMAL))
		to_chat(src, span_warning("Вы пытаетесь поднять [target], но [target.ru_who()] слишком тяжелая!"))
		return
	if(can_belly_ride(target))
		visible_message(span_warning("[src] начинает закреплять [target] в ремни на своем животе."),
		span_notice("Вы закрепяете [target] в ремни на своем животе."))
		if(do_after(src, RIDING_CARRYDELAY_BELLY, target, extra_checks = CALLBACK(src, PROC_REF(can_belly_ride), target)))
			if(can_belly_ride(target))
				buckle_mob(target, TRUE, TRUE, buckle_type = RIDING_BELLY, auto_by_type = TRUE)
				return
		visible_message(span_warning("[src] не закрепил [target] на своем животе!"))
	else
		if(ishuman(target))
			to_chat(src, span_notice("Вы не смогли закрепить [target] в ремни на своем животе!"))

/mob/living/carbon/human/proc/fireman_carry(mob/living/carbon/target)
	var/carrydelay = 40 //if you have latex you are faster at grabbing
	var/skills_space = "" //cobby told me to do this
	var/gloves_used = FALSE
	if(HAS_TRAIT(src, TRAIT_QUICKER_CARRY))
		if(HAS_TRAIT_FROM(src, TRAIT_QUICKER_CARRY, GLOVE_TRAIT))
			gloves_used = TRUE
		carrydelay = 20
		skills_space = "профессионально "
	// BLUEMOON ADDITION AHEAD making mind-based condition for job-specific qualification
	else if(HAS_TRAIT(src.mind, TRAIT_QUICK_CARRY))
		carrydelay = 20
		skills_space = "оперативно "
	// BLUEMOON ADDITION END
	else if(HAS_TRAIT(src, TRAIT_QUICK_CARRY) || target.mob_weight < MOB_WEIGHT_NORMAL)
		carrydelay = 27.5 // BLUEMOON EDIT making this a little bit useful
		skills_space = "быстро "
	// BLUEMOON ADDITION AHEAD - тяжёлых и сверхтяжёлых персонажей нельзя нести на плече
	if(target.mob_weight > MOB_WEIGHT_NORMAL)
		to_chat(src, span_warning("Вы пытаетесь поднять [target], но [target.ru_who()] слишком тяжелая!"))
		return
	// BLUEMOON ADDITION END
	if(can_be_firemanned(target) && !incapacitated(FALSE, TRUE))
		visible_message(span_notice("[src] [skills_space]поднимает [target] на свои плечи."),
		//Joe Medic starts quickly/expertly lifting Grey Tider onto their back..
		span_notice("[gloves_used ? "Используя перчатки с наночипами, вы" : "Вы"] [skills_space]поднимаете [target] на свои плечи."))
		//(Using your gloves' nanochips, you/You) ( /quickly/expertly) start to lift Grey Tider onto your back(, while assisted by the nanochips in your gloves../...)
		if(do_after(src, carrydelay, target, extra_checks = CALLBACK(src, PROC_REF(can_be_firemanned), target)))
			//Second check to make sure they're still valid to be carried
			if(can_be_firemanned(target) && !incapacitated(FALSE, TRUE))
				buckle_mob(target, TRUE, TRUE, buckle_type = RIDING_FIREMAN, auto_by_type = TRUE)
				return
		visible_message(span_warning("[src] не поднимает [target] за свои плечи!"))
	else
		if (ishuman(target))
			to_chat(src, span_notice("Вы не можете поднять [target] на свои плечи, ибо [target] стоит!"))
		else
			to_chat(src, span_notice("Вам не удалось поднять [src]."))

/mob/living/carbon/human/proc/piggyback(mob/living/carbon/target)
	if(can_piggyback(target))
		visible_message(span_notice("[target] начинает забираться на [src]..."))

		// BLUEMOON ADDITION START - тяжёлые персонажи дольше забираются на спину
		var/climb_on_time = 1.5 SECONDS
		switch(target.mob_weight)
			if(MOB_WEIGHT_HEAVY_SUPER)
				climb_on_time = 4 SECONDS
			if(MOB_WEIGHT_HEAVY)
				climb_on_time = 2.5 SECONDS
		// BLUEMOON ADDITION END

		if(do_after(target, climb_on_time, src, IGNORE_INCAPACITATED, extra_checks = CALLBACK(src, PROC_REF(can_piggyback), target)))
			if(can_piggyback(target))
				if(target.incapacitated(FALSE, TRUE) || incapacitated(FALSE, TRUE))
					target.visible_message(span_warning("[target] не может уцепиться за [src]!"))
					return
				// BLUEMOON ADDITION START
				if(target.mob_weight > MOB_WEIGHT_NORMAL)
					target.visible_message(span_warning("[target] слишком много весит для [src]!"))
					var/obj/item/bodypart/affecting = get_bodypart(BODY_ZONE_CHEST)
					var/wound_bon = 100
					var/damage = 40

					if(target.mob_weight > MOB_WEIGHT_HEAVY)
						wound_bon += 300
						damage += 120
						to_chat(src, span_danger("Умные мысли преследуют вас, но вы всегда быстрее!"))
						to_chat(target, span_danger("Вы случайно упали на [src], скорее всего сломав ему что-то!"))
					else
						to_chat(src, span_danger("Вы сминаетесь под весом [target]!"))
						to_chat(target, span_danger("Вы случайно упали на [src]!"))

					apply_damage(damage, BRUTE, affecting, wound_bonus=wound_bon)
					playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
					AddElement(/datum/element/squish, 20 SECONDS) // Totally not stolen from a vending machine code
					Knockdown(3 SECONDS) // Knocking down the unlucky guy
					target.Knockdown(1) // simply make the oversized one fall
					if(get_turf(target) != get_turf(src))
						target.throw_at(get_turf(src), 1, 1, FALSE, FALSE)
					// BLUEMOON ADDITION END
				buckle_mob(target, TRUE, TRUE, buckle_type = RIDING_PIGGYBACK, auto_by_type = TRUE)
		else
			visible_message(span_warning("[target] не удаётся забраться на [src]!"))
	else
		to_chat(target, span_warning("Ты не можешь прокатиться на спине [src] прямо сейчас!"))

/mob/living/carbon/human/buckle_mob(mob/living/target, force = FALSE, check_loc = TRUE, lying_buckle = 0, hands_needed = 0, target_hands_needed = 0, buckle_type = RIDING_PIGGYBACK, auto_by_type = FALSE)
	if(!force)//humans are only meant to be ridden through piggybacking and special cases
		return
	if(!istype(target))
		return FALSE
	if(!is_type_in_typecache(target, can_ride_typecache))
		target.visible_message(span_warning("[target] действительно не может забраться на [src]..."))
		return
	if(target.has_buckled_mobs())
		return FALSE

	// Автосмена типа перевозки для тавров, если это RIDING_BELLY
	if(RIDING_IS_BELLY(buckle_type))
		buckle_type = RIDING_BELLY

		// Переносимый, проверка на то, что тавры могут быть только переносчиками, но не носимыми
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			if(!(H.dna?.features["taur"] in list(null, "None")))
				var/datum/sprite_accessory/taur/T = GLOB.taur_list[H.dna.features["taur"]]
				if(T && T.taur_mode != STYLE_SNEK_TAURIC)
					target.visible_message(span_warning("[target] не может уместиться в ремни [src]..."))
					return

		// Переносчик, проверка, что он 4х лапый, а не змея
		if(!(dna?.features["taur"] in list(null, "None")))
			var/datum/sprite_accessory/taur/T = GLOB.taur_list[dna.features["taur"]]
			if(T?.taur_mode in list(STYLE_PAW_TAURIC, STYLE_HOOF_TAURIC))
				buckle_type = RIDING_BELLY_TAUR

	// Пресеты настроек по типу переноски
	if(auto_by_type)
		switch(buckle_type)
			if(RIDING_PIGGYBACK)
				lying_buckle = 0
				hands_needed = 1
				target_hands_needed = 2
			if(RIDING_FIREMAN)
				lying_buckle = 90
				hands_needed = 1
				target_hands_needed = 0
			if(RIDING_PRINCESS)
				lying_buckle = 90
				hands_needed = 2
				target_hands_needed = 0
			if(RIDING_FACE_TO_FACE)
				lying_buckle = 0
				hands_needed = 1
				target_hands_needed = 0
			if(RIDING_BELLY, RIDING_BELLY_TAUR)
				lying_buckle = 0
				hands_needed = 0
				target_hands_needed = 0

	buckle_lying = lying_buckle
	var/datum/component/riding/human/riding_datum = LoadComponent(/datum/component/riding/human)
	if(target_hands_needed)
		riding_datum.ride_check_rider_restrained = TRUE
	if(buckled_mobs && ((target in buckled_mobs) || (buckled_mobs.len >= max_buckled_mobs)) || buckled)
		return
	if(istype(target, /mob/living/silicon/pai))
		hands_needed = 1
		target_hands_needed = 0
	var/equipped_hands_self
	var/equipped_hands_target
	if(hands_needed)
		equipped_hands_self = riding_datum.equip_buckle_inhands(src, hands_needed, target)
	if(target_hands_needed)
		equipped_hands_target = riding_datum.equip_buckle_inhands(target, target_hands_needed)

	if(hands_needed || target_hands_needed)
		if(hands_needed && !equipped_hands_self)
			src.visible_message(span_warning("[src] can't get a grip on [target] because their hands are full!"),
				span_warning("You can't get a grip on [target] because your hands are full!"))
			return
		else if(target_hands_needed && !equipped_hands_target)
			target.visible_message(span_warning("[target] can't get a grip on [src] because their hands are full!"),
				span_warning("You can't get a grip on [src] because your hands are full!"))
			return

	stop_pulling()
	riding_datum.buckle_type = buckle_type
	riding_datum.handle_vehicle_layer(dir)
	if(RIDING_IS_BELLY(buckle_type))
		riding_datum.belly_harness = belt
	. = ..(target, force, check_loc)
	if(!.)
		visible_message(span_warning("[src] не смог(ла) поднять [target]."))
		riding_datum.unequip_buckle_inhands(src)
		riding_datum.unequip_buckle_inhands(target)

/mob/living/carbon/human/proc/is_shove_knockdown_blocked() //If you want to add more things that block shove knockdown, extend this
	for(var/obj/item/clothing/C in get_equipped_items()) //doesn't include pockets
		if(C.blocks_shove_knockdown)
			return TRUE
	return FALSE

/mob/living/carbon/human/updatehealth()
	. = ..()
	dna?.species.spec_updatehealth(src)
	if(HAS_TRAIT(src, TRAIT_IGNORESLOWDOWN))	//if we want to ignore slowdown from damage and equipment
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)
		return
	if(!HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))	//if we want to ignore slowdown from damage, but not from equipment
		var/scaling = maxHealth / 100
		var/health_deficiency = max(((maxHealth / scaling) - (health / scaling)), max(0, getStaminaLoss() - 39))
		if(health_deficiency >= 40)
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown, TRUE, health_deficiency / 75)
			add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying, TRUE, health_deficiency / 25)
		else
			remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
			remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown)
		remove_movespeed_modifier(/datum/movespeed_modifier/damage_slowdown_flying)

/mob/living/carbon/human/is_bleeding()
	if(NOBLOOD in dna.species.species_traits || bleedsuppress)
		return FALSE
	return ..()

/mob/living/carbon/human/get_total_bleed_rate()
	if(NOBLOOD in dna.species.species_traits)
		return FALSE
	return ..()

/mob/living/carbon/human/species
	var/race = null

/mob/living/carbon/human/species/Initialize(mapload)
	. = ..()
	set_species(race)

/**
 * # `spec_trait_examine_font()`
 *
 * This gets a humanoid's special examine font, which is used to color their species name during examine / health analyzing.
 * The first of these that applies is returned.
 * Returns:
 * * Metallic font if robotic
 * * Cyan if a toxinlover
 * * Purple if plasmaperson
 * * Rock / Brownish if a golem
 * * Green if none of the others apply (aka, generic organic)
*/
/mob/living/carbon/human/proc/spec_trait_examine_font()
	if(HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM))
		return "<font color='#aaa9ad'>"
	if(HAS_TRAIT(src, TRAIT_TOXINLOVER))
		return "<font color='#00ffff'>"
	if(isplasmaman(src))
		return "<font color='#800080'>"
	if(isgolem(src))
		return "<font color='#8b4513'>"
	return "<font color='#18d855'>"


/mob/living/carbon/human/get_tooltip_data()
	/*var/t_He = ru_who(TRUE)
	var/t_is = p_are()
	. = list()
	var/skipface = (wear_mask && (wear_mask.flags_inv & HIDEFACE)) || (head && (head.flags_inv & HIDEFACE))
	if(skipface || get_visible_name() == "Unknown")
		. += "You can't make out what species they are."
	else
		. += "[t_He] [t_is] a [spec_trait_examine_font()][dna.custom_species ? dna.custom_species : dna.species.name]</font>"
	SEND_SIGNAL(src, COMSIG_PARENT_EXAMINE, usr, .)*/
	if(activity)
		. = list()
		. += activity


/mob/living/carbon/human/get_access_locations()
	. = ..()
	. |= list(wear_id, w_uniform)

/mob/living/carbon/human/chestonly
	bodyparts = list(/obj/item/bodypart/chest)

/mob/living/carbon/human/species/abductor
	race = /datum/species/abductor

/mob/living/carbon/human/species/android
	race = /datum/species/android

/mob/living/carbon/human/species/corporate
	race = /datum/species/corporate

/mob/living/carbon/human/species/felinid
	race = /datum/species/human/felinid

/mob/living/carbon/human/species/fly
	race = /datum/species/fly

/mob/living/carbon/human/species/golem
	race = /datum/species/golem

/mob/living/carbon/human/species/golem/random
	race = /datum/species/golem/random

/mob/living/carbon/human/species/golem/adamantine
	race = /datum/species/golem/adamantine

/mob/living/carbon/human/species/golem/plasma
	race = /datum/species/golem/plasma

/mob/living/carbon/human/species/golem/diamond
	race = /datum/species/golem/diamond

/mob/living/carbon/human/species/golem/gold
	race = /datum/species/golem/gold

/mob/living/carbon/human/species/golem/silver
	race = /datum/species/golem/silver

/mob/living/carbon/human/species/golem/plasteel
	race = /datum/species/golem/plasteel

/mob/living/carbon/human/species/golem/titanium
	race = /datum/species/golem/titanium

/mob/living/carbon/human/species/golem/plastitanium
	race = /datum/species/golem/plastitanium

/mob/living/carbon/human/species/golem/alien_alloy
	race = /datum/species/golem/alloy

/mob/living/carbon/human/species/golem/wood
	race = /datum/species/golem/wood

/mob/living/carbon/human/species/golem/uranium
	race = /datum/species/golem/uranium

/mob/living/carbon/human/species/golem/sand
	race = /datum/species/golem/sand

/mob/living/carbon/human/species/golem/glass
	race = /datum/species/golem/glass

/mob/living/carbon/human/species/golem/bluespace
	race = /datum/species/golem/bluespace

/mob/living/carbon/human/species/golem/bananium
	race = /datum/species/golem/bananium

/mob/living/carbon/human/species/golem/blood_cult
	race = /datum/species/golem/runic

/mob/living/carbon/human/species/golem/cloth
	race = /datum/species/golem/cloth

/mob/living/carbon/human/species/golem/plastic
	race = /datum/species/golem/plastic

/mob/living/carbon/human/species/golem/bronze
	race = /datum/species/golem/bronze

/mob/living/carbon/human/species/golem/cardboard
	race = /datum/species/golem/cardboard

/mob/living/carbon/human/species/golem/leather
	race = /datum/species/golem/leather

/mob/living/carbon/human/species/golem/bone
	race = /datum/species/golem/bone

/mob/living/carbon/human/species/golem/durathread
	race = /datum/species/golem/durathread

/mob/living/carbon/human/species/golem/clockwork
	race = /datum/species/golem/clockwork

/mob/living/carbon/human/species/golem/clockwork/no_scrap
	race = /datum/species/golem/clockwork/no_scrap

/mob/living/carbon/human/species/jelly
	race = /datum/species/jelly

/mob/living/carbon/human/species/jelly/slime
	race = /datum/species/jelly/slime

/mob/living/carbon/human/species/jelly/stargazer
	race = /datum/species/jelly/stargazer

/mob/living/carbon/human/species/jelly/luminescent
	race = /datum/species/jelly/luminescent

/mob/living/carbon/human/species/lizard
	race = /datum/species/lizard

/mob/living/carbon/human/species/ethereal
	race = /datum/species/ethereal

/mob/living/carbon/human/species/lizard/ashwalker
	race = /datum/species/lizard/ashwalker

/mob/living/carbon/human/species/insect
	race = /datum/species/insect

/mob/living/carbon/human/species/mush
	race = /datum/species/mush

/mob/living/carbon/human/species/plasma
	race = /datum/species/plasmaman

/mob/living/carbon/human/species/pod
	race = /datum/species/pod

/mob/living/carbon/human/species/shadow
	race = /datum/species/shadow

/mob/living/carbon/human/species/shadow/nightmare
	race = /datum/species/shadow/nightmare

/mob/living/carbon/human/species/skeleton
	race = /datum/species/skeleton

/mob/living/carbon/human/species/synth
	race = /datum/species/synth

/mob/living/carbon/human/species/synth/military
	race = /datum/species/synth/military

/mob/living/carbon/human/species/vampire
	race = /datum/species/vampire

/mob/living/carbon/human/species/zombie
	race = /datum/species/zombie

/mob/living/carbon/human/species/zombie/infectious
	race = /datum/species/zombie/infectious

/mob/living/carbon/human/species/zombie/krokodil_addict
	race = /datum/species/krokodil_addict

/mob/living/carbon/human/species/mammal
	race = /datum/species/mammal

/mob/living/carbon/human/species/insect
	race = /datum/species/insect

/mob/living/carbon/human/species/xeno
	race = /datum/species/xeno

/mob/living/carbon/human/species/ipc
	race = /datum/species/ipc

/mob/living/carbon/human/species/roundstartslime
	race = /datum/species/jelly/roundstartslime

/mob/living/carbon/human/species/arachnid
	race = /datum/species/arachnid

/mob/living/carbon/human/singularity_pull(S, current_size)
	..()
	if(current_size >= STAGE_THREE)
		for(var/obj/item/hand in held_items)
			if(prob(current_size * 5) && hand.w_class >= ((11-current_size)/2)  && dropItemToGround(hand))
				step_towards(hand, src)
				to_chat(src, span_warning("\The [S] pulls \the [hand] from your grip!"))

///Sets up the jump component for the mob. Proc args can be altered so different mobs have different 'default' jump settings
/mob/living/proc/set_jump_component(duration = 0.5 SECONDS, cooldown = 1 SECONDS, cost = 64, height = 16, sound = null, flags = JUMP_SHADOW, flags_pass = PASSTABLE)
	if(HAS_TRAIT(src, TRAIT_FREERUNNING))
		AddComponent(/datum/component/jump, _jump_duration = duration, _jump_cooldown = cooldown, _stamina_cost = 32, _jump_height = height, _jump_sound = sound, _jump_flags = flags, _jumper_allow_pass_flags = flags_pass)
	else
		AddComponent(/datum/component/jump, _jump_duration = duration, _jump_cooldown = cooldown, _stamina_cost = cost, _jump_height = height, _jump_sound = sound, _jump_flags = flags, _jumper_allow_pass_flags = flags_pass)
