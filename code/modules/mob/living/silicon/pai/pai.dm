/mob/living/silicon/pai
	name = "pAI"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"
	density = FALSE
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	desc = "A generic pAI mobile hard-light holographics emitter. It seems to be deactivated."
	health = 500
	maxHealth = 500
	layer = BELOW_MOB_LAYER
	var/obj/item/instrument/piano_synth/internal_instrument
	silicon_privileges = PRIVILEGES_PAI

	var/network = "ss13"
	var/obj/machinery/camera/current = null

	var/ram = 100	// Used as currency to purchase different abilities
	var/list/software = list()
	var/userDNA		// The DNA string of our assigned user
	var/obj/item/paicard/card	// The card we inhabit
	var/hacking = FALSE		//Are we hacking a door?

	var/speakStatement = "states"
	var/speakExclamation = "declares"
	var/speakDoubleExclamation = "alarms"
	var/speakQuery = "queries"

	var/obj/item/radio/headset			// The pAI's headset
	var/obj/item/pai_cable/cable		// The cable we produce and use when door or camera jacking

	var/master				// Name of the one who commands us
	var/master_dna			// DNA string for owner verification

// Various software-specific vars

	var/temp				// General error reporting text contained here will typically be shown once and cleared
	var/screen				// Which screen our main window displays
	var/subscreen			// Which specific function of the main screen is being displayed

	var/obj/item/modular_computer/pda/silicon/pai/pda = null

	var/secHUD = 0			// Toggles whether the Security HUD is active or not
	var/medHUD = 0			// Toggles whether the Medical  HUD is active or not

	var/datum/data/record/medicalActive1		// Datacore record declarations for record software
	var/datum/data/record/medicalActive2

	var/datum/data/record/securityActive1		// Could probably just combine all these into one
	var/datum/data/record/securityActive2

	var/obj/machinery/door/hackdoor		// The airlock being hacked
	var/obj/machinery/camera/hackcamera		// The camera being hacked
	var/hackprogress = 0				// Possible values: 0 - 100, >= 100 means the hack is complete and will be reset upon next check

	var/heartbeat_sensor = FALSE		// Whether the heartbeat sensor is active
	var/heartbeat_alert_cooldown = 0	// Cooldown for heartbeat alerts

	var/obj/item/integrated_signaler/signaler // AI's signaller

	var/encryptmod = FALSE
	var/holoform = FALSE
	var/canholo = TRUE
	var/chassis = "repairbot"
	var/dynamic_chassis
	var/dynamic_chassis_sit = FALSE			//whether we're sitting instead of resting spritewise
	var/dynamic_chassis_bellyup = FALSE		//whether we're lying down bellyup
	var/list/possible_chassis			//initialized in initialize.
	var/list/dynamic_chassis_icons		//ditto.
	var/list/chassis_pixel_offsets_x	//stupid dogborgs

	var/emitterhealth = 20
	var/emittermaxhealth = 20
	var/emitterregen = 0.25
	var/emitter_next_use = 0
	var/emitter_emp_cd = 300
	var/emittercd = 50
	var/emitteroverloadcd = 100

	var/radio_short = FALSE
	var/radio_short_cooldown = 3 MINUTES
	var/radio_short_timerid

	mobility_flags = MOBILITY_UI
	var/silent = FALSE
	var/brightness_power = 5

	var/icon/custom_holoform_icon

