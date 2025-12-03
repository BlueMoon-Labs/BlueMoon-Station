#define AUTOCLONING_MINIMAL_LEVEL 4

/obj/machinery/computer/cloning
	name = "cloning console"
	desc = "Used to clone people and manage DNA."
	icon_screen = "dna"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/computer/cloning
	req_access = list(ACCESS_HEADS) //ONLY USED FOR RECORD DELETION RIGHT NOW.
	var/obj/machinery/dna_scannernew/scanner = null //Linked scanner. For scanning.
	var/clonepod_type = /obj/machinery/clonepod
	var/list/pods //Linked cloning pods
	var/cloning_message = ""
	var/cloning_flag = "info" // TGUI
	var/scanned_ckey
	var/scanned_name
	var/scan_message = ""
	var/scan_flag = "info" // TGUI
	var/obj/item/disk/data/diskette = null //Mostly so the geneticist can steal everything.
	var/autoprocess = 0
	var/use_records = TRUE // Old experimental cloner.
	var/list/records = list()

	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/cloning/Initialize(mapload)
	. = ..()
	updatemodules(TRUE)
	var/obj/item/circuitboard/computer/cloning/board = circuit
	records = board.records

/obj/machinery/computer/cloning/Destroy()
	if(pods)
		for(var/P in pods)
			DetachCloner(P)
		pods = null
	return ..()

/obj/machinery/computer/cloning/proc/SetScanMessage(message = "", flag = "info")
	scan_message = message
	scan_flag = flag

/obj/machinery/computer/cloning/proc/SetCloningMessage(message = "", flag = "info")
	cloning_message = message
	cloning_flag = flag

/obj/machinery/computer/cloning/proc/GetAvailablePod()
	if(!pods)
		return
	for(var/P in pods)
		var/obj/machinery/clonepod/pod = P
		if(pod.occupant && pod.get_clone_mind == CLONEPOD_GET_MIND && pod.clonemind == null)
			return null
		if(pod.is_operational() && !(pod.occupant || pod.mess))
			return pod

/obj/machinery/computer/cloning/proc/get_pods_status()
	var/list/result = list()

	for(var/obj/machinery/clonepod/pod in pods)
		var/list/L

		if(!pod.is_operational())
			L = list("status"="Offline", "color"="bad")
		else if(pod.mess)
			L = list("status"="Messy", "color"="bad")
		else if(pod.occupant && pod.occupant.loc == pod)
			var/mob/living/O = pod.occupant
			L = list("status"="Cloning [O.real_name] [round(pod.get_completion())]%", "color"="orange")
		else
			L = list("status"="Online", "color"="good")

		result += list(L)

	return result

/obj/machinery/computer/cloning/proc/HasEfficientPod()
	if(!pods)
		return
	for(var/P in pods)
		var/obj/machinery/clonepod/pod = P
		if(pod.is_operational() && pod.efficiency > 5)
			return TRUE

/obj/machinery/computer/cloning/proc/GetAvailableEfficientPod(mind = null)
	if(!pods)
		return
	for(var/P in pods)
		var/obj/machinery/clonepod/pod = P
		if(pod.occupant && pod.clonemind == mind)
			return pod
		else if(!. && pod.is_operational() && !(pod.occupant || pod.mess) && pod.efficiency > 5)
			. = pod

/obj/machinery/computer/cloning/process()
	if(!(scanner && LAZYLEN(pods) && autoprocess))
		return

	for(var/datum/data/record/R in records)
		var/obj/machinery/clonepod/pod = GetAvailableEfficientPod(R.fields["mind"])

		if(!pod)
			return

		if(pod.occupant)
			continue	//how though?

		if(pod.growclone(R.fields["ckey"], R.fields["name"], R.fields["UI"], R.fields["SE"], R.fields["mind"], R.fields["blood_type"], R.fields["mrace"], R.fields["features"], R.fields["factions"], R.fields["quirks"], R.fields["bank_account"], R.fields["traumas"]))
			SetCloningMessage("[R.fields["name"]] => Cloning cycle in progress...", "warning")
			records -= R

/obj/machinery/computer/cloning/proc/updatemodules(findfirstcloner)
	src.scanner = findscanner()
	if(findfirstcloner && !LAZYLEN(pods))
		findcloner()
	if(!autoprocess)
		STOP_PROCESSING(SSmachines, src)
	else
		START_PROCESSING(SSmachines, src)

