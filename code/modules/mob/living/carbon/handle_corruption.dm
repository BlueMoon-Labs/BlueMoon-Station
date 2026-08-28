//////////////////////////////////////
//SYSTEM CORRUPTION FOR ROBOT-PEOPLE//
//////////////////////////////////////

//Moved into its own file for easier accessability & less cluttering of carbon/life.dm. Used in BiologicalLife()


#define CORRUPTION_CHECK_INTERVAL 10   //Life() is called once every second, so ten seconds interval.
#define CORRUPTION_THRESHHOLD_MINOR 10 //Above: Annoyances, to remind you you should get your corruption fixed.
#define CORRUPTION_THRESHHOLD_MAJOR 35 //Above: Very annoying stuff, go get fixed.
#define CORRUPTION_THRESHHOLD_CRITICAL 65 //Above: Extremely annoying stuff, possibly life-threatening
#define CORRUPTION_THRESHHOLD_CATASTROPHIC 100 //Above: Extremely annoying stuff, possibly life-threatening

/mob/living/carbon/proc/handle_corruption()
	if(!HAS_TRAIT(src, TRAIT_ROBOTIC_ORGANISM)) //Only robot-people need to care about this
		return
	corruption_timer++
	var/corruption = getToxLoss(toxins_type = TOX_SYSCORRUPT)
	var/corruption_state
	var/timer_req = CORRUPTION_CHECK_INTERVAL
	switch(corruption)
		if(0 to CORRUPTION_THRESHHOLD_MINOR)
			timer_req = INFINITY //Below minor corruption you are fiiine
			corruption_state = "<font color='green'>None</font>" //This should never happen, but have it anyways.
		if(CORRUPTION_THRESHHOLD_MINOR to CORRUPTION_THRESHHOLD_MAJOR)
			corruption_state = "<font color='blue'>Minor</font>"
			error_handler(1)
		if(CORRUPTION_THRESHHOLD_MAJOR to CORRUPTION_THRESHHOLD_CRITICAL)
			timer_req -= 1
			corruption_state = "<font color='orange'>Major</font>"
			error_handler(2)
		if(CORRUPTION_THRESHHOLD_CRITICAL to CORRUPTION_THRESHHOLD_CATASTROPHIC)
			timer_req -= 2
			corruption_state = "<font color='red'>Critical</font>"
			error_handler(3)
		if(CORRUPTION_THRESHHOLD_CATASTROPHIC to INFINITY)
			timer_req -= 3
			corruption_state = "<font color='red'>CATASTROPHIC</font>"
			error_handler(4)
	if(corruption_timer < timer_req)
		return
	corruption_timer = 0
	if(!prob(corruption)) //Lucky you beat the rng roll!
		return
	var/list/whatmighthappen = list()
	whatmighthappen += list("avoided" = 3, "dropthing" = 1, "movetile" = 1, "shortdeaf" = 1, "flopover" = 1, "nutriloss" = 1, "selfflash" = 1, "harmies" = 1)
	if(corruption >= CORRUPTION_THRESHHOLD_MAJOR)
		whatmighthappen += list("longdeaf" = 1, "longknockdown" = 1, "shortlimbdisable" = 1, "shortblind" = 1, "shortstun" = 1, "shortmute" = 1, "vomit" = 1, "hallucinate" = 1, "jamcoolanthud" = 1)
	if(corruption >= CORRUPTION_THRESHHOLD_CRITICAL)
		whatmighthappen += list("receporgandamage" = 1, "longlimbdisable" = 1, "blindmutedeaf" = 1, "longstun" = 1, "sleep" = 1, "inducetrauma" = 1, "amplifycorrupt" = 1, "changetemp" = 1)
	var/event = pickweight(whatmighthappen)
	log_message("has been affected by [event] due to system corruption of [corruption], with a corruption state of [corruption_state]", LOG_ATTACK)
	var/size = rand(12, 24)
	switch(event)
		if("avoided")
			to_chat(src, "<span class='notice'>System malfunction avoided by hardware safeguards - intervention recommended.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "System malfunction avoided by hardware safeguards - intervention recommended.", "SYSTEM", null, 12)
			adjustToxLoss(-0.2, toxins_type = TOX_SYSCORRUPT) //If you roll this, your system safeguards caught onto the system corruption and neutralised a bit of it.
		if("dropthing")
			drop_all_held_items()
			to_chat(src, "<span class='warning'>Error - Malfunction in arm circuitry.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Malfunction in arm circuitry.", "ERROR", null, size)
		if("movetile")
			if(CHECK_MOBILITY(src, MOBILITY_MOVE) && !ismovable(loc))
				step(src, pick(GLOB.cardinals))
				to_chat(src, "<span class='warning'>Error - Malfunction in movement control subsystem.</span>")
				SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Malfunction in movement control subsystem.", "ERROR", null, size)
		if("shortdeaf")
			ADD_TRAIT(src, TRAIT_DEAF, CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_hearing)), 5 SECONDS)
			to_chat(src, "<span class='hear'><b>ZZZZT</b></span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "ZZZZT", "ERROR", null, 20)
		if("flopover")
			DefaultCombatKnockdown(1)
			to_chat(src, "<span class='warning'>Error - Malfunction in actuator circuitry.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Malfunction in actuator circuitry.", "ERROR", null, size)
		if("nutriloss")
			adjust_nutrition(-50)
			to_chat(src, "<span class='warning'>Power surge detected in internal battery cell.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Power surge detected in internal battery cell.", "ERROR", null, size)
		if("selfflash")
			if(flash_act(override_protection = 1))
				confused += 4
				to_chat(src, "<span class='warning'>Error - Sensory system overload detected!</span>")
				SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Sensory system overload detected!", "ERROR", null, size)
		if("harmies")
			a_intent_change(INTENT_HARM)
			to_chat(src, "<span class='notice'>Intent subsystem successfully recalibrated.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Intent subsystem successfully recalibrated.", "SYSTEM", null, size)
		if("longdeaf")
			ADD_TRAIT(src, TRAIT_DEAF, CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_hearing)), 20 SECONDS)
			to_chat(src, "<span class='notice'>Hearing subsystem successfully shutdown.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Hearing subsystem successfully shutdown.", "SYSTEM", null, size)
		if("longknockdown")
			DefaultCombatKnockdown(50)
			to_chat(src, "<span class='warning'>Significant error in actuator subsystem - Rebooting.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Significant error in actuator subsystem - Rebooting.", "SYSTEM", null, size)
		if("shortlimbdisable")
			var/disabled_type = pick(list(TRAIT_PARALYSIS_L_ARM, TRAIT_PARALYSIS_R_ARM, TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG))
			ADD_TRAIT(src, disabled_type, CORRUPTED_SYSTEM)
			update_disabled_bodyparts()
			addtimer(CALLBACK(src, PROC_REF(reenable_limb), disabled_type), 5 SECONDS)
			to_chat(src, "<span class='warning'>Error - Limb control subsystem partially shutdown, rebooting.</span>")
		if("shortblind")
			become_blind(CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_vision)), 5 SECONDS)
			to_chat(src, "<span class='warning'>Visual receptor shutdown detected - Initiating reboot.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Visual receptor shutdown detected - Initiating reboot.", "SYSTEM", null, size)
		if("shortstun")
			Stun(30)
			var/code = rand(101, 999)
			to_chat(src, "<span class='warning'>Deadlock detected in primary systems, error code [code].</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Deadlock detected in primary systems, error code [code].", "ERROR", null, size)
		if("shortmute")
			ADD_TRAIT(src, TRAIT_MUTE, CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_speech)), 5 SECONDS)
			to_chat(src, "<span class='notice'>Communications matrix successfully shutdown for maintenance.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Communications matrix successfully shutdown for maintenance.", "SYSTEM", null, size)
		if("vomit")
			to_chat(src, "<span class='notice'>Ejecting contaminant.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Ejecting contaminant.", "SYSTEM", null, size)
			vomit()
		if("hallucinate")
			hallucination += 20 //Doesn't give a cue
		if("jamcoolanthud")
			hud_used.coolant_display.jam(10)
		if("receporgandamage")
			adjustOrganLoss(ORGAN_SLOT_EARS, rand(10, 20))
			adjustOrganLoss(ORGAN_SLOT_EYES, rand(10, 20))
			to_chat(src, "<span class='warning'>Power spike detected in auditory and visual systems!</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Power spike detected in auditory and visual systems!", "ERROR", null, size)
		if("longlimbdisable")
			var/disabled_type = pick(list(TRAIT_PARALYSIS_L_ARM, TRAIT_PARALYSIS_R_ARM, TRAIT_PARALYSIS_L_LEG, TRAIT_PARALYSIS_R_LEG))
			ADD_TRAIT(src, disabled_type, CORRUPTED_SYSTEM)
			update_disabled_bodyparts()
			addtimer(CALLBACK(src, PROC_REF(reenable_limb), disabled_type), 25 SECONDS)
			to_chat(src, "<span class='warning'>Fatal error in limb control subsystem - rebooting.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Fatal error in limb control subsystem - rebooting.", "ERROR", null, size)
		if("blindmutedeaf")
			become_blind(CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_vision)), (rand(10, 25)) SECONDS)
			ADD_TRAIT(src, TRAIT_DEAF, CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_hearing)), (rand(15, 35)) SECONDS)
			ADD_TRAIT(src, TRAIT_MUTE, CORRUPTED_SYSTEM)
			addtimer(CALLBACK(src, PROC_REF(reenable_speech)), (rand(20, 45)) SECONDS)
			to_chat(src, "<span class='warning'>Fatal error in multiple systems - Performing recovery.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Fatal error in multiple systems - Performing recovery.", "ERROR", null, size)
		if("longstun")
			Stun(80)
			to_chat(src, "<span class='warning'>Critical divide-by-zero error detected - Failsafe initiated.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Critical divide-by-zero error detected - Failsafe initiated.", "ERROR", null, size)
		if("sleep")
			addtimer(CALLBACK(src, PROC_REF(forcesleep)), (rand(6, 10)) SECONDS)
			to_chat(src, "<span class='warning'>Priority 1 shutdown order received in operating system - Preparing powerdown.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Priority 1 shutdown order received in operating system - Preparing powerdown.", "ERROR", null, size)
		if("inducetrauma")
			to_chat(src, "<span class='warning'>Major interference detected in main operating matrix - Complications possible.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Major interference detected in main operating matrix - Complications possible.", "ERROR", null, size)
			var/resistance = pick(
				65;TRAUMA_RESILIENCE_BASIC,
				35;TRAUMA_RESILIENCE_SURGERY)

			var/trauma_type = pickweight(list(
				BRAIN_TRAUMA_MILD = 80,
				BRAIN_TRAUMA_SEVERE = 10))
			gain_trauma_type(trauma_type, resistance) //Gaining the trauma will inform them, but we'll tell them too so they know what the reason was.
		if("amplifycorrupt")
			adjustToxLoss(5, toxins_type = TOX_SYSCORRUPT)
			to_chat(src, "<span class='warning'>System safeguards failing - Action urgently required.</span>")
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "System safeguards failing - Action urgently required.", "ERROR", null, size)
		if("changetemp")
			adjust_bodytemperature(rand(150, 250))
			var/node = rand(6, 99)
			to_chat(src, "<span class='warning'>Warning - Fatal coolant flow error at node [node]!</span>") //This is totally not a reference to anything.
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Warning - Fatal coolant flow error at node [node]!", "ERROR", null, size)