/mob/living/silicon/pai/Destroy()
	QDEL_NULL(signaler)
	QDEL_NULL(pda)
	QDEL_NULL(internal_instrument)
	if(cable)
		QDEL_NULL(cable)
	hackdoor = null
	medicalActive1 = null
	medicalActive2 = null
	securityActive1 = null
	securityActive2 = null
	if (loc != card)
		card.forceMove(drop_location())
	card.pai = null
	card.cut_overlays()
	card.add_overlay("pai-off")
	card = null
	current = null
	GLOB.pai_list -= src
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/mob/living/silicon/pai/Initialize(mapload)
	var/obj/item/paicard/P = loc
	START_PROCESSING(SSfastprocess, src)
	GLOB.pai_list += src
	make_laws()
	if(!istype(P)) //when manually spawning a pai, we create a card to put it into.
		var/newcardloc = P
		P = new /obj/item/paicard(newcardloc)
		P.setPersonality(src)
	forceMove(P)
	card = P
	signaler = new(src)
	if(!radio)
		radio = new /obj/item/radio/headset/silicon/pai(src)

	//PDA
	pda = new(src)
	pda.ownjob = "pAI Messenger"
	pda.owner = text("[]", src)
	pda.name = pda.owner + " (" + pda.ownjob + ")"
	pda.saved_identification = pda.owner
	pda.saved_job = pda.ownjob

	possible_chassis = typelist(NAMEOF(src, possible_chassis), list("cat" = TRUE, "mouse" = TRUE, "monkey" = TRUE, "corgi" = FALSE,
									"fox" = TRUE, "repairbot" = TRUE, "rabbit" = TRUE, "borgi" = TRUE ,
									"parrot" = TRUE, "bear" = FALSE , "mushroom" = TRUE, "crow" = TRUE ,
									"fairy" = TRUE , "spiderbot" = TRUE, "snake" = FALSE, "pAIkemon_Espeon" = TRUE,
									"Syndicat" = FALSE, "Syndifox" = FALSE))		//assoc value is whether it can be picked up.
	dynamic_chassis_icons = typelist(NAMEOF(src, dynamic_chassis_icons), initialize_dynamic_chassis_icons())
	chassis_pixel_offsets_x = typelist(NAMEOF(src, chassis_pixel_offsets_x), default_chassis_pixel_offsets_x())

	. = ..()

	var/datum/action/innate/pai/software/SW = new
	var/datum/action/innate/pai/shell/AS = new /datum/action/innate/pai/shell
	var/datum/action/innate/pai/chassis/AC = new /datum/action/innate/pai/chassis
	var/datum/action/innate/pai/rest/AR = new /datum/action/innate/pai/rest
	var/datum/action/innate/pai/light/AL = new /datum/action/innate/pai/light
	var/datum/action/innate/custom_holoform/custom_holoform = new /datum/action/innate/custom_holoform

	SW.Grant(src)
	AS.Grant(src)
	AC.Grant(src)
	AR.Grant(src)
	AL.Grant(src)
	custom_holoform.Grant(src)
	emitter_next_use = world.time + 10 SECONDS

/mob/living/silicon/pai/deployed/Initialize(mapload)
	. = ..()
	fold_out(TRUE)

/mob/living/silicon/pai/ComponentInitialize()
	. = ..()
	if(possible_chassis[chassis])
		AddElement(/datum/element/mob_holder, chassis, 'icons/mob/pai_item_head.dmi', 'icons/mob/pai_item_rh.dmi', 'icons/mob/pai_item_lh.dmi', ITEM_SLOT_HEAD)

/mob/living/silicon/pai/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	if(hacking)
		process_hack()
	if(heartbeat_sensor)
		process_heartbeat()

/mob/living/silicon/pai/proc/process_hack()
	if(!cable || !cable.machine || get_dist(src, cable.machine) > 1)
		temp = "Джек: соединение потеряно. Взлом отменён."
		hackprogress = 0
		hacking = FALSE
		hackdoor = null
		hackcamera = null
		return
	if(istype(cable.machine, /obj/machinery/door) && cable.machine == hackdoor)
		hackprogress = clamp(hackprogress + 4, 0, 100)
		if(screen == "doorjack" && subscreen == 0)
			paiInterface()
		if(hackprogress >= 100)
			hackprogress = 0
			var/obj/machinery/door/D = cable.machine
			D.open()
			hacking = FALSE
	else if(istype(cable.machine, /obj/machinery/camera) && cable.machine == hackcamera)
		hackprogress = clamp(hackprogress + 4, 0, 100)
		if(screen == "camerajack" && subscreen == 0)
			paiInterface()
		if(hackprogress >= 100)
			hackprogress = 0
			var/obj/machinery/camera/C = cable.machine
			C.toggle_cam(src, 0)
			hacking = FALSE
			temp = "Взлом камеры: камера отключена."
	else
		temp = "Джек: соединение потеряно. Взлом отменён."
		hackprogress = 0
		hacking = FALSE
		hackdoor = null
		hackcamera = null