/obj/machinery/computer/cloning/proc/findscanner()
	var/obj/machinery/dna_scannernew/scannerf = null

	// Loop through every direction
	for(var/direction in GLOB.cardinals)

		// Try to find a scanner in that direction
		scannerf = locate(/obj/machinery/dna_scannernew, get_step(src, direction))

		// If found and operational, return the scanner
		if (!isnull(scannerf) && scannerf.is_operational())
			return scannerf

	// If no scanner was found, it will return null
	return null

/obj/machinery/computer/cloning/proc/findcloner()
	var/obj/machinery/clonepod/podf
	for(var/direction in GLOB.cardinals)
		podf = locate(clonepod_type, get_step(src, direction))
		if(podf?.is_operational())
			AttachCloner(podf)

/obj/machinery/computer/cloning/proc/AttachCloner(obj/machinery/clonepod/pod)
	if(!pod.connected)
		pod.connected = src
		LAZYADD(pods, pod)

/obj/machinery/computer/cloning/proc/DetachCloner(obj/machinery/clonepod/pod)
	pod.connected = null
	LAZYREMOVE(pods, pod)

/obj/machinery/computer/cloning/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/disk/data)) //INSERT SOME DISKETTES
		if (!src.diskette)
			if (!user.transferItemToLoc(W,src))
				return
			src.diskette = W
			to_chat(user, "<span class='notice'>You insert [W].</span>")
			playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, 0)
	else if(W.tool_behaviour == TOOL_MULTITOOL)
		if(istype(W.buffer, clonepod_type))
			if(get_area(W.buffer) != get_area(src))
				to_chat(user, "<font color = #666633>-% Cannot link machines across power zones. Buffer cleared %-</font color>")
				W.buffer = null
				return
			to_chat(user, "<font color = #666633>-% Successfully linked [W.buffer] with [src] %-</font color>")
			var/obj/machinery/clonepod/pod = W.buffer
			if(pod.connected)
				pod.connected.DetachCloner(pod)
			AttachCloner(pod)
		else
			W.buffer = src
			to_chat(user, "<font color = #666633>-% Successfully stored [REF(W.buffer)] [W.buffer] in buffer %-</font color>")
		return
	else
		return ..()

/obj/machinery/computer/cloning/AltClick(mob/user)
	. = ..()
	EjectDisk(user)

/obj/machinery/computer/cloning/proc/EjectDisk(mob/user)
	if(diskette)
		SetScanMessage("Disk Ejected", "success")
		diskette.forceMove(drop_location())
		usr.put_in_active_hand(diskette)
		diskette = null
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, 0)

/obj/machinery/computer/cloning/proc/Save(mob/user, target)
	var/datum/data/record/GRAB = null
	for(var/datum/data/record/record in records)
		if(record.fields["id"] == target)
			GRAB = record
			break
		else
			continue
	if(!GRAB || !GRAB.fields)
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
		SetScanMessage("Failed saving to disk: Data Corruption","danger")
		return FALSE
	if(!diskette || diskette.read_only)
		SetScanMessage(!diskette ? "Failed saving to disk: No disk." : "Failed saving to disk: Disk refuses override attempt.","danger")
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
		return
	diskette.fields = GRAB.fields.Copy()
	diskette.name = "data disk - '[src.diskette.fields["name"]]'"
	SetScanMessage("Saved to disk successfully.","success")
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)

/obj/machinery/computer/cloning/proc/DeleteRecord(mob/user, target)
	var/datum/data/record/GRAB = null
	for(var/datum/data/record/record in records)
		if(record.fields["id"] == target)
			GRAB = record
			break
		else
			continue
	if(!GRAB)
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
		SetScanMessage("Cannot delete: Data Corrupted.","danger")
		return FALSE
	var/obj/item/card/id/C = usr.get_idcard(hand_first = TRUE)
	if(istype(C) || istype(C, /obj/item/pda) || istype(C, /obj/item/modular_computer/tablet))
		if(check_access(C))
			SetScanMessage("[GRAB.fields["name"]] => Record deleted.","warning")
			records.Remove(GRAB)
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)
			var/obj/item/circuitboard/computer/cloning/board = circuit
			board.records = records
			return TRUE
	SetScanMessage("Cannot delete: Access Denied.","danger")
	playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)