/mob/living/carbon/proc/reenable_limb(disabled_limb)
	REMOVE_TRAIT(src, disabled_limb, CORRUPTED_SYSTEM)
	update_disabled_bodyparts()
	to_chat(src, "<span class='notice'>Limb control subsystem successfully rebooted.</span>")
	SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Limb control subsystem successfully rebooted.", "SYSTEM", null, 12)

/mob/living/carbon/proc/reenable_hearing()
	REMOVE_TRAIT(src, TRAIT_DEAF, CORRUPTED_SYSTEM)
	to_chat(src, "<span class='notice'>Hearing restored.</span>")
	SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Hearing restored.", "SYSTEM", null, 12)

/mob/living/carbon/proc/reenable_vision()
	cure_blind(CORRUPTED_SYSTEM)
	to_chat(src, "<span class='notice'>Visual receptors back online.</span>")
	SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Visual receptors back online.", "SYSTEM", null, 12)

/mob/living/carbon/proc/reenable_speech()
	REMOVE_TRAIT(src, TRAIT_MUTE, CORRUPTED_SYSTEM)
	to_chat(src, "<span class='notice'>Communications subsystem operational.</span>")
	SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Communications subsystem operational.", "SYSTEM", null, 12)

/mob/living/carbon/proc/forcesleep(time = 100)
	to_chat(src, "<span class='notice'>Preparations complete, powering down.</span>")
	SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "Preparations complete, powering down.", "SYSTEM", null, 12)
	Sleeping(time)