/mob/living/silicon/pai/proc/process_heartbeat()
	var/mob/living/M = card.loc
	var/count = 0
	while(!isliving(M))
		if(!M || !M.loc || count >= 6)
			return
		M = M.loc
		count++
	if(M.stat == DEAD && world.time > heartbeat_alert_cooldown)
		to_chat(src, "<span class='danger'>Сенсор пульса: ФЛАТЛАЙН у [M.name]!</span>")
		heartbeat_alert_cooldown = world.time + 30 SECONDS
	else if(M.health <= 0 && world.time > heartbeat_alert_cooldown)
		to_chat(src, "<span class='warning'>Сенсор пульса: критическое состояние [M.name]!</span>")
		heartbeat_alert_cooldown = world.time + 30 SECONDS

/mob/living/silicon/pai/make_laws()
	laws = new /datum/ai_laws/pai()
	return TRUE

/mob/living/silicon/pai/Login()
	..()
	usr << browse_rsc('html/paigrid.png')			// Go ahead and cache the interface resources as early as possible
	if(client)
		client.perspective = EYE_PERSPECTIVE
		if(holoform)
			client.eye = src
		else
			client.eye = card

/mob/living/silicon/pai/get_status_tab_items()
	. += ..()
	if(!stat)
		. += text("Emitter Integrity: [emitterhealth * (100/emittermaxhealth)]")
	else
		. += text("Systems nonfunctional")

/mob/living/silicon/pai/restrained(ignore_grab)
	. = FALSE

/mob/living/silicon/pai/can_interact_with(atom/target)
	if(istype(target, /obj/item/mod/control)) // A poor workaround for enabling MODsuit control
		var/obj/item/mod/control/C = target
		if(C.ai == src)
			return TRUE
	return ..()

// See software.dm for Topic()

/mob/living/silicon/pai/canUseTopic(atom/movable/M, be_close=FALSE, no_dextery=FALSE, no_tk=FALSE, check_resting=FALSE, silent = FALSE)
	if(be_close && !in_range(M, src))
		if(!silent)
			to_chat(src, "<span class='warning'>You are too far away!</span>")
		return FALSE
	return TRUE

/mob/proc/makePAI(delold)
	var/obj/item/paicard/card = new /obj/item/paicard(get_turf(src))
	var/mob/living/silicon/pai/pai = new /mob/living/silicon/pai(card)
	transfer_ckey(pai)
	pai.name = name
	card.setPersonality(pai)
	if(delold)
		qdel(src)

/datum/action/innate/pai
	name = "PAI Action"
	icon_icon = 'icons/mob/actions/actions_silicon.dmi'
	var/mob/living/silicon/pai/P

/datum/action/innate/pai/Trigger()
	if(!ispAI(owner))
		return FALSE
	P = owner

/datum/action/innate/pai/software
	name = "Software Interface"
	button_icon_state = "pai"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/software/Trigger()
	..()
	P.paiInterface()

/datum/action/innate/pai/shell
	name = "Toggle Holoform"
	button_icon_state = "pai_holoform"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/shell/Trigger()
	..()
	if(P.holoform)
		P.fold_in(FALSE)
	else
		P.fold_out()

/datum/action/innate/pai/chassis
	name = "Holochassis Appearance Composite"
	button_icon_state = "pai_chassis"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/chassis/Trigger()
	..()
	P.choose_chassis()

/datum/action/innate/pai/rest
	name = "Rest"
	button_icon_state = "pai_rest"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/rest/Trigger()
	..()
	P.lay_down()

/datum/action/innate/pai/light
	name = "Toggle Integrated Lights"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "emp"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/light/Trigger()
	..()
	P.toggle_integrated_light()

/mob/living/silicon/pai/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..(movement_dir, continuous_move)
	if(!.)
		add_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
		return TRUE
	remove_movespeed_modifier(/datum/movespeed_modifier/pai_spacewalk)
	return TRUE

/mob/living/silicon/pai/examine(mob/user)
	. = ..()
	. += "A personal AI in holochassis mode. Its master ID string seems to be [master]."