/obj/machinery/computer/cloning/proc/Load(mob/user)
	if(!diskette || !istype(diskette.fields) || !diskette.fields["name"] || !diskette.fields)
		SetScanMessage("Failed loading: Load error.","danger")
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
		return
	for(var/datum/data/record/R in records)
		if(R.fields["key"] == diskette.fields["key"])
			SetScanMessage("Failed loading: Data already exists!","danger")
			return FALSE
	var/datum/data/record/R = new(src)
	for(var/key in diskette.fields)
		R.fields[key] = diskette.fields[key]
	records += R
	SetScanMessage("Loaded into internal storage successfully.","success")
	var/obj/item/circuitboard/computer/cloning/board = circuit
	board.records = records
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)

/obj/machinery/computer/cloning/proc/Clone(mob/user, target)
	var/datum/data/record/C = find_record("id", target, records)
	//Look for that player! They better be dead!
	var/sound = 'sound/machines/terminal_prompt_deny.ogg'
	if(C)
		var/obj/machinery/clonepod/pod = GetAvailablePod()
		//Can't clone without someone to clone.  Or a pod.  Or if the pod is busy. Or full of gibs.
		if(!LAZYLEN(pods))
			SetCloningMessage("Error: No Clonepods detected.","danger")
		else if(!pod)
			SetCloningMessage("Error: No Clonepods available.","danger")
		else if(!CONFIG_GET(flag/revival_cloning))
			SetCloningMessage("Error: Unable to initiate cloning cycle.","danger")
		else if(pod.occupant)
			SetCloningMessage("Warning: Cloning cycle already in progress.","info")
		else if(pod.growclone(C.fields["ckey"], C.fields["name"], C.fields["UI"], C.fields["SE"], C.fields["mind"], C.fields["blood_type"], C.fields["mrace"], C.fields["features"], C.fields["factions"], C.fields["quirks"], C.fields["bank_account"], C.fields["traumas"]))
			SetCloningMessage("[C.fields["name"]] => Cloning cycle has begun...","success")
			sound = 'sound/machines/terminal_prompt_confirm.ogg'
			records.Remove(C)
		else
			SetCloningMessage("Error: [C.fields["name"]] => Initialisation failure.","danger")
	else
		SetCloningMessage("Failed to clone: Data corrupted.","danger")

	playsound(src, sound, 50, 0)
	. = TRUE
	// Clear cloning_message
	addtimer(CALLBACK(src,PROC_REF(SetCloningMessage)), 15 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/machinery/computer/cloning/proc/Toggle_lock(mob/user)
	if(!scanner.is_operational())
		return
	if(!scanner.locked && !scanner.occupant) //I figured out that if you're fast enough, you can lock an open pod
		return
	scanner.locked = !scanner.locked
	playsound(src, scanner.locked ? 'sound/machines/terminal_prompt_deny.ogg' : 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)
	. = TRUE

/obj/machinery/computer/cloning/proc/Scan(mob/user)
	if(!scanner.is_operational() || !scanner.occupant)
		return
	SetScanMessage("[scanned_name] => Scanning...","warning")
	playsound(src, 'sound/machines/terminal_prompt.ogg', 50, 0)
	say("Initiating scan...")
	var/prev_locked = scanner.locked
	scanner.locked = TRUE
	addtimer(CALLBACK(src, PROC_REF(finish_scan), scanner.occupant, prev_locked), 2 SECONDS)
	. = TRUE

/obj/machinery/computer/cloning/proc/Toggle_autoprocess(mob/user)
	autoprocess = !autoprocess
	if(autoprocess)
		START_PROCESSING(SSmachines, src)
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)
	else
		STOP_PROCESSING(SSmachines, src)
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
	. = TRUE