/mob/living/carbon/proc/error_handler(severity)
	var/size = rand(9, 22)
	var/memory = rand(11111111, 99999999)
	switch(severity)
		if(1)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "EXCEPTION ENCOUNTERED: ERROR 0x[memory]", "ERROR", null, 12)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "EXCEPTION", "0x[memory]", 10 SECONDS)
		if(2)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "EX4444@#PTION ENC@#RED: ER@##OR 0x[memory]", "ERROR", null, 12)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "E@[rand(1, 9)]!#P[rand(1, 9)]TION[rand(1, 9)]", "0x[memory]@##@", 5 SECONDS)
		if(3)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "EX12@#PTION ENC@#@ED: ER@##OR 0@##x[memory]@#$ 2 3 @ # #@34#@#", "E@$E@#", "#ff0000", size)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "E@[rand(1, 9)]!#P[rand(1, 9)]TION[rand(1, 9)]", "[rand(1, 9)]x[memory]@##@", 5 SECONDS)
		if(4)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_LOG, "EXggg@#PTION ENC@#@ED C#RI@#ROITI#ICAL: ER@##OR 0@##x[memory]@#$ 2 @##@#CRIT F@#AIL 3 @ # #@34#@@#@#", "E###########SWE@#", "#ff0000", size)
			SEND_SIGNAL(src, COMSIG_NEURAL_INTERFACE_WRITE_DATA, "@#$@#!@#$@[rand(1, 9)]!#@$$[rand(1, 9)]@$$@$[rand(1, 9)]$@@!@!$HH[rand(1, 9)]AHAHAHHAHAHAHAHAHA[rand(1, 9)]", "[rand(1, 9)]x[memory]@##HELP@##@#AHASHHAHAHAHA", 5 SECONDS)



#undef CORRUPTION_CHECK_INTERVAL
#undef CORRUPTION_THRESHHOLD_MINOR
#undef CORRUPTION_THRESHHOLD_MAJOR
#undef CORRUPTION_THRESHHOLD_CRITICAL
#undef CORRUPTION_THRESHHOLD_CATASTROPHIC