/mob/living/silicon/pai/PhysicalLife()
	. = ..()
	if(cable)
		if(get_dist(src, cable) > 1)
			var/turf/T = get_turf(src.loc)
			T.visible_message("<span class='warning'>[src.cable] rapidly retracts back into its spool.</span>", "<span class='italics'>You hear a click and the sound of wire spooling rapidly.</span>")
			qdel(src.cable)
			cable = null

/mob/living/silicon/pai/BiologicalLife()
	if(!(. = ..()))
		return
	silent = max(silent - 1, 0)

/mob/living/silicon/pai/updatehealth()
	if(status_flags & GODMODE)
		return
	health = maxHealth - getBruteLoss() - getFireLoss()
	update_stat()

/mob/living/silicon/pai/process()
	emitterhealth = clamp((emitterhealth + emitterregen), -50, emittermaxhealth)

/obj/item/paicard/attackby(obj/item/W, mob/user, params)
	..()
	user.set_machine(src)
	var/encryption_key_stuff = W.tool_behaviour == TOOL_SCREWDRIVER || istype(W, /obj/item/encryptionkey)
	if(!encryption_key_stuff)
		return
	if(pai?.encryptmod)
		pai.radio.attackby(W, user, params)
	else
		to_chat(user, "Encryption Key ports not configured.")

/obj/item/paicard/attack_ghost(mob/dead/observer/user)
	if(pai)
		to_chat(user, "<span class='warning'>This pAI is already in use!</span>")
		return

	var/area/A = get_area(get_turf(src))
	if(A.type in SSpai.restricted_areas) // set in subsystem/pai.dm on initialize of the subsystem
		to_chat(user, "<span class='warning'>You can't download yourself into a restricted area!</span>")
		return

	var/pai_name = reject_bad_name(stripped_input(usr, "Enter a name for your pAI", "pAI Name", user.name, MAX_NAME_LEN), TRUE)
	if(!pai_name)
		to_chat(user, "<span class='warning'>Entered name is not valid.</span>")
		return

	var/mob/living/silicon/pai/new_pai = new(src)
	new_pai.name = pai_name
	new_pai.real_name = new_pai.name
	new_pai.key = user.key

	setPersonality(new_pai)

	SSticker.mode?.update_cult_icons_removed(pai.mind)

/obj/item/paicard/emag_act(mob/user) // Emag to wipe the master DNA and supplemental directive
	. = ..()
	if(!pai)
		return
	to_chat(user, "<span class='notice'>You override [pai]'s directive system, clearing its master string and supplied directive.</span>")
	to_chat(pai, "<span class='danger'>Warning: System override detected, check directive sub-system for any changes.'</span>")
	log_admin("[key_name(user)] emagged [key_name(pai)], wiping their master DNA and supplemental directive at [AREACOORD(src)]")
	pai.master = null
	pai.master_dna = null
	pai.laws.supplied[1] = "None." // Sets supplemental directive to this

/mob/living/silicon/pai/proc/short_radio()
	if(radio_short_timerid)
		deltimer(radio_short_timerid)
	radio_short = TRUE
	to_chat(src, "<span class='danger'>Your radio shorts out!</span>")
	radio_short_timerid = addtimer(CALLBACK(src, PROC_REF(unshort_radio)), radio_short_cooldown, flags = TIMER_STOPPABLE)

/mob/living/silicon/pai/proc/unshort_radio()
	radio_short = FALSE
	to_chat(src, "<span class='danger'>You feel your radio is operational once more.</span>")
	if(radio_short_timerid)
		deltimer(radio_short_timerid)