/obj/machinery/computer/cloning/ui_data(mob/user)
	var/list/data = list()
	data["useRecords"] = use_records
	var/list/records_to_send = list()
	if(use_records)
		if(scanner && HasEfficientPod() && scanner.scan_level >= AUTOCLONING_MINIMAL_LEVEL)
			data["hasAutoprocess"] = TRUE
		if(length(records))
			for(var/datum/data/record/R in records)
				var/list/record_entry = list()
				record_entry["name"] = "[R.fields["name"]]"
				record_entry["id"] = "[R.fields["id"]]"
				var/obj/item/implant/health/H = locate(R.fields["imp"])
				if(H && istype(H))
					record_entry["damages"] = H.sensehealth(TRUE)
				else
					record_entry["damages"] = FALSE
				record_entry["UI"] = "[R.fields["UI"]]"
				record_entry["UE"] = "[R.fields["UE"]]"
				record_entry["blood_type"] = "[R.fields["blood_type"]]"
				records_to_send += list(record_entry)
			data["records"] = records_to_send
		else
			data["records"] = list()
		if(diskette && diskette.fields)
			var/list/disk_data = list()
			disk_data["name"] = "[diskette.fields["name"]]"
			disk_data["id"] = "[diskette.fields["id"]]"
			disk_data["UI"] = "[diskette.fields["UI"]]"
			disk_data["UE"] = "[diskette.fields["UE"]]"
			disk_data["blood_type"] = "[diskette.fields["blood_type"]]"
			data["diskData"] = disk_data
		else
			data["diskData"] = list()
	else
		data["hasAutoprocess"] = FALSE
	data["autoprocess"] = autoprocess
	data["pods"] = get_pods_status()
	data["hasScanner"] = !isnull(src.scanner)
	var/build_temp = use_records ? "Ready to Scan" : "Ready to Clone"
	var/mob/living/scanner_occupant = get_mob_or_brainmob(scanner?.occupant)
	if(!scan_message || scanner_occupant?.ckey != scanned_ckey || scanner_occupant?.name != scanned_name)
		if(use_records)
			scanned_ckey = scanner_occupant?.ckey
			scanned_name = scanner_occupant?.name
		if(scanner_occupant)
			SetScanMessage("[scanner_occupant] => [build_temp]","info")
		else
			SetScanMessage(build_temp+"...","info")
	data["scan_result"] = list("message" = scan_message, "flag" = scan_flag)
	data["cloning_result"] = list("message" = cloning_message, "flag" = cloning_flag)
	data["scannerLocked"] = scanner?.locked
	data["hasOccupant"] = scanner?.occupant

	return data

/obj/machinery/computer/cloning/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("toggle_autoprocess")
			Toggle_autoprocess(usr)
		if("scan")
			Scan(usr)
		if("toggle_lock")
			Toggle_lock(usr)
		if("clone")
			Clone(usr, params["target"])
		if("delrecord")
			DeleteRecord(usr, params["target"])
		if("save")
			Save(usr, params["target"])
		if("load")
			Load(usr)
		if("eject")
			EjectDisk(usr)

/obj/machinery/computer/cloning/ui_interact(mob/user, datum/tgui/ui)
	if(..())
		return
	updatemodules(TRUE)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CloningConsole", "Cloning System Control")
		ui.open()

/obj/machinery/computer/cloning/proc/finish_scan(mob/living/L, prev_locked)
	if(!scanner || !L)
		return
	src.add_fingerprint(usr)

	if(use_records)
		scan_occupant(L)
	else
		clone_occupant(L)

	scanner.locked = prev_locked
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)


/obj/machinery/computer/cloning/proc/scan_occupant(occupant)
	var/mob/living/mob_occupant = get_mob_or_brainmob(occupant)
	var/datum/dna/dna
	var/datum/bank_account/has_bank_account

	// Do not use unless you know what they are.
	var/mob/living/carbon/C = mob_occupant
	var/mob/living/brain/B = mob_occupant

	if(ishuman(mob_occupant))
		dna = C.has_dna()
		var/obj/item/card/id/I = C.get_idcard()
		if(I)
			has_bank_account = I.registered_account
	if(isbrain(mob_occupant))
		dna = B.stored_dna

	if(!can_scan(dna, mob_occupant, FALSE, has_bank_account))
		return

	var/datum/data/record/R = new()
	if(dna.species)
		// We store the instance rather than the path, because some
		// species (abductors, slimepeople) store state in their
		// species datums
		dna.delete_species = FALSE
		R.fields["mrace"] = dna.species
	else
		var/datum/species/rando_race = pick(GLOB.roundstart_races)
		R.fields["mrace"] = rando_race.type

	R.fields["ckey"] = mob_occupant.ckey
	R.fields["name"] = mob_occupant.real_name
	R.fields["id"] = copytext_char(md5(mob_occupant.real_name), 2, 6)
	R.fields["UE"] = dna.unique_enzymes
	R.fields["UI"] = dna.uni_identity
	R.fields["SE"] = dna.mutation_index
	R.fields["blood_type"] = dna.blood_type
	R.fields["features"] = dna.features
	R.fields["factions"] = mob_occupant.faction
	R.fields["quirks"] = list()
	for(var/V in mob_occupant.roundstart_quirks)
		var/datum/quirk/T = V
		R.fields["quirks"][T.type] = T.clone_data()

	R.fields["traumas"] = list()
	if(ishuman(mob_occupant))
		R.fields["traumas"] = C.get_traumas()
	if(isbrain(mob_occupant))
		R.fields["traumas"] = B.get_traumas()

	R.fields["bank_account"] = has_bank_account
	if (!isnull(mob_occupant.mind)) //Save that mind so traitors can continue traitoring after cloning.
		R.fields["mind"] = "[REF(mob_occupant.mind)]"

   //Add an implant if needed
	var/obj/item/implant/health/imp
	for(var/obj/item/implant/health/HI in mob_occupant.implants)
		imp = HI
		break
	if(!imp)
		imp = new /obj/item/implant/health(mob_occupant)
		imp.implant(mob_occupant)
	R.fields["imp"] = "[REF(imp)]"

	src.records += R
	var/obj/item/circuitboard/computer/cloning/board = circuit
	board.records = records
	SetScanMessage("Subject successfully scanned.","success")
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)

