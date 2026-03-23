#define MAIN_SCREEN 1
#define SYMPTOM_DETAILS 2

/obj/machinery/computer/pandemic
	name = "PanD.E.M.I.C 2200"
	desc = "Used to work with viruses."
	density = TRUE
	icon = 'modular_splurt/icons/obj/chemical.dmi'
	icon_state = "pandemic0"
	icon_keyboard = null
	base_icon_state = "pandemic"
	use_power = IDLE_POWER_USE
	idle_power_usage = 20
	resistance_flags = ACID_PROOF
	circuit = /obj/item/circuitboard/computer/pandemic
	unique_icon = TRUE

	var/wait
	var/datum/symptom/selected_symptom
	var/obj/item/reagent_containers/beaker
	var/tier = 1
	var/replicator_cooldown_time = 50
	var/vaccine_cooldown_time = 200
	var/custom_virus_cooldown = 0
	var/custom_virus_cooldown_duration = 1800 // 3 minutes
	var/obj/item/pandemic_upgrade/installed_upgrade

/obj/machinery/computer/pandemic/Initialize(mapload)
	. = ..()
	update_tier()
	update_icon()

/obj/machinery/computer/pandemic/proc/update_tier()
	tier = installed_upgrade ? installed_upgrade.rating : 1
	replicator_cooldown_time = initial(replicator_cooldown_time) / tier
	vaccine_cooldown_time = initial(vaccine_cooldown_time) / tier

/obj/machinery/computer/pandemic/Destroy()
	if(installed_upgrade)
		installed_upgrade.forceMove(drop_location())
		installed_upgrade = null
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/computer/pandemic/examine(mob/user)
	. = ..()
	if(installed_upgrade)
		. += "Installed replication module: Tier [tier]."
	if(beaker)
		var/is_close
		if(Adjacent(user)) //don't reveal exactly what's inside unless they're close enough to see the UI anyway.
			. += "It contains \a [beaker]."
			is_close = TRUE
		else
			. += "It has a beaker inside it."
		. += "<span class='info'>Alt-click to eject [is_close ? beaker : "the beaker"].</span>"

/obj/machinery/computer/pandemic/AltClick(mob/user)
	. = ..()
	if(user.canUseTopic(src, BE_CLOSE))
		eject_beaker()

/obj/machinery/computer/pandemic/handle_atom_del(atom/A)
	if(A == beaker)
		beaker = null
		update_icon()
	return ..()

/obj/machinery/computer/pandemic/proc/get_by_index(thing, index)
	if(!beaker || !beaker.reagents)
		return
	var/datum/reagent/blood/B = locate() in beaker.reagents.reagent_list
	if(B && B.data[thing])
		return B.data[thing][index]

/obj/machinery/computer/pandemic/proc/get_virus_id_by_index(index)
	var/datum/disease/D = get_by_index("viruses", index)
	if(D)
		return D.GetDiseaseID()

/obj/machinery/computer/pandemic/proc/get_viruses_data(datum/reagent/blood/B)
	. = list()
	var/list/V = B.get_diseases()
	var/index = 1
	for(var/virus in V)
		var/datum/disease/D = virus
		if(!istype(D) || D.visibility_flags & HIDDEN_PANDEMIC)
			continue

		var/list/this = list()
		this["name"] = D.name
		if(istype(D, /datum/disease/advance))
			var/datum/disease/advance/A = D
			var/disease_name = SSdisease.get_disease_name(A.GetDiseaseID())
			this["can_rename"] = ((disease_name == "Unknown") && A.mutable)
			this["name"] = disease_name
			this["is_adv"] = TRUE
			this["symptoms"] = list()
			for(var/symptom in A.symptoms)
				var/datum/symptom/S = symptom
				var/list/this_symptom = list()
				this_symptom = get_symptom_data(S)
				this["symptoms"] += list(this_symptom)
			this["resistance"] = A.totalResistance()
			this["stealth"] = A.totalStealth()
			this["stage_speed"] = A.totalStageSpeed()
			this["transmission"] = A.totalTransmittable()
		this["index"] = index++
		this["agent"] = D.agent
		this["description"] = D.desc || "none"
		this["spread"] = D.spread_text || "none"
		this["cure"] = D.cure_text || "none"

		. += list(this)