/mob/living/silicon/pai/proc/initialize_dynamic_chassis_icons()
	. = list()
	var/icon/curr		//for inserts

	//This is a horrible system and I wish I was not as lazy and did something smarter, like just generating a new icon in memory which is probably more efficient.

	//Basic /tg/ cyborgs
	.["Cyborg - Engineering (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "engineer"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (loaderborg)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "loaderborg"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (handyeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "handyeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (sleekeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "sleekeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (marinaeng)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinaeng"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "medical"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (marinamed)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinamed"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (eyebotmed)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "eyebotmed"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "sec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (sleeksec)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "sleeksec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (marinasec)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/robots.dmi', "marinasec"), HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Clown (default)"] = process_holoform_icon_filter(icon('icons/mob/robots.dmi', "clown"), HOLOFORM_FILTER_PAI, FALSE)

	//Citadel dogborgs
	//Engi
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeeng-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (dog - valeeng)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "pupdozer-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Engineering (dog - pupdozer)"] = curr
	//Med
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "medihound")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihound-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - medihound)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "medihounddark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - medihounddark)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valemed")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valemed-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Medical (dog - valemed)"] = curr
	//Sec
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "k9")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - k9)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "k9dark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - k9dark)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valesec")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesec-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Security (dog - valesec)"] = curr
	//Service
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeserv-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Service (dog - valeserv)"] = curr
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valeservdark-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Service (dog - valeservdark)"] = curr
	//Sci
	curr = icon('modular_citadel/icons/mob/widerobot.dmi', "valesci")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-rest"), "rest")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-sit"), "sit")
	curr.Insert(icon('modular_citadel/icons/mob/widerobot.dmi', "valesci-bellyup"), "bellyup")
	process_holoform_icon_filter(curr, HOLOFORM_FILTER_PAI, FALSE)
	.["Cyborg - Science (dog - valesci)"] = curr
	//Misc
	.["Cyborg - Misc (dog - blade)"] = process_holoform_icon_filter(icon('modular_citadel/icons/mob/widerobot.dmi', "blade"), HOLOFORM_FILTER_PAI, FALSE)

	// Gorillas
	.["Gorilla (standing)"] = process_holoform_icon_filter(icon('icons/mob/gorilla.dmi', "standing"), HOLOFORM_FILTER_PAI, FALSE)
	.["Gorilla (crawling)"] = process_holoform_icon_filter(icon('icons/mob/gorilla.dmi', "crawling"), HOLOFORM_FILTER_PAI, FALSE)

/mob/living/silicon/pai/proc/default_chassis_pixel_offsets_x()
	. = list()
	//Engi
	.["Cyborg - Engineering (dog - valeeng)"] = -16
	.["Cyborg - Engineering (dog - pupdozer)"] = -16
	//Med
	.["Cyborg - Medical (dog - medihound)"] = -16
	.["Cyborg - Medical (dog - medihounddark)"] = -16
	.["Cyborg - Medical (dog - valemed)"] = -16
	//Sec
	.["Cyborg - Security (dog - k9)"] = -16
	.["Cyborg - Security (dog - valesec)"] = -16
	.["Cyborg - Security (dog - k9dark)"] = -16
	//Service
	.["Cyborg - Service (dog - valeserv)"] = -16
	.["Cyborg - Service (dog - valeservdark)"] = -16
	//Sci
	.["Cyborg - Security (dog - valesci)"] = -16
	//Misc
	.["Cyborg - Misc (dog - blade)"] = -16

/mob/living/silicon/pai/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PaiSoftware")
		ui.set_autoupdate(TRUE)
		ui.open()