//Used by the experimental cloning computer.
/obj/machinery/computer/cloning/proc/clone_occupant(occupant)
	var/mob/living/mob_occupant = get_mob_or_brainmob(occupant)
	var/datum/dna/dna
	if(ishuman(mob_occupant))
		var/mob/living/carbon/C = mob_occupant
		dna = C.has_dna()
	if(isbrain(mob_occupant))
		var/mob/living/brain/B = mob_occupant
		dna = B.stored_dna

	if(!can_scan(dna, mob_occupant, TRUE))
		return

	var/clone_species
	if(dna.species)
		clone_species = dna.species
	else
		var/datum/species/rando_race = pick(GLOB.roundstart_races)
		clone_species = rando_race.type

	var/obj/machinery/clonepod/pod = GetAvailablePod()
	//Can't clone without someone to clone.  Or a pod.  Or if the pod is busy. Or full of gibs.
	if(!LAZYLEN(pods))
		SetCloningMessage("No Clonepods detected.","danger")
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
	else if(!pod)
		SetCloningMessage("No Clonepods available.","danger")
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
	else if(pod.occupant)
		SetCloningMessage("Cloning cycle already in progress.","info")
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, 0)
	else
		pod.growclone(null, mob_occupant.real_name, dna.uni_identity, dna.mutation_index, null, dna.blood_type, clone_species, dna.features, mob_occupant.faction)
		SetCloningMessage("[mob_occupant.real_name] => Cloning data sent to pod.","success")
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, 0)

/obj/machinery/computer/cloning/proc/can_scan(datum/dna/dna, mob/living/mob_occupant, experimental = FALSE, datum/bank_account/account)
	var/error_message = ""
	var/error_sound = 'sound/machines/terminal_prompt_deny.ogg'
	if(!istype(dna))
		error_message = "Unable to locate valid genetic data."
	// Check for DNC Order quirk
	else if(HAS_TRAIT(mob_occupant, TRAIT_DNC_ORDER))
		error_message = "Subject has an active DNC order on file. Further operations terminated."
	// BLUEMOON ADD START - нельзя сканировать синтетиков
	else if(HAS_TRAIT(mob_occupant, TRAIT_ROBOTIC_ORGANISM))
		error_message = "ERROR. Insert a living occupant."
	// BLUEMOON ADD END
	else if((HAS_TRAIT(mob_occupant, TRAIT_NOCLONE)) && (src.scanner.scan_level < 2))
		error_message = "Subject no longer contains the fundamental materials required to create a living clone."
		error_sound = 'sound/machines/terminal_alert.ogg'
	else if(!experimental)
		if(mob_occupant.suiciding || mob_occupant.hellbound)
			error_message = "Subject's brain is not responding to scanning stimuli."
		else if(!mob_occupant.ckey || !mob_occupant.client)
			error_message = "Mental interface failure."
		else if (find_record("ckey", mob_occupant.ckey, records))
			error_message = "Subject already in database."
		else if(SSeconomy.full_ancap && !account)
			error_message = "Subject is either missing an ID card with a bank account on it, or does not have an account to begin with. Please ensure the ID card is on the body before attempting to scan."

	if(error_message)
		SetScanMessage(error_message,"danger")
		playsound(src, error_sound, 50, 0)
		return FALSE

	return TRUE

//Prototype cloning console, much more rudimental and lacks modern functions such as saving records, autocloning, or safety checks.
/obj/machinery/computer/cloning/prototype
	name = "prototype cloning console"
	desc = "Used to operate an experimental cloner."
	icon_screen = "dna"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/computer/cloning/prototype
	clonepod_type = /obj/machinery/clonepod/experimental
	use_records = FALSE	//Wait, so you tell me it lacks records but you never set it as false?

#undef AUTOCLONING_MINIMAL_LEVEL