/obj/machinery/computer/pandemic/proc/get_symptom_data(datum/symptom/S)
	. = list()
	var/list/this = list()
	this["name"] = S.name
	this["desc"] = S.desc
	this["stealth"] = S.stealth
	this["resistance"] = S.resistance
	this["stage_speed"] = S.stage_speed
	this["transmission"] = S.transmittable
	this["level"] = S.level
	this["neutered"] = S.neutered
	this["threshold_desc"] = S.threshold_desc
	. += this

/obj/machinery/computer/pandemic/proc/get_resistance_data(datum/reagent/blood/B)
	. = list()
	if(!islist(B.data["resistances"]))
		return
	var/list/resistances = B.data["resistances"]
	for(var/id in resistances)
		var/list/this = list()
		this["id"] = id
		var/datum/disease/D = SSdisease.archive_diseases[id]
		this["name"] = D ? D.name : "Unknown"
		. += list(this)

/obj/machinery/computer/pandemic/proc/reset_replicator_cooldown()
	wait = FALSE
	update_icon()
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)

/obj/machinery/computer/pandemic/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = (beaker ? "mixer1_b" : "mixer0_b")
	else
		icon_state = "pandemic[(beaker) ? "1" : "0"][powered() ? "" : "_nopower"]"

/obj/machinery/computer/pandemic/update_overlays()
	. = ..()
	if(wait)
		. += "waitlight"

/obj/machinery/computer/pandemic/proc/eject_beaker()
	if(beaker)
		var/obj/item/reagent_containers/B = beaker
		beaker.forceMove(drop_location())
		beaker = null
		update_icon()
		return B
	return null

/obj/machinery/computer/pandemic/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Pandemic", name)
		ui.open()

/obj/machinery/computer/pandemic/ui_data(mob/user)
	var/list/data = list()
	data["is_ready"] = !wait
	data["tier"] = tier
	data["custom_cooldown"] = max(0, custom_virus_cooldown - world.time)
	if(beaker)
		data["has_beaker"] = TRUE
		data["beaker_empty"] = (!beaker.reagents.total_volume || !beaker.reagents.reagent_list)
		var/datum/reagent/blood/B = locate() in beaker.reagents.reagent_list
		if(B)
			data["has_blood"] = TRUE
			data["blood"] = list() //wha why the fuck are we sending pathtypes to tgui frontend?
			data["blood"]["dna"] = B.data["blood_DNA"] || "none"
			data["blood"]["type"] = B.data["blood_type"] || "none"
			data["viruses"] = get_viruses_data(B)
			data["resistances"] = get_resistance_data(B)
		else
			data["has_blood"] = FALSE
	else
		data["has_beaker"] = FALSE
		data["has_blood"] = FALSE

	return data

/obj/machinery/computer/pandemic/ui_static_data(mob/user)
	var/list/data = list()
	data["all_symptoms"] = list()
	var/index = 1
	for(var/symp_type in SSdisease.list_symptoms)
		var/datum/symptom/S = new symp_type
		if(S.name && !S.neutered)
			data["all_symptoms"] += list(list(
				"id" = "[index]",
				"name" = S.name,
				"desc" = S.desc,
				"level" = S.level,
				"resistance" = S.resistance,
				"stage_speed" = S.stage_speed,
				"transmission" = S.transmittable,
				"stealth" = S.stealth
			))
		qdel(S)
		index++
	return data