/mob/living/silicon/pai/ui_data(mob/user)
	var/list/data = list()
	data["screen"] = screen
	data["subscreen"] = subscreen
	data["ram"] = ram
	data["software"] = software
	data["available_software"] = available_software
	data["master"] = master
	data["master_dna"] = master_dna
	data["laws_zeroth"] = laws?.zeroth
	data["laws_supplied"] = laws?.supplied
	data["temp"] = temp
	data["stat"] = stat
	data["secHUD"] = secHUD
	data["medHUD"] = medHUD
	data["encryptmod"] = encryptmod
	data["radio_short"] = radio_short
	data["signaler_frequency"] = signaler ? signaler.frequency : null
	data["signaler_code"] = signaler ? signaler.code : null
	data["hackprogress"] = hackprogress
	data["hacking"] = hacking
	data["cable_extended"] = cable ? TRUE : FALSE
	data["cable_connected"] = (cable?.machine) ? TRUE : FALSE
	data["pda_installed"] = pda ? TRUE : FALSE
	data["heartbeat_sensor"] = heartbeat_sensor
	data["emitterhealth"] = emitterhealth
	data["emittermaxhealth"] = emittermaxhealth
	data["holoform"] = holoform
	// Unread messages from PDA messenger
	data["messenger_unread"] = 0
	if(pda)
		var/datum/computer_file/program/messenger/messenger = locate() in pda.get_all_files()
		if(messenger)
			for(var/chat_ref in messenger.saved_chats)
				var/datum/pda_chat/chat = messenger.saved_chats[chat_ref]
				data["messenger_unread"] += chat.unread_messages

	var/datum/language_holder/H = get_language_holder()
	data["translator_on"] = H?.omnitongue ? TRUE : FALSE

	// Crew manifest
	data["crew_manifest"] = list()
	if(GLOB.data_core.general)
		for(var/datum/data/record/t in sortRecord(GLOB.data_core.general))
			data["crew_manifest"] += list(list(
				"name" = t.fields["name"],
				"rank" = t.fields["rank"],
			))

	// Medical records list
	data["medical_records"] = list()
	if(GLOB.data_core.general)
		for(var/datum/data/record/R in sortRecord(GLOB.data_core.general))
			data["medical_records"] += list(list(
				"id" = R.fields["id"],
				"name" = R.fields["name"],
				"rank" = R.fields["rank"],
			))

	// Security records list
	data["security_records"] = list()
	if(GLOB.data_core.general)
		for(var/datum/data/record/R in sortRecord(GLOB.data_core.general))
			data["security_records"] += list(list(
				"id" = R.fields["id"],
				"name" = R.fields["name"],
				"rank" = R.fields["rank"],
			))

	// Active medical record
	data["medical_active1"] = null
	data["medical_active2"] = null
	if(medicalActive1)
		data["medical_active1"] = list(
			"name" = medicalActive1.fields["name"],
			"id" = medicalActive1.fields["id"],
			"gender" = medicalActive1.fields["gender"],
			"age" = medicalActive1.fields["age"],
			"fingerprint" = medicalActive1.fields["fingerprint"],
			"p_stat" = medicalActive1.fields["p_stat"],
			"m_stat" = medicalActive1.fields["m_stat"],
		)
	if(medicalActive2)
		data["medical_active2"] = list(
			"blood_type" = medicalActive2.fields["blood_type"],
			"b_dna" = medicalActive2.fields["b_dna"],
			"mi_dis" = medicalActive2.fields["mi_dis"],
			"mi_dis_d" = medicalActive2.fields["mi_dis_d"],
			"ma_dis" = medicalActive2.fields["ma_dis"],
			"ma_dis_d" = medicalActive2.fields["ma_dis_d"],
			"alg" = medicalActive2.fields["alg"],
			"alg_d" = medicalActive2.fields["alg_d"],
			"cdi" = medicalActive2.fields["cdi"],
			"cdi_d" = medicalActive2.fields["cdi_d"],
			"notes" = medicalActive2.fields["notes"],
		)

	// Active security record
	data["security_active1"] = null
	data["security_active2"] = null
	if(securityActive1)
		data["security_active1"] = list(
			"name" = securityActive1.fields["name"],
			"id" = securityActive1.fields["id"],
			"gender" = securityActive1.fields["gender"],
			"age" = securityActive1.fields["age"],
			"rank" = securityActive1.fields["rank"],
			"fingerprint" = securityActive1.fields["fingerprint"],
			"p_stat" = securityActive1.fields["p_stat"],
			"m_stat" = securityActive1.fields["m_stat"],
		)
	if(securityActive2)
		data["security_active2"] = list(
			"criminal" = securityActive2.fields["criminal"],
			"mi_crim" = securityActive2.fields["mi_crim"],
			"mi_crim_d" = securityActive2.fields["mi_crim_d"],
			"ma_crim" = securityActive2.fields["ma_crim"],
			"ma_crim_d" = securityActive2.fields["ma_crim_d"],
			"notes" = securityActive2.fields["notes"],
		)

	// Atmosphere
	var/turf/T = get_turf(loc)
	if(!isnull(T))
		var/datum/gas_mixture/environment = T.return_air()
		if(environment)
			data["atmo_pressure"] = round(environment.return_pressure(), 0.1)
			data["atmo_temp"] = round(environment.return_temperature() - T0C)
			data["atmo_gases"] = list()
			var/total_moles = environment.total_moles()
			if(total_moles)
				for(var/id in environment.get_gases())
					var/gas_level = environment.get_moles(id)/total_moles
					if(gas_level > 0.01)
						data["atmo_gases"] += list(list(
							"name" = GLOB.gas_data.names[id],
							"percent" = round(gas_level*100),
						))
		else
			data["atmo_pressure"] = null
	else
		data["atmo_pressure"] = null

	// Bioscan data
	data["bioscan"] = null
	if(subscreen == 1 && screen == "medicalhud")
		var/mob/living/M = card.loc
		var/count = 0
		while(!isliving(M))
			if(!M || !M.loc || count >= 6)
				data["bioscan"] = list("error" = "Биологический носитель не найден.")
				break
			M = M.loc
			count++
		if(isliving(M) && !data["bioscan"])
			var/list/bioscan = list()
			bioscan["name"] = M.name
			bioscan["stat"] = M.stat > 1 ? "мертв" : "[M.health]% здоровья"
			bioscan["oxy"] = M.getOxyLoss()
			bioscan["tox"] = M.getToxLoss()
			bioscan["burn"] = M.getFireLoss()
			bioscan["brute"] = M.getBruteLoss()
			bioscan["temp_c"] = M.bodytemperature - T0C
			bioscan["diseases"] = list()
			for(var/thing in M.diseases)
				var/datum/disease/D = thing
				bioscan["diseases"] += list(list(
					"name" = D.name,
					"spread" = D.spread_text,
					"stage" = D.stage,
					"max_stages" = D.max_stages,
					"cure" = D.cure_text,
				))
			data["bioscan"] = bioscan

	return data