/obj/machinery/computer/pandemic/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("create_custom_virus")
			if(tier < 4)
				to_chat(usr, "<span class='warning'>Upgrade the machine to Tier 4 to use this feature.</span>")
				return
			if(custom_virus_cooldown > world.time)
				to_chat(usr, "<span class='warning'>Replication sequencer is cooling down.</span>")
				return
			
			var/list/symptom_ids = params["symptom_ids"]
			if(!islist(symptom_ids) || !symptom_ids.len)
				return
			
			if(symptom_ids.len > VIRUS_SYMPTOM_LIMIT)
				to_chat(usr, "<span class='warning'>Too many symptoms selected. Max is [VIRUS_SYMPTOM_LIMIT].</span>")
				return

			var/datum/disease/advance/D = new()
			D.symptoms = list()
			
			for(var/symp_id in symptom_ids)
				var/index = text2num(symp_id)
				if(index < 1 || index > SSdisease.list_symptoms.len)
					continue
				var/symp_type = SSdisease.list_symptoms[index]
				var/datum/symptom/S = new symp_type
				if(!D.HasSymptom(S))
					D.symptoms += S
				else
					qdel(S)
			if(D.symptoms.len)
				D.AssignName("Custom Strain [rand(100, 999)]")
				D.Refresh()
				
				var/obj/item/reagent_containers/glass/bottle/B = new(drop_location())
				B.name = "[D.name] culture bottle"
				B.desc = "A small bottle. Contains [D.agent] culture in synthblood medium."
				var/list/data = list("donor"=null,"viruses"=list(D),"blood_DNA"="SYNTHESIZED", "bloodcolor" = BLOOD_COLOR_SYNTHETIC, "blood_type"="SY","resistances"=null,"trace_chem"=null,"mind"=null,"ckey"=null,"gender"=null,"real_name"=null,"cloneable"=null,"factions"=null)
				B.reagents.add_reagent(/datum/reagent/blood/synthetics, 10, data)
				
				custom_virus_cooldown = world.time + custom_virus_cooldown_duration
				var/turf/source_turf = get_turf(src)
				log_virus("A custom virus [D.admin_details()] was synthesized at [loc_name(source_turf)] by [key_name(usr)]")
				to_chat(usr, "<span class='notice'>Virus synthesized successfully.</span>")
				. = TRUE
			else
				qdel(D)
				to_chat(usr, "<span class='warning'>Failed to synthesize virus. No valid symptoms.</span>")
		if("eject_beaker")
			eject_beaker()
			. = TRUE
		if("empty_beaker")
			if(beaker)
				beaker.reagents.clear_reagents()
			. = TRUE
		if("empty_eject_beaker")
			if(beaker)
				beaker.reagents.clear_reagents()
				eject_beaker()
			. = TRUE
		if("rename_disease")
			var/id = get_virus_id_by_index(text2num(params["index"]))
			var/datum/disease/advance/A = SSdisease.archive_diseases[id]
			if(!A.mutable)
				return
			if(A)
				var/new_name = sanitize_name(html_encode(trim(params["name"], 50)))//, allow_numbers = TRUE)
				if(!new_name || ..())
					return
				A.AssignName(new_name)
				. = TRUE
		if("create_culture_bottle")
			if (wait)
				return
			var/id = get_virus_id_by_index(text2num(params["index"]))
			var/datum/disease/advance/A = SSdisease.archive_diseases[id]
			if(!istype(A) || !A.mutable)
				to_chat(usr, "<span class='warning'>ERROR: Cannot replicate virus strain.</span>")
				return
			A = A.Copy()
			var/list/data = list("donor"=null,"viruses"=list(A),"blood_DNA"="REPLICATED", "bloodcolor" = BLOOD_COLOR_SYNTHETIC, "blood_type"="SY","resistances"=null,"trace_chem"=null,"mind"=null,"ckey"=null,"gender"=null,"real_name"=null,"cloneable"=null,"factions"=null)
			var/obj/item/reagent_containers/glass/bottle/B = new(drop_location())
			B.name = "[A.name] culture bottle"
			B.desc = "A small bottle. Contains [A.agent] culture in synthblood medium."
			B.reagents.add_reagent(/datum/reagent/blood/synthetics, 10, data)
			wait = TRUE
			update_icon()
			var/turf/source_turf = get_turf(src)
			log_virus("A culture bottle was printed for the virus [A.admin_details()] at [loc_name(source_turf)] by [key_name(usr)]")
			addtimer(CALLBACK(src, PROC_REF(reset_replicator_cooldown)), replicator_cooldown_time)
			. = TRUE
		if("create_vaccine_bottle")
			if (wait)
				return
			var/id = params["index"]
			if(!id)
				return
			var/datum/disease/D = SSdisease.archive_diseases[id]
			var/obj/item/reagent_containers/glass/bottle/B = new(drop_location())
			var/display_name = D ? D.name : "Unknown"
			B.name = "[display_name] vaccine bottle"
			B.reagents.add_reagent(/datum/reagent/vaccine, 15, list(id))
			wait = TRUE
			update_icon()
			addtimer(CALLBACK(src, PROC_REF(reset_replicator_cooldown)), vaccine_cooldown_time)
			. = TRUE