/mob/living/silicon/pai/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("set_screen")
			var/new_screen = params["screen"]
			screen = new_screen
			subscreen = text2num(params["sub"]) || 0
			return TRUE
		if("buy")
			var/target = params["buy"]
			if(available_software.Find(target) && !software.Find(target))
				var/cost = available_software[target]
				if(ram >= cost)
					software.Add(target)
					ram -= cost
				else
					temp = "Недостаточно ОЗУ."
			else
				temp = "Модуль \"[target]\" не найден."
			return TRUE
		if("radio")
			radio.attack_self(src)
			return TRUE
		if("image")
			var/newImage = tgui_input_list(src, "Выберите новое изображение экрана.", "Изображение экрана", list("Happy", "Cat", "Extremely Happy", "Face", "Laugh", "Off", "Sad", "Angry", "What", "Exclamation", "Question", "Sunglasses", "Mal-0"))
			if(!newImage)
				return
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
			return TRUE
		if("signaller_send")
			signaler.send_activation()
			audible_message("[icon2html(src, hearers(src))] *beep* *beep* *beep*")
			playsound(src, 'sound/machines/triple_beep.ogg', ASSEMBLY_BEEP_VOLUME, TRUE)
			return TRUE
		if("signaller_freq")
			var/new_frequency = signaler.frequency + text2num(params["freq"])
			if(new_frequency < MIN_FREE_FREQ || new_frequency > MAX_FREE_FREQ)
				new_frequency = sanitize_frequency(new_frequency)
			signaler.set_frequency(new_frequency)
			return TRUE
		if("signaller_code")
			signaler.code += text2num(params["code"])
			signaler.code = round(signaler.code)
			signaler.code = min(100, signaler.code)
			signaler.code = max(1, signaler.code)
			return TRUE
		if("directive_dna")
			var/mob/living/M = card.loc
			var/count = 0
			while(!isliving(M))
				if(!M || !M.loc)
					return FALSE
				M = M.loc
				count++
				if(count >= 6)
					to_chat(src, "Вас никто не носит!")
					return FALSE
			INVOKE_ASYNC(src, PROC_REF(CheckDNA), M)
			return TRUE
		if("medicalrecord_select")
			medicalActive1 = GLOB.data_core.general_by_id[params["id"]]
			if(medicalActive1)
				medicalActive2 = GLOB.data_core.medical_by_id[params["id"]]
			if(!medicalActive2)
				medicalActive1 = null
				temp = "Не удалось найти запрошенную мед. карту."
			subscreen = 1
			return TRUE
		if("securityrecord_select")
			securityActive1 = GLOB.data_core.general_by_id[params["id"]]
			if(securityActive1)
				securityActive2 = GLOB.data_core.security_by_id[params["id"]]
			if(!securityActive2)
				securityActive1 = null
				temp = "Не удалось найти запрошенную служ. карту."
			subscreen = 1
			return TRUE
		if("toggle_sec_hud")
			secHUD = !secHUD
			if(secHUD)
				var/datum/atom_hud/sec = GLOB.huds[sec_hud]
				sec.add_hud_to(src)
			else
				var/datum/atom_hud/sec = GLOB.huds[sec_hud]
				sec.remove_hud_from(src)
			return TRUE
		if("toggle_med_hud")
			medHUD = !medHUD
			if(medHUD)
				var/datum/atom_hud/med = GLOB.huds[med_hud]
				med.add_hud_to(src)
			else
				var/datum/atom_hud/med = GLOB.huds[med_hud]
				med.remove_hud_from(src)
			return TRUE
		if("toggle_encrypt")
			encryptmod = TRUE
			return TRUE
		if("toggle_translator")
			grant_all_languages(source = LANGUAGE_SOFTWARE)
			return TRUE
		if("doorjack_start")
			if(cable && cable.machine)
				hackdoor = cable.machine
				hackloop()
			return TRUE
		if("doorjack_cancel")
			hackdoor = null
			return TRUE
		if("doorjack_cable")
			var/turf/T = get_turf(loc)
			cable = new /obj/item/pai_cable(T)
			T.visible_message("<span class='warning'>Порт на [src] открывается, оттуда высыпается [cable] и падает на пол.</span>", "<span class='italics'>Ты слышишь лёгкий щелчок чего-то твёрдого, падающего на землю.</span>")
			return TRUE
		if("camerajack_start")
			if(cable && cable.machine && istype(cable.machine, /obj/machinery/camera))
				hackcamera = cable.machine
				hackloop()
			return TRUE
		if("camerajack_cancel")
			hackcamera = null
			return TRUE
		if("toggle_heartbeat")
			heartbeat_sensor = !heartbeat_sensor
			if(heartbeat_sensor)
				to_chat(src, "<span class='notice'>Сенсор пульса активирован.</span>")
			else
				to_chat(src, "<span class='notice'>Сенсор пульса деактивирован.</span>")
			return TRUE
		if("toggle_projection")
			if(holoform)
				fold_in()
			else
				fold_out()
			return TRUE
		if("messenger")
			if(pda)
				var/datum/computer_file/program/messenger/messenger = locate() in pda.get_all_files()
				if(messenger)
					messenger.run_program(src)
					pda.active_program = messenger
					messenger.ui_interact(src)
				else
					to_chat(src, "<span class='warning'>Мессенджер не найден!</span>")
			else
				to_chat(src, "<span class='warning'>PDA не установлен!</span>")
			return TRUE
		if("quick_reply")
			if(pda)
				var/datum/computer_file/program/messenger/messenger = locate() in pda.get_all_files()
				if(messenger)
					var/datum/pda_chat/target_chat = null
					for(var/chat_ref in messenger.saved_chats)
						var/datum/pda_chat/chat = messenger.saved_chats[chat_ref]
						if(chat.unread_messages > 0)
							target_chat = chat
							break
					if(target_chat)
						messenger.quick_reply_prompt(src, target_chat)
					else
						messenger.run_program(src)
						pda.active_program = messenger
						messenger.ui_interact(src)
				else
					to_chat(src, "<span class='warning'>Мессенджер не найден!</span>")
			else
				to_chat(src, "<span class='warning'>PDA не установлен!</span>")
			return TRUE
		if("loudness_open")
			if(!internal_instrument)
				internal_instrument = new(src)
			internal_instrument.ui_interact(src)
			return TRUE
		if("medical_bioscan")
			subscreen = 1
			return TRUE
		if("clear_temp")
			temp = null
			return TRUE
		if("refresh")
			return TRUE

/mob/living/silicon/pai/proc/paiInterface()
	ui_interact(src)