/obj/machinery/computer/pandemic/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/pandemic_upgrade))
		if(installed_upgrade)
			to_chat(user, "<span class='warning'>[src] already has a replication module. Use a crowbar to remove it first.</span>")
			return
		if(!user.transferItemToLoc(I, src))
			return
		installed_upgrade = I
		update_tier()
		to_chat(user, "<span class='notice'>You install [I] into [src]. Replication tier is now [tier].</span>")
		return
	if(I.tool_behaviour == TOOL_CROWBAR && installed_upgrade)
		installed_upgrade.forceMove(drop_location())
		if(user && Adjacent(user) && user.can_hold_items())
			user.put_in_hands(installed_upgrade)
		to_chat(user, "<span class='notice'>You remove [installed_upgrade] from [src].</span>")
		installed_upgrade = null
		update_tier()
		I.play_tool_sound(src)
		return
	if(istype(I, /obj/item/reagent_containers) && !(I.item_flags & ABSTRACT) && I.is_open_container())
		. = TRUE //no afterattack
		if(machine_stat & (NOPOWER|BROKEN))
			return
		var/obj/item/reagent_containers/B
		if(beaker)
			B = eject_beaker() //now with 100% more swapping
		if(!user.transferItemToLoc(I, src))
			return
		if(B)
			if(user && Adjacent(user) && user.can_hold_items())
				user.put_in_hands(B)
		beaker = I
		if(B) to_chat(user, "<span class='notice'>You remove [B] and insert [I] into [src].</span>")
		else to_chat(user, "<span class='notice'>You insert [I] into [src].</span>")
		update_icon()
	else
		return ..()

/obj/machinery/computer/pandemic/on_deconstruction()
	if(installed_upgrade)
		installed_upgrade.forceMove(drop_location())
		installed_upgrade = null
	eject_beaker()
	. = ..()

// Upgrade module — insert into built Pandemic to increase tier (faster cooldowns, Tier 4+ unlocks custom virus synthesis).
/obj/item/pandemic_upgrade
	name = "Pandemic replication module (Tier 2)"
	desc = "A module that speeds up culture and vaccine production when installed in a PanD.E.M.I.C. 2200. Use on the machine to install; crowbar to remove."
	icon = 'icons/obj/module.dmi'
	icon_state = "card_mod"
	w_class = WEIGHT_CLASS_SMALL
	var/rating = 2

/obj/item/pandemic_upgrade/tier3
	name = "Pandemic replication module (Tier 3)"
	rating = 3

/obj/item/pandemic_upgrade/tier4
	name = "Pandemic replication module (Tier 4)"
	rating = 4

/obj/item/pandemic_upgrade/tier5
	name = "Pandemic replication module (Tier 5)"
	rating = 5
